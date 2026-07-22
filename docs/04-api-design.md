# 接口设计说明书

## 1. 文档说明

本文档用于定义 Enterprise AI Platform 第一迭代的接口规范。

第一迭代主要覆盖以下业务：

- 用户登录。
- 获取当前登录用户信息。
- 用户权限校验。
- AI 问答。
- 基础会话查询。

------

## 2. 接口统一规范

### 2.1 接口基础路径

所有外部接口统一通过网关访问。

```text
/api
```

各业务模块路径如下：

| 模块        | 基础路径             |
| ----------- | -------------------- |
| 认证模块    | `/api/auth`          |
| 用户模块    | `/api/users`         |
| AI 问答模块 | `/api/ai`            |
| 会话模块    | `/api/conversations` |

示例：

```text
POST /api/auth/login
GET /api/users/me
POST /api/ai/chat
```

------

### 2.2 数据格式

请求和响应统一使用 JSON：

```http
Content-Type: application/json
```

文件上传等特殊接口除外。

字符编码统一使用 UTF-8。

------

### 2.3 认证方式

除登录接口外，受保护接口必须在请求头中携带访问令牌：

```http
Authorization: Bearer <access_token>
```

示例：

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

网关负责完成以下操作：

1. 获取访问令牌。
2. 校验令牌是否合法。
3. 判断令牌是否过期。
4. 提取用户身份信息。
5. 将身份信息传递给下游服务。

网关向下游服务传递以下内部请求头：

```http
X-User-Id: 10001
X-Tenant-Id: 20001
X-Username: admin
```

这些内部请求头只能由网关生成，下游服务不能信任客户端直接传入的同名请求头。

------

### 2.4 统一响应结构

所有普通接口统一返回以下结构：

```json
{
  "code": "SUCCESS",
  "message": "操作成功",
  "data": {},
  "requestId": "01J2ABCDEF123456789",
  "timestamp": 1750000000000
}
```

字段说明：

| 字段        | 类型   | 说明             |
| ----------- | ------ | ---------------- |
| `code`      | String | 业务结果码       |
| `message`   | String | 结果说明         |
| `data`      | Object | 返回的业务数据   |
| `requestId` | String | 请求链路编号     |
| `timestamp` | Long   | 服务器响应时间戳 |

成功响应示例：

```json
{
  "code": "SUCCESS",
  "message": "操作成功",
  "data": {
    "userId": 10001,
    "username": "admin"
  },
  "requestId": "01J2ABCDEF123456789",
  "timestamp": 1750000000000
}
```

失败响应示例：

```json
{
  "code": "AUTH_PASSWORD_ERROR",
  "message": "用户名或密码错误",
  "data": null,
  "requestId": "01J2ABCDEF123456789",
  "timestamp": 1750000000000
}
```

------

### 2.5 HTTP 状态码

| HTTP 状态码 | 使用场景                   |
| ----------- | -------------------------- |
| `200`       | 请求成功                   |
| `400`       | 请求参数错误               |
| `401`       | 未登录、令牌无效或令牌过期 |
| `403`       | 已登录但没有访问权限       |
| `404`       | 请求的资源不存在           |
| `409`       | 数据冲突或重复操作         |
| `429`       | 请求频率超过限制           |
| `500`       | 系统内部异常               |
| `503`       | 下游服务或大模型暂时不可用 |

------

### 2.6 第一迭代错误码

| 错误码                   | 说明                 |
| ------------------------ | -------------------- |
| `SUCCESS`                | 操作成功             |
| `PARAM_INVALID`          | 请求参数不合法       |
| `AUTH_REQUIRED`          | 用户尚未登录         |
| `AUTH_TOKEN_INVALID`     | 访问令牌无效         |
| `AUTH_TOKEN_EXPIRED`     | 访问令牌已过期       |
| `AUTH_PASSWORD_ERROR`    | 用户名或密码错误     |
| `ACCESS_DENIED`          | 当前用户没有访问权限 |
| `USER_NOT_FOUND`         | 用户不存在           |
| `USER_DISABLED`          | 用户已被禁用         |
| `AI_MODEL_UNAVAILABLE`   | 大模型服务暂时不可用 |
| `AI_REQUEST_FAILED`      | AI 请求执行失败      |
| `CONVERSATION_NOT_FOUND` | 会话不存在           |
| `SYSTEM_ERROR`           | 系统内部异常         |

------

### 2.7 分页参数

分页查询统一使用以下参数：

| 参数       | 类型    | 默认值 | 说明                |
| ---------- | ------- | ------ | ------------------- |
| `pageNum`  | Integer | `1`    | 当前页码，从 1 开始 |
| `pageSize` | Integer | `20`   | 每页数量，最大 100  |

分页响应统一使用：

```json
{
  "list": [],
  "pageNum": 1,
  "pageSize": 20,
  "total": 0,
  "pages": 0
}
```

------

### 2.8 日期时间格式

接口中的日期时间统一使用 ISO 8601 格式：

```text
2026-07-22T15:30:00+08:00
```

数据库中统一保存时间信息，接口层负责转换为标准格式。

不建议前端自行拼接或解析非标准日期字符串。