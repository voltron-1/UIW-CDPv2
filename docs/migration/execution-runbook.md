# UIW-CDP → Security Onion 3.1 — Migration Execution Runbook

**Repo of record:** `voltron-1/UIW-CDPv2` — docs, scaffold, migration code, **and** the issue board all live here. There is no second repo.
**Target platform:** Security Onion 3.1.0-20260528, Standalone, ISO install (Oracle Linux 9 baked in), separate hardware
**Workstation:** Dragon-Zord (WSL2 Ubuntu) — hosts docs, integration code, CI. *Never* hosts the grid.
**Owners:** Tommy (Lead Architect) · Sterling Garnett (Security Analyst) · Ishmael Pendleton (Network Engineer)

> This runbook starts **after** the scaffold prompt has run and the `feat/so-migration-scaffold` PR is open. It carries you from "scaffold exists" to "old ELK decommissioned, issues burned down." Work the phases in order. A gate failure means stop and fix, not proceed.

**Ownership tags:** `[CC]` = executable by Claude Code · `[HUMAN]` = Tommy/Sterling/Ishmael performs it; Claude Code only records the result. Untagged items in Phases 1–5 default to `[HUMAN]` on hardware, `[CC]` in the repo.

**Canonical paths (this repo):**

| Artifact | Path |
|---|---|
| This runbook | `docs/migration/execution-runbook.md` |
| ADR | `docs/adr/ADR-001-security-onion-migration.md` |
| Integration inventory | `docs/migration/integration-inventory.md` |
| SO install runbook | `docs/migration/so-install-runbook.md` |
| Gate evidence | `docs/migration/evidence/phase-N.md` (one per phase) |
| Sigma migration notes | `detections/MIGRATION_NOTES.md` |

**Burn-down semantics:** an issue "burns down" at a gate when its evidence is complete there; the actual GitHub close happens in the Phase 5 sweep. The **Quick issue-to-phase index** at the bottom is the canonical issue list — per-phase text references it rather than repeating numbers.

---

## Golden rules (read once, hold for the whole migration)

1. **Parallel-run, never big-bang.** The old ELK stack stays *live* until SO has proven telemetry + detection parity. Decommission happens only in Phase 5, only after a passing gate, only after a final snapshot.
2. **The custom layer is the capstone.** SO replaces the *pipeline* (Zeek→Filebeat→Logstash→ES→Kibana). The SOAR agent, HDI orchestrator, Ollama layer, four-gate Sigma CI, and `slo_metrics.py` **survive and re-point** — they are the original contribution, so they get re-integrated, not rebuilt.
3. **Least-privilege, always.** Re-pointed components get a **dedicated** ES service account mirroring SO's `auth.sls` pattern — never `so_elastic`.
4. **Every gate produces evidence, recorded in `docs/migration/evidence/phase-N.md`** — command output, screenshots by filename, issue links. That evidence *is* the capstone demo.
5. **Committed means pushed.** Every commit is pushed to origin in the same work session — local-only commits are invisible to collaborators, to CI, and to any agent reading remote state, and divergence between local and origin has already cost this project a debugging cycle. `git push` immediately follows `git commit`; a session never ends with unpushed work.

---

## Phase 0 — Land the scaffold & pre-flight (Dragon-Zord, ~half a day)

**Goal:** scaffold merged, planning docs complete with zero TODOs, clean rollback point frozen. Nothing on hardware yet.

**0.0 — Path normalization `[CC]`**
- [ ] Create `docs/migration/` and `docs/migration/evidence/` if absent
- [ ] Move `docs/integration-inventory.md` → `docs/migration/integration-inventory.md` if the scaffold placed it at the old path
- [ ] Create `docs/migration/so-install-runbook.md` from template if absent (sections: Target Host, NIC Layout, HOME_NET, ISO Source & Verification — each with a TODO placeholder)
- [ ] Confirm this runbook lives at `docs/migration/execution-runbook.md`

**0.1 — PR review `[CC]` proposes, `[HUMAN]` confirms**
- [ ] Open the `feat/so-migration-scaffold` PR diff
- [ ] Confirm additive-only: no modified lines in the existing top-level `README.md`
- [ ] Confirm `reference/` is gitignored (not tracked)
- [ ] Diff the created tree against the scaffold spec — flag missing or extra paths
- [ ] Leave the PR open until 0.2–0.6 are done

**0.2 — ADR-001 `[CC]` drafts, `[HUMAN]` approves wording**
- [ ] License Posture section: Elastic License 2.0 (ELv2) — source-available, not GPL/OSI; permitted lab/capstone use; prohibited managed-service resale and license-key circumvention
- [ ] Free-vs-Pro Boundary section: MCP Server, External API, Reports, OIDC, Onion AI are Pro-only; our Ollama/SOAR/orchestrator layer is the free-tier equivalent = the capstone's original contribution
- [ ] Decision statement: why SO, what's replaced (pipeline), what's retained (custom layer)
- [ ] Consequences (provisional — updated with actuals in Phase 5)
- [ ] Cross-reference issue **#150 (D-38)** so issue and doc point at each other
- [ ] Verify zero TODO/TBD strings remain

**0.3 — Integration inventory `[CC]` drafts, Sterling reviews**
- [ ] One row per component touching ES/Kibana/Logstash today: Flask SOAR Response Agent, HDI/self-critique orchestrator (Network Inspection spoke), `slo_metrics.py`, `weekly_ciso_report.py`, each dashboard/saved-object set
- [ ] Fill *current method* for every row; leave *SO target method* empty (Phase 4)

**0.4 — SO install runbook values `[HUMAN]` (Ishmael + Tommy) supply, `[CC]` records**
- [ ] Target host spec (make/model or VM spec)
- [ ] NIC layout: which interface is management, which is monitor
- [ ] Confirm the monitor NIC's SPAN/mirror source is defined and reachable (Ishmael)
- [ ] HOME_NET ranges (lab subnets, CIDR)
- [ ] Exact ISO/KEYS/signature URLs for `3.1.0-20260528`
- [ ] Verify zero TODO strings remain — required before any Phase 1 hardware work

**0.5 — Issue board labeling `[CC]`, read-before-write**
- [ ] Confirm `gh` access to `voltron-1/UIW-CDPv2`
- [ ] Read actual current label state — never assume from this document
- [ ] Create labels if missing: `so-migration:obviates`, `so-migration:reduces`, `so-migration:decision`
- [ ] Apply per the index table: obviates (24), reduces (17), decision (#102, #149)
- [ ] Spot-check 2–3 labeled issues before batch-applying the rest

**0.6 — Freeze checkpoint / D-37 `[HUMAN]` snapshots, `[CC]` records**
- [ ] Confirm snapshot mechanism (hypervisor VM snapshot vs. manual export)
- [ ] Take it — or export Kibana saved objects, all Sigma rules, Logstash pipelines, and a representative ES index sample
- [ ] **Verify restorability** — test-restore to scratch if feasible; at minimum confirm the artifact is complete and non-corrupt
- [ ] Record snapshot ID/timestamp + restorability evidence in `evidence/phase-0.md`
- [ ] Note on issue **#149** that this snapshot replaces the originally-scoped in-place ELK→SO migration

**0.7 — Merge `[CC]` proposes, `[HUMAN]` executes go-ahead**
- [ ] Confirm 0.0–0.6 complete, then propose merging the PR to `main` and wait for explicit approval

**Gate 0:** scaffold on `main` · zero unfilled TODOs across ADR-001 / integration-inventory / so-install-runbook · ELK snapshot exists with restorability verified · `evidence/phase-0.md` written.

---

## Phase 1 — Stand up the SO grid (on hardware, ~1 day + burn-in)

**Goal:** a healthy Standalone grid ingesting its own default telemetry. Nothing custom yet.

- [ ] `[HUMAN]` Verify the ISO checksum and GPG signature against Security Onion's published values; record output in `evidence/phase-1.md`
- [ ] `[HUMAN]` Boot the verified SO 3.1 ISO (it installs Oracle Linux 9 + Security Onion together) and complete the setup wizard: choose **Standalone**, assign the **monitor interface** (the SPAN/mirror destination Ishmael provides) distinct from the management interface, set HOME_NET per `so-install-runbook.md`
- [ ] Let the grid finish provisioning, then validate:
  - [ ] `sudo so-status` — all services green
  - [ ] The SOC console (backed by Kibana / Elasticsearch 9.3.3) reachable over HTTPS; login works
  - [ ] Default **Zeek** and **Suricata** telemetry landing — check SOC → Grid and the Hunt/Dashboards views for live events
- [ ] `[CC]` Record the five named ES service accounts and the `auth.sls` location on the manager (`/opt/so/saltstack/local/pillar/elasticsearch/auth.sls`) in the inventory. These get mirrored — never reused — in Phase 4.

**Gate 1:** `so-status` clean · SOC console up · SO's own sensors producing events into Elasticsearch · old ELK still running untouched in parallel.

**Rollback:** the grid is standalone and additive — a Phase 1 failure touches nothing on the old stack. Rebuild or re-run setup.

---

## Phase 2 — Telemetry cutover & parity (network + endpoints, ~2–4 days)

**Goal:** the data SO collects natively matches or beats what the old pipeline collected, in ECS.

- [ ] `[HUMAN]` With Ishmael: confirm the switch SPAN/mirror feeds the SO monitor NIC (what old issue **#5** did manually — SO now owns the sensor side)
- [ ] Enroll lab endpoints into SO's **Elastic Agent** (via Fleet) for host telemetry — process + command line, identity/auth, PowerShell (**#6**, satisfies **#125/D-13** natively)
- [ ] Spot-check ECS normalization: a Zeek conn event and a Windows process event show ECS field names (**#123/D-11** — verify SO already does what that issue asked you to build)
- [ ] Confirm sensor-health/heartbeat in the Grid view — dead-shipper alarms are native (**#126/D-14**)
- [ ] **Parity check:** for a fixed window, run the same activity (benign Nmap sweep, SSH login) and confirm SO sees at least what old-ELK saw; log deltas in the inventory
- [ ] **Re-measure ingest lag.** The old stack's ingest-lag SLO breach (~23,662s vs 300s target) undermined the MTTD claim. Measure SO's end-to-end lag on the same event class — the delta is capstone evidence for `evidence/phase-2.md`

**Gate 2:** SO telemetry ≥ old-ELK telemetry for the parity window · ECS confirmed · heartbeat visible · ingest lag within SLO · **old ELK still live**.

**Burns down at this gate:** per index table, Phase 2 row.

---

## Phase 3 — Detection migration (Dragon-Zord + SO, ~3–5 days)

**Goal:** the Sigma rules live on SO, fire correctly, and the four-gate CI targets the grid.

- [ ] `[CC]` Inventory + classify every Sigma rule (**#19 / #33**): keep / retire / needs-remap
- [ ] `[CC]` Triage ECS field mappings in `detections/MIGRATION_NOTES.md` — anything that assumed old Logstash field names
- [ ] **Decision point — #102 `[HUMAN]` decides:** retire the custom `translate_rules.py` in favor of SO's native Sigma deploy path (`/nsm/rules/custom-local-repos/local-sigma`, declared in `salt/soc/defaults.yaml`)? Yes → close #102 as obviated. Keeping the translator → its risk_score/enabled/sub-technique bugs remain real and #102 stays open.
- [ ] Fix platform-independent rule-content bugs — **#103** (RDP-hijack rule mis-tagged T1574 → should be T1563.002)
- [ ] Deploy rules to the local-sigma repo path on the grid
- [ ] **Retarget the four-gate Sigma CI** (lint → TP gate → FP gate → re-emulation regression) at SO's Elasticsearch; the FP gate reuses the count-query pattern against SO indices
- [ ] Validate: each kept rule fires against live SO data — one targeted trigger per rule

**Gate 3:** ATT&CK coverage matrix rebuilt against SO · kept rules confirmed firing · four-gate CI green against the grid.

**Burns down at this gate:** per index table, Phase 3 row.

---

## Phase 4 — Re-point the custom layer (Dragon-Zord ↔ SO, ~1 week)

**Goal:** the capstone's original contribution runs against SO end-to-end.

- [ ] **Create a dedicated least-privilege ES service account** on the grid, mirroring the `auth.sls` pattern — scoped read (plus only the write it needs) per component; document in the inventory. **Not** `so_elastic`.
- [ ] Re-point the **Flask SOAR Response Agent** (HMAC-SHA256 endpoints, three-tier action matrix) at SO's ES surface; preserve the **Human-of-Record** rule — explicit analyst approval before any containment executes
- [ ] Re-point the **HDI / self-critique orchestrator** (+ Network Inspection spoke, Redis pub/sub channels, two mandatory self-critique passes) at SO's data streams
- [ ] Re-point **`slo_metrics.py`** at SO indices — and fix **#91** in the same pass: TLS verification on, new least-priv account, LLM egress governance honored
- [ ] Confirm the **Ollama** layer still holds the **Telemetry-Stays-on-Campus** invariant against the SO data path
- [ ] **End-to-end dry run:** attack → SO detects → alert → SOAR triage → Ollama adjudication → Human-of-Record approval → containment; trace one full path into `evidence/phase-4.md`

**Gate 4:** a live attack produces a measurable SOC outcome through *your* pipeline · human-in-the-loop validated · least-priv confirmed · Ollama invariant intact.

**Burns down at this gate:** per index table, Phase 4 row (inventory rows close; #91, #121 re-scope — the roles to map student access onto now exist in SO's Elasticsearch/Kibana security model).

---

## Phase 5 — Validate, burn down, decommission (~3–5 days)

**Goal:** prove the whole thing with the adversary loop, close the board, retire old ELK.

- [ ] Run **Adversary-in-a-Box** through a full named-actor kill-chain against the SO-backed lab (**#40–#43**), including assume-breach
- [ ] Confirm the **telemetry-presence check** between emulate and detect (**#136/D-24**) and **pipeline-blinding** detection — cleared logs / killed agent (**#139/D-27**) — fed by SO's grid heartbeat + Windows 1102 + Elastic Agent/Fleet status
- [ ] `[CC]` **Close the obviated set (24)** with the obviated template, each attributed to the SO migration + ADR-001 — per index table
- [ ] `[CC]` **Re-scope the reduced set (17)** to their residuals — keep open, don't close — per index table
- [ ] **Resolve the decision-gated (2):** #102 per the Phase 3 call; #149 close as superseded (the in-place ELK→SO migration it guarded no longer happens; the Phase 0 snapshot covered the real need)
- [ ] **#86 — the one that survives `[HUMAN]` executes:** the committed `elastic` superuser password is in **git history** regardless of stack. Scrub it (`git filter-repo` / BFG), force-push per team process, **rotate** the credential. History rewrite and force-push are never delegated. Close only after both.
- [ ] `[HUMAN]` **Decommission old ELK** — only now, only after parity held through Phases 2–4, with one final snapshot before teardown
- [ ] Update ADR-001 consequences with actuals; finalize the recover/rebuild runbooks (**#148/D-36**, **#151/D-39**) against the now-real grid

**Gate 5 (capstone demo):** end-to-end — attack → SO alert → AI analysis → analyst response — on the live grid, with the burn-down board and the ingest-lag before/after in `evidence/phase-5.md`.

---

## Quick issue-to-phase index (canonical)

| Phase | Closes on gate | Reduces / re-scopes | Decides |
|---|---|---|---|
| 2 | #5 #6 #84 #85 #90 #99 #100 #101 #109 #110 #123 #124 #125 #126 #128 | #3 #20 #21 #29 #31 | — |
| 3 | #8 #26 #27 #28 #95 #103 #111 | #36 | #102 |
| 4 | (inventory rows) | #91 #121 | — |
| 5 | #4 #97 #98 (final sweep of all obviated) | #86 #92 #112 #133 #136 #139 #147 #148 #151 | #149 |

*Label mapping for 0.5: obviated set (24) = every issue in the "Closes on gate" column plus the Phase 5 sweep trio; reduced set (17) = every issue in the "Reduces" column; decision = #102, #149. #86 never auto-closes — history scrub + rotate is a standing task even after SO owns credentials.*

---

## What to do if a gate fails

- **Gate 1/2 (telemetry):** old ELK is still live — you lose nothing. Fix the sensor/interface/agent issue on SO and re-validate. Never proceed to detection work on a grid that isn't seeing data.
- **Gate 3 (detection):** rules that won't fire are almost always ECS field-mapping drift — check `detections/MIGRATION_NOTES.md` mappings before touching rule logic.
- **Gate 4 (custom layer):** if the SOAR/orchestrator can't read SO, check the least-priv account's index permissions first. Auth scope is the usual culprit.
- **Gate 5:** never decommission on a failed gate. The parallel ELK stack + Phase 0 snapshot are the rollback the entire way through.
