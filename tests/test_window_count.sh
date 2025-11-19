#!/bin/bash
# Test script to measure X window allocation by XV
# Verifies that Phase 1 and Phase 2 optimizations reduced window count

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XV_BINARY="${SCRIPT_DIR}/../build/xv"
TEST_IMAGE="${SCRIPT_DIR}/test_data/test_image.png"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're running in X11
if [ -z "$DISPLAY" ]; then
    echo -e "${RED}ERROR: No X11 display available (DISPLAY not set)${NC}"
    echo "This test requires a running X server."
    exit 1
fi

# Check for required tools
check_tools() {
    local missing=0

    if ! command -v xwininfo &> /dev/null; then
        echo -e "${RED}ERROR: xwininfo not found${NC}"
        missing=1
    fi

    if ! command -v xdotool &> /dev/null; then
        echo -e "${YELLOW}WARNING: xdotool not found (some tests will be limited)${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo "Please install required X11 tools:"
        echo "  Ubuntu/Debian: sudo apt-get install x11-utils xdotool"
        echo "  Fedora: sudo dnf install xorg-x11-utils xdotool"
        exit 1
    fi
}

# Count windows for a given process
count_windows() {
    local pid=$1
    # Get all windows and filter by PID
    # We count both top-level and child windows
    local count=$(xwininfo -root -tree | grep -c "xv" || echo "0")
    echo "$count"
}

# Count windows created by specific PID
count_windows_by_pid() {
    local pid=$1
    local count=0

    # Use xdotool if available for more accurate counting
    if command -v xdotool &> /dev/null; then
        count=$(xdotool search --pid $pid 2>/dev/null | wc -l)
    else
        # Fallback: parse xwininfo output
        count=$(xwininfo -root -tree | grep -c "xv" || echo "0")
    fi

    echo "$count"
}

# Main test
echo "========================================="
echo "XV X Window Allocation Test"
echo "========================================="
echo

check_tools

# Check if XV binary exists
if [ ! -f "$XV_BINARY" ]; then
    echo -e "${YELLOW}WARNING: XV binary not found at $XV_BINARY${NC}"
    echo "Please build XV first: cd build && cmake .. && make"
    exit 1
fi

# Create test image if it doesn't exist
mkdir -p "${SCRIPT_DIR}/test_data"
if [ ! -f "$TEST_IMAGE" ]; then
    echo "Creating test image..."
    # Create a simple test image using ImageMagick or skip if not available
    if command -v convert &> /dev/null; then
        convert -size 100x100 xc:blue "$TEST_IMAGE"
    else
        echo -e "${YELLOW}WARNING: ImageMagick not found, skipping image creation${NC}"
        echo "Test will run without loading an image"
        TEST_IMAGE=""
    fi
fi

echo "Starting XV..."
if [ -n "$TEST_IMAGE" ]; then
    $XV_BINARY "$TEST_IMAGE" &
else
    $XV_BINARY &
fi
XV_PID=$!

# Give XV time to start and create windows
sleep 2

# Check if XV is still running
if ! kill -0 $XV_PID 2>/dev/null; then
    echo -e "${RED}ERROR: XV failed to start${NC}"
    exit 1
fi

echo "XV started with PID: $XV_PID"
echo

# Count windows
echo "Counting X windows..."
WINDOW_COUNT=$(count_windows_by_pid $XV_PID)

echo -e "Total windows allocated: ${YELLOW}$WINDOW_COUNT${NC}"
echo

# Expected values based on optimizations
# Before optimizations: ~142 windows
# After Phase 1: ~25 windows (browser=0, formats=0, gamma=0, PS=0)
# After Phase 2: ~8 windows (menu popups=0)
EXPECTED_MAX=15  # Allow some margin
EXPECTED_MIN=5   # Should have at least core windows

echo "Analysis:"
echo "  Before optimizations: ~142 windows"
echo "  After Phase 1 + 2:    ~8 windows (expected)"
echo "  Measured:             $WINDOW_COUNT windows"
echo

# Test results
PASSED=0
if [ $WINDOW_COUNT -le $EXPECTED_MAX ] && [ $WINDOW_COUNT -ge $EXPECTED_MIN ]; then
    echo -e "${GREEN}✓ PASS: Window count is within expected range ($EXPECTED_MIN-$EXPECTED_MAX)${NC}"
    PASSED=1

    # Calculate savings
    BASELINE=142
    SAVED=$((BASELINE - WINDOW_COUNT))
    PERCENT=$((SAVED * 100 / BASELINE))
    echo -e "${GREEN}  Saved: $SAVED windows ($PERCENT% reduction)${NC}"
else
    echo -e "${RED}✗ FAIL: Window count ($WINDOW_COUNT) outside expected range ($EXPECTED_MIN-$EXPECTED_MAX)${NC}"

    if [ $WINDOW_COUNT -gt $EXPECTED_MAX ]; then
        echo -e "${RED}  Too many windows - optimizations may not be working${NC}"
    else
        echo -e "${RED}  Too few windows - XV may not have started correctly${NC}"
    fi
fi

echo
echo "Cleaning up..."
kill $XV_PID 2>/dev/null || true
wait $XV_PID 2>/dev/null || true

echo
echo "========================================="
if [ $PASSED -eq 1 ]; then
    echo -e "${GREEN}Test PASSED${NC}"
    exit 0
else
    echo -e "${RED}Test FAILED${NC}"
    exit 1
fi
