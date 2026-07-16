# SOP-001: Pipeline Operations

This page links to the full Standard Operating Procedure for operating the Suburban-SOC network monitoring pipeline.

## Quick Reference

| SOP | Script | Purpose |
|---|---|---|
| **SOP-001-A** | `stream_bat0_data.sh` | Live capture — mesh `bat0` interface |
| **SOP-001-B** | `stream_br_lan_data.sh` | Live capture — LAN bridge `br-lan` |
| **SOP-001-C** | `stream_raw_data.sh` | Live capture — local `eth0` (dev/debug) |
| **SOP-001-D** | `zeek_run_pcap.sh` | Offline PCAP analysis |
| **SOP-001-E** | `zeek_connect_host.sh` | Interactive Zeek host monitor |
| **SOP-002** | `install_filebeat.sh` | Filebeat install and configure |
| **SOP-003** | `configs/logstash.conf` | Logstash pipeline stages |
| **SOP-004** | `clear_logs.sh` | ⚠️ Clear logs / reset environment |
| **SOP-005** | — | End-to-end pipeline startup sequence |

## Full Document

The complete SOP with step-by-step instructions, prerequisites, expected outputs, and troubleshooting is located in the repository at:

[`docs/SOP-001-pipeline-operations.md`](https://github.com/sterlinggarnett/cis3353_s26_TL_SG_MF/blob/main/docs/SOP-001-pipeline-operations.md)

## End-to-End Startup Order

1. Start Docker
2. Start ELK stack (`docker compose up -d`)
3. Verify Elasticsearch (`curl http://localhost:9200`)
4. Verify Kibana (`http://localhost:5601`)
5. Start Filebeat (`sudo systemctl start filebeat`)
6. Run capture script (SOP-001-A, B, C, or D)
7. Confirm logs in `/storage/PCAP/zeek_logs/`
8. Confirm data in Kibana (`logstash-*` index)

## Related Pages
- [Home](Home)
- [Architecture](Architecture)
- [Commit-Approach](Commit-Approach)
