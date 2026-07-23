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
