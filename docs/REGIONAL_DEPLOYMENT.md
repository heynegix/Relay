# Regional deployment

Relay's current source tree contains no real municipality, administrative code, precise deployment coordinates, or government URL.

Set \`RELAY_REGIONAL_PROFILE=/path/to/profile.json\`. The profile supplies a stable region identifier, display name, ISO country code, IANA timezone, locales, bounded offline-map settings, tile attribution, and official-information endpoint/format.

The default profile is neutral: maps and official feeds are disabled until an operator supplies a profile. This prevents a public build from revealing an operator's location or silently presenting one jurisdiction's alerts in another.

Supported formats are JMA Bosai JSON, JMA XML Atom, and OASIS CAP 1.2. Live content is labelled transport-TLS-only; cached content is labelled unverified. Relay does not claim publisher authenticity unless a separate signed trust root is configured.

Map bounds can cross the antimeridian (\`west > east\`). Tile downloads are HTTPS-only, bounded, and written atomically. Profiles must not contain secrets, private addresses, or personal data.

Android reads \`relay-regional-profile.json\` from packaged assets; the supplied example has no official links. Historical commits are intentionally unchanged.
