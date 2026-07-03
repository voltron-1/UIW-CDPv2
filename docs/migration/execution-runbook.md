# UIW-CDP → Security Onion 3.1 — Migration Execution Runbook

**Repo of record:** `voltron-1/UIW-CDPv2`
**Target platform:** Security Onion 3.1.0-20260528, Standalone, ISO on Oracle Linux 9 (separate hardware)
**Workstation:** Dragon-Zord (WSL2 Ubuntu) — hosts docs, integration code, CI. *Never* hosts the grid.
**Owners:** Tommy (Lead Architect) · Sterling Garnett (Security Analyst) · Ishmael Pendleton (Network Engineer)

> This runbook starts **after** the scaffold prompt has run and the `feat/so-migration-scaffold` PR is open. It carries you from "scaffold exists" to "old ELK decommissioned, issues burned down." Work the phases in order. Do **not** skip a validation gate — a gate failure means stop and fix, not proceed.

---

## Golden rules (read once, hold for the whole migration)

1. **Parallel-run, never big-bang.** The old ELK stack stays *live* until SO has proven telemetry + detection parity. You decommission only in Phase 5, only after a passing gate, only after a final snapshot.
2. **The custom layer is the capstone.** SO replaces the *pipeline* (Zeek→Filebeat→Logstash→ES→Kibana). Your SOAR agent, HDI orchestrator, Ollama layer, four-gate Sigma CI, and `slo_metrics.py` **survive and re-point** — they are the original contribution, so they get re-integrated, not rebuilt.
3. **Least-privilege, always.** The re-pointed components get a **dedicated** ES service account mirroring SO's `auth.sls` pattern — they never borrow `so_elastic`.
4. **Every gate produces evidence.** Screenshots, `so-status` output, a coverage row, a burned-down issue number. That evidence *is* your capstone demo.

---

## Phase 0 — Land the scaffold & pre-flight (Dragon-Zord, ~half a day)

**Goal:** merge the scaffold, fill in the machine-specific blanks, freeze a clean starting point.

- [ ] Review the `feat/so-migration-scaffold` PR. Confirm it's **additive only** — no overwrite of the existing top-level `README.md`, `reference/` is gitignored, tree matches what the prompt claimed to create.
- [ ] Fill in `docs/adr/ADR-001-security-onion-migration.md`: confirm the Elastic License 2.0 posture wording, the free-vs-Pro boundary, and the decision statement. This is issue **#150 (D-38)** — the ADR log now exists.
- [ ] Populate `docs/migration/integration-inventory.md` — one row per component touching ES/Kibana/Logstash today (SOAR agent, orchestrator, `slo_metrics.py`, `weekly_ciso_report.py`, any dashboards). Fill *current method* now; leave *SO target method* for Phase 4.
- [ ] Fill the TODO fields in `docs/migration/so-install-runbook.md` with your **real** values: target host, NIC layout (management vs monitor), HOME_NET ranges, ISO source. Do this *before* you touch the hardware.
- [ ] Apply the issue-board labels if not already done (the `so-migration:{obviates,reduces,decision}` batch). This tags the burn-down set before any work lands.
- [ ] **Freeze checkpoint (the real D-37):** snapshot the current ELK host — VM snapshot or a full config+data export. This is the honest version of issue **#149** — not an in-place ELK→OS migration, but a *rollback point before you build the parallel grid.*
- [ ] Merge the PR to `main`.

**Gate 0:** scaffold on `main`, ADR + inventory + install-runbook have no unfilled TODOs, ELK snapshot verified restorable.

---

## Phase 1 — Stand up the SO grid (on hardware, ~1 day + burn-in)

**Goal:** a healthy Standalone grid ingesting its own default telemetry. Nothing custom yet.

- [ ] Verify the ISO checksum against Security Onion's published hash. Do not skip this.
- [ ] Install Oracle Linux 9 base per the runbook, then run `so-setup`. Choose **Standalone**. Assign the **monitor interface** (the SPAN/mirror destination Ishmael provides) distinct from the management interface. Set HOME_NET.
- [ ] Let the grid finish provisioning. Then validate:
  - [ ] `sudo so-status` — all services green.
  - [ ] OpenSearch Dashboards reachable over HTTPS; you can log in.
  - [ ] Default **Zeek**, **Suricata**, and **Wazuh** telemetry is landing — check the SOC → Grid and the Hunt/Dashboards views for live events.
- [ ] Record the five named ES service accounts and the `auth.sls` location on the manager (`/opt/so/saltstack/local/pillar/elasticsearch/auth.sls`). You'll mirror this pattern in Phase 4. **Do not** reuse these accounts for your components.

**Gate 1:** `so-status` clean, dashboards up, SO's own sensors producing events into OpenSearch. Old ELK still running untouched in parallel.

**Rollback:** grid is standalone and additive — if Phase 1 fails, nothing on the old stack is affected. Rebuild or re-`so-setup`.

---

## Phase 2 — Telemetry cutover & parity (network + endpoints, ~2–4 days)

**Goal:** the data SO collects natively matches or beats what the old pipeline collected, in ECS.

- [ ] With Ishmael: confirm the switch SPAN/mirror feeds the SO monitor NIC (this is what old issue **#5** was doing manually — SO now owns the sensor side).
- [ ] Enroll lab endpoints into SO's agent (Wazuh / Elastic Agent) for host telemetry — process + command line, identity/auth, PowerShell. This is issue **#6** and satisfies **#125 (D-13)** natively.
- [ ] Confirm SO's ingest is ECS-normalized out of the box — spot-check a Zeek conn event and a Windows process event for ECS field names. This is what **#123 (D-11)** asked you to build by hand; verify SO already does it.
- [ ] Confirm sensor-health/heartbeat is visible in the Grid view — dead-shipper alarms are native. That's **#126 (D-14)**.
- [ ] **Parity check:** for a fixed window, run the same activity (a benign Nmap sweep, an SSH login) and confirm SO sees at least what old-ELK saw. Log deltas in `integration-inventory.md`.
- [ ] **Re-measure ingest lag.** The old stack had an ingest-lag SLO breach (~23,662s vs 300s target) that was undermining the MTTD claim. Measure SO's end-to-end lag on the same event class — this should now pass, and *that delta is capstone evidence.*

**Gate 2:** SO telemetry ≥ old-ELK telemetry for the parity window, ECS confirmed, heartbeat visible, ingest lag within SLO. **Old ELK still live.**

**Burns down at this gate (pending final close in Phase 5):** #5, #6, #123, #124, #125, #126, #128, and the audit cluster tied to the dead pipeline (#84, #85, #90, #99, #100, #101, #109, #110).

---

## Phase 3 — Detection migration (Dragon-Zord + SO, ~3–5 days)

**Goal:** your Sigma rules live on SO, fire correctly, and your four-gate CI targets the grid.

- [ ] Inventory + classify every Sigma rule (issues **#19 / #33**). Mark: keep / retire / needs-remap.
- [ ] Triage ECS field mappings in `migration/detections/MIGRATION_NOTES.md` — anything that assumed your old Logstash field names.
- [ ] **Decision point — issue #102:** retire the custom `translate_rules.py` in favor of SO's native Sigma deploy path (`/nsm/rules/custom-local-repos/local-sigma`, declared in `salt/soc/defaults.yaml`)? If yes → close #102 as obviated. If you keep the translator → the risk_score/enabled/sub-technique bugs remain real and #102 stays open.
- [ ] Fix carry-over rule-content bugs that are platform-independent — e.g. **#103** (RDP-hijack rule mis-tagged T1574 → should be T1563.002).
- [ ] Deploy rules to the SO local-sigma repo path.
- [ ] **Retarget the four-gate Sigma CI** (lint → TP gate → FP gate → re-emulation regression) at SO's OpenSearch. The FP gate reuses your count-query pattern against SO indices now.
- [ ] Validate: each kept rule fires against live SO data. Run a targeted trigger per rule.

**Gate 3:** ATT&CK coverage matrix rebuilt against SO, kept rules confirmed firing, four-gate CI green against the grid.

**Burns down:** #8, #26, #27, #28, #95 (Watcher translations — gone, SO uses its own detection mechanism), #111. Reduces #36.

---

## Phase 4 — Re-point the custom layer (Dragon-Zord ↔ SO, ~1 week)

**Goal:** the capstone's original contribution runs against SO end-to-end.

- [ ] **Create a dedicated least-privilege ES service account** on the grid, mirroring the `auth.sls` pattern — scoped read (and only the write it needs) to the indices each component touches. Document it in the inventory. **Not** `so_elastic`.
- [ ] Re-point the **Flask SOAR Response Agent** (HMAC-SHA256 endpoints, three-tier action matrix) at SO's ES surface. Preserve the **Human-of-Record** rule — explicit analyst approval before any containment executes.
- [ ] Re-point the **HDI / self-critique orchestrator** (+ Network Inspection spoke, Redis pub/sub channels, two mandatory self-critique passes) at SO's data streams.
- [ ] Re-point **`slo_metrics.py`** at SO indices — and while you're in it, fix issue **#91**: enable TLS verification, use the new least-priv account, honor LLM egress governance. Reduces #91.
- [ ] Confirm the **Ollama** layer still holds the **Telemetry-Stays-on-Campus** invariant against the SO data path — no lab telemetry leaves campus for adjudication.
- [ ] **End-to-end dry run:** attack → SO detects → alert → SOAR triage → Ollama adjudication → Human-of-Record approval → containment. Trace one full path.

**Gate 4:** a live attack produces a measurable SOC outcome through *your* pipeline, human-in-the-loop validated, least-priv confirmed, Ollama invariant intact.

**Burns down:** the re-point work closes the "component X now on SO" inventory rows. Reduces #91, #121 (map student roles to SO's real OpenSearch Security roles — the roles now exist to map to).

---

## Phase 5 — Validate, burn down, decommission (~3–5 days)

**Goal:** prove the whole thing with the adversary loop, close the board, retire old ELK.

- [ ] Run **Adversary-in-a-Box** through a full named-actor kill-chain against the SO-backed lab (issues **#40–#43**). Include assume-breach.
- [ ] Confirm the **telemetry-presence check** between emulate and detect (**#136 / D-24**) and **pipeline-blinding** detection — cleared logs / killed agent (**#139 / D-27**), which SO's heartbeat + Windows 1102 + Wazuh agent-status now feed.
- [ ] **Close the obviated set (24)** with the obviated template — attribute each to the SO migration + ADR-001: #4, #5, #6, #8, #26, #27, #28, #84, #85, #90, #95, #97, #98, #99, #100, #101, #109, #110, #111, #123, #124, #125, #126, #128.
- [ ] **Re-scope the reduced set (17)** to their residuals — keep open, don't close: #3, #20, #21, #29, #31, #36, #86, #91, #92, #112, #121, #133, #136, #139, #147, #148, #151.
- [ ] **Resolve the decision-gated (2):** #102 (per your Phase 3 call), #149 (close as superseded — the ELK→OS in-place migration it guarded no longer happens; the Phase 0 snapshot covered the real need).
- [ ] **#86 — the one that survives:** the committed `elastic` superuser password is in **git history** regardless of stack. Scrub it (`git filter-repo` / BFG), force-push per your team's process, and **rotate** the credential. Close only after both.
- [ ] **Decommission old ELK** — only now, only after parity held through Phases 2–4, and take one final snapshot before teardown.
- [ ] Update `ADR-001` consequences with actuals; finalize the recover/rebuild runbooks (**#148 / D-36**, **#151 / D-39**) against the now-real grid.

**Gate 5 (capstone demo):** end-to-end — attack → SO alert → AI analysis → analyst response — on the live grid, with the burn-down board and the ingest-lag before/after as evidence.

---

## Quick issue-to-phase index

| Phase | Closes on gate | Reduces / re-scopes | Decides |
|---|---|---|---|
| 2 | #5 #6 #84 #85 #90 #99 #100 #101 #109 #110 #123 #124 #125 #126 #128 | #3 #20 #21 #29 #31 | — |
| 3 | #8 #26 #27 #28 #95 #111 | #36 | #102 |
| 4 | (inventory rows) | #91 #121 | — |
| 5 | #4 #97 #98 (final sweep of all obviated) | #86 #92 #112 #133 #136 #139 #147 #148 #151 | #149 |

*(#86 never auto-closes — history scrub + rotate is a standing task even after SO owns credentials.)*

---

## What to do if a gate fails

- **Gate 1/2 (telemetry):** old ELK is still live — you lose nothing. Fix the sensor/interface/agent issue on SO and re-validate. Do not proceed to detection work on a grid that isn't seeing data.
- **Gate 3 (detection):** if rules won't fire, the fault is almost always ECS field-mapping drift — check `MIGRATION_NOTES.md` mappings before touching rule logic.
- **Gate 4 (custom layer):** if the SOAR/orchestrator can't read SO, check the least-priv account's index permissions before anything else. Auth scope is the usual culprit.
- **Gate 5:** never decommission on a failed gate. The parallel ELK stack + Phase 0 snapshot are your rollback the entire way through.
