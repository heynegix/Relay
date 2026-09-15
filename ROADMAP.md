# Relay roadmap

Relay is a development-stage open-source project. This roadmap describes areas
of work, not promises or production dates. The project must not be described
as field-ready or production-ready until the readiness evidence supports that
statement.

## Current

- Keep the Android, PC Gateway, Broker, protocol, and shared model paths
  buildable and documented.
- Preserve honest delivery states and readiness tracking.
- Improve automated tests for malformed input, replay, downgrade, signature,
  storage, and failure paths.
- Make local development, synthetic-data drills, and contributor setup easier.
- Maintain dependency verification, CodeQL, secret scanning, workflow checks,
  fuzzing, API contract tests, and scheduled heavy validation.

## Near-term

- Add contributor-friendly examples and troubleshooting guides.
- Expand deterministic protocol and Broker integration fixtures.
- Improve physical-device test documentation and make evidence collection
  reproducible without implying that the tests have already run.
- Improve accessibility and error messages in the Android and Gateway UIs.
- Reduce stale documentation and keep the English entry points current.

## Medium-term

- Establish repeatable multi-device Nearby/BLE and real-LAN validation with
  approved test devices and synthetic data.
- Define operational ownership, regional trust provisioning, privacy review,
  retention policy, monitoring, backup/recovery, and incident procedures with
  responsible external stakeholders.
- Complete the release-signing and provenance process only when the required
  organizational keys, review, and distribution policy exist.

## Long-term

- Evaluate additional transports and platform support behind explicit protocol
  and security boundaries.
- Measure reliability, resource use, and recovery behavior in controlled,
  documented environments.
- Reassess whether any real-world deployment claim is justified by evidence,
  governance, and independent review.
