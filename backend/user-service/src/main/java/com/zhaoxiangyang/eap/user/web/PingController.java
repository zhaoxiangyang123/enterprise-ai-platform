package com.zhaoxiangyang.eap.user.web;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class PingController {

    @GetMapping("/api/users/ping")
    public ApiResponse<Map<String, String>> ping() {
        return ApiResponse.success(Map.of(
                "service", "user-service",
                "status", "UP"
        ));
    }
}
