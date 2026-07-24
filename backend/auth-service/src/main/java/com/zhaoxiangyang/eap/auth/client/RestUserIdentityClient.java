package com.zhaoxiangyang.eap.auth.client;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhaoxiangyang.eap.auth.client.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationRequest;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;
import com.zhaoxiangyang.eap.auth.config.AuthProperties;
import com.zhaoxiangyang.eap.common.api.ApiResponse;
import com.zhaoxiangyang.eap.common.constant.InternalHeaders;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.io.IOException;

/**
 * Synchronous internal client used by the login path.
 */
@Component
public class RestUserIdentityClient implements UserIdentityClient {

    private static final ParameterizedTypeReference<
            ApiResponse<UserAuthenticationResponse>
            > AUTHENTICATION_RESPONSE_TYPE = new ParameterizedTypeReference<>() {
    };

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final AuthProperties properties;

    public RestUserIdentityClient(
            RestClient userServiceRestClient,
            ObjectMapper objectMapper,
            AuthProperties properties
    ) {
        this.restClient = userServiceRestClient;
        this.objectMapper = objectMapper;
        this.properties = properties;
    }

    @Override
    public UserAuthenticationResponse findForAuthentication(
            String tenantCode,
            String username
    ) {
        try {
            ApiResponse<UserAuthenticationResponse> response = restClient
                    .post()
                    .uri("/internal/users/authentication")
                    .header(
                            InternalHeaders.INTERNAL_TOKEN,
                            properties.internalToken()
                    )
                    .body(new UserAuthenticationRequest(tenantCode, username))
                    .retrieve()
                    .onStatus(
                            status -> status.isError(),
                            this::mapErrorResponse
                    )
                    .body(AUTHENTICATION_RESPONSE_TYPE);

            if (response == null || response.data() == null) {
                throw new BusinessException(ErrorCode.SYSTEM_ERROR);
            }

            return response.data();
        } catch (BusinessException exception) {
            throw exception;
        } catch (ResourceAccessException exception) {
            throw new BusinessException(
                    ErrorCode.USER_SERVICE_UNAVAILABLE,
                    ErrorCode.USER_SERVICE_UNAVAILABLE.message(),
                    exception
            );
        } catch (RestClientException exception) {
            throw new BusinessException(
                    ErrorCode.USER_SERVICE_UNAVAILABLE,
                    ErrorCode.USER_SERVICE_UNAVAILABLE.message(),
                    exception
            );
        }
    }

    @Override
    public void recordLoginEvent(LoginEventRequest request) {
        try {
            restClient
                    .post()
                    .uri("/internal/users/login-events")
                    .header(
                            InternalHeaders.INTERNAL_TOKEN,
                            properties.internalToken()
                    )
                    .body(request)
                    .retrieve()
                    .onStatus(
                            status -> status.isError(),
                            this::mapErrorResponse
                    )
                    .toBodilessEntity();
        } catch (BusinessException exception) {
            throw exception;
        } catch (RestClientException exception) {
            throw new BusinessException(
                    ErrorCode.USER_SERVICE_UNAVAILABLE,
                    ErrorCode.USER_SERVICE_UNAVAILABLE.message(),
                    exception
            );
        }
    }

    private void mapErrorResponse(
            HttpRequest request,
            ClientHttpResponse response
    ) throws IOException {
        byte[] body = response.getBody().readAllBytes();

        if (body.length == 0) {
            throw new BusinessException(ErrorCode.USER_SERVICE_UNAVAILABLE);
        }

        ApiResponse<Object> apiResponse = objectMapper.readValue(
                body,
                new TypeReference<>() {
                }
        );

        ErrorCode errorCode = ErrorCode.fromCode(apiResponse.code());
        throw new BusinessException(errorCode, apiResponse.message());
    }
}
