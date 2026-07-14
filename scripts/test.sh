#!/usr/bin/env bash
# ==============================================
# Test Script - Unit Tests + Coverage Report
# Usage: ./scripts/test.sh
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

log_info()  { echo -e "${GREEN}[TEST]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[FAIL]${NC}  $1"; }

COVERAGE_THRESHOLD=80
FAILED=0

echo "=============================================="
echo "  AI Project Test - Unit Test Suite"
echo "=============================================="

# Step 1: Run tests with JaCoCo
log_info "Running unit tests with JaCoCo coverage..."
if mvn test jacoco:report -q 2>&1; then
    log_info "All unit tests passed."
else
    log_error "Some unit tests failed!"
    FAILED=1
fi

# Step 2: Check coverage report
COVERAGE_CSV="target/site/jacoco/jacoco.csv"
if [ -f "$COVERAGE_CSV" ]; then
    log_info "=============================================="
    log_info "  Coverage Report"
    log_info "=============================================="

    # Parse JaCoCo CSV: INSTRUCTION, BRANCH, LINE, COMPLEXITY, METHOD, CLASS
    # CSV format: GROUP,PACKAGE,CLASS,INSTRUCTION_MISSED,INSTRUCTION_COVERED,BRANCH_MISSED,...
    INSTRUCTION_COVERAGE=$(awk -F',' 'NR>1 {
        missed=$4; covered=$5;
        total=missed+covered;
        if(total>0) sum+=covered/total; count++
    } END { if(count>0) printf "%.1f", (sum/count)*100; else print "0" }' "$COVERAGE_CSV")

    BRANCH_COVERAGE=$(awk -F',' 'NR>1 {
        missed=$6; covered=$7;
        total=missed+covered;
        if(total>0) sum+=covered/total; count++
    } END { if(count>0) printf "%.1f", (sum/count)*100; else print "0" }' "$COVERAGE_CSV")

    LINE_COVERAGE=$(awk -F',' 'NR>1 {
        missed=$8; covered=$9;
        total=missed+covered;
        if(total>0) sum+=covered/total; count++
    } END { if(count>0) printf "%.1f", (sum/count)*100; else print "0" }' "$COVERAGE_CSV")

    echo "  Instruction Coverage : ${INSTRUCTION_COVERAGE}%"
    echo "  Branch Coverage      : ${BRANCH_COVERAGE}%"
    echo "  Line Coverage        : ${LINE_COVERAGE}%"
    echo ""

    # Check against threshold
    INSTR_INT=$(echo "$INSTRUCTION_COVERAGE" | cut -d. -f1)
    if [ "$INSTR_INT" -lt "$COVERAGE_THRESHOLD" ]; then
        log_error "Instruction coverage ${INSTRUCTION_COVERAGE}% is below threshold of ${COVERAGE_THRESHOLD}%"
        FAILED=1
    else
        log_info "Coverage gate passed (>= ${COVERAGE_THRESHOLD}%)."
    fi
else
    log_error "Coverage report not found at $COVERAGE_CSV"
    FAILED=1
fi

# Step 3: Summary
echo ""
echo "=============================================="
if [ "$FAILED" -eq 0 ]; then
    log_info "TEST SUITE PASSED"
    log_info "Coverage report: target/site/jacoco/index.html"
    exit 0
else
    log_error "TEST SUITE FAILED"
    log_error "Check report: target/site/jacoco/index.html"
    log_error "Surefire reports: target/surefire-reports/"
    exit 1
fi
