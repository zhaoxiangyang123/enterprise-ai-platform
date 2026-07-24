# 认证模块开发与验证指南

## 1. 本阶段目标

本阶段完成第一迭代的认证基础闭环：

```text
POST /api/auth/login
    -> auth-service
    -> user-service 内部认证查询
    -> BCrypt 密码校验
    -> JWT 签发
    -> Redis 会话保存
    -> 返回访问令牌
```

同时实现：

- 统一 API 响应结构
- 统一业务错误码和异常映射
- 请求编号生成与响应头回传
- 用户、租户、角色和权限认证查询
- 内部接口令牌校验
- 登录成功和失败次数更新
- JWT 退出登录和 Redis 会话删除
- 单元测试和本地端到端验证

## 2. 服务边界

### auth-service

负责：

- 接收登录密码
- 调用 user-service 获取内部认证信息
- 使用 BCrypt 校验密码
- 签发 JWT
- 将会话写入 Redis
- 处理退出登录

### user-service

负责：

- 查询租户和用户
- 判断租户、用户是否可用
- 查询角色和权限
- 保存登录成功或失败信息
- 管理 eap_user 数据库

user-service 的内部接口会返回 `passwordHash`，但该字段只能通过
`/internal/users/**` 访问，并要求 `X-Internal-Token`。任何公共用户接口都不得
返回密码摘要。

## 3. 本阶段接口

### 3.1 登录

```http
POST /api/auth/login
Content-Type: application/json
```

请求：

```json
{
  "tenantCode": "default",
  "username": "admin",
  "password": "Admin@123"
}
```

成功响应：

```json
{
  "code": "SUCCESS",
  "message": "登录成功",
  "data": {
    "accessToken": "...",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "user": {
      "userId": 1001,
      "tenantId": 1,
      "username": "admin",
      "displayName": "系统管理员",
      "roles": ["SYSTEM_ADMIN"],
      "permissions": ["ai:chat"]
    }
  },
  "requestId": "...",
  "timestamp": 0
}
```

### 3.2 退出

```http
POST /api/auth/logout
Authorization: Bearer <access-token>
```

退出会校验 JWT，并删除 Redis 中以 JTI 为键的会话。

## 4. 本地配置

### user-service

```yaml
eap:
  internal:
    token: ${EAP_INTERNAL_TOKEN:eap-local-internal-token-change-me}
```

### auth-service

```yaml
eap:
  auth:
    user-service-base-url: http://127.0.0.1:8082
    internal-token: eap-local-internal-token-change-me
    jwt-issuer: enterprise-ai-platform
    jwt-secret-base64: <local-only-secret>
    access-token-ttl: PT2H
    redis-session-prefix: eap:auth:session:
```

提交到仓库的默认 JWT 密钥只用于 `local` Profile。共享开发、测试和生产环境
必须通过环境变量覆盖：

```text
EAP_INTERNAL_TOKEN
EAP_JWT_SECRET_BASE64
EAP_ACCESS_TOKEN_TTL
```

生产密钥不得提交到 Git，也不得记录到日志。

## 5. 请求编号

`RequestIdFilter` 的行为：

1. 接受合法的 `X-Request-Id`。
2. 请求头缺失或格式不安全时生成 32 位 UUID。
3. 将编号写入日志 MDC。
4. 将编号写回响应头。
5. 统一响应 JSON 同时包含 `requestId`。
6. 请求结束后清理 ThreadLocal 和 MDC，避免线程复用污染。

## 6. 密码安全

- 数据库存储 BCrypt 摘要，不存明文。
- 登录日志不得打印 `LoginRequest`，因为其中包含密码。
- 用户不存在时仍执行一次 BCrypt 运算，再返回统一的
  `AUTH_PASSWORD_ERROR`，降低用户名枚举和响应时间侧信道风险。
- 错误密码会增加 `login_fail_count`。
- 登录成功会清零失败次数并更新最后登录时间和 IP。
- 临时锁定策略将在登录限流阶段继续完善。

## 7. JWT Claims

当前访问令牌包含：

| Claim | 含义 |
|---|---|
| `iss` | 令牌签发方 |
| `sub` | 用户编号 |
| `tenantId` | 租户编号 |
| `username` | 用户名 |
| `roles` | 角色编码 |
| `jti` | 令牌唯一编号 |
| `iat` | 签发时间 |
| `exp` | 过期时间 |

权限明细不写入 JWT，而是保存在 Redis 会话中。后续网关鉴权阶段会根据 JTI
检查会话是否存在，并传递可信身份请求头。

## 8. Windows PowerShell 5.1 文件规则

本项目的 `.ps1`、`.psm1` 和 `.psd1` 文件必须：

- 使用 UTF-8 with BOM
- 文件前三字节为 `EF BB BF`
- 使用 CRLF 换行
- 使用 Windows PowerShell 5.1 做语法解析
- 通过 Windows PowerShell 5.1 实际执行验证命令

脚本生成 PowerShell 文件时必须使用：

```powershell
[System.IO.File]::WriteAllText(
    $Path,
    $Content,
    [System.Text.UTF8Encoding]::new($true)
)
```

Linux、Docker 和数据库文件继续使用 UTF-8 no BOM 与 LF。

## 9. 完整验证

在项目根目录使用 Windows PowerShell 5.1 执行：

```powershell
$PowerShell51 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

& $PowerShell51 `
  -NoProfile `
  -ExecutionPolicy Bypass `
  -File ".\scripts\verify-authentication-foundation.ps1"
```

验证脚本会实际执行：

1. 确认当前宿主是 Windows PowerShell 5.1。
2. 检查仓库所有 PowerShell 文件的 BOM 和 CRLF。
3. 使用 PowerShell 5.1 Parser 检查脚本语法。
4. 执行 Maven 全模块测试。
5. 检查 MySQL、Redis 和 Nacos。
6. 启动 user-service 和 auth-service 的 local Profile。
7. 调用真实登录接口。
8. 校验 JWT 响应、管理员角色和 Redis 会话。
9. 调用真实退出接口。
10. 停止本次启动的服务进程。

## 10. 后续阶段

本阶段完成后继续实现：

1. 网关 JWT 签名和 Redis 会话校验
2. 清除客户端伪造的内部身份头
3. 写入可信用户、租户和用户名请求头
4. `/api/users/me`
5. RBAC 权限检查
6. 登录审计表和账号临时锁定策略
