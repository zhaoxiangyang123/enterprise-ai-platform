package com.zhaoxiangyang.eap.auth.session;

import java.time.Instant;
import java.util.List;

public record AuthSession(
        String jti,
        Long userId,
        Long tenantId,
        String username,
        List<String> roles,
        List<String> permissions,
        Instant issuedAt,
        Instant expiresAt
) {

    public AuthSession {
        roles = List.copyOf(roles);
        permissions = List.copyOf(permissions);
    }
}
