package com.zhaoxiangyang.eap.user.interfaces.internal.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record LoginEventRequest(
        @NotNull
        Long userId,

        @NotNull
        Long tenantId,

        @NotBlank
        @Pattern(regexp = "SUCCESS|FAILURE")
        String eventType,

        @Size(max = 64)
        String clientIp
) {
}
