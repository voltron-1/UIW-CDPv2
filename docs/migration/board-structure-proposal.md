# Board Structure Proposal — Security Onion Migration

**Status: PROPOSED. Nothing below has been created in GitHub yet.** This is
step 0.5b's summary for review; creation happens in one `gh` pass only after
explicit approval, per rule 3.

Read against the live board via `gh` on 2026-07-03: 152 existing issues
(#1–#152), all `OPEN`, across 8 existing milestones (`PI-1`…`PI-7`,
`Framework Alignment`) — a separate, pre-existing taxonomy. The six new
phase milestones below are additive alongside those, not a replacement.
None of #1–#152 are touched, duplicated, retitled, or recreated by this
proposal.

Label work is done (`evidence/phase-0.md` §0.5, re-verified live) — no
label creation/application proposed here beyond the new `so-migration:task`
label on the new task issues themselves.

**Numbering:** Phase 0 already has step IDs (0.0–0.7) in the runbook.
Phases 1–5 don't — this proposal extends the same `P<phase>.<n>` convention
to them, numbering each phase's top-level checklist bullets in document
order (sub-bullets under one bullet, e.g. Phase 1's `so-status`/console/
telemetry trio, stay inside that one step's body rather than becoming
separate issues).

**Ownership tags:** applied per the runbook's own stated rule — explicit
`[CC]`/`[HUMAN]` tags where the runbook has them; where untagged, "on
hardware" defaults to `[HUMAN]`, "in the repo" defaults to `[CC]`. Marked
per item below; flagged where the call is genuinely close so it can be
corrected on review.

**Body convention (all task issues):** the step's own checkbox text from
`execution-runbook.md`, reproduced verbatim as the issue body's checklist,
plus an `Evidence for: #N #M` line where the runbook cites specific
existing issue numbers inline for that step (referenced only — never
closed by this proposal). Every task issue: label `so-migration:task`,
milestone = its phase.

---

## Milestones (6)

| # | Title | Description (= gate exit criteria, verbatim from runbook) |
|---|---|---|
| M1 | Phase 0 — Land the scaffold & pre-flight | Gate 0: scaffold on `main` · zero unfilled TODOs across ADR-001/integration-inventory/so-install-runbook (0.4 exception approved 2026-07-03 — see `evidence/phase-0.md`) · ELK snapshot exists with restorability verified · `evidence/phase-0.md` written. |
| M2 | Phase 1 — Stand up the SO grid | Gate 1: `so-status` clean · SOC console up · SO's own sensors producing events into Elasticsearch · old ELK still running untouched in parallel. |
| M3 | Phase 2 — Telemetry cutover & parity | Gate 2: SO telemetry ≥ old-ELK telemetry for the parity window · ECS confirmed · heartbeat visible · ingest lag within SLO · old ELK still live. |
| M4 | Phase 3 — Detection migration | Gate 3: ATT&CK coverage matrix rebuilt against SO · kept rules confirmed firing · four-gate CI green against the grid. |
| M5 | Phase 4 — Re-point the custom layer | Gate 4: a live attack produces a measurable SOC outcome through the pipeline · human-in-the-loop validated · least-priv confirmed · Ollama invariant intact. |
| M6 | Phase 5 — Validate, burn down, decommission | Gate 5 (capstone demo): end-to-end — attack → SO alert → AI analysis → analyst response — on the live grid, with the burn-down board and ingest-lag before/after in `evidence/phase-5.md`. |

---

## Task issues — Phase 0 (milestone M1)

0.5 is **skipped** — already done and verified, nothing left to track.
0.0/0.1/0.2/0.3/0.6/0.7 are already complete; created **OPEN** anyway as a
historical record (not closed here — closing needs separate confirmation
per rule 3), body notes point at the existing evidence.

| ID | Title | Owner/tag | Notes |
|---|---|---|---|
| P0.0 | [P0.0] Path normalization | `[CC]` | Done — evidence: `evidence/phase-0.md` §0.0 |
| P0.1 | [P0.1] PR review | `[CC]`/`[HUMAN]` | Done — PR #155 |
| P0.2 | [P0.2] ADR-001 | `[CC]` drafts/`[HUMAN]` approves | Done — evidence §0.2 |
| P0.3 | [P0.3] Integration inventory | `[CC]` drafts/Sterling reviews | Done — evidence §0.3; flags orchestrator has no implementation |
| **P0.4** | **[P0.4] SO install runbook values** | `[HUMAN]` (Ishmael + Tommy) | **Created OPEN, assigned to Tommy + Ishmael. Body notes: blocks Phase 1 (hardware) only; deferred pending school hardware allocation.** |
| P0.6 | [P0.6] Freeze checkpoint / D-37 | `[HUMAN]` snapshots/`[CC]` records | Done — evidence §0.6; evidence for: #149 |
| P0.7 | [P0.7] Merge | `[CC]` proposes/`[HUMAN]` executes | In progress — PR #155 open, awaiting merge confirmation |

## Task issues — Phase 1 (milestone M2)

| ID | Title | Owner/tag | Evidence for | Notes |
|---|---|---|---|---|
| P1.1 | [P1.1] Verify SO 3.1 ISO checksum + GPG signature | `[HUMAN]` (explicit) | — | Record output in `evidence/phase-1.md` |
| P1.2 | [P1.2] Install SO 3.1 Standalone, complete setup wizard | `[HUMAN]` (explicit) | — | Monitor interface distinct from management; HOME_NET per `so-install-runbook.md` — **depends on P0.4** |
| P1.3 | [P1.3] Validate grid provisioning | `[HUMAN]` (untagged, on hardware) | — | `so-status`, SOC console reachable, default Zeek/Suricata telemetry landing |
| P1.4 | [P1.4] Record the five ES service accounts + auth.sls location | `[CC]` (explicit) | — | Feeds Phase 4's dedicated-account work |

## Task issues — Phase 2 (milestone M3)

| ID | Title | Owner/tag | Evidence for | Notes |
|---|---|---|---|---|
| P2.1 | [P2.1] Confirm switch SPAN/mirror feeds SO monitor NIC | `[HUMAN]` (explicit, with Ishmael) | #5 | |
| P2.2 | [P2.2] Enroll lab endpoints into Elastic Agent/Fleet | `[HUMAN]` (untagged, on hardware) | #6, #125 | |
| P2.3 | [P2.3] Spot-check ECS normalization | `[HUMAN]` (untagged, on hardware — lean CC once grid API access exists) | #123 | |
| P2.4 | [P2.4] Confirm sensor-health/heartbeat in Grid view | `[HUMAN]` (untagged, on hardware) | #126 | |
| P2.5 | [P2.5] Parity check vs. old-ELK | `[HUMAN]` (untagged, on hardware) | — | Log deltas in inventory |
| P2.6 | [P2.6] Re-measure ingest lag | `[HUMAN]` runs/`[CC]` records | — | Old SLO breach was ~23,662s vs 300s target; capstone evidence for `evidence/phase-2.md` |

## Task issues — Phase 3 (milestone M4)

| ID | Title | Owner/tag | Evidence for | Notes |
|---|---|---|---|---|
| P3.1 | [P3.1] Inventory + classify every Sigma rule | `[CC]` (explicit) | #19, #33 | keep/retire/needs-remap |
| P3.2 | [P3.2] Triage ECS field mappings | `[CC]` (explicit) | — | `detections/MIGRATION_NOTES.md` |
| P3.3 | [P3.3] Decision point: retire translate_rules.py? | `[HUMAN]` (explicit decision) | #102 | Yes → #102 obviated; No → stays open, bugs remain real |
| P3.4 | [P3.4] Fix RDP-hijack rule mis-tag | `[CC]` (untagged, repo work) | #103 | T1574 → T1563.002 |
| P3.5 | [P3.5] Deploy rules to local-sigma repo path | `[CC]` lean (untagged — git-based deploy; flag if actually hardware-side) | — | |
| P3.6 | [P3.6] Retarget four-gate Sigma CI at SO's ES | `[CC]` (untagged, repo work) | — | |
| P3.7 | [P3.7] Validate each kept rule fires against live SO data | `[HUMAN]` (untagged, on hardware) | — | One targeted trigger per rule |

## Task issues — Phase 4 (milestone M5)

| ID | Title | Owner/tag | Evidence for | Notes |
|---|---|---|---|---|
| P4.1 | [P4.1] Create dedicated least-priv ES service accounts | `[CC]` lean (demonstrated API-driven pattern on Suburban-SOC this session; flag if grid access differs) | — | Never `so_elastic` |
| P4.2 | [P4.2] Re-point Flask SOAR Response Agent | `[CC]` (untagged, repo work) | — | Preserve Human-of-Record rule |
| P4.3 | [P4.3] Re-point HDI/self-critique orchestrator | `[CC]` (untagged, repo work) | — | **Blocker: no implementation exists anywhere in this repo (0.3 finding) — this step can't start until the orchestrator is built** |
| P4.4 | [P4.4] Re-point slo_metrics.py, fix #91 | `[CC]` (untagged, repo work) | #91 | TLS on, least-priv account, LLM egress governance |
| P4.5 | [P4.5] Confirm Ollama Telemetry-Stays-on-Campus invariant | `[CC]` (untagged, verification) | — | |
| P4.6 | [P4.6] End-to-end dry run | `[HUMAN]`+`[CC]` joint (untagged, live attack/response) | — | Trace into `evidence/phase-4.md` |

## Task issues — Phase 5 (milestone M6)

| ID | Title | Owner/tag | Evidence for | Notes |
|---|---|---|---|---|
| P5.1 | [P5.1] Run Adversary-in-a-Box kill-chain | `[HUMAN]` (untagged, live emulation) | #40–#43 | Including assume-breach |
| P5.2 | [P5.2] Confirm telemetry-presence + pipeline-blinding detection | `[CC]` lean (untagged, API-queryable) | #136, #139 | |
| P5.3 | [P5.3] Close the obviated set | `[CC]` (explicit) — **proposes only; closing needs separate go-ahead per rule 3** | #4 #5 #6 #8 #26 #27 #28 #84 #85 #90 #95 #97 #98 #99 #100 #101 #109 #110 #111 #123 #124 #125 #126 #128 (24, fresh via `gh`) | |
| P5.4 | [P5.4] Re-scope the reduced set | `[CC]` (explicit) — keep open, re-scope only | #3 #20 #21 #29 #31 #36 #86 #91 #92 #112 #121 #133 #136 #139 #147 #148 #151 (17, fresh via `gh`) | |
| P5.5 | [P5.5] Resolve the decision-gated set | `[CC]` proposes/`[HUMAN]` confirms | #102, #149 | #102 per Phase 3 call; #149 close as superseded |
| P5.6 | [P5.6] Scrub + rotate the committed elastic superuser credential | `[HUMAN]` (explicit — "never delegated") | #86 | History rewrite + force-push; close only after both |
| P5.7 | [P5.7] Decommission old ELK | `[HUMAN]` (explicit) | — | Only after parity held through Phases 2–4; final snapshot before teardown |
| P5.8 | [P5.8] Update ADR-001 consequences with actuals | `[CC]` (untagged, repo/doc work) | #148, #151 | Finalize recover/rebuild runbooks |

---

## Totals

- 6 milestones
- 38 task issues (7 in Phase 0 — 0.5 skipped — plus 4+6+7+6+8 across Phases 1–5)
- 0 issues closed, 0 existing issues modified, 0 duplicates

Awaiting approval before any `gh` create calls run.
