[CmdletBinding()]
param(
    [string]$RepositoryUrl = "https://github.com/qrdgalbano-arch/qmmc_pd1_poc.git",
    [string]$ReleaseTag = "v0.1.0",
    [string]$ProjectDirectory = (Join-Path $HOME "Documents\qmmc_pd1_poc"),
    [switch]$ResetDatabase,
    [switch]$SkipSeed
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-CommandAvailable {
    param([string]$CommandName)
    return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Get-LanIPv4Address {
    $address = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Sort-Object -Property InterfaceIndex |
        Select-Object -First 1

    if ($null -eq $address) {
        throw "No usable LAN IPv4 address was found. Connect to Wi-Fi or Ethernet, then run the script again."
    }

    return $address.IPAddress
}

function New-SafeRandomString {
    param(
        [int]$Length,
        [string]$Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
    )

    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    try {
        $bytes = New-Object byte[] $Length
        $rng.GetBytes($bytes)
        return -join ($bytes | ForEach-Object { $Characters[$_ % $Characters.Length] })
    }
    finally {
        $rng.Dispose()
    }
}

function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & docker compose --env-file .\.env.production -f .\docker-compose.production.yml @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose command failed: docker compose $($Arguments -join ' ')"
    }
}

Write-Step "Checking required software"

if (-not (Test-CommandAvailable "git")) {
    throw "Git for Windows is required on the host PC. Install it, reopen PowerShell, and run this script again."
}

if (-not (Test-CommandAvailable "docker")) {
    throw "Docker Desktop is required on the host PC. Install and start it, then run this script again."
}

try {
    docker info | Out-Null
}
catch {
    throw "Docker Desktop is not running. Start Docker Desktop, wait until it is ready, then run this script again."
}

Write-Host "Git: $(git --version)"
Write-Host "Docker: $(docker --version)"
Write-Host "Compose: $(docker compose version)"

Write-Step "Getting the project release"

if (-not (Test-Path $ProjectDirectory)) {
    $parentDirectory = Split-Path -Parent $ProjectDirectory
    New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null

    git clone $RepositoryUrl $ProjectDirectory

    if ($LASTEXITCODE -ne 0) {
        throw "Could not clone the repository. Check internet access and repository permissions."
    }
}
else {
    Write-Host "Using existing project directory: $ProjectDirectory" -ForegroundColor Yellow
}

Set-Location $ProjectDirectory

if (-not (Test-Path .\docker-compose.production.yml)) {
    throw "docker-compose.production.yml was not found. Confirm ProjectDirectory points to the repository root."
}

if (-not (Test-Path .\.env.production.example)) {
    throw ".env.production.example was not found in the repository root."
}

git fetch --tags origin

if ($LASTEXITCODE -ne 0) {
    throw "Could not fetch release tags from origin."
}

git checkout $ReleaseTag

if ($LASTEXITCODE -ne 0) {
    throw "Could not check out release tag $ReleaseTag."
}

Write-Step "Converting container entrypoint to Linux line endings"

$entrypointPath = Resolve-Path .\backend\entrypoint.production.sh
$entrypointContent = Get-Content -LiteralPath $entrypointPath -Raw
$entrypointContent = $entrypointContent -replace "`r`n", "`n"

[System.IO.File]::WriteAllText(
    $entrypointPath,
    $entrypointContent,
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Step "Finding host network address"

$hostIp = Get-LanIPv4Address
Write-Host "Host LAN IP: $hostIp" -ForegroundColor Green

Write-Step "Preparing private local environment"

$environmentFile = Join-Path $ProjectDirectory ".env.production"

if (Test-Path $environmentFile) {
    Write-Host ".env.production already exists; preserving its current secrets and database settings." -ForegroundColor Yellow
}
else {
    $databasePassword = New-SafeRandomString -Length 36
    $jwtSecret = New-SafeRandomString -Length 64

@"
POSTGRES_DB=qmmc_pd1
POSTGRES_USER=qmmc_user
POSTGRES_PASSWORD=$databasePassword
DATABASE_URL=postgresql+psycopg://qmmc_user:$databasePassword@db:5432/qmmc_pd1

JWT_SECRET_KEY=$jwtSecret
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

ENVIRONMENT=production
DEBUG=false

CORS_ORIGINS=http://localhost,http://127.0.0.1,http://$hostIp
TRUSTED_HOSTS=localhost,127.0.0.1,$hostIp
"@ | Set-Content -LiteralPath $environmentFile -Encoding utf8

    Remove-Variable databasePassword, jwtSecret
    Write-Host "Created .env.production with new local-only secrets." -ForegroundColor Green
}

Write-Step "Checking that secrets are ignored by Git"

git check-ignore -v .\.env.production

if ($LASTEXITCODE -ne 0) {
    throw ".env.production is not ignored by Git. Stop and correct .gitignore before continuing."
}

Write-Step "Validating Docker Compose configuration"

Invoke-Compose config | Out-Host

if ($ResetDatabase) {
    Write-Step "Resetting local demonstration database"

    Write-Host "Warning: This removes the local Docker database volume and all POC records on this computer." -ForegroundColor Yellow

    Invoke-Compose down -v
}

Write-Step "Starting PostgreSQL, backend, and Nginx"

try {
    Invoke-Compose up -d --build
}
catch {
    Write-Host "Docker Compose reported a startup problem. The script will check health and display logs if needed." -ForegroundColor Yellow
}

Write-Step "Waiting for backend health"

$healthy = $false

for ($attempt = 1; $attempt -le 30; $attempt++) {
    try {
        $response = Invoke-RestMethod http://localhost/health -TimeoutSec 5

        if ($response.status -eq "healthy") {
            $healthy = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $healthy) {
    Write-Host "The backend did not become healthy. Recent container logs:" -ForegroundColor Red

    & docker compose --env-file .\.env.production -f .\docker-compose.production.yml logs --tail=150 backend nginx db

    throw "Deployment health check failed. If credentials were changed after an existing database was created, rerun with -ResetDatabase only when it is safe to erase local POC data."
}

Write-Host "Health endpoint is responding." -ForegroundColor Green

if (-not $SkipSeed) {
    Write-Step "Creating or verifying POC demonstration data"

    Invoke-Compose exec backend python -m scripts.seed_demo_users
    Invoke-Compose exec backend python -m scripts.seed_dashboard_demo_data
}

Write-Step "Local-network POC is ready"

Invoke-Compose ps

Write-Host ""
Write-Host "Host PC dashboard:" -ForegroundColor Green
Write-Host "  http://localhost/staff-dashboard"

Write-Host ""
Write-Host "Another PC on the same Wi-Fi/LAN:" -ForegroundColor Green
Write-Host "  http://$hostIp/staff-dashboard"

Write-Host ""
Write-Host "Phone browser network test:" -ForegroundColor Green
Write-Host "  http://$hostIp/health"

Write-Host ""
Write-Host "Demo staff login:" -ForegroundColor Yellow
Write-Host "  Email: staff@example.com"
Write-Host "  Password: StaffDemo123!"

Write-Host ""
Write-Host "Demo patient login:" -ForegroundColor Yellow
Write-Host "  Email: patient@example.com"
Write-Host "  Password: PatientDemo123!"

Write-Host ""
Write-Host "POC notice: Use demo/test data only. This local HTTP deployment is not for public or clinical use." -ForegroundColor Yellow