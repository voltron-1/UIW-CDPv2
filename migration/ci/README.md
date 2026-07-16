# Sigma CI Pipeline Retarget

Placeholder for retargeting the four-gate Sigma detection pipeline at
Security Onion 3.1:

1. **Lint** — Sigma syntax/schema validation.
2. **TP gate** — true-positive check: rule fires against known-bad replay.
3. **FP gate** — false-positive check: rule stays quiet against baseline
   traffic.
4. **Re-emulation regression** — full adversary-emulation replay confirms the
   migrated rule set's coverage did not regress.

Gates must run against SO's ECS field mappings (post-triage rules from
`detections/`) and deploy to
`/nsm/rules/custom-local-repos/local-sigma`.
