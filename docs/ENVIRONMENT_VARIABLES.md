# Environment Variables for Hanzo ERPNext

Only **TWO** environment variables are required. Set these in the Hanzo/Dokploy UI when creating your application.

## Required Variables

```bash
DB_PASSWORD=<secure_database_password>
ADMIN_PASSWORD=<administrator_password>
```

## How to Generate

### DB_PASSWORD
Generate a secure random password:
```bash
openssl rand -base64 32
```

### ADMIN_PASSWORD
Choose a strong password that you'll remember. This is used to login to ERPNext as Administrator.

## That's It!

No other configuration needed. The Docker Compose file handles everything else:

- ✅ Database name (erpnext_prod or erpnext_dev)
- ✅ Redis configuration
- ✅ Site domain (erp.hanzo.ai or erp-dev.hanzo.ai)
- ✅ All service connections
- ✅ Site creation and initialization
- ✅ Scheduler setup
- ✅ Production/development mode

## After Deployment

Login at your domain with:
- **Username**: Administrator
- **Password**: The ADMIN_PASSWORD you set

## Notes

- Both passwords should be strong and unique
- DB_PASSWORD is used internally by services
- ADMIN_PASSWORD is your login to ERPNext
- These are the ONLY variables you need to set
- Everything else is automated in the compose file
