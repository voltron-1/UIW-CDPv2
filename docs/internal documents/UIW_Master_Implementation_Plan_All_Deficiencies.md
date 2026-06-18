# UIW Cyber Defense Platform — Master Implementation Plan (All Deficiencies)

**Created:** 2026-06-15
**Consolidates deficiencies from all four reviews:**
- `UIW_Cyber_Defense_Platform_Evaluation.md` (P1–P6 + Smaller Notes)
- `Lens_Eval_1_SOC_Architect.md`
- `Lens_Eval_2_Red_Team_Architect.md`
- `Lens_Eval_3_Purple_Team_Architect.md`

**Purpose:** A single, de-duplicated remediation backlog. Every deficiency found anywhere in the four reviews appears once here, with a fix, a target Program Increment (PI), effort sizing, owner role, and a measurable acceptance criterion. This is the authoritative "fix list"; the companion `UIW_Evaluation_Implementation_Plan.md` holds the wave-based scheduling view.

**Legend:** Effort S = <½ day · M = 1–2 days · L = 3–5 days · XL = >1 week. Severity: 🔴 Blocker / High · 🟠 Medium · 🟡 Low-but-cheap.

---

## 1. Deficiency Register (consolidated & de-duplicated)

### A. Planning & Schedule

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-01 | No master schedule; PI durations sum to ~21–29 wks, untested against the term | Eval P1 | 🔴 | Map all 7 PIs to calendar weeks + total rollup | PI1 | S | PM/Lead | Schedule table approved; fits term with slack |
| D-02 | No prioritization of deliverables; cuts would be improvised | Eval P1 | 🟠 | MoSCoW-tag every deliverable | PI1 | S | PM/Lead | Each deliverable tagged M/S/C/W |
| D-03 | No early end-to-end proof; risk concentrated late | Eval P1/P2 | 🔴 | Define "thin-thread" MVP (1 source→1 detection→1 alert→1 manual response) by PI3–4 | PI1 | S | Lead | MVP milestone in plan with date |
| D-04 | PI7 has no duration; no demo rehearsal | Eval Notes | 🟠 | Allocate 1–2 wks to PI7 incl. dry run | PI1 | S | PM | PI7 has duration + rehearsal slot |
| D-05 | No PI→Objective traceability | Eval Notes | 🟡 | One-page traceability matrix | PI1 | S | Lead | Every PI maps to ≥1 Strategic Objective |
| D-06 | No explicit NIST CSF 2.0 framing | Eval Notes | 🟡 | Map objectives to Govern/Identify/Protect/Detect/Respond/Recover | PI1 | S | Lead | CSF mapping paragraph in plan |

### B. Risk, Governance & Access Control

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-07 | No forward-looking risk register | Eval P6 | 🟠 | Living `Risk_Register.md` (HW limits, turnover, model perf, migration) | PI1 | S–M | Lead | Register live, ≥6 risks w/ mitigations |
| D-08 | Govern plane unaddressed; no data-handling/RBAC policy | SOC | 🟠 | Define student-operator access policy + data handling | PI1/PI6 | M | Lead | Written policy; reviewed |
| D-09 | No student RBAC mapped to real permissions (Observer/Analyst/Hunter on honor system) | SOC | 🟠 | Map PI6 roles to actual OpenSearch security roles | PI6 | M | Eng | 3 roles enforced in OpenSearch |
| D-10 | **Attack range not segmented from SOC / campus production** | SOC | 🔴 | Isolated VLAN/VM for emulation; no pivot to real assets | PI1→PI4 | M | Eng | Emulation segment provably isolated; documented |

### C. Data Ingestion & Normalization

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-11 | **No normalization schema chosen** (field sprawl) | SOC, Purple | 🔴 | Adopt **ECS** as the normalization contract | PI2 | M | Eng | All telemetry normalized to ECS pre-index |
| D-12 | Collection/shipping tier not named | SOC | 🟠 | Pick Filebeat/Winlogbeat+Logstash *or* Vector | PI2 | S | Eng | Shipping tier named + deployed |
| D-13 | **Missing high-value telemetry**: process+cmdline, identity/auth, PowerShell script-block | Red, Purple | 🔴 | Enable Sysmon 1 / 4688(cmdline), 4624/4625 + IdP, 4104 | PI2 | M | Eng | All four source classes indexed + verified |
| D-14 | **No sensor-health telemetry** (dead shipper = silent) | Red, Purple | 🟠 | Heartbeat/health signal per source | PI2 | S–M | Eng | Dead source raises an alert |
| D-15 | "Cyber & Physical Systems Monitoring" promised in vision but no PI delivers it | Eval P5 | 🟠 | Scope into a PI *or* move to Deferred Scope (decision) | PI1 | S | Lead | Decision recorded; no orphan promise |
| D-16 | No ILM/retention policy; lab disk fills | SOC, Eval P5 | 🟠 | OpenSearch ISM rollover + delete policy + disk budget | PI2 | S | Eng | ISM policy active; disk projection documented |

### D. Detection Engineering (Detection-as-Code)

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-17 | "Detection Repository" has no Git workflow | SOC, Eval P5 | 🟠 | Branch/PR/review workflow for Sigma rules | PI3 | S | Eng | Rules live in Git w/ PR review |
| D-18 | **No CI validation for rules** | SOC, Purple, Eval P5 | 🔴 | CI: `sigma-cli` lint+convert, test vs. labeled samples | PI3 | M | Eng | CI runs on every PR; blocks bad rules |
| D-19 | **No FP-storm gate before deploy** | Purple | 🔴 | Validate new rule vs. normal-telemetry baseline; block on FP threshold | PI3 | M | Eng | Deploy blocked if FP rate > threshold |
| D-20 | No rule metadata standard (ATT&CK tag in front-matter) | SOC | 🟡 | Mandate ATT&CK technique tag per rule | PI3 | S | Eng | Coverage dashboard auto-populates from tags |
| D-21 | Pure-signature ceiling; no behavioral/anomaly detection | Red | 🟠 | Add ≥1 anomaly detection (new parent-child proc / first-seen logon hr / log-volume→0) | PI3 | M | Eng | ≥1 behavioral detection firing |

### E. Adversary Emulation & Validation Loop

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-22 | **Adversary-in-a-Box never defined**; no isolation stated | Eval P5 | 🔴 | Name engine (Caldera/Atomic Red Team/VECTR) + isolation boundary | PI1→PI4 | M | Eng | Engine named; isolation documented (links D-10) |
| D-23 | Validation only tests own replay library (false confidence) | Red | 🟠 | Emulate a **named actor's full kill-chain** + assume-breach exercises | PI4 | M | Eng | ≥1 named-actor chain run unscripted |
| D-24 | **No telemetry-presence check** between emulate and detect | Red, Purple | 🔴 | After each TTP, confirm expected source event exists | PI4 | M | Eng | Presence Y/N recorded per TTP |
| D-25 | **No re-emulation regression** to confirm a fix works | Red, Purple | 🔴 | Auto-re-run atomic test after rule written; confirm alert fires | PI4 | M | Eng | Re-run is an explicit PI4 exit criterion |
| D-26 | Coverage implied binary; no detected/partial/missed | Red, Purple, Eval P3 | 🟠 | **Four-column coverage table** (Technique | Telemetry Y/N | Alert Y/N | Rule Ref) | PI3→PI4 | M | Eng | Table is the centerpiece artifact, auto-fed |
| D-27 | No detection of pipeline-blinding (cleared logs / killed agent) | Red | 🟠 | Emulate self-tampering; confirm platform notices silence | PI4 | S–M | Eng | Blinding attempt raises alert |

### F. AI / SOAR Tier

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-28 | **Local-model feasibility unproven** (Ollama on lab HW) | SOC, Eval P2/P4 | 🔴 | 2–3 day spike: model, GPU/VRAM, latency/alert | PI1 | M | Eng | Spike report w/ go/no-go + numbers |
| D-29 | Over-scoped: 4 agents | SOC, Eval P4 | 🟠 | Cut to 2 (enrichment + summarization); defer rest | PI5 | S | Lead | Scope doc shows 2 core + stretch |
| D-30 | Compliance Agent has no compliance regime | SOC, Eval Notes | 🟡 | Justify (maps detections to framework?) or cut | PI5 | S | Lead | Decision recorded |
| D-31 | **No grounding contract** (hallucination risk; students trust model) | SOC, Eval P4 | 🔴 | Every agent output cites source event ID; "AI-assisted, analyst-verified" disclaimer | PI5 | M | Eng | No ungrounded output shown; disclaimer in UI |
| D-32 | "Agent Communication Bus" undefined | SOC, Eval P4 | 🟡 | Name transport (e.g., Redis pub/sub) | PI5 | S | Eng | Bus tech specified + working |
| D-33 | "Audit Logging" undefined | SOC, Eval P4 | 🟡 | Define what/where/retention | PI5 | S | Eng | Audit log schema + retention documented |
| D-34 | Measurable AI quality criterion absent | Eval P3 | 🟠 | Measure enrichment vs. analyst baseline on ≥20 alerts; track accuracy + hallucination rate | PI5 | M | Eng | Metric reported |

### G. Resilience, Reproducibility & Recover

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-35 | **No IaC; hand-built, non-reproducible** (contradicts sustainability thesis) | SOC, Eval P6 | 🔴 | Encode stack as docker-compose/Ansible | PI2→PI6 | L | Eng | Cohort N+1 can `up` the stack |
| D-36 | No Recover plan / platform backup | SOC, Eval P6 | 🟠 | OpenSearch snapshot policy + rebuild runbook | PI2/PI6 | M | Eng | Restore tested from snapshot |
| D-37 | PI2 ELK→OpenSearch migration has no rollback | SOC, Eval P6 | 🟠 | Backup checkpoint before migration | PI2 | S | Eng | Documented rollback path |
| D-38 | No ADR log for cohort handoff | Eval P6 | 🟡 | Architecture Decision Record log | PI1→PI7 | S (ongoing) | Lead | ADRs captured per major decision |
| D-39 | No "rebuild from scratch" runbook | Eval P6 | 🟠 | Step-by-step rebuild guide | PI6 | M | Eng | Runbook validated by a fresh build |

### H. Measurable Exit Criteria (cross-cutting)

| ID | Deficiency | Source | Sev | Fix | PI | Effort | Owner | Acceptance Criterion |
|---|---|---|---|---|---|---|---|---|
| D-40 | Exit criteria mostly binary/vague; "measurable" unquantified | Eval P3 | 🔴 | Attach numeric thresholds to every PI exit criterion | all | M | Lead | Each PI has ≥1 numeric exit metric (see §3) |

---

## 2. Phased Rollout (by Program Increment)

> Ordered so blockers and risk-reducers land first; everything maps to an existing PI so no re-architecting is needed.

### PI1 — Foundation & De-risking
- **Planning:** D-01, D-02, D-03, D-04, D-05, D-06
- **Risk/Govern:** D-07, D-08 (start), D-10 (start segmentation), D-15 (decision), D-22 (name engine)
- **Critical spike:** D-28 (Ollama feasibility — do in week 1–2)
- **Ongoing:** D-38 (ADRs start)
- **Gate to exit PI1:** schedule approved, MVP defined, Ollama go/no-go decided, attack-range isolation designed, Adversary-in-a-Box engine chosen.

### PI2 — Platform Engineering & Telemetry Foundation
- **Normalization:** D-11 (ECS), D-12 (shipping tier)
- **Telemetry:** D-13 (process/identity/PowerShell), D-14 (sensor-health)
- **Lifecycle/Resilience:** D-16 (ILM), D-37 (migration rollback), D-35 (IaC start), D-36 (snapshot start)
- **Gate:** ≥3 ECS-normalized sources visible end-to-end; high-value telemetry verified present; migration reversible.

### PI3 — Detection Engineering Program
- **Detection-as-Code:** D-17 (Git), D-18 (CI), D-19 (FP gate), D-20 (ATT&CK metadata)
- **Coverage:** D-26 (four-column table — start)
- **Behavioral:** D-21 (anomaly detection)
- **Gate:** ≥15 rules validated via CI; FP gate active; coverage table populating from rule tags.

### PI4 — Adversary-in-a-Box & Closed Loop
- **Emulation:** D-22 (isolation finalized), D-23 (named-actor chain), D-27 (pipeline-blinding test)
- **Loop closure:** D-24 (telemetry-presence), D-25 (re-emulation regression), D-26 (table finalized)
- **Gate:** loop demonstrably closes — a seeded gap goes miss → rule → re-emulate → detect; coverage table shows detected/partial/missed.

### PI5 — Multi-Agent SOAR (scoped + grounded)
- **Scope:** D-29 (cut to 2), D-30 (Compliance decision)
- **Safety:** D-31 (grounding + disclaimer), D-32 (bus), D-33 (audit logging)
- **Measure:** D-34 (vs-analyst baseline)
- **Gate:** 2 agents grounded to event IDs; hallucination rate measured; no ungrounded output rendered.

### PI6 — Student Operations & Sustainability
- **Access:** D-09 (RBAC), D-08 (policy finalized)
- **Reproducibility:** D-35 (IaC finish), D-36 (Recover finish), D-39 (rebuild runbook)
- **Gate:** new student stands up + operates the platform from docs/code alone.

### PI7 — Capstone Demonstration
- **D-04** (duration + rehearsal), traceability/CSF artifacts (D-05/D-06) finalized in deliverables.
- **Gate:** full closed-loop demo rehearsed and executed end-to-end.

---

## 3. Measurable Exit-Criteria Rewrite (closes D-40)

| PI | Current (vague) | Rewritten (measurable) |
|---|---|---|
| PI2 | "Telemetry visible" | ≥3 ECS-normalized sources end-to-end with < **5** min ingest latency; high-value telemetry (D-13) verified present for ≥3 hosts |
| PI3 | "Detection coverage measurable" | ≥15 Sigma rules validated in CI; per-rule TP/FP rate documented; ATT&CK coverage ≥ **N** techniques across ≥ **M** tactics; FP gate blocking confirmed |
| PI4 | "Attacks produce measurable SOC outcomes" | ≥10 TTPs emulated; each row in four-column table classified detected/partial/missed; ≥1 seeded gap closed via re-emulation regression |
| PI5 | "Agents consume and process alerts" | Enrichment measured vs. analyst baseline on ≥20 alerts; accuracy + hallucination rate reported; 100% of shown outputs cite a source event ID |
| PI6 | "New students can operate platform" | A student not on the build team stands up the stack from IaC and completes the MVP workflow unaided |

*(Set N/M during PI1 scheduling to realistic, hardware-bounded values.)*

---

## 4. Priority Tranches (if time/resources compress)

**Tranche 1 — Blockers (do regardless):**
D-01, D-03, D-10, D-11, D-13, D-18, D-19, D-22, D-24, D-25, D-28, D-31, D-35, D-40

**Tranche 2 — High-value, moderate cost:**
D-07, D-09, D-14, D-16, D-21, D-23, D-26, D-27, D-29, D-34, D-36, D-37, D-39

**Tranche 3 — Cheap polish / defensibility:**
D-02, D-04, D-05, D-06, D-08, D-12, D-15, D-17, D-20, D-30, D-32, D-33, D-38

> Tranche 1 alone yields a defensible capstone: an isolated, ECS-normalized, well-instrumented platform with a CI-gated detection pipeline, a closed validation loop, a grounded AI assistant, and reproducible infrastructure.

---

## 5. Source Traceability (every deficiency → origin)

| Source review | Deficiency IDs |
|---|---|
| Evaluation P1 (timeline) | D-01, D-02, D-03 |
| Evaluation P2 (sequencing) | D-03, D-28 |
| Evaluation P3 (measurable criteria) | D-26, D-34, D-40 |
| Evaluation P4 (AI tier) | D-28, D-29, D-31, D-32, D-33 |
| Evaluation P5 (spec gaps) | D-15, D-16, D-17, D-18, D-22 |
| Evaluation P6 (sustainability/risk) | D-07, D-35, D-36, D-37, D-38, D-39 |
| Evaluation Smaller Notes | D-04, D-05, D-06, D-30 |
| SOC-Architect lens | D-08, D-09, D-10, D-11, D-12, D-13(+), D-14, D-16, D-18, D-19, D-31, D-35, D-36 |
| Red-Team lens | D-13, D-14, D-21, D-23, D-24, D-25, D-26, D-27 |
| Purple-Team lens | D-11, D-13, D-18, D-19, D-24, D-25, D-26 |

---

## 6. Relationship to Other Docs

- **`UIW_Evaluation_Implementation_Plan.md`** — wave-based scheduling view (Waves 0–3 + Wave C). Use it for *sequencing*.
- **This document** — authoritative *deficiency register + acceptance criteria*. Use it for *tracking completeness*.
- The two are cross-consistent: Wave C items (WC-1..9) correspond to D-11, D-13/14, D-18/19, D-24, D-25, D-26, D-23, D-21, D-10 respectively.
