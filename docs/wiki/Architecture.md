# Architecture

## Suburban-SOC Network Pipeline Architecture

![Architecture Diagram](https://github.com/sterlinggarnett/cis3353_s26_TL_SG_MF/blob/main/docs/architecture-diagram.png?raw=true)

## Pipeline Flow

```
OpenWrt Router → SSH/tcpdump → Zeek (Docker) → Logstash (Docker) → Elasticsearch (Docker) → Kibana (Docker)
```

## Component Breakdown

| Component | Runtime | Port | Role |
|---|---|---|---|
| **OpenWrt Router** | Hardware / Physical | — | Captures all boundary network traffic for the home mesh network via mirroring |
| **Zeek** | WSL / Docker Container | File-based | Ingests raw PCAP via SSH/tcpdump tunnel and converts packets into structured JSON logs |
| **Logstash** | Docker Container | 5044 in → 9200 out | Enriches, filters, and routes JSON logs with GeoIP metadata to Elasticsearch |
| **Elasticsearch** | Docker Container | 9200 | Indexes and stores all structured log data enabling high-speed querying |
| **Kibana** | Docker Container | 5601 | Visualizes network events, security notices, and threat dashboards via web UI |

## Network Zones

| Zone | Description |
|---|---|
| **Home Network** | Physical layer — OpenWrt mesh router and connected end-user devices |
| **Ubuntu WSL / Docker Host** | All software pipeline components run here in isolated Docker containers |

## Data Flow Detail

1. **Capture:** The OpenWrt Router mirrors boundary HTTP traffic. `tcpdump` streams packets over SSH to the host.
2. **Parse:** Zeek reads the raw PCAP and outputs structured JSON log files (`conn.log`, `http.log`, `notice.log`, etc.)
3. **Ship & Enrich:** Logstash ingests the JSON logs on port 5044, applies GeoIP enrichment, and forwards to Elasticsearch on port 9200.
4. **Index:** Elasticsearch indexes the enriched logs into daily indices for fast retrieval.
5. **Visualize:** Kibana connects to Elasticsearch and renders dashboards, maps, and alert views accessible at `http://localhost:5601`.

## Related Files
- [Architecture Diagram PNG](https://github.com/sterlinggarnett/cis3353_s26_TL_SG_MF/blob/main/docs/architecture-diagram.png)
- [Zeek ELK Pipeline Docs](https://github.com/sterlinggarnett/cis3353_s26_TL_SG_MF/blob/main/docs/Zeek_ELK_Pipeline.md)
- [Network Topology](https://github.com/sterlinggarnett/cis3353_s26_TL_SG_MF/blob/main/docs/network_topology.md)
