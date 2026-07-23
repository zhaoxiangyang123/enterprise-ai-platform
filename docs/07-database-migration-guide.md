# 第一迭代数据库迁移指南

## 1. 目标

本阶段使用 Flyway 管理用户服务和 AI 服务的数据库版本。

- `user-service` 管理 `eap_user`
- `ai-service` 管理 `eap_ai`
- 每个服务只迁移自己的数据库
- 迁移记录保存在各数据库的 `flyway_schema_history`

## 2. 迁移文件

### user-service

- `V1__create_identity_schema.sql`
- `V2__seed_identity_data.sql`

### ai-service

- `V1__create_ai_schema.sql`

Flyway 已执行过的版本脚本禁止直接修改。需要调整数据库结构时，新增下一版本脚本，例如：

```text
V3__add_department_tables.sql
```

## 3. 本地数据源

本地 Java 服务运行在 Windows，所以连接地址为：

```text
MySQL: 127.0.0.1:13306
```

应用配置通过环境变量覆盖：

```text
EAP_MYSQL_HOST
EAP_MYSQL_PORT
EAP_MYSQL_USERNAME
EAP_MYSQL_PASSWORD
```

默认值与 `deploy/local/.env.example` 保持一致，仅用于本地开发。

## 4. 执行迁移

先确保基础设施处于运行状态：

```powershell
.\scripts\status-infrastructure.ps1
```

构建项目：

```powershell
mvn -f backend/pom.xml clean test
```

启动用户服务并激活 local 配置：

```powershell
mvn -f backend/user-service/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

看到 Flyway 成功日志和服务启动日志后，按 `Ctrl+C` 停止。

再启动 AI 服务：

```powershell
mvn -f backend/ai-service/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

看到 Flyway 成功日志和服务启动日志后，按 `Ctrl+C` 停止。

## 5. 验证迁移

```powershell
.\scripts\verify-database-migrations.ps1
```

预期结果：

- `eap_user` 存在 6 张业务表和 `flyway_schema_history`
- `eap_ai` 存在 2 张业务表和 `flyway_schema_history`
- 默认租户为 `default`
- 默认管理员为 `admin`
- 默认管理员角色为 `SYSTEM_ADMIN`

## 6. 默认开发账号

```text
tenantCode: default
username: admin
password: Admin@123
```

该账号只用于本地开发。首次实现登录功能后，应增加强制修改默认密码机制。

## 7. 迁移规则

1. 已在共享环境执行的版本脚本不能修改。
2. 每次数据库变更都新增版本文件。
3. 版本号严格递增。
4. 一个脚本只处理一个明确主题。
5. SQL 文件统一使用 UTF-8。
6. 禁止在迁移脚本中保存真实生产密码。
7. 生产环境禁止使用 Flyway clean。
8. 跨服务不能共享迁移目录。
