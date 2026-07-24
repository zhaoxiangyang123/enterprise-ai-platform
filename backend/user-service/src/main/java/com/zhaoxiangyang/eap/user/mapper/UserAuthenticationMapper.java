package com.zhaoxiangyang.eap.user.mapper;

import com.zhaoxiangyang.eap.user.domain.AuthenticationUser;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Explicit SQL mapper for the authentication read model.
 *
 * This first implementation uses Spring JDBC so every tenant and logical
 * deletion condition is visible in code. MyBatis-Plus can be introduced in
 * the broader user-management stage without changing the internal API.
 */
@Repository
public class UserAuthenticationMapper {

    private static final String FIND_USER_SQL = """
            SELECT
                u.id AS user_id,
                u.tenant_id,
                t.tenant_code,
                u.username,
                u.password_hash,
                u.display_name,
                u.email,
                u.status AS user_status,
                t.status AS tenant_status,
                u.login_fail_count,
                u.locked_until
            FROM sys_user u
            INNER JOIN sys_tenant t
                ON t.id = u.tenant_id
               AND t.deleted = 0
            WHERE t.tenant_code = ?
              AND u.username = ?
              AND u.deleted = 0
            LIMIT 1
            """;

    private static final String FIND_ROLE_CODES_SQL = """
            SELECT DISTINCT r.role_code
            FROM sys_user_role ur
            INNER JOIN sys_role r
                ON r.id = ur.role_id
               AND r.tenant_id = ur.tenant_id
               AND r.status = 1
               AND r.deleted = 0
            WHERE ur.tenant_id = ?
              AND ur.user_id = ?
            ORDER BY r.role_code
            """;

    private static final String FIND_PERMISSION_CODES_SQL = """
            SELECT DISTINCT p.permission_code
            FROM sys_user_role ur
            INNER JOIN sys_role r
                ON r.id = ur.role_id
               AND r.tenant_id = ur.tenant_id
               AND r.status = 1
               AND r.deleted = 0
            INNER JOIN sys_role_permission rp
                ON rp.tenant_id = ur.tenant_id
               AND rp.role_id = ur.role_id
            INNER JOIN sys_permission p
                ON p.id = rp.permission_id
               AND p.status = 1
               AND p.deleted = 0
            WHERE ur.tenant_id = ?
              AND ur.user_id = ?
            ORDER BY p.permission_code
            """;

    private final JdbcTemplate jdbcTemplate;

    public UserAuthenticationMapper(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<AuthenticationUser> findByTenantCodeAndUsername(
            String tenantCode,
            String username
    ) {
        List<AuthenticationUser> users = jdbcTemplate.query(
                FIND_USER_SQL,
                (resultSet, rowNum) -> {
                    Timestamp lockedUntil = resultSet.getTimestamp("locked_until");

                    return new AuthenticationUser(
                            resultSet.getLong("user_id"),
                            resultSet.getLong("tenant_id"),
                            resultSet.getString("tenant_code"),
                            resultSet.getString("username"),
                            resultSet.getString("password_hash"),
                            resultSet.getString("display_name"),
                            resultSet.getString("email"),
                            resultSet.getInt("user_status"),
                            resultSet.getInt("tenant_status"),
                            resultSet.getInt("login_fail_count"),
                            lockedUntil == null ? null : lockedUntil.toLocalDateTime()
                    );
                },
                tenantCode,
                username
        );

        return users.stream().findFirst();
    }

    public List<String> findRoleCodes(Long tenantId, Long userId) {
        return jdbcTemplate.queryForList(
                FIND_ROLE_CODES_SQL,
                String.class,
                tenantId,
                userId
        );
    }

    public List<String> findPermissionCodes(Long tenantId, Long userId) {
        return jdbcTemplate.queryForList(
                FIND_PERMISSION_CODES_SQL,
                String.class,
                tenantId,
                userId
        );
    }

    public int recordLoginFailure(Long tenantId, Long userId) {
        return jdbcTemplate.update(
                """
                UPDATE sys_user
                SET login_fail_count = login_fail_count + 1,
                    updated_at = CURRENT_TIMESTAMP(3)
                WHERE id = ?
                  AND tenant_id = ?
                  AND deleted = 0
                """,
                userId,
                tenantId
        );
    }

    public int recordLoginSuccess(Long tenantId, Long userId, String clientIp) {
        return jdbcTemplate.update(
                """
                UPDATE sys_user
                SET login_fail_count = 0,
                    locked_until = NULL,
                    last_login_at = CURRENT_TIMESTAMP(3),
                    last_login_ip = ?,
                    updated_at = CURRENT_TIMESTAMP(3)
                WHERE id = ?
                  AND tenant_id = ?
                  AND deleted = 0
                """,
                clientIp,
                userId,
                tenantId
        );
    }
}
