#!/usr/bin/env bash
# ==============================================
# Deploy Script - Docker Compose Blue-Green Deploy
# Usage: ./scripts/deploy.sh [tag] [env]
#   tag: image tag (default: latest)
#   env: dev (default) | prod
#
# Strategy: Rolling update with health check
# ==============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
TAG="${1:-latest}"
ENV="${2:-dev}"
APP_PORT="${APP_PORT:-8080}"
HEALTH_URL="http://localhost:${APP_PORT}/health"
HEALTH_RETRIES=30
HEALTH_INTERVAL=2
ROLLBACK_ON_FAILURE="${ROLLBACK_ON_FAILURE:-true}"

echo "=============================================="
echo "  AI Project Test - Deploy"
echo "=============================================="
echo "  Tag        : ${TAG}"
echo "  Environment: ${ENV}"
echo "  Port       : ${APP_PORT}"
echo "=============================================="

# Determine compose files
COMPOSE_FILES=(-f docker-compose.yml)
if [ "$ENV" = "prod" ]; then
    COMPOSE_FILES+=(-f docker-compose.prod.yml)
fi

# Step 1: Pull image (if remote registry)
log_info "Pulling latest images..."
export TAG="$TAG"
export DEPLOY_ENV="$ENV"
export SPRING_PROFILES_ACTIVE="$ENV"

# Step 2: Capture current container state for rollback
OLD_CONTAINER_ID=$(docker ps -q --filter "name=ai-project-test" 2>/dev/null || echo "")
OLD_IMAGE=""
if [ -n "$OLD_CONTAINER_ID" ]; then
    OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$OLD_CONTAINER_ID" 2>/dev/null || echo "")
    log_info "Current running image: ${OLD_IMAGE:-unknown}"
fi

# Step 3: Deploy with Docker Compose
log_info "Starting deployment..."
if docker compose "${COMPOSE_FILES[@]}" up -d --remove-orphans 2>&1; then
    log_info "Containers started. Waiting for health check..."
else
    log_error "Docker Compose up failed!"
    exit 1
fi

# Step 4: Health check polling
log_info "Polling health endpoint: ${HEALTH_URL}"
for i in $(seq 1 $HEALTH_RETRIES); do
    if curl -sf "${HEALTH_URL}" > /dev/null 2>&1; then
        log_info "Health check PASSED (attempt ${i}/${HEALTH_RETRIES})"
        break
    fi
    if [ "$i" -eq "$HEALTH_RETRIES" ]; then
        log_error "Health check FAILED after ${HEALTH_RETRIES} attempts!"

        # Auto rollback
        if [ "$ROLLBACK_ON_FAILURE" = "true" ] && [ -n "$OLD_IMAGE" ]; then
            log_warn "Rolling back to previous image: ${OLD_IMAGE}"
            docker tag "$OLD_IMAGE" "ai-project-test:rollback" 2>/dev/null || true
            TAG="rollback" docker compose "${COMPOSE_FILES[@]}" up -d --remove-orphans
            log_warn "Rollback completed."
        fi
        exit 1
    fi
    sleep "$HEALTH_INTERVAL"
done

# Step 5: Verify deployment
RESPONSE=$(curl -s "${HEALTH_URL}" 2>/dev/null || echo '{}')
STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "UNKNOWN")

if [ "$STATUS" = "UP" ]; then
    log_info "=============================================="
    log_info "  DEPLOYMENT SUCCESSFUL"
    log_info "  Environment: ${ENV}"
    log_info "  Health:      ${STATUS}"
    log_info "  URL:         ${HEALTH_URL}"
    log_info "=============================================="

    # Clean up old images (keep last 3)
    docker images "ai-project-test" --format "{{.ID}} {{.Tag}}" | sort -u | tail -n +4 | awk '{print $1}' | xargs -r docker rmi 2>/dev/null || true
    exit 0
else
    log_error "Deployment verification failed. Health status: ${STATUS}"
    exit 1
fi
