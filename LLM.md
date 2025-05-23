# ERPNext Hanzo Deployment - LLM Context

## Project Overview

This repository contains ERPNext (Open Source ERP System) configured for deployment on Hanzo (Dokploy) platform. The setup is self-initializing with Docker Compose configurations for both production and development environments.

## Key Components

### 1. ERPNext Application
- **Framework**: Built on Frappe Framework
- **Version**: v15.62.0 (as per Docker images)
- **Languages**: Python (backend), JavaScript (frontend)
- **Database**: MariaDB 10.6
- **Cache/Queue**: Redis 7

### 2. Deployment Architecture

#### Services Structure
```
┌─────────────────────────────────────────────────┐
│                   Internet                      │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│          Traefik (SSL Termination)              │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│      Frontend (Nginx) - Port 8080               │
│  ┌─────────────┬──────────────┬──────────────┐ │
│  │ /socket.io/ │   /assets/   │      /*      │ │
│  └──────┬──────┴───────┬──────┴──────┬───────┘ │
└─────────┼──────────────┼─────────────┼─────────┘
          │              │             │
┌─────────▼────────┐    │    ┌───────▼────────┐
│ WebSocket :9000  │    │    │ Backend :8000  │
└──────────────────┘    │    └───────┬────────┘
                        │            │
                   Static Files      │
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
    ┌───────▼────────┐     ┌───────▼────────┐     ┌───────▼────────┐
    │  MariaDB :3306 │     │ Redis Cache    │     │ Redis Queue    │
    └────────────────┘     └────────────────┘     └────────────────┘
```

#### Key Services
1. **Configurator**: One-time initialization service that:
   - Configures bench settings
   - Creates ERPNext site
   - Installs ERPNext app
   - Enables scheduler
   - Sets production/dev mode

2. **Frontend**: Nginx reverse proxy (only exposed service)
   - Routes to backend, websocket, and static files
   - Traefik labels for SSL/routing
   - CSP headers for security

3. **Backend**: Frappe/ERPNext application server
4. **WebSocket**: Real-time communication (Socket.io)
5. **Workers**: Background job processors (short & long queues)
6. **Scheduler**: Cron-like task runner
7. **Database**: MariaDB for data persistence
8. **Redis**: Cache and job queue management

### 3. Environment Configuration

#### Required Variables (set in Hanzo UI)
- `DB_PASSWORD`: MariaDB root password
- `ADMIN_PASSWORD`: ERPNext Administrator password

#### Domains
- **Production**: erp.hanzo.ai
- **Development**: erp-dev.hanzo.ai

### 4. Key Features

#### Self-Initialization
- No manual setup required
- Configurator service handles all initialization
- Site creation automated with checks for existing sites
- Database wait loop ensures proper startup order

#### Security
- External `hanzo-network` for service isolation
- Traefik handles SSL/TLS termination
- CSP headers prevent XSS attacks
- HTTPS redirect enforced
- tmpfs for temporary files

#### Routing
- Single domain handles all services
- Frontend nginx proxies to appropriate backends
- WebSocket support with proper upgrade headers
- Static asset serving optimized

### 5. Development Patterns

#### Docker Compose Structure
- Service dependencies with health checks
- Platform specification (linux/amd64)
- Restart policies for reliability
- Volume persistence for data
- Network isolation

#### Traefik Integration
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.{service}-http.rule=Host(`{domain}`)"
  - "traefik.http.routers.{service}-https.tls.certresolver=letsencrypt"
  - "traefik.http.services.{service}.loadbalancer.server.port=8080"
```

### 6. Deployment Process

1. Set environment variables in Hanzo UI
2. Upload compose file to Hanzo
3. Deploy - system auto-initializes:
   - Waits for database
   - Creates site if not exists
   - Configures all settings
   - Starts all services

### 7. Maintenance Operations

#### Backup
```bash
docker exec <backend-container> bench --site <domain> backup --with-files
```

#### Updates
- Change image version in compose file
- Redeploy in Hanzo
- Migrations run automatically

#### Monitoring
- Check configurator logs for initialization issues
- Monitor worker queues for job processing
- Verify scheduler for cron tasks

### 8. File Structure

```
/Users/z/work/hanzo/erp/
├── compose.prod.yml          # Production Docker config
├── compose.dev.yml           # Development Docker config
├── docs/
│   ├── ENVIRONMENT_VARIABLES.md
│   ├── HANZO_DEPLOYMENT.md
│   └── ROUTING_ARCHITECTURE.md
├── erpnext/                  # ERPNext application code
│   ├── accounts/
│   ├── assets/
│   ├── buying/
│   ├── crm/
│   ├── manufacturing/
│   ├── selling/
│   ├── stock/
│   └── ...
├── README.md
├── package.json              # Node dependencies
└── pyproject.toml           # Python project config
```

### 9. Technology Stack

- **Backend**: Python 3.10+, Frappe Framework
- **Frontend**: JavaScript, Vue.js (in Frappe)
- **Database**: MariaDB 10.6
- **Cache**: Redis 7
- **Web Server**: Nginx
- **Process Manager**: Bench (Frappe's CLI)
- **Container Runtime**: Docker
- **Orchestration**: Docker Compose
- **Reverse Proxy**: Traefik

### 10. Best Practices Implemented

1. **12-Factor App Principles**
   - Config via environment variables
   - Stateless services (state in DB/Redis)
   - Dev/prod parity

2. **Container Best Practices**
   - Single process per container
   - Health checks for reliability
   - Non-root user execution
   - Minimal base images

3. **Security Best Practices**
   - Network isolation
   - Least privilege principle
   - CSP headers
   - HTTPS enforcement

### 11. Common Tasks

#### Access Console
```bash
docker exec -it <backend-container> bench console
```

#### Clear Cache
```bash
docker exec <backend-container> bench --site <domain> clear-cache
```

#### Run Migrations
```bash
docker exec <backend-container> bench --site <domain> migrate
```

### 12. Integration Points

- **Hanzo/Dokploy**: Via Docker Compose deployment
- **Traefik**: Via container labels for routing
- **Let's Encrypt**: Via Traefik for SSL certificates
- **External Services**: Can integrate with email, payment gateways, etc.

## Notes for AI Assistants

When working with this project:

1. **Deployment Changes**: Always update both prod and dev compose files
2. **Security**: Never expose internal services directly
3. **Configuration**: Use environment variables, not hardcoded values
4. **Initialization**: Let configurator handle all setup
5. **Updates**: Change image tags, not individual service configs
6. **Debugging**: Check configurator logs first for setup issues
7. **Networking**: All services must be on `hanzo-network`
8. **Routing**: Frontend service handles all external traffic

This setup prioritizes simplicity and reliability for production deployments while maintaining flexibility for development environments.
