# ==============================================================================
# Makefile for FlutBeat (Root Orchestration)
# ==============================================================================

.DEFAULT_GOAL := help
.PHONY: help test-signal test-signal-brady test-signal-tachy test-signal-leadoff send-test-signal sim run-node run-receiver build build-release test check clean fe-run

PORT       ?= 50051
UDP_PORT   ?= 50052
BPM        ?= 72
SERVER_URL ?= http://127.0.0.1:$(PORT)

# ANSI Color Codes
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
BOLD   := \033[1m
RESET  := \033[0m

help: ## Show this help menu with descriptions
	@echo ""
	@echo "$(BOLD)$(CYAN)FlutBeat$(RESET) - Root Make Commands"
	@echo "================================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  $(GREEN)%-24s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

test-signal: ## Run BE generating synthetic ECG test signal for FE (default: BPM=72, PORT=50051)
	@$(MAKE) -C backend test-signal BPM=$(BPM) PORT=$(PORT) UDP_PORT=$(UDP_PORT)

test-signal-brady: ## Run BE test signal with Bradycardia (48 BPM) for FE alert testing
	@$(MAKE) -C backend test-signal-brady PORT=$(PORT) UDP_PORT=$(UDP_PORT)

test-signal-tachy: ## Run BE test signal with Tachycardia (135 BPM) for FE alert testing
	@$(MAKE) -C backend test-signal-tachy PORT=$(PORT) UDP_PORT=$(UDP_PORT)

test-signal-leadoff: ## Run BE test signal with Lead-Off disconnect condition for FE testing
	@$(MAKE) -C backend test-signal-leadoff BPM=$(BPM) PORT=$(PORT) UDP_PORT=$(UDP_PORT)

send-test-signal: ## Inject UDP test signal into running BE (simulates WeMos D1 Mini)
	@$(MAKE) -C backend send-test-signal BPM=$(BPM) UDP_PORT=$(UDP_PORT)

sim: test-signal ## Alias for test-signal

run-node: ## Run FlutBeat backend gRPC server daemon
	@$(MAKE) -C backend run-node PORT=$(PORT) UDP_PORT=$(UDP_PORT)

run-receiver: ## Run terminal ECG oscilloscope & telemetry receiver
	@$(MAKE) -C backend run-receiver SERVER_URL=$(SERVER_URL)

build: ## Build backend binaries
	@$(MAKE) -C backend build

build-release: ## Build release backend binaries
	@$(MAKE) -C backend build-release

test: ## Run unit and integration tests
	@$(MAKE) -C backend test

check: ## Fast compilation check
	@$(MAKE) -C backend check

clean: ## Clean build artifacts
	@$(MAKE) -C backend clean

fe-run: ## Run Flutter clinical dashboard frontend
	cd frontend && flutter run

