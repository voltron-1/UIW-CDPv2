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
