# Detections Migration Notes

Staging area for migrating the existing Sigma rule set (see `rules/` in the
repo root) onto Security Onion 3.1's Detections module.

## Deploy target

SO 3.1 consumes custom Sigma rules from a local rule repo:

```
/nsm/rules/custom-local-repos/local-sigma
```

This path is registered in SOC's detection-engine config
(`reference/salt/soc/defaults.yaml`, `rulesRepos` for the Sigma engine — see
`docs/migration/salt-map.md`). Rules staged here get pushed to that repo on
the SO manager; SOC's Detections module then imports and manages them.

## ECS field-mapping triage

Legacy rules were written against our hand-built Logstash output, whose field
names do not all match the ECS mappings SO's ingest produces. Before any rule
moves out of this staging area:

1. Inventory every field referenced by the rule.
2. Map each field to its ECS equivalent as emitted by SO's pipelines
   (`reference/salt/logstash/pipelines/config/so/`).
3. Classify the rule: **clean** (fields already ECS), **remap** (mechanical
   rename), or **rework** (logsource/field semantics differ — needs re-test
   against replayed traffic).
4. Record the triage outcome per rule before it enters the CI gates
   (`migration/ci/`).

## Issue 173: Sigma Rule Inventory

All 10 legacy Windows process creation rules have been reviewed and classified to **keep** as they remain high-fidelity baseline analytics.

| Rule File | Classification | Reason |
| :--- | :--- | :--- |
| `proc_creation_win_bitsadmin_download.yml` | **Keep** | Standard T1197 coverage. |
| `proc_creation_win_clear_event_logs.yml` | **Keep** | Standard T1070 coverage. |
| `proc_creation_win_local_acct_create.yml` | **Keep** | Standard T1136 coverage. |
| `proc_creation_win_lsass_dump.yml` | **Keep** | Standard T1003.001 coverage. |
| `proc_creation_win_powershell_encoded.yml` | **Keep** | Standard T1059.001 coverage. |
| `proc_creation_win_rdp_hijack_tscon.yml` | **Keep** | Standard T1563.002 coverage. |
| `proc_creation_win_regsvr32_remote_sct.yml`| **Keep** | Standard T1218.010 coverage. |
| `proc_creation_win_scheduled_task.yml` | **Keep** | Standard T1053.005 coverage. |
| `proc_creation_win_user_discovery.yml` | **Keep** | Standard T1087 coverage. |
| `proc_creation_win_wmi_process_create.yml` | **Keep** | Standard T1047 coverage. |

## Issue 174: ECS Field Mapping Triage

Legacy rules assumed custom Logstash fields. Security Onion 3.1 utilizes standard Elastic Common Schema (ECS). The following translation matrix applies to the `keep` rules above:

| Legacy Field | SO 3.1 (ECS) Field | Action |
| :--- | :--- | :--- |
| `EventID` / `event_id` | `event.code` | Remap |
| `Image` | `process.executable` | Remap |
| `CommandLine` | `process.command_line` | Remap |
| `ParentImage` | `process.parent.executable` | Remap |
| `ParentCommandLine` | `process.parent.command_line` | Remap |
| `User` | `user.name` | Remap |
| `LogonId` | `winlog.logon.id` | Remap |
| `TerminalSessionId` | `winlog.logon.id` (contextual) | Rework |
