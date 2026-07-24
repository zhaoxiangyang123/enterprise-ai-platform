package com.zhaoxiangyang.eap.auth.service;

import com.zhaoxiangyang.eap.auth.client.UserIdentityClient;
import com.zhaoxiangyang.eap.auth.client.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;
import com.zhaoxiangyang.eap.auth.jwt.IssuedToken;
import com.zhaoxiangyang.eap.auth.jwt.JwtPrincipal;
import com.zhaoxiangyang.eap.auth.jwt.JwtTokenService;
import com.zhaoxiangyang.eap.auth.session.AuthSession;
import com.zhaoxiangyang.eap.auth.session.SessionStore;
import com.zhaoxiangyang.eap.auth.web.LoginRequest;
import com.zhaoxiangyang.eap.auth.web.LoginResponse;
import com.zhaoxiangyang.eap.auth.web.LoginUserView;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Coordinates identity lookup, password verification, token issuance and
 * Redis-backed session creation.
 */
@Service
public class AuthenticationService {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(AuthenticationService.class);

    /**
     * Used only to equalize BCrypt work when a username does not exist.
     */
    private static final String DUMMY_BCRYPT_HASH =
            "$2y$12$crKEibuK/b6M/Ss5uEBOuuOsJY7uCpOQI8CdsyMspq6ULnvL0diRi";

    private final UserIdentityClient userIdentityClient;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final SessionStore sessionStore;

    public AuthenticationService(
            UserIdentityClient userIdentityClient,
            PasswordEncoder passwordEncoder,
            JwtTokenService jwtTokenService,
            SessionStore sessionStore
    ) {
        this.userIdentityClient = userIdentityClient;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.sessionStore = sessionStore;
    }

    public LoginResponse login(LoginRequest request, String clientIp) {
        UserAuthenticationResponse user = findUserWithoutLeakingExistence(request);

        if (!passwordEncoder.matches(request.password(), user.passwordHash())) {
            recordLoginEventBestEffort(
                    LoginEventRequest.failure(user.userId(), user.tenantId())
            );
            throw new BusinessException(ErrorCode.AUTH_PASSWORD_ERROR);
        }

        IssuedToken issuedToken = jwtTokenService.issue(user);

        sessionStore.save(new AuthSession(
                issuedToken.jti(),
                user.userId(),
                user.tenantId(),
                user.username(),
                user.roles(),
                user.permissions(),
                issuedToken.issuedAt(),
                issuedToken.expiresAt()
        ));

        recordLoginEventBestEffort(
                LoginEventRequest.success(
                        user.userId(),
                        user.tenantId(),
                        clientIp
                )
        );

        return new LoginResponse(
                issuedToken.token(),
                "Bearer",
                jwtTokenService.expiresInSeconds(),
                new LoginUserView(
                        user.userId(),
                        user.tenantId(),
                        user.username(),
                        user.displayName(),
                        user.roles(),
                        user.permissions()
                )
        );
    }

    public void logout(String authorizationHeader) {
        String token = extractBearerToken(authorizationHeader);
        JwtPrincipal principal = jwtTokenService.verify(token);
        sessionStore.delete(principal.jti());
    }

    private UserAuthenticationResponse findUserWithoutLeakingExistence(
            LoginRequest request
    ) {
        try {
            return userIdentityClient.findForAuthentication(
                    request.tenantCode(),
                    request.username()
            );
        } catch (BusinessException exception) {
            if (exception.errorCode() == ErrorCode.USER_NOT_FOUND) {
                passwordEncoder.matches(
                        request.password(),
                        DUMMY_BCRYPT_HASH
                );
                throw new BusinessException(ErrorCode.AUTH_PASSWORD_ERROR);
            }

            throw exception;
        }
    }

    private void recordLoginEventBestEffort(LoginEventRequest event) {
        try {
            userIdentityClient.recordLoginEvent(event);
        } catch (RuntimeException exception) {
            LOGGER.warn(
                    "Failed to record login event for userId={}",
                    event.userId(),
                    exception
            );
        }
    }

    private String extractBearerToken(String authorizationHeader) {
        if (authorizationHeader == null
                || !authorizationHeader.startsWith("Bearer ")) {
            throw new BusinessException(ErrorCode.AUTH_REQUIRED);
        }

        String token = authorizationHeader.substring(7).trim();

        if (token.isEmpty()) {
            throw new BusinessException(ErrorCode.AUTH_REQUIRED);
        }

        return token;
    }
}
