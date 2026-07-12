# Planned Execution — Security Onion 3.1 Migration

> **Derived view, not a source of truth.** Completion state is authoritative in
> GitHub issues and the canonical issue burn-down index in
> [`docs/migration/execution-runbook.md`](docs/migration/execution-runbook.md)
> ("Quick issue-to-phase index"). This file is the sequenced execution view; when
> it disagrees with GitHub, GitHub wins — fix this file.
>
> Markers: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked (by a dependency)
> Update cadence: adjust markers in the same PR that closes/advances the items.
> Last reconciled against GitHub: **2026-07-07**.

---

## NEXT UP

**Phase 2 — Telemetry cutover & parity (Gate 2 · milestone #11).**
Next unstarted item: **`[P2.1]` #167 — get simulated traffic to the sensor**
(dev environment: sensor traffic is simulated by design — replay pcaps onto
`ens224` or run the sims on a promiscuous segment; harness ready in
[`migration/parity/`](migration/parity/)).
Parallel-capable now: `[P2.2]` #168 — endpoint enrollment rides the management
network, independent of the monitor NIC.

---

## LAST SESSION (2026-07-11 → 12)

**Not SO-migration phase work — a parallel security-remediation pass on the
"old ELK" docker-compose stack** (the one Gate 2+ requires to "stay live" during
the parity window). Full detail: `docs/audits/security-posture-diff-2026-07-10.md`
(audit) and `docs/audits/remediation-plan-2026-07-11.md` (the actual source of
truth for this work — its own status lines, not this file, track completion).
None of these PRs close a `[P#.#]` item below; recorded here only because it
touched the same "old ELK" stack this migration plan treats as a dependency.

- **PR #205** — Workstream A: broker/agent HMAC auth (replay protection,
  privileged-endpoint gating), SSH host-key verification, fail-closed
  exclusion-list enforcement.
- **PR #206** — Workstream B: Logstash pipeline hardening (Beats mTLS, signed
  SOAR trigger replacing the two dead Watcher webhooks, persisted queue + DLQ,
  parse-failure quarantine, PII stripping at ingest).
- **PR #207** — Workstream C: CI security gates (gitleaks, Trivy image/IaC
  scan, pip-audit, SHA-pinned actions, blocking pytest).
- **PR #208** — Workstream G: agent loopback-only port binding, container
  memory caps.
- **PR #209** — Workstream E: least-privilege Elasticsearch service accounts
  for Logstash/agent/slo_metrics (previously ran as `elastic` superuser).
- **PR #210** — Workstreams F (partial) + H: broker dependency pinning,
  pipeline parse-failure test coverage (surfaced and fixed a real gap: modern
  OpenSSH's `sshd-session`/`sshd-auth` auth events were falling through the
  sshd grok filter unparsed and unflagged).

One item DOES connect directly to a phase item: **`[P4.1]` #180** (below) is
tagged "demonstrated an API-driven account-provisioning pattern against
Suburban-SOC this session; flag on review if grid access differs" — PR #209
is exactly that demonstration, done properly (role JSONs, an idempotent
`apply_roles.sh`/`provision_es_service_accounts.sh` pair, and a
security-review-driven fix splitting one shared writer account into two
scoped ones so the untrusted-input-facing component can't forge the other's
audit trail). #180 itself stays open — it still needs the same pattern
re-applied against the actual SO grid (`auth.sls`, never `so_elastic`), which
needs grid access this session didn't have — but PR #209 is directly reusable
prior art for whoever picks that up.

Still open in that remediation plan, not attempted this session:
`committed-credential-rotation` (UIW #191, below — owner action, needs a
coordinated history rewrite) and Workstream D (detection content restoration —
deliberately not started; likely overlaps `[P3.1]`–`[P3.7]` #173–#179 below,
needs a scoping conversation before touching).

## Prior session (2026-07-07)

- **PR #201** merged — `[P2.6]` #172 ingest-lag helper + A6 measurement method landed on `main` (`migration/parity/ingest_lag.py`, `test_ingest_lag.py`). The re-measurement itself still awaits #167 traffic.
- **PR #202** merged — audit-remediation doc-truth pass: reconciled the `hive-mind-broker` docs↔code contradiction (README row/tree + SOP-022 note), corrected the Elasticsearch legacy-version drift → **9.3.2** (ADR-001 + 3 re-point stubs), fixed stale `(#109)`→`(#94)` code refs.
- **#94 reframed** → *"hive-mind-broker is the agent's router-block tier — integrate & deploy (not remove)"*: disposition **KEEP + INTEGRATE**; build (compose service, secret templating, `/webhook/dispatch` contract, single approval surface, tests #96) sequenced into **Phase 4 / #181**. Two new breakages recorded: endpoint mismatch + dual-approval split-brain.

### Prior (2026-07-05 → 06)
- **PR #197 / #198 / #199** merged — README truth pass (ADR-001 → Accepted, closed #196); Phase 1 grid stand-up on dev VM `cardinal-so` (**Gate 1 MET**, closed #160, #163–#166); Phase 2 kickoff + Gate 2 evidence scaffold + parity harness. Board renamed **"CARDINAL — SO 3.1 Migration"** (project #13).

---

## Phase 0 — Land the scaffold & pre-flight (M1 · milestone #9) — ✅ Gate 0 approved 2026-07-03 (0.4 exception)

Gate 0: scaffold on `main` · zero unfilled TODOs (ADR-001 / integration-inventory / so-install-runbook) · verified ELK snapshot · evidence written.

- [x] `[P0.0]` #156 Path normalization — [`evidence/phase-0.md`](docs/migration/evidence/phase-0.md) §0.0
- [x] `[P0.1]` #157 PR review — PR #155
- [x] `[P0.2]` #158 ADR-001 — evidence §0.2; status → **Accepted** 2026-07-05 (PR #197)
- [x] `[P0.3]` #159 Integration inventory — evidence §0.3 (flags: orchestrator has **no implementation**)
- [x] `[P0.4]` #160 SO install runbook values — closed via PR #198 with **dev-VM values**; school-hardware refill → DEFERRED-1
- [x] `[P0.5]` (no issue — skipped by design; burn-down labels applied + verified, evidence §0.5)
- [x] `[P0.6]` #161 Freeze checkpoint / D-37 — evidence §0.6 (SLM snapshot, restorability verified)
- [x] `[P0.7]` #162 Merge — PR #155 merged 2026-07-03 (`db11e45`)

> GitHub note: **#156–#159, #161, #162 remain OPEN as historical records** — work
> is complete per evidence; closing them needs a separate go-ahead (rule 3).

## Phase 1 — Stand up the SO grid (M2 · milestone #10) — ✅ Gate 1 MET 2026-07-05 (PR #198)

Gate 1: `so-status` clean · SOC console up · SO sensors producing events · old ELK untouched in parallel.

- [x] `[P1.1]` #163 ISO checksum + GPG verified — [`evidence/phase-1.md`](docs/migration/evidence/phase-1.md) §A1
- [x] `[P1.2]` #164 SO 3.1 Standalone installed — dev VM `cardinal-so`, VMware Workstation (12 vCPU / 32 GB / 200 GB) — §A2; production-hardware deployment → DEFERRED-2
- [x] `[P1.3]` #165 Grid validated — `so-status` all green · console login · 235 Suricata alerts via `so-test` — §A3
- [x] `[P1.4]` #166 Five ES service accounts + `auth.sls` recorded — §A4

## Phase 2 — Telemetry cutover & parity (M3 · milestone #11) — ⏳ CURRENT (0/6)

Gate 2: SO telemetry ≥ old-ELK for the parity window · ECS confirmed · heartbeat visible · ingest lag within SLO · **old ELK still live**.
Burns down at Gate 2 (index row): closes #5 #6 #84 #85 #90 #99 #100 #101 #109 #110 #123 #124 #125 #126 #128 · re-scopes #3 #20 #21 #29 #31. *(Actual GitHub closes happen in the Phase 5 sweep.)*

Session prep (done via PR #199 — no task issues; see FLAGGED):
- [x] Phase 2 kickoff plan — [`plans/20260705-so-migration-phase2-kickoff.md`](plans/20260705-so-migration-phase2-kickoff.md)
- [x] Gate 2 evidence scaffold — [`docs/migration/evidence/phase-2.md`](docs/migration/evidence/phase-2.md)
- [x] Parity harness (capture → HOME_NET rewrite → replay, + live-flows alt) — [`migration/parity/`](migration/parity/)

Execution:
- [ ] `[P2.1]` #167 Get simulated traffic to the sensor — replay pcaps onto `ens224` or sims on a promiscuous segment; align HOME_NET (`10.18.81.0/24` vs mgmt `192.168.126.0/24`) ← **NEXT**
- [ ] `[P2.2]` #168 Enroll lab endpoints (Elastic Agent/Fleet) — needs ≥1 Windows (Sysmon) + ≥1 Linux; can run parallel with #167
- [ ] `[P2.3]` #169 ECS spot-check (Zeek `conn` + Windows process) — after #167/#168 produce events
- [ ] `[P2.4]` #170 Sensor/agent heartbeat + dead-shipper alarm — after #167/#168
- [ ] `[P2.5]` #171 Parity check vs legacy ELK — needs #167–#170 **and legacy ELK (`Suburban_SOC`) running**; use the `migration/parity/` pcap path
- [~] `[P2.6]` #172 Re-measure ingest lag (legacy breach ~23,662 s vs 300 s SLO) — helper + A6 method landed (PR #201); re-measurement pending #167 traffic

## Phase 3 — Detection migration (M4 · milestone #12) — (0/7)

Gate 3: ATT&CK coverage rebuilt against SO · kept rules firing · four-gate CI green.
Burns down at Gate 3 (index row): closes #8 #26 #27 #28 #95 #103 #111 · re-scopes #36 · decides #102.

- [ ] `[P3.1]` #173 Inventory + classify Sigma rules (keep/retire/remap; refs #19 #33) — repo work, startable now
- [ ] `[P3.2]` #174 Triage ECS field mappings — [`detections/MIGRATION_NOTES.md`](detections/MIGRATION_NOTES.md); startable now
- [ ] `[P3.3]` #175 **DECISION:** retire `translate_rules.py`? (→ #102)
- [ ] `[P3.4]` #176 Fix RDP-hijack rule mis-tag (T1574 → T1563.002; → #103)
- [ ] `[P3.5]` #177 Deploy rules to the `local-sigma` repo path
- [ ] `[P3.6]` #178 Retarget four-gate Sigma CI at SO's ES — [`migration/ci/`](migration/ci/)
- [ ] `[P3.7]` #179 Validate each kept rule fires against live SO data — needs grid + traffic

## Phase 4 — Re-point the custom layer (M5 · milestone #13) — (0/6)

Gate 4: live attack → measurable SOC outcome · human-in-the-loop · least-priv confirmed · Ollama invariant intact.
Burns down at Gate 4 (index row): inventory rows close · re-scopes #91 #121.

- [ ] `[P4.1]` #180 Dedicated least-priv ES service accounts (never `so_elastic`) — also unlocks CC read-only grid access (deferred here from Phase 1). Provisioning pattern demonstrated against the old-ELK stack 2026-07-11/12, PR #209 — reuse the role-JSON + idempotent-apply-script shape, not the accounts themselves (those are `so_elastic`-adjacent, not `auth.sls`)
- [ ] `[P4.2]` #181 Re-point Flask SOAR Response Agent (preserve Human-of-Record)
- [!] `[P4.3]` #182 Re-point HDI/self-critique orchestrator — **blocked: no implementation exists** (0.3 finding); build/descope decision is required pre-work
- [ ] `[P4.4]` #183 Re-point `slo_metrics.py` + fix #91 (TLS on, least-priv, egress governance)
- [ ] `[P4.5]` #184 Confirm Ollama Telemetry-Stays-on-Campus invariant
- [ ] `[P4.6]` #185 End-to-end dry run → `evidence/phase-4.md`
- [ ] *(unscheduled — no runbook step)* #195 Add confidence logic to the ingesting agent — slotted into Phase 4 on 2026-07-06 (labeled `so-migration:task`, milestone set, on the board); natural pairing: `[P4.2]` #181

## Phase 5 — Validate, burn down, decommission (M6 · milestone #14) — (0/8 + 1 done)

Gate 5 (capstone demo): attack → SO alert → AI analysis → analyst response on the live grid, with the burn-down board + ingest-lag before/after in `evidence/phase-5.md`.
Burns down at Gate 5 (index row): closes #4 #97 #98 + **final sweep of all obviated** · re-scopes #86 #92 #112 #133 #136 #139 #147 #148 #151 · decides #149. **#86 never auto-closes.**

- [ ] `[P5.1]` #186 Adversary-in-a-Box kill-chain (#40–#43, incl. assume-breach)
- [ ] `[P5.2]` #187 Telemetry-presence + pipeline-blinding detection (#136/#139)
- [ ] `[P5.3]` #188 Close the obviated set (24 issues — proposes only; closing needs go-ahead per rule 3)
- [ ] `[P5.4]` #189 Re-scope the reduced set (17 issues — keep open)
- [ ] `[P5.5]` #190 Resolve the decision-gated set (#102 per the Phase 3 call; #149 close as superseded)
- [ ] `[P5.6]` #191 Scrub + rotate the committed `elastic` credential (#86) — **[HUMAN]-only; never with open PRs/branches**
- [ ] `[P5.7]` #192 Decommission old ELK — destructive, last, only after a final snapshot
- [ ] `[P5.8]` #193 Update ADR-001 consequences with actuals (#148, #151)
- [x] #196 README rewrite pulled forward (P5.WP2.T2 partial) — PR #197; residual (network-topology doc + diagram) stays in P5.WP2.T2

---

## Canonical burn-down index (copy — source: `docs/migration/execution-runbook.md`)

| Phase | Closes on gate | Reduces / re-scopes | Decides |
|---|---|---|---|
| 2 | #5 #6 #84 #85 #90 #99 #100 #101 #109 #110 #123 #124 #125 #126 #128 | #3 #20 #21 #29 #31 | — |
| 3 | #8 #26 #27 #28 #95 #103 #111 | #36 | #102 |
| 4 | (inventory rows) | #91 #121 | — |
| 5 | #4 #97 #98 (final sweep of all obviated) | #86 #92 #112 #133 #136 #139 #147 #148 #151 | #149 |

"Burns down" = evidence complete at that gate; the actual GitHub closes happen in
the Phase 5 sweep (#188–#190) after explicit go-ahead. All 57 indexed legacy
issues verified **OPEN** on GitHub as of 2026-07-06 — consistent with the model.

---

## DEFERRED (waiting on an external event — distinct from blocked)

1. **Step 0.4 install-runbook values for school hardware** — pending school
   hardware allocation. #160 was closed (PR #198) with the **dev-VM** values;
   when school hardware lands, Target Host / NIC layout / SPAN source / HOME_NET
   get refilled for the production install (track via a new issue at that time).
2. **Standalone SO production deployment on school hardware** — pending school
   hardware allocation. The current grid (`cardinal-so`) is a VMware Workstation
   dev VM; the dedicated-hardware install re-runs P1.1–P1.4 against real
   NICs/SPAN. No tracking issue yet.
3. **GitHub wiki one-time manual init** — pending a manual UI action (create the
   first page); `wiki-sync` publishes automatically afterwards. Non-blocking.

---

## FLAGGED — items that don't map cleanly to an issue

- **#195 "Add in confidence logic to the ingesting agent"** — was unmapped (no
  label/milestone/runbook step); resolved 2026-07-06: labeled `so-migration:task`,
  milestoned to Phase 4, added to Project #13. Remains *unscheduled* — it has no
  `P4.x` runbook step, so sequence it explicitly when Phase 4 starts.
- **Phase 2 session-prep artifacts** (kickoff plan, evidence scaffold, parity
  harness — PR #199) — done without task issues; the runbook has no steps for
  between-gate prep work.
- **`[P0.5]`** — no issue by design (board doc: "already done and verified,
  nothing left to track"; evidence §0.5).
- **Phase 0 open-but-done issues** — #156–#159, #161, #162 (see Phase 0 note).
- **Production-hardware redeploy** (DEFERRED-2) — no tracking issue yet.
