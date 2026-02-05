# Dyllis Makefile - manage workspace services with PM2 (Rocky Linux / RHEL)
# PM2 processes run as dedicated 'pm2' user for security isolation
ROOT_DIR:=$(shell pwd)
CPANEL_DIR=$(ROOT_DIR)/cpanel
TIMESTAMP:=$(shell date +%s)

# PM2 configuration - runs as restricted 'pm2' user
PM2_USER?=pm2
PM2_HOME?=/home/pm2/.pm2
PM2_MAX_MEM?=768M

# PM2 command helper - use $(call pm2_run,<pm2-args>)
# Example: $(call pm2_run,list)
#          $(call pm2_run,start app.js --name myapp)
define pm2_run
su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 $(1)'
endef

# PM2 with environment variables - use $(call pm2_env_run,<env-vars>,<pm2-args>)
# Example: $(call pm2_env_run,NODE_ENV=production PORT=3000,start app.js)
define pm2_env_run
su -l $(PM2_USER) -c '$(1) PM2_HOME=$(PM2_HOME) pm2 $(2)'
endef

.DEFAULT_GOAL := help
.PHONY: help install all all-up install-deps palcon-start palcon-pm2-start palcon-pm2-stop discord-pm2-start discord-pm2-stop app-start app-pm2-stop legacy-start legacy-stop admin build build-modern build-legacy build-server build-and-start ensure-pm2-user ditto-debug studio-start studio-stop build-studio build-all wiki-start wiki-stop wiki-logs wiki-status serven-logs nginx-test nginx-reload nginx-logs routing-show

help:
	@echo "Dyllis Makefile"
	@echo ""
	@echo "First time setup:"
	@echo "  make install        Run initial setup (license required)"
	@echo ""
	@echo "Build & Deploy:"
	@echo "  make all            Build and deploy ALL services (app + studio + discord)"
	@echo "  make build-studio   Build Studio app"
	@echo "  make build-serven   Build App-Serven (kidszzanggame.com)"
	@echo "  make build          Build main app"
	@echo "  make build-server   Build Ditto Server"
	@echo "  make build-all      Build everything"
	@echo ""
	@echo "Service Management (runs as '$(PM2_USER)' user):"
	@echo "  make studio-start   Start Studio Server"
	@echo "  make studio-stop    Stop Studio Server"
	@echo "  make serven-start   Start App-Serven (Ditto on 7602)"
	@echo "  make serven-stop    Stop App-Serven"
	@echo "  make app-start      Start Ditto Server"
	@echo "  make app-pm2-stop   Stop Ditto Server"
	@echo "  make discord-pm2-start   Start Discord Bot"
	@echo "  make discord-pm2-stop    Stop Discord Bot"
	@echo "  make wiki-start     Start Wiki.js (docs.zuzunza.com)"
	@echo "  make wiki-stop      Stop Wiki.js"
	@echo "  make wiki-status    Show Wiki.js status"
	@echo "  make wiki-logs      Show Wiki.js logs"
	@echo "  make serven-logs   Show App-Serven logs (proxy-swf 등)"
	@echo ""
	@echo "Nginx Management:"
	@echo "  make nginx-test     Test Nginx configuration"
	@echo "  make nginx-reload   Reload Nginx"
	@echo "  make nginx-logs     Show Nginx error logs"
	@echo "  make routing-show   Show routing rules"
	@echo ""
	@echo "Direct PM2 access: su -l $(PM2_USER) -c 'pm2 list'"

# =============================================================================
# INSTALLATION
# =============================================================================

# First-time installation with license verification
install:
	@echo "Starting Dyllis installation..."
	@bash $(ROOT_DIR)/scripts/install.sh

# Install Node.js dependencies only
install-deps:
	@echo "Installing Node.js dependencies..."
	pnpm install -w

# Verify pm2 user exists
ensure-pm2-user:
	@if ! id "$(PM2_USER)" &>/dev/null; then \
		echo "Error: pm2 user does not exist."; \
		echo "Run 'make install' first."; \
		exit 1; \
	fi
	@mkdir -p $(PM2_HOME) && chown $(PM2_USER):$(PM2_USER) $(PM2_HOME)

build-server:
	@echo "Building Dyllis Ditto Server..."
	cd $(ROOT_DIR)/dyllis-ditto/server && pnpm install && pnpm build

build: build-modern

build-modern:
	@echo "Building Next.js app (BuildAdapter: modern, Standalone, clean)..."
	cd $(ROOT_DIR)/app && pnpm install && BUILD_MODE=modern BUILD_CACHE_ENABLED=false pnpm run build:clean
	@echo "Deploying standalone build to dyllis-ditto/compile/$(TIMESTAMP)..."
	@command -v rsync >/dev/null 2>&1 || { echo "rsync is required. Install it and retry."; exit 1; }; \
	BUILD_DIR=$(ROOT_DIR)/dyllis-ditto/compile/$(TIMESTAMP); \
	SRC_APP=$(ROOT_DIR)/app; \
	SRC_STANDALONE=$$SRC_APP/.next/standalone; \
	mkdir -p $$BUILD_DIR; \
	if [ ! -d "$$SRC_STANDALONE" ]; then echo "ERROR: Standalone build not found at $$SRC_STANDALONE"; exit 1; fi; \
	echo "Copying standalone output (Dockerfile runner stage equivalent)..."; \
	rsync -a --delete $$SRC_STANDALONE/ $$BUILD_DIR/; \
	echo "Copying static assets..."; \
	if [ -d "$$SRC_APP/.next/static" ]; then \
	  if [ -d "$$BUILD_DIR/app" ]; then \
	    mkdir -p $$BUILD_DIR/app/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/app/.next/static/; \
	  else \
	    mkdir -p $$BUILD_DIR/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/.next/static/; \
	  fi; \
	fi; \
	echo "Copying public assets..."; \
	if [ -d "$$SRC_APP/public" ]; then \
	  mkdir -p $$BUILD_DIR/public; \
	  rsync -a --delete $$SRC_APP/public/ $$BUILD_DIR/public/; \
	  echo "Syncing public assets to /var/www/html..."; \
	  rsync -avzh $$SRC_APP/public/ /var/www/html/; \
	fi; \
	echo "Linking app node_modules (full) ..."; \
	if [ -d "$$BUILD_DIR/node_modules" ]; then \
	  mv $$BUILD_DIR/node_modules $$BUILD_DIR/node_modules_standalone; \
	fi; \
	ln -sfn $$SRC_APP/node_modules $$BUILD_DIR/node_modules; \
	if [ -d "$$BUILD_DIR/app" ]; then \
	  rm -rf $$BUILD_DIR/app/node_modules; \
	  ln -sfn ../node_modules $$BUILD_DIR/app/node_modules; \
	fi; \
	echo "Updating ACTIVE_BUILD in ditto.conf..."; \
	sed -i 's/^ACTIVE_BUILD=.*/ACTIVE_BUILD=$(TIMESTAMP)/' $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	echo "Pruning old builds (keep latest 3)..."; \
	idx=0; \
	for b in $$(ls -1t $(ROOT_DIR)/dyllis-ditto/compile 2>/dev/null); do \
	  idx=$$((idx+1)); \
	  if [ $$idx -gt 3 ]; then \
	    echo "Removing old build: $$b"; \
	    rm -rf $(ROOT_DIR)/dyllis-ditto/compile/$$b; \
	  fi; \
	done; \
	echo "✅ Build $(TIMESTAMP) deployed successfully."

build-legacy:
	@echo "Building Next.js app (BuildAdapter: legacy, Standalone, clean)..."
	cd $(ROOT_DIR)/app && pnpm install && BUILD_MODE=legacy BUILD_CACHE_ENABLED=false pnpm run build:clean
	@echo "Deploying standalone build to dyllis-ditto/compile/$(TIMESTAMP)..."
	@command -v rsync >/dev/null 2>&1 || { echo "rsync is required. Install it and retry."; exit 1; }; \
	BUILD_DIR=$(ROOT_DIR)/dyllis-ditto/compile/$(TIMESTAMP); \
	SRC_APP=$(ROOT_DIR)/app; \
	SRC_STANDALONE=$$SRC_APP/.next/standalone; \
	mkdir -p $$BUILD_DIR; \
	if [ ! -d "$$SRC_STANDALONE" ]; then echo "ERROR: Standalone build not found at $$SRC_STANDALONE"; exit 1; fi; \
	echo "Copying standalone output (Dockerfile runner stage equivalent)..."; \
	rsync -a --delete $$SRC_STANDALONE/ $$BUILD_DIR/; \
	echo "Copying static assets..."; \
	if [ -d "$$SRC_APP/.next/static" ]; then \
	  mkdir -p $$BUILD_DIR/.next/static; \
	  rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/.next/static/; \
	fi; \
	echo "Copying public assets..."; \
	if [ -d "$$SRC_APP/public" ]; then \
	  mkdir -p $$BUILD_DIR/public; \
	  rsync -a --delete $$SRC_APP/public/ $$BUILD_DIR/public/; \
	  echo "Syncing public assets to /var/www/html..."; \
	  mkdir -p /var/www/html; \
	  rsync -a --delete $$SRC_APP/public/ /var/www/html/; \
	fi; \
	echo "Using standalone node_modules (runtime required)..."; \
	if [ -d "$$BUILD_DIR/app" ] && [ -d "$$BUILD_DIR/node_modules" ]; then \
	  rm -rf $$BUILD_DIR/app/node_modules; \
	  ln -sfn ../node_modules $$BUILD_DIR/app/node_modules; \
	fi; \
	echo "Updating ACTIVE_BUILD in ditto.conf..."; \
	sed -i 's/^ACTIVE_BUILD=.*/ACTIVE_BUILD=$(TIMESTAMP)/' $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	echo "Pruning old builds (keep latest 3)..."; \
	idx=0; \
	for b in $$(ls -1t $(ROOT_DIR)/dyllis-ditto/compile 2>/dev/null); do \
	  idx=$$((idx+1)); \
	  if [ $$idx -gt 3 ]; then \
	    echo "Removing old build: $$b"; \
	    rm -rf $(ROOT_DIR)/dyllis-ditto/compile/$$b; \
	  fi; \
	done; \
	echo "✅ Build $(TIMESTAMP) deployed successfully."

build-and-start: build build-server app-start
	@echo ""
	@echo "================================"
	@echo "✅ Build completed and Ditto Server started!"
	@echo "================================"
	@$(call pm2_run,ls)

all: build-all app-start studio-start serven-start discord-pm2-start
	@echo ""
	@echo "================================"
	@echo "✅ All services built and started!"
	@echo "  - Main App (dyllis-ditto)"
	@echo "  - Studio (dyllis-studio)"
	@echo "  - App-Serven (kidszzanggame.com)"
	@echo "  - Discord Bot (dyllis-discord-bot)"
	@echo "================================"
	@$(call pm2_run,ls)

install-systemctl-alpine:
	@echo "Installing systemctl-alpine (requires root)"
	bash $(CPANEL_DIR)/install_systemctl_alpine.sh

install-all:
	@echo "Installing all node dependencies (pnpm workspaces)"
	pnpm install -w

build-all: build build-studio build-serven build-server
	@echo "Building all workspace packages"

palcon-start:
	@echo "Start palcon server directly (dev mode)"
	cd $(ROOT_DIR)/palcon && pnpm install && pnpm start

palcon-pm2-start: ensure-pm2-user
	@echo "Start palcon via PM2 (as $(PM2_USER) user)"
	@cd $(ROOT_DIR)/palcon && pnpm install
	@$(call pm2_env_run,cd $(ROOT_DIR)/palcon &&,start ecosystem.config.js)
	@$(call pm2_run,save)

palcon-pm2-stop: ensure-pm2-user
	@echo "Stop palcon PM2 process"
	@$(call pm2_run,stop dyllis-palcon) || true
	@$(call pm2_run,delete dyllis-palcon) || true
	@$(call pm2_run,save) || true

discord-pm2-start: ensure-pm2-user
	@echo "Start Discord Bot via PM2 (as $(PM2_USER) user)"
	@cd $(ROOT_DIR)/app-discord && pnpm install
	@$(call pm2_env_run,cd $(ROOT_DIR)/app-discord &&,start ecosystem.config.js)
	@$(call pm2_run,save)

discord-pm2-stop: ensure-pm2-user
	@echo "Stop Discord Bot PM2 process"
	@$(call pm2_run,stop dyllis-discord-bot) || true
	@$(call pm2_run,delete dyllis-discord-bot) || true
	@$(call pm2_run,save) || true

app-start: ensure-pm2-user
	@echo "Starting Dyllis Ditto Server via PM2 (as $(PM2_USER) user)..."
	@ACTIVE_BUILD=$$(grep "^ACTIVE_BUILD=" $(ROOT_DIR)/dyllis-ditto/ditto.conf | cut -d= -f2); \
	if [ -z "$$ACTIVE_BUILD" ]; then echo "Error: ACTIVE_BUILD not found in ditto.conf"; exit 1; fi; \
	if su -l $(PM2_USER) -c "PM2_HOME=$(PM2_HOME) pm2 describe dyllis-ditto" >/dev/null 2>&1; then \
	  su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) ACTIVE_BUILD=$$ACTIVE_BUILD PM2_HOME=$(PM2_HOME) pm2 restart dyllis-ditto --update-env --max-memory-restart $(PM2_MAX_MEM)"; \
	else \
	  su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) ACTIVE_BUILD=$$ACTIVE_BUILD PM2_HOME=$(PM2_HOME) pm2 start $(ROOT_DIR)/dyllis-ditto/server/dist/index.js --name dyllis-ditto --max-memory-restart $(PM2_MAX_MEM)"; \
	fi
	@$(call pm2_run,save)

app-pm2-stop: ensure-pm2-user
	@echo "Stop Ditto Server PM2 process"
	@$(call pm2_run,stop dyllis-ditto) || true
	@$(call pm2_run,delete dyllis-ditto) || true

legacy-start: ensure-pm2-user
	@echo "Start Legacy Wrapping Server (SSSV) on Port 6001 (as $(PM2_USER) user)"
	@$(call pm2_env_run,cd $(ROOT_DIR)/legacy-server &&,start index.js --name dyllis-legacy-server) || \
		$(call pm2_run,restart dyllis-legacy-server)

legacy-stop: ensure-pm2-user
	@echo "Stop Legacy Wrapping Server PM2 process"
	@$(call pm2_run,stop dyllis-legacy-server) || true
	@$(call pm2_run,delete dyllis-legacy-server) || true

legacy-install:
	@echo "Install Legacy Server dependencies"
	cd $(ROOT_DIR)/legacy-server && pnpm install

admin:
	@bash $(CPANEL_DIR)/admin.sh

ditto-debug:
	@bash $(ROOT_DIR)/scripts/ditto-debug.sh

build-studio:
	@echo "Building Studio app (BuildAdapter: modern, Standalone, clean)..."
	cd $(ROOT_DIR)/app-studio && pnpm install && BUILD_MODE=studio BUILD_CACHE_ENABLED=false pnpm run build:clean
	@echo "Deploying Studio standalone build to dyllis-ditto/studio-compile/$(TIMESTAMP)..."
	@command -v rsync >/dev/null 2>&1 || { echo "rsync is required. Install it and retry."; exit 1; }; \
	BUILD_DIR=$(ROOT_DIR)/dyllis-ditto/studio-compile/$(TIMESTAMP); \
	SRC_APP=$(ROOT_DIR)/app-studio; \
	SRC_STANDALONE=$$SRC_APP/.next/standalone; \
	mkdir -p $$BUILD_DIR; \
	if [ ! -d "$$SRC_STANDALONE" ]; then echo "ERROR: Standalone build not found at $$SRC_STANDALONE"; exit 1; fi; \
	echo "Copying standalone output..."; \
	rsync -a --delete $$SRC_STANDALONE/ $$BUILD_DIR/; \
	echo "Copying static assets..."; \
	if [ -d "$$SRC_APP/.next/static" ]; then \
	  if [ -d "$$BUILD_DIR/app-studio" ]; then \
	    mkdir -p $$BUILD_DIR/app-studio/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/app-studio/.next/static/; \
	  else \
	    mkdir -p $$BUILD_DIR/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/.next/static/; \
	  fi; \
	fi; \
	echo "Copying public assets..."; \
	if [ -d "$$SRC_APP/public" ]; then \
	  mkdir -p $$BUILD_DIR/public; \
	  rsync -a --delete $$SRC_APP/public/ $$BUILD_DIR/public/; \
	fi; \
	echo "Linking node_modules (full) ..."; \
	ln -sfn $$SRC_APP/node_modules $$BUILD_DIR/node_modules; \
	echo "Updating ACTIVE_STUDIO_BUILD in ditto.conf..."; \
	if grep -q "ACTIVE_STUDIO_BUILD=" $(ROOT_DIR)/dyllis-ditto/ditto.conf; then \
	  sed -i 's/^ACTIVE_STUDIO_BUILD=.*/ACTIVE_STUDIO_BUILD=$(TIMESTAMP)/' $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	else \
	  echo "ACTIVE_STUDIO_BUILD=$(TIMESTAMP)" >> $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	fi; \
	echo "Pruning old studio builds (keep latest 3)..."; \
	idx=0; \
	for b in $$(ls -1t $(ROOT_DIR)/dyllis-ditto/studio-compile 2>/dev/null); do \
	  idx=$$((idx+1)); \
	  if [ $$idx -gt 3 ]; then \
	    echo "Removing old build: $$b"; \
	    rm -rf $(ROOT_DIR)/dyllis-ditto/studio-compile/$$b; \
	  fi; \
	done; \
	echo "✅ Studio Build $(TIMESTAMP) deployed successfully."

studio-start: ensure-pm2-user
	@echo "Starting Dyllis Studio Server via PM2 (as $(PM2_USER) user)..."
	@ACTIVE_STUDIO_BUILD=$$(grep "ACTIVE_STUDIO_BUILD" $(ROOT_DIR)/dyllis-ditto/ditto.conf | cut -d= -f2); \
	if [ -z "$$ACTIVE_STUDIO_BUILD" ]; then echo "Error: ACTIVE_STUDIO_BUILD not found in ditto.conf"; exit 1; fi; \
	su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) BUILD_DIR_NAME=studio-compile ACTIVE_BUILD=$$ACTIVE_STUDIO_BUILD SERVER_PORT=7601 PM2_HOME=$(PM2_HOME) pm2 restart dyllis-studio --update-env --max-memory-restart $(PM2_MAX_MEM)" 2>/dev/null || \
	su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) BUILD_DIR_NAME=studio-compile ACTIVE_BUILD=$$ACTIVE_STUDIO_BUILD SERVER_PORT=7601 PM2_HOME=$(PM2_HOME) pm2 start $(ROOT_DIR)/dyllis-ditto/server/dist/index.js --name dyllis-studio --max-memory-restart $(PM2_MAX_MEM)"
	@$(call pm2_run,save)

studio-stop: ensure-pm2-user
	@echo "Stop Studio Server PM2 process"
	@$(call pm2_run,stop dyllis-studio) || true
	@$(call pm2_run,delete dyllis-studio) || true

build-serven:
	@echo "Building App-Serven (kidszzanggame.com) with Ditto integration..."
	cd $(ROOT_DIR)/app-serven && pnpm install && pnpm run build:ditto
	@echo "Deploying App-Serven build to dyllis-ditto/serven-compile/$(TIMESTAMP)..."
	@command -v rsync >/dev/null 2>&1 || { echo "rsync is required. Install it and retry."; exit 1; }; \
	BUILD_DIR=$(ROOT_DIR)/dyllis-ditto/serven-compile/$(TIMESTAMP); \
	SRC_APP=$(ROOT_DIR)/app-serven; \
	SRC_STANDALONE=$$SRC_APP/.next/standalone; \
	mkdir -p $$BUILD_DIR; \
	if [ -d "$$SRC_STANDALONE" ]; then \
	  rsync -a --delete $$SRC_STANDALONE/ $$BUILD_DIR/; \
	else \
	  rsync -a --delete $$SRC_APP/.next/ $$BUILD_DIR/.next/; \
	fi; \
	if [ -d "$$SRC_APP/.next/static" ]; then \
	  if [ -d "$$BUILD_DIR/app" ]; then \
	    mkdir -p $$BUILD_DIR/app/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/app/.next/static/; \
	  else \
	    mkdir -p $$BUILD_DIR/.next/static; \
	    rsync -a --delete $$SRC_APP/.next/static/ $$BUILD_DIR/.next/static/; \
	  fi; \
	fi; \
	if [ -f "$$SRC_APP/ditto-build.json" ]; then \
	  cp $$SRC_APP/ditto-build.json $$BUILD_DIR/ditto-build.json; \
	elif [ -f "$$SRC_APP/.next/ditto-build.json" ]; then \
	  cp $$SRC_APP/.next/ditto-build.json $$BUILD_DIR/ditto-build.json; \
	fi; \
	if [ -d "$$SRC_APP/public" ]; then \
	  mkdir -p $$BUILD_DIR/public; \
	  rsync -a --delete $$SRC_APP/public/ $$BUILD_DIR/public/; \
	fi; \
	ln -sfn $$SRC_APP/node_modules $$BUILD_DIR/node_modules; \
	if [ -d "$$BUILD_DIR/app" ]; then \
	  rm -rf $$BUILD_DIR/app/node_modules; \
	  ln -sfn ../node_modules $$BUILD_DIR/app/node_modules; \
	fi; \
	if grep -q "ACTIVE_SERVEN_BUILD=" $(ROOT_DIR)/dyllis-ditto/ditto.conf; then \
	  sed -i 's/^ACTIVE_SERVEN_BUILD=.*/ACTIVE_SERVEN_BUILD=$(TIMESTAMP)/' $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	else \
	  echo "ACTIVE_SERVEN_BUILD=$(TIMESTAMP)" >> $(ROOT_DIR)/dyllis-ditto/ditto.conf; \
	fi; \
	idx=0; \
	for b in $$(ls -1t $(ROOT_DIR)/dyllis-ditto/serven-compile 2>/dev/null); do \
	  idx=$$((idx+1)); \
	  if [ $$idx -gt 3 ]; then \
	    rm -rf $(ROOT_DIR)/dyllis-ditto/serven-compile/$$b; \
	  fi; \
	done; \
	echo "✅ App-Serven Build $(TIMESTAMP) deployed successfully."

serven-start: ensure-pm2-user
	@echo "Starting App-Serven Ditto Server via PM2 (7602)..."
	@ACTIVE_SERVEN_BUILD=$$(grep "^ACTIVE_SERVEN_BUILD=" $(ROOT_DIR)/dyllis-ditto/ditto.conf | cut -d= -f2); \
	if [ -z "$$ACTIVE_SERVEN_BUILD" ]; then echo "Error: ACTIVE_SERVEN_BUILD not found in ditto.conf"; exit 1; fi; \
	NAME=dyllis-serven-7602; \
	PORT=7602; \
	su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) BUILD_DIR_NAME=serven-compile ACTIVE_SERVEN_BUILD=$$ACTIVE_SERVEN_BUILD SERVER_PORT=$$PORT PM2_HOME=$(PM2_HOME) pm2 restart $$NAME --update-env --max-memory-restart $(PM2_MAX_MEM)" 2>/dev/null || \
	su -l $(PM2_USER) -c "DITTO_REPO_ROOT=$(ROOT_DIR) BUILD_DIR_NAME=serven-compile ACTIVE_SERVEN_BUILD=$$ACTIVE_SERVEN_BUILD SERVER_PORT=$$PORT PM2_HOME=$(PM2_HOME) pm2 start $(ROOT_DIR)/dyllis-ditto/server/dist/index.js --name $$NAME --max-memory-restart $(PM2_MAX_MEM)"
	@$(call pm2_run,save)

serven-stop: ensure-pm2-user
	@echo "Stop App-Serven Ditto Server"
	@$(call pm2_run,stop dyllis-serven-7602) || true
	@$(call pm2_run,delete dyllis-serven-7602) || true

serven-restart: serven-stop serven-start

# =============================================================================
# Wiki.js (docs.zuzunza.com) - Hosted separately from Ditto
# =============================================================================

wiki-start: ensure-pm2-user
	@echo "🚀 Starting Wiki.js (docs.zuzunza.com) via PM2..."
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 start $(ROOT_DIR)/docs/ecosystem.config.js --max-memory-restart $(PM2_MAX_MEM)' || \
	 su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 restart wiki --update-env --max-memory-restart $(PM2_MAX_MEM)'
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 save'
	@echo "✅ Wiki.js started. Available at: http://localhost:3500"

wiki-stop: ensure-pm2-user
	@echo "⏹️  Stopping Wiki.js..."
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 stop wiki' || true
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 delete wiki' || true
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 save'
	@echo "✅ Wiki.js stopped"

wiki-restart: wiki-stop wiki-start

wiki-status: ensure-pm2-user
	@echo "📊 Wiki.js Status:"
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 describe wiki' || echo "Wiki.js is not running"

wiki-logs: ensure-pm2-user
	@echo "📋 Wiki.js Logs:"
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 logs wiki --lines 50 --nostream'

serven-logs: ensure-pm2-user
	@echo "📋 App-Serven (dyllis-serven-7602) Logs - proxy-swf만 보기: pm2 logs dyllis-serven-7602 | grep proxy-swf"
	@su -l $(PM2_USER) -c 'PM2_HOME=$(PM2_HOME) pm2 logs dyllis-serven-7602 --lines 100 --nostream'

# =============================================================================
# Nginx Management - Domain Routing & Configuration
# =============================================================================

nginx-test:
	@echo "🔍 Testing Nginx configuration..."
	@sudo nginx -t

nginx-reload: nginx-test
	@echo "🔄 Reloading Nginx..."
	@sudo systemctl reload nginx
	@echo "✅ Nginx reloaded successfully"

nginx-logs:
	@echo "📋 Nginx Error Logs (last 50 lines):"
	@sudo tail -50 /var/log/nginx/error.log

routing-show:
	@echo "📖 Domain Routing Rules:"
	@cat $(ROOT_DIR)/ROUTING_RULES.md
