# Security Onion 3.1 — Install Runbook

Values in this file are supplied by Tommy/Ishmael (`[HUMAN]` per
[execution-runbook.md](execution-runbook.md) §0.4) and recorded here by
Claude Code. **Do not fill TODOs with invented values** — every field below
must come from a real decision about the target hardware/network before
Phase 1 (grid stand-up) begins. Gate 0 requires zero unfilled TODOs here.

> **Status (2026-07-05, #160 / P0.4):** The **ISO Source & Verification**
> section below is now filled from the pinned reference clone (deterministic,
> not hardware-dependent). **Remaining before Phase 1 can start** — three
> hardware/network decisions only Tommy/Ishmael can supply: **Target Host**,
> **NIC Layout**, and **HOME_NET**. Fill those, drop the `TODO`s, and #160 closes.

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

**Sourced from the pinned reference clone** `reference/DOWNLOAD_AND_VERIFY_ISO.md`
@ tag `3.1.0-20260528` — these are Security Onion's own published release values,
transcribed (not invented). `[HUMAN]` confirm each URL resolves against the live
mirror before download; the checksums and key fingerprint below are what
`sha256sum` and `gpg --verify` must reproduce (see `evidence/phase-1.md` §A1 for
the ready-to-run steps).

- ISO download URL for tag `3.1.0-20260528`:
  `https://download.securityonion.net/file/securityonion/securityonion-3.1.0-20260528.iso`
- KEYS / signing key source:
  `https://raw.githubusercontent.com/Security-Onion-Solutions/securityonion/3/main/KEYS`
- Signature file URL:
  `https://github.com/Security-Onion-Solutions/securityonion/raw/3/main/sigs/securityonion-3.1.0-20260528.iso.sig`
  (also present locally at `reference/sigs/securityonion-3.1.0-20260528.iso.sig`)
- Expected checksums:
  - SHA256: `62FAB57E247C843D6A04F0796D8162C732B65D82FC3E4A59D087135B9FD32912`
  - SHA1: `2B8B816B6CEC3B7F96B3C5E040EBF502DD2C412F`
  - MD5: `9D6FF58DEEE24089D722C73169765B3E`
- Expected signing-key fingerprint (RSA key ID `FE507013`):
  `C804 A93D 36BE 0C73 3EA1 9644 7C10 60B7 FE50 7013`
  — "Security Onion Solutions, LLC &lt;info@securityonionsolutions.com&gt;"
- Verification procedure: see `reference/DOWNLOAD_AND_VERIFY_ISO.md` (read-only
  reference — cite, don't copy).
