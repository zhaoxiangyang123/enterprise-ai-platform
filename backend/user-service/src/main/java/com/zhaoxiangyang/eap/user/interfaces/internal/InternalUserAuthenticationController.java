package com.zhaoxiangyang.eap.user.interfaces.internal;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import com.zhaoxiangyang.eap.common.constant.InternalHeaders;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.AuthenticationUserQueryRequest;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.AuthenticationUserResponse;
import com.zhaoxiangyang.eap.user.interfaces.internal.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.user.security.InternalAccessVerifier;
import com.zhaoxiangyang.eap.user.service.UserAuthenticationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/users")
public class InternalUserAuthenticationController {

    private final InternalAccessVerifier accessVerifier;
    private final UserAuthenticationService authenticationService;

    public InternalUserAuthenticationController(
            InternalAccessVerifier accessVerifier,
            UserAuthenticationService authenticationService
    ) {
        this.accessVerifier = accessVerifier;
        this.authenticationService = authenticationService;
    }

    @PostMapping("/authentication")
    public ApiResponse<AuthenticationUserResponse> findForAuthentication(
            @RequestHeader(
                    name = InternalHeaders.INTERNAL_TOKEN,
                    required = false
            )
            String internalToken,
            @Valid @RequestBody AuthenticationUserQueryRequest request
    ) {
        accessVerifier.verify(internalToken);

        AuthenticationUserResponse response =
                authenticationService.findForAuthentication(
                        request.tenantCode(),
                        request.username()
                );

        return ApiResponse.success(response);
    }

    @PostMapping("/login-events")
    public ApiResponse<Void> recordLoginEvent(
            @RequestHeader(
                    name = InternalHeaders.INTERNAL_TOKEN,
                    required = false
            )
            String internalToken,
            @Valid @RequestBody LoginEventRequest request
    ) {
        accessVerifier.verify(internalToken);
        authenticationService.recordLoginEvent(request);
        return ApiResponse.success("登录事件已记录", null);
    }
}
