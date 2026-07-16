# NIST SP 800-162 (ABAC) Implementation Plan

This document outlines the proposed integration of Attribute-Based Access Control (ABAC) into the UIW-CDPv2 platform, transitioning from the static HMAC/RBAC model to a dynamic, context-aware policy engine. 

## User Review Required
> [!IMPORTANT]
> Please review the core attribute definitions below. We need to decide if the Policy Information Point (PIP) should query an external identity provider (like a campus Active Directory) or if we will simulate attributes locally in a JSON file for the scope of the Capstone MVP.

## Open Questions
> [!WARNING]
> 1. How should the `approver` identity be securely transmitted? Currently, it is just a string passed in the JSON payload (e.g., `"approver": "soc-ai-agent"` or the human's name). Should we transition to signed JWTs for student identities?
> 2. What are the defined "lab hours"? (This dictates the environmental time-of-day attribute).

---

## Proposed Changes

We will implement the standard ABAC architecture defined by NIST 800-162:
- **PEP (Policy Enforcement Point):** The existing `/approve` and `/webhook/dispatch` endpoints in the `hive-mind-broker`.
- **PDP (Policy Decision Point):** A new Python module within the broker that evaluates the ABAC rules.
- **PIP (Policy Information Point):** A module that fetches student attributes (e.g., current shift status).

### Core Components

#### [MODIFY] [app.py](file:///wsl$/Ubuntu/home/tjlam/projects/UIW-CDPv2/scripts/hive-mind-broker/app.py)
*   Inject the PEP logic into `/approve` and `/webhook/dispatch`. 
*   Before calling `dispatch_block_to_all()`, the endpoints will call `evaluate_abac_policy(subject, object, environment)`.
*   If the PDP returns `DENY`, the broker will log the denial and return a 403 Forbidden, writing an audit record via `write_denial()`.

#### [NEW] [pdp.py](file:///wsl$/Ubuntu/home/tjlam/projects/UIW-CDPv2/scripts/hive-mind-broker/pdp.py)
*   Create the Policy Decision Point logic.
*   **Attributes Evaluated:**
    *   **Subject:** `role` (must be `student_analyst` or `instructor`), `location` (must be within the `10.18.81.0/24` lab subnet or VPN pool), `active_shift` (boolean).
    *   **Object:** `target_tenant`, `router_count` (e.g., require instructor approval if `router_count > 5`), `is_exclusion_list` (inherits existing logic).
    *   **Environment:** `time_of_day` (must be during defined lab operating hours).
*   **Policy Logic:** A series of boolean gates matching the attributes against the defined JSON policy.

#### [NEW] [pip.py](file:///wsl$/Ubuntu/home/tjlam/projects/UIW-CDPv2/scripts/hive-mind-broker/pip.py)
*   Create the Policy Information Point logic.
*   For the MVP, this will load a local `students.json` file mapping user IDs to their roles, schedules, and active shift statuses to simulate campus directory integration.

#### [MODIFY] [agent_app.py](file:///wsl$/Ubuntu/home/tjlam/projects/UIW-CDPv2/scripts/setup/ai_agent/agent_app.py)
*   Update the SOAR Response Agent to securely forward the logged-in Student Analyst's identity context to the broker when submitting an approval.

---

## Verification Plan

### Automated Tests
- Run `pytest scripts/hive-mind-broker/test_app.py` after adding unit tests for the PDP logic.
- Tests will include:
    - Attempting a block outside of lab hours (Expect: DENY).
    - Attempting a block without an active shift (Expect: DENY).
    - Attempting a massive block (`router_count > 5`) as a student (Expect: DENY) vs as an instructor (Expect: PERMIT).

### Manual Verification
- Deploy the modified broker to the `soc-mesh-net` in the local Dev VM (`cardinal-so`).
- Simulate an alert via Adversary-in-a-Box.
- Attempt to manually approve the drafted containment blueprint while modifying the environment clock to outside lab hours to verify the ABAC deny behavior.
