#!/usr/bin/env bash
# ==============================================
# Release Script - Version Tagging & Changelog
# Usage: ./scripts/release.sh <version>
#   version: e.g., 1.0.0, 1.1.0-RC1
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

log_info()  { echo -e "${GREEN}[RELEASE]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}   $1"; }
log_error() { echo -e "${RED}[ERROR]${NC}  $1"; }

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    log_error "Version required!"
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.0.0"
    exit 1
fi

# Validate version format (semver-like)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9]+)?$'; then
    log_error "Invalid version format: ${VERSION}"
    echo "Use semver-like format: X.Y.Z or X.Y.Z-SUFFIX"
    exit 1
fi

echo "=============================================="
echo "  AI Project Test - Release ${VERSION}"
echo "=============================================="

# Step 1: Ensure working directory is clean
if [ -n "$(git status --porcelain 2>/dev/null || echo '')" ]; then
    log_warn "Working directory has uncommitted changes."
    git status --short 2>/dev/null || true
    echo ""
    read -r -p "Continue anyway? (y/N) " CONFIRM
    if [ "${CONFIRM,,}" != "y" ]; then
        log_info "Release cancelled."
        exit 0
    fi
fi

# Step 2: Update version in pom.xml
log_info "Updating version to ${VERSION} in pom.xml..."
mvn versions:set -DnewVersion="${VERSION}" -q 2>/dev/null || {
    log_warn "Maven version update failed. Update pom.xml manually if needed."
}

# Step 3: Run full test suite
log_info "Running full test suite..."
if mvn clean verify -q 2>&1; then
    log_info "All tests passed."
else
    log_error "Tests failed! Fix issues before releasing."
    exit 1
fi

# Step 4: Build Docker image
log_info "Building release Docker image..."
./scripts/docker-build.sh "" "${VERSION}"

# Step 5: Git tag
log_info "Creating Git tag: v${VERSION}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Generate changelog from commits since last tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$LAST_TAG" ]; then
        CHANGELOG=$(git log "${LAST_TAG}..HEAD" --oneline --no-merges 2>/dev/null || echo "No changes recorded")
    else
        CHANGELOG=$(git log --oneline --no-merges 2>/dev/null || echo "Initial release")
    fi

    echo ""
    echo "--- Changelog (${LAST_TAG:-initial}..HEAD) ---"
    echo "${CHANGELOG}"
    echo ""

    git tag -a "v${VERSION}" -m "Release v${VERSION}

${CHANGELOG}"
    log_info "Tag v${VERSION} created."

    # Step 6: Push tag
    read -r -p "Push tag v${VERSION} to remote? (y/N) " PUSH_CONFIRM
    if [ "${PUSH_CONFIRM,,}" = "y" ]; then
        git push origin "v${VERSION}"
        log_info "Tag pushed to remote."
    fi
else
    log_warn "Not a Git repository. Skipping tag creation."
fi

# Step 7: Create release artifacts
RELEASE_DIR="target/release-${VERSION}"
mkdir -p "$RELEASE_DIR"
cp target/demo.jar "$RELEASE_DIR/" 2>/dev/null || true
cp target/docker-build-info.properties "$RELEASE_DIR/" 2>/dev/null || true

# Generate release manifest
cat > "$RELEASE_DIR/release-manifest.json" << EOF
{
  "version": "${VERSION}",
  "releaseDate": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "artifact": "target/demo.jar",
  "dockerImage": "ai-project-test:${VERSION}",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

echo ""
log_info "=============================================="
log_info "  RELEASE ${VERSION} COMPLETE"
log_info "  Artifacts: ${RELEASE_DIR}/"
log_info "=============================================="
