package com.zhaoxiangyang.eap.user.interfaces.internal.dto;

import java.util.List;

/**
 * Internal response. passwordHash must never be exposed by a public API.
 */
public record AuthenticationUserResponse(
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

    public AuthenticationUserResponse {
        roles = List.copyOf(roles);
        permissions = List.copyOf(permissions);
    }
}
