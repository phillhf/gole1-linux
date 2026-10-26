# Baut das Gole1-Linux-ISO unter Windows mit Docker Desktop.
# Das fertige ISO landet in .\out\
#   .\build.ps1            normaler Build
#   .\build.ps1 clean      Build-Cache löschen
param([string]$Action = "")

$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker ist nicht installiert. Siehe README.md (Abschnitt 'ISO bauen')."
}

docker build -t gole1-builder $PSScriptRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Gebaut wird im Docker-Volume 'gole1-work' (Linux-Dateisystem), damit
# heruntergeladene Pakete beim nächsten Build wiederverwendet werden.
docker run --rm --privileged `
    -v "${PSScriptRoot}:/src" `
    -v gole1-work:/var/tmp/gole1-build `
    gole1-builder $Action
exit $LASTEXITCODE
