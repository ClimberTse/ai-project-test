#!/usr/bin/env bash
# ==============================================
# Build Script - Maven Clean Compile & Package
# Usage: ./scripts/build.sh [profile] [skip-tests]
#   profile: dev (default) | prod
#   skip-tests: --skip-tests (optional)
# ==============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Configuration
PROFILE="${1:-dev}"
SKIP_TESTS="${2:-}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[BUILD]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}   $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create build info directory
mkdir -p target

echo "=============================================="
echo "  AI Project Test - Build Script"
echo "=============================================="
echo "  Profile   : ${PROFILE}"
echo "  Skip Tests: ${SKIP_TESTS:-false}"
echo "  Timestamp : ${TIMESTAMP}"
echo "=============================================="

# Step 1: Clean
log_info "Step 1/4: Cleaning previous build artifacts..."
mvn clean -q

# Step 2: Compile
log_info "Step 2/4: Compiling source code..."
mvn compile -P"${PROFILE}" -q
log_info "Compilation successful."

# Step 3: Run tests (unless skipped)
if [ "${SKIP_TESTS}" != "--skip-tests" ]; then
    log_info "Step 3/4: Running unit tests..."
    if mvn test -P"${PROFILE}"; then
        log_info "All tests passed."
    else
        log_error "Tests failed! Check test reports in target/surefire-reports/"
        exit 1
    fi
else
    log_warn "Step 3/4: Tests skipped (--skip-tests flag provided)."
fi

# Step 4: Package
log_info "Step 4/4: Packaging application..."
mvn package -P"${PROFILE}" -DskipTests="${SKIP_TESTS:+true}" -q
log_info "Package created: target/demo.jar"

# Build summary
ARTIFACT_SIZE=$(du -h target/demo.jar 2>/dev/null | cut -f1 || echo "unknown")
log_info "=============================================="
log_info "  BUILD SUCCESSFUL"
log_info "  Artifact: target/demo.jar (${ARTIFACT_SIZE})"
log_info "=============================================="

# Write build metadata
cat > target/build-info.properties << EOF
build.timestamp=${TIMESTAMP}
build.profile=${PROFILE}
build.version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo "unknown")
build.git.commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
build.git.branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
EOF

log_info "Build metadata written to target/build-info.properties"
