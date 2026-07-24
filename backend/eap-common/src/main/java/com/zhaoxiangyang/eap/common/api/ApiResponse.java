package com.zhaoxiangyang.eap.common.api;

import com.zhaoxiangyang.eap.common.context.RequestContext;
import com.zhaoxiangyang.eap.common.error.ErrorCode;

import java.time.Instant;
import java.util.Objects;

/**
 * Unified response envelope for ordinary JSON APIs.
 *
 * @param code business result code
 * @param message readable result message
 * @param data response payload
 * @param requestId request trace identifier
 * @param timestamp server timestamp in milliseconds
 * @param <T> payload type
 */
public record ApiResponse<T>(
        String code,
        String message,
        T data,
        String requestId,
        long timestamp
) {

    public ApiResponse {
        Objects.requireNonNull(code, "code must not be null");
        Objects.requireNonNull(message, "message must not be null");
        Objects.requireNonNull(requestId, "requestId must not be null");
    }

    public static <T> ApiResponse<T> success(T data) {
        return success("操作成功", data);
    }

    public static <T> ApiResponse<T> success(String message, T data) {
        return new ApiResponse<>(
                ErrorCode.SUCCESS.code(),
                message,
                data,
                RequestContext.currentRequestId(),
                Instant.now().toEpochMilli()
        );
    }

    public static ApiResponse<Void> failure(ErrorCode errorCode) {
        return failure(errorCode, errorCode.message());
    }

    public static ApiResponse<Void> failure(ErrorCode errorCode, String message) {
        return new ApiResponse<>(
                errorCode.code(),
                message,
                null,
                RequestContext.currentRequestId(),
                Instant.now().toEpochMilli()
        );
    }
}
