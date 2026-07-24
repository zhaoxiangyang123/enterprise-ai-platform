package com.zhaoxiangyang.eap.user.security;

import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import com.zhaoxiangyang.eap.user.config.InternalApiProperties;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Constant-time comparison for internal service credentials.
 */
@Component
public class InternalAccessVerifier {

    private final byte[] expectedToken;

    public InternalAccessVerifier(InternalApiProperties properties) {
        this.expectedToken = properties.token().getBytes(StandardCharsets.UTF_8);
    }

    public void verify(String providedToken) {
        if (providedToken == null) {
            throw new BusinessException(ErrorCode.INTERNAL_CALL_FORBIDDEN);
        }

        byte[] provided = providedToken.getBytes(StandardCharsets.UTF_8);

        if (!MessageDigest.isEqual(expectedToken, provided)) {
            throw new BusinessException(ErrorCode.INTERNAL_CALL_FORBIDDEN);
        }
    }
}
