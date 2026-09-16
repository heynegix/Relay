# Relay security architecture

This document records the security-relevant design currently implemented or
explicitly bounded by the repository. It should be updated with code changes;
it must not be used to infer guarantees that are not backed by tests or
external evidence.

## Component responsibilities

| Component | Security responsibility | Trust position |
|---|---|---|
| Android app | Create requests, encrypt envelopes, protect local storage, manage consent and transport state | Holds the user-side plaintext and private device keys |
| Nearby / BLE transport | Carry bounded protocol data and routing metadata | Untrusted transport; can drop, duplicate, reorder, or modify traffic |
| LAN Bridge / Gateway path | Deliver data to an enrolled Gateway over the local path | Authenticated only where the path-specific credential/signature checks pass |
| HTTPS Broker | Register devices, accept opaque envelopes, deduplicate, expire, rate-limit, and serve scoped pulls | Delivery intermediary; not trusted to decrypt rescue bodies or provide availability |
| PC Gateway | Authenticate staff, validate/store requests, apply roles, issue receipts, and record minimal audit data | Operational endpoint; must be provisioned and protected by its operator |
| Regional trust data | Bind configured shelter/Gateway manifests to a signing hierarchy | External trust authority; no production root is bundled in this repository |
| CI/release tooling | Test, scan, verify dependencies, and gate artifact publication | Supply-chain boundary; runner and credentials remain external risks |

## Cryptographic and integrity mechanisms

- Rescue envelopes use AES-256-GCM content encryption in the current Android/JVM
  implementations. The content key is wrapped for the intended recipient;
  relay nodes and the Broker are not given the recipient private key.
- ECDSA P-256 with SHA-256 is used for the current report, receipt, and trust
  document signatures where those protocol objects require signatures.
- Android report signing keys are generated in Android Keystore and are not
  exported by `ReportSigningKeyStore`.
- Android local database protection uses Room with SQLCipher and a Keystore-
  protected passphrase in the production path; migration and device evidence
  remain separate readiness concerns.
- Gateway credential/session protections, private-key file permissions, and
  optional Windows DPAPI behavior are documented in
  [`docs/PC_GATEWAY_SECURITY.md`](../PC_GATEWAY_SECURITY.md). Optional DPAPI
  is not HSM, TPM, KMS, or a substitute for host security.

## Authentication and authorization

- Gateway enrollment requires more than discovery; fingerprint confirmation
  and path-specific enrollment checks are used where implemented.
- Broker Gateway pulls use scoped Gateway credentials and shelter/Gateway
  identity checks.
- PC Gateway staff sessions use hashed session tokens and role checks.
- `ADMIN`, `OPERATOR`, and `VIEWER` roles are intentionally distinct.
- UDP discovery and public beacons are not treated as authentication.
- Development-only compatibility paths must not be described as production
  trust mechanisms.

## Replay, downgrade, and malformed data

- Envelope IDs, TTL/expiry, hop limits, delivery ledgers, idempotent storage,
  path-specific nonce caches, and signature verification address replay or
  duplicate processing where the current implementation covers the path.
- Version negotiation and validation reject unsupported protocol versions.
- State-merge rules reject selected downgrades and preserve stronger verified
  state in the covered repositories.
- Size limits and structured validation are applied before expensive parsing or
  storage on the Broker and Gateway paths. Fuzzing and negative tests cover
  decoder and protocol boundaries.
- These are not universal guarantees: every new transport or compatibility
  adapter must add its own threat analysis and tests.

## Logging and data minimization

Security events record coarse categories such as authentication failures,
invalid proofs, rate limiting, and authorization rejection. Logs and audit
records are intended not to contain rescue bodies, GPS, ciphertext, passwords,
session tokens, private keys, Broker credentials, or exception text. Exported
formula-looking cells are neutralized for spreadsheet safety.

Developers must treat diagnostic additions as security-sensitive. Prefer a
stable event code and redacted identifiers over request bodies, URLs with
credentials, raw headers, or stack traces containing user data.

## Supply-chain controls

The repository includes pinned GitHub Actions, Gradle dependency verification,
Dependabot, dependency review, CodeQL, gitleaks, actionlint/zizmor checks,
OpenSSF Scorecard, fuzzing, and release/provenance gates. These controls are
reviewed in CI; their presence is not an independent audit or a guarantee that
an artifact is safe for emergency operation.
