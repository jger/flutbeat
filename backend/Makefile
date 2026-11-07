# ==============================================================================
# Makefile for FlutBeat (AD8232 ECG Telemetry & DSP Backend)
# ==============================================================================

.DEFAULT_GOAL := help
.PHONY: help build build-release run-node run-receiver check test fmt clippy clean

SERVER_URL ?= http://127.0.0.1:50051

# ANSI Color Codes
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
BOLD   := \033[1m
RESET  := \033[0m

help: ## Show this help menu with descriptions
	@echo ""
	@echo "$(BOLD)$(CYAN)FlutBeat Backend$(RESET) - Available Make Commands"
	@echo "================================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  $(GREEN)%-22s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

build: ## Build debug binaries (ecg_node, ecg_receiver)
	cargo build

build-release: ## Build optimized release binaries
	cargo build --release

run-node: ## Run FlutBeat ECG gRPC server & simulator daemon
	cargo run --bin ecg_node

run-receiver: ## Run terminal ECG oscilloscope & telemetry receiver
	cargo run --bin ecg_receiver -- --server-url $(SERVER_URL)

check: ## Fast compilation check
	cargo check

test: ## Run full unit and gRPC integration test suite
	cargo test

fmt: ## Format Rust codebase with rustfmt
	cargo fmt

clippy: ## Run Clippy linter
	cargo clippy -- -D warnings

clean: ## Clean cargo target artifacts
	cargo clean
