$ErrorActionPreference = 'Stop'

$repo = 'c:\Users\broki\OneDrive\Desktop\Sea Level\Severance-Tabletop'
$savesDir = 'C:\Users\broki\OneDrive\Documents\My Games\Tabletop Simulator\Saves'
$out = Join-Path $savesDir 'Severance_Tabletop_Playtest_v1.json'

$luaPath = Join-Path $repo 'tts\scripts\Global.lua'
$xmlPath = Join-Path $repo 'tts\scripts\ui.xml'

$lua = Get-Content -Path $luaPath -Raw -Encoding UTF8
$xml = Get-Content -Path $xmlPath -Raw -Encoding UTF8

$obj = [ordered]@{
  SaveName = 'Severance Tabletop Playtest'
  EpochTime = [int][double]::Parse((Get-Date -UFormat %s))
  Date = (Get-Date).ToString('M/d/yyyy h:mm:ss tt')
  VersionNumber = 'v13.4.0'
  GameMode = ''
  GameType = ''
  GameComplexity = ''
  Tags = @('Card Game','Custom','Severance')
  Gravity = 0.5
  PlayArea = 0.5
  Table = 'Table_Rounded'
  Sky = 'Sky/Cloudy'
  Note = 'Local playtest save generated from Severance-Tabletop scripts.'
  TabStates = @{}
  LuaScript = $lua
  LuaScriptState = ''
  XmlUI = $xml
  ObjectStates = @()
}

New-Item -ItemType Directory -Path $savesDir -Force | Out-Null
$obj | ConvertTo-Json -Depth 50 | Set-Content -Path $out -Encoding UTF8

$check = Get-Content -Path $out -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "save_name=$($check.SaveName)"
Write-Output "lua_len=$(([string]$check.LuaScript).Length)"
Write-Output "xml_len=$(([string]$check.XmlUI).Length)"
Write-Output "out=$out"
