

# Dynamic path variables to guarantee cross-environment stability
ROOT_DIR        := $(shell pwd)
FLUTTER_APP_DIR := $(ROOT_DIR)/app/flutter

# Define default automation target when typing just 'make'
.DEFAULT_GOAL := help

# Declare all non-file targets as .PHONY to prevent folder name execution conflicts
.PHONY: help setup clean get run-chrome test

## help: Print out all available automation targets and descriptions
help:
	@echo "Apparule Monorepo Management Console"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available Tasks:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/  /'

## setup: Perform first-time initialization of environment and submodules
setup:
	@echo "Initializing Monorepo structural environment..."
	cd $(FLUTTER_APP_DIR) && flutter pub get

## get: Fetch latest dependency pack packages for the Flutter application
get:
	@echo "Fetching Flutter dependencies..."
	cd $(FLUTTER_APP_DIR) && flutter pub get

## clean: Wipe localized compilation artifacts and build caches safely
clean:
	@echo "Purging build directories..."
	cd $(FLUTTER_APP_DIR) && flutter clean

## run-chrome: Spin up localized preview build server targeted on Google Chrome
run-chrome:
	@echo "Launching development build on local Chrome instance..."
	cd $(FLUTTER_APP_DIR) && flutter run -d chrome

## test: Run structural unit validation suites across core logic elements
test:
	@echo "Running test suites..."
	cd $(FLUTTER_APP_DIR) && flutter test