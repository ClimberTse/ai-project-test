#!/usr/bin/env bash
# ==============================================
# Docker Build & Push Script
# Usage: ./scripts/docker-build.sh [registry] [tag]
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

log_info()  { echo -e "${GREEN}[DOCKER]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
DOCKER_REGISTRY="${1:-}"           # e.g., harbor.example.com/project
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Image tagging strategy: {branch}-{commit}-{timestamp}
IMAGE_NAME="ai-project-test"
TAG_BASE="${2:-${GIT_BRANCH}-${GIT_COMMIT}-${TIMESTAMP}}"
TAG_LATEST="latest"
TAG_BRANCH="${GIT_BRANCH}"

if [ -n "$DOCKER_REGISTRY" ]; then
    FULL_IMAGE="${DOCKER_REGISTRY}/${IMAGE_NAME}"
else
    FULL_IMAGE="${IMAGE_NAME}"
fi

echo "=============================================="
echo "  AI Project Test - Docker Build"
echo "=============================================="
echo "  Image    : ${FULL_IMAGE}"
echo "  Tag      : ${TAG_BASE}"
echo "  Registry : ${DOCKER_REGISTRY:-local}"
echo "  Git      : ${GIT_BRANCH}@${GIT_COMMIT}"
echo "=============================================="

# Step 1: Build the image
log_info "Building Docker image..."
docker build \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="${GIT_COMMIT}" \
    --build-arg VERSION="${TAG_BASE}" \
    -t "${FULL_IMAGE}:${TAG_BASE}" \
    -t "${FULL_IMAGE}:${TAG_BRANCH}" \
    -t "${FULL_IMAGE}:${TAG_LATEST}" \
    -f Dockerfile .

BUILD_EXIT=$?
if [ $BUILD_EXIT -ne 0 ]; then
    log_error "Docker build failed!"
    exit $BUILD_EXIT
fi

log_info "Image built successfully."

# Step 2: Image info
IMAGE_SIZE=$(docker images --format "{{.Size}}" "${FULL_IMAGE}:${TAG_BASE}" 2>/dev/null || echo "unknown")
IMAGE_ID=$(docker images --format "{{.ID}}" "${FULL_IMAGE}:${TAG_BASE}" 2>/dev/null || echo "unknown")
log_info "  Image ID:   ${IMAGE_ID}"
log_info "  Image Size: ${IMAGE_SIZE}"

# Step 3: Push if registry specified
if [ -n "$DOCKER_REGISTRY" ]; then
    log_info "Pushing images to registry: ${DOCKER_REGISTRY}"

    docker push "${FULL_IMAGE}:${TAG_BASE}"
    docker push "${FULL_IMAGE}:${TAG_BRANCH}"
    docker push "${FULL_IMAGE}:${TAG_LATEST}"

    log_info "Images pushed successfully."
else
    log_warn "No registry specified. Images built locally only."
    log_info "To push, run: docker tag ${IMAGE_NAME}:${TAG_BASE} <registry>/${IMAGE_NAME}:<tag>"
fi

# Step 4: Save version info
mkdir -p target
cat > target/docker-build-info.properties << EOF
docker.image=${FULL_IMAGE}
docker.tag=${TAG_BASE}
docker.tag_branch=${TAG_BRANCH}
docker.tag_latest=${TAG_LATEST}
docker.image_id=${IMAGE_ID}
docker.registry=${DOCKER_REGISTRY:-local}
build.timestamp=${TIMESTAMP}
git.commit=${GIT_COMMIT}
git.branch=${GIT_BRANCH}
EOF

echo ""
log_info "=============================================="
log_info "  DOCKER BUILD SUCCESSFUL"
log_info "  ${FULL_IMAGE}:${TAG_BASE}"
log_info "=============================================="
