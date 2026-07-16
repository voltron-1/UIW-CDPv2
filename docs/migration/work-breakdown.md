# Migration Work Breakdown — Security Onion 3.1

Decomposition of the five-phase plan ([README](README.md)) into
**Phase → Work Package → Task**.

**Task schema:** `P<phase>.WP<n>.T<n>` · parent WP · one-sentence imperative
objective · observable expected outcome · exact validation check · dependency
task IDs · linked UIW-CDPv2 issue(s).

**Iteration loop (applies to every task):** Plan → Build → Validate → Reflect.
If validation fails, record why on the task's `Log:` line and loop; if it
passes, record the evidence pointer (commit, PR, query output, screenshot
path) and close. A task is not done until its Validation command has been run
and its Log line points at evidence.

Commands prefixed `[SO]` run on the Security Onion Standalone box;
unprefixed commands run on the engineering workstation in the repo root.

---

## P1 — Foundation

### P1.WP1 — Repo scaffold *(complete via PR #154)*

#### P1.WP1.T1 — Pin the Security Onion reference clone
- **Objective:** Clone upstream `securityonion` read-only at the pinned tag into `reference/`.
- **Expected outcome:** `reference/` exists at exactly tag `3.1.0-20260528` and is excluded from version control.
- **Validation:** `git -C reference describe --tags` prints `3.1.0-20260528` **and** `git check-ignore reference/` exits 0.
- **Depends on:** —
- **Linked issue:** —
- **Log:** ✅ 2026-07-02 — validated; evidence: PR #154, `.gitignore:79`.

#### P1.WP1.T2 — Record the migration decision (ADR-001)
- **Objective:** Write ADR-001 covering context, decision, free-vs-Pro boundary, ELv2 license posture, consequences.
- **Expected outcome:** `docs/adr/ADR-001-security-onion-migration.md` merged to `main`, seeding the ADR log.
- **Validation:** `gh pr view 154 --json state,mergedAt` shows `MERGED`; file present on `main`.
- **Depends on:** P1.WP1.T1
- **Linked issue:** #150 (D-38)
- **Log:** ✅ 2026-07-02 — authored on `feat/so-migration-scaffold`; merge pending PR #154 review.

#### P1.WP1.T3 — Map SO's salt/pillar config surface
- **Objective:** Document where ES auth/TLS, Logstash pipelines, Zeek interface, and the Detections rule-repo mechanism live in `reference/`.
- **Expected outcome:** `docs/migration/salt-map.md` with only paths that exist at the pinned tag.
- **Validation:** `grep -ohE '(salt|pillar)/[A-Za-z0-9/._-]+' docs/migration/salt-map.md | sort -u | while read p; do [ -e "reference/$p" ] || echo "MISSING $p"; done` prints nothing.
- **Depends on:** P1.WP1.T1
- **Linked issue:** —
- **Log:** ✅ 2026-07-02 — all four areas located; evidence: PR #154.

### P1.WP2 — Plan and pre-migration baseline

#### P1.WP2.T1 — Commit this work breakdown
- **Objective:** Decompose the five-phase plan into this WBS and link it from the migration README.
- **Expected outcome:** `docs/migration/work-breakdown.md` on the feature branch, referenced from `docs/migration/README.md`.
- **Validation:** `grep -q work-breakdown.md docs/migration/README.md && git log --oneline -1 -- docs/migration/work-breakdown.md` shows the commit.
- **Depends on:** —
- **Linked issue:** —
- **Log:** —

#### P1.WP2.T2 — Take a pre-migration backup checkpoint of the legacy stack
- **Objective:** Snapshot legacy Elasticsearch indices and archive legacy configs before any cutover work.
- **Expected outcome:** A restorable ES snapshot plus a checksummed config tarball, locations recorded in `docs/migration/`.
- **Validation:** `curl -s -u "$LEGACY_USER" https://legacy-es:9200/_snapshot/migration_backup/_all | jq -r '.snapshots[].state'` prints `SUCCESS`, and `sha256sum -c legacy-config-backup.sha256` passes.
- **Depends on:** —
- **Linked issue:** #149 (D-37)
- **Log:** —

#### P1.WP2.T3 — Fill the integration inventory to "Mapped"
- **Objective:** Complete every row of the integration inventory with its SO 3.1 target method and breaking changes.
- **Expected outcome:** No empty "SO 3.1 target method" cells; all rows at status `Mapped`.
- **Validation:** `awk -F'|' 'NR>4 && NF>6 && $4 ~ /^ *$/' docs/migration/integration-inventory.md` prints nothing.
- **Depends on:** P1.WP1.T3
- **Linked issue:** —
- **Log:** —

---

## P2 — Platform stand-up

### P2.WP1 — Standalone install

#### P2.WP1.T1 — Verify and stage the SO 3.1 ISO
- **Objective:** Download the SO 3.1 ISO matching the pinned tag and verify its signature per upstream instructions.
- **Expected outcome:** Verified ISO on install media; hash recorded in the task log.
- **Validation:** `sha256sum -c securityonion-3.1.0.iso.sha256` passes (procedure per `reference/DOWNLOAD_AND_VERIFY_ISO.md`).
- **Depends on:** —
- **Linked issue:** —
- **Log:** —

#### P2.WP1.T2 — Install SO 3.1 Standalone on dedicated hardware
- **Objective:** Perform the ISO install and initial Standalone setup on the SO box (not Dragon-Zord).
- **Expected outcome:** All SO services healthy; SOC web UI reachable from the engineering workstation.
- **Validation:** `[SO] sudo so-status` reports all containers `running/healthy`, and `curl -sk https://<so-manager>/ | grep -qi 'security onion'` succeeds from Dragon-Zord.
- **Depends on:** P2.WP1.T1
- **Linked issue:** —
- **Log:** —

#### P2.WP1.T3 — Authorize workstation access through the SO firewall
- **Objective:** Allow the engineering workstation's IP into the analyst/API firewall hostgroups.
- **Expected outcome:** SOC UI and ES API reachable only from authorized addresses.
- **Validation:** `curl -sk -o /dev/null -w '%{http_code}' https://<so-manager>/` returns `200`/`302` from Dragon-Zord and times out from a non-allowlisted host.
- **Depends on:** P2.WP1.T2
- **Linked issue:** —
- **Log:** —

### P2.WP2 — Network sensing

#### P2.WP2.T1 — Configure the Zeek sniffing interface
- **Objective:** Set the sensor interface via pillar (`sensor.interface`, per salt-map §3) so Zeek captures the lab span/tap.
- **Expected outcome:** Zeek is capturing on the intended interface and conn events reach Elasticsearch.
- **Validation:** `[SO] sudo salt-call pillar.get sensor:interface` returns the intended NIC, and `[SO] sudo so-elasticsearch-query 'logs-zeek*/_count?q=@timestamp:>now-15m' | jq .count` is > 0.
- **Depends on:** P2.WP1.T2
- **Linked issue:** —
- **Log:** —

#### P2.WP2.T2 — Apply BPF filters for lab scope
- **Objective:** Configure BPF so out-of-scope traffic (e.g. management VLAN) is excluded from capture.
- **Expected outcome:** Excluded subnets produce no NSM records; in-scope traffic still flows.
- **Validation:** `[SO] sudo so-elasticsearch-query 'logs-zeek*/_count?q=source.ip:<excluded-subnet> AND @timestamp:>now-1h' | jq .count` is 0 while the T1 count check stays > 0.
- **Depends on:** P2.WP2.T1
- **Linked issue:** —
- **Log:** —

#### P2.WP2.T3 — Audit network telemetry sources for ingestion health
- **Objective:** Confirm Zeek and Suricata datasets are ingesting without drops or parse failures.
- **Expected outcome:** Non-zero, growing document counts for both datasets; zero ingest pipeline failures.
- **Validation:** `[SO] sudo so-elasticsearch-query 'logs-zeek*,logs-suricata*/_count?q=@timestamp:>now-1h' | jq .count` > 0 on two checks ≥30 min apart, with SOC Grid showing no unhealthy nodes.
- **Depends on:** P2.WP2.T1
- **Linked issue:** #20
- **Log:** —

### P2.WP3 — Endpoint telemetry

#### P2.WP3.T1 — Deploy Elastic Agent with Sysmon telemetry to lab endpoints
- **Objective:** Enroll lab Windows endpoint(s) via SO's Elastic Fleet with Sysmon/Windows integrations so endpoint Sigma rules have data to fire on.
- **Expected outcome:** Agent(s) `Healthy` in Fleet; Sysmon events indexed.
- **Validation:** `[SO] sudo so-elasticsearch-query 'logs-windows.sysmon_operational-*/_count?q=@timestamp:>now-1h' | jq .count` > 0.
- **Depends on:** P2.WP1.T2
- **Linked issue:** #85 (CRITICAL — closes)
- **Log:** —

### P2.WP4 — Legacy defect disposition

#### P2.WP4.T1 — Disposition audit issues made moot by retiring the legacy stack
- **Objective:** Review each legacy-pipeline audit issue, and close as superseded (with rationale comment) those the SO platform replaces outright.
- **Expected outcome:** #84, #90, #98, #99, #100, #101, #26, #27, #28 each carry a disposition comment and correct state; anything NOT fully superseded gets re-scoped to a P3/P4 task instead of closed.
- **Validation:** `gh issue view <n> --json state,comments` shows a disposition comment on every listed issue; none closed without one.
- **Depends on:** P2.WP2.T3, P2.WP3.T1
- **Linked issue:** #84 #90 #98 #99 #100 #101 #26 #27 #28
- **Log:** —

---

## P3 — Detections migration

### P3.WP1 — Inventory and ECS triage

#### P3.WP1.T1 — Inventory and classify every existing Sigma rule
- **Objective:** Produce a per-rule inventory (id, title, logsource, status) of the legacy rule set in `detections/`.
- **Expected outcome:** `detections/rule-inventory.md` with one row per rule file.
- **Validation:** Inventory row count equals `find rules -name '*.yml' -o -name '*.yaml' | wc -l`.
- **Depends on:** —
- **Linked issue:** #19
- **Log:** —

#### P3.WP1.T2 — Triage each rule against SO's ECS field mappings
- **Objective:** Classify every inventoried rule as clean / remap / rework per `detections/MIGRATION_NOTES.md`.
- **Expected outcome:** Every inventory row carries exactly one triage class and, for remaps, the field-mapping delta.
- **Validation:** `grep -cE 'clean|remap|rework' migration/detections/rule-inventory.md` equals the inventory row count.
- **Depends on:** P3.WP1.T1
- **Linked issue:** #123 (D-11), #33 (supersedes its OpenSearch target)
- **Log:** —

#### P3.WP1.T3 — Correct the mis-tagged RDP-hijack rule during remap
- **Objective:** Re-tag the RDP session hijack rule from T1574 to T1563.002 as it passes through triage.
- **Expected outcome:** Migrated rule carries `attack.t1563.002` and passes lint.
- **Validation:** `grep -rl 't1563.002' migration/detections/staged/ | xargs sigma check` exits 0, and no staged rule still tags the hijack logic T1574.
- **Depends on:** P3.WP1.T2
- **Linked issue:** #103 (closes)
- **Log:** —

### P3.WP2 — Deploy to the Detections module

#### P3.WP2.T1 — Create the local-sigma custom rule repo on the SO manager
- **Objective:** Initialize `/nsm/rules/custom-local-repos/local-sigma` as a git repo and load the triaged rule set.
- **Expected outcome:** SOC Detections module syncs and lists the custom rules.
- **Validation:** `[SO] git -C /nsm/rules/custom-local-repos/local-sigma log --oneline -1` shows the import commit, and the SOC Detections UI rule count for the local-sigma ruleset equals the staged rule count.
- **Depends on:** P3.WP1.T2
- **Linked issue:** —
- **Log:** —

#### P3.WP2.T2 — Enable and baseline-tune the migrated rules
- **Objective:** Enable the migrated rules in SOC and record any threshold/filter overrides applied.
- **Expected outcome:** All staged rules enabled; overrides documented in `detections/`.
- **Validation:** `[SO] sudo so-detections-runtime-status` reports healthy, and enabled-rule count in the Detections UI matches the staged count minus documented exclusions.
- **Depends on:** P3.WP2.T1
- **Linked issue:** —
- **Log:** —

### P3.WP3 — Four-gate CI retarget

#### P3.WP3.T1 — Gate 1: Sigma lint in CI
- **Objective:** Add a GitHub Actions job running `sigma check` on every PR touching rule files.
- **Expected outcome:** Rule PRs get an automatic lint check; malformed rules block merge.
- **Validation:** `gh run list --workflow sigma-ci --limit 1` shows green on a valid-rule PR, and a deliberately malformed test rule produces a red check.
- **Depends on:** P3.WP1.T2
- **Linked issue:** #93, #130 (D-18), #129 (D-17), #83 (FW-D3)
- **Log:** —

#### P3.WP3.T2 — Gate 2: true-positive gate
- **Objective:** Replay known-bad telemetry per rule and assert the rule produces an alert on SO.
- **Expected outcome:** CI (or a runnable harness in `migration/ci/`) fails any rule whose TP replay yields zero alerts.
- **Validation:** Harness run against the staged set exits 0, and inverting one rule's condition makes it exit non-zero.
- **Depends on:** P3.WP3.T1, P3.WP2.T2, P2.WP3.T1
- **Linked issue:** #130, #78 (FW-C3)
- **Log:** —

#### P3.WP3.T3 — Gate 3: false-positive gate
- **Objective:** Replay baseline (benign) telemetry and assert the rule set stays quiet.
- **Expected outcome:** FP harness reporting zero alerts against the baseline corpus, wired into the same CI workflow.
- **Validation:** Harness exits 0 on baseline replay; seeding the corpus with a known-trigger event makes it exit non-zero (harness self-test).
- **Depends on:** P3.WP3.T2
- **Linked issue:** #130, #78
- **Log:** —

#### P3.WP3.T4 — Gate 4: re-emulation regression
- **Objective:** Re-run the full adversary-emulation set after any rule change and diff detection coverage against the last known-good run.
- **Expected outcome:** A regression report artifact per run; coverage regressions block merge.
- **Validation:** Two consecutive harness runs on an unchanged rule set produce an empty diff; disabling one detection produces a non-empty diff and a red check.
- **Depends on:** P3.WP3.T3, P5.WP1.T2*
- **Linked issue:** #137 (D-25)
- **Log:** — *(full automation lands with P5 playbooks; a manual atomic subset is acceptable to close the gate initially — note which in the log)*

### P3.WP4 — New detections and coverage

#### P3.WP4.T1 — Add at least one behavioral/anomaly detection
- **Objective:** Author ≥1 behavioral or anomaly-based detection (not signature/IOC) against SO telemetry.
- **Expected outcome:** Rule staged, gated, and enabled like any migrated rule.
- **Validation:** Rule passes all four gates (P3.WP3) and fires on its TP scenario replay.
- **Depends on:** P3.WP3.T3
- **Linked issue:** #133 (D-21)
- **Log:** —

#### P3.WP4.T2 — Detect pipeline blinding
- **Objective:** Author detections for telemetry silence — cleared logs (T1070.001) and killed/stopped agent — so blinding the pipeline itself raises an alert.
- **Expected outcome:** Stopping an endpoint agent or clearing event logs in the lab produces an alert.
- **Validation:** Stop Elastic Agent on the lab endpoint; alert appears in SOC within the rule's window. Restart and confirm recovery.
- **Depends on:** P2.WP3.T1, P3.WP3.T1
- **Linked issue:** #139 (D-27)
- **Log:** —

#### P3.WP4.T3 — Generate an ATT&CK Navigator layer from the live rule set
- **Objective:** Script the export of enabled SO detections into a Navigator layer JSON.
- **Expected outcome:** Committed generator script + layer artifact reflecting current coverage.
- **Validation:** `jq '.techniques | length' coverage/navigator-layer.json` > 0 and the file loads cleanly in ATT&CK Navigator.
- **Depends on:** P3.WP2.T2
- **Linked issue:** #76 (FW-C1), #13
- **Log:** —

#### P3.WP4.T4 — Build the telemetry-aware coverage scorecard
- **Objective:** Score coverage per technique, weighted by whether the required telemetry source is actually ingesting.
- **Expected outcome:** Scorecard artifact (doc or dashboard) distinguishing "rule exists" from "rule can actually fire here."
- **Validation:** Scorecard marks a technique with a rule but no telemetry as non-covered (test with one known gap).
- **Depends on:** P3.WP4.T3, P2.WP3.T1
- **Linked issue:** #77 (FW-C2)
- **Log:** —

---

## P4 — Integration re-point

### P4.WP1 — Least-privilege service accounts

#### P4.WP1.T1 — Create dedicated ES service accounts for each integration
- **Objective:** Create three least-privilege roles+users on SO's Elasticsearch — `svc_soar` (scoped write), `svc_orchestrator` (read-only, alert indices), `svc_slo` (read-only, metrics indices) — never reusing `so_elastic`.
- **Expected outcome:** Three accounts exist with documented role definitions in `migration/integrations/`.
- **Validation:** For each account `curl -sk -u <acct> https://<so-manager>:9200/_security/_authenticate | jq .username` succeeds, **and** a write attempt with a read-only account returns HTTP 403.
- **Depends on:** P2.WP1.T3
- **Linked issue:** #86 (successor credential model), #91
- **Log:** —

#### P4.WP1.T2 — Keep integration credentials out of the repo
- **Objective:** Store service-account credentials only in gitignored `.env` files and verify no secret reaches git.
- **Expected outcome:** Clean secret scan over the working tree and the new commits.
- **Validation:** `gitleaks detect --source . --no-banner` (or equivalent) reports 0 leaks on the branch.
- **Depends on:** P4.WP1.T1
- **Linked issue:** #86
- **Log:** —

### P4.WP2 — SOAR agent

#### P4.WP2.T1 — Re-point the SOAR agent to SO's ES surface with verified TLS
- **Objective:** Switch the Flask SOAR agent's ES client to the SO manager using `svc_soar` and the SO CA bundle, with certificate verification ON.
- **Expected outcome:** SOAR agent reads/writes against SO ES; no TLS-verification bypass anywhere in its code path.
- **Validation:** Integration test performs a round-trip (read alert → write disposition) against SO ES, and `grep -rn 'verify=False\|verify_certs=False' <soar source dir>` prints nothing.
- **Depends on:** P4.WP1.T1
- **Linked issue:** #91, #46 (advances epic)
- **Log:** —

#### P4.WP2.T2 — Add automated tests for SOAR decision logic
- **Objective:** Cover `agent_app.py` decision paths (approve/deny/queue, HMAC validation) with unit tests wired into CI.
- **Expected outcome:** Test suite exercising each decision branch; red check on regression.
- **Validation:** `pytest tests/ -k soar -q` passes locally and in the CI run for the PR.
- **Depends on:** P4.WP2.T1
- **Linked issue:** #96 (closes)
- **Log:** —

#### P4.WP2.T3 — Retire the orphaned duplicate SOAR engine
- **Objective:** Remove (or archive with an ADR note) the hive-mind-broker duplicate so exactly one SOAR engine exists.
- **Expected outcome:** Single SOAR code path; duplicate gone from the tree.
- **Validation:** `grep -ri 'hive-mind-broker' --include='*.py' .` prints nothing outside `docs/`.
- **Depends on:** P4.WP2.T1
- **Linked issue:** #94 (closes)
- **Log:** —

#### P4.WP2.T4 — Disposition the placeholder Watcher translations
- **Objective:** Close out the never-loaded Elastic Watcher placeholders as superseded by SO's Detections module.
- **Expected outcome:** Placeholders removed; issue closed with rationale referencing ADR-001.
- **Validation:** `gh issue view 95 --json state` shows `CLOSED` with a disposition comment.
- **Depends on:** P3.WP2.T2
- **Linked issue:** #95 (closes)
- **Log:** —

### P4.WP3 — Orchestrator and LLM layer

#### P4.WP3.T1 — Re-point the HDI/self-critique orchestrator to SO ES
- **Objective:** Switch orchestrator reads to SO's alert indices via `svc_orchestrator` (read-only) with verified TLS.
- **Expected outcome:** Orchestrator triages a live SO alert end-to-end through the Ollama layer.
- **Validation:** Trigger a TP alert (P3 harness); orchestrator output references that alert's document `_id` within one polling cycle.
- **Depends on:** P4.WP1.T1, P3.WP2.T2
- **Linked issue:** —
- **Log:** —

#### P4.WP3.T2 — Enforce the LLM grounding contract
- **Objective:** Require every LLM triage output to cite the source event ID and carry the analyst-verification disclaimer.
- **Expected outcome:** Structured output schema enforced in code; non-conforming outputs rejected.
- **Validation:** Automated test over ≥10 sampled triage outputs asserts 100% contain a resolvable `_id` citation and the disclaimer string.
- **Depends on:** P4.WP3.T1
- **Linked issue:** #143 (D-31, closes)
- **Log:** —

### P4.WP4 — SLO metrics and reporting

#### P4.WP4.T1 — Re-point SLO metrics collection with least privilege and verified TLS
- **Objective:** Migrate `slo_metrics.py` to `svc_slo` (read-only) against SO ES, removing all TLS-verification bypasses and LLM-egress violations flagged in audit.
- **Expected outcome:** SLO job runs green against SO; no `verify=False` in the reporting code path.
- **Validation:** Scheduled run exits 0 with metrics emitted, and `grep -rn 'verify=False\|verify_certs=False' scripts/ | grep -i 'slo\|report'` prints nothing.
- **Depends on:** P4.WP1.T1
- **Linked issue:** #91 (closes)
- **Log:** —

#### P4.WP4.T2 — Fix CISO reporting to NIST CSF 2.0
- **Objective:** Rework `weekly_ciso_report.py` around the six CSF 2.0 functions (adding Govern) with rule/SOP metadata feeding evidence automatically.
- **Expected outcome:** Generated report enumerates Govern, Identify, Protect, Detect, Respond, Recover with evidence rows.
- **Validation:** `python scripts/weekly_ciso_report.py --dry-run | grep -c -iE '^#+ *(Govern|Identify|Protect|Detect|Respond|Recover)'` returns 6.
- **Depends on:** P4.WP4.T1
- **Linked issue:** #89 (closes), #69 (advances)
- **Log:** —

---

## P5 — Validation and cutover

### P5.WP1 — Purple-team validation

#### P5.WP1.T1 — Connect the emulation platform to the SOC lab subnet
- **Objective:** Attach Adversary-in-a-Box to the monitored lab subnet so its traffic transits the SO sensor.
- **Expected outcome:** Emulation host reachable in-lab and visible in NSM data.
- **Validation:** `[SO] sudo so-elasticsearch-query 'logs-zeek*/_count?q=source.ip:<emulation-host-ip> AND @timestamp:>now-15m' | jq .count` > 0 during a test ping/scan.
- **Depends on:** P2.WP2.T1
- **Linked issue:** #40 (closes)
- **Log:** —

#### P5.WP1.T2 — Author automated ATT&CK exercise playbooks
- **Objective:** Script repeatable emulation playbooks (technique → expected telemetry → expected detection) for the covered technique set.
- **Expected outcome:** Playbooks in-repo, each declaring the ATT&CK technique ID and the SO rule(s) expected to fire.
- **Validation:** One full playbook run produces the declared telemetry, confirmed by the P3.WP3 harness consuming its output.
- **Depends on:** P5.WP1.T1, P3.WP2.T2
- **Linked issue:** #41 (closes), #57 (advances)
- **Log:** —

#### P5.WP1.T3 — Measure detection effectiveness per emulation run
- **Objective:** Emit TP/FN counts, coverage %, and alert latency per emulation run, keyed by run ID.
- **Expected outcome:** Per-run effectiveness report artifact feeding the coverage scorecard.
- **Validation:** Two runs produce two distinct run-ID-keyed reports; a deliberately disabled rule appears as FN in the next report.
- **Depends on:** P5.WP1.T2, P3.WP4.T4
- **Linked issue:** #42 (closes), #38 (advances gate)
- **Log:** —

#### P5.WP1.T4 — Publish the detection validation framework and QA workflow
- **Objective:** Document the end-to-end detection lifecycle (author → gates → deploy → re-emulate → tune) as the standing QA process.
- **Expected outcome:** Framework doc merged; referenced by the rules CONTRIBUTING/workflow docs.
- **Validation:** Doc merged to `main` and cross-linked from the Sigma workflow docs (`grep` finds the link); one new rule has traversed the documented process end-to-end.
- **Depends on:** P5.WP1.T3
- **Linked issue:** #37 (closes), #35 (closes), #78 (advances)
- **Log:** —

### P5.WP2 — Cutover and close-out

#### P5.WP2.T1 — Decommission the legacy stack
- **Objective:** After a final verified backup, stop and remove the legacy Zeek/Filebeat/Logstash/ES/Kibana containers. **Destructive — requires explicit sign-off from Tommy before execution.**
- **Expected outcome:** Legacy containers gone; backup restore-tested; SO is the only detection platform.
- **Validation:** `docker ps --format '{{.Names}}'` on the legacy host shows no legacy-stack containers, and a test restore of one index from the P1.WP2.T2 snapshot succeeds.
- **Depends on:** P1.WP2.T2, P4.WP2.T1, P4.WP3.T1, P4.WP4.T1, P5.WP1.T3
- **Linked issue:** #149
- **Log:** —

#### P5.WP2.T2 — Sweep and close superseded issues; update architecture docs
- **Objective:** Close every migration-superseded issue with a disposition comment and update the architecture/topology docs to reflect SO 3.1.
- **Expected outcome:** Issue board reflects reality; docs describe the SO-based platform.
- **Validation:** `gh issue list --search 'label:superseded state:open' --json number | jq length` returns 0, and `docs/network_topology.md` (+ architecture diagram) reference Security Onion, not the legacy stack.
- **Depends on:** P5.WP2.T1, P2.WP4.T1
- **Linked issue:** #26 #27 #28 #33 #84 #90 #95 #98 #99 #100 #101 (dispositions)
- **Log:** —

#### P5.WP2.T3 — Migration exit review
- **Objective:** Assemble the evidence packet (coverage scorecard, effectiveness reports, SLO metrics, closed-issue ledger) and hold the exit review.
- **Expected outcome:** Signed-off exit review doc in `docs/migration/`; migration epic closed.
- **Validation:** Exit review doc merged to `main` with links resolving to every WP's evidence pointers; #38-style gate criteria all checked.
- **Depends on:** P5.WP2.T2
- **Linked issue:** #38 (analog gate), #115 (D-03 thin-thread demonstrated end-to-end)
- **Log:** —
