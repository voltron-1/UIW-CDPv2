# UNIVERSITY OF THE INCARNATE WORD
## SCHOOL OF MATHEMATICS, SCIENCE AND ENGINEERING

# UIW Cyber Defense Platform
## Enterprise Scaling & AI-Driven Multi-Agent SOAR Implementation
### PROJECT PROPOSAL & AGILE ALIGNMENT BLUEPRINT
### REVISION 6 (CAPSTONE EDITION)

| Metadata Key | Project Details |
| :--- | :--- |
| **Lead Architect:** | Tommy Lammers (Security Analyst / Engineer) |
| **Team Members:** | Sterling Garnett (Security Analyst / Engineer)<br>Ishmael Pendleton (Network Engineer / Documentation) |
| **Target Lab:** | UIW Cyber & Engineering Laboratory |
| **Date:** | June 2026 |

---

### 1. Executive Summary
This proposal formalizes the strategic scaling and architecture overhaul of Suburban-SOC—a completed, single-host Minimum Viable Product (MVP) containerized log stack engineered by Tommy Lammers and Sterling Garnett—into a resilient, enterprise-grade open-source deployment designated as the UIW Cyber Defense Platform.

Engineered specifically for the University of the Incarnate Word (UIW) Cyber & Engineering Laboratory, this ecosystem transitions the legacy environment into a multi-host, sustainably managed defense capability operated entirely by Student Analysts.

Ishmael Pendleton joins the engineering team to lead the baseline infrastructure-hardening phase, ensuring university-grade perimeter and host resilience.

The integrated platform provides localized multi-host network intrusion detection (Suricata), host-level forensics (Wazuh agents), a centralized telemetry indexing and correlation layer (OpenSearch), proactive AI-driven threat triage, and automated validation capabilities mapped tightly to the MITRE ATT&CK framework.

The operational framework relies upon three mandatory structural invariants:
1. **Hardening-First Invariant:** Full end-to-end infrastructure hardening (Layer 2 through Layer 7) must strictly precede any ecosystem or sensor deployment.
2. **Containerized Execution Boundary:** All AI agents execute actions within immutable, containerized localized boundaries; autonomous containment authority is explicitly deferred out of scope to preserve operational safety, establishing a permanent human-in-the-loop validation model for the Capstone deployment.
3. **Explicit Testing Authorization:** All validation activity relies on automated, localized emulation environments conducted under explicit authorization within an isolated subnet under strict stop-call supervision.

---

### 2. Project Team and Ownership
The platform is delivered through a structured engineering division of labor. Program Increment 1 has a dedicated infrastructure lead, while Program Increments 2 through 7 are executed through clear, per-module ownership boundaries:

| Team Member | Core Role | Ecosystem Domain & Project Ownership |
| :--- | :--- | :--- |
| **Tommy Lammers** | Lead Architect / Security Analyst | Overall platform architecture, OpenSearch cluster design, Multi-Agent SOAR boundaries, safety invariants, and core point of contact. |
| **Sterling Garnett** | Security Analyst / Engineer | Detection engineering program, local LLM agent execution pipelines, integration testing, and core contributor across PIs 2-7. |
| **Ishmael Pendleton** | Network Engineer / Documentation | PI 1 Lead (Infrastructure Hardening & Baselining). Master documentation owner across all program increments. Infrastructure-hardening verification. |

---

### 3. Strategic Vision & Core Objectives
The ultimate goal is not to deploy an enterprise SIEM, but rather to build an enduring cyber defense capability that can be comprehensively extended, analyzed, and operated by subsequent generations of UIW Student Analysts. The platform implementation is focused across four core strategic objectives:
* **Operational Security Visibility:** Establish centralized monitoring across laboratory assets. Centralize telemetry pipelines into an operational OpenSearch cluster, provisioning customized OpenSearch Dashboards to deliver structural laboratory visibility.
* **Repeatable Detection Engineering:** Construct an automated detection lifecycle utilizing standardized Sigma rules. Validate detection syntax, eliminate ingestion failures, and establish a measurable, structured MITRE ATT&CK coverage index.
* **AI-Assisted Security Operations:** Deploy a localized Multi-Agent System (MAS) running on containerized infrastructure to act as an operational layer for Student Analysts, facilitating rapid threat summarization, alert enrichment, and automated mitigation blueprints.
* **Continuous Adversary Validation:** Ensure system efficacy by integrating an automated Adversary-in-a-Box emulation platform directly within the laboratory subnet, verifying detection pipelines against live, safe replayed techniques.

---

### 4. Architectural Invariants
To guarantee operational integrity and data security, five design invariants are enforced. Any variance requires formal change-management review, an explicit technical rationale, and team-lead sign-off:

1. **Hardening-First Invariant:** No security component, detection sensor, or artificial intelligence agent will be provisioned on a laboratory host until that specific host has passed the baseline hardening validation.
2. **Telemetry-Stays-on-Campus Invariant:** Laboratory security telemetry—including IP addresses, hostnames, system logs, user identifiers, and raw packet captures—is prohibited from exiting physical university hardware. The localized Ollama infrastructure processes all telemetry data internally. The hosted external API fallback is strictly constrained to generic, fully anonymized and pre-sanitized text generation.
3. **Human-of-Record Invariant:** To protect production assets, autonomous containment authority is explicitly deferred out of scope. Every remediation recommendation generated by the Multi-Agent System requires explicit manual intervention and authorization by a Student Analyst before execution.
4. **Single-Source-of-Truth Invariant:** The centralized OpenSearch cluster serves as the absolute authoritative log, dashboard, and alert index. Localized Wazuh server indexers are disabled; all Wazuh HIDS components run strictly as telemetry-forwarding endpoints.
5. **Written-Authorization Invariant:** No offensive emulation tool or script shall be executed against UIW infrastructure without an active, signed Rules of Engagement (RoE) document identifying the scoped testing subnet, time window, and designated stop-call authorities.

---

### 5. Technical Architecture
The platform is engineered leveraging an entirely open-source, containerized microservices architecture to ensure scalability and ease of maintenance:

| Component | Technology Selected | Ecosystem Role & Structural Bounds |
| :--- | :--- | :--- |
| **Infrastructure Base** | UIW Cisco Hardware & Ubuntu Linux | Hardened physical and logical nodes serving as the isolated laboratory baseline environment. |
| **Containerization** | Docker & Docker Compose | Orchestration and deployment management of the centralized microservices stack. |
| **Central Index & SIEM** | OpenSearch Cluster | Central single source of truth for telemetry ingestion, field parsing, correlation indexing, and native alerting. |
| **Visualization Plane** | OpenSearch Dashboards | Unified analyst monitoring workspace, metrics reporting, and visual threat hunting interfaces. |
| **Network Telemetry** | Suricata NIDS | Passive network intrusion detection listening on a configured core switch SPAN port. |
| **Host Telemetry** | Wazuh HIDS (Agent Only) | Endpoint-level monitoring and integrity checking. Configured to forward logs directly into the OpenSearch pipeline. |
| **AI Execution Engine** | Ollama Infrastructure | Localized LLM engine running on university hardware to prevent off-campus telemetry data leakage. |
| **SOAR Framework** | Custom Python MAS & Agent Bus | Multi-Agent System executing automated alert enrichment, threat intelligence parsing, and triage. |
| **Emulation Engine** | Adversary-in-a-Box | Localized automation platform mimicking real-world threat behaviors to continuously validate rule coverage. |
| **Inter-Service Security** | Mutual TLS (mTLS) | Mandatory cryptographic protection for all container-to-container and sensor-to-cluster communications. |

---

### 6. The Multi-Agent System (MAS)
The automated orchestration layer consists of four specialized, containerized Python agents executing via an internal Agent Communication Bus. All agent outputs are advisory; they maintain zero autonomous containment authority.

* **Response Agent (SOAR Core):** Ingests automated OpenSearch alerts via webhooks, compiles comprehensive incident briefings, sanitizes metadata, and structures prescriptive containment blueprints (e.g., iptables rules) for mandatory human-in-the-loop approval.
* **Threat Hunter Agent:** Executes a continuous scheduled cadence (default: 15-minute intervals) querying OpenSearch indices for behavioral anomalies, low-and-slow exfiltration patterns, beaconing thresholds, or cross-segment policy violations, promoting findings directly to an analyst review queue.
* **CTI Agent:** Threat Intelligence Enrichment. Automatically interfaces with external OSINT feeds (VirusTotal, AlienVault OTX) to extract reputational confidence metrics against source IPs, anomalous domains, and binary hashes.
* **Compliance Agent:** Aggregates operational OpenSearch data into formalized weekly executive summaries capturing Mean Time to Detect (MTTD), Mean Time to Respond (MTTR), and structural mapping aligned against the NIST Cybersecurity Framework categories. This agent selectively leverages the pre-sanitized external hosted fallback LLM for narrative generation.

---

### 7. Infrastructure Hardening Framework
Executed strictly during Program Increment 1, this phase serves as a structural blocker for all subsequent deployments across the laboratory architecture:
* **Hardware and Physical Layer:** Complete credential overhaul requiring the immediate elimination of all factory-default administrative credentials. Administrative interfaces like Telnet and HTTP are completely disabled in favor of SSH (v2 only) and HTTPS. Direct console interfaces enforce absolute timeouts.
* **Layer 2 & Layer 3 Network Hardening:** Implementation of strict VLAN segmentation to isolate administrative SOC traffic from student traffic. Port security with explicit MAC-address filtering is instituted across all active nodes. Unused physical switch ports are administratively shut down, and discovery protocols (CDP/LLDP) are deactivated on all edge interfaces.
* **Layer 4 Transport Hardening:** Activation of TCP SYN cookies across underlying Linux environments to defend against high-volume SYN-flood attacks. Rate limiting constraints are enforced on concurrent raw TCP connection paths.
* **Layer 5 & Layer 6 Session Security:** Deployment of an internal Certificate Authority (CA) to enforce mutual TLS (mTLS) encryption across all inter-service traffic. Legacy cryptographic packages (SSL, TLS 1.0, TLS 1.1) are formally deprecated, locking the environment into a hardened TLS 1.3 profile.
* **Layer 7 Application Hardening:** Provisioning an upstream Web Application Firewall (WAF) to intercept injection techniques targeting OpenSearch Dashboards. Mandatory Ed25519 public-key authentication replaces interactive password validation across internal endpoints.

---

### 8. Program Increment Roadmap & Agile Execution
The project delivery is structured around seven highly definitive Program Increments (PI), transitioning the legacy single-host MVP architecture into an operational, validated campus platform:

| Program Increment | Duration | Core Technical Objectives | Mandatory Deliverables |
| :--- | :--- | :--- | :--- |
| **PI 1: Foundation Assessment** | 2-3 Weeks | Audit the legacy Suburban-SOC architecture, baseline existing telemetry parsing, analyze ingestion pipelines, and inventory rule sets. | Platform Gap Analysis, Technical Debt Register, Current-State Document. |
| **PI 2: Platform Engineering** | 3-4 Weeks | Migrate all legacy ELK stack elements into an open-source OpenSearch Cluster. Standardize indexing and rebuild monitoring visibility dashboards. | Operational OpenSearch Cluster, OpenSearch Dashboards, Runbooks. |
| **PI 3: Detection Engineering** | 4-5 Weeks | Validate existing Sigma rules, verify multi-platform log parsing accuracy, and map laboratory coverage to the MITRE ATT&CK framework. | Centralized Detection Repository, ATT&CK Matrix Dashboard, QA Framework. |
| **PI 4: Adversary Validation** | 4-6 Weeks | Integrate the Adversary-in-a-Box framework into the laboratory subnet. Establish automated attack playbooks to validate live alerts. | Purple-Team Emulation Subnet, Automated Impact Matrix, Playbook Library. |
| **PI 5: Multi-Agent SOAR Core** | 5-6 Weeks | Provision containerized Multi-Agent System infrastructure. Configure the Ollama framework and establish the Agent Communication Bus. | Containerized Agent Framework, Local Ollama Profile, Immutable Audit Log. |
| **PI 6: Student Analyst Ops** | 3-4 Weeks | Develop human-centric training material and standard operating procedures mapped to operational laboratory personas. | Student Analyst Handbook, SOC Operations Guide, Training Labs. |
| **PI 7: Capstone Demo** | 1 Week | Execute an end-to-end operational sequence demonstrating live attack generation, OpenSearch visibility, AI analysis, and analyst mitigation. | Capstone Presentation, Final Architecture Diagrams, Technical Package. |

---

### 9. Verification & Gate Criteria
Each Program Increment is governed by rigid exit criteria. Failure to satisfy these criteria triggers a hard stop on subsequent technical development:

| Program Increment | Mandatory Technical Exit Criteria | Disposition on Gate Failure |
| :--- | :--- | :--- |
| **PI 1: Foundation** | Every in-scope host passes its CIS Benchmark Level 2 scan with zero open vulnerabilities. External network scans reveal only documented ports. | Hard Stop. Software stack deployment is blocked until all host configurations are remediated. |
| **PI 2: Platform** | OpenSearch cluster actively indexes network/host logs. Dashboards render cleanly without manual configuration steps. | Hard Stop. Re-engineer the deployment playbooks before initializing PI 3. |
| **PI 3, 4, 5: Detection, Adversary, SOAR** | Sigma detections are validated across the rule management framework and visually represented within the MITRE ATT&CK dashboard. Synthetic attack playback strictly triggers corresponding security alerts inside OpenSearch Dashboards within 60 seconds of injection. Webhook alerts generate accurate incident briefings within 30 seconds. Exclusion-list containment queries are blocked at the wrapper layer. | Hard Stop. Halt progression; fix indexing pipelines/rules syntax errors. Telemetry or parsing failure must be remediated. Immediately suspend external fallback or local routing anomalies. |
| **PI 6: Operations** | Onboarding evaluations confirm that newly recruited student analysts can effectively interpret alerts and dashboards independently. | Gate Extension. Additional instructional runbooks and guidelines must be authored. |
| **PI 7: Demonstration** | Flawless execution of an end-to-end workflow: Automated attack injection -> OpenSearch Alert -> Ollama Analysis -> Human Mitigation. | Redo. Re-evaluate system components, refine playbook automation, and re-test live scenario. |

---

### 10. Deferred Scope & Program Boundaries
To secure absolute delivery of the core platform components for the Capstone evaluation, the following enterprise functionalities are explicitly identified as **Deferred Scope** and are out of scope for this deployment cycle:
* **Enterprise Ticketing Platforms:** External commercial ticketing integration (e.g., Jira Service Desk, ServiceNow) is excluded; the platform leverages the internal OpenSearch alerting queues.
* **Asset Inventory Platforms:** Dedicated network discovery platforms are bypassed in favor of localized static laboratory asset maps.
* **Autonomous Containment Authority:** Automated active remediation via independent agent execution is entirely omitted. To eliminate the risk of false-positive containment targeting benign nodes, containment execution remains bounded to manual confirmation.
* **Campus-Wide Fleet Ingestion:** Ingestion bounds are strictly locked to the internal subnet of the Cyber & Engineering Laboratory. External campus enterprise routing or wider network monitoring is completely excluded.
* **Commercial Threat Intelligence (TIP):** Subscription-based intelligence platforms are excluded; all external enrichment is handled exclusively via free, community-tier OSINT APIs.

---

### 11. Definition of Success
The UIW Cyber Defense Platform achieves absolute project success when a Student Analyst can sequentially perform the following six operational lifecycle steps within the laboratory environment:
1. Observe an unannounced attack signature generated safely by the automated Adversary-in-a-Box emulation platform.
2. Verify the continuous flow of matching raw network and host security telemetry within OpenSearch.
3. Observe a validated, non-duplicated alert generated cleanly via the localized Sigma Detection Engine.
4. Receive an enriched, structured, and plain-English incident briefing compiled by the localized Multi-Agent SOAR framework.
5. Investigate the historical context and malicious artifacts of the security event using tailored OpenSearch Dashboards.
6. Execute a prescriptive, informed manual mitigation blueprint generated securely by the local platform architecture.

**At this juncture, the UIW Cyber Defense Platform has fully accomplished its capstone mission.**
