#!/usr/bin/env bash
# ==============================================
# Rollback Script
# Usage: ./scripts/rollback.sh [tag|image]
#   tag:  specific image tag to roll back to
#   If no tag specified, rolls back to previous version
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

log_info()  { echo -e "${GREEN}[ROLLBACK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}     $1"; }
log_error() { echo -e "${RED}[ERROR]${NC}    $1"; }

TARGET_TAG="${1:-}"
ENV="${DEPLOY_ENV:-dev}"
BACKUP_DIR="target/rollback"

mkdir -p "$BACKUP_DIR"

echo "=============================================="
echo "  AI Project Test - Rollback"
echo "=============================================="

# Step 1: Determine target version
if [ -z "$TARGET_TAG" ]; then
    log_info "No target specified. Finding previous version..."

    # List available local images sorted by creation date
    PREV_IMAGE=$(docker images "ai-project-test" --format "{{.Tag}} {{.CreatedAt}}" | sort -k2 -r | head -2 | tail -1 | awk '{print $1}' 2>/dev/null || echo "")

    if [ -n "$PREV_IMAGE" ] && [ "$PREV_IMAGE" != "latest" ]; then
        TARGET_TAG="$PREV_IMAGE"
        log_info "Found previous version: ${TARGET_TAG}"
    elif [ -f "$BACKUP_DIR/previous-version.txt" ]; then
        TARGET_TAG=$(cat "$BACKUP_DIR/previous-version.txt")
        log_info "Using backup record: ${TARGET_TAG}"
    else
        log_error "No previous version found!"
        echo ""
        echo "Available local images:"
        docker images "ai-project-test" --format "  {{.Tag}}  ({{.CreatedAt}})" 2>/dev/null || echo "  (none)"
        echo ""
        echo "Usage: ./scripts/rollback.sh <tag>"
        exit 1
    fi
fi

# Step 2: Verify target image exists
if ! docker image inspect "ai-project-test:${TARGET_TAG}" > /dev/null 2>&1; then
    log_error "Image 'ai-project-test:${TARGET_TAG}' not found locally."
    log_info "Try pulling it first, or specify a valid tag."
    echo ""
    echo "Available images:"
    docker images "ai-project-test" --format "  {{.Tag}}  ({{.Size}})" 2>/dev/null
    exit 1
fi

log_info "Target image: ai-project-test:${TARGET_TAG}"

# Step 3: Capture current state
CURRENT_CONTAINER=$(docker ps -q --filter "name=ai-project-test" 2>/dev/null || echo "")
if [ -n "$CURRENT_CONTAINER" ]; then
    CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CURRENT_CONTAINER" 2>/dev/null || echo "unknown")
    echo "$CURRENT_IMAGE" > "$BACKUP_DIR/previous-version.txt"
    log_info "Current image saved for reference: ${CURRENT_IMAGE}"
fi

# Step 4: Stop current container
log_info "Stopping current deployment..."
docker compose down 2>/dev/null || true

# Step 5: Rollback deploy
log_info "Starting rollback deployment with tag: ${TARGET_TAG}"

COMPOSE_FILES=(-f docker-compose.yml)
if [ "$ENV" = "prod" ]; then
    COMPOSE_FILES+=(-f docker-compose.prod.yml)
fi

export TAG="$TARGET_TAG"
export DEPLOY_ENV="$ENV"

if docker compose "${COMPOSE_FILES[@]}" up -d --remove-orphans 2>&1; then
    log_info "Rollback containers started."
else
    log_error "Failed to start rollback containers!"
    exit 1
fi

# Step 6: Health check
APP_PORT="${APP_PORT:-8080}"
HEALTH_URL="http://localhost:${APP_PORT}/health"

log_info "Waiting for health check (${HEALTH_URL})..."
for i in $(seq 1 30); do
    if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
        log_info "Health check PASSED."
        break
    fi
    if [ "$i" -eq 30 ]; then
        log_error "Health check FAILED after rollback! Manual intervention required."
        exit 1
    fi
    sleep 2
done

# Step 7: Success
echo ""
log_info "=============================================="
log_info "  ROLLBACK SUCCESSFUL"
log_info "  Now running: ai-project-test:${TARGET_TAG}"
log_info "=============================================="
exit 0
