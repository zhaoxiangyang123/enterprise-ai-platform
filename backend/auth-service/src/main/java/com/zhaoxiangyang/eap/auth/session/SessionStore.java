package com.zhaoxiangyang.eap.auth.session;

public interface SessionStore {

    void save(AuthSession session);

    void delete(String jti);
}
