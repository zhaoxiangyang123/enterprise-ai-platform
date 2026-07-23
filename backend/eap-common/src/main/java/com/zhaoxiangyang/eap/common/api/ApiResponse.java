package com.zhaoxiangyang.eap.common.api;

import java.time.Instant;

/**
 * Minimal unified API response used during the bootstrap stage.
 *
 * @param code      business result code
 * @param message   readable result message
 * @param data      response payload
 * @param timestamp server timestamp
 * @param <T>       payload type
 */
public record ApiResponse<T>(
        String code,
        String message,
        T data,
        long timestamp
) {

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(
                "SUCCESS",
                "操作成功",
                data,
                Instant.now().toEpochMilli()
        );
    }
}
