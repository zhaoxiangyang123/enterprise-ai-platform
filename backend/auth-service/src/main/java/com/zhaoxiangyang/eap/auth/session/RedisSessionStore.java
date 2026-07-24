package com.zhaoxiangyang.eap.auth.session;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhaoxiangyang.eap.auth.config.AuthProperties;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.time.Instant;

@Repository
public class RedisSessionStore implements SessionStore {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final AuthProperties properties;

    public RedisSessionStore(
            StringRedisTemplate redisTemplate,
            ObjectMapper objectMapper,
            AuthProperties properties
    ) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.properties = properties;
    }

    @Override
    public void save(AuthSession session) {
        Duration ttl = Duration.between(Instant.now(), session.expiresAt());

        if (ttl.isZero() || ttl.isNegative()) {
            throw new BusinessException(ErrorCode.AUTH_TOKEN_EXPIRED);
        }

        try {
            String json = objectMapper.writeValueAsString(session);
            redisTemplate.opsForValue().set(key(session.jti()), json, ttl);
        } catch (JsonProcessingException | DataAccessException exception) {
            throw new BusinessException(
                    ErrorCode.SESSION_STORE_UNAVAILABLE,
                    ErrorCode.SESSION_STORE_UNAVAILABLE.message(),
                    exception
            );
        }
    }

    @Override
    public void delete(String jti) {
        try {
            redisTemplate.delete(key(jti));
        } catch (DataAccessException exception) {
            throw new BusinessException(
                    ErrorCode.SESSION_STORE_UNAVAILABLE,
                    ErrorCode.SESSION_STORE_UNAVAILABLE.message(),
                    exception
            );
        }
    }

    private String key(String jti) {
        return properties.redisSessionPrefix() + jti;
    }
}
