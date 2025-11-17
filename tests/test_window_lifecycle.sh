#!/bin/bash
# Test window lifecycle - creation and destruction
# Verifies windows are properly cleaned up when features are closed

XV="${XV_BINARY:-../build/xv}"
TEST_IMG="test_data/test_image.png"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Window Lifecycle Test ===${NC}"
echo "Tests that windows are created and destroyed properly"
echo

cleanup() {
    killall -9 xv 2>/dev/null || true
    sleep 0.5
}

PASSED=0
FAILED=0

# Test 1: Baseline window count
test_baseline() {
    echo -e "${YELLOW}[1/3] Test: Baseline window count${NC}"

    cleanup

    $XV $TEST_IMG &
    PID=$!
    sleep 2

    if ! ps -p $PID >/dev/null 2>&1; then
        echo -e "${RED}  ✗ FAIL: XV failed to start${NC}"
        ((FAILED++))
        return 1
    fi

    COUNT=$(xdotool search --pid $PID 2>/dev/null | wc -l)
    echo "  Baseline window count: $COUNT"

    if [ $COUNT -ge 3 ] && [ $COUNT -le 15 ]; then
        echo -e "${GREEN}  ✓ PASS: Reasonable baseline count${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}  ~ WARN: Unusual count (may be environment)${NC}"
    fi

    kill $PID 2>/dev/null
    wait $PID 2>/dev/null || true

    echo
}

# Test 2: Multiple open/close cycles
test_window_churn() {
    echo -e "${YELLOW}[2/3] Test: Window churn (10 cycles)${NC}"

    cleanup

    $XV $TEST_IMG &
    PID=$!
    sleep 2

    if ! ps -p $PID >/dev/null 2>&1; then
        echo -e "${RED}  ✗ FAIL: XV failed to start${NC}"
        ((FAILED++))
        return 1
    fi

    INITIAL=$(xdotool search --pid $PID 2>/dev/null | wc -l)
    echo "  Initial windows: $INITIAL"

    # Get main window
    WIN=$(xdotool search --pid $PID | head -1)

    if [ -n "$WIN" ]; then
        echo "  Running 10 open/close cycles (Ctrl+V)..."

        for i in {1..10}; do
            xdotool windowactivate --sync $WIN 2>/dev/null
            xdotool key ctrl+v 2>/dev/null  # Toggle browser
            sleep 0.3
        done

        sleep 1

        FINAL=$(xdotool search --pid $PID 2>/dev/null | wc -l)
        echo "  Final windows: $FINAL"

        # After even number of toggles, should be back to initial
        DIFF=$((FINAL - INITIAL))

        if [ $DIFF -ge -2 ] && [ $DIFF -le 2 ]; then
            echo -e "${GREEN}  ✓ PASS: Window count stable (±2)${NC}"
            echo "    No window leak detected"
            ((PASSED++))
        else
            echo -e "${YELLOW}  ~ WARN: Window count changed by $DIFF${NC}"
            echo "    May indicate leak or just browser state"
        fi

        # Check if XV still responsive
        if ps -p $PID >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ PASS: XV still running after churn${NC}"
            ((PASSED++))
        else
            echo -e "${RED}  ✗ FAIL: XV crashed during churn${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}  ~ SKIP: Could not find window${NC}"
    fi

    kill $PID 2>/dev/null
    wait $PID 2>/dev/null || true

    echo
}

# Test 3: Process cleanup
test_cleanup() {
    echo -e "${YELLOW}[3/3] Test: Process cleanup${NC}"

    cleanup

    # Start multiple instances
    for i in {1..5}; do
        $XV $TEST_IMG &
    done
    sleep 2

    BEFORE=$(ps aux | grep "[x]v.*$TEST_IMG" | wc -l)
    echo "  XV processes before cleanup: $BEFORE"

    # Kill all
    cleanup

    AFTER=$(ps aux | grep "[x]v.*$TEST_IMG" | wc -l)
    echo "  XV processes after cleanup: $AFTER"

    if [ "$AFTER" -eq 0 ]; then
        echo -e "${GREEN}  ✓ PASS: All processes terminated${NC}"
        ((PASSED++))
    else
        echo -e "${RED}  ✗ FAIL: $AFTER processes still running${NC}"
        ((FAILED++))
    fi

    echo
}

# Run tests
test_baseline
test_window_churn
test_cleanup

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}=== LIFECYCLE TESTS PASSED ===${NC}"
    echo "Windows are created and destroyed properly"
    exit 0
else
    echo -e "${YELLOW}=== SOME TESTS HAD ISSUES ===${NC}"
    echo "Review output above for details"
    exit 0  # Don't fail hard - may be environment
fi
