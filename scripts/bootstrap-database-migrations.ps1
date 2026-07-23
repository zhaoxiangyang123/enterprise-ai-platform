$ErrorActionPreference = "Stop"
$ProjectRoot = (Get-Location).Path

if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    throw "当前目录不是 Git 项目根目录。"
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

Write-Host "开始生成 Flyway 数据库迁移文件..."

Write-Utf8NoBom -RelativePath 'backend\user-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>user-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP User Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>

        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>

        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-mysql</artifactId>
        </dependency>

        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>ai-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP AI Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>

        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>

        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-mysql</artifactId>
        </dependency>

        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\resources\application-local.yml' -Content @'
spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:mysql://${EAP_MYSQL_HOST:127.0.0.1}:${EAP_MYSQL_PORT:13306}/eap_user?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false&rewriteBatchedStatements=true
    username: ${EAP_MYSQL_USERNAME:eap}
    password: ${EAP_MYSQL_PASSWORD:EapApp_2026_Local}
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      pool-name: EapUserHikariPool
      minimum-idle: 2
      maximum-pool-size: 10
      connection-timeout: 30000
      validation-timeout: 5000
      idle-timeout: 600000
      max-lifetime: 1800000

  flyway:
    enabled: true
    locations: classpath:db/migration
    encoding: UTF-8
    validate-on-migrate: true
    baseline-on-migrate: false
    clean-disabled: true
    out-of-order: false

  sql:
    init:
      mode: never

logging:
  level:
    org.flywaydb: INFO
    com.zaxxer.hikari: INFO

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\main\resources\application-local.yml' -Content @'
spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:mysql://${EAP_MYSQL_HOST:127.0.0.1}:${EAP_MYSQL_PORT:13306}/eap_ai?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false&rewriteBatchedStatements=true
    username: ${EAP_MYSQL_USERNAME:eap}
    password: ${EAP_MYSQL_PASSWORD:EapApp_2026_Local}
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      pool-name: EapAiHikariPool
      minimum-idle: 2
      maximum-pool-size: 10
      connection-timeout: 30000
      validation-timeout: 5000
      idle-timeout: 600000
      max-lifetime: 1800000

  flyway:
    enabled: true
    locations: classpath:db/migration
    encoding: UTF-8
    validate-on-migrate: true
    baseline-on-migrate: false
    clean-disabled: true
    out-of-order: false

  sql:
    init:
      mode: never

logging:
  level:
    org.flywaydb: INFO
    com.zaxxer.hikari: INFO

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\user-service\src\test\resources\application.yml' -Content @'
spring:
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
      - org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\test\resources\application.yml' -Content @'
spring:
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
      - org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\resources\db\migration\V1__create_identity_schema.sql' -Content @'
CREATE TABLE sys_tenant (
    id              BIGINT          NOT NULL COMMENT '租户主键',
    tenant_code     VARCHAR(50)     NOT NULL COMMENT '租户编码',
    tenant_name     VARCHAR(100)    NOT NULL COMMENT '租户名称',
    status          TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    contact_name    VARCHAR(50)              COMMENT '联系人姓名',
    contact_email   VARCHAR(100)             COMMENT '联系人邮箱',
    expire_time     DATETIME(3)              COMMENT '租户到期时间',
    version         INT             NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    deleted         TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    created_by      BIGINT                   COMMENT '创建人编号',
    created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_by      BIGINT                   COMMENT '更新人编号',
    updated_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                    ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_tenant_code (tenant_code),
    KEY idx_tenant_status_deleted (status, deleted)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='租户表';

CREATE TABLE sys_user (
    id                  BIGINT          NOT NULL COMMENT '用户主键',
    tenant_id           BIGINT          NOT NULL COMMENT '租户编号',
    username            VARCHAR(50)     NOT NULL COMMENT '登录用户名',
    password_hash       VARCHAR(100)    NOT NULL COMMENT 'BCrypt密码摘要',
    display_name        VARCHAR(100)    NOT NULL COMMENT '用户显示名称',
    email               VARCHAR(100)             COMMENT '邮箱',
    mobile              VARCHAR(30)              COMMENT '手机号',
    avatar_url          VARCHAR(500)             COMMENT '头像地址',
    status              TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用，2-锁定',
    login_fail_count    INT             NOT NULL DEFAULT 0 COMMENT '连续登录失败次数',
    locked_until        DATETIME(3)              COMMENT '账号锁定截止时间',
    password_changed_at DATETIME(3)              COMMENT '密码最后修改时间',
    last_login_at       DATETIME(3)              COMMENT '最后登录时间',
    last_login_ip       VARCHAR(64)               COMMENT '最后登录IP',
    version             INT             NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    deleted             TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    created_by          BIGINT                   COMMENT '创建人编号',
    created_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_by          BIGINT                   COMMENT '更新人编号',
    updated_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_tenant_username (tenant_id, username),
    UNIQUE KEY uk_user_tenant_email (tenant_id, email),
    KEY idx_user_tenant_status_deleted (tenant_id, status, deleted),
    KEY idx_user_tenant_mobile (tenant_id, mobile)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='用户表';

CREATE TABLE sys_role (
    id              BIGINT          NOT NULL COMMENT '角色主键',
    tenant_id       BIGINT          NOT NULL COMMENT '租户编号',
    role_code       VARCHAR(100)    NOT NULL COMMENT '角色编码',
    role_name       VARCHAR(100)    NOT NULL COMMENT '角色名称',
    description     VARCHAR(500)             COMMENT '角色说明',
    built_in        TINYINT         NOT NULL DEFAULT 0 COMMENT '是否内置：0-否，1-是',
    status          TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    sort_order      INT             NOT NULL DEFAULT 0 COMMENT '排序值',
    version         INT             NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    deleted         TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    created_by      BIGINT                   COMMENT '创建人编号',
    created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_by      BIGINT                   COMMENT '更新人编号',
    updated_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                    ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_tenant_code (tenant_id, role_code),
    KEY idx_role_tenant_status_deleted (tenant_id, status, deleted)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='角色表';

CREATE TABLE sys_permission (
    id                  BIGINT          NOT NULL COMMENT '权限主键',
    permission_code     VARCHAR(150)    NOT NULL COMMENT '权限编码',
    permission_name     VARCHAR(100)    NOT NULL COMMENT '权限名称',
    permission_type     TINYINT         NOT NULL COMMENT '类型：1-菜单，2-按钮，3-接口',
    parent_id           BIGINT          NOT NULL DEFAULT 0 COMMENT '父权限编号',
    resource_path       VARCHAR(255)             COMMENT '资源路径',
    http_method         VARCHAR(10)              COMMENT 'HTTP方法',
    description         VARCHAR(500)             COMMENT '权限说明',
    sort_order          INT             NOT NULL DEFAULT 0 COMMENT '排序值',
    status              TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    version             INT             NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    deleted             TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    created_by          BIGINT                   COMMENT '创建人编号',
    created_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_by          BIGINT                   COMMENT '更新人编号',
    updated_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_permission_code (permission_code),
    KEY idx_permission_parent (parent_id),
    KEY idx_permission_type_status_deleted (permission_type, status, deleted)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='权限表';

CREATE TABLE sys_user_role (
    id              BIGINT          NOT NULL COMMENT '关联主键',
    tenant_id       BIGINT          NOT NULL COMMENT '租户编号',
    user_id         BIGINT          NOT NULL COMMENT '用户编号',
    role_id         BIGINT          NOT NULL COMMENT '角色编号',
    created_by      BIGINT                   COMMENT '创建人编号',
    created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role (tenant_id, user_id, role_id),
    KEY idx_user_role_user (tenant_id, user_id),
    KEY idx_user_role_role (tenant_id, role_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='用户角色关联表';

CREATE TABLE sys_role_permission (
    id              BIGINT          NOT NULL COMMENT '关联主键',
    tenant_id       BIGINT          NOT NULL COMMENT '租户编号',
    role_id         BIGINT          NOT NULL COMMENT '角色编号',
    permission_id   BIGINT          NOT NULL COMMENT '权限编号',
    created_by      BIGINT                   COMMENT '创建人编号',
    created_at      DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_permission (tenant_id, role_id, permission_id),
    KEY idx_role_permission_role (tenant_id, role_id),
    KEY idx_role_permission_permission (permission_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='角色权限关联表';

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\resources\db\migration\V2__seed_identity_data.sql' -Content @'
INSERT INTO sys_tenant (
    id, tenant_code, tenant_name, status, version, deleted, created_at, updated_at
) VALUES (
    1, 'default', '默认企业', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)
);

INSERT INTO sys_role (
    id, tenant_id, role_code, role_name, description,
    built_in, status, sort_order, version, deleted, created_at, updated_at
) VALUES
(101, 1, 'SYSTEM_ADMIN', '系统管理员', '拥有租户内全部管理权限', 1, 1, 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(102, 1, 'AI_ADMIN', 'AI管理员', '负责AI能力和知识库管理', 1, 1, 2, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(103, 1, 'EMPLOYEE', '普通员工', '使用AI问答和个人会话功能', 1, 1, 3, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

INSERT INTO sys_permission (
    id, permission_code, permission_name, permission_type,
    parent_id, resource_path, http_method, status,
    version, deleted, created_at, updated_at
) VALUES
(201, 'ai:chat', '发起AI问答', 3, 0, '/api/ai/chat', 'POST', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(202, 'conversation:read', '查询会话', 3, 0, '/api/conversations/**', 'GET', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(203, 'conversation:delete', '删除会话', 3, 0, '/api/conversations/**', 'DELETE', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(204, 'user:read', '查询用户', 3, 0, '/api/users/**', 'GET', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(205, 'user:create', '创建用户', 3, 0, '/api/users', 'POST', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(206, 'user:update', '修改用户', 3, 0, '/api/users/**', 'PUT', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(207, 'role:read', '查询角色', 3, 0, '/api/roles/**', 'GET', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
(208, 'role:assign', '分配角色', 3, 0, '/api/users/**/roles', 'PUT', 1, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

INSERT INTO sys_user (
    id, tenant_id, username, password_hash, display_name, email,
    status, login_fail_count, password_changed_at,
    version, deleted, created_at, updated_at
) VALUES (
    1001, 1, 'admin',
    '$2y$12$crKEibuK/b6M/Ss5uEBOuuOsJY7uCpOQI8CdsyMspq6ULnvL0diRi',
    '系统管理员', 'admin@example.com',
    1, 0, CURRENT_TIMESTAMP(3),
    0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)
);

INSERT INTO sys_user_role (
    id, tenant_id, user_id, role_id, created_at
) VALUES
(301, 1, 1001, 101, CURRENT_TIMESTAMP(3));

INSERT INTO sys_role_permission (
    id, tenant_id, role_id, permission_id, created_at
) VALUES
(401, 1, 101, 201, CURRENT_TIMESTAMP(3)),
(402, 1, 101, 202, CURRENT_TIMESTAMP(3)),
(403, 1, 101, 203, CURRENT_TIMESTAMP(3)),
(404, 1, 101, 204, CURRENT_TIMESTAMP(3)),
(405, 1, 101, 205, CURRENT_TIMESTAMP(3)),
(406, 1, 101, 206, CURRENT_TIMESTAMP(3)),
(407, 1, 101, 207, CURRENT_TIMESTAMP(3)),
(408, 1, 101, 208, CURRENT_TIMESTAMP(3)),
(409, 1, 102, 201, CURRENT_TIMESTAMP(3)),
(410, 1, 102, 202, CURRENT_TIMESTAMP(3)),
(411, 1, 102, 203, CURRENT_TIMESTAMP(3)),
(412, 1, 102, 204, CURRENT_TIMESTAMP(3)),
(413, 1, 103, 201, CURRENT_TIMESTAMP(3)),
(414, 1, 103, 202, CURRENT_TIMESTAMP(3)),
(415, 1, 103, 203, CURRENT_TIMESTAMP(3));

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\main\resources\db\migration\V1__create_ai_schema.sql' -Content @'
CREATE TABLE ai_conversation (
    id                  BIGINT          NOT NULL COMMENT '会话主键',
    tenant_id           BIGINT          NOT NULL COMMENT '租户编号',
    user_id             BIGINT          NOT NULL COMMENT '会话所属用户编号',
    title               VARCHAR(200)    NOT NULL COMMENT '会话标题',
    knowledge_base_id   BIGINT                   COMMENT '知识库编号，第一迭代为空',
    model_code          VARCHAR(100)             COMMENT '默认模型编码',
    status              TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：1-正常，2-归档',
    message_count       INT             NOT NULL DEFAULT 0 COMMENT '消息数量',
    last_message_at     DATETIME(3)              COMMENT '最后消息时间',
    version             INT             NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    deleted             TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    created_by          BIGINT                   COMMENT '创建人编号',
    created_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_by          BIGINT                   COMMENT '更新人编号',
    updated_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    KEY idx_conversation_user_list (
        tenant_id,
        user_id,
        deleted,
        last_message_at
    ),
    KEY idx_conversation_tenant_status (
        tenant_id,
        status,
        deleted
    ),
    KEY idx_conversation_knowledge_base (
        tenant_id,
        knowledge_base_id
    )
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='AI会话表';

CREATE TABLE ai_message (
    id                  BIGINT          NOT NULL COMMENT '消息主键',
    tenant_id           BIGINT          NOT NULL COMMENT '租户编号',
    conversation_id     BIGINT          NOT NULL COMMENT '会话编号',
    user_id             BIGINT          NOT NULL COMMENT '会话所属用户编号',
    parent_message_id   BIGINT                   COMMENT '父消息编号',
    client_message_id   VARCHAR(64)              COMMENT '客户端消息唯一编号',
    request_id          VARCHAR(64)              COMMENT '请求链路编号',
    `role`              VARCHAR(20)     NOT NULL COMMENT '角色：SYSTEM、USER、ASSISTANT、TOOL',
    content_type        VARCHAR(20)     NOT NULL DEFAULT 'TEXT' COMMENT '内容类型',
    content             MEDIUMTEXT      NOT NULL COMMENT '消息内容',
    message_status      TINYINT         NOT NULL DEFAULT 1 COMMENT '状态：1-完成，2-生成中，3-失败',
    model_code          VARCHAR(100)             COMMENT '模型编码',
    prompt_tokens       INT             NOT NULL DEFAULT 0 COMMENT '输入Token数量',
    completion_tokens   INT             NOT NULL DEFAULT 0 COMMENT '输出Token数量',
    total_tokens        INT             NOT NULL DEFAULT 0 COMMENT '总Token数量',
    latency_ms          BIGINT                   COMMENT '模型调用耗时，单位毫秒',
    finish_reason       VARCHAR(50)              COMMENT '模型停止原因',
    error_code          VARCHAR(100)             COMMENT '错误码',
    metadata_json       JSON                     COMMENT '扩展元数据',
    created_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_message_client_id (
        tenant_id,
        user_id,
        client_message_id
    ),
    KEY idx_message_conversation (
        tenant_id,
        conversation_id,
        id
    ),
    KEY idx_message_user_created (
        tenant_id,
        user_id,
        created_at
    ),
    KEY idx_message_request_id (request_id),
    KEY idx_message_parent (parent_message_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='AI消息表';

'@ -LinuxLineEndings

Write-Utf8NoBom -RelativePath 'scripts\verify-database-migrations.ps1' -Content @'
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

'@

Write-Utf8NoBom -RelativePath 'docs\07-database-migration-guide.md' -Content @'
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

'@ -LinuxLineEndings

Write-Host ""
Write-Host "数据库迁移文件生成完成。"
Write-Host "下一步执行："
Write-Host "  mvn -f backend/pom.xml clean test"
Write-Host "  git diff --check"
Write-Host "  git status"
