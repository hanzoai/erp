# ERPNext Hanzo Deployment

ERPNext v15 configured for Docker Compose deployment on Hanzo (Dokploy) platform. Self-initializing -- no manual setup required.

## Stack

- **App**: ERPNext v15.62.0 on Frappe Framework (Python/JS)
- **DB**: MariaDB 10.6
- **Cache/Queue**: Redis 7
- **Web**: Nginx reverse proxy
- **SSL**: Traefik with Let's Encrypt
- **Container**: Docker Compose

## Domains

- **Production**: erp.hanzo.ai (`compose.prod.yml`)
- **Development**: erp-dev.hanzo.ai (`compose.dev.yml`)

## Services

```
Internet -> Traefik (SSL) -> Nginx :8080
                              ├── /* -> Backend :8000
                              ├── /socket.io/ -> WebSocket :9000
                              └── /assets/ -> Static Files

Backend -> MariaDB :3306
        -> Redis Cache
        -> Redis Queue
```

| Service | Role |
|---------|------|
| configurator | One-time init: creates site, installs app, enables scheduler |
| frontend | Nginx reverse proxy (only exposed service) |
| backend | Frappe/ERPNext app server |
| websocket | Socket.io real-time |
| worker-short | Short-running background jobs |
| worker-long | Long-running background jobs |
| scheduler | Cron task runner |
| db | MariaDB |
| redis-cache | Cache (LRU, 512MB) |
| redis-queue | Job queue (AOF persistence) |

## Environment Variables

Set in Hanzo UI:
- `DB_PASSWORD`: MariaDB root password
- `ADMIN_PASSWORD`: ERPNext Administrator password

## File Structure

```
/Users/z/work/hanzo/erp/
├── compose.prod.yml       # Production config
├── compose.dev.yml        # Development config
├── erpnext/               # ERPNext application source
├── docs/                  # Deployment and routing docs
├── pyproject.toml         # Python config
└── package.json           # Node dependencies
```

## Common Tasks

```bash
# Backup
docker exec <backend> bench --site erp.hanzo.ai backup --with-files

# Console
docker exec -it <backend> bench console

# Clear cache
docker exec <backend> bench --site erp.hanzo.ai clear-cache

# Migrations
docker exec <backend> bench --site erp.hanzo.ai migrate
```

## Deployment

1. Set `DB_PASSWORD` and `ADMIN_PASSWORD` in Hanzo UI
2. Deploy compose file -- configurator auto-initializes everything
3. Updates: change image version tag, redeploy (migrations run automatically)

## Notes for AI Assistants

- Always update both prod and dev compose files for deployment changes
- Never expose internal services directly -- frontend handles all external traffic
- All services must be on `hanzo-network`
- Check configurator logs first for setup issues
- Use environment variables, not hardcoded values

## Rules for AI Assistants

1. ALWAYS update LLM.md with significant discoveries
2. NEVER commit symlinked files (.AGENTS.md, CLAUDE.md, etc.) -- they are in .gitignore
3. NEVER create random summary files -- update THIS file
