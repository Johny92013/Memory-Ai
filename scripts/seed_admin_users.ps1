# Seed Admin and Test users for Family Memories AI
#
# Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env or environment.
# NEVER commit the service role key.
# Set minimum password length to 4 in Supabase Auth settings.

param(
    [string]$ProjectUrl = $env:SUPABASE_URL,
    [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY
)

$ErrorActionPreference = "Stop"

function Load-DotEnv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Set-Item -Path "Env:$name" -Value $value
            }
        }
    }
}

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ProjectUrl)) {
    Load-DotEnv (Join-Path $root ".env")
    $ProjectUrl = $env:SUPABASE_URL
}
if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
    $ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY
}

if ([string]::IsNullOrWhiteSpace($ProjectUrl) -or [string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
    Write-Error "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required."
}

$authUrl = "$ProjectUrl/auth/v1/admin/users"
$headers = @{
    "apikey" = $ServiceRoleKey
    "Authorization" = "Bearer $ServiceRoleKey"
    "Content-Type" = "application/json"
}

function Ensure-User {
    param(
        [string]$Email,
        [string]$Password,
        [hashtable]$AppMetadata,
        [string]$Username,
        [string]$FirstName
    )

    $userId = $null

    $body = @{
        email = $Email
        password = $Password
        email_confirm = $true
        app_metadata = $AppMetadata
        user_metadata = @{
            first_name = $FirstName
        }
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Method Post -Uri $authUrl -Headers $headers -Body $body
        $userId = $response.id
        Write-Host "Created: $Email (id=$userId)"
    }
    catch {
        $err = $_.ErrorDetails.Message
        if ($err -match "already been registered") {
            Write-Host "Already exists: $Email - updating metadata"
            $listUrl = "$ProjectUrl/auth/v1/admin/users?email=$Email"
            $users = Invoke-RestMethod -Method Get -Uri $listUrl -Headers $headers
            $userId = $users.users[0].id
            $updateUrl = "$ProjectUrl/auth/v1/admin/users/$userId"
            $updateBody = @{
                password = $Password
                email_confirm = $true
                app_metadata = $AppMetadata
                user_metadata = @{
                    first_name = $FirstName
                }
            } | ConvertTo-Json -Depth 5
            Invoke-RestMethod -Method Put -Uri $updateUrl -Headers $headers -Body $updateBody | Out-Null
        }
        else {
            throw
        }
    }

    if (-not $userId) {
        $listUrl = "$ProjectUrl/auth/v1/admin/users?email=$Email"
        $users = Invoke-RestMethod -Method Get -Uri $listUrl -Headers $headers
        $userId = $users.users[0].id
    }

    $profileBody = @{
        id = $userId
        email = $Email
        username = $Username
        first_name = $FirstName
        profile_completed = $true
    } | ConvertTo-Json

    $restHeaders = @{
        "apikey" = $ServiceRoleKey
        "Authorization" = "Bearer $ServiceRoleKey"
        "Content-Type" = "application/json"
        "Prefer" = "resolution=merge-duplicates"
    }

    Invoke-RestMethod -Method Post -Uri "$ProjectUrl/rest/v1/profiles" -Headers $restHeaders -Body $profileBody | Out-Null
    Write-Host "Profile set: $Username"
}

Write-Host "Seed starting for $ProjectUrl"

Ensure-User -Email "admin@memoryai.app" -Password "admin" -AppMetadata @{ app_role = "admin" } -Username "admin" -FirstName "Admin"
Ensure-User -Email "test@memoryai.app" -Password "test" -AppMetadata @{ app_role = "user" } -Username "test" -FirstName "Test"

Write-Host "Seed complete."
Write-Host "Login: admin / admin or test / test"
