package com.zhaoxiangyang.eap.auth.client.dto;

import java.util.List;

public record UserAuthenticationResponse(
        Long userId,
        Long tenantId,
        String tenantCode,
        String username,
        String passwordHash,
        String displayName,
        String email,
        List<String> roles,
        List<String> permissions
) {

    public UserAuthenticationResponse {
        roles = List.copyOf(roles);
        permissions = List.copyOf(permissions);
    }
}
