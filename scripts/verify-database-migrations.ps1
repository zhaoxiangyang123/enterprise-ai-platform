$ErrorActionPreference = "Stop"

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$EnvFile = Join-Path $RepositoryRoot "deploy\local\.env"

if (-not (Test-Path $EnvFile)) {
    throw "未找到 deploy\local\.env。请先启动本地基础设施。"
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

$EnvValues = Read-DotEnv -Path $EnvFile
$User = $EnvValues["MYSQL_APP_USER"]
$Password = $EnvValues["MYSQL_APP_PASSWORD"]

function Invoke-MySql {
    param(
        [string]$Database,
        [string]$Sql
    )

    & docker exec `
        -e "MYSQL_PWD=$Password" `
        eap-mysql `
        mysql `
        --default-character-set=utf8mb4 `
        -u $User `
        -D $Database `
        -e $Sql

    if ($LASTEXITCODE -ne 0) {
        throw "MySQL 验证失败：$Database"
    }
}

Write-Host "=== eap_user Flyway 历史 ==="
Invoke-MySql -Database "eap_user" -Sql "SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank;"

Write-Host ""
Write-Host "=== eap_user 表 ==="
Invoke-MySql -Database "eap_user" -Sql "SHOW TABLES;"

Write-Host ""
Write-Host "=== 默认用户和角色 ==="
Invoke-MySql -Database "eap_user" -Sql "SELECT u.id, u.username, u.display_name, r.role_code FROM sys_user u JOIN sys_user_role ur ON ur.user_id = u.id AND ur.tenant_id = u.tenant_id JOIN sys_role r ON r.id = ur.role_id AND r.tenant_id = ur.tenant_id WHERE u.tenant_id = 1 AND u.deleted = 0;"

Write-Host ""
Write-Host "=== eap_ai Flyway 历史 ==="
Invoke-MySql -Database "eap_ai" -Sql "SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank;"

Write-Host ""
Write-Host "=== eap_ai 表 ==="
Invoke-MySql -Database "eap_ai" -Sql "SHOW TABLES;"
