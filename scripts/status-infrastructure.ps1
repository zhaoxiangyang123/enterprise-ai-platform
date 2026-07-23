$ErrorActionPreference = "Stop"

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$DeployDirectory = Join-Path $RepositoryRoot "deploy\local"
$ComposeFile = Join-Path $DeployDirectory "docker-compose.yml"
$EnvFile = Join-Path $DeployDirectory ".env"

function Assert-DockerAvailable {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "未找到 docker 命令，请先安装并启动 Docker Desktop。"
    }

    & docker version *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Docker 引擎不可用，请确认 Docker Desktop 已启动。"
    }
}

function Read-DotEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Values = @{}

    foreach ($Line in Get-Content $Path) {
        $TrimmedLine = $Line.Trim()

        if ([string]::IsNullOrWhiteSpace($TrimmedLine)) {
            continue
        }

        if ($TrimmedLine.StartsWith("#")) {
            continue
        }

        $Parts = $TrimmedLine -split "=", 2

        if ($Parts.Count -eq 2) {
            $Values[$Parts[0].Trim()] = $Parts[1].Trim()
        }
    }

    return $Values
}

Assert-DockerAvailable

if (-not (Test-Path $EnvFile)) {
    throw "未找到 deploy\local\.env，请先运行基础设施启动脚本。"
}

$EnvValues = Read-DotEnv -Path $EnvFile

Push-Location $DeployDirectory

try {
    & docker compose --env-file $EnvFile -f $ComposeFile ps

    Write-Host ""
    Write-Host "端口检查："

    $Ports = @(
        @{
            Name = "MySQL"
            Port = [int]$EnvValues["MYSQL_PORT"]
        },
        @{
            Name = "Redis"
            Port = [int]$EnvValues["REDIS_PORT"]
        },
        @{
            Name = "Nacos Server"
            Port = [int]$EnvValues["NACOS_SERVER_PORT"]
        },
        @{
            Name = "Nacos Console"
            Port = [int]$EnvValues["NACOS_CONSOLE_PORT"]
        },
        @{
            Name = "Nacos gRPC"
            Port = [int]$EnvValues["NACOS_GRPC_PORT"]
        }
    )

    foreach ($Item in $Ports) {
        $Open = Test-NetConnection `
            -ComputerName "127.0.0.1" `
            -Port $Item.Port `
            -InformationLevel Quiet `
            -WarningAction SilentlyContinue

        $State = if ($Open) { "OPEN" } else { "CLOSED" }

        Write-Host (
            "{0,-14} {1,-6} {2}" -f `
                $Item.Name,
                $Item.Port,
                $State
        )
    }
}
finally {
    Pop-Location
}