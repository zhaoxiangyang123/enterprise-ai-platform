package com.zhaoxiangyang.eap.common.error;

import java.util.Arrays;

/**
 * Stable business error codes shared by all services.
 */
public enum ErrorCode {

    SUCCESS("SUCCESS", "操作成功", 200),

    PARAM_INVALID("PARAM_INVALID", "请求参数不合法", 400),
    REQUEST_METHOD_NOT_SUPPORTED("REQUEST_METHOD_NOT_SUPPORTED", "请求方法不支持", 405),

    AUTH_REQUIRED("AUTH_REQUIRED", "用户尚未登录", 401),
    AUTH_TOKEN_INVALID("AUTH_TOKEN_INVALID", "访问令牌无效", 401),
    AUTH_TOKEN_EXPIRED("AUTH_TOKEN_EXPIRED", "访问令牌已过期", 401),
    AUTH_PASSWORD_ERROR("AUTH_PASSWORD_ERROR", "用户名或密码错误", 401),

    ACCESS_DENIED("ACCESS_DENIED", "当前用户没有访问权限", 403),
    INTERNAL_CALL_FORBIDDEN("INTERNAL_CALL_FORBIDDEN", "内部服务调用认证失败", 403),
    TENANT_DISABLED("TENANT_DISABLED", "租户已被禁用", 403),
    USER_DISABLED("USER_DISABLED", "用户已被禁用或锁定", 403),

    USER_NOT_FOUND("USER_NOT_FOUND", "用户不存在", 404),
    RESOURCE_NOT_FOUND("RESOURCE_NOT_FOUND", "请求的资源不存在", 404),

    DATA_CONFLICT("DATA_CONFLICT", "数据冲突", 409),
    RATE_LIMITED("RATE_LIMITED", "请求过于频繁", 429),

    USER_SERVICE_UNAVAILABLE("USER_SERVICE_UNAVAILABLE", "用户服务暂时不可用", 503),
    SESSION_STORE_UNAVAILABLE("SESSION_STORE_UNAVAILABLE", "认证会话服务暂时不可用", 503),

    SYSTEM_ERROR("SYSTEM_ERROR", "系统内部异常", 500);

    private final String code;
    private final String message;
    private final int httpStatus;

    ErrorCode(String code, String message, int httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }

    public String code() {
        return code;
    }

    public String message() {
        return message;
    }

    public int httpStatus() {
        return httpStatus;
    }

    public static ErrorCode fromCode(String code) {
        return Arrays.stream(values())
                .filter(value -> value.code.equals(code))
                .findFirst()
                .orElse(SYSTEM_ERROR);
    }
}
