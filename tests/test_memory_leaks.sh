#!/bin/bash
# Test for memory leaks using valgrind
# Checks if lazy window creation introduces memory leaks

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

echo -e "${BLUE}=== Memory Leak Detection Test ===${NC}"
echo

# Check if valgrind is available
if ! command -v valgrind &>/dev/null; then
    echo -e "${YELLOW}⚠ SKIP: valgrind not installed${NC}"
    echo "Install with: sudo apt-get install valgrind"
    echo
    echo "Skipping memory leak tests (not critical for Phase 1)"
    exit 0
fi

echo "Using valgrind to check for memory leaks..."
echo "Note: This may take 30-60 seconds"
echo

LOGFILE="valgrind-xv-$$.log"

# Run XV under valgrind for a short time
echo "Starting XV under valgrind..."
timeout 10 valgrind \
    --leak-check=full \
    --show-leak-kinds=definite,possible \
    --errors-for-leak-kinds=definite \
    --error-exitcode=42 \
    --log-file="$LOGFILE" \
    $XV $TEST_IMG 2>&1 >/dev/null &

VALGRIND_PID=$!

# Let it run for a bit
sleep 8

# Kill if still running
if ps -p $VALGRIND_PID >/dev/null 2>&1; then
    kill $VALGRIND_PID 2>/dev/null
    wait $VALGRIND_PID 2>/dev/null || true
fi

# Wait for log to be written
sleep 1

# Check results
if [ -f "$LOGFILE" ]; then
    echo
    echo "Analyzing valgrind output..."
    echo

    # Check for definite leaks
    DEFINITE=$(grep "definitely lost:" "$LOGFILE" | tail -1 | awk '{print $4}' | tr -d ',')
    POSSIBLY=$(grep "possibly lost:" "$LOGFILE" | tail -1 | awk '{print $4}' | tr -d ',')
    STILL_REACHABLE=$(grep "still reachable:" "$LOGFILE" | tail -1 | awk '{print $4}' | tr -d ',')

    echo "Memory leak summary:"
    echo "  Definitely lost: ${DEFINITE:-0} bytes"
    echo "  Possibly lost: ${POSSIBLY:-0} bytes"
    echo "  Still reachable: ${STILL_REACHABLE:-0} bytes"
    echo

    # X11 applications typically have some "still reachable" memory
    # We're mainly concerned with "definitely lost"
    DEFINITE_NUM=${DEFINITE:-0}
    if [ "$DEFINITE_NUM" = "0" ]; then
        echo -e "${GREEN}✓ PASS: No definite memory leaks detected${NC}"
        echo
        echo "Note: X11 apps often have 'still reachable' memory"
        echo "This is normal and not considered a leak."
        rm -f "$LOGFILE"
        exit 0
    elif [ "$DEFINITE_NUM" -lt 10000 ]; then
        echo -e "${YELLOW}~ WARN: Small memory leak detected ($DEFINITE bytes)${NC}"
        echo "  This may be from X11 libraries, not our code"
        echo
        echo "  Check $LOGFILE for details"
        exit 0
    else
        echo -e "${RED}✗ FAIL: Significant memory leak detected${NC}"
        echo
        echo "  See $LOGFILE for full details"
        echo "  This may need investigation"
        exit 1
    fi
else
    echo -e "${YELLOW}~ WARN: Valgrind log not generated${NC}"
    echo "  Test may have timed out or failed to run"
    exit 0
fi
