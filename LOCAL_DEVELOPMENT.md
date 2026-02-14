# Local Development Setup

This document describes how to run ERPNext locally using MariaDB for development.

## Prerequisites

1. **Install uv** (Python package manager):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

2. **Install system dependencies** (macOS):
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required packages
brew install mariadb redis node yarn

# Start services
brew services start mariadb
brew services start redis

# Secure MariaDB installation (optional but recommended)
mysql_secure_installation
```

## Quick Start

```bash
# 1. Complete setup (one-time)
make setup

# 2. Start the development server
make start
```

This will:
- Install Python 3.11 using uv
- Create a virtual environment
- Install frappe-bench
- Create a new bench with MariaDB
- Install ERPNext
- Create a site
- Open ERPNext in your browser

## Default Credentials

- **URL**: http://localhost:8000
- **Username**: Administrator
- **Password**: admin

## Common Commands

```bash
# Start development server
make start

# Stop all processes
make stop

# Open Python console
make console

# Run database migrations
make migrate

# Build frontend assets
make build

# Watch and rebuild assets on change
make watch

# Clear cache
make clear-cache

# Create backup
make backup

# Run tests
make test

# Update to latest
make update

# Check system health
make doctor

# Show all available commands
make help
```

## Project Structure

After setup, the project structure will be:
```
/Users/z/work/hanzo/
├── erp/                 # This ERPNext app
│   ├── erpnext/        # App source code
│   └── Makefile        # Local development commands
└── erpnext-dev/        # Bench directory (created by make setup)
    ├── apps/           # Installed apps
    │   └── erpnext/    # Symlink to ../erp
    ├── sites/          # Sites data
    └── logs/           # Log files
```

## Services

The following services need to be running:
- **MariaDB**: Database server
- **Redis**: Cache and queue management
- **Node.js**: Frontend build tools

## Troubleshooting

1. **Check system health**:
```bash
make doctor
```

2. **Reset site** (deletes all data):
```bash
make reset
```

3. **View logs**:
```bash
make logs
```

4. **Stop services**:
```bash
make stop-services
```

5. **Clean and reinstall**:
```bash
make uninstall
make setup
```

## Development Workflow

1. Make changes to code in `/Users/z/work/hanzo/erp/`
2. Assets are automatically rebuilt if you run `make watch`
3. For Python changes, the server auto-reloads
4. Clear cache if needed: `make clear-cache`

## Database Access

To access MariaDB directly:
```bash
mysql -u root
```

Then:
```sql
USE _your_site_db_name_;
SHOW TABLES;
```

## Notes

- This setup uses MariaDB which is the recommended database for ERPNext
- For production, use the Docker setup
- The bench is created as a sibling directory to keep the app code clean
- All Python dependencies are managed by uv for fast, reliable installs
- Services (MariaDB and Redis) need to be running for ERPNext to work
