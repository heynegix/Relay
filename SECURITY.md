# Security policy

Relay is a development-stage project that handles rescue-related data across Android devices, nearby transports, LAN paths, an HTTPS Broker, and a PC Gateway. Security reports are welcome, but the project has not undergone an independent formal security audit and is not suitable for real-disaster emergency dispatch.

## Scope and reporting

Please report suspected vulnerabilities privately before public disclosure. Do not include rescue content, GPS, access tokens, private keys, passwords, or production credentials in a GitHub issue.

Until a dedicated security contact is published by the project owner, use [GitHub’s private vulnerability-reporting form for Relay](https://github.com/heynegix/Relay/security/advisories/new). If that feature is unavailable, contact the repository owner through a private channel and include only the minimum reproducible, sanitized information.

## What to include

- affected component and version/commit;
- concise reproduction steps using synthetic data only;
- expected and observed security impact;
- whether the issue could expose a staff session, shelter scope, private key, rescue content, GPS, or release artifact.

Use synthetic data only. If a reproduction requires a real person, device, shelter, network, or emergency service, stop and describe the setup at a safe level instead of testing against it.

## Coordinated disclosure

The maintainers aim to acknowledge a report within 14 days, assess impact, and coordinate a remediation and disclosure timeline with the reporter. No fixed remediation SLA is promised for this development-stage repository. Do not exploit a vulnerability against real users, shelters, networks, or emergency services.

## Current boundary

Relay is under development-preview validation. A report, patch, test, or Release artifact does not make it suitable for real-disaster emergency dispatch. See [project readiness](docs/readiness/READINESS_TABLE.md) and the security design documents:

- [Threat model](docs/security/THREAT_MODEL.md)
- [Security architecture](docs/security/SECURITY_ARCHITECTURE.md)
- [Trust boundaries](docs/security/TRUST_BOUNDARIES.md)

Automated tests, CodeQL, dependency checks, secret scanning, fuzzing, and protocol tests are evidence about the checked paths only. They do not prove safety on every Android device, radio environment, LAN, Broker deployment, Gateway installation, or field operation.
