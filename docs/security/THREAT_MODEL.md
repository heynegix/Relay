# Relay threat model

This document describes the security boundaries and residual risks of the
current development-stage implementation. It is a design and review aid, not a
claim of formal certification, field safety, or complete threat coverage.

## Assets

- Rescue request content, including approximate location and free-text notes.
- Delivery metadata, receipts, staff status, and audit records.
- Android, Gateway, Broker, regional trust, and signing keys.
- Gateway credentials, staff sessions, enrollment material, and local stores.
- Build inputs, dependency metadata, release artifacts, and CI credentials.

## Components and paths

1. An Android app creates and stores a request locally.
2. The app can move an encrypted envelope through Nearby or an enrolled LAN
   path, or upload it to an HTTPS Broker.
3. The Broker stores opaque envelopes and a PC Gateway pulls them with a
   scoped Gateway credential.
4. The PC Gateway validates, stores, and processes requests, then can issue a
   signed receipt or staff-state update.
5. The app verifies supported receipts and displays a delivery state that is
   intentionally different from rescue completion.

## Adversaries

- A passive observer of Nearby, BLE, LAN, or Broker traffic.
- A malicious or compromised relay device that forwards, drops, duplicates,
  reorders, or modifies packets.
- A malicious or compromised Broker that can observe metadata, withhold or
  replay stored ciphertext, or return malformed data.
- A spoofed Gateway beacon, untrusted local client, or compromised Gateway.
- An attacker attempting malformed-packet denial of service, credential abuse,
  replay, downgrade, or privilege escalation.
- A compromised developer workstation, dependency, GitHub Action, or release
  credential.
- A person with offline access to an unlocked or improperly protected device,
  Gateway host, backup, log, or exported file.

## Security goals

- Keep rescue bodies opaque to intermediate relay devices and the Broker when
  the current envelope path is used.
- Reject malformed, oversized, expired, unsupported, unauthorized, or
  cryptographically invalid input at defined boundaries.
- Make duplicate delivery and selected replay paths observable and
  non-destructive.
- Prevent lower-trust or older state from silently overwriting stronger
  verified state where the current policy covers that transition.
- Minimize sensitive data in logs and audit records.
- Make automated verification and known external blockers visible.

## Threat analysis

| Threat | Current mitigation | Residual risk / limitation |
|---|---|---|
| Packet tampering | Envelope validation, AES-GCM authentication, signatures where the protocol requires them | Key trust, endpoint compromise, and all protocol paths still require review |
| Malicious relay node | Relays receive routing metadata and opaque ciphertext; hop/TTL/size checks limit forwarding | A relay can drop, delay, duplicate, or selectively forward traffic |
| Compromised Broker | Broker validates structure/signatures and stores opaque envelopes with limits, TTLs, deduplication, and rate limits | Broker can observe metadata, withhold data, or deny service; it is not trusted for availability |
| Compromised Gateway | Enrollment, scoped credentials, roles, local authorization, audit logging, and fail-closed production profile | A compromised Gateway can access data it is authorized to decrypt and can mis-handle operations |
| Replay | Envelope expiry, idempotent IDs, delivery ledgers, receipt/signature checks, and nonce/replay guards on covered ingress paths | Replay resistance is path-specific; availability attacks and old valid data remain possible |
| Downgrade | Version checks, validation, signed-state rules, and rejection of unsupported transitions | Compatibility code and legacy formats need continued review |
| Malformed input | Bounded body sizes, schema/model validation, fuzzing and negative tests | Not every deployment or third-party integration has equal test coverage |
| Credential theft | Scoped credentials, session-token hashing, Keystore/DPAPI options, and explicit enrollment | Host compromise, operator mistakes, backups, and unencrypted development material remain risks |
| Sensitive logging | Coarse security events and redaction rules | A future code path can regress; log review and tests must continue |
| Supply-chain compromise | Pinned Actions, dependency verification, Dependabot, CodeQL, gitleaks, dependency review, Scorecard, and provenance gates | No automated control proves that every dependency or runner is trustworthy |

## Explicit non-goals

Relay does not currently guarantee delivery, availability, anonymity, correct
rescue decisions, authenticity of arbitrary official-information feeds, secure
operation on a compromised endpoint, protection from RF jamming, or recovery
from every key-loss and infrastructure failure. It does not replace official
emergency channels.

## Validation references

- Protocol and cryptography tests: `shared/src/*Test` and
  `relay-protocol/src/test`.
- Broker/API tests: `broker/src/test`, `tools/api-contract`, and the Broker
  workflow checks.
- Gateway security tests: `pc-gateway/src/test` and
  `docs/PC_GATEWAY_SECURITY.md`.
- Fuzz and fault-injection material: `fuzz-jvm` and `test-lab`.
- Readiness evidence: `docs/readiness/status.yml`.
