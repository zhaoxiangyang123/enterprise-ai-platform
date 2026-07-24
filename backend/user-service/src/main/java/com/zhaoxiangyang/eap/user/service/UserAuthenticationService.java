package com.zhaoxiangyang.eap.user.service;

import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import com.zhaoxiangyang.eap.user.domain.AuthenticationUser;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.AuthenticationUserResponse;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.user.mapper.UserAuthenticationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class UserAuthenticationService {

    private static final int ENABLED = 1;

    private final UserAuthenticationMapper mapper;
    private final Clock clock;

    @Autowired
    public UserAuthenticationService(UserAuthenticationMapper mapper) {
        this(mapper, Clock.systemDefaultZone());
    }

    UserAuthenticationService(UserAuthenticationMapper mapper, Clock clock) {
        this.mapper = mapper;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public AuthenticationUserResponse findForAuthentication(
            String tenantCode,
            String username
    ) {
        AuthenticationUser user = mapper
                .findByTenantCodeAndUsername(tenantCode, username)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));

        if (user.tenantStatus() != ENABLED) {
            throw new BusinessException(ErrorCode.TENANT_DISABLED);
        }

        if (user.userStatus() != ENABLED || isCurrentlyLocked(user.lockedUntil())) {
            throw new BusinessException(ErrorCode.USER_DISABLED);
        }

        List<String> roles = mapper.findRoleCodes(user.tenantId(), user.userId());
        List<String> permissions =
                mapper.findPermissionCodes(user.tenantId(), user.userId());

        return new AuthenticationUserResponse(
                user.userId(),
                user.tenantId(),
                user.tenantCode(),
                user.username(),
                user.passwordHash(),
                user.displayName(),
                user.email(),
                roles,
                permissions
        );
    }

    @Transactional
    public void recordLoginEvent(LoginEventRequest request) {
        if ("SUCCESS".equals(request.eventType())) {
            mapper.recordLoginSuccess(
                    request.tenantId(),
                    request.userId(),
                    normalizeClientIp(request.clientIp())
            );
            return;
        }

        mapper.recordLoginFailure(request.tenantId(), request.userId());
    }

    private boolean isCurrentlyLocked(LocalDateTime lockedUntil) {
        return lockedUntil != null
                && lockedUntil.isAfter(LocalDateTime.now(clock));
    }

    private String normalizeClientIp(String clientIp) {
        return clientIp == null || clientIp.isBlank() ? null : clientIp;
    }
}
