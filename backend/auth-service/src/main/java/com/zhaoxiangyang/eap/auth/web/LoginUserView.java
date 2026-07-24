package com.zhaoxiangyang.eap.auth.web;

import java.util.List;

public record LoginUserView(
        Long userId,
        Long tenantId,
        String username,
        String displayName,
        List<String> roles,
        List<String> permissions
) {

    public LoginUserView {
        roles = List.copyOf(roles);
        permissions = List.copyOf(permissions);
    }
}
