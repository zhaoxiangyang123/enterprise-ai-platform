package com.zhaoxiangyang.eap.auth.jwt;

import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;
import com.zhaoxiangyang.eap.auth.config.AuthProperties;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtTokenServiceTest {

    private static final String SECRET =
            "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDE=";

    @Test
    void shouldIssueAndVerifyToken() {
        Instant now = Instant.parse("2026-07-24T00:00:00Z");
        JwtTokenService service = serviceAt(now, Duration.ofHours(2));

        IssuedToken issuedToken = service.issue(user());
        JwtPrincipal principal = service.verify(issuedToken.token());

        assertThat(principal.userId()).isEqualTo(1001L);
        assertThat(principal.tenantId()).isEqualTo(1L);
        assertThat(principal.roles()).containsExactly("SYSTEM_ADMIN");
    }

    @Test
    void shouldRejectExpiredToken() {
        Instant issuedAt = Instant.parse("2026-07-24T00:00:00Z");
        JwtTokenService issuer = serviceAt(issuedAt, Duration.ofMinutes(1));
        IssuedToken token = issuer.issue(user());

        JwtTokenService verifier = serviceAt(
                issuedAt.plus(Duration.ofMinutes(2)),
                Duration.ofMinutes(1)
        );

        assertThatThrownBy(() -> verifier.verify(token.token()))
                .isInstanceOf(BusinessException.class)
                .extracting(exception ->
                        ((BusinessException) exception).errorCode()
                )
                .isEqualTo(ErrorCode.AUTH_TOKEN_EXPIRED);
    }

    private JwtTokenService serviceAt(Instant now, Duration ttl) {
        AuthProperties properties = new AuthProperties(
                "http://127.0.0.1:8082",
                "internal-token",
                "test-issuer",
                SECRET,
                ttl,
                "test:session:"
        );

        return new JwtTokenService(
                properties,
                Clock.fixed(now, ZoneOffset.UTC)
        );
    }

    private UserAuthenticationResponse user() {
        return new UserAuthenticationResponse(
                1001L,
                1L,
                "default",
                "admin",
                "unused",
                "系统管理员",
                "admin@example.com",
                List.of("SYSTEM_ADMIN"),
                List.of("ai:chat")
        );
    }
}
