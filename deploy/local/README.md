# Local Infrastructure

Local dependencies for the first iteration:

- MySQL 8.4 LTS
- Redis 7.2
- Nacos 3.2 standalone

## Ports

The committed defaults are shown below. A developer can override them in
`deploy/local/.env`.

| Component | Default address |
|---|---|
| MySQL | `127.0.0.1:13306` |
| Redis | `127.0.0.1:6379` |
| Nacos server | `127.0.0.1:8848` |
| Nacos console | `http://127.0.0.1:8849` |
| Nacos gRPC | `127.0.0.1:9848` |

The MySQL host port uses `13306` so it can coexist with a MySQL installation
using the conventional host port `3306`.

Nacos uses host port `8849` for its console. Inside the Nacos container the
console listens on port `8080`; this does not conflict with the gateway running
on the Windows host.

## Commands

```powershell
.\scripts\start-infrastructure.ps1
.\scripts\status-infrastructure.ps1
.\scripts\logs-infrastructure.ps1
.\scripts\stop-infrastructure.ps1
```

View one service's logs:

```powershell
.\scripts\logs-infrastructure.ps1 -Service mysql -Tail 100
```

Delete all local data:

```powershell
.\scripts\stop-infrastructure.ps1 -DeleteData
```

The first startup copies `.env.example` to `.env`. The real `.env` is ignored
by Git.

## MySQL configuration

MySQL development settings are passed as container startup arguments rather
than through a Windows bind-mounted `.cnf` file. This avoids the Linux
`world-writable config file ... is ignored` warning caused by Windows-mounted
file permissions.

Local Nacos uses standalone embedded storage for development only. A later
deployment stage will move it to authenticated cluster mode with external
persistent storage.
