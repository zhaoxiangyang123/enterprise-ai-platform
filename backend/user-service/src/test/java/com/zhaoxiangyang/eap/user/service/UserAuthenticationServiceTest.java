package com.zhaoxiangyang.eap.user.service;

import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import com.zhaoxiangyang.eap.user.domain.AuthenticationUser;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.AuthenticationUserResponse;
import com.zhaoxiangyang.eap.user.mapper.UserAuthenticationMapper;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class UserAuthenticationServiceTest {

    private final UserAuthenticationMapper mapper =
            mock(UserAuthenticationMapper.class);

    private final Clock clock = Clock.fixed(
            Instant.parse("2026-07-24T00:00:00Z"),
            ZoneOffset.UTC
    );

    private final UserAuthenticationService service =
            new UserAuthenticationService(mapper, clock);

    @Test
    void shouldReturnAuthenticationAggregateForEnabledUser() {
        AuthenticationUser user = enabledUser();

        when(mapper.findByTenantCodeAndUsername("default", "admin"))
                .thenReturn(Optional.of(user));
        when(mapper.findRoleCodes(1L, 1001L))
                .thenReturn(List.of("SYSTEM_ADMIN"));
        when(mapper.findPermissionCodes(1L, 1001L))
                .thenReturn(List.of("ai:chat", "user:read"));

        AuthenticationUserResponse result =
                service.findForAuthentication("default", "admin");

        assertThat(result.userId()).isEqualTo(1001L);
        assertThat(result.roles()).containsExactly("SYSTEM_ADMIN");
        assertThat(result.permissions()).containsExactly("ai:chat", "user:read");
    }

    @Test
    void shouldRejectDisabledTenant() {
        AuthenticationUser user = new AuthenticationUser(
                1001L,
                1L,
                "default",
                "admin",
                "hash",
                "系统管理员",
                "admin@example.com",
                1,
                0,
                0,
                null
        );

        when(mapper.findByTenantCodeAndUsername("default", "admin"))
                .thenReturn(Optional.of(user));

        assertThatThrownBy(
                () -> service.findForAuthentication("default", "admin")
        )
                .isInstanceOf(BusinessException.class)
                .extracting(exception ->
                        ((BusinessException) exception).errorCode()
                )
                .isEqualTo(ErrorCode.TENANT_DISABLED);
    }

    @Test
    void shouldRejectCurrentlyLockedUser() {
        AuthenticationUser user = new AuthenticationUser(
                1001L,
                1L,
                "default",
                "admin",
                "hash",
                "系统管理员",
                "admin@example.com",
                1,
                1,
                3,
                LocalDateTime.of(2026, 7, 24, 1, 0)
        );

        when(mapper.findByTenantCodeAndUsername("default", "admin"))
                .thenReturn(Optional.of(user));

        assertThatThrownBy(
                () -> service.findForAuthentication("default", "admin")
        )
                .isInstanceOf(BusinessException.class)
                .extracting(exception ->
                        ((BusinessException) exception).errorCode()
                )
                .isEqualTo(ErrorCode.USER_DISABLED);
    }

    private AuthenticationUser enabledUser() {
        return new AuthenticationUser(
                1001L,
                1L,
                "default",
                "admin",
                "hash",
                "系统管理员",
                "admin@example.com",
                1,
                1,
                0,
                null
        );
    }
}
