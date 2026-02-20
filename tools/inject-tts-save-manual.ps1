param(
  [int]$SaveSlot = 20,
  [string]$SaveName = '[DEV] Severance Playtest'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$injector = Join-Path $PSScriptRoot 'inject-tts-save.js'
$savesDir = 'C:/Users/broki/OneDrive/Documents/My Games/Tabletop Simulator/Saves'

if (!(Test-Path $injector)) {
  throw "Missing injector script: $injector"
}

if (!(Test-Path $savesDir)) {
  throw "Missing TTS saves directory: $savesDir"
}

$targetJson = Join-Path $savesDir ("TS_Save_{0}.json" -f $SaveSlot)
$targetPng = Join-Path $savesDir ("TS_Save_{0}.png" -f $SaveSlot)
$autoJson = Join-Path $savesDir 'TS_AutoSave.json'
$autoPng = Join-Path $savesDir 'TS_AutoSave.png'

if (!(Test-Path $targetJson)) {
  if (!(Test-Path $autoJson)) {
    throw "Cannot initialize manual slot; missing auto save template: $autoJson"
  }
  Copy-Item -Path $autoJson -Destination $targetJson -Force
  if ((Test-Path $autoPng) -and !(Test-Path $targetPng)) {
    Copy-Item -Path $autoPng -Destination $targetPng -Force
  }
}

$nodeArgs = @(
  $injector,
  $targetJson,
  $SaveName
)

$env:TTS_INJECT_SKIP_BACKUP = '1'
& node @nodeArgs
Remove-Item Env:TTS_INJECT_SKIP_BACKUP -ErrorAction SilentlyContinue

Write-Output "manual_slot=$SaveSlot"
Write-Output "manual_save=$targetJson"
