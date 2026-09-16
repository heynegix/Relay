# Contributing to Relay

Thank you for helping inspect, test, document, and improve Relay. Relay is an
open-source, development-stage project for moving rescue-related information
across unstable connectivity. It is not an official emergency service and it
must not be tested against real emergencies, real rescue operations, or real
personal data.

Read the [Code of Conduct](CODE_OF_CONDUCT.md) and [Security Policy](SECURITY.md)
before contributing.

## Before you start

- Use synthetic names, locations, keys, tokens, and rescue records.
- Check existing Issues and the [roadmap](ROADMAP.md) before starting larger work.
- Ask first before changing the wire protocol, cryptographic behavior, trust
  roots, readiness definitions, release workflows, or data-retention policy.
- Do not claim device-tested, field-tested, pilot-ready, or production-ready
  behavior without the evidence required by `docs/readiness/status.yml`.

## Development environment

The main development paths use:

- JDK 17
- Android SDK / API 36
- Git
- Gradle through the checked-in wrapper
- Node.js for `staff-console-e2e`
- Docker when running Broker/Gateway integration or resilience tests
- Windows PowerShell for the PC Gateway and device-test scripts

Clone the repository and create a short-lived branch from `main`:

```bash
git clone https://github.com/heynegix/Relay.git
cd Relay
git switch -c <type>/<short-description>
```

Examples: `docs/clarify-local-pilot`, `test/add-envelope-case`,
`fix/gateway-error-message`.

## Build and test

Use the wrapper so the repository-pinned Gradle version is used.

```bash
./gradlew :shared:jvmTest :relay-protocol:test :app:testDebugUnitTest :pc-gateway:test :broker:test
```

On Windows:

```powershell
.\gradlew.bat :shared:jvmTest :relay-protocol:test :app:testDebugUnitTest :pc-gateway:test :broker:test
```

Useful additional checks include:

```powershell
python tools/readiness/readiness_tool.py validate
python tools/readiness/readiness_tool.py check
.\scripts\verify-implementation-contracts.ps1
```

For the staff-console browser tests:

```bash
cd staff-console-e2e
npm ci
npx playwright install chromium
npm test
```

The exact GitHub Actions matrix is authoritative for CI. Pull requests run
build, unit, lint, security, readiness, and applicable integration checks;
heavier E2E, fuzzing, resilience, and reproducibility checks may run in
separate workflows or on a schedule.

## What to test

For code changes, add or update the smallest relevant automated test. Changes
to protocol parsing, encryption, signatures, replay handling, downgrade
handling, authentication, authorization, or sensitive logging require tests
for both the expected path and rejection/failure paths.

Changes involving Nearby, BLE, Android permissions, background behavior,
battery/Doze, multiple devices, RF conditions, or real LAN topology also need
the relevant script or test-lab documentation. A local unit test is not a
substitute for physical-device evidence.

## Documentation-only changes

Documentation changes should:

- use current repository paths and `heynegix/Relay` URLs;
- preserve the readiness and emergency-safety disclaimers;
- distinguish implemented, automatically tested, emulator-tested,
  device-tested, and field-tested behavior;
- avoid invented adoption, deployment, contributor, or reliability numbers;
- include link or command validation where practical.

## Branches, commits, and pull requests

- Keep branches focused and based on `main`.
- Use a clear imperative or conventional commit subject, for example
  `docs: clarify Broker limitations` or `test: cover replay rejection`.
- Do not commit credentials, private keys, personal rescue data, generated
  local databases, or unsigned artifacts as if they were production releases.
- Open a pull request using the repository template and explain the scope,
  validation, security/privacy impact, compatibility, physical-device testing,
  and readiness impact.
- Keep generated readiness files synchronized by editing
  `docs/readiness/status.yml` and running the readiness tool.
- Respond to CI and review feedback with follow-up commits; do not force-push
  shared branches unless the reviewer agrees.

## Security issues

Do not open a public Issue for a suspected vulnerability. Follow
[SECURITY.md](SECURITY.md) and use GitHub private vulnerability reporting when
available. Include only sanitized reproduction details and synthetic data.

## Readiness evidence

Readiness is managed in `docs/readiness/status.yml`. Code and automated tests
may support `IMPLEMENTED` and `AUTOMATED_TESTED`, but they do not promote a
feature to `DEVICE_TESTED` or `FIELD_TESTED`. Those states require dated,
reviewable external evidence and must not be added speculatively.

## Review priorities

Reviewers will prioritize correctness, safe failure, privacy, protocol
compatibility, honest status reporting, and reproducibility. A smaller patch
with clear tests and documentation is generally easier to review than a broad
feature bundle.
