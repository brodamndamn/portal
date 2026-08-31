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
    throw "前端构建未生成 dist/index.html。"
}

scp -r "$distDirectory" "${Server}:/tmp/researchflow-dist"
Write-Host "前端构建产物已上传到 ${Server}:/tmp/researchflow-dist"
