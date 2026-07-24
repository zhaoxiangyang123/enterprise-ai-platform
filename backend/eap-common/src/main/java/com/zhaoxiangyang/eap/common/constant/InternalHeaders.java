package com.zhaoxiangyang.eap.common.constant;

/**
 * Trusted headers used between the gateway and internal services.
 */
public final class InternalHeaders {

    public static final String REQUEST_ID = "X-Request-Id";
    public static final String INTERNAL_TOKEN = "X-Internal-Token";
    public static final String USER_ID = "X-User-Id";
    public static final String TENANT_ID = "X-Tenant-Id";
    public static final String USERNAME = "X-Username";

    private InternalHeaders() {
    }
}
