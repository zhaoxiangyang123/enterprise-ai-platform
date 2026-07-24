package com.zhaoxiangyang.eap.auth.web;

import com.zhaoxiangyang.eap.auth.service.AuthenticationService;
import com.zhaoxiangyang.eap.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationService authenticationService;

    public AuthController(AuthenticationService authenticationService) {
        this.authenticationService = authenticationService;
    }

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest servletRequest
    ) {
        LoginResponse response = authenticationService.login(
                request,
                servletRequest.getRemoteAddr()
        );

        return ApiResponse.success("登录成功", response);
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(
            @RequestHeader(
                    name = HttpHeaders.AUTHORIZATION,
                    required = false
            )
            String authorizationHeader
    ) {
        authenticationService.logout(authorizationHeader);
        return ApiResponse.success("退出成功", null);
    }
}
