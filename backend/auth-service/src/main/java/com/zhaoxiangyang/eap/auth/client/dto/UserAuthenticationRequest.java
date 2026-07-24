package com.zhaoxiangyang.eap.auth.client.dto;

public record UserAuthenticationRequest(
        String tenantCode,
        String username
) {
}
