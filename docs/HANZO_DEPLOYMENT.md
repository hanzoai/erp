# Hanzo ERPNext Deployment Guide

Complete guide for deploying self-initializing ERPNext on Hanzo platform.

## Overview

This deployment is completely self-contained. Once you deploy the Docker Compose file with the required environment variables, ERPNext will:

1. Start all services
2. Wait for dependencies
3. Create the database
4. Initialize the ERPNext site
5. Configure all settings
6. Be ready to use

No manual intervention required!

## Environment Variables

Only two variables needed in Hanzo UI:

| Variable | Description | How to Generate |
|----------|-------------|-----------------|
| `DB_PASSWORD` | MariaDB root password | `openssl rand -base64 32` |
| `ADMIN_PASSWORD` | ERPNext Administrator password | Choose a strong password |

## Deployment Steps

### 1. Create Application in Hanzo

1. Log into Hanzo
2. Click "Create New Application"
3. Choose "Docker Compose"
4. Name your application:
   - Production: `erp-prod`
   - Development: `erp-dev`

### 2. Configure Application

1. Upload the appropriate compose file:
   - Production: `compose.prod.yml`
   - Development: `compose.dev.yml`

2. Set environment variables in Hanzo UI

3. Ensure domain matches:
   - Production: `erp.hanzo.ai`
   - Development: `erp-dev.hanzo.ai`

### 3. Deploy

Click "Deploy" and wait. The system will:

- Pull all Docker images
- Start database and Redis
- Run the configurator to:
  - Set up bench configuration
  - Create the ERPNext site
  - Install ERPNext app
  - Enable scheduler
  - Configure production/dev settings
- Start all application services

### 4. Verify Deployment

After 3-5 minutes, visit your domain:
- https://erp.hanzo.ai (production)
- https://erp-dev.hanzo.ai (development)

## How It Works

### Configurator Service

The key to self-initialization is the `configurator` service that:

```yaml
configurator:
  restart: "no"  # Runs once and exits
  command:
    - |
      # Configure bench settings
      bench set-config -g db_host db
      
      # Wait for database
      until mysql -h db -u root -p${DB_PASSWORD} -e "SELECT 1"; do
        sleep 2
      done
      
      # Create site if it doesn't exist
      if ! bench --site $DOMAIN list | grep -q "$DOMAIN"; then
        bench new-site $DOMAIN \
          --mariadb-root-password ${DB_PASSWORD} \
          --admin-password ${ADMIN_PASSWORD} \
          --install-app erpnext
      fi
      
      # Configure site
      bench --site $DOMAIN enable-scheduler
      bench --site $DOMAIN set-config developer_mode 0
```

### Service Dependencies

All services depend on the configurator completing successfully:

```yaml
backend:
  depends_on:
    configurator:
      condition: service_completed_successfully
```

This ensures the site is created before any service tries to use it.

## Monitoring Deployment

### Check Configurator Logs

The configurator handles all initialization. Check its logs:

```bash
docker logs $(docker ps -a | grep configurator | awk '{print $1}')
```

### Check Service Status

```bash
# See all running services
docker ps

# Check specific service logs
docker logs <container-name> -f
```

## Post-Deployment

### First Login

- URL: https://[your-domain]
- Username: `Administrator`
- Password: The `ADMIN_PASSWORD` you set

### Initial Configuration

1. **Company Setup**
   - Settings > Company
   - Add your company details

2. **Email Configuration**
   - Settings > Email Domain
   - Configure SMTP

3. **Users**
   - Settings > User
   - Create additional users

## Maintenance

### Backups

Automated backups can be set up in Hanzo:

```bash
# Cron job example
0 2 * * * docker exec $(docker ps -q -f name=backend) bench --site erp.hanzo.ai backup --with-files
```

### Updates

To update ERPNext:

1. Change the image version in compose file
2. Redeploy in Hanzo
3. The system automatically handles migrations

### Troubleshooting

If deployment fails:

1. Check configurator logs first - it handles all setup
2. Verify environment variables are set
3. Ensure `hanzo-network` exists
4. Check database connectivity

Common issues:
- **Configurator fails**: Usually wrong DB_PASSWORD
- **Site not accessible**: Check Traefik labels and domain
- **Services not starting**: Check depends_on conditions

## Advanced Configuration

### Custom Apps

To add custom Frappe apps:

1. Build custom image with your apps
2. Update image in compose file
3. Redeploy

### Performance Tuning

Adjust in compose file:
- Database: `innodb_buffer_pool_size`
- Redis: `maxmemory` settings
- Worker counts and queues

### SSL Certificates

Handled automatically by Hanzo's Traefik setup using Let's Encrypt.

## Support

- ERPNext Forum: https://discuss.erpnext.com
- Frappe GitHub: https://github.com/frappe/erpnext
- Hanzo Support: Contact your Hanzo administrator
