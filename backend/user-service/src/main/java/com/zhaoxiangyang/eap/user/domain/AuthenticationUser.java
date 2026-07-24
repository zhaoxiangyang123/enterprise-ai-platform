package com.zhaoxiangyang.eap.user.domain;

import java.time.LocalDateTime;

/**
 * Database projection used only by the authentication query.
 */
public record AuthenticationUser(
        Long userId,
        Long tenantId,
        String tenantCode,
        String username,
        String passwordHash,
        String displayName,
        String email,
        int userStatus,
        int tenantStatus,
        int loginFailCount,
        LocalDateTime lockedUntil
) {
}
