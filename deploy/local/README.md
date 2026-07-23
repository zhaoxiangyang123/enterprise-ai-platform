# Local Infrastructure

Local dependencies for the first iteration:

- MySQL 8.4 LTS
- Redis 7.2
- Nacos 3.2 standalone

## Ports

| Component | Address |
|---|---|
| MySQL | `127.0.0.1:3306` |
| Redis | `127.0.0.1:6379` |
| Nacos server | `127.0.0.1:8848` |
| Nacos console | `http://127.0.0.1:8849` |
| Nacos gRPC | `127.0.0.1:9848` |

Nacos uses host port 8849 for its console because gateway-service uses 8080.

## Commands

```powershell
.\scripts\start-infrastructure.ps1
.\scripts\status-infrastructure.ps1
.\scripts\logs-infrastructure.ps1
.\scripts\stop-infrastructure.ps1
```

Delete all local data:

```powershell
.\scripts\stop-infrastructure.ps1 -DeleteData
```

The first startup copies `.env.example` to `.env`. `.env` is ignored by Git.

Local Nacos uses standalone embedded storage for development only. A later deployment stage will move it to authenticated cluster mode with external persistent storage.
