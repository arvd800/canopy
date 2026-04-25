# Makefile for Canopy - a fork of canopy-network/canopy
# Provides common development, build, and deployment targets

.PHONY: all build run stop clean test lint docker-build docker-up docker-down logs help

# Default binary name and paths
BINARY_NAME := canopy
BUILD_DIR := ./build
CMD_DIR := ./cmd/canopy
GO := go

# Docker compose file
COMPOSE_FILE := docker-compose.yml

# Version info from git
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BUILD_TIME := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')

# Linker flags for embedding version info
LDFLAGS := -ldflags "-X main.Version=$(GIT_TAG) -X main.Commit=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME)"

## all: build the binary (default target)
all: build

## build: compile the canopy binary
build:
	@echo ">> Building $(BINARY_NAME) ($(GIT_TAG)-$(GIT_COMMIT))..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(CMD_DIR)
	@echo ">> Binary available at $(BUILD_DIR)/$(BINARY_NAME)"

## run: build and run the node locally
run: build
	@echo ">> Starting $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME) start

## test: run all unit tests
test:
	@echo ">> Running tests..."
	$(GO) test ./... -v -count=1

## test-short: run tests excluding long-running integration tests
test-short:
	@echo ">> Running short tests..."
	$(GO) test ./... -short -count=1

## lint: run golangci-lint
lint:
	@echo ">> Linting..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not found, install from https://golangci-lint.run/usage/install/" && exit 1)
	golangci-lint run ./...

## fmt: format Go source files
fmt:
	@echo ">> Formatting source files..."
	$(GO) fmt ./...

## vet: run go vet
vet:
	@echo ">> Running go vet..."
	$(GO) vet ./...

## tidy: tidy go modules
tidy:
	@echo ">> Tidying modules..."
	$(GO) mod tidy

## check: run fmt, vet, and lint in sequence (handy pre-commit check)
check: fmt vet lint
	@echo ">> All checks passed."

## docker-build: build the Docker image
docker-build:
	@echo ">> Building Docker image..."
	docker build -f .docker/Dockerfile -t canopy:$(GIT_TAG) -t canopy:latest .

## docker-up: start all services via docker-compose
docker-up:
	@echo ">> Starting services..."
	docker compose -f $(COMPOSE_FILE) up -d

## docker-down: stop all services
docker-down:
	@echo ">> Stopping services..."
	docker compose -f $(COMPOSE_FILE) down

## logs: tail logs from docker-compose services
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

## stop: alias for docker-down
stop: docker-down

## clean: remove build artifacts
clean:
	@echo ">> Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo ">> Done."

## help: display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
