# Plan: Security Onion Migration — Phase 1 Kickoff

Date: 2026-07-05 · Owner: Tommy · Board: GitHub Project #13 ("CARDINAL — SO 3.1 Migration")

References: [execution-runbook.md](../docs/migration/execution-runbook.md) ·
[work-breakdown.md](../docs/migration/work-breakdown.md) ·
[board-structure-proposal.md](../docs/migration/board-structure-proposal.md) ·
[so-install-runbook.md](../docs/migration/so-install-runbook.md)

## §1 Current State

- **Phase 0 complete.** Gate 0 approved 2026-07-03 with the **0.4 exception**
  (install-runbook values deferred pending hardware). Evidence:
  [`docs/migration/evidence/phase-0.md`](../docs/migration/evidence/phase-0.md).
- Scaffold merged to `main` (PR #155); wiki-temp CI fix merged (PR #194);
  Wiki Sync green. The wiki's one-time manual initialization is still outstanding
  (non-blocking).
- **Next gate: Gate 1.** Phase 1 stands up the Security Onion grid on hardware.
- **Blocker:** Phase 1 is gated on step 0.4 / issue
  [#160](https://github.com/voltron-1/UIW-CDPv2/issues/160), which needs a real
  hardware/network decision before it can be filled.

The golden rules hold for the whole migration: **parallel-run, never big-bang**;
**the custom layer is the capstone** (re-point, don't rebuild); **least-privilege,
always**; **every gate produces evidence** in `docs/migration/evidence/phase-N.md`;
**committed means pushed** (a session never ends with unpushed work).

## §2 Track A — Critical Path (hardware-gated, serialized)

Every step logs to its issue **and** to `docs/migration/evidence/phase-1.md`
(create this file at A1). Track A cannot begin until A0 lands.

| Step | Issue | Owner | Entry criteria | Exit criteria |
|---|---|---|---|---|
| **A0 — Unblock 0.4** | [#160](https://github.com/voltron-1/UIW-CDPv2/issues/160) `[P0.4]` | `[HUMAN]` Tommy + Ishmael supply values; `[CC]` records | School hardware allocated | All five value groups in `so-install-runbook.md` filled (target host, NIC layout, SPAN/mirror confirmed, HOME_NET CIDRs, ISO/KEYS/signature URLs); `grep -c TODO docs/migration/so-install-runbook.md` = 0; #160 closed with an evidence comment |
| **A1 — Verify ISO** | [#163](https://github.com/voltron-1/UIW-CDPv2/issues/163) `[P1.1]` | `[HUMAN]` | A0 done (URLs known) | ISO checksum + GPG signature verified against SO's published values (procedure per `reference/DOWNLOAD_AND_VERIFY_ISO.md`); transcript in `evidence/phase-1.md` |
| **A2 — Install** | [#164](https://github.com/voltron-1/UIW-CDPv2/issues/164) `[P1.2]` | `[HUMAN]` | A1 verified | ISO booted; setup wizard complete: **Standalone**, monitor interface distinct from management, HOME_NET set per runbook |
| **A3 — Validate grid** | [#165](https://github.com/voltron-1/UIW-CDPv2/issues/165) `[P1.3]` | `[HUMAN]` | A2 provisioning finished | `sudo so-status` all green; SOC console reachable over HTTPS with working login; default **Zeek + Suricata** telemetry visible in SOC → Grid and Hunt/Dashboards |
| **A4 — Record accounts** | [#166](https://github.com/voltron-1/UIW-CDPv2/issues/166) `[P1.4]` | `[CC]` | A3 green | The five named ES service accounts + `auth.sls` location (`/opt/so/saltstack/local/pillar/elasticsearch/auth.sls`) recorded in `integration-inventory.md` for Phase 4 mirroring |

**Gate 1** (milestone [#10](https://github.com/voltron-1/UIW-CDPv2/issues/10),
verbatim): `so-status` clean · SOC console up · SO's own sensors producing events
into Elasticsearch · **old ELK still running untouched in parallel**.

**Evidence file** `docs/migration/evidence/phase-1.md` (new) must contain: the
ISO hash/GPG transcript, `so-status` output, screenshot filenames (SOC console
login, Grid view, Hunt view with Zeek/Suricata events), the five service-account
names, and links to #163–#166.

**Rollback:** Phase 1 is additive — the grid is standalone; a failure touches
nothing on the legacy ELK stack. Rebuild or re-run setup.

## §3 Track B — Parallel, Not Hardware-Blocked (can start today)

These progress the migration while Track A waits on hardware. None writes to a
file Track A reads, except A0 (so-install-runbook) and A4 (inventory append).

1. **README truth pass** *(this PR)* — reflect SO 3.1 reality in the root README.
   Pulls forward part of WBS **P5.WP2.T2**; tracked by a new
   `so-migration:task` issue on milestone #14. *Rationale:* the README is the
   repo's public face and currently describes a stack that was never deployed.
2. **Sigma inventory + ECS triage prep** —
   [#173](https://github.com/voltron-1/UIW-CDPv2/issues/173) `[P3.1]` /
   [#174](https://github.com/voltron-1/UIW-CDPv2/issues/174) `[P3.2]`. Inventory
   and classify the 10 rules in `rules/sigma/` (keep / retire / needs-remap);
   triage ECS field mappings into `detections/MIGRATION_NOTES.md` against the
   `reference/` clone's mappings and `salt-map.md`. *Rationale:* pure repo/docs
   work; only live-fire validation (#179) needs the grid.
3. **`translate_rules.py` decision memo** —
   [#175](https://github.com/voltron-1/UIW-CDPv2/issues/175) `[P3.3]` / #102.
   `[CC]` drafts native `local-sigma` deploy path vs. keeping the custom
   translator; `[HUMAN]` decides. *Rationale:* decision-gated, zero hardware
   dependency, unblocks Phase 3 sequencing.
4. **Orchestrator build decision** — pre-work for
   [#182](https://github.com/voltron-1/UIW-CDPv2/issues/182) `[P4.3]`. The
   integration inventory records **no orchestrator implementation exists**;
   decide build-minimal (in `migration/integrations/orchestrator/`) vs. descope
   to SOAR-only vs. defer, and record it (ADR-002 or issue re-scope).
   *Rationale:* P4.3 currently references code that must first be built —
   deciding now prevents a Phase 4 stall.
5. **#86 secret-scrub prep** —
   [#86](https://github.com/voltron-1/UIW-CDPv2/issues/86). `[CC]` preps only
   (tool choice — git-filter-repo vs. BFG — blob/path enumeration, rotation
   checklist). Execution is **`[HUMAN]`-only** (history rewrite + force-push +
   rotate). *Rationale:* the committed `elastic` password is in history
   regardless of stack. **Sequencing:** run the rewrite at a quiet point with
   **no open PRs/branches** — a force-push invalidates them.
6. **ADR-001 → Accepted** — done in this PR (status flipped with a dated note
   citing Gate 0 + PR #155). *Rationale:* the README cites ADR-001 as the
   decision of record; its status should match reality.
7. **Staleness hygiene** — land the stranded evidence commit `a16b37a` on `main`
   (cherry-picked into this PR); board-doc erratum on the #13 rename (done);
   update project memory (board renamed "CARDINAL — SO 3.1 Migration").

## §4 Sequencing

Track B items 1–7 can all start today. Track A is strictly serialized behind
#160 and open-ended on hardware timing. The only cross-track coupling: A0 edits
`so-install-runbook.md`; A4 appends a distinct section to `integration-inventory.md`.

## §5 Conventions

- Evidence for every task goes to its issue **and** the phase evidence file.
- `git push` immediately follows `git commit` — no session ends with unpushed work.
- Every new issue is added to Project #13 (`gh project item-add 13 --owner voltron-1 --url <url>`).
- Merges require Tommy's explicit approval; no self-merge.

## §6 Risks

- **Hardware timing unknown** — Track A is open-ended until #160 is unblocked.
- **Orchestrator scope creep** — timebox item B4 to a *decision memo*, not a build.
- **#86 history rewrite** — invalidates open branches; never run mid-PR.
