package com.zhaoxiangyang.eap.auth.web;

public record LoginResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        LoginUserView user
) {
}
