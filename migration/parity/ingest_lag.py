#!/usr/bin/env python3
"""
ingest_lag.py — Phase 2 / Gate 2 ingest-lag measurement (A6 / issue #172).

Computes Security Onion end-to-end ingest lag from a set of ECS events and
checks it against the 300 s SLO — the metric that the legacy ELK pipeline
breached at ~23,662 s (docs/migration/evidence/phase-2.md, A6).

It does NOT talk to Elasticsearch. It reads newline-delimited JSON (NDJSON)
events — exported from the SOC console (Hunt/Discover "download"), or piped from
a Phase-4 ES query once P4.1 provisions the read-only account — and reports the
lag distribution. This keeps A6 runnable while direct SO ES access is deferred to
Phase 4 (see migration/parity/README.md, "Not automated here").

Lag is decomposed by ECS timestamp so a breach is diagnosable, not just visible:

    collection lag = event.created  - @timestamp   (source -> shipper/agent)
    index lag      = event.ingested - event.created (shipper -> indexed in ES)
    end-to-end lag = event.ingested - @timestamp    (HEADLINE vs the 300 s SLO)

`event.ingested` is stamped by the ES ingest pipeline at index time, so it is the
best "queryable in the store" proxy; `@timestamp` is when the event occurred.

Fallback is fail-closed by design. Docs missing `event.ingested` can only yield a
*collection-only lower bound* (`event.created - @timestamp`) that omits the very
shipper->index leg the legacy breach lived in. Such docs are therefore EXCLUDED
from the SLO verdict and reported separately — they cannot produce a PASS. Pass
`--allow-fallback` to fold them into the verdict as a lower bound anyway (e.g. an
environment that genuinely never stamps `event.ingested`).

Usage:
    # From a console export:
    python3 ingest_lag.py sample.ndjson
    # From a pipe (e.g. a Phase-4 ES query via jq producing one _source per line):
    some_es_query | python3 ingest_lag.py --format md
    # Tighten/loosen the SLO or point at non-default fields:
    python3 ingest_lag.py --slo 300 --event-time @timestamp sample.ndjson

Exit code: 0 if the end-to-end SLO holds (median AND p95 within SLO, on real
`event.ingested` samples), 1 if breached or unconfirmable (e.g. no
`event.ingested` samples and no --allow-fallback), 2 on a usage/input error
(unreadable file, non-UTF-8 bytes, or no event carrying a usable timestamp pair).
The non-zero-on-breach contract lets a later CI job gate on it.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from math import ceil
from typing import Any, Iterable

# Trailing fractional seconds with more than microsecond precision (e.g. Elastic
# nanosecond timestamps) — datetime only carries microseconds, so truncate.
_SUBSECOND = re.compile(r"\.(\d{6})\d+")


def parse_ts(value: Any) -> datetime | None:
    """Parse an ECS/ISO-8601 timestamp into an aware UTC datetime, or None.

    Tolerates a trailing 'Z', explicit offsets, and sub-microsecond (nanosecond)
    precision. Naive timestamps are assumed UTC. Returns None for anything
    unparseable so one bad field never aborts a whole run.
    """
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip()
    # datetime.fromisoformat accepts 'Z' only on 3.11+; normalize for safety.
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    text = _SUBSECOND.sub(r".\1", text, count=1)
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def get_field(doc: dict[str, Any], dotted: str) -> Any:
    """Fetch an ECS field that may be stored dotted ('event.ingested') or nested.

    ES sources vary: some carry flat dotted keys, some nest objects. Try the flat
    key first, then walk the nesting. Returns None if absent at any level.
    """
    if dotted in doc:
        return doc[dotted]
    node: Any = doc
    for part in dotted.split("."):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


def unwrap(record: dict[str, Any]) -> dict[str, Any]:
    """Return the ECS body whether the line is a raw _source or a full ES hit."""
    inner = record.get("_source")
    return inner if isinstance(inner, dict) else record


def percentile(values: list[float], pct: float) -> float:
    """Nearest-rank percentile (deterministic, no numpy). `values` must be sorted."""
    if not values:
        raise ValueError("percentile of empty sequence")
    rank = ceil(pct / 100.0 * len(values))
    rank = min(max(rank, 1), len(values))
    return values[rank - 1]


@dataclass
class LagStats:
    """Distribution of a single lag stage (all figures in seconds)."""

    count: int
    minimum: float
    median: float
    p95: float
    maximum: float

    @classmethod
    def of(cls, seconds: list[float]) -> "LagStats | None":
        if not seconds:
            return None
        ordered = sorted(seconds)
        mid = len(ordered) // 2
        median = (
            ordered[mid]
            if len(ordered) % 2
            else (ordered[mid - 1] + ordered[mid]) / 2.0
        )
        return cls(
            count=len(ordered),
            minimum=ordered[0],
            median=median,
            p95=percentile(ordered, 95),
            maximum=ordered[-1],
        )


@dataclass
class Report:
    slo_stats: LagStats | None = None  # distribution the SLO verdict is computed on
    end_to_end: LagStats | None = None  # real event.ingested - @timestamp samples
    fallback: LagStats | None = None  # collection-only lower bound (no event.ingested)
    collection: LagStats | None = None  # diagnostic leg: event.created - @timestamp
    index: LagStats | None = None  # diagnostic leg: event.ingested - event.created
    real_count: int = 0  # docs with event.ingested
    fallback_count: int = 0  # docs with only event.created (lower-bound proxy)
    negative: dict[str, int] = field(
        default_factory=lambda: {"end_to_end": 0, "fallback": 0, "collection": 0, "index": 0}
    )
    skipped: int = 0  # docs lacking a usable timestamp pair
    malformed: int = 0  # unparseable JSON lines
    total: int = 0  # JSON-dict records read (excludes blank/malformed lines)
    slo_seconds: float = 300.0
    allow_fallback: bool = False
    warnings: list[str] = field(default_factory=list)

    @property
    def within_slo(self) -> bool:
        """SLO holds iff the verdict distribution exists and median AND p95 fit.

        Fail-closed: with no `event.ingested` samples and no --allow-fallback,
        `slo_stats` is None → not within SLO (unconfirmable, never a false PASS).
        """
        s = self.slo_stats
        return bool(s) and s.median <= self.slo_seconds and s.p95 <= self.slo_seconds


def measure(
    records: Iterable[dict[str, Any]],
    *,
    event_time: str = "@timestamp",
    ingested: str = "event.ingested",
    created: str = "event.created",
    slo_seconds: float = 300.0,
    allow_fallback: bool = False,
) -> Report:
    """Compute the lag report over already-parsed JSON records."""
    rep = Report(slo_seconds=slo_seconds, allow_fallback=allow_fallback)
    real_e2e: list[float] = []  # ingested - @timestamp (SLO-authoritative)
    fallback_e2e: list[float] = []  # created - @timestamp (lower bound)
    collection: list[float] = []
    index: list[float] = []

    def _tally(seconds: float, leg: str, bucket: list[float]) -> None:
        if seconds < 0:
            rep.negative[leg] += 1
        bucket.append(seconds)

    for record in records:
        rep.total += 1
        doc = unwrap(record)
        t_event = parse_ts(get_field(doc, event_time))
        t_ingested = parse_ts(get_field(doc, ingested))
        t_created = parse_ts(get_field(doc, created))

        if t_event is None:
            rep.skipped += 1
            continue

        # End-to-end needs event.ingested. If it's absent we can only fall back to
        # event.created — a collection-only lower bound kept out of the verdict.
        if t_ingested is not None:
            rep.real_count += 1
            _tally((t_ingested - t_event).total_seconds(), "end_to_end", real_e2e)
        elif t_created is not None:
            rep.fallback_count += 1
            _tally((t_created - t_event).total_seconds(), "fallback", fallback_e2e)
        else:
            rep.skipped += 1
            continue

        if t_created is not None:
            _tally((t_created - t_event).total_seconds(), "collection", collection)
        if t_ingested is not None and t_created is not None:
            _tally((t_ingested - t_created).total_seconds(), "index", index)

    rep.end_to_end = LagStats.of(real_e2e)
    rep.fallback = LagStats.of(fallback_e2e)
    rep.collection = LagStats.of(collection)
    rep.index = LagStats.of(index)
    # The verdict runs on real samples, plus fallback only when opted in.
    verdict_samples = real_e2e + (fallback_e2e if allow_fallback else [])
    rep.slo_stats = LagStats.of(verdict_samples)

    _add_warnings(rep)
    return rep


def _add_warnings(rep: Report) -> None:
    for leg, count in rep.negative.items():
        if count:
            rep.warnings.append(
                f"{count} event(s) had negative {leg.replace('_', '-')} lag "
                "(clock skew) — kept in the distribution; check NTP if widespread."
            )
    if rep.fallback_count and rep.allow_fallback:
        rep.warnings.append(
            f"{rep.fallback_count} event(s) lacked event.ingested — folded into the "
            "verdict as a collection-only LOWER BOUND (omits the shipper→index leg)."
        )
    elif rep.fallback_count:
        rep.warnings.append(
            f"{rep.fallback_count} event(s) lacked event.ingested — EXCLUDED from the "
            "SLO verdict (collection-only lower bound). Re-run with --allow-fallback "
            "to include them as a lower bound."
        )
    if rep.slo_stats is None and (rep.fallback_count or rep.real_count == 0):
        rep.warnings.append(
            "No event.ingested samples in the verdict — SLO is UNCONFIRMED "
            "(fail-closed). Verdict reads BREACH until real end-to-end data exists."
        )


def _fmt(seconds: float) -> str:
    return f"{seconds:.1f}s"


def render_text(rep: Report) -> str:
    lines: list[str] = []
    verdict = "PASS" if rep.within_slo else "BREACH"
    basis = "" if rep.slo_stats is None else (
        " (incl. fallback lower bound)" if rep.allow_fallback and rep.fallback_count else ""
    )
    lines.append(f"Ingest-lag report — SLO {int(rep.slo_seconds)}s — {verdict}{basis}")
    lines.append(
        f"  records read: {rep.total} · real end-to-end: {rep.real_count} · "
        f"fallback: {rep.fallback_count} · skipped: {rep.skipped} · "
        f"malformed lines: {rep.malformed}"
    )
    for label, stats in (
        ("end-to-end (event.ingested - @timestamp)", rep.end_to_end),
        ("fallback   (event.created  - @timestamp, lower bound)", rep.fallback),
        ("collection (event.created  - @timestamp)", rep.collection),
        ("index      (event.ingested - event.created)", rep.index),
    ):
        if stats is None:
            lines.append(f"  {label}: n/a")
            continue
        lines.append(
            f"  {label}: n={stats.count} median={_fmt(stats.median)} "
            f"p95={_fmt(stats.p95)} max={_fmt(stats.maximum)} min={_fmt(stats.minimum)}"
        )
    for warning in rep.warnings:
        lines.append(f"  WARN: {warning}")
    return "\n".join(lines)


def render_md(rep: Report) -> str:
    """A markdown block ready to paste into evidence/phase-2.md (A6)."""
    s = rep.slo_stats
    slo = int(rep.slo_seconds)
    within = "✓" if rep.within_slo else "✗"
    median = _fmt(s.median) if s else "unconfirmed"
    p95 = _fmt(s.p95) if s else "unconfirmed"
    maximum = _fmt(s.maximum) if s else "unconfirmed"
    n = s.count if s else 0
    lines = [
        "| Metric | Legacy ELK | Security Onion |",
        "|---|---|---|",
        f"| Median end-to-end lag (n={n}) | ~23,662 s (breach) | {median} |",
        f"| p95 end-to-end lag | — | {p95} |",
        f"| Max end-to-end lag | — | {maximum} |",
        f"| Within {slo} s SLO? | ✗ | {within} |",
    ]
    if rep.warnings:
        lines.append("")
        for warning in rep.warnings:
            lines.append(f"> Note: {warning}")
    return "\n".join(lines)


def parse_ndjson(lines: Iterable[str]) -> tuple[list[dict[str, Any]], int]:
    """Parse NDJSON lines into JSON-dict records; return (records, malformed_count).

    Blank lines are ignored; lines that don't parse or aren't objects count as
    malformed (a JSON array/scalar is not a usable ECS document).
    """
    records: list[dict[str, Any]] = []
    malformed = 0
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            malformed += 1
            continue
        if isinstance(obj, dict):
            records.append(obj)
        else:
            malformed += 1
    return records, malformed


def _read_input_lines(files: list[str]) -> list[str]:
    """Read all NDJSON lines from files (or stdin). Raises OSError/UnicodeDecodeError."""
    if not files:
        return sys.stdin.readlines()
    lines: list[str] = []
    for path in files:
        with open(path, "r", encoding="utf-8") as handle:
            lines.extend(handle.readlines())
    return lines


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1] if __doc__ else "")
    parser.add_argument("files", nargs="*", help="NDJSON files (default: stdin)")
    parser.add_argument("--slo", type=float, default=300.0, help="SLO in seconds (default 300)")
    parser.add_argument("--event-time", default="@timestamp", help="event-time field")
    parser.add_argument("--ingested", default="event.ingested", help="indexed-time field")
    parser.add_argument("--created", default="event.created", help="collection-time field")
    parser.add_argument(
        "--allow-fallback",
        action="store_true",
        help="fold event.created lower-bound samples into the SLO verdict",
    )
    parser.add_argument("--format", choices=("text", "md"), default="text", help="output format")
    args = parser.parse_args(argv)

    try:
        raw_lines = _read_input_lines(args.files)
    except (OSError, UnicodeDecodeError) as exc:
        print(f"error: cannot read input: {exc}", file=sys.stderr)
        return 2

    records, malformed = parse_ndjson(raw_lines)
    rep = measure(
        records,
        event_time=args.event_time,
        ingested=args.ingested,
        created=args.created,
        slo_seconds=args.slo,
        allow_fallback=args.allow_fallback,
    )
    rep.malformed = malformed

    # Truly no usable data (no real and no fallback samples) is an input error.
    if rep.end_to_end is None and rep.fallback is None:
        print(
            "error: no events with a usable (@timestamp + event.ingested/created) "
            f"pair — read {rep.total}, skipped {rep.skipped}, malformed {malformed}",
            file=sys.stderr,
        )
        return 2

    print(render_md(rep) if args.format == "md" else render_text(rep))
    return 0 if rep.within_slo else 1


if __name__ == "__main__":
    raise SystemExit(main())
