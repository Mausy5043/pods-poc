# Makefile for pods-poc: build, start and manage Podman pod and images

SHELL := /bin/bash

IMAGE_COLLECTOR ?= pods-poc-collector:latest
IMAGE_TREND ?= pods-poc-trend:latest
IMAGE_WEB ?= pods-poc-web:latest
IMAGE_STORAGE ?= pods-poc-storage:latest

POD_NAME ?= pods-poc-pod
DATA_DIR ?= $(PWD)/data
RCLONE_REMOTE ?=
INSTALL_RCLONE ?= 0

.PHONY: help build rebuild install start stop restart status pod-create pod-rm pull-db install-deps ensure-deps rclone-config

help:
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo "Targets:"
	@echo "  build       Build all images (collector, trend, web, storage)"
	@echo "  rebuild     Rebuild all images (no cache)"
	@echo "  install     Build and start the pod (initial install)"
	@echo "  start       Create pod (if needed), pull DB and start services"
	@echo "  stop        Stop and remove the pod and containers"
	@echo "  restart     Stop and start"
	@echo "  status      Show pod/containers status"
	@echo "Variables:"
	@echo "  POD_NAME    name of pod (default: $(POD_NAME))"
	@echo "  DATA_DIR    host data dir to mount (default: $(DATA_DIR))"
	@echo "  RCLONE_REMOTE  rclone remote name for initial pull (optional)"

## Build images
build:
	@echo "Building images..."
	podman build -t $(IMAGE_COLLECTOR) -f containers/collector/Dockerfile .
	podman build -t $(IMAGE_TREND) -f containers/trend/Dockerfile .
	podman build -t $(IMAGE_WEB) -f containers/web/Dockerfile .
	podman build -t $(IMAGE_STORAGE) -f containers/storage/Dockerfile .

build: ensure-deps
rebuild: ensure-deps
	@echo "Rebuilding images (no cache)..."
	podman build --no-cache -t $(IMAGE_COLLECTOR) -f containers/collector/Dockerfile .
	podman build --no-cache -t $(IMAGE_TREND) -f containers/trend/Dockerfile .
	podman build --no-cache -t $(IMAGE_WEB) -f containers/web/Dockerfile .
	podman build --no-cache -t $(IMAGE_STORAGE) -f containers/storage/Dockerfile .

## One-shot install: build images and optionally install systemd units
install: ensure-deps build
	@echo "Running install-units.sh to install systemd units and helper scripts. You may be prompted for sudo."
	@sudo ./systemd/install-units.sh --enable-all || { echo "install-units failed; units not installed"; exit 1; }

## Create pod
pod-create:
	@echo "Creating pod $(POD_NAME) (port 8000 exposed, container port 80)..."
	-podman pod inspect $(POD_NAME) >/dev/null 2>&1 || podman pod create --name $(POD_NAME) -p 8000:80

pod-rm:
	@echo "Removing pod $(POD_NAME)"
	-podman pod rm -f $(POD_NAME) || true

## One-off pull of DB (restore) - uses storage image's pull command
pull-db:
	@if [ -z "$(RCLONE_REMOTE)" ]; then \
		echo "RCLONE_REMOTE is empty; set RCLONE_REMOTE=dropbox:pods-poc_poc"; exit 1; \
	fi
	@$(MAKE) check-rclone-config || true
	@echo "Running initial DB pull from $(RCLONE_REMOTE) into $(DATA_DIR)"
	podman run --rm -v $(DATA_DIR):/data -e RCLONE_REMOTE=$(RCLONE_REMOTE) $(IMAGE_STORAGE) pull

## Start services in order: initial pull -> run collector, trend, web in pod
start: pod-create
	@echo "Ensuring data dir exists: $(DATA_DIR)"
	mkdir -p $(DATA_DIR)
	@if [ -n "$(RCLONE_REMOTE)" ]; then \
		echo "Performing initial DB pull..."; \
		$(MAKE) check-rclone-config || true; \
		podman run --rm -v $(DATA_DIR):/data -e RCLONE_REMOTE=$(RCLONE_REMOTE) $(IMAGE_STORAGE) pull; \
	else \
		echo "No RCLONE_REMOTE provided; skipping initial DB pull"; \
	fi
	@echo "Starting collector..."
	podman run -d --name pods-poc-collector --pod $(POD_NAME) -v $(DATA_DIR):/data $(IMAGE_COLLECTOR)
	@echo "Starting trend..."
	podman run -d --name pods-poc-trend --pod $(POD_NAME) -v $(DATA_DIR):/data $(IMAGE_TREND)
	@echo "Starting web..."
	podman run -d --name pods-poc-web --pod $(POD_NAME) -v $(DATA_DIR):/data $(IMAGE_WEB)

stop:
	@echo "Stopping pod "$(POD_NAME)" and removing containers"
	-podman pod rm -f $(POD_NAME) || true

restart: stop start

status:
	@echo "Pod overview for $(POD_NAME):"
	-podman pod inspect $(POD_NAME) || true
	@echo "Containers:"
	-podman ps --pod $(POD_NAME) || true

## Ensure build dependencies are present (podman)
install-deps:
	@echo "Checking for podman..."
	@command -v podman >/dev/null 2>&1 || { \
		if command -v brew >/dev/null 2>&1; then \
			echo "Installing podman via brew..."; brew install podman; \
		elif command -v apt-get >/dev/null 2>&1; then \
			echo "Installing podman via apt (requires sudo)..."; sudo apt-get update && sudo apt-get install -y podman; \
		elif command -v dnf >/dev/null 2>&1; then \
			echo "Installing podman via dnf..."; sudo dnf -y install podman; \
		elif command -v pacman >/dev/null 2>&1; then \
				echo "Installing podman and make via pacman (system update)..."; sudo pacman -Syu --noconfirm podman make; \
		else \
			echo "Could not auto-install podman. Please install it manually: https://podman.io/getting-started/installation"; exit 1; \
		fi }
	# Optional: install rclone on the host if requested (set INSTALL_RCLONE=1)
	if [ "$(INSTALL_RCLONE)" = "1" ]; then \
		@echo "INSTALL_RCLONE=1; attempting to install rclone on host..."; \
		command -v rclone >/dev/null 2>&1 || { \
			if command -v brew >/dev/null 2>&1; then \
				echo "Installing rclone via brew..."; brew install rclone; \
			elif command -v apt-get >/dev/null 2>&1; then \
				echo "Installing rclone via apt (requires sudo)..."; sudo apt-get update && sudo apt-get install -y rclone; \
			elif command -v dnf >/dev/null 2>&1; then \
				echo "Installing rclone via dnf..."; sudo dnf -y install rclone; \
			elif command -v pacman >/dev/null 2>&1; then \
				echo "Installing rclone via pacman..."; sudo pacman -S --noconfirm rclone; \
			else \
				echo "Could not auto-install rclone. Please install it manually: https://rclone.org/install/"; exit 1; \
			fi }; \
	fi
ensure-deps: install-deps
	@echo "All required build dependencies present."

## Documentation: how to provide rclone config to the storage container
rclone-config:
	@echo "rclone runs from inside the storage container; you do NOT need rclone on the host to run pulls/pushes."
	@echo "Provide a configured rclone.conf to the container by mounting your host rclone config directory or file into /config in the container. Examples:"
	@echo "  # mount directory (common):"
	@echo "  podman run --rm -v ~/.config/rclone:/config -v $(DATA_DIR):/data -e RCLONE_REMOTE=dropbox:pods-poc $(IMAGE_STORAGE) pull"
	@echo "  # mount single file (explicit):"
	@echo "  podman run --rm -v ~/.config/rclone/rclone.conf:/config/rclone.conf -v $(DATA_DIR):/data -e RCLONE_REMOTE=dropbox:pods-poc $(IMAGE_STORAGE) pull"
	@echo "If you prefer host rclone for interactive 'rclone config' steps, install rclone on your workstation and create the config, then mount it into the container as shown above."

check-rclone-config:
	@if [ -n "$(RCLONE_REMOTE)" ]; then \
		if [ -f "$$HOME/.config/rclone/rclone.conf" ]; then \
			echo "rclone config found at $$HOME/.config/rclone/rclone.conf"; \
		else \
			echo "WARNING: RCLONE_REMOTE is set but no rclone config found at $$HOME/.config/rclone/rclone.conf."; \
			echo "Either mount your host rclone config into the storage container (see 'make rclone-config')"; \
			false; \
		fi; \
	else \
		echo "RCLONE_REMOTE not set; skipping rclone config check"; \
	fi
