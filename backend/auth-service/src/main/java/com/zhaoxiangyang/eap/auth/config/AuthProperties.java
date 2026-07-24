package com.zhaoxiangyang.eap.auth.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Authentication settings. Secrets are supplied by environment variables in
 * shared environments; committed defaults exist only in application-local.yml.
 */
@ConfigurationProperties(prefix = "eap.auth")
public record AuthProperties(
        String userServiceBaseUrl,
        String internalToken,
        String jwtIssuer,
        String jwtSecretBase64,
        Duration accessTokenTtl,
        String redisSessionPrefix
) {

    public AuthProperties {
        requireText(userServiceBaseUrl, "userServiceBaseUrl");
        requireText(internalToken, "internalToken");
        requireText(jwtIssuer, "jwtIssuer");
        requireText(jwtSecretBase64, "jwtSecretBase64");
        requireText(redisSessionPrefix, "redisSessionPrefix");

        if (accessTokenTtl == null || accessTokenTtl.isZero() || accessTokenTtl.isNegative()) {
            throw new IllegalArgumentException("accessTokenTtl must be positive");
        }
    }

    private static void requireText(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(name + " must not be blank");
        }
    }
}
