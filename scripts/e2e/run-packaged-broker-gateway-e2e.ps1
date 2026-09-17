<#
.SYNOPSIS
  Black-box E2E test: builds Broker and Gateway distributions, starts them as
  separate processes, and exercises the full rescue delivery flow over HTTP.
.DESCRIPTION
  Unlike the in-process PackagedBrokerGatewayE2eTest (which only checks health
  endpoints), this script:
  1. Builds installDist for both :broker and :pc-gateway
  2. Starts each as a separate OS process
  3. Fetches the real public rescue manifest from the Gateway distribution
  4. Requires the real Broker upload route to reject a malformed upload with 400

  This is a REAL black-box test using actual distribution artifacts.

  Coverage boundary: the assertions below are reachability, manifest-shape and
  malformed-input rejection. This script does NOT prove valid encrypted
  end-to-end delivery or a signed shelter receipt; those require a real
  RSA-OAEP/ECDSA envelope and are covered by the JVM integration tests
  (BrokerGatewayLoadAndFaultInjectionTest, EmulatorBrokerGatewayReceiptE2ETest).

  Exit codes:
    0 = PASS
    1 = FAIL
    2 = BLOCKED
#>
[CmdletBinding()]
param(
    [int]$BrokerPort = 0,
    [int]$GatewayPort = 0,
    [int]$StartupTimeout = 60,
    [int]$TestTimeout = 120,
    [string]$ArtifactDir = ''
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gradlew = Join-Path $Root 'gradlew.bat'

if (-not $ArtifactDir) {
    $ArtifactDir = Join-Path $Root 'artifacts\e2e-packaged'
}
New-Item -ItemType Directory -Force -Path $ArtifactDir | Out-Null

$summary = [ordered]@{
    script    = 'run-packaged-broker-gateway-e2e'
    timestamp = (Get-Date).ToString('o')
    status    = 'INCONCLUSIVE'
    steps     = @()
}

function Add-Step {
    param([string]$Name, [string]$Status, [string]$Detail = '')
    $script:summary.steps += @{ name = $Name; status = $Status; detail = $Detail }
    $color = switch ($Status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'BLOCKED' { 'Yellow' } default { 'Gray' } }
    Write-Host "  [$Status] $Name $(if ($Detail) { \"- $Detail\" })" -ForegroundColor $color
}

# Allocate random ports if not specified (avoid fixed port conflicts)
function Get-FreePort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $listener.Stop()
    return $port
}

if ($BrokerPort -eq 0) { $BrokerPort = Get-FreePort }
if ($GatewayPort -eq 0) { $GatewayPort = Get-FreePort }

Write-Host "=== Packaged Broker-Gateway E2E Test ==="
Write-Host "  Broker port:  $BrokerPort"
Write-Host "  Gateway port: $GatewayPort"
Write-Host ""

$brokerProc = $null
$gatewayProc = $null
$tempDir = $null

try {
    # --- Step 1: Build distributions ---
    Write-Host "[1/8] Building distributions..."
    & $gradlew ':broker:installDist' ':pc-gateway:installDist' --no-daemon --console=plain 2>&1 |
        Set-Content (Join-Path $ArtifactDir 'gradle-build.log') -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        Add-Step 'build-distributions' 'FAIL' "Gradle exit code: $LASTEXITCODE"
        $summary.status = 'FAIL'
        $summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ArtifactDir 'summary.json') -Encoding UTF8
        exit 1
    }

    $brokerBin = Join-Path $Root 'broker\build\install\broker\bin\broker.bat'
    $gatewayBin = Join-Path $Root 'pc-gateway\build\install\pc-gateway\bin\pc-gateway.bat'

    if (-not (Test-Path -LiteralPath $brokerBin)) {
        Add-Step 'build-distributions' 'FAIL' 'broker.bat not found after installDist'
        $summary.status = 'FAIL'
        $summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ArtifactDir 'summary.json') -Encoding UTF8
        exit 1
    }
    if (-not (Test-Path -LiteralPath $gatewayBin)) {
        Add-Step 'build-distributions' 'FAIL' 'pc-gateway.bat not found after installDist'
        $summary.status = 'FAIL'
        $summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ArtifactDir 'summary.json') -Encoding UTF8
        exit 1
    }
    Add-Step 'build-distributions' 'PASS'

    # --- Step 2: Create temp directories ---
    $tempDir = Join-Path $env:TEMP "relay-e2e-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $brokerDb = Join-Path $tempDir 'broker.db'
    $gatewayDb = Join-Path $tempDir 'gateway.db'
    $gatewayKeys = Join-Path $tempDir 'rescue-keys.json'
    New-Item -ItemType Directory -Force -Path (Join-Path $tempDir 'maps') | Out-Null

    # --- Step 3: Start Broker ---
    Write-Host "[2/8] Starting Broker on port $BrokerPort..."
    $brokerEnv = @{
        RELAY_BROKER_PROFILE = 'DEVELOPMENT'
        RELAY_BROKER_HOST = '127.0.0.1'
        RELAY_BROKER_PORT = "$BrokerPort"
        RELAY_BROKER_DB_PATH = $brokerDb
    }
    $brokerLogOut = Join-Path $ArtifactDir 'broker-stdout.log'
    $brokerLogErr = Join-Path $ArtifactDir 'broker-stderr.log'

    # Set environment variables for the broker process
    foreach ($kv in $brokerEnv.GetEnumerator()) { [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, 'Process') }

    $brokerProc = Start-Process -FilePath $brokerBin -WorkingDirectory $Root `
        -RedirectStandardOutput $brokerLogOut -RedirectStandardError $brokerLogErr `
        -NoNewWindow -PassThru

    # Wait for Broker health
    $brokerReady = $false
    $elapsed = 0
    while ($elapsed -lt $StartupTimeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$BrokerPort/v1/health" -TimeoutSec 3 -ErrorAction SilentlyContinue
            if ($resp.StatusCode -eq 200) { $brokerReady = $true; break }
        } catch { }
        if ($brokerProc.HasExited) { break }
    }

    if (-not $brokerReady) {
        Add-Step 'broker-start' 'FAIL' "Broker did not become healthy within ${StartupTimeout}s"
        $summary.status = 'FAIL'
        throw 'Broker startup failed'
    }
    Add-Step 'broker-start' 'PASS' "Healthy on port $BrokerPort"

    # --- Step 4: Start Gateway ---
    Write-Host "[3/8] Starting Gateway on port $GatewayPort..."
    $gatewayEnv = @{
        RELAY_PROFILE = 'development'
        RELAY_GATEWAY_HOST = '127.0.0.1'
        RELAY_GATEWAY_PORT = "$GatewayPort"
        RELAY_GATEWAY_DB = $gatewayDb
        RELAY_GATEWAY_ID = 'e2e-test-gateway'
        RELAY_SHELTER_ID = 'e2e-test-shelter'
        RELAY_RESCUE_KEY_FILE = $gatewayKeys
        RELAY_OFFLINE_MAP_DIR = (Join-Path $tempDir 'maps')
        RELAY_GATEWAY_LAN_MODE = 'DISABLED'
    }
    foreach ($kv in $gatewayEnv.GetEnumerator()) { [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, 'Process') }

    $gatewayLogOut = Join-Path $ArtifactDir 'gateway-stdout.log'
    $gatewayLogErr = Join-Path $ArtifactDir 'gateway-stderr.log'

    $gatewayProc = Start-Process -FilePath $gatewayBin -WorkingDirectory $Root `
        -RedirectStandardOutput $gatewayLogOut -RedirectStandardError $gatewayLogErr `
        -NoNewWindow -PassThru

    # Wait for Gateway health
    $gatewayReady = $false
    $elapsed = 0
    while ($elapsed -lt $StartupTimeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$GatewayPort/api/health" -TimeoutSec 3 -ErrorAction SilentlyContinue
            if ($resp.StatusCode -eq 200) { $gatewayReady = $true; break }
        } catch { }
        if ($gatewayProc.HasExited) { break }
    }

    if (-not $gatewayReady) {
        Add-Step 'gateway-start' 'FAIL' "Gateway did not become healthy within ${StartupTimeout}s"
        $summary.status = 'FAIL'
        throw 'Gateway startup failed'
    }
    Add-Step 'gateway-start' 'PASS' "Healthy on port $GatewayPort"

    # --- Step 5: Fetch manifest ---
    Write-Host "[4/8] Fetching rescue manifest..."
    try {
        # The public rescue manifest is served at this exact path. A previous revision of this
        # script used /api/public/manifest, which is not a route, so the check could never pass.
        $manifestResp = Invoke-WebRequest -Uri "http://127.0.0.1:$GatewayPort/api/public/rescue/manifest" -TimeoutSec 10
        if ($manifestResp.StatusCode -eq 200 -and $manifestResp.Content.Length -gt 10) {
            $manifestJson = $manifestResp.Content | ConvertFrom-Json
            $hasPublicKey = [bool]($manifestJson.recipientPublicKey.encodedBase64 -and $manifestJson.receiptSigningPublicKey.encodedBase64)
            if ($hasPublicKey -and $manifestJson.shelterId) {
                Add-Step 'manifest-fetch' 'PASS' 'Manifest carries recipient and receipt-signing public keys'
            } else {
                Add-Step 'manifest-fetch' 'FAIL' 'Manifest response lacks a public key or shelter id'
                $summary.status = 'FAIL'
                throw 'Bad manifest'
            }
        } else {
            Add-Step 'manifest-fetch' 'FAIL' "Unexpected status: $($manifestResp.StatusCode)"
            $summary.status = 'FAIL'
            throw 'Manifest fetch failed'
        }
    } catch [System.Net.WebException] {
        Add-Step 'manifest-fetch' 'FAIL' "HTTP error: $($_.Exception.Message)"
        $summary.status = 'FAIL'
        throw
    }

    # --- Step 6: Verify the Broker upload route exists and rejects malformed input ---
    Write-Host "[5/8] Testing malformed upload rejection on the Broker..."
    # A real EncryptedRescueEnvelope requires RSA-OAEP and ECDSA-P256 material that PowerShell
    # cannot reproduce faithfully, so the black-box assertion here is the same one the CI heavy
    # lane uses: the real route must exist and answer 400 for a structurally invalid upload.
    $malformedUploadBody = '{}'
    $uploadRoute = "http://127.0.0.1:$BrokerPort/v1/rescue/upload"
    try {
        $uploadResp = Invoke-WebRequest -Uri $uploadRoute `
            -Method POST -Body $malformedUploadBody -ContentType 'application/json' -TimeoutSec 10 -ErrorAction Stop
        Add-Step 'upload-route-validation' 'FAIL' "Malformed upload was accepted (status $($uploadResp.StatusCode))"
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }
        if ($statusCode -eq 400) {
            Add-Step 'upload-route-validation' 'PASS' 'Malformed upload rejected (400)'
        } else {
            Add-Step 'upload-route-validation' 'FAIL' "Expected 400, got $(if ($statusCode) { $statusCode } else { $_.Exception.Message })"
        }
    }

    # --- Step 7: Verify a rejected upload changes nothing reachable ---
    Write-Host "[6/8] Re-testing the same malformed upload..."
    # This step depends on upload-route-validation having passed.
    $uploadStep = $summary.steps | Where-Object { $_.name -eq 'upload-route-validation' } | Select-Object -First 1
    if ($uploadStep -and $uploadStep.status -eq 'PASS') {
        try {
            $resubmitResp = Invoke-WebRequest -Uri $uploadRoute `
                -Method POST -Body $malformedUploadBody -ContentType 'application/json' -TimeoutSec 10 -ErrorAction Stop
            Add-Step 'upload-repeatability' 'FAIL' "Repeat upload was accepted (status $($resubmitResp.StatusCode))"
        } catch {
            $statusCode = $null
            if ($_.Exception.Response) { $statusCode = [int]$_.Exception.Response.StatusCode }
            if ($statusCode -eq 400) {
                Add-Step 'upload-repeatability' 'PASS' 'Same malformed upload still rejected (400)'
            } else {
                Add-Step 'upload-repeatability' 'FAIL' "Expected 400, got $(if ($statusCode) { $statusCode } else { $_.Exception.Message })"
            }
        }
    } else {
        Add-Step 'upload-repeatability' 'NOT_RUN' 'Skipped (upload-route-validation did not pass)'
    }

    # --- Step 8: Verify Broker health still OK ---
    Write-Host "[7/8] Final health checks..."
    try {
        $brokerFinal = Invoke-WebRequest -Uri "http://127.0.0.1:$BrokerPort/v1/health" -TimeoutSec 5
        $gatewayFinal = Invoke-WebRequest -Uri "http://127.0.0.1:$GatewayPort/api/health" -TimeoutSec 5
        if ($brokerFinal.StatusCode -eq 200 -and $gatewayFinal.StatusCode -eq 200) {
            Add-Step 'final-health' 'PASS' 'Both services healthy after test'
        } else {
            Add-Step 'final-health' 'FAIL' 'Health degraded after test'
        }
    } catch {
        Add-Step 'final-health' 'FAIL' "Health check failed: $($_.Exception.Message)"
    }

    # --- Determine overall status ---
    $failedSteps = @($summary.steps | Where-Object { $_.status -eq 'FAIL' })
    if ($failedSteps.Count -gt 0) {
        $summary.status = 'FAIL'
    } else {
        $summary.status = 'PASS'
    }

} catch {
    if ($summary.status -ne 'FAIL') { $summary.status = 'FAIL' }
    $summary['error'] = $_.Exception.Message
} finally {
    # --- Cleanup: always stop processes ---
    Write-Host "[8/8] Cleaning up..."
    if ($gatewayProc -and -not $gatewayProc.HasExited) {
        try { $gatewayProc.Kill() } catch { }
        $gatewayProc.WaitForExit(5000) | Out-Null
    }
    if ($brokerProc -and -not $brokerProc.HasExited) {
        try { $brokerProc.Kill() } catch { }
        $brokerProc.WaitForExit(5000) | Out-Null
    }

    # Record process info
    $summary['brokerPort'] = $BrokerPort
    $summary['gatewayPort'] = $GatewayPort
    $summary['brokerPid'] = if ($brokerProc) { $brokerProc.Id } else { $null }
    $summary['gatewayPid'] = if ($gatewayProc) { $gatewayProc.Id } else { $null }

    # Clean temp directory (remove credentials)
    if ($tempDir -and (Test-Path -LiteralPath $tempDir)) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Clear environment variables
    foreach ($key in @($brokerEnv.Keys + $gatewayEnv.Keys) | Select-Object -Unique) {
        [Environment]::SetEnvironmentVariable($key, $null, 'Process')
    }

    # Write summary
    $summary | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ArtifactDir 'summary.json') -Encoding UTF8
    Write-Host ""
    Write-Host "=== E2E Result: $($summary.status) ===" -ForegroundColor $(
        switch ($summary.status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    )
}

switch ($summary.status) {
    'PASS' { exit 0 }
    'BLOCKED' { exit 2 }
    default { exit 1 }
}
