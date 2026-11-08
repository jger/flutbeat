# ==============================================================================
# Makefile for FlutBeat (AD8232 ECG Telemetry & DSP Backend)
# ==============================================================================

.DEFAULT_GOAL := help
.PHONY: help build build-release run-node run-receiver test-signal test-signal-brady test-signal-tachy test-signal-leadoff send-test-signal sim check test fmt clippy clean

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
	@echo "$(BOLD)$(CYAN)FlutBeat Backend$(RESET) - Available Make Commands"
	@echo "================================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  $(GREEN)%-22s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

test-signal: ## Run BE generating synthetic ECG test signal for FE (default: BPM=72, PORT=50051)
	cargo run --bin ecg_node -- --mode sim --bpm $(BPM) --port $(PORT) --udp-port $(UDP_PORT)

test-signal-brady: ## Run BE test signal with Bradycardia (48 BPM) for FE alert testing
	cargo run --bin ecg_node -- --mode sim --bpm 48 --port $(PORT) --udp-port $(UDP_PORT)

test-signal-tachy: ## Run BE test signal with Tachycardia (135 BPM) for FE alert testing
	cargo run --bin ecg_node -- --mode sim --bpm 135 --port $(PORT) --udp-port $(UDP_PORT)

test-signal-leadoff: ## Run BE test signal with Lead-Off disconnect condition for FE alert testing
	cargo run --bin ecg_node -- --mode sim --bpm $(BPM) --port $(PORT) --udp-port $(UDP_PORT) --lead-off

send-test-signal: ## Stream UDP test signal packets into running BE (simulates WeMos D1 Mini)
	python3 scripts/send_test_udp.py --port $(UDP_PORT) --bpm $(BPM)

sim: test-signal ## Alias for test-signal

build: ## Build debug binaries (ecg_node, ecg_receiver)
	cargo build

build-release: ## Build optimized release binaries
	cargo build --release

run-node: ## Run FlutBeat ECG gRPC server & simulator daemon
	cargo run --bin ecg_node -- --port $(PORT) --udp-port $(UDP_PORT)

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
