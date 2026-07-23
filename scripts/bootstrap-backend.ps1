param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Get-Location).Path

if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    throw "当前目录不是 Git 项目根目录。请先 cd 到 Enterprise AI Platform 项目根目录后再执行。"
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $FullPath = Join-Path $ProjectRoot $RelativePath
    $Parent = Split-Path $FullPath -Parent

    if (-not (Test-Path $Parent)) {
        New-Item -ItemType Directory -Force $Parent | Out-Null
    }

    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($FullPath, $Content, $Utf8NoBom)
    Write-Host "CREATED  $RelativePath"
}

Write-Host "开始生成后端 Maven 多模块工程..."
Write-Host "注意：脚本会覆盖 backend 目录下同名的工程骨架文件。"

Write-Utf8NoBom -RelativePath 'backend\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.15</version>
        <relativePath/>
    </parent>

    <groupId>com.zhaoxiangyang.eap</groupId>
    <artifactId>eap-backend</artifactId>
    <version>0.1.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <name>Enterprise AI Platform Backend</name>
    <description>Enterprise AI Platform backend aggregator project</description>

    <modules>
        <module>eap-dependencies</module>
        <module>eap-common</module>
        <module>gateway-service</module>
        <module>auth-service</module>
        <module>user-service</module>
        <module>ai-service</module>
    </modules>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.release>21</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>

        <spring-cloud.version>2025.0.3</spring-cloud.version>
        <maven-compiler-plugin.version>3.15.0</maven-compiler-plugin.version>
        <maven-surefire-plugin.version>3.5.5</maven-surefire-plugin.version>
    </properties>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>${maven-compiler-plugin.version}</version>
                    <configuration>
                        <release>${maven.compiler.release}</release>
                        <parameters>true</parameters>
                        <encoding>${project.build.sourceEncoding}</encoding>
                    </configuration>
                </plugin>

                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-surefire-plugin</artifactId>
                    <version>${maven-surefire-plugin.version}</version>
                </plugin>
            </plugins>
        </pluginManagement>

        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\eap-dependencies\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-backend</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../pom.xml</relativePath>
    </parent>

    <artifactId>eap-dependencies</artifactId>
    <packaging>pom</packaging>

    <name>EAP Dependencies</name>
    <description>Shared parent and dependency management for EAP modules</description>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\eap-common\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>eap-common</artifactId>
    <packaging>jar</packaging>

    <name>EAP Common</name>
    <description>Shared components for Enterprise AI Platform</description>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\eap-common\src\main\java\com\zhaoxiangyang\eap\common\api\ApiResponse.java' -Content @'
package com.zhaoxiangyang.eap.common.api;

import java.time.Instant;

/**
 * Minimal unified API response used during the bootstrap stage.
 *
 * @param code      business result code
 * @param message   readable result message
 * @param data      response payload
 * @param timestamp server timestamp
 * @param <T>       payload type
 */
public record ApiResponse<T>(
        String code,
        String message,
        T data,
        long timestamp
) {

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(
                "SUCCESS",
                "操作成功",
                data,
                Instant.now().toEpochMilli()
        );
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\gateway-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>gateway-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP Gateway Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway-server-webflux</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\auth-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>auth-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP Auth Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>user-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP User Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\pom.xml' -Content @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.zhaoxiangyang.eap</groupId>
        <artifactId>eap-dependencies</artifactId>
        <version>0.1.0-SNAPSHOT</version>
        <relativePath>../eap-dependencies/pom.xml</relativePath>
    </parent>

    <artifactId>ai-service</artifactId>
    <packaging>jar</packaging>

    <name>EAP AI Service</name>

    <dependencies>
        <dependency>
            <groupId>com.zhaoxiangyang.eap</groupId>
            <artifactId>eap-common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>

'@

Write-Utf8NoBom -RelativePath 'backend\gateway-service\src\main\java\com\zhaoxiangyang\eap\gateway\GatewayApplication.java' -Content @'
package com.zhaoxiangyang.eap.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\gateway-service\src\test\java\com\zhaoxiangyang\eap\gateway\GatewayApplicationTests.java' -Content @'
package com.zhaoxiangyang.eap.gateway;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class GatewayApplicationTests {

    @Test
    void contextLoads() {
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\auth-service\src\main\java\com\zhaoxiangyang\eap\auth\AuthServiceApplication.java' -Content @'
package com.zhaoxiangyang.eap.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\auth-service\src\test\java\com\zhaoxiangyang\eap\auth\AuthServiceApplicationTests.java' -Content @'
package com.zhaoxiangyang.eap.auth;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class AuthServiceApplicationTests {

    @Test
    void contextLoads() {
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\java\com\zhaoxiangyang\eap\user\UserServiceApplication.java' -Content @'
package com.zhaoxiangyang.eap.user;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class UserServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\src\test\java\com\zhaoxiangyang\eap\user\UserServiceApplicationTests.java' -Content @'
package com.zhaoxiangyang.eap.user;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class UserServiceApplicationTests {

    @Test
    void contextLoads() {
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\main\java\com\zhaoxiangyang\eap\ai\AiServiceApplication.java' -Content @'
package com.zhaoxiangyang.eap.ai;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AiServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AiServiceApplication.class, args);
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\test\java\com\zhaoxiangyang\eap\ai\AiServiceApplicationTests.java' -Content @'
package com.zhaoxiangyang.eap.ai;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class AiServiceApplicationTests {

    @Test
    void contextLoads() {
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\auth-service\src\main\java\com\zhaoxiangyang\eap\auth\web\PingController.java' -Content @'
package com.zhaoxiangyang.eap.auth.web;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class PingController {

    @GetMapping("/api/auth/ping")
    public ApiResponse<Map<String, String>> ping() {
        return ApiResponse.success(Map.of(
                "service", "auth-service",
                "status", "UP"
        ));
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\java\com\zhaoxiangyang\eap\user\web\PingController.java' -Content @'
package com.zhaoxiangyang.eap.user.web;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class PingController {

    @GetMapping("/api/users/ping")
    public ApiResponse<Map<String, String>> ping() {
        return ApiResponse.success(Map.of(
                "service", "user-service",
                "status", "UP"
        ));
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\main\java\com\zhaoxiangyang\eap\ai\web\PingController.java' -Content @'
package com.zhaoxiangyang.eap.ai.web;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class PingController {

    @GetMapping("/api/ai/ping")
    public ApiResponse<Map<String, String>> ping() {
        return ApiResponse.success(Map.of(
                "service", "ai-service",
                "status", "UP"
        ));
    }
}

'@

Write-Utf8NoBom -RelativePath 'backend\gateway-service\src\main\resources\application.yml' -Content @'
server:
  port: 8080
  shutdown: graceful

spring:
  application:
    name: gateway-service
  cloud:
    gateway:
      server:
        webflux:
          routes:
            - id: auth-service
              uri: http://localhost:8081
              predicates:
                - Path=/api/auth/**
            - id: user-service
              uri: http://localhost:8082
              predicates:
                - Path=/api/users/**
            - id: ai-service
              uri: http://localhost:8083
              predicates:
                - Path=/api/ai/**,/api/conversations/**

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

'@

Write-Utf8NoBom -RelativePath 'backend\auth-service\src\main\resources\application.yml' -Content @'
server:
  port: 8081
  shutdown: graceful

spring:
  application:
    name: auth-service

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

'@

Write-Utf8NoBom -RelativePath 'backend\user-service\src\main\resources\application.yml' -Content @'
server:
  port: 8082
  shutdown: graceful

spring:
  application:
    name: user-service

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

'@

Write-Utf8NoBom -RelativePath 'backend\ai-service\src\main\resources\application.yml' -Content @'
server:
  port: 8083
  shutdown: graceful

spring:
  application:
    name: ai-service

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

'@

Write-Utf8NoBom -RelativePath 'backend\README.md' -Content @'
# Backend Bootstrap

## Modules

- `eap-dependencies`: shared parent and dependency management
- `eap-common`: shared Java components
- `gateway-service`: API gateway, port `8080`
- `auth-service`: authentication service, port `8081`
- `user-service`: user and permission service, port `8082`
- `ai-service`: AI conversation service, port `8083`

## Build

```powershell
mvn -f backend/pom.xml clean test
```

## Start services

Open four terminals and run:

```powershell
mvn -f backend/auth-service/pom.xml spring-boot:run
mvn -f backend/user-service/pom.xml spring-boot:run
mvn -f backend/ai-service/pom.xml spring-boot:run
mvn -f backend/gateway-service/pom.xml spring-boot:run
```

## Verify

```powershell
Invoke-RestMethod http://localhost:8080/api/auth/ping
Invoke-RestMethod http://localhost:8080/api/users/ping
Invoke-RestMethod http://localhost:8080/api/ai/ping
Invoke-RestMethod http://localhost:8080/actuator/health
```

'@

Write-Host ""
Write-Host "后端工程文件生成完成。"

if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "开始执行 Maven clean test..."
    & mvn -f (Join-Path $ProjectRoot "backend\pom.xml") clean test

    if ($LASTEXITCODE -ne 0) {
        throw "Maven 构建失败，退出码：$LASTEXITCODE"
    }

    Write-Host ""
    Write-Host "BUILD SUCCESS：全部模块已通过编译和基础测试。"
}
else {
    Write-Host "已跳过构建。稍后可手动执行：mvn -f backend/pom.xml clean test"
}

Write-Host ""
Write-Host "下一步建议执行："
Write-Host "  git diff --check"
Write-Host "  git status"
