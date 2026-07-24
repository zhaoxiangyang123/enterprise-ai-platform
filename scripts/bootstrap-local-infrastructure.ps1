param(
    [switch]$Start
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Get-Location).Path

if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    throw "当前目录不是 Git 项目根目录。请先进入 Enterprise AI Platform 根目录。"
}

function Write-Utf8NoBom {
    param(
        [string]$RelativePath,
        [string]$Content,
        [switch]$LinuxLineEndings
    )

    $FullPath = Join-Path $ProjectRoot $RelativePath
    $Parent = Split-Path $FullPath -Parent

    if (-not (Test-Path $Parent)) {
        New-Item -ItemType Directory -Force $Parent | Out-Null
    }

    if ($LinuxLineEndings) {
        $Content = $Content -replace "`r`n", "`n"
    }

    $UseBom = [System.IO.Path]::GetExtension($FullPath) -ieq ".ps1"
    $Encoding = New-Object System.Text.UTF8Encoding($UseBom)
    [System.IO.File]::WriteAllText($FullPath, $Content, $Encoding)
    Write-Host "CREATED  $RelativePath"
}

Write-Host "开始生成本地基础设施文件..."

Write-Utf8NoBom -RelativePath '.gitattributes' -Content @'
* text=auto

.gitattributes text eol=lf
*.sh text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.sql text eol=lf
*.md text eol=lf
.env.example text eol=lf
*.ps1 text eol=crlf
'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'deploy\local\.env.example' -Content @'
# Local development only. Do not reuse these values in shared or production environments.
COMPOSE_PROJECT_NAME=enterprise-ai-platform-local
TZ=Asia/Shanghai

MYSQL_IMAGE=mysql:8.4.10
MYSQL_PORT=13306
MYSQL_ROOT_PASSWORD=EapRoot_2026_Local
MYSQL_APP_USER=eap
MYSQL_APP_PASSWORD=EapApp_2026_Local

REDIS_IMAGE=redis:7.2.14-alpine
REDIS_PORT=6379
REDIS_PASSWORD=EapRedis_2026_Local

NACOS_IMAGE=nacos/nacos-server:v3.2.3
NACOS_CONSOLE_PORT=8849
NACOS_SERVER_PORT=8848
NACOS_GRPC_PORT=9848

NACOS_AUTH_TOKEN=RW50ZXJwcmlzZS1BSS1QbGF0Zm9ybS1Mb2NhbC1EZXZlbG9wbWVudC1Ub2tlbi0yMDI2
NACOS_AUTH_IDENTITY_KEY=eap-local-server
NACOS_AUTH_IDENTITY_VALUE=eap-local-server-value
'@

Write-Utf8NoBom -RelativePath 'deploy\local\docker-compose.yml' -Content @'
name: ${COMPOSE_PROJECT_NAME:-enterprise-ai-platform-local}

services:
  mysql:
    image: ${MYSQL_IMAGE}
    container_name: eap-mysql
    restart: unless-stopped
    env_file:
      - .env
    environment:
      TZ: ${TZ}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_APP_USER: ${MYSQL_APP_USER}
      MYSQL_APP_PASSWORD: ${MYSQL_APP_PASSWORD}
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --default-time-zone=+08:00
      - --max-connections=300
      - --skip-name-resolve
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - eap-mysql-data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test:
        - CMD-SHELL
        - mysqladmin ping -h 127.0.0.1 -uroot -p"$${MYSQL_ROOT_PASSWORD}" --silent
      interval: 10s
      timeout: 5s
      retries: 20
      start_period: 30s
    networks:
      - eap-local

  redis:
    image: ${REDIS_IMAGE}
    container_name: eap-redis
    restart: unless-stopped
    env_file:
      - .env
    environment:
      TZ: ${TZ}
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    command:
      - sh
      - -c
      - exec redis-server --appendonly yes --requirepass "$$REDIS_PASSWORD"
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - eap-redis-data:/data
    healthcheck:
      test:
        - CMD-SHELL
        - redis-cli -a "$${REDIS_PASSWORD}" ping | grep PONG
      interval: 10s
      timeout: 5s
      retries: 20
      start_period: 10s
    networks:
      - eap-local

  nacos:
    image: ${NACOS_IMAGE}
    container_name: eap-nacos
    restart: unless-stopped
    env_file:
      - .env
    environment:
      MODE: standalone
      PREFER_HOST_MODE: hostname
      NACOS_CONSOLE_PORT: "8080"
      NACOS_AUTH_ENABLE: "true"
      NACOS_AUTH_TOKEN: ${NACOS_AUTH_TOKEN}
      NACOS_AUTH_IDENTITY_KEY: ${NACOS_AUTH_IDENTITY_KEY}
      NACOS_AUTH_IDENTITY_VALUE: ${NACOS_AUTH_IDENTITY_VALUE}
      JVM_XMS: 256m
      JVM_XMX: 512m
      JVM_XMN: 128m
    ports:
      - "${NACOS_CONSOLE_PORT}:8080"
      - "${NACOS_SERVER_PORT}:8848"
      - "${NACOS_GRPC_PORT}:9848"
    volumes:
      - eap-nacos-logs:/home/nacos/logs
      - eap-nacos-data:/home/nacos/data
    networks:
      - eap-local

volumes:
  eap-mysql-data:
  eap-redis-data:
  eap-nacos-logs:
  eap-nacos-data:

networks:
  eap-local:
    name: eap-local
    driver: bridge
'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'deploy\local\mysql\init\01-init-databases.sh' -Content @'
#!/usr/bin/env bash
set -euo pipefail

echo "[mysql-init] Creating application databases and user..."

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
CREATE DATABASE IF NOT EXISTS eap_user
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eap_ai
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_APP_USER}'@'%'
  IDENTIFIED BY '${MYSQL_APP_PASSWORD}';

ALTER USER '${MYSQL_APP_USER}'@'%'
  IDENTIFIED BY '${MYSQL_APP_PASSWORD}';

GRANT ALL PRIVILEGES ON eap_user.* TO '${MYSQL_APP_USER}'@'%';
GRANT ALL PRIVILEGES ON eap_ai.* TO '${MYSQL_APP_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

echo "[mysql-init] Databases eap_user and eap_ai are ready."
'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'deploy\local\README.md' -Content @'
# Local Infrastructure

Local dependencies for the first iteration:

- MySQL 8.4 LTS
- Redis 7.2
- Nacos 3.2 standalone

## Ports

The committed defaults are shown below. A developer can override them in
`deploy/local/.env`.

| Component | Default address |
|---|---|
| MySQL | `127.0.0.1:13306` |
| Redis | `127.0.0.1:6379` |
| Nacos server | `127.0.0.1:8848` |
| Nacos console | `http://127.0.0.1:8849` |
| Nacos gRPC | `127.0.0.1:9848` |

The MySQL host port uses `13306` so it can coexist with a MySQL installation
using the conventional host port `3306`.

Nacos uses host port `8849` for its console. Inside the Nacos container the
console listens on port `8080`; this does not conflict with the gateway running
on the Windows host.

## Commands

```powershell
.\scripts\start-infrastructure.ps1
.\scripts\status-infrastructure.ps1
.\scripts\logs-infrastructure.ps1
.\scripts\stop-infrastructure.ps1
```

View one service's logs:

```powershell
.\scripts\logs-infrastructure.ps1 -Service mysql -Tail 100
```

Delete all local data:

```powershell
.\scripts\stop-infrastructure.ps1 -DeleteData
```

The first startup copies `.env.example` to `.env`. The real `.env` is ignored
by Git.

## MySQL configuration

MySQL development settings are passed as container startup arguments rather
than through a Windows bind-mounted `.cnf` file. This avoids the Linux
`world-writable config file ... is ignored` warning caused by Windows-mounted
file permissions.

Local Nacos uses standalone embedded storage for development only. A later
deployment stage will move it to authenticated cluster mode with external
persistent storage.
'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'scripts\start-infrastructure.ps1' -Content @'
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
$NacosConsolePort = Get-EnvValue -Values $EnvValues -Name "NACOS_CONSOLE_PORT" -DefaultValue "8849"

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
    Write-Host "Nacos 控制台：http://127.0.0.1:$NacosConsolePort"
}
finally {
    Pop-Location
}
'@

Write-Utf8NoBom -RelativePath 'scripts\stop-infrastructure.ps1' -Content @'
param(
    [switch]$DeleteData
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
    if ($DeleteData) {
        Write-Warning "将删除 MySQL、Redis 和 Nacos 的全部本地数据卷。"
        & docker compose --env-file $EnvFile -f $ComposeFile down --volumes --remove-orphans
    }
    else {
        & docker compose --env-file $EnvFile -f $ComposeFile down --remove-orphans
    }

    if ($LASTEXITCODE -ne 0) {
        throw "基础设施停止失败。"
    }
}
finally {
    Pop-Location
}
'@

Write-Utf8NoBom -RelativePath 'scripts\status-infrastructure.ps1' -Content @'
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
'@

Write-Utf8NoBom -RelativePath 'scripts\logs-infrastructure.ps1' -Content @'
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
'@

$LegacyMySqlConfig = Join-Path $ProjectRoot "deploy\local\mysql\conf.d\eap.cnf"
if (Test-Path $LegacyMySqlConfig) {
    Remove-Item $LegacyMySqlConfig -Force
    Write-Host "REMOVED  deploy\local\mysql\conf.d\eap.cnf"
}

$LegacyConfigDirectory = Split-Path $LegacyMySqlConfig -Parent
if ((Test-Path $LegacyConfigDirectory) -and
    -not (Get-ChildItem $LegacyConfigDirectory -Force | Select-Object -First 1)) {
    Remove-Item $LegacyConfigDirectory -Force
}

$EnvExample = Join-Path $ProjectRoot "deploy\local\.env.example"
$EnvFile = Join-Path $ProjectRoot "deploy\local\.env"

if (-not (Test-Path $EnvFile)) {
    Copy-Item $EnvExample $EnvFile
    Write-Host "CREATED  deploy\local\.env（本地文件，不提交 Git）"
}

Write-Host ""
Write-Host "文件生成完成。"

if ($Start) {
    & (Join-Path $ProjectRoot "scripts\start-infrastructure.ps1")
}
else {
    Write-Host "启动命令：.\scripts\start-infrastructure.ps1"
}

Write-Host "检查命令："
Write-Host "  .\scripts\status-infrastructure.ps1"
Write-Host "  git diff --check"
Write-Host "  git status"
