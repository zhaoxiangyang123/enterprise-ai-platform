package com.zhaoxiangyang.eap.user.interfaces.internal.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AuthenticationUserQueryRequest(
        @NotBlank
        @Size(max = 50)
        String tenantCode,

        @NotBlank
        @Size(max = 50)
        String username
) {
}
