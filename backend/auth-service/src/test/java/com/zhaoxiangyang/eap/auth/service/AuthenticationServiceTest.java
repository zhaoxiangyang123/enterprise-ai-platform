package com.zhaoxiangyang.eap.auth.service;

import com.zhaoxiangyang.eap.auth.client.UserIdentityClient;
import com.zhaoxiangyang.eap.auth.client.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;
import com.zhaoxiangyang.eap.auth.config.AuthProperties;
import com.zhaoxiangyang.eap.auth.jwt.JwtPrincipal;
import com.zhaoxiangyang.eap.auth.jwt.JwtTokenService;
import com.zhaoxiangyang.eap.auth.session.AuthSession;
import com.zhaoxiangyang.eap.auth.session.SessionStore;
import com.zhaoxiangyang.eap.auth.web.LoginRequest;
import com.zhaoxiangyang.eap.auth.web.LoginResponse;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthenticationServiceTest {

    private final UserIdentityClient userIdentityClient =
            mock(UserIdentityClient.class);
    private final SessionStore sessionStore = mock(SessionStore.class);
    private final PasswordEncoder passwordEncoder =
            new BCryptPasswordEncoder(4);

    private AuthenticationService authenticationService;
    private JwtTokenService jwtTokenService;

    @BeforeEach
    void setUp() {
        AuthProperties properties = new AuthProperties(
                "http://127.0.0.1:8082",
                "internal-token",
                "test-issuer",
                "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDE=",
                Duration.ofHours(2),
                "test:session:"
        );

        Clock clock = Clock.fixed(
                Instant.parse("2026-07-24T00:00:00Z"),
                ZoneOffset.UTC
        );

        jwtTokenService = new JwtTokenService(properties, clock);
        authenticationService = new AuthenticationService(
                userIdentityClient,
                passwordEncoder,
                jwtTokenService,
                sessionStore
        );
    }

    @Test
    void shouldIssueTokenAndSaveRedisSessionForValidCredentials() {
        UserAuthenticationResponse user = userWithPassword("Admin@123");

        when(userIdentityClient.findForAuthentication("default", "admin"))
                .thenReturn(user);
        doNothing().when(sessionStore).save(any(AuthSession.class));
        doNothing().when(userIdentityClient)
                .recordLoginEvent(any(LoginEventRequest.class));

        LoginResponse response = authenticationService.login(
                new LoginRequest("admin", "Admin@123", "default"),
                "127.0.0.1"
        );

        JwtPrincipal principal =
                jwtTokenService.verify(response.accessToken());

        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresIn()).isEqualTo(7200);
        assertThat(response.user().roles()).containsExactly("SYSTEM_ADMIN");
        assertThat(principal.userId()).isEqualTo(1001L);
        assertThat(principal.tenantId()).isEqualTo(1L);

        ArgumentCaptor<AuthSession> sessionCaptor =
                ArgumentCaptor.forClass(AuthSession.class);
        verify(sessionStore).save(sessionCaptor.capture());
        assertThat(sessionCaptor.getValue().permissions())
                .containsExactly("ai:chat", "user:read");
    }

    @Test
    void shouldReturnGenericPasswordErrorForWrongPassword() {
        when(userIdentityClient.findForAuthentication("default", "admin"))
                .thenReturn(userWithPassword("Admin@123"));

        assertThatThrownBy(
                () -> authenticationService.login(
                        new LoginRequest("admin", "WrongPass123", "default"),
                        "127.0.0.1"
                )
        )
                .isInstanceOf(BusinessException.class)
                .extracting(exception ->
                        ((BusinessException) exception).errorCode()
                )
                .isEqualTo(ErrorCode.AUTH_PASSWORD_ERROR);
    }

    @Test
    void shouldHideWhetherUsernameExists() {
        when(userIdentityClient.findForAuthentication("default", "missing"))
                .thenThrow(new BusinessException(ErrorCode.USER_NOT_FOUND));

        assertThatThrownBy(
                () -> authenticationService.login(
                        new LoginRequest("missing", "WrongPass123", "default"),
                        "127.0.0.1"
                )
        )
                .isInstanceOf(BusinessException.class)
                .extracting(exception ->
                        ((BusinessException) exception).errorCode()
                )
                .isEqualTo(ErrorCode.AUTH_PASSWORD_ERROR);
    }

    private UserAuthenticationResponse userWithPassword(String password) {
        return new UserAuthenticationResponse(
                1001L,
                1L,
                "default",
                "admin",
                passwordEncoder.encode(password),
                "系统管理员",
                "admin@example.com",
                List.of("SYSTEM_ADMIN"),
                List.of("ai:chat", "user:read")
        );
    }
}
