#!/usr/bin/env bash
# ==============================================
# Code Review Script - Checkstyle + SpotBugs
# Usage: ./scripts/code-review.sh
# ==============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[REVIEW]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

FAILED=0
REPORT_DIR="target/code-review"
mkdir -p "$REPORT_DIR"

echo "=============================================="
echo "  AI Project Test - Code Review"
echo "=============================================="

# Step 1: Checkstyle
log_info "Running Checkstyle analysis..."
CHECKSTYLE_REPORT="$REPORT_DIR/checkstyle-report.xml"
if mvn checkstyle:check -q 2>&1 | tee "$REPORT_DIR/checkstyle-output.txt"; then
    log_info "Checkstyle: PASSED (0 violations)"
else
    CHECKSTYLE_VIOLATIONS=$(grep -c "WARN\|ERROR" "$REPORT_DIR/checkstyle-output.txt" 2>/dev/null || echo "?")
    log_error "Checkstyle: FAILED (${CHECKSTYLE_VIOLATIONS} violations found)"
    log_error "See: $REPORT_DIR/checkstyle-output.txt"
    FAILED=1
fi

# Step 2: SpotBugs
log_info "Running SpotBugs analysis..."
if mvn spotbugs:check -q 2>&1 | tee "$REPORT_DIR/spotbugs-output.txt"; then
    log_info "SpotBugs: PASSED (0 High/Medium bugs)"
else
    log_error "SpotBugs: FAILED (bugs found above threshold)"
    log_error "See: target/spotbugs.html"
    FAILED=1
fi

# Step 3: Summary
echo ""
echo "=============================================="
if [ "$FAILED" -eq 0 ]; then
    log_info "CODE REVIEW PASSED - Quality gates met"
    log_info "Reports: $REPORT_DIR/"
    exit 0
else
    log_error "CODE REVIEW FAILED - Fix issues before proceeding"
    log_info "Checkstyle config: config/checkstyle.xml"
    log_info "SpotBugs exclusions: config/spotbugs-exclude.xml"
    exit 1
fi
