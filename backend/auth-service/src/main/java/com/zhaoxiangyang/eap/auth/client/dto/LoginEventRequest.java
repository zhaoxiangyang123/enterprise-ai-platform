package com.zhaoxiangyang.eap.auth.client.dto;

public record LoginEventRequest(
        Long userId,
        Long tenantId,
        String eventType,
        String clientIp
) {

    public static LoginEventRequest success(
            Long userId,
            Long tenantId,
            String clientIp
    ) {
        return new LoginEventRequest(
                userId,
                tenantId,
                "SUCCESS",
                clientIp
        );
    }

    public static LoginEventRequest failure(Long userId, Long tenantId) {
        return new LoginEventRequest(
                userId,
                tenantId,
                "FAILURE",
                null
        );
    }
}
