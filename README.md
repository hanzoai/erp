# ERPNext Docker Deployment for Hanzo

Self-initializing Docker configurations for deploying ERPNext on Hanzo (Dokploy). No manual setup required - just deploy and go!

## 🌐 Environments

- **Production**: https://erp.hanzo.ai (single domain for all services)
- **Development**: https://erp-dev.hanzo.ai (single domain for all services)

## 📁 Files

- **`compose.prod.yml`** - Production Docker Compose (self-initializing)
- **`compose.dev.yml`** - Development Docker Compose (self-initializing)
- **`ENVIRONMENT_VARIABLES.md`** - Environment variables reference
- **`ROUTING_ARCHITECTURE.md`** - How routing and services work
- **`HANZO_DEPLOYMENT.md`** - Detailed deployment guide

## 🚀 Quick Start

### 1. Set Environment Variables in Hanzo

In your Hanzo/Dokploy UI, set these two variables:

```bash
DB_PASSWORD=<generate_secure_password>
ADMIN_PASSWORD=<your_admin_password>
```

Generate a secure DB_PASSWORD:
```bash
openssl rand -base64 32
```

### 2. Deploy

1. Create new app in Hanzo
2. Choose "Docker Compose" deployment type
3. Upload the appropriate compose file:
   - Production: `compose.prod.yml`
   - Development: `compose.dev.yml`
4. Click Deploy

That's it! The system will automatically:
- Configure all services
- Create the database
- Initialize the ERPNext site
- Set up the scheduler
- Configure production/development settings

### 3. Access Your Instance

Once deployment is complete (3-5 minutes):

- **Production**: https://erp.hanzo.ai
- **Development**: https://erp-dev.hanzo.ai

Login with:
- Username: `Administrator`
- Password: The `ADMIN_PASSWORD` you set in Hanzo

## 🔧 Architecture

Each environment includes:

- **MariaDB** - Database server
- **Redis** (2 instances) - Cache and queue management
- **Backend** - Frappe/ERPNext application server
- **Frontend** - Nginx web server (only service exposed via Traefik)
- **WebSocket** - Real-time communication
- **Workers** - Background job processors (short & long queues)
- **Scheduler** - Scheduled task runner
- **Configurator** - One-time setup service (auto-creates site)

**Note**: All traffic routes through the Frontend service. No additional domains or ports needed!

## 🔐 Security Features

- External `hanzo-network` for isolation
- Traefik SSL/TLS termination
- Content Security Policy headers
- HTTPS redirect middleware
- tmpfs for temporary files

## 📊 Resource Allocation

### Production
- MariaDB: 1GB buffer pool, 200 max connections
- Redis Cache: 512MB max memory
- Production mode enabled

### Development
- MariaDB: 512MB buffer pool, 100 max connections
- Redis Cache: 256MB max memory
- Developer mode enabled

## 🛠️ Maintenance

### Backup
```bash
# Find your backend container
docker ps | grep backend

# Run backup
docker exec <backend-container> bench --site <domain> backup --with-files
```

### Clear Cache
```bash
docker exec <backend-container> bench --site <domain> clear-cache
```

### View Logs
```bash
# All services
docker-compose -f compose.prod.yml logs

# Specific service
docker logs <container-name> -f
```

### Update ERPNext Version
1. Update the image tag in compose file (all services use same version)
2. Redeploy in Hanzo
3. System will automatically run migrations

## 🐛 Troubleshooting

### Check Service Health
```bash
docker ps
```

### Database Issues
Check the configurator logs - it handles all initialization:
```bash
docker logs <configurator-container>
```

### Frontend Not Accessible
- Verify Traefik labels in compose file
- Check domain configuration in Hanzo
- Ensure `hanzo-network` exists

## 📚 Resources

- [ERPNext Documentation](https://docs.erpnext.com)
- [Frappe Framework](https://frappeframework.com)
- [Hanzo Platform](https://hanzo.ai)
