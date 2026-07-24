package com.zhaoxiangyang.eap.common.web;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;

/**
 * Explicitly imported by servlet services.
 *
 * The gateway does not import this configuration, so eap-common can remain
 * compatible with the gateway's reactive WebFlux runtime.
 */
@Configuration(proxyBeanMethods = false)
public class CommonWebMvcConfiguration {

    @Bean
    public FilterRegistrationBean<RequestIdFilter> requestIdFilterRegistration() {
        FilterRegistrationBean<RequestIdFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new RequestIdFilter());
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE);
        registration.addUrlPatterns("/*");
        return registration;
    }

    @Bean
    public GlobalExceptionHandler globalExceptionHandler() {
        return new GlobalExceptionHandler();
    }
}
