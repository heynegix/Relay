@file:Suppress("MaxLineLength")
package com.example.relay.pcgateway

import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class RegionalDeploymentProfileTest {
    @Test fun missingProfileIsNeutral() {
        val p = RegionalDeploymentProfileLoader.load(java.nio.file.Path.of("does-not-exist.json"))
        assertEquals("global", p.regionId)
        assertEquals(false, p.map.enabled)
    }
    @Test fun internationalProfileSupportsTimezoneAndAntimeridian() {
        val f = Files.createTempFile("regional-profile-", ".json")
        Files.writeString(f, """{"regionId":"example-pacific","displayName":"Configured Pacific region","countryCode":"NZ","timezoneId":"Pacific/Auckland","defaultLocale":"en-NZ","supportedLocales":["en-NZ"],"map":{"enabled":true,"initialLatitude":-40.9,"initialLongitude":174.8,"initialZoom":10,"south":-42.0,"north":-34.0,"west":170.0,"east":-175.0,"minZoom":8,"maxNativeZoom":10,"maxZoom":14,"tileTemplate":"https://tiles.example.invalid/{z}/{x}/{y}.png","attribution":"Example map provider"},"officialInfo":{"enabled":true,"providerName":"Example authority","endpoint":"https://alerts.example.invalid/feed","format":"CAP_1_2","sources":[{"title":"Example authority","organization":"Example authority","url":"https://authority.example.invalid/alerts"}]}}""")
        val p = RegionalDeploymentProfileLoader.load(f)
        assertEquals("Pacific/Auckland", p.timezoneId)
        assertEquals(170.0, p.map.west, 0.0)
        assertEquals(-175.0, p.map.east, 0.0)
        Files.deleteIfExists(f)
    }
    @Test fun invalidExistingProfileFailsClosed() {
        val f = Files.createTempFile("regional-profile-invalid-", ".json")
        Files.writeString(f, """{"regionId":"INVALID","displayName":"","timezoneId":"bad"}""")
        assertThrows(IllegalArgumentException::class.java) { RegionalDeploymentProfileLoader.load(f) }
        Files.deleteIfExists(f)
    }
}
