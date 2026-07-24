package com.zhaoxiangyang.eap.user.config;

import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Authentication for service-to-service endpoints.
 */
@Validated
@ConfigurationProperties(prefix = "eap.internal")
public record InternalApiProperties(
        @NotBlank String token
) {
}
