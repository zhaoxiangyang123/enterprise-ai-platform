$ErrorActionPreference = "Stop"

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$DeployDirectory = Join-Path $RepositoryRoot "deploy\local"
$ComposeFile = Join-Path $DeployDirectory "docker-compose.yml"
$EnvFile = Join-Path $DeployDirectory ".env"

function Assert-DockerAvailable {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "未找到 docker 命令。请先安装并启动 Docker Desktop。"
    }

    & docker version *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker 引擎当前不可用。请确认 Docker Desktop 已启动。"
    }

    & docker compose version *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose 不可用。请更新 Docker Desktop。"
    }
}

function Ensure-LocalEnv {
    if (-not (Test-Path $EnvFile)) {
        Copy-Item (Join-Path $DeployDirectory ".env.example") $EnvFile
        Write-Host "已根据 .env.example 创建 deploy\local\.env。"
    }
}

Assert-DockerAvailable
Ensure-LocalEnv

Push-Location $DeployDirectory
try {
    Write-Host "正在校验 Docker Compose 配置..."
    & docker compose --env-file $EnvFile -f $ComposeFile config --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose 配置校验失败。"
    }

    Write-Host "正在拉取并启动 MySQL、Redis 和 Nacos..."
    & docker compose --env-file $EnvFile -f $ComposeFile up -d
    if ($LASTEXITCODE -ne 0) {
        throw "基础设施启动失败。"
    }

    Write-Host ""
    & docker compose --env-file $EnvFile -f $ComposeFile ps

    Write-Host ""
    Write-Host "首次下载和初始化可能需要数分钟。"
    Write-Host "Nacos 控制台：http://127.0.0.1:8849"
}
finally {
    Pop-Location
}
