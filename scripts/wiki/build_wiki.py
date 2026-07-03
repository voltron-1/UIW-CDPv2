#!/usr/bin/env python3
"""Generate GitHub wiki pages from the migration docs.

Deterministic, stdlib-only. Reads docs/migration/ and docs/adr/, writes
wiki-ready markdown into an output directory. Run from the repo root:

    python3 scripts/wiki/build_wiki.py --out wiki-build
"""

import argparse
import os
import re
import sys

# repo doc path -> wiki page name (page name == filename without .md)
MIRRORED = {
    "docs/migration/README.md": "Migration-Plan",
    "docs/migration/work-breakdown.md": "Work-Breakdown",
    "docs/migration/salt-map.md": "Salt-Map",
    "docs/migration/integration-inventory.md": "Integration-Inventory",
    "docs/adr/ADR-001-security-onion-migration.md": "ADR-001-Security-Onion-Migration",
}

# relative link text as it appears inside the docs -> wiki page name
LINK_REWRITES = {
    "README.md": "Migration-Plan",
    "work-breakdown.md": "Work-Breakdown",
    "salt-map.md": "Salt-Map",
    "integration-inventory.md": "Integration-Inventory",
    "../adr/ADR-001-security-onion-migration.md": "ADR-001-Security-Onion-Migration",
}

# Tolerates a footnote marker on the ID (T2*) and -- in place of the em-dash.
TASK_RE = re.compile(r"^#### (P\d+\.WP\d+\.T\d+)\*? *(?:—|--) *(.+)$")
PHASE_RE = re.compile(r"^## (P\d+) *(?:—|--) *(.+)$")
FIELD_RE = re.compile(r"^- \*\*(Objective|Linked issue|Log):\*\* (.*)$")


def warn(msg):
    print(f"warn: {msg}", file=sys.stderr)


def parse_wbs(text):
    """Return list of phases: {id, title, tasks:[{id, title, objective, issues, log}]}."""
    phases = []
    task = None
    for line in text.splitlines():
        m = PHASE_RE.match(line)
        if m:
            phases.append({"id": m.group(1), "title": m.group(2), "tasks": []})
            task = None
            continue
        m = TASK_RE.match(line)
        if m and phases:
            task = {"id": m.group(1), "title": m.group(2),
                    "objective": "", "issues": "", "log": ""}
            phases[-1]["tasks"].append(task)
            continue
        # A task-looking heading that didn't parse means WBS format drift:
        # the task would silently vanish from every count. Make it visible.
        if line.startswith("#### "):
            warn(f"unparsed task heading dropped: {line!r}")
        m = FIELD_RE.match(line)
        if m and task is not None:
            key = {"Objective": "objective", "Linked issue": "issues",
                   "Log": "log"}[m.group(1)]
            task[key] = m.group(2).strip()
    for ph in phases:
        for t in ph["tasks"]:
            if not t["objective"]:
                warn(f"task {t['id']} has no parsed Objective (format drift?)")
    return phases


def task_status(task):
    return "✅ Done" if task["log"].startswith("✅") else "Open"


def cell(value):
    """Make a value safe for a markdown table cell; blank out em-dash placeholders."""
    if value in ("", "—"):
        return ""
    return value.replace("|", "\\|")


def rewrite_links(text):
    # Known limitation: plain substring replace anchored on "(target)" — not
    # code-block aware and won't catch path-prefixed forms like
    # (docs/migration/README.md). Fine for the current docs; revisit if links drift.
    for target, page in LINK_REWRITES.items():
        text = text.replace(f"({target})", f"({page})")
        text = text.replace(f"({target}#", f"({page}#")
    return text


def build_home(phases, sha):
    lines = [
        "# UIW Cyber Defense Platform — Wiki",
        "",
        "Auto-generated from the repo docs by `scripts/wiki/build_wiki.py`",
        "(workflow: `wiki-sync.yml`). **Do not edit these generated pages by",
        "hand** — changes land via the repo. Hand-written pages with other",
        "names are left untouched.",
        "",
        "## Security Onion 3.1 migration progress",
        "",
        "| Phase | Done / Total |",
        "|---|---|",
    ]
    for ph in phases:
        done = sum(1 for t in ph["tasks"] if t["log"].startswith("✅"))
        lines.append(f"| {ph['id']} — {ph['title']} | {done} / {len(ph['tasks'])} |")
    lines += [
        "",
        "## Pages",
        "",
        "- [[Migration-Status]] — live per-task dashboard",
        "- [[Migration-Plan]] — five-phase plan, pinned reference tag, roles",
        "- [[Work-Breakdown]] — full Phase → WP → Task decomposition",
        "- [[Integration-Inventory]] — ES/Kibana/Logstash touchpoints",
        "- [[Salt-Map]] — where relevant config lives in the SO reference",
        "- [[ADR-001-Security-Onion-Migration]] — the migration decision record",
        "",
        f"_Generated from commit `{sha}`._",
    ]
    return "\n".join(lines) + "\n"


def build_status(phases, sha):
    lines = ["# Migration Status", "",
             "Live dashboard generated from [[Work-Breakdown]]. Status is",
             "derived from each task's `Log:` line (✅ prefix = done).", ""]
    for ph in phases:
        done = sum(1 for t in ph["tasks"] if t["log"].startswith("✅"))
        lines += [f"## {ph['id']} — {ph['title']} ({done}/{len(ph['tasks'])})", "",
                  "| Task | Objective | Issues | Status | Log |",
                  "|---|---|---|---|---|"]
        for t in ph["tasks"]:
            lines.append(
                f"| {t['id']} | {cell(t['objective'])} | {cell(t['issues'])} | "
                f"{task_status(t)} | {cell(t['log'])} |")
        lines.append("")
    lines.append(f"_Generated from commit `{sha}`._")
    return "\n".join(lines) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="output directory")
    args = ap.parse_args()

    wbs_path = "docs/migration/work-breakdown.md"
    if not os.path.exists(wbs_path):
        sys.exit(f"error: {wbs_path} not found (run from the repo root)")
    with open(wbs_path, encoding="utf-8") as f:
        phases = parse_wbs(f.read())
    if not phases:
        sys.exit("error: no phases parsed from work-breakdown.md")

    sha = os.environ.get("GITHUB_SHA", "local")[:12]
    os.makedirs(args.out, exist_ok=True)

    pages = {"Home.md": build_home(phases, sha),
             "Migration-Status.md": build_status(phases, sha)}
    for src, page in MIRRORED.items():
        with open(src, encoding="utf-8") as f:
            pages[page + ".md"] = rewrite_links(f.read())

    for name, content in pages.items():
        with open(os.path.join(args.out, name), "w", encoding="utf-8") as f:
            f.write(content)
        print(f"wrote {args.out}/{name}")


if __name__ == "__main__":
    main()
