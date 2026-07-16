# SOP-002 — Windows Endpoint Telemetry (Sysmon + Winlogbeat)

**Status:** Active · **Owner:** SOC Engineering · **Related issues:** #100, #99

## Purpose
The `proc_creation_win_*` Sigma rules (`rules/sigma/`) detect Windows process-creation
behaviour (LSASS dump, encoded PowerShell, BITSAdmin download, etc.). They require
**Windows endpoint telemetry** — specifically **Sysmon Event ID 1** with `Image` and
`CommandLine`. The platform's network sensor (Zeek) cannot produce these events, so
without endpoint telemetry every one of those detections is dormant. This SOP wires
up that telemetry.

> Pipeline/config changes related to this SOP are static-only and have **not** been
> validated against a live Windows endpoint + cluster. Validate in a lab before relying
> on the detections.

## Architecture
```
Windows endpoint
  └─ Sysmon (driver)  ──► Microsoft-Windows-Sysmon/Operational event log
       └─ Winlogbeat  ──► Logstash :5044  (tag: endpoint_logs)
            └─ Logstash "endpoint_logs" branch ──► ECS process.* fields
                 └─ Elasticsearch  ──► detection rules / dashboards
```

## Procedure

### 1. Install Sysmon on each Windows endpoint
Use a curated config (e.g. SwiftOnSecurity `sysmon-config`) so the volume is sane:
```powershell
# From an elevated PowerShell
Invoke-WebRequest -Uri https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip
Expand-Archive Sysmon.zip -DestinationPath C:\Sysmon
# sysmonconfig.xml = SwiftOnSecurity or your tuned config
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml
# Verify the channel exists:
Get-WinEvent -ListLog "Microsoft-Windows-Sysmon/Operational"
```

### 2. Install + configure Winlogbeat
- Install Winlogbeat **9.x** (match the ELK 9.3.2 stack).
- Deploy `configs/server/winlogbeat.yml` as `C:\Program Files\Winlogbeat\winlogbeat.yml`.
- Set the Logstash target (defaults to `localhost:5044`):
  ```powershell
  setx LOGSTASH_HOST "<logstash-host>:5044"
  ```
- Start the service:
  ```powershell
  Start-Service winlogbeat
  ```

### 3. Confirm ingestion
After generating a process event (e.g. open `cmd.exe`), confirm ECS fields arrive:
```bash
curl -k -u "elastic:${ELASTIC_PASSWORD}" \
  "https://localhost:9200/logstash-security-*/_search?q=event.dataset:sysmon&size=1"
```
You should see `process.executable` and `process.command_line` populated (the fields
the Logstash endpoint branch maps from Sysmon `Image` / `CommandLine`).

## Field contract (Logstash endpoint branch)
| Sysmon field (`winlog.event_data.*`) | ECS field mapped by Logstash |
|--------------------------------------|------------------------------|
| `Image`                              | `process.executable`         |
| `CommandLine`                        | `process.command_line`       |
| `ParentImage`                        | `process.parent.executable`  |
| `User`                               | `user.name`                  |
| `TargetUserName`                     | `user.target.name`           |

`event.dataset` is set to `sysmon` for these events so detections/dashboards can
filter endpoint vs. network telemetry.

## Rollback
Stop and remove Winlogbeat (`Stop-Service winlogbeat`); uninstall Sysmon with
`Sysmon64.exe -u`. Detections relying on endpoint telemetry return to dormant.
