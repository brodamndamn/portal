param(
    [Parameter(Mandatory = $true)]
    [string]$Server
)

$ErrorActionPreference = "Stop"
$deployDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$portalDirectory = Split-Path -Parent $deployDirectory
$workspaceRoot = Split-Path -Parent $portalDirectory
$isaacFrontendDirectory = Join-Path $workspaceRoot "ISAAC\frontend"
$researchFrontendDirectory = Join-Path $workspaceRoot "agents_project\frontend"
$isaacDistDirectory = Join-Path $isaacFrontendDirectory "dist"
$researchDistDirectory = Join-Path $researchFrontendDirectory "dist"
$remoteRoot = "/tmp/resume-frontends"

Push-Location $isaacFrontendDirectory
try {
    & npm ci
    if ($LASTEXITCODE -ne 0) { throw "ISAAC dependency installation failed." }
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "ISAAC frontend build failed." }
}
finally {
    Pop-Location
}

Push-Location $researchFrontendDirectory
try {
    & pnpm install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "ResearchFlow dependency installation failed." }
    & pnpm build
    if ($LASTEXITCODE -ne 0) { throw "ResearchFlow frontend build failed." }
}
finally {
    Pop-Location
}
foreach ($file in @(
    (Join-Path $portalDirectory "index.html"),
    (Join-Path $portalDirectory "styles.css"),
    (Join-Path $portalDirectory "favicon.svg"),
    (Join-Path $isaacDistDirectory "index.html"),
    (Join-Path $researchDistDirectory "index.html")
)) {
    if (-not (Test-Path $file)) { throw "Missing deployment artifact: $file" }
}

& ssh $Server "mkdir -p $remoteRoot/portal $remoteRoot/isaac $remoteRoot/research"
if ($LASTEXITCODE -ne 0) { throw "Unable to create the server temporary directory." }

& scp (Join-Path $portalDirectory "index.html") (Join-Path $portalDirectory "styles.css") (Join-Path $portalDirectory "favicon.svg") "${Server}:$remoteRoot/portal/"
if ($LASTEXITCODE -ne 0) { throw "Portal upload failed." }

& scp -r "${isaacDistDirectory}\*" "${Server}:$remoteRoot/isaac/"
if ($LASTEXITCODE -ne 0) { throw "ISAAC frontend upload failed." }

& scp -r "${researchDistDirectory}\*" "${Server}:$remoteRoot/research/"
if ($LASTEXITCODE -ne 0) { throw "ResearchFlow frontend upload failed." }

Write-Host "All frontend bundles were built locally and uploaded to $remoteRoot."