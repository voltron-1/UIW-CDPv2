#!/usr/bin/env python3
"""
test_ingest_lag.py — tests for the A6 ingest-lag helper (issue #172).

Runs under pytest, or standalone: `python3 test_ingest_lag.py`.
"""

from __future__ import annotations

import os
import tempfile
from datetime import timezone

import ingest_lag as il


# --- parse_ts -------------------------------------------------------------

def test_parse_ts_zulu_and_offset_are_equal():
    a = il.parse_ts("2026-07-06T12:00:00Z")
    b = il.parse_ts("2026-07-06T12:00:00+00:00")
    assert a == b
    assert a.tzinfo == timezone.utc


def test_parse_ts_truncates_nanoseconds():
    # 9 fractional digits -> microseconds, no crash.
    ts = il.parse_ts("2026-07-06T12:00:00.123456789Z")
    assert ts is not None
    assert ts.microsecond == 123456


def test_parse_ts_naive_assumed_utc():
    ts = il.parse_ts("2026-07-06T12:00:00")
    assert ts is not None and ts.tzinfo == timezone.utc


def test_parse_ts_bad_input_returns_none():
    for bad in ["", "   ", "not-a-date", None, 12345, {}]:
        assert il.parse_ts(bad) is None


# --- get_field / unwrap ---------------------------------------------------

def test_get_field_dotted_then_nested():
    assert il.get_field({"event.ingested": "x"}, "event.ingested") == "x"
    assert il.get_field({"event": {"ingested": "y"}}, "event.ingested") == "y"
    assert il.get_field({"event": {}}, "event.ingested") is None
    assert il.get_field({}, "event.ingested") is None


def test_unwrap_source_vs_raw():
    assert il.unwrap({"_source": {"a": 1}}) == {"a": 1}
    assert il.unwrap({"a": 1}) == {"a": 1}


# --- percentile / LagStats -----------------------------------------------

def test_percentile_nearest_rank():
    vals = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
    assert il.percentile(vals, 95) == 10.0
    assert il.percentile(vals, 50) == 5.0
    assert il.percentile([42.0], 95) == 42.0


def test_lagstats_median_even_and_odd():
    assert il.LagStats.of([3.0, 1.0, 2.0]).median == 2.0  # odd
    assert il.LagStats.of([1.0, 2.0, 3.0, 4.0]).median == 2.5  # even
    assert il.LagStats.of([]) is None


# --- measure: end-to-end paths -------------------------------------------

def _event(ts, ingested=None, created=None):
    doc = {"@timestamp": ts}
    if ingested is not None:
        doc["event.ingested"] = ingested
    if created is not None:
        doc["event.created"] = created
    return doc


def test_measure_within_slo():
    events = [
        _event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:10Z", created="2026-07-06T12:00:03Z"),
        _event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:20Z", created="2026-07-06T12:00:05Z"),
        _event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:30Z", created="2026-07-06T12:00:06Z"),
    ]
    rep = il.measure(events, slo_seconds=300)
    assert rep.end_to_end.count == 3
    assert rep.end_to_end.median == 20.0
    assert rep.slo_stats.median == 20.0  # verdict runs on the real distribution
    assert rep.collection.median == 5.0
    assert rep.index.median == 15.0  # 20 - 5
    assert rep.within_slo is True


def test_measure_breach_sets_nonzero_verdict():
    events = [
        _event("2026-07-06T00:00:00Z", ingested="2026-07-06T06:34:22Z"),  # 23662s
    ]
    rep = il.measure(events, slo_seconds=300)
    assert rep.end_to_end.median == 23662.0
    assert rep.within_slo is False


def test_measure_fallback_is_excluded_from_verdict_by_default():
    # No event.ingested -> fail-closed: not counted toward the SLO verdict.
    events = [_event("2026-07-06T12:00:00Z", created="2026-07-06T12:00:04Z")]
    rep = il.measure(events, slo_seconds=300)
    assert rep.fallback_count == 1
    assert rep.end_to_end is None  # no real end-to-end samples
    assert rep.fallback.median == 4.0  # lower bound is still reported
    assert rep.slo_stats is None  # excluded from the verdict
    assert rep.within_slo is False  # unconfirmable -> not a PASS
    assert rep.index is None  # no ingested -> no index leg
    assert any("EXCLUDED" in w for w in rep.warnings)


def test_measure_allow_fallback_folds_lower_bound_into_verdict():
    events = [_event("2026-07-06T12:00:00Z", created="2026-07-06T12:00:04Z")]
    rep = il.measure(events, slo_seconds=300, allow_fallback=True)
    assert rep.slo_stats.median == 4.0
    assert rep.within_slo is True
    assert any("LOWER BOUND" in w for w in rep.warnings)


def test_measure_flags_negative_end_to_end_lag():
    events = [_event("2026-07-06T12:00:10Z", ingested="2026-07-06T12:00:00Z")]  # -10s
    rep = il.measure(events, slo_seconds=300)
    assert rep.negative["end_to_end"] == 1
    assert rep.end_to_end.median == -10.0
    assert any("clock skew" in w and "end-to-end" in w for w in rep.warnings)


def test_measure_flags_negative_index_leg_independently():
    # ingested BEFORE created: end-to-end nets positive, but the index leg is -5s.
    events = [_event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:15Z", created="2026-07-06T12:00:20Z")]
    rep = il.measure(events, slo_seconds=300)
    assert rep.negative["index"] == 1
    assert rep.negative["end_to_end"] == 0
    assert rep.index.median == -5.0
    assert any("index" in w and "clock skew" in w for w in rep.warnings)


def test_measure_skips_docs_missing_timestamps():
    events = [
        _event("2026-07-06T12:00:00Z"),  # no ingested/created -> skipped
        {"event.ingested": "2026-07-06T12:00:10Z"},  # no @timestamp -> skipped
        _event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:05Z"),  # usable
    ]
    rep = il.measure(events, slo_seconds=300)
    assert rep.total == 3
    assert rep.skipped == 2
    assert rep.end_to_end.count == 1


def test_measure_within_slo_false_when_no_data():
    rep = il.measure([], slo_seconds=300)
    assert rep.end_to_end is None
    assert rep.slo_stats is None
    assert rep.within_slo is False


# --- NDJSON parsing -------------------------------------------------------

def test_parse_ndjson_counts_malformed():
    lines = ['{"a": 1}', "", "  ", "not json", "[1,2,3]", '{"b": 2}']
    records, malformed = il.parse_ndjson(lines)
    assert len(records) == 2  # two dicts
    assert malformed == 2  # "not json" + the JSON array (not a dict)


# --- CLI / main -----------------------------------------------------------

def test_main_non_utf8_input_returns_2_not_breach():
    # Regression: a non-UTF-8 file must NOT crash or read as exit 1 (=breach).
    with tempfile.NamedTemporaryFile("wb", suffix=".ndjson", delete=False) as handle:
        handle.write(b'{"@timestamp":"2026-07-06T12:00:00Z"}\n\xff\xfe garbage\n')
        path = handle.name
    try:
        assert il.main([path]) == 2
    finally:
        os.unlink(path)


def test_main_all_fallback_fails_closed():
    with tempfile.NamedTemporaryFile("w", suffix=".ndjson", delete=False, encoding="utf-8") as handle:
        handle.write('{"@timestamp":"2026-07-06T12:00:00Z","event.created":"2026-07-06T12:00:02Z"}\n')
        path = handle.name
    try:
        assert il.main([path]) == 1  # no event.ingested -> unconfirmed -> non-zero
        assert il.main(["--allow-fallback", path]) == 0  # opt in -> lower bound passes
    finally:
        os.unlink(path)


# --- rendering ------------------------------------------------------------

def test_render_md_marks_breach():
    rep = il.measure([_event("2026-07-06T00:00:00Z", ingested="2026-07-06T06:34:22Z")], slo_seconds=300)
    md = il.render_md(rep)
    assert "23,662 s (breach)" in md
    assert "| Within 300 s SLO? | ✗ | ✗ |" in md


def test_render_text_pass():
    rep = il.measure([_event("2026-07-06T12:00:00Z", ingested="2026-07-06T12:00:05Z")], slo_seconds=300)
    text = il.render_text(rep)
    assert "PASS" in text
    assert "end-to-end" in text


def _run_standalone() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    failures = 0
    for test in tests:
        try:
            test()
            print(f"  PASS {test.__name__}")
        except AssertionError as exc:
            failures += 1
            print(f"  FAIL {test.__name__}: {exc}")
        except Exception as exc:  # noqa: BLE001 - surface any unexpected error
            failures += 1
            print(f"  ERROR {test.__name__}: {type(exc).__name__}: {exc}")
    print(f"\n{len(tests) - failures}/{len(tests)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(_run_standalone())
