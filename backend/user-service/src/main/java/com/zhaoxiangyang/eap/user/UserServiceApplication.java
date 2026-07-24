package com.zhaoxiangyang.eap.user;

import com.zhaoxiangyang.eap.common.web.CommonWebMvcConfiguration;
import com.zhaoxiangyang.eap.user.config.InternalApiProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Import;

@SpringBootApplication
@EnableConfigurationProperties(InternalApiProperties.class)
@Import(CommonWebMvcConfiguration.class)
public class UserServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}
