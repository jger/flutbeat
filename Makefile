# ==============================================================================
# Makefile for FlutBeat (Direct USB OTG Architecture)
# ==============================================================================

.DEFAULT_GOAL := help
.PHONY: help fe-run test analyze clean build-apk

# ANSI Color Codes
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
BOLD   := \033[1m
RESET  := \033[0m

help: ## Show this help menu with descriptions
	@echo ""
	@echo "$(BOLD)$(CYAN)FlutBeat (Direct USB OTG - No Backend)$(RESET)"
	@echo "================================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

fe-run: ## Run Flutter clinical dashboard frontend
	cd frontend && flutter run

test: ## Run Flutter test suite (DSP, models, UI widgets)
	cd frontend && flutter test

analyze: ## Run Flutter static analysis
	cd frontend && flutter analyze

build-apk: ## Build Android release APK for OTG device testing
	cd frontend && flutter build apk --release

clean: ## Clean Flutter build artifacts
	cd frontend && flutter clean
