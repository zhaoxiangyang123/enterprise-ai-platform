package com.zhaoxiangyang.eap.common.web;

import com.zhaoxiangyang.eap.common.constant.InternalHeaders;
import com.zhaoxiangyang.eap.common.context.RequestContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.regex.Pattern;

/**
 * Creates or propagates a request identifier and places it in MDC.
 */
public class RequestIdFilter extends OncePerRequestFilter {

    private static final Pattern SAFE_REQUEST_ID =
            Pattern.compile("[A-Za-z0-9._:-]{8,64}");

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String requestId = resolveRequestId(request.getHeader(InternalHeaders.REQUEST_ID));

        RequestContext.setRequestId(requestId);
        MDC.put("requestId", requestId);
        response.setHeader(InternalHeaders.REQUEST_ID, requestId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove("requestId");
            RequestContext.clear();
        }
    }

    private String resolveRequestId(String candidate) {
        if (candidate != null && SAFE_REQUEST_ID.matcher(candidate).matches()) {
            return candidate;
        }

        return RequestContext.newRequestId();
    }
}
