param(
    [ValidateSet("all", "mysql", "redis", "nacos")]
    [string]$Service = "all",

    [ValidateRange(1, 10000)]
    [int]$Tail = 200
)

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

function Read-DotEnv {
    param([string]$Path)

    $Values = @{}

    foreach ($Line in Get-Content $Path) {
        $Trimmed = $Line.Trim()

        if ([string]::IsNullOrWhiteSpace($Trimmed) -or $Trimmed.StartsWith("#")) {
            continue
        }

        $Parts = $Trimmed -split "=", 2
        if ($Parts.Count -eq 2) {
            $Values[$Parts[0].Trim()] = $Parts[1].Trim()
        }
    }

    return $Values
}

function Get-EnvValue {
    param(
        [hashtable]$Values,
        [string]$Name,
        [string]$DefaultValue
    )

    if ($Values.ContainsKey($Name) -and
        -not [string]::IsNullOrWhiteSpace($Values[$Name])) {
        return $Values[$Name]
    }

    return $DefaultValue
}

Assert-DockerAvailable
Ensure-LocalEnv

Push-Location $DeployDirectory
try {
    if ($Service -eq "all") {
        & docker compose --env-file $EnvFile -f $ComposeFile logs --tail $Tail -f
    }
    else {
        & docker compose --env-file $EnvFile -f $ComposeFile logs --tail $Tail -f $Service
    }

    if ($LASTEXITCODE -ne 0) {
        throw "读取基础设施日志失败。"
    }
}
finally {
    Pop-Location
}
