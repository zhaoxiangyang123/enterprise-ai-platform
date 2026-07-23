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
$EnvValues = Read-DotEnv -Path $EnvFile

$Ports = @(
    @{
        Name = "MySQL"
        Port = [int](Get-EnvValue -Values $EnvValues -Name "MYSQL_PORT" -DefaultValue "13306")
    },
    @{
        Name = "Redis"
        Port = [int](Get-EnvValue -Values $EnvValues -Name "REDIS_PORT" -DefaultValue "6379")
    },
    @{
        Name = "Nacos Server"
        Port = [int](Get-EnvValue -Values $EnvValues -Name "NACOS_SERVER_PORT" -DefaultValue "8848")
    },
    @{
        Name = "Nacos Console"
        Port = [int](Get-EnvValue -Values $EnvValues -Name "NACOS_CONSOLE_PORT" -DefaultValue "8849")
    },
    @{
        Name = "Nacos gRPC"
        Port = [int](Get-EnvValue -Values $EnvValues -Name "NACOS_GRPC_PORT" -DefaultValue "9848")
    }
)

Push-Location $DeployDirectory
try {
    & docker compose --env-file $EnvFile -f $ComposeFile ps
    if ($LASTEXITCODE -ne 0) {
        throw "无法读取基础设施容器状态。"
    }

    Write-Host ""
    Write-Host "端口检查："

    foreach ($Item in $Ports) {
        $Open = Test-NetConnection `
            -ComputerName "127.0.0.1" `
            -Port $Item.Port `
            -InformationLevel Quiet `
            -WarningAction SilentlyContinue

        $State = if ($Open) { "OPEN" } else { "CLOSED" }
        Write-Host ("{0,-14} {1,-5} {2}" -f $Item.Name, $Item.Port, $State)
    }
}
finally {
    Pop-Location
}
