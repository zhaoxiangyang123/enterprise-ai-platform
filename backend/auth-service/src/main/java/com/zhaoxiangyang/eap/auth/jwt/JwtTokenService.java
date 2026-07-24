package com.zhaoxiangyang.eap.auth.jwt;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JOSEObjectType;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;
import com.zhaoxiangyang.eap.auth.config.AuthProperties;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.springframework.stereotype.Service;

import java.text.ParseException;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/**
 * Issues and verifies HMAC-SHA256 access tokens.
 */
@Service
public class JwtTokenService {

    private static final int MINIMUM_HS256_KEY_BYTES = 32;

    private final AuthProperties properties;
    private final Clock clock;
    private final byte[] secret;

    public JwtTokenService(AuthProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
        this.secret = decodeSecret(properties.jwtSecretBase64());

        if (secret.length < MINIMUM_HS256_KEY_BYTES) {
            throw new IllegalArgumentException(
                    "JWT secret must contain at least 32 decoded bytes"
            );
        }
    }

    public IssuedToken issue(UserAuthenticationResponse user) {
        Instant issuedAt = Instant.now(clock);
        Instant expiresAt = issuedAt.plus(properties.accessTokenTtl());
        String jti = UUID.randomUUID().toString().replace("-", "");

        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .issuer(properties.jwtIssuer())
                .subject(user.userId().toString())
                .jwtID(jti)
                .issueTime(Date.from(issuedAt))
                .expirationTime(Date.from(expiresAt))
                .claim("tenantId", user.tenantId())
                .claim("username", user.username())
                .claim("roles", user.roles())
                .build();

        SignedJWT signedJwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.HS256)
                        .type(JOSEObjectType.JWT)
                        .build(),
                claims
        );

        try {
            signedJwt.sign(new MACSigner(secret));
        } catch (JOSEException exception) {
            throw new BusinessException(
                    ErrorCode.SYSTEM_ERROR,
                    "访问令牌签发失败",
                    exception
            );
        }

        return new IssuedToken(
                signedJwt.serialize(),
                jti,
                issuedAt,
                expiresAt
        );
    }

    public JwtPrincipal verify(String token) {
        try {
            SignedJWT signedJwt = SignedJWT.parse(token);

            if (!JWSAlgorithm.HS256.equals(signedJwt.getHeader().getAlgorithm())
                    || !signedJwt.verify(new MACVerifier(secret))) {
                throw new BusinessException(ErrorCode.AUTH_TOKEN_INVALID);
            }

            JWTClaimsSet claims = signedJwt.getJWTClaimsSet();
            validateClaims(claims);

            Object tenantIdClaim = claims.getClaim("tenantId");
            if (!(tenantIdClaim instanceof Number tenantIdNumber)) {
                throw new BusinessException(ErrorCode.AUTH_TOKEN_INVALID);
            }

            List<String> roles = claims.getStringListClaim("roles");

            return new JwtPrincipal(
                    Long.valueOf(claims.getSubject()),
                    tenantIdNumber.longValue(),
                    claims.getStringClaim("username"),
                    roles == null ? List.of() : roles,
                    claims.getJWTID(),
                    claims.getIssueTime().toInstant(),
                    claims.getExpirationTime().toInstant()
            );
        } catch (BusinessException exception) {
            throw exception;
        } catch (ParseException | JOSEException | RuntimeException exception) {
            throw new BusinessException(
                    ErrorCode.AUTH_TOKEN_INVALID,
                    ErrorCode.AUTH_TOKEN_INVALID.message(),
                    exception
            );
        }
    }

    public long expiresInSeconds() {
        return properties.accessTokenTtl().toSeconds();
    }

    private void validateClaims(JWTClaimsSet claims) {
        if (!properties.jwtIssuer().equals(claims.getIssuer())
                || claims.getSubject() == null
                || claims.getJWTID() == null
                || claims.getIssueTime() == null
                || claims.getExpirationTime() == null) {
            throw new BusinessException(ErrorCode.AUTH_TOKEN_INVALID);
        }

        Instant now = Instant.now(clock);
        if (!claims.getExpirationTime().toInstant().isAfter(now)) {
            throw new BusinessException(ErrorCode.AUTH_TOKEN_EXPIRED);
        }
    }

    private byte[] decodeSecret(String encodedSecret) {
        try {
            return Base64.getDecoder().decode(encodedSecret);
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException(
                    "jwtSecretBase64 must be valid Base64",
                    exception
            );
        }
    }
}
