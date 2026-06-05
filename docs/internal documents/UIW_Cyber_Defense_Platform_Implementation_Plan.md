# UIW Cyber Defense Platform
## Revised Agile Implementation Plan (Capstone Edition)

### Vision Statement
Develop a fully open-source Cyber Defense Platform for the University of the Incarnate Word Cyber & Engineering Laboratory that enables Student Analysts to monitor, detect, investigate, validate, and respond to cyber threats through an integrated ecosystem consisting of:
* OpenSearch Security Operations Center (SOC)
* Detection Engineering Program
* Multi-Agent SOAR
* Adversary-in-a-Box
* Cyber & Physical Systems Monitoring

**The goal is not to build a SIEM.**
The goal is to build a sustainable cyber defense capability that can be operated and expanded by future Student Analysts.

### Strategic Objectives

#### Objective 1: Operational Security Visibility
Provide centralized monitoring and visibility across laboratory assets.
**Success Metrics:**
* Security telemetry centralized.
* OpenSearch operational.
* Dashboards functional.
* Student Analyst visibility established.

#### Objective 2: Detection Engineering
Create a repeatable detection lifecycle.
**Success Metrics:**
* Sigma detections validated.
* ATT&CK mapping completed.
* Detection coverage measurable.
* False positives tracked.

#### Objective 3: AI-Assisted Security Operations
Develop a multi-agent architecture capable of supporting Student Analysts.
**Success Metrics:**
* Threat summarization.
* Alert enrichment.
* Investigation assistance.
* Recommendation generation.

#### Objective 4: Adversary Validation
Continuously validate platform effectiveness.
**Success Metrics:**
* ATT&CK emulation capability.
* Detection validation workflows.
* Coverage reporting.

### Program Increment Roadmap

#### Program Increment 1: Foundation Assessment
* **Duration:** 2-3 Weeks
* **Objectives:**
  * Audit MVP architecture.
  * Audit Sigma detections.
  * Audit telemetry sources.
  * Audit dashboard functionality.
  * Identify detection failures.
  * Identify ingestion failures.
* **Deliverables:**
  * Current State Architecture Document.
  * Detection Inventory.
  * Platform Gap Analysis.
  * Technical Debt Register.
* **Exit Criteria:**
  * Known current-state architecture.
  * Known detection status.
  * Known dashboard issues.

#### Program Increment 2: Platform Engineering
* **Duration:** 3-4 Weeks
* **Objectives:**
  * Migrate ELK components to OpenSearch.
  * Rebuild dashboards.
  * Standardize index naming.
  * Standardize telemetry pipelines.
* **Deliverables:**
  * OpenSearch Cluster.
  * OpenSearch Dashboards.
  * Updated Deployment Documentation.
* **Exit Criteria:**
  * Telemetry visible.
  * Dashboards functional.
  * Alerting operational.

#### Program Increment 3: Detection Engineering Program
* **Duration:** 4-5 Weeks
* **Objectives:**
  * Validate Sigma rules.
  * Build ATT&CK matrix.
  * Create detection QA process.
  * Create rule lifecycle management.
* **Deliverables:**
  * Detection Repository.
  * ATT&CK Coverage Dashboard.
  * Detection Validation Framework.
* **Exit Criteria:**
  * Detection coverage measurable.
  * ATT&CK reporting operational.

#### Program Increment 4: Adversary-in-a-Box Integration
* **Duration:** 4-6 Weeks
* **Objectives:**
  * Connect emulation platform to SOC.
  * Automate ATT&CK exercises.
  * Measure detection effectiveness.
  * Generate validation reports.
* **Deliverables:**
  * Purple-Team Validation Environment.
  * Automated Coverage Reports.
  * Attack Replay Library.
* **Exit Criteria:**
  * Attacks produce measurable SOC outcomes.

#### Program Increment 5: Multi-Agent SOAR Core
* **Duration:** 5-6 Weeks
* **Objectives:**
  * Deploy Threat Hunter Agent
  * Deploy CTI Agent
  * Deploy Response Agent
  * Deploy Compliance Agent
* **Capabilities:**
  * Alert enrichment.
  * Threat summarization.
  * Investigation assistance.
  * Recommendation generation.
* **Deliverables:**
  * Agent Framework.
  * Ollama Infrastructure.
  * Agent Communication Bus.
  * Audit Logging.
* **Exit Criteria:**
  * Agents consume and process alerts.

#### Program Increment 6: Student Analyst Operations
* **Duration:** 3-4 Weeks
* **Objectives:**
  * Create workflows for Student Observer
  * Create workflows for Student Analyst
  * Create workflows for Student Threat Hunter
* **Deliverables:**
  * Student Analyst Handbook.
  * SOC Operations Guide.
  * Training Exercises.
  * Operational Procedures.
* **Exit Criteria:**
  * New students can operate platform.

#### Program Increment 7: Capstone Demonstration
* **Objectives:**
  * Demonstrate Attack Generation, Detection, Alert Creation, AI Analysis, Student Analyst Workflow, Response Recommendation
* **Live Scenario:**
  * Adversary-in-a-Box Live Scenario
  * Response Action
* **Deliverables:**
  * Capstone Presentation.
  * Technical Documentation.
  * Architecture Diagrams.
  * Deployment Guide.
  * OpenSearch SOC, Detection Engine, Multi-Agent SOAR, Student Analyst Workflow Integration
* **Exit Criteria:**
  * Complete end-to-end cyber defense workflow demonstrated successfully.

### Deferred Scope (Explicitly Out of Scope)
* Enterprise ticketing systems
* Asset inventory platform
* Enterprise case management
* Campus-wide deployment
* Autonomous containment authority
* Commercial threat intelligence platforms

*These may be future enhancements but are not required for successful capstone completion.*

### Definition of Success
The project succeeds when a Student Analyst can:
1. Observe an attack generated by Adversary-in-a-Box.
2. See telemetry within OpenSearch.
3. Observe a validated detection.
4. Receive AI-assisted analysis.
5. Investigate the event.
6. Execute an informed response.

**At that point the UIW Cyber Defense Platform has achieved its mission.**
