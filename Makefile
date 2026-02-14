# ERPNext Local Development Makefile
# Uses uv for Python management and MariaDB for database

# Variables
PYTHON_VERSION := 3.11
BENCH_NAME := erpnext-dev
SITE_NAME := erp.local
ADMIN_PASSWORD := admin
BENCH_PATH := ../$(BENCH_NAME)
CURRENT_DIR := $(shell pwd)
UV := uv
BENCH := $(CURRENT_DIR)/.venv/bin/bench
ACTIVATE := source $(CURRENT_DIR)/.venv/bin/activate
DB_USER := root
DB_PASSWORD := 

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)ERPNext Local Development Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick start:$(NC) make setup && make start"

.PHONY: check-uv
check-uv: ## Check if uv is installed
	@command -v $(UV) >/dev/null 2>&1 || { \
		echo "$(RED)Error: uv is not installed$(NC)"; \
		echo "Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		exit 1; \
	}
	@echo "$(GREEN)✓ uv is installed$(NC)"

.PHONY: check-deps
check-deps: check-uv ## Check system dependencies
	@echo "$(BLUE)Checking system dependencies...$(NC)"
	@command -v mysql >/dev/null 2>&1 || { \
		echo "$(RED)Error: MySQL/MariaDB is not installed$(NC)"; \
		echo "Install it with:"; \
		echo "  brew install mariadb"; \
		echo "  brew services start mariadb"; \
		echo "  mysql_secure_installation"; \
		exit 1; \
	}
	@command -v redis-server >/dev/null 2>&1 || { \
		echo "$(RED)Error: Redis is not installed$(NC)"; \
		echo "Install it with: brew install redis"; \
		exit 1; \
	}
	@command -v node >/dev/null 2>&1 || { \
		echo "$(RED)Error: Node.js is not installed$(NC)"; \
		echo "Install it with: brew install node"; \
		exit 1; \
	}
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

.PHONY: install-python
install-python: check-uv ## Install Python using uv
	@echo "$(BLUE)Installing Python $(PYTHON_VERSION)...$(NC)"
	$(UV) python install $(PYTHON_VERSION)
	@echo "$(GREEN)✓ Python $(PYTHON_VERSION) installed$(NC)"

.PHONY: setup-venv
setup-venv: install-python ## Create virtual environment
	@echo "$(BLUE)Creating virtual environment...$(NC)"
	$(UV) venv .venv --python $(PYTHON_VERSION)
	@echo "$(GREEN)✓ Virtual environment created$(NC)"

.PHONY: install-bench
install-bench: setup-venv ## Install frappe-bench
	@echo "$(BLUE)Installing frappe-bench...$(NC)"
	$(UV) pip install --upgrade frappe-bench
	@echo "$(GREEN)✓ frappe-bench installed$(NC)"

.PHONY: start-services
start-services: ## Start MariaDB and Redis services
	@echo "$(BLUE)Starting services...$(NC)"
	@if ! pgrep -x "mysqld" > /dev/null; then \
		brew services start mariadb; \
		echo "$(GREEN)✓ MariaDB started$(NC)"; \
	else \
		echo "$(YELLOW)MariaDB already running$(NC)"; \
	fi
	@if ! pgrep -x "redis-server" > /dev/null; then \
		brew services start redis; \
		echo "$(GREEN)✓ Redis started$(NC)"; \
	else \
		echo "$(YELLOW)Redis already running$(NC)"; \
	fi

.PHONY: init-bench
init-bench: install-bench start-services ## Initialize new bench
	@if [ -d "$(BENCH_PATH)" ]; then \
		echo "$(YELLOW)Bench already exists at $(BENCH_PATH)$(NC)"; \
	else \
		echo "$(BLUE)Creating new bench...$(NC)"; \
		$(ACTIVATE) && cd .. && bench init $(BENCH_NAME) --frappe-branch version-15; \
		echo "$(GREEN)✓ Bench created$(NC)"; \
	fi

.PHONY: install-app
install-app: init-bench ## Install ERPNext app into bench
	@echo "$(BLUE)Installing ERPNext app...$(NC)"
	@if [ -d "$(BENCH_PATH)/apps/erpnext" ]; then \
		echo "$(YELLOW)ERPNext app already installed, updating...$(NC)"; \
		rm -rf $(BENCH_PATH)/apps/erpnext; \
	fi
	ln -sf $(CURRENT_DIR) $(BENCH_PATH)/apps/erpnext
	$(ACTIVATE) && cd $(BENCH_PATH) && bench setup requirements --dev
	$(ACTIVATE) && cd $(BENCH_PATH) && bench build --app erpnext
	@echo "$(GREEN)✓ ERPNext app installed$(NC)"

.PHONY: create-site
create-site: install-app ## Create new site with ERPNext
	@echo "$(BLUE)Creating site $(SITE_NAME)...$(NC)"
	@cd $(BENCH_PATH) && if $(ACTIVATE) && bench --site $(SITE_NAME) exists 2>/dev/null; then \
		echo "$(YELLOW)Site already exists$(NC)"; \
	else \
		$(ACTIVATE) && bench new-site $(SITE_NAME) --mariadb-root-password "$(DB_PASSWORD)" --admin-password $(ADMIN_PASSWORD) --install-app erpnext; \
		$(ACTIVATE) && bench --site $(SITE_NAME) use; \
		echo "$(GREEN)✓ Site created$(NC)"; \
		echo "$(GREEN)✓ Admin credentials - User: Administrator, Password: $(ADMIN_PASSWORD)$(NC)"; \
	fi

.PHONY: setup
setup: check-deps create-site ## Complete setup process
	@echo ""
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Run $(GREEN)make start$(NC) to start the development server"
	@echo "  2. Access ERPNext at $(GREEN)http://localhost:8000$(NC)"
	@echo "  3. Login with User: $(GREEN)Administrator$(NC), Password: $(GREEN)$(ADMIN_PASSWORD)$(NC)"
	@echo ""

.PHONY: start
start: ## Start development server and open browser
	@echo "$(BLUE)Starting ERPNext development server...$(NC)"
	@echo "$(YELLOW)Server will start at http://localhost:8000$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@sleep 2
	@open http://localhost:8000 2>/dev/null || xdg-open http://localhost:8000 2>/dev/null || echo "$(YELLOW)Please open http://localhost:8000 in your browser$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench start

.PHONY: stop
stop: ## Stop all bench processes
	@echo "$(BLUE)Stopping bench processes...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench stop || true
	@echo "$(GREEN)✓ Stopped$(NC)"

.PHONY: console
console: ## Open Python console
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) console

.PHONY: migrate
migrate: ## Run database migrations
	@echo "$(BLUE)Running migrations...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) migrate
	@echo "$(GREEN)✓ Migrations complete$(NC)"

.PHONY: build
build: ## Build frontend assets
	@echo "$(BLUE)Building assets...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench build --app erpnext
	@echo "$(GREEN)✓ Build complete$(NC)"

.PHONY: watch
watch: ## Watch and rebuild assets on change
	$(ACTIVATE) && cd $(BENCH_PATH) && bench watch

.PHONY: test
test: ## Run tests
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) run-tests --app erpnext

.PHONY: shell
shell: ## Open shell in bench directory
	cd $(BENCH_PATH) && $$SHELL

.PHONY: logs
logs: ## Show bench logs
	cd $(BENCH_PATH) && tail -f logs/*.log

.PHONY: clear-cache
clear-cache: ## Clear all caches
	@echo "$(BLUE)Clearing cache...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) clear-cache
	@echo "$(GREEN)✓ Cache cleared$(NC)"

.PHONY: backup
backup: ## Create backup
	@echo "$(BLUE)Creating backup...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) backup
	@echo "$(GREEN)✓ Backup created$(NC)"

.PHONY: restore
restore: ## Restore from latest backup
	@echo "$(BLUE)Restoring from latest backup...$(NC)"
	$(ACTIVATE) && cd $(BENCH_PATH) && bench --site $(SITE_NAME) restore
	@echo "$(GREEN)✓ Restored$(NC)"

.PHONY: reset
reset: ## Reset site (delete and recreate)
	@echo "$(RED)This will delete all data!$(NC)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(ACTIVATE) && cd $(BENCH_PATH) && bench drop-site $(SITE_NAME) --force; \
		$(MAKE) create-site; \
	fi

.PHONY: update
update: ## Update ERPNext to latest
	@echo "$(BLUE)Updating ERPNext...$(NC)"
	cd $(CURRENT_DIR) && git pull
	$(ACTIVATE) && cd $(BENCH_PATH) && bench setup requirements --dev
	$(ACTIVATE) && cd $(BENCH_PATH) && bench build --app erpnext
	$(MAKE) migrate
	@echo "$(GREEN)✓ Update complete$(NC)"

.PHONY: doctor
doctor: ## Run diagnostic checks
	@echo "$(BLUE)Running diagnostics...$(NC)"
	@echo ""
	@echo "Checking uv..."
	@$(MAKE) check-uv
	@echo ""
	@echo "Checking Python..."
	@$(ACTIVATE) && python --version || echo "$(RED)✗ Python not found$(NC)"
	@echo ""
	@echo "Checking bench..."
	@cd $(BENCH_PATH) 2>/dev/null && $(ACTIVATE) && bench version || echo "$(RED)✗ Bench not found$(NC)"
	@echo ""
	@echo "Checking site..."
	@cd $(BENCH_PATH) 2>/dev/null && $(ACTIVATE) && bench --site $(SITE_NAME) exists && echo "$(GREEN)✓ Site exists$(NC)" || echo "$(RED)✗ Site not found$(NC)"
	@echo ""
	@echo "Checking MariaDB..."
	@mysql -u$(DB_USER) -p$(DB_PASSWORD) -e "SELECT VERSION();" 2>/dev/null && echo "$(GREEN)✓ MariaDB running$(NC)" || echo "$(RED)✗ MariaDB not accessible$(NC)"
	@echo ""
	@echo "Checking Redis..."
	@redis-cli ping 2>/dev/null && echo "$(GREEN)✓ Redis running$(NC)" || echo "$(RED)✗ Redis not running$(NC)"

.PHONY: stop-services
stop-services: ## Stop MariaDB and Redis services
	@echo "$(BLUE)Stopping services...$(NC)"
	brew services stop mariadb || true
	brew services stop redis || true
	@echo "$(GREEN)✓ Services stopped$(NC)"

.PHONY: clean
clean: ## Clean up generated files
	@echo "$(BLUE)Cleaning up...$(NC)"
	rm -rf .venv
	cd $(BENCH_PATH) 2>/dev/null && $(ACTIVATE) && bench clear-cache || true
	@echo "$(GREEN)✓ Cleaned$(NC)"

.PHONY: uninstall
uninstall: clean stop-services ## Completely remove bench and all data
	@echo "$(RED)This will delete the entire bench and all data!$(NC)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(BENCH_PATH); \
		rm -rf .venv; \
		echo "$(GREEN)✓ Uninstalled$(NC)"; \
	fi

# Default target
.DEFAULT_GOAL := help
