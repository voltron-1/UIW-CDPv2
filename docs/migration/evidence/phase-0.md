# Phase 0 Evidence

Gate 0 exit criteria (per `execution-runbook.md`): scaffold on `main` · zero
unfilled TODOs across ADR-001 / integration-inventory / so-install-runbook ·
ELK snapshot exists with restorability verified · `evidence/phase-0.md`
written.

**Gate 0 status: advancing with one flagged gap (0.4), by explicit decision
2026-07-03.** 0.4's TODOs are real, unfilled, and expected to stay that way
until Tommy/Ishmael supply target-host/NIC/HOME_NET/ISO values — that gap
blocks Phase 1 (hardware) specifically, not the rest of the migration.
Everything else in the exit criteria is met.

**Merge approval (Tommy, 2026-07-03):** approved to merge PR #155 with the
0.4 exception — "zero unfilled TODOs except 0.4 (so-install-runbook
values), deferred pending school hardware allocation." This is the policy
decision that the 0.4 gap is an acceptable, tracked deferral, not a defect.
It does not by itself authorize the merge to execute — per rule 3, that
still requires Tommy's separate, explicit confirmation after reviewing the
PR as updated.

## 0.0 — Path normalization

- `docs/migration/` and `docs/migration/evidence/` created.
- `docs/migration/integration-inventory.md` was already at the current path
  (scaffold never placed it at the old `docs/integration-inventory.md`) — no
  move needed.
- `docs/migration/so-install-runbook.md` created from template, sections
  Target Host / NIC Layout / HOME_NET / ISO Source & Verification, each with
  a TODO placeholder (see 0.4).
- This runbook confirmed at `docs/migration/execution-runbook.md`.
- One deviation found and fixed: the Sigma migration notes were nested at
  `migration/detections/MIGRATION_NOTES.md`; moved to `detections/` to match
  the runbook's own canonical-paths table, all cross-references updated.

## 0.1 — PR review

- Additive-only confirmed: `git show d6cd8e7 --stat` shows zero lines
  touched in the top-level `README.md`.
- `reference/` confirmed gitignored (`git check-ignore` passes), never
  tracked.
- Tree diffed against the scaffold spec: one deviation (the
  `migration/detections/` nesting above), fixed.
- **Deviation from the runbook's assumption:** PR #154 was already
  **merged** (`mergedAt` 2026-07-02T17:07:04Z, `mergedBy` voltron-1) by the
  time this session reached 0.1 — it merged only the first 10-file scaffold
  commit. "Leave the PR open until 0.2–0.6" was therefore not literally
  possible; all subsequent Phase 0 commits landed on `feat/so-migration-scaffold`
  with no open PR. A new PR is proposed at 0.7 to land them.

## 0.2 — ADR-001

- License Posture, Free-vs-Pro Boundary, Decision, Consequences sections all
  present in `docs/adr/ADR-001-security-onion-migration.md`.
- Gap found and fixed: Free-vs-Pro list was missing **OIDC**; added
  (Pro-only list now reads MCP Server, External API, Reports, OIDC, Onion AI).
- Cross-references issue **#150 (D-38)**.
- Zero TODO/TBD strings (`grep -inE "TODO|TBD"` — clean).

## 0.3 — Integration inventory

- One row per component in `docs/migration/integration-inventory.md`:
  Flask SOAR Response Agent, HDI/self-critique orchestrator, Ollama layer,
  `slo_metrics.py`, `weekly_ciso_report.py` (added — the runbook lists it
  explicitly, the original scaffold template didn't have it as its own row),
  Kibana dashboards/saved objects, Sigma detection rules/CI, legacy
  Logstash configs, legacy Filebeat shippers.
- *Current method* filled for every row from actual source inspection (not
  invented) — auth mechanism, TLS verification state, and file paths cited
  per component. *SO target method* correctly left empty for Phase 4.
- Notable finding surfaced during this step: **the HDI/self-critique
  orchestrator has no implementation anywhere in this repo** — referenced
  only in planning docs. Phase 4's "re-point the orchestrator" currently
  assumes code that doesn't exist yet.

## 0.4 — SO install runbook values — OPEN

- `docs/migration/so-install-runbook.md` exists with the required sections,
  but all 5 value groups remain TODO: target host spec, NIC layout,
  monitor-NIC SPAN/mirror confirmation, HOME_NET CIDR ranges, exact
  ISO/KEYS/signature URLs for `3.1.0-20260528`.
- Explicitly deferred by Tommy (2026-07-02) — no placeholders invented, per
  rule 6. **This blocks Phase 1 (hardware work) only; it does not block
  Gate 0 advancement or opening the follow-up PR.**

## 0.5 — Issue board labeling

- `so-migration:obviates` / `reduces` / `decision` labels already existed
  and were already fully applied before this session touched them — no
  action taken, verified only.
- Verified via `gh` (not from memory or the runbook's tables), twice, on two
  different dates: **24** issues `obviates`, **17** issues `reduces`,
  `decision` on exactly `#149` and `#102` — matches the runbook's index
  table exactly, including the deliberate, correct exclusion of `#103`
  (a rule-content bug fix, not something the migration obviates).

## 0.6 — Freeze checkpoint / D-37

**Snapshot mechanism:** Elasticsearch Snapshot Lifecycle Management (SLM), not
a VM snapshot. The legacy ELK stack runs in a separate sibling repo,
`voltron-1/Suburban_SOC` (local checkout: `~/projects/Suburban-SOC`), which
already had a filesystem snapshot repository and daily SLM policy configured
(`configs/elasticsearch/apply-lifecycle.sh`, `ilm/snapshot-repository.json`,
`ilm/slm-policy.json`) — this checkpoint uses that existing mechanism rather
than building a new one.

**Action taken (2026-07-03, this session):**
1. Brought up only the containers needed for the checkpoint —
   `docker compose up -d elasticsearch lifecycle` in
   `Suburban-SOC/scripts/setup/` (auto-resolves the `setup` cert-gen
   dependency). Kibana, Logstash, the AI agent, and the hive-mind broker were
   left down — out of scope for an ES-only snapshot.
2. `soc_lifecycle` re-applied (idempotent) the snapshot repo, SLM policy, ILM
   policies, and index templates — all four steps returned HTTP 200.
3. Triggered an on-demand snapshot: `apply-lifecycle.sh --snapshot-now` →
   `POST _slm/policy/suburban-soc-daily-snapshots/_execute` → HTTP 200.
4. Stopped `elasticsearch` again afterward (`docker compose stop
   elasticsearch`) — Suburban-SOC returned to its pre-session state (only
   `zeek-host-capture` running).

**Result:**

| Field | Value |
|---|---|
| Snapshot | `suburban-soc-snap-2026.07.03-jv7kixdrrw-gvzsn4l3tjq` |
| Repository | `suburban-soc-snapshots` (fs, location `suburban-soc`) |
| State | `SUCCESS` |
| Shards | 30 / 30 successful, 0 failed |
| Indices captured | 30 (`logstash-security-*`, `soar-actions-*`, `soc-controls`, `soc-deploys`, `soc-audit-*` and their data streams) |
| Timestamp | 2026-07-03T01:56:32Z |

Nine earlier nightly snapshots (2026-06-11 through 2026-06-29) are also
present in the repository, all `SUCCESS` — the SLM policy has been running
reliably; this checkpoint is not the first evidence of restorability, just
the first one taken deliberately as a migration freeze point.

**Restorability — actually verified, not assumed:**
- Live `soc-controls` index: 35 documents (`_count`)
- Restored `soc-controls` from the above snapshot into a scratch index
  (`rename_pattern`/`rename_replacement`, so the live index was never
  touched): `POST _snapshot/suburban-soc-snapshots/<snapshot>/_restore` →
  restored index also shows 35 documents — exact match
- Scratch index deleted after verification (`DELETE
  restore-verify-soc-controls` → confirmed gone, HTTP 404 on re-check)

**Per the runbook:** this snapshot is the honest version of issue **#149** —
not an in-place ELK→OS migration (which #149 originally scoped), but the
rollback point before the parallel SO grid is built. Noted on #149 directly
(see comment, 2026-07-03). #149 stays open — it's decision-gated and closes
in the Phase 5 sweep, not here.

## 0.7 — Merge

Not yet proposed as of this evidence snapshot. PR #154 already merged the
initial scaffold; a new PR from `feat/so-migration-scaffold` is the proposed
vehicle for everything since (0.0–0.6 work in commits `1eef0d4`, `03dca15`,
`518413e`, plus golden rule 5 in the runbook itself). Per rule 3, opening
that PR is not a merge and proceeds without a separate go-ahead; merging it
requires Tommy's explicit approval regardless of how clean the checklist
looks.

## Post-merge addendum — CI failure on db11e45 (2026-07-03)

After PR #155 merged (`db11e45`), `gh run list --branch main --limit 5`
showed **Wiki Sync** failed on that commit while **CodeQL Advanced**
succeeded on the same commit; **automate-infra-board** did not run
(`workflow_dispatch`-only, not push-triggered — not implicated).

**Cause, from `gh run view 28634311655 --log-failed`:** the failure is
inside `actions/checkout`'s own post-checkout credential-cleanup step, not
in the wiki-sync logic itself:

```
fatal: No url found for submodule path 'wiki-temp' in .gitmodules
##[error]The process '/usr/bin/git' failed with exit code 128
```

Chain of cause:
1. `wiki-temp` is a pre-existing broken git submodule reference in the repo
   tree (`git ls-files -s` shows it as a gitlink, mode `160000`, commit
   `ccdb45af28d92d9c71360b1932f4c42fe6b137dd`) with **no `.gitmodules`
   file** anywhere in the repo defining its URL. Predates this session's
   work entirely.
2. `actions/checkout` only enumerates submodules during its post-checkout
   credential-removal cleanup, which only runs when `persist-credentials:
   false` is set — unconditionally, regardless of the `submodules:` input.
3. `wiki-sync.yml`'s checkout step sets `persist-credentials: false` — a
   hardening fix added earlier this session per the security-auditor's
   finding. That's what triggers the cleanup, which hits the broken
   `wiki-temp` gitlink and fails before checkout completes.
4. CodeQL's checkout step uses plain `actions/checkout@v4` with no `with:`
   overrides (`persist-credentials` defaults to `true`), so it never runs
   that cleanup and never touches submodules — same commit, same broken
   repo state, no failure.

**Net effect:** an earlier security fix in this session surfaced a
pre-existing, unrelated repo defect. The wiki-sync automation's actual
logic (the Python generator, the wiki clone/publish) never got a chance to
run.

**Fix: proposed, not yet applied.** Reported to Tommy for a decision between
(1) removing the broken `wiki-temp` gitlink outright — the root-cause fix,
since it's empty/unresolvable and functionally superseded by the wiki-sync
automation itself — or (2) reverting `persist-credentials: false` on just
this workflow's checkout step as a narrower fallback. Awaiting go-ahead per
rule 3 before touching either the workflow file or tracked repo content.

**Resolved (2026-07-03):** Tommy chose option 1. Removed the broken
`wiki-temp` gitlink (`git rm wiki-temp`) — root-cause fix, `persist-
credentials: false` stays in place on `wiki-sync.yml`. Verified before
removal: empty on disk, gitlink at commit `ccdb45af...` with no
`.gitmodules` entry anywhere in the repo, so nothing resolvable was lost.
Next push to `main` re-triggers Wiki Sync; expected green now that
`actions/checkout`'s submodule-cleanup step has nothing broken to trip on.

**Verified fixed (2026-07-03):** PR #194 merged (`806e246`). `Wiki Sync` on
that commit completed `success` in 6s (run `28635383874`) — `actions/
checkout` finished cleanly, no submodule error. The generator built all 6
wiki pages; the run then hit the *separate, already-known* fact that the
GitHub wiki has never been manually initialized (`git clone
...UIW-CDPv2.wiki.git` → "Repository not found") — handled gracefully by
design (`::warning::` + `SKIP_SYNC=1`, exit 0), not a failure. That one-time
manual init (visit the wiki tab, click "Create the first page") is still
outstanding and unrelated to this fix.
