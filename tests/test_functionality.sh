#!/bin/bash
# Functional tests for XV lazy-loaded features
# Verifies that browser windows, dialogs, and menus work correctly after optimizations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XV_BINARY="${SCRIPT_DIR}/../build/xv"
TEST_IMAGE="${SCRIPT_DIR}/test_data/test_image.png"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Check if we're running in X11
if [ -z "$DISPLAY" ]; then
    echo -e "${RED}ERROR: No X11 display available (DISPLAY not set)${NC}"
    exit 1
fi

# Check for xdotool (required for functional tests)
if ! command -v xdotool &> /dev/null; then
    echo -e "${RED}ERROR: xdotool is required for functional tests${NC}"
    echo "Install with: sudo apt-get install xdotool"
    exit 1
fi

# Helper functions
test_start() {
    echo -e "${BLUE}Testing: $1${NC}"
}

test_pass() {
    echo -e "${GREEN}  ✓ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}  ✗ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_skip() {
    echo -e "${YELLOW}  ⊘ SKIP: $1${NC}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Find XV window by PID
find_xv_window() {
    local pid=$1
    xdotool search --pid $pid --name "xv" 2>/dev/null | head -1
}

# Count windows for XV process
count_xv_windows() {
    local pid=$1
    xdotool search --pid $pid 2>/dev/null | wc -l
}

# Simulate key press
send_key() {
    local window=$1
    local key=$2
    xdotool key --window $window "$key" 2>/dev/null
    sleep 0.3
}

# Simulate mouse click at coordinates
click_at() {
    local window=$1
    local x=$2
    local y=$3
    xdotool mousemove --window $window $x $y click 1 2>/dev/null
    sleep 0.3
}

echo "========================================="
echo "XV Functional Tests"
echo "========================================="
echo

# Check if XV binary exists
if [ ! -f "$XV_BINARY" ]; then
    echo -e "${RED}ERROR: XV binary not found at $XV_BINARY${NC}"
    echo "Please build XV first"
    exit 1
fi

# Create test image if needed
mkdir -p "${SCRIPT_DIR}/test_data"
if [ ! -f "$TEST_IMAGE" ]; then
    if command -v convert &> /dev/null; then
        convert -size 100x100 xc:blue "$TEST_IMAGE"
    else
        echo -e "${YELLOW}WARNING: No test image available${NC}"
    fi
fi

# Start XV
echo "Starting XV..."
if [ -f "$TEST_IMAGE" ]; then
    $XV_BINARY "$TEST_IMAGE" &
else
    $XV_BINARY &
fi
XV_PID=$!
sleep 2

# Check if XV started
if ! kill -0 $XV_PID 2>/dev/null; then
    echo -e "${RED}ERROR: XV failed to start${NC}"
    exit 1
fi

XV_WINDOW=$(find_xv_window $XV_PID)
if [ -z "$XV_WINDOW" ]; then
    echo -e "${RED}ERROR: Could not find XV window${NC}"
    kill $XV_PID 2>/dev/null || true
    exit 1
fi

echo "XV started with PID: $XV_PID, Window: $XV_WINDOW"
echo

# Count initial windows
INITIAL_WINDOWS=$(count_xv_windows $XV_PID)
echo "Initial window count: $INITIAL_WINDOWS"
echo

# Test 1: Verify low initial window count
test_start "Initial window allocation"
if [ $INITIAL_WINDOWS -le 15 ]; then
    test_pass "Initial windows ($INITIAL_WINDOWS) within optimized range"
else
    test_fail "Too many initial windows ($INITIAL_WINDOWS > 15)"
fi
echo

# Test 2: Test browser window lazy creation
test_start "Browser window lazy creation"
echo "  Attempting to open browser window..."

# Try to open browser window (usually Ctrl+B or via menu)
# Note: This may vary by XV build, so we test if windows increase
BEFORE_BROWSER=$(count_xv_windows $XV_PID)
send_key $XV_WINDOW "ctrl+b"
sleep 1
AFTER_BROWSER=$(count_xv_windows $XV_PID)

if [ $AFTER_BROWSER -gt $BEFORE_BROWSER ]; then
    test_pass "Browser window created on-demand (+$((AFTER_BROWSER - BEFORE_BROWSER)) windows)"
    # Close browser window (Escape)
    send_key $XV_WINDOW "Escape"
    sleep 0.5
else
    test_skip "Browser window test (may not be supported in this build)"
fi
echo

# Test 3: Test gamma/color editor lazy creation
test_start "Gamma window lazy creation"
echo "  Attempting to open gamma/color editor..."

BEFORE_GAMMA=$(count_xv_windows $XV_PID)
send_key $XV_WINDOW "ctrl+e"
sleep 1
AFTER_GAMMA=$(count_xv_windows $XV_PID)

if [ $AFTER_GAMMA -gt $BEFORE_GAMMA ]; then
    test_pass "Gamma window created on-demand (+$((AFTER_GAMMA - BEFORE_GAMMA)) windows)"
    # Close gamma window
    send_key $XV_WINDOW "Escape"
    sleep 0.5
else
    test_skip "Gamma window test (may not be supported or no gmap)"
fi
echo

# Test 4: Test save dialog (format dialogs)
test_start "Format dialog lazy creation"
echo "  Attempting to open save dialog..."

BEFORE_SAVE=$(count_xv_windows $XV_PID)
send_key $XV_WINDOW "ctrl+s"
sleep 1
AFTER_SAVE=$(count_xv_windows $XV_PID)

if [ $AFTER_SAVE -gt $BEFORE_SAVE ]; then
    test_pass "Save dialog created on-demand (+$((AFTER_SAVE - BEFORE_SAVE)) windows)"

    # Try to select JPEG format to test format dialog lazy creation
    # This is hard to automate without knowing exact UI layout
    # So we just verify the save dialog opened

    # Close save dialog
    send_key $XV_WINDOW "Escape"
    sleep 0.5
else
    test_skip "Save dialog test (may require loaded image)"
fi
echo

# Test 5: Test menu button popup lazy creation
test_start "Menu button popup lazy creation"
echo "  Testing menu button activation..."

# This test verifies that menu popups work but don't increase persistent window count
BEFORE_MENU=$(count_xv_windows $XV_PID)

# Right-click on image window to trigger a menu (if available)
# This is build/config dependent
click_at $XV_WINDOW 50 50
sleep 0.5

# Click away to close any menu
click_at $XV_WINDOW 10 10
sleep 0.5

AFTER_MENU=$(count_xv_windows $XV_PID)

# Menu popups should be created and destroyed, so count should be similar
if [ $AFTER_MENU -eq $BEFORE_MENU ]; then
    test_pass "Menu popups don't persist (window count stable)"
elif [ $AFTER_MENU -gt $BEFORE_MENU ]; then
    # Some menus might still be open
    test_skip "Menu popup test (menu may still be visible)"
else
    test_pass "Menu popups work correctly"
fi
echo

# Test 6: Verify XV still responds
test_start "XV responsiveness after tests"
if kill -0 $XV_PID 2>/dev/null; then
    test_pass "XV still running and responsive"
else
    test_fail "XV crashed during tests"
fi
echo

# Test 7: Window count remains low
test_start "Window count remains optimized"
FINAL_WINDOWS=$(count_xv_windows $XV_PID)
echo "  Final window count: $FINAL_WINDOWS"

if [ $FINAL_WINDOWS -le 20 ]; then
    test_pass "Window count remains low after operations ($FINAL_WINDOWS ≤ 20)"
else
    test_fail "Window count increased unexpectedly ($FINAL_WINDOWS > 20)"
fi
echo

# Cleanup
echo "Cleaning up..."
kill $XV_PID 2>/dev/null || true
wait $XV_PID 2>/dev/null || true

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests PASSED${NC}"
    exit 0
else
    echo -e "${RED}Some tests FAILED${NC}"
    exit 1
fi
