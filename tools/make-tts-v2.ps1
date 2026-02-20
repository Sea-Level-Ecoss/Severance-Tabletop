$ErrorActionPreference = 'Stop'

$repo = 'c:\Users\broki\OneDrive\Desktop\Sea Level\Severance-Tabletop'
$saves = 'C:\Users\broki\OneDrive\Documents\My Games\Tabletop Simulator\Saves'
$baseJson = Join-Path $saves 'TS_Save_20.json'
$basePng = Join-Path $saves 'TS_Save_20.png'
$outBase = 'Severance_Tabletop_Playtest_v2'
$outJson = Join-Path $saves ($outBase + '.json')
$outPng = Join-Path $saves ($outBase + '.png')

$lua = Get-Content -Path (Join-Path $repo 'tts\scripts\Global.lua') -Raw -Encoding UTF8
$xml = Get-Content -Path (Join-Path $repo 'tts\scripts\ui.xml') -Raw -Encoding UTF8

$json = Get-Content -Path $baseJson -Raw -Encoding UTF8 | ConvertFrom-Json
$json.SaveName = 'Severance Tabletop Playtest'
if ($json.PSObject.Properties.Name -contains 'GameMode') { $json.GameMode = 'Severance Tabletop Playtest' }
if ($json.PSObject.Properties.Name -contains 'Note') { $json.Note = 'Severance playtest save (template-based for compatibility).' }
$json.LuaScript = $lua
$json.LuaScriptState = ''
$json.XmlUI = $xml

$json | ConvertTo-Json -Depth 100 | Set-Content -Path $outJson -Encoding UTF8

if (Test-Path $basePng) {
  Copy-Item -Path $basePng -Destination $outPng -Force
}

$check = Get-Content -Path $outJson -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "json=$outJson"
Write-Output "png=$outPng"
Write-Output "name=$($check.SaveName)"
Write-Output "lua_len=$(([string]$check.LuaScript).Length)"
Write-Output "xml_len=$(([string]$check.XmlUI).Length)"
