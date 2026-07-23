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
