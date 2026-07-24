package com.zhaoxiangyang.eap.auth.jwt;

import java.time.Instant;
import java.util.List;

public record JwtPrincipal(
        Long userId,
        Long tenantId,
        String username,
        List<String> roles,
        String jti,
        Instant issuedAt,
        Instant expiresAt
) {

    public JwtPrincipal {
        roles = List.copyOf(roles);
    }
}
