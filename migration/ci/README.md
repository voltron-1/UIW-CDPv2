# Four-Gate Sigma CI Pipeline (SO 3.1)

This directory contains the retargeted continuous integration pipeline for the SOC detection rules, pointing to the Security Onion 3.1 Elasticsearch instance.

## The Gates
1. **Lint Gate**: Ensures valid YAML and presence of required Sigma metadata (`title`, `id`, `status`, `logsource`, `detection`).
2. **True-Positive Gate**: Verifies the compiled rule successfully flags a mapped attack in the testing index.
3. **False-Positive Gate**: Performs a count-query against standard `so-*` indices (e.g. `so-zeek`, `so-beats`) to ensure the rule isn't excessively noisy on baseline traffic.
4. **Re-emulation Gate**: Triggers a live replay test to ensure end-to-end alerting (Filebeat -> Logstash -> ES -> ElastAlert/SO Detections).

See `sigma_ci.sh` for the execution skeleton.
