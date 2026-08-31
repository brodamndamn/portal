param(
    [Parameter(Mandatory = $true)]
    [string]$Server
)

$ErrorActionPreference = "Stop"
$deployDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDirectory = Join-Path (Split-Path -Parent $deployDirectory) "..\agents_project\frontend"
$frontendDirectory = [System.IO.Path]::GetFullPath($frontendDirectory)
$distDirectory = Join-Path $frontendDirectory "dist"

Push-Location $frontendDirectory
try {
    pnpm install --frozen-lockfile
    pnpm exec vite build
}
finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $distDirectory "index.html"))) {
    throw "Frontend build did not produce dist/index.html."
}

$remoteDirectory = "/tmp/researchflow-dist"
$remoteTarget = "$Server`:$remoteDirectory"
scp -r $distDirectory $remoteTarget
Write-Host "Frontend build uploaded to $remoteTarget"
