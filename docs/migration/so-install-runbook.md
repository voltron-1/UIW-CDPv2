# Security Onion 3.1 — Install Runbook

Values in this file are supplied by Tommy/Ishmael (`[HUMAN]` per
[execution-runbook.md](execution-runbook.md) §0.4) and recorded here by
Claude Code. **Do not fill TODOs with invented values** — every field below
must come from a real decision about the target hardware/network before
Phase 1 (grid stand-up) begins. Gate 0 requires zero unfilled TODOs here.

## Target Host

- Make/model or VM spec: TODO
- CPU / RAM / disk allocated to the SO Standalone install: TODO
- Physical location / rack or hypervisor host: TODO

## NIC Layout

- Management interface (name, IP/CIDR): TODO
- Monitor interface (name): TODO
- Monitor NIC's SPAN/mirror source confirmed and reachable (Ishmael): TODO

## HOME_NET

- Lab subnet CIDR range(s) to declare as HOME_NET: TODO

## ISO Source & Verification

- ISO download URL for tag `3.1.0-20260528`: TODO
- KEYS / signing key source: TODO
- Signature/checksum file URL: TODO
- Verification procedure: see `reference/DOWNLOAD_AND_VERIFY_ISO.md` (read-only
  reference — cite, don't copy) once the above URLs are confirmed
