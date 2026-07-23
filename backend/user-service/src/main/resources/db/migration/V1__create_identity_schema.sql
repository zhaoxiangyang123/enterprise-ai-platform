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
