# Security isolation test for Travel Pivot RLS
# Account A = admin@memoryai.app, Account B = test@memoryai.app
# Requires .env with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY

param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            Set-Item -Path "Env:$($matches[1].Trim())" -Value $matches[2].Trim().Trim('"')
        }
    }
}

$base = $env:SUPABASE_URL
$key = $env:SUPABASE_PUBLISHABLE_KEY
if (-not $base -or -not $key) { Write-Error "Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY" }

function Get-Token($email, $password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    $r = Invoke-RestMethod -Method Post -Uri "$base/auth/v1/token?grant_type=password" `
        -Headers @{ apikey = $key; Authorization = "Bearer $key"; "Content-Type" = "application/json" } -Body $body
    return $r.access_token
}

function Rest-Get($path, $token) {
    return Invoke-RestMethod -Method Get -Uri "$base/rest/v1/$path" `
        -Headers @{ apikey = $key; Authorization = "Bearer $token"; Accept = "application/json" }
}

function Rest-Post($path, $body, $token) {
    return Invoke-RestMethod -Method Post -Uri "$base/rest/v1/$path" `
        -Headers @{ apikey = $key; Authorization = "Bearer $token"; "Content-Type" = "application/json"; Prefer = "return=representation" } `
        -Body ($body | ConvertTo-Json)
}

Write-Host "=== Security Isolation Test ==="

$tokenA = Get-Token "admin@memoryai.app" "admin"
$tokenB = Get-Token "test@memoryai.app" "test"

# Create private media for A (no trip, no family)
$media = Rest-Post "media_items" @{
    owner_id = (Invoke-RestMethod -Uri "$base/auth/v1/user" -Headers @{ apikey = $key; Authorization = "Bearer $tokenA" }).id
    media_type = "image"
    title = "Private A"
    metadata_status = "automatic"
    location_source = "unknown"
} $tokenA
$mediaId = $media[0].id
Write-Host "Created private media_items for A: $mediaId"

# Create private trip for A
$trip = Rest-Post "trips" @{
    owner_id = (Invoke-RestMethod -Uri "$base/auth/v1/user" -Headers @{ apikey = $key; Authorization = "Bearer $tokenA" }).id
    title = "Private Trip A"
    status = "planning"
} $tokenA
$tripId = $trip[0].id
Write-Host "Created private trip for A: $tripId"

# Create private person for A
$person = Rest-Post "people" @{
    owner_id = (Invoke-RestMethod -Uri "$base/auth/v1/user" -Headers @{ apikey = $key; Authorization = "Bearer $tokenA" }).id
    name = "Person A"
    detection_source = "manual"
} $tokenA
$personId = $person[0].id
Write-Host "Created private person for A: $personId"

$fail = $false

try {
    $rows = Rest-Get "media_items?id=eq.$mediaId&select=id" $tokenB
    if ($rows -and $rows.Count -gt 0) {
        Write-Host "FAIL: B can read A's media_items"
        $fail = $true
    } else { Write-Host "PASS: B cannot read A's media_items" }
} catch { Write-Host "PASS: B cannot read A's media_items (error)" }

try {
    $rows = Rest-Get "trips?id=eq.$tripId&select=id" $tokenB
    if ($rows -and $rows.Count -gt 0) {
        Write-Host "FAIL: B can read A's trips"
        $fail = $true
    } else { Write-Host "PASS: B cannot read A's trips" }
} catch { Write-Host "PASS: B cannot read A's trips (error)" }

try {
    $rows = Rest-Get "people?id=eq.$personId&select=id" $tokenB
    if ($rows -and $rows.Count -gt 0) {
        Write-Host "FAIL: B can read A's people"
        $fail = $true
    } else { Write-Host "PASS: B cannot read A's people" }
} catch { Write-Host "PASS: B cannot read A's people (error)" }

# B tries to update A's media (RLS should block or affect 0 rows)
$before = Rest-Get "media_items?id=eq.$mediaId&select=title" $tokenA
try {
    Invoke-RestMethod -Method Patch -Uri "$base/rest/v1/media_items?id=eq.$mediaId" `
        -Headers @{ apikey = $key; Authorization = "Bearer $tokenB"; "Content-Type" = "application/json" } `
        -Body '{"title":"Hacked"}' | Out-Null
} catch { }
$after = Rest-Get "media_items?id=eq.$mediaId&select=title" $tokenA
if ($after[0].title -eq "Hacked") {
    Write-Host "FAIL: B changed A's media_items title"
    $fail = $true
} else {
    Write-Host "PASS: B cannot change A's media_items"
}

if ($fail) { exit 1 }
Write-Host "=== All isolation checks passed ==="
