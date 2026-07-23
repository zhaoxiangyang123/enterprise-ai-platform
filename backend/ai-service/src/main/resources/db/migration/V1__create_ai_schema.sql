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
