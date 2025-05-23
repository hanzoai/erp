# ERPNext Routing Architecture

## Overview

All traffic routes through a **single domain** (e.g., `erp.hanzo.ai`). No additional hostnames or subdomains are required.

## Traffic Flow

```
Internet
    ↓
Traefik (SSL termination)
    ↓
Frontend Service (nginx on port 8080)
    ├── /socket.io/* → WebSocket Service (port 9000)
    ├── /assets/*    → Static Files (served directly)
    └── /*           → Backend Service (port 8000)
```

## Service Communication

All services communicate internally via the `hanzo-network`:

- **Frontend** → **Backend**: `backend:8000`
- **Frontend** → **WebSocket**: `websocket:9000`
- **Backend** → **Database**: `db:3306`
- **Backend** → **Redis Cache**: `redis-cache:6379`
- **Backend** → **Redis Queue**: `redis-queue:6379`
- **Workers** → **Redis Queue**: `redis-queue:6379`

## Exposed Services

Only the **Frontend** service is exposed to the internet via Traefik. All other services are internal only.

## Key Features

### WebSocket Support
- Proper upgrade headers configured
- CSP allows `wss://` connections
- nginx handles WebSocket proxy

### Security
- All internal services isolated
- CSP headers prevent XSS
- HTTPS enforced via redirect
- X-Frame-Options prevents clickjacking

### Headers
- `X-Forwarded-Proto`: Ensures backend knows it's HTTPS
- `X-Forwarded-Host`: Preserves original host
- `X-Frappe-Site-Name`: Routes to correct ERPNext site

## No Additional Configuration Needed

- ✅ Single domain handles everything
- ✅ WebSocket support built-in
- ✅ All routing handled by nginx
- ✅ Traefik labels properly configured
- ✅ CSP allows all necessary connections

## Troubleshooting

If WebSocket connections fail:
1. Check browser console for CSP violations
2. Ensure `wss://your-domain` is in CSP connect-src
3. Verify nginx socket.io location block
4. Check that websocket service is running

If backend connections fail:
1. Verify all services are on same network
2. Check service names match in environment variables
3. Ensure configurator completed successfully
4. Review nginx proxy_pass configuration
