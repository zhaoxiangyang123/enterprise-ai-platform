package com.zhaoxiangyang.eap.auth.jwt;

import java.time.Instant;

public record IssuedToken(
        String token,
        String jti,
        Instant issuedAt,
        Instant expiresAt
) {
}
