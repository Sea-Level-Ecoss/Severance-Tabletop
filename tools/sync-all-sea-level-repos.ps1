param(
  [string]$RootDir = "$HOME/Sea Level"
)

$ErrorActionPreference = 'Stop'

$repos = @(
  @{ Name = 'AntiPwr.github.io'; Url = 'https://github.com/Sea-Level-Ecoss/antipwr.github.io.git'; Branch = 'main' },
  @{ Name = 'Seventh-Severance-Unity'; Url = 'https://github.com/Sea-Level-Ecoss/Seventh-Severance-Unity.git'; Branch = 'main' },
  @{ Name = 'Sea-Level-Launcher'; Url = 'https://github.com/Sea-Level-Ecoss/Sea-Level-Launcher.git'; Branch = 'main' },
  @{ Name = 'Severance-Tabletop'; Url = 'https://github.com/Sea-Level-Ecoss/Severance-Tabletop.git'; Branch = 'main' },
  @{ Name = 'VivBot'; Url = 'https://github.com/Sea-Level-Ecoss/Viv-Bot.git'; Branch = 'main' },
  @{ Name = 'GrilwurtBot'; Url = 'https://github.com/Sea-Level-Ecoss/Grilwurt-Bot.git'; Branch = 'main' }
)

if (!(Test-Path $RootDir)) {
  New-Item -ItemType Directory -Path $RootDir -Force | Out-Null
}

foreach ($repo in $repos) {
  $target = Join-Path $RootDir $repo.Name
  Write-Output "=== $($repo.Name) ==="

  if (!(Test-Path $target)) {
    git clone $repo.Url $target
  }

  if (!(Test-Path (Join-Path $target '.git'))) {
    Write-Warning "Skipping $($repo.Name): target exists but is not a git repo ($target)"
    continue
  }

  Push-Location $target
  try {
    git fetch origin
    git checkout $repo.Branch
    git pull --rebase origin $repo.Branch
    git status --short --branch
  }
  finally {
    Pop-Location
  }

  Write-Output ""
}

Write-Output "Sync complete."
