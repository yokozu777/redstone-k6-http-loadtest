# Profile: default, light, heavy, or spike.
# TargetHost, Endpoints, InstallLocalCert (true|false), and RemoteCaUrl match the shell script.
param(
    [Parameter(Position = 0)]
    [ValidateSet("default", "light", "heavy", "spike")]
    [string]$Profile = $(if ($env:PROFILE) { $env:PROFILE } else { "default" }),

    [string]$TargetHost = $(if ($env:TARGET_HOST) { $env:TARGET_HOST } else { "https://change-me.example/" }),

    [string]$Endpoints = $(if ($env:ENDPOINTS) { $env:ENDPOINTS } else { "/" }),

    [ValidateSet("true", "false")]
    [string]$InstallLocalCert = $(if ($env:INSTALL_LOCAL_CERT) { $env:INSTALL_LOCAL_CERT } else { "false" }),

    [string]$RemoteCaUrl = $(if ($null -ne $env:REMOTE_CA_URL) { $env:REMOTE_CA_URL } else { "" })
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

switch ($Profile) {
    "default" {
        $config = "default.json"
        $result = "results.json"
        $k6Extra = @("--vus", "200", "--duration", "10m")
    }
    "light" {
        $config = "light-load.json"
        $result = "light.json"
        $k6Extra = @()
    }
    "heavy" {
        $config = "heavy-load.json"
        $result = "heavy.json"
        $k6Extra = @()
    }
    "spike" {
        $config = "spike-test.json"
        $result = "spike.json"
        $k6Extra = @()
    }
}

New-Item -ItemType Directory -Force -Path results | Out-Null

Write-Host "Building the image (INSTALL_LOCAL_CERT=$InstallLocalCert)..."
docker build `
    --build-arg "INSTALL_LOCAL_CERT=$InstallLocalCert" `
    --build-arg "REMOTE_CA_URL=$RemoteCaUrl" `
    -t ph-loadtest .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Starting profile '$Profile' against $TargetHost"
Write-Host "Paths: $Endpoints"
Write-Host "Results: results/$result"

$userArgs = @()
if (Get-Command id -ErrorAction SilentlyContinue) {
    $userArgs = @("--user", "$((id -u)):$((id -g))")
}

docker run --rm -it @userArgs `
    -e "TARGET_HOST=$TargetHost" `
    -e "ENDPOINTS=$Endpoints" `
    -v "${PWD}/results:/app/results" `
    ph-loadtest `
    -c "/app/config/$config" run --out "json=/app/results/$result" @k6Extra /app/loadtest.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Profile '$Profile' finished. Results are in results/$result"
