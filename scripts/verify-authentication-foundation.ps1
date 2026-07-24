$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSEdition -ne "Desktop" -or
    $PSVersionTable.PSVersion.Major -ne 5 -or
    $PSVersionTable.PSVersion.Minor -ne 1) {
    throw "必须使用 Windows PowerShell 5.1 执行本脚本。当前版本：$($PSVersionTable.PSVersion)"
}

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$WindowsPowerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$VerificationDirectory = Join-Path $RepositoryRoot "target\authentication-verification"
$UserRunner = Join-Path $VerificationDirectory "run-user-service.ps1"
$AuthRunner = Join-Path $VerificationDirectory "run-auth-service.ps1"
$UserOutLog = Join-Path $VerificationDirectory "user-service.out.log"
$UserErrorLog = Join-Path $VerificationDirectory "user-service.error.log"
$AuthOutLog = Join-Path $VerificationDirectory "auth-service.out.log"
$AuthErrorLog = Join-Path $VerificationDirectory "auth-service.error.log"
$LocalEnvFile = Join-Path $RepositoryRoot "deploy\local\.env"

function Assert-Utf8BomAndCrLf {
    param([string]$Path)

    $Bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($Bytes.Length -lt 3 -or
        $Bytes[0] -ne 0xEF -or
        $Bytes[1] -ne 0xBB -or
        $Bytes[2] -ne 0xBF) {
        throw "PowerShell 文件不是 UTF-8 with BOM：$Path"
    }

    $Content = [System.IO.File]::ReadAllText(
        $Path,
        [System.Text.UTF8Encoding]::new($true)
    )

    $WithoutCrLf = $Content -replace "`r`n", ""
    if ($WithoutCrLf.Contains("`r") -or $WithoutCrLf.Contains("`n")) {
        throw "PowerShell 文件包含非 CRLF 换行：$Path"
    }
}

function Assert-PowerShellSyntax {
    param([string]$Path)

    $Tokens = $null
    $Errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$Tokens,
        [ref]$Errors
    ) | Out-Null

    if ($Errors.Count -gt 0) {
        foreach ($ParseError in $Errors) {
            Write-Error "$Path：$($ParseError.Message)"
        }

        throw "PowerShell 5.1 语法检查失败：$Path"
    }
}

function Assert-PortAvailable {
    param(
        [string]$Name,
        [int]$Port
    )

    $Open = Test-NetConnection `
        -ComputerName "127.0.0.1" `
        -Port $Port `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue

    if ($Open) {
        throw "$Name 端口 $Port 已被占用。请先停止旧服务。"
    }
}

function Wait-HttpHealth {
    param(
        [string]$Name,
        [string]$Uri,
        [int]$TimeoutSeconds,
        [System.Diagnostics.Process]$Process,
        [string]$OutLog,
        [string]$ErrorLog
    )

    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $Deadline) {
        if ($Process.HasExited) {
            Write-Host "=== $Name 标准输出 ==="
            if (Test-Path $OutLog) {
                Get-Content $OutLog -Tail 80
            }

            Write-Host "=== $Name 错误输出 ==="
            if (Test-Path $ErrorLog) {
                Get-Content $ErrorLog -Tail 80
            }

            throw "$Name 提前退出，退出码：$($Process.ExitCode)"
        }

        try {
            $Health = Invoke-RestMethod `
                -Method Get `
                -Uri $Uri `
                -TimeoutSec 3

            if ($Health.status -eq "UP") {
                Write-Host "$Name 健康检查通过：$Uri"
                return
            }
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }

    throw "$Name 在 $TimeoutSeconds 秒内未通过健康检查。"
}

function Stop-ProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process -or $Process.HasExited) {
        return
    }

    & taskkill.exe /PID $Process.Id /T /F *> $null
}

function Write-PowerShellFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $CrLfContent = ($Content -replace "`r?`n", "`r`n")

    [System.IO.File]::WriteAllText(
        $Path,
        $CrLfContent,
        [System.Text.UTF8Encoding]::new($true)
    )
}

function Read-DotEnv {
    param([string]$Path)

    $Values = @{}

    foreach ($Line in Get-Content $Path) {
        $Trimmed = $Line.Trim()

        if ([string]::IsNullOrWhiteSpace($Trimmed) -or
            $Trimmed.StartsWith("#")) {
            continue
        }

        $Parts = $Trimmed -split "=", 2
        if ($Parts.Count -eq 2) {
            $Values[$Parts[0].Trim()] = $Parts[1].Trim()
        }
    }

    return $Values
}

Write-Host "=== 1. Windows PowerShell 5.1 环境 ==="
Write-Host "版本：$($PSVersionTable.PSVersion)"
Write-Host "可执行文件：$WindowsPowerShell"

Write-Host ""
Write-Host "=== 2. PowerShell 编码、换行和语法 ==="

$PowerShellFiles = Get-ChildItem `
    -Path $RepositoryRoot `
    -Recurse `
    -File `
    -Include *.ps1, *.psm1, *.psd1 |
    Where-Object {
        $_.FullName -notmatch "\\target\\" -and
        $_.FullName -notmatch "\\.git\\"
    }

foreach ($File in $PowerShellFiles) {
    Assert-Utf8BomAndCrLf -Path $File.FullName
    Assert-PowerShellSyntax -Path $File.FullName
    Write-Host "PS51 OK  $($File.FullName.Substring($RepositoryRoot.Length + 1))"
}

Write-Host ""
Write-Host "=== 3. Maven 全模块测试并安装快照 ==="

Push-Location $RepositoryRoot
try {
    & mvn -f backend/pom.xml clean install
    if ($LASTEXITCODE -ne 0) {
        throw "Maven 测试失败，退出码：$LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== 4. 基础设施状态 ==="

& (Join-Path $RepositoryRoot "scripts\status-infrastructure.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "基础设施状态检查失败。"
}

Assert-PortAvailable -Name "auth-service" -Port 8081
Assert-PortAvailable -Name "user-service" -Port 8082

if (Test-Path $VerificationDirectory) {
    Remove-Item $VerificationDirectory -Recurse -Force
}

New-Item -ItemType Directory -Path $VerificationDirectory -Force | Out-Null

$EscapedRepositoryRoot = $RepositoryRoot.Replace("'", "''")

$UserRunnerContent = @"
`$ErrorActionPreference = "Stop"
Set-Location -LiteralPath '$EscapedRepositoryRoot'
mvn -f backend/user-service/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
exit `$LASTEXITCODE
"@

$AuthRunnerContent = @"
`$ErrorActionPreference = "Stop"
Set-Location -LiteralPath '$EscapedRepositoryRoot'
mvn -f backend/auth-service/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
exit `$LASTEXITCODE
"@

Write-PowerShellFile -Path $UserRunner -Content $UserRunnerContent
Write-PowerShellFile -Path $AuthRunner -Content $AuthRunnerContent

$UserProcess = $null
$AuthProcess = $null

try {
    Write-Host ""
    Write-Host "=== 5. 启动 user-service ==="

    $UserProcess = Start-Process `
        -FilePath $WindowsPowerShell `
        -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            ('"{0}"' -f $UserRunner)
        ) `
        -RedirectStandardOutput $UserOutLog `
        -RedirectStandardError $UserErrorLog `
        -WindowStyle Hidden `
        -PassThru

    Wait-HttpHealth `
        -Name "user-service" `
        -Uri "http://127.0.0.1:8082/actuator/health" `
        -TimeoutSeconds 90 `
        -Process $UserProcess `
        -OutLog $UserOutLog `
        -ErrorLog $UserErrorLog

    Write-Host ""
    Write-Host "=== 6. 启动 auth-service ==="

    $AuthProcess = Start-Process `
        -FilePath $WindowsPowerShell `
        -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            ('"{0}"' -f $AuthRunner)
        ) `
        -RedirectStandardOutput $AuthOutLog `
        -RedirectStandardError $AuthErrorLog `
        -WindowStyle Hidden `
        -PassThru

    Wait-HttpHealth `
        -Name "auth-service" `
        -Uri "http://127.0.0.1:8081/actuator/health" `
        -TimeoutSeconds 90 `
        -Process $AuthProcess `
        -OutLog $AuthOutLog `
        -ErrorLog $AuthErrorLog

    Write-Host ""
    Write-Host "=== 7. 实际登录 ==="

    $LoginBody = @{
        tenantCode = "default"
        username = "admin"
        password = "Admin@123"
    } | ConvertTo-Json

    $LoginResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "http://127.0.0.1:8081/api/auth/login" `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($LoginBody)) `
        -TimeoutSec 15

    if ($LoginResponse.code -ne "SUCCESS") {
        throw "登录接口未返回 SUCCESS：$($LoginResponse | ConvertTo-Json -Depth 8)"
    }

    if ([string]::IsNullOrWhiteSpace($LoginResponse.data.accessToken)) {
        throw "登录响应缺少 accessToken。"
    }

    if ($LoginResponse.data.user.username -ne "admin") {
        throw "登录响应用户名不正确。"
    }

    if (-not ($LoginResponse.data.user.roles -contains "SYSTEM_ADMIN")) {
        throw "登录响应缺少 SYSTEM_ADMIN 角色。"
    }

    Write-Host "登录成功"
    Write-Host "userId：$($LoginResponse.data.user.userId)"
    Write-Host "tenantId：$($LoginResponse.data.user.tenantId)"
    Write-Host "roles：$($LoginResponse.data.user.roles -join ', ')"
    Write-Host "expiresIn：$($LoginResponse.data.expiresIn)"

    Write-Host ""
    Write-Host "=== 8. Redis 会话 ==="

    if (-not (Test-Path $LocalEnvFile)) {
        throw "未找到 deploy\local\.env，无法读取 Redis 本地密码。"
    }

    $LocalEnv = Read-DotEnv -Path $LocalEnvFile
    $RedisPassword = $LocalEnv["REDIS_PASSWORD"]

    if ([string]::IsNullOrWhiteSpace($RedisPassword)) {
        throw "deploy\local\.env 缺少 REDIS_PASSWORD。"
    }

    $RedisKeyPattern = "eap:auth:session:*"

    $RedisKeys = & docker exec `
        -e "REDISCLI_AUTH=$RedisPassword" `
        eap-redis `
        redis-cli `
        --scan `
        --pattern $RedisKeyPattern

    if ($LASTEXITCODE -ne 0) {
        throw "Redis 会话检查失败。"
    }

    if (-not $RedisKeys) {
        throw "登录后未找到 Redis 认证会话。"
    }

    Write-Host "Redis 会话存在：$($RedisKeys | Select-Object -First 1)"

    Write-Host ""
    Write-Host "=== 9. 实际退出登录 ==="

    $Headers = @{
        Authorization = "Bearer $($LoginResponse.data.accessToken)"
    }

    $LogoutResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "http://127.0.0.1:8081/api/auth/logout" `
        -Headers $Headers `
        -TimeoutSec 15

    if ($LogoutResponse.code -ne "SUCCESS") {
        throw "退出接口未返回 SUCCESS。"
    }

    Write-Host "退出登录成功"

    $SessionKey = $RedisKeys | Select-Object -First 1
    $SessionExists = & docker exec `
        -e "REDISCLI_AUTH=$RedisPassword" `
        eap-redis `
        redis-cli `
        EXISTS $SessionKey

    if ($LASTEXITCODE -ne 0 -or [int]$SessionExists -ne 0) {
        throw "退出登录后 Redis 会话仍然存在：$SessionKey"
    }

    Write-Host "Redis 会话已删除"
    Write-Host ""
    Write-Host "认证基础闭环验证全部通过。"
}
finally {
    Write-Host ""
    Write-Host "=== 10. 停止验证进程 ==="
    Stop-ProcessTree -Process $AuthProcess
    Stop-ProcessTree -Process $UserProcess
}
