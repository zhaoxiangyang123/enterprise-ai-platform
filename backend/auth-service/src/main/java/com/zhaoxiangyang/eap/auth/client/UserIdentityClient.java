package com.zhaoxiangyang.eap.auth.client;

import com.zhaoxiangyang.eap.auth.client.dto.LoginEventRequest;
import com.zhaoxiangyang.eap.auth.client.dto.UserAuthenticationResponse;

public interface UserIdentityClient {

    UserAuthenticationResponse findForAuthentication(
            String tenantCode,
            String username
    );

    void recordLoginEvent(LoginEventRequest request);
}
