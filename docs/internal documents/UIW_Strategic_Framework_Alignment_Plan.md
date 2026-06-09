# UIW Cyber Defence Platform — Strategic Framework Alignment Plan

> **Purpose:** Bring the repository up to the standard of the Strategic Framework
> Architecture: a NIST CSF 2.0 / ISO 27001 governance layer that drives two
> operational pillars — **SOC-CMM** (operational maturity, people & processes)
> and **MITRE ATT&CK** (detection engineering & threat-hunt mapping).
>
> **Status:** Draft v1 · **Owner:** Lead Architect (@voltron-1) ·
> **Aligns to:** PI Roadmap (README.md), Implementation Plan (this folder).

---

## 1. Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 NIST CSF 2.0 / ISO 27001                    │
│      (High-Level Strategy, Governance, & Compliance)        │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌──────────────────────────────┐┌─────────────────────────────┐
│          SOC-CMM             ││       MITRE ATT&CK          │
│   (Operational Maturity,     ││   (Detection Engineering,   │
│   People, & Processes)       ││    Threat Hunter Mapping)   │
└──────────────────────────────┘└─────────────────────────────┘
```

**Design principle:** Governance (top) sets *what good looks like*. SOC-CMM
measures *how mature we are at doing it*. ATT&CK measures *how much of the
adversary we can actually see*. Every artifact in the repo must trace upward to
at least one CSF 2.0 Function/Category and, where applicable, an ISO 27001:2022
Annex A control.

---

## 2. Current State vs. Target (Gap Analysis)

| Layer | Exists today | Gap to close |
|---|---|---|
| **NIST CSF 2.0 / ISO 27001** | `NIST:<func>` alert tags; `weekly_ciso_report.py` maps the **legacy 5** functions (Identify/Protect/Detect/Respond/Recover) | Missing the CSF 2.0 **Govern (GV)** function; no ISO 27001:2022 Annex A control mapping; no governance pack (policies, risk register, RoE register, SoA) |
| **SOC-CMM** | None | No maturity self-assessment across the 5 SOC-CMM domains; no scored baseline; no improvement backlog or re-assessment cadence |
| **MITRE ATT&CK** | `docs/attack_matrix.md` (flat table); 10 Sigma rules in `rules/sigma/` with `tags:` | No ATT&CK Navigator layer JSON; no coverage **scoring** (detection confidence/volume); not linked to detection-lifecycle QA |
| **Traceability** | Implicit | No single mapping tying CSF → SOC-CMM → ATT&CK → repo artifact |

**Already-strong foundations to build on (do not rebuild):** Sigma detection repo,
Adversary-in-a-Box simulations (`tests/anomaly_simulation/`), Multi-Agent SOAR
(`scripts/setup/ai_agent/`), governance exclusion list (`governance/`), and the
CISO reporting pipeline.

---

## 3. Workstreams

The plan is organized as **four workstreams (WS-A…WS-D)** that map onto the
existing PI roadmap rather than replacing it. Each item lists target repo paths
and acceptance criteria.

### WS-A — Governance & Compliance Layer (NIST CSF 2.0 / ISO 27001)

> *The top of the pyramid. This is the largest current gap.*

**A1. Create the governance pack.** New top-level `governance/` content:
- `governance/policies/` — Information Security Policy, Acceptable Use,
  Logging & Monitoring, Incident Response, Access Control, Change Management.
  (Short, lab-appropriate — 1–2 pages each, not enterprise boilerplate.)
- `governance/risk-register.md` — tabular register: risk ID, description,
  likelihood, impact, owner, treatment, residual risk, linked CSF/ISO control.
- `governance/roe-register.md` — index of signed Rules of Engagement documents
  (enforces the *Written-Authorization-Required* invariant from README).
- `governance/statement-of-applicability.md` — ISO 27001:2022 SoA: each Annex A
  control, applicability (Y/N + justification), implementation status, evidence link.

**A2. Adopt CSF 2.0 (add the Govern function).** Upgrade from the legacy 5-function
model to the **6-function** CSF 2.0 model:
- `governance/nist-csf-2.0-profile.md` — Current Profile vs. Target Profile across
  **GV, ID, PR, DE, RS, RC**, with a per-Category tier (1–4) and gap notes.
- Extend `scripts/setup/ai_agent/weekly_ciso_report.py`: add `"Govern"` to the
  `NIST_FUNCTIONS` set and `GV:*` subcategory handling so the CISO report reflects
  CSF 2.0. *(Acceptance: report renders all 6 functions.)*

**A3. ISO 27001:2022 Annex A control mapping.**
- `governance/iso27001-annexA-mapping.md` — maps the 93 Annex A controls (4 themes:
  Organizational, People, Physical, Technological) to repo evidence. Mark
  Implemented / Partial / N-A-for-lab. Cross-reference CSF subcategories.

**A4. Compliance evidence automation.** Reuse the existing reporting pipeline:
- Tag every Sigma rule and SOP with both `nist_csf:` and `iso27001:` fields in
  front-matter/metadata so the CISO report and ATT&CK layer can auto-aggregate.
- *Acceptance:* `weekly_ciso_report.py` produces a coverage figure per CSF function
  sourced from rule/SOP metadata, not hardcoded demo data.

### WS-B — SOC-CMM Operational Maturity (People & Process)

> *New capability. Establishes the maturity baseline the program improves against.*

**B1. Maturity assessment instrument.**
- `governance/soc-cmm/assessment.md` (or `.csv`) — the SOC-CMM model scored across
  its five domains: **Business, People, Process, Technology, Services** (plus the
  capability sub-domains: e.g. Services → Security Monitoring, Incident Response,
  Threat Intelligence, Threat Hunting, Use Case Mgmt).
- Score each element 0–5 (the SOC-CMM maturity/capability scale). Capture a dated
  **baseline** snapshot.

**B2. Roles, RACI, and process docs (People/Process domains).**
- `docs/operations/roles-and-raci.md` — the Student roles already in scope
  (Student Observer / Analyst / Threat Hunter) mapped to responsibilities and to
  SOC-CMM People elements (training, certification path, shift model).
- Promote existing SOPs (`docs/SOP-001`, `SOP-022`) into a numbered SOP index and
  fill obvious process gaps: triage, escalation, on/offboarding, detection
  change-management, post-incident review.

**B3. Operational metrics.** Define and instrument SOC-CMM-aligned KPIs:
- MTTD / MTTR (already partially computed in CISO report), detection coverage %,
  false-positive rate, use-case backlog burn-down.
- `docs/operations/metrics-catalog.md` — each metric: definition, data source
  (OpenSearch index), target, owner. Wire into a dashboard NDJSON in `configs/server/`.

**B4. Improvement backlog & cadence.**
- `governance/soc-cmm/improvement-backlog.md` — gaps from B1 turned into prioritized
  GitHub issues (reuse `scripts/agile/`). Define a **re-assessment cadence**
  (e.g., once per PI) so maturity trend is tracked, not one-shot.

### WS-C — MITRE ATT&CK Detection Engineering (mature the existing asset)

> *Upgrade the flat matrix into a measured, lifecycle-managed coverage program.*

**C1. ATT&CK Navigator layer (machine-readable).**
- `rules/attack/navigator-layer.json` — generate an ATT&CK Navigator layer from the
  Sigma rule `tags:` (attack.* mappings). Color/score cells by detection count.
- Add `scripts/setup/generate_attack_layer.py` to build the layer from `rules/sigma/`
  so it regenerates as rules are added. *(Acceptance: importing the JSON into
  Navigator renders the current 10 techniques highlighted.)*
- Regenerate `docs/attack_matrix.md` from the same source so the doc and layer
  never drift.

**C2. Detection coverage scoring.**
- `docs/detections/coverage-scorecard.md` — per technique: rule(s), data source
  required, telemetry-available? (Y/N), confidence (low/med/high), tested-by
  (link to `tests/anomaly_simulation/` sim), last-validated date.
- Surfaces *real* coverage (a tagged rule with no telemetry = no coverage).

**C3. Detection lifecycle & QA.**
- `docs/detections/detection-lifecycle.md` — states (Draft → Test → Production →
  Deprecated), the QA checklist a rule must pass, and how Adversary-in-a-Box
  validates it. Link each Sigma rule's validation to a sim in `tests/anomaly_simulation/`.
- Add a CI check (extend `.github/workflows/`) that lints Sigma rules and fails on
  missing `attack.*` tags or missing `nist_csf:` metadata — enforcing C1/A4/WS-A.

**C4. Threat-hunt mapping.** Connect the Threat Hunter Agent to ATT&CK:
- `docs/detections/hunt-hypotheses.md` — hunt hypotheses indexed by ATT&CK technique
  for gaps where no automated rule exists (the white space on the Navigator layer).

### WS-D — Cross-Framework Traceability & Enforcement

> *The "glue" that makes the three layers one system instead of three documents.*

**D1. Master traceability matrix.**
- `governance/traceability-matrix.md` (or generated `.csv`) — one row per control
  objective linking: **CSF 2.0 subcategory ↔ ISO 27001 Annex A control ↔ SOC-CMM
  element ↔ ATT&CK technique(s) ↔ repo artifact (rule/SOP/script) ↔ evidence**.
  This is the single artifact a reviewer reads to confirm the architecture holds.

**D2. Metadata schema + automation.**
- Define a standard front-matter schema (`nist_csf`, `iso27001`, `soc_cmm`,
  `attack`) and apply it to Sigma rules and SOPs.
- `scripts/setup/build_traceability.py` — assembles D1 from that metadata so the
  matrix is generated, not hand-maintained.

**D3. Repo conventions & CI gate.**
- Update `README.md` "Architectural Invariants" with a 6th invariant:
  *Framework-Traceability-Required* (no detection/SOP merges without CSF + ATT&CK tags).
- CI job validates metadata presence and regenerates D1 on PR.

---

## 4. Mapping to the Existing PI Roadmap

| PI | Existing objective | Framework work folded in |
|---|---|---|
| **PI-1 Foundation** | Audit legacy architecture | **WS-A1/A2** governance pack + CSF 2.0 profile; **WS-B1** SOC-CMM baseline assessment |
| **PI-2 Platform** | Migrate to OpenSearch | **WS-B3** metrics instrumentation (indices/dashboards) |
| **PI-3 Detection** | Validate Sigma, ATT&CK dashboard | **WS-C1–C3** Navigator layer, scorecard, lifecycle/CI |
| **PI-4 Adversary** | Automate validation | **WS-C2/C3** sim-to-rule validation linkage |
| **PI-5 SOAR Core** | Provision MAS | **WS-A4** compliance automation; **WS-C4** hunt mapping |
| **PI-6 Operations** | Student ops guides | **WS-B2** roles/RACI/SOP index; **WS-B4** improvement cadence |
| **PI-7 Capstone** | End-to-end demo | **WS-D1** traceability matrix as the capstone evidence artifact |

---

## 5. Sequencing (recommended order)

1. **WS-A1/A2 + WS-B1** — stand up the governance pack and take the SOC-CMM +
   CSF 2.0 baseline. *Everything else traces to these; do them first.*
2. **WS-C1/C2** — make ATT&CK coverage measurable (highest-value quick win; the
   asset already exists).
3. **WS-D2** — define the metadata schema, then back-tag existing rules/SOPs.
4. **WS-A3/A4 + WS-C3** — ISO mapping, compliance automation, detection CI gate.
5. **WS-B2/B3/B4 + WS-C4** — process docs, metrics dashboards, hunt mapping.
6. **WS-D1/D3** — generate the master traceability matrix and lock in CI enforcement.

---

## 6. Definition of Done (framework standard met when…)

- [ ] Governance pack exists: policies, risk register, RoE register, ISO SoA.
- [ ] CSF 2.0 Current/Target Profile published across all **6** functions; CISO
      report renders Govern.
- [ ] SOC-CMM baseline scored across all 5 domains with a dated snapshot and a
      re-assessment cadence defined.
- [ ] ATT&CK Navigator layer is generated from `rules/sigma/` and coverage is
      *scored* (telemetry-aware), not just tagged.
- [ ] ISO 27001:2022 Annex A mapping complete (Implemented/Partial/N-A).
- [ ] Master traceability matrix generated from metadata links CSF ↔ ISO ↔
      SOC-CMM ↔ ATT&CK ↔ artifact.
- [ ] CI gate enforces framework metadata on detections and SOPs.

---

## 7. Out of Scope (consistent with README Deferred Scope)

- Formal ISO 27001 **certification** (this is internal alignment, not an audit).
- Commercial GRC tooling. The governance pack is markdown-in-repo by design.
- Campus-wide control coverage — bounded to the Lab subnet, per existing invariants.
```
