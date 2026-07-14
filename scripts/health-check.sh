#!/usr/bin/env bash
# ==============================================
# Health Check Script - Monitors service health
# Usage: ./scripts/health-check.sh [url] [timeout]
#   url:     health endpoint (default: http://localhost:8080/health)
#   timeout: max wait in seconds (default: 60)
# ==============================================
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[HEALTH]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

HEALTH_URL="${1:-http://localhost:8080/health}"
TIMEOUT="${2:-60}"
INTERVAL=2
MAX_RETRIES=$((TIMEOUT / INTERVAL))

echo "=============================================="
echo "  AI Project Test - Health Check"
echo "=============================================="
echo "  URL:     ${HEALTH_URL}"
echo "  Timeout: ${TIMEOUT}s"
echo "=============================================="

# Poll health endpoint
START_TIME=$(date +%s)

for i in $(seq 1 $MAX_RETRIES); do
    HTTP_CODE=$(curl -s -o /tmp/health-response.json -w "%{http_code}" \
        --connect-timeout 5 --max-time 10 "${HEALTH_URL}" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        RESPONSE=$(cat /tmp/health-response.json 2>/dev/null || echo "{}")
        STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "UNKNOWN")

        if [ "$STATUS" = "UP" ]; then
            ELAPSED=$(($(date +%s) - START_TIME))
            log_info "Service is HEALTHY (HTTP ${HTTP_CODE}, status: ${STATUS})"
            log_info "Response time: ${ELAPSED}s"

            # Show extra info
            SERVICE=$(echo "$RESPONSE" | grep -o '"service":"[^"]*"' | cut -d'"' -f4 || echo "?")
            log_info "Service: ${SERVICE}"
            exit 0
        else
            log_warn "HTTP 200 but status is '${STATUS}' - retrying (${i}/${MAX_RETRIES})..."
        fi
    elif [ "$HTTP_CODE" = "000" ]; then
        log_warn "Connection refused - service may be starting (${i}/${MAX_RETRIES})..."
    else
        RESPONSE=$(cat /tmp/health-response.json 2>/dev/null || echo "{}")
        log_warn "HTTP ${HTTP_CODE} - retrying (${i}/${MAX_RETRIES})..."
    fi

    sleep "$INTERVAL"
done

# Health check failed
ELAPSED=$(($(date +%s) - START_TIME))
log_error "Health check FAILED after ${ELAPSED}s (${MAX_RETRIES} retries)"

# Check Docker container status for diagnostics
echo ""
echo "--- Container Status ---"
docker ps -a --filter "name=ai-project-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker not available or container not found"

echo ""
echo "--- Recent Logs ---"
docker logs --tail 20 "ai-project-test-app" 2>/dev/null || docker logs --tail 20 "ai-project-test-prod" 2>/dev/null || echo "  No logs available"

rm -f /tmp/health-response.json
exit 1
