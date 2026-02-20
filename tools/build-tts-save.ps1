param(
  [string]$OutputDir = "../tts/package",
  [string]$SaveFileName = "Severance-Tabletop-Playtest.json",
  [string]$ZipFileName = "Severance-Tabletop-Playtest.zip"
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptsDir = Join-Path $repoRoot 'tts/scripts'
$globalLuaPath = Join-Path $scriptsDir 'Global.lua'
$uiXmlPath = Join-Path $scriptsDir 'ui.xml'

if (!(Test-Path $globalLuaPath)) {
  throw "Missing Global.lua at: $globalLuaPath"
}

if (!(Test-Path $uiXmlPath)) {
  throw "Missing ui.xml at: $uiXmlPath"
}

$globalLua = Get-Content -Path $globalLuaPath -Raw -Encoding UTF8
$uiXml = Get-Content -Path $uiXmlPath -Raw -Encoding UTF8

$outDirAbs = Resolve-Path (Join-Path $PSScriptRoot $OutputDir) -ErrorAction SilentlyContinue
if ($null -eq $outDirAbs) {
  $outDirAbs = Join-Path $PSScriptRoot $OutputDir
  New-Item -ItemType Directory -Path $outDirAbs -Force | Out-Null
} else {
  $outDirAbs = $outDirAbs.Path
}

$savePath = Join-Path $outDirAbs $SaveFileName
$zipPath = Join-Path $outDirAbs $ZipFileName
$readmePath = Join-Path $outDirAbs 'README-LOAD.txt'

$save = [ordered]@{
  SaveName = 'Severance Tabletop Playtest'
  Date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  VersionNumber = 'v13.4.0'
  GameMode = ''
  GameType = ''
  GameComplexity = ''
  Tags = @('Card Game', 'Custom', 'Severance')
  Gravity = 0.5
  PlayArea = 0.5
  Table = 'Table_Rounded'
  Sky = 'Sky/Cloudy'
  Note = 'Local playtest save generated from Severance-Tabletop scripts.'
  Rules = 'Use Build Presence Deck / Build Absence Deck buttons. Requires local API at http://127.0.0.1:8787.'
  LuaScript = $globalLua
  LuaScriptState = ''
  XmlUI = $uiXml
  ObjectStates = @()
  TabStates = @{}
}

$save | ConvertTo-Json -Depth 50 | Set-Content -Path $savePath -Encoding UTF8

$readme = @"
Severance Tabletop Playtest Save

Files:
- $SaveFileName (drop in your TTS Saves folder)

Install:
1) Close Tabletop Simulator.
2) Copy $SaveFileName into:
   Documents\My Games\Tabletop Simulator\Saves
3) Open Tabletop Simulator.
4) Click Create -> Singleplayer -> Saved Games.
5) Load 'Severance Tabletop Playtest'.

Runtime requirement:
- Local API must be available at http://127.0.0.1:8787
"@

Set-Content -Path $readmePath -Value $readme -Encoding UTF8

if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

Compress-Archive -Path $savePath, $readmePath -DestinationPath $zipPath -CompressionLevel Optimal

Write-Output "Created save: $savePath"
Write-Output "Created package: $zipPath"
