param(
    [Parameter(Mandatory = $true)]
    [string]$Server
)

$ErrorActionPreference = "Stop"
$deployDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $deployDirectory
$portalDirectory = Join-Path $projectRoot "portal"
$isaacFrontendDirectory = Join-Path $projectRoot "ISAAC\frontend"
$researchFrontendDirectory = Join-Path $projectRoot "agents_project\frontend"
$isaacDistDirectory = Join-Path $isaacFrontendDirectory "dist"
$researchDistDirectory = Join-Path $researchFrontendDirectory "dist"
$remoteRoot = "/tmp/resume-frontends"

Push-Location $isaacFrontendDirectory
try {
    & npm ci
    if ($LASTEXITCODE -ne 0) { throw "ISAAC 依赖安装失败。" }
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "ISAAC 前端构建失败。" }
}
finally {
    Pop-Location
}

Push-Location $researchFrontendDirectory
try {
    & pnpm install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "ResearchFlow 依赖安装失败。" }
    & pnpm build
    if ($LASTEXITCODE -ne 0) { throw "ResearchFlow 前端构建失败。" }
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
    if (-not (Test-Path $file)) { throw "缺少部署产物：$file" }
}

& ssh $Server "mkdir -p $remoteRoot/portal $remoteRoot/isaac $remoteRoot/research"
if ($LASTEXITCODE -ne 0) { throw "无法创建服务器临时目录。" }

& scp (Join-Path $portalDirectory "index.html") (Join-Path $portalDirectory "styles.css") (Join-Path $portalDirectory "favicon.svg") "${Server}:$remoteRoot/portal/"
if ($LASTEXITCODE -ne 0) { throw "Portal 上传失败。" }

& scp -r "${isaacDistDirectory}\*" "${Server}:$remoteRoot/isaac/"
if ($LASTEXITCODE -ne 0) { throw "ISAAC 前端上传失败。" }

& scp -r "${researchDistDirectory}\*" "${Server}:$remoteRoot/research/"
if ($LASTEXITCODE -ne 0) { throw "ResearchFlow 前端上传失败。" }

Write-Host "三个前端已在本机构建并上传到 $remoteRoot。"