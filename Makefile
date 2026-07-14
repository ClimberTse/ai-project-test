# ==============================================
# Makefile - AI Project Test
# Local development & CI/CD shortcuts
# ==============================================

.PHONY: help build test clean package run docker-build docker-up docker-down deploy rollback health code-review release lint

# Default target
.DEFAULT_GOAL := help

# Variables
APP_PORT ?= 8080
PROFILE ?= dev
TAG ?= latest
VERSION ?= 1.0.0-SNAPSHOT

# Colors
GREEN  := \033[0;32m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
NC     := \033[0m

help: ## Show this help message
	@echo "$(BLUE)=============================================$(NC)"
	@echo "$(BLUE)  AI Project Test - Makefile Commands$(NC)"
	@echo "$(BLUE)=============================================$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# ===== Build =====
build: ## Maven clean compile + package
	@chmod +x scripts/*.sh 2>/dev/null || true
	./scripts/build.sh $(PROFILE)

build-skip-tests: ## Build without running tests
	./scripts/build.sh $(PROFILE) --skip-tests

# ===== Test =====
test: ## Run unit tests with coverage
	./scripts/test.sh

test-watch: ## Run tests in watch mode (requires fswatch)
	@echo "Watching for changes..."
	@while true; do \
		inotifywait -r -e modify src/ 2>/dev/null || fswatch -1 src/ 2>/dev/null; \
		mvn test -q; \
	done

# ===== Code Quality =====
lint: code-review ## Alias for code-review

code-review: ## Run Checkstyle + SpotBugs
	./scripts/code-review.sh

checkstyle: ## Run only Checkstyle
	mvn checkstyle:check

spotbugs: ## Run only SpotBugs
	mvn spotbugs:check

# ===== Docker =====
docker-build: ## Build Docker image
	./scripts/docker-build.sh

docker-build-push: ## Build and push Docker image
	./scripts/docker-build.sh "$(DOCKER_REGISTRY)" "$(TAG)"

docker-up: ## Start services with Docker Compose (dev)
	TAG=$(TAG) DEPLOY_ENV=dev docker compose up -d

docker-down: ## Stop services
	docker compose down

docker-logs: ## Tail Docker Compose logs
	docker compose logs -f

docker-ps: ## Show running containers
	docker compose ps

docker-clean: ## Remove containers, images, and volumes
	docker compose down -v --rmi local

# ===== Deploy =====
deploy: ## Deploy application
	./scripts/deploy.sh $(TAG) $(PROFILE)

deploy-prod: ## Deploy to production
	./scripts/deploy.sh $(TAG) prod

rollback: ## Rollback to previous version
	./scripts/rollback.sh

rollback-to: ## Rollback to specific version (usage: make rollback-to TAG=v1.0.0)
	./scripts/rollback.sh $(TAG)

# ===== Health & Monitoring =====
health: ## Check service health
	./scripts/health-check.sh

smoke-test: ## Run smoke tests against running service
	@echo "=== Smoke Tests ==="
	curl -fsS http://localhost:$(APP_PORT)/health | python -m json.tool 2>/dev/null || curl -fsS http://localhost:$(APP_PORT)/health
	@echo ""
	curl -fsS "http://localhost:$(APP_PORT)/api/greeting?name=SmokeTest" | python -m json.tool 2>/dev/null || curl -fsS "http://localhost:$(APP_PORT)/api/greeting?name=SmokeTest"
	@echo ""
	curl -fsS http://localhost:$(APP_PORT)/api/info | python -m json.tool 2>/dev/null || curl -fsS http://localhost:$(APP_PORT)/api/info

# ===== Release =====
release: ## Cut a release (usage: make release VERSION=1.0.0)
	./scripts/release.sh $(VERSION)

# ===== Utility =====
clean: ## Clean build artifacts
	mvn clean
	rm -rf target/

run: ## Run application locally (Maven)
	mvn spring-boot:run -Dspring-boot.run.profiles=$(PROFILE)

package: ## Package application only (JAR)
	mvn package -DskipTests -q

deps: ## Show dependency tree
	mvn dependency:tree

versions: ## Show dependency updates
	mvn versions:display-dependency-updates

# ===== CI/CD Pipeline (local simulation) =====
ci: ## Run full CI pipeline locally (build + test + lint)
	@echo "$(BLUE)=== Running CI Pipeline ===$(NC)"
	$(MAKE) build
	$(MAKE) test
	$(MAKE) code-review
	@echo "$(GREEN)=== CI Pipeline Complete ===$(NC)"

cd: ## Run full CD pipeline locally (docker-build + deploy + health)
	@echo "$(BLUE)=== Running CD Pipeline ===$(NC)"
	$(MAKE) docker-build
	$(MAKE) deploy
	$(MAKE) health
	@echo "$(GREEN)=== CD Pipeline Complete ===$(NC)"

full: ## Run complete CI/CD pipeline locally
	@echo "$(BLUE)=== Running Full CI/CD Pipeline ===$(NC)"
	$(MAKE) ci
	$(MAKE) cd
	@echo "$(GREEN)=== Full Pipeline Complete ===$(NC)"
