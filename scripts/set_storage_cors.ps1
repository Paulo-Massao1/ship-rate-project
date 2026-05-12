param(
  [string]$Bucket = "gs://shiprate-daf18.firebasestorage.app"
)

$ErrorActionPreference = "Stop"

function Find-Tool {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandName,

    [Parameter(Mandatory = $true)]
    [string[]]$CandidatePaths
  )

  $command = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  foreach ($candidate in $CandidatePaths) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  return $null
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$configDir = Join-Path $repoRoot ".gcloud-cli"
if (-not (Test-Path $configDir)) {
  New-Item -ItemType Directory -Path $configDir | Out-Null
}
$env:CLOUDSDK_CONFIG = $configDir

$gcloudPath = Find-Tool -CommandName "gcloud" -CandidatePaths @(
  "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
  "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
  "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
)

if (-not $gcloudPath) {
  throw @"
Google Cloud CLI was not found.

Install Google Cloud CLI, then run:
  gcloud auth login
  gcloud config set project shiprate-daf18

Official docs:
  https://cloud.google.com/sdk/docs/install
"@
}

$activeAccount = & $gcloudPath auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $activeAccount) {
  throw @"
No active Google Cloud login was found for the local config directory:
  $configDir

Run these commands first in this same terminal:

  `$env:CLOUDSDK_CONFIG = "$configDir"
  & "$gcloudPath" auth login
  & "$gcloudPath" config set project shiprate-daf18

Then run this script again.
"@
}

Write-Host ("Using CLOUDSDK_CONFIG at {0}" -f $configDir) -ForegroundColor DarkGray
Write-Host ("Applying CORS from cors.json to {0}..." -f $Bucket) -ForegroundColor Cyan
& $gcloudPath storage buckets update $Bucket --cors-file=cors.json

Write-Host ""
Write-Host ("Current CORS for {0}:" -f $Bucket) -ForegroundColor Cyan
& $gcloudPath storage buckets describe $Bucket --format="default(cors_config)"
