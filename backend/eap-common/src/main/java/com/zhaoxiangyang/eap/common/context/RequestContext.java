package com.zhaoxiangyang.eap.common.context;

import java.util.UUID;

/**
 * Holds request-scoped tracing information for synchronous servlet requests.
 */
public final class RequestContext {

    private static final ThreadLocal<String> REQUEST_ID = new ThreadLocal<>();

    private RequestContext() {
    }

    public static void setRequestId(String requestId) {
        REQUEST_ID.set(requestId);
    }

    public static String currentRequestId() {
        String requestId = REQUEST_ID.get();
        return requestId == null ? newRequestId() : requestId;
    }

    public static void clear() {
        REQUEST_ID.remove();
    }

    public static String newRequestId() {
        return UUID.randomUUID().toString().replace("-", "");
    }
}
