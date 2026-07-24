package com.zhaoxiangyang.eap.auth.web;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
        @NotBlank
        @Size(min = 4, max = 50)
        String username,

        @NotBlank
        @Size(min = 8, max = 100)
        String password,

        @NotBlank
        @Size(max = 50)
        String tenantCode
) {
}
