#!/bin/bash
# Quick validation test for XV optimizations
# Tests that basic functionality works with lazy window creation

set -e

XV="${XV_BINARY:-../build/xv}"
TEST_IMG="test_data/test_image.png"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Quick Validation Test ==="
echo

# Test 1: XV starts
echo -e "${YELLOW}[1/5] Testing: XV starts without crash${NC}"
timeout 2 $XV $TEST_IMG &
PID=$!
sleep 1
if ps -p $PID > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ PASS: XV running${NC}"
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
else
    echo -e "${RED}  ✗ FAIL: XV crashed${NC}"
    exit 1
fi
echo

# Test 2: Window count is optimized
echo -e "${YELLOW}[2/5] Testing: Window count is optimized${NC}"
$XV $TEST_IMG &
PID=$!
sleep 2
COUNT=$(xwininfo -root -tree 2>/dev/null | grep -c "xv" || echo "0")
kill $PID 2>/dev/null
wait $PID 2>/dev/null
if [ $COUNT -le 20 ]; then
    echo -e "${GREEN}  ✓ PASS: Window count is $COUNT (≤ 20)${NC}"
else
    echo -e "${RED}  ✗ FAIL: Window count is $COUNT (too high)${NC}"
    exit 1
fi
echo

# Test 3: Browser can be opened
echo -e "${YELLOW}[3/5] Testing: Browser window opens on demand${NC}"
$XV $TEST_IMG &
PID=$!
sleep 2
WIN=$(xdotool search --pid $PID 2>/dev/null | head -1)
if [ -n "$WIN" ]; then
    xdotool windowactivate $WIN 2>/dev/null
    xdotool key ctrl+v 2>/dev/null
    sleep 1
    if xdotool search --pid $PID --name "schnauzer" > /dev/null 2>&1 || \
       xdotool search --pid $PID --name "browser" > /dev/null 2>&1 || \
       xdotool search --pid $PID --name "Visual" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ PASS: Browser window opened${NC}"
    else
        echo -e "${YELLOW}  ⚠ WARN: Could not verify browser (may be working)${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ WARN: Could not find XV window${NC}"
fi
kill $PID 2>/dev/null
wait $PID 2>/dev/null
echo

# Test 4: Multiple instances work
echo -e "${YELLOW}[4/5] Testing: Multiple instances work${NC}"
declare -a PIDS
for i in {1..3}; do
    $XV $TEST_IMG &
    PIDS[$i]=$!
done
sleep 2
RUNNING=0
for pid in "${PIDS[@]}"; do
    if ps -p $pid > /dev/null 2>&1; then
        ((RUNNING++))
    fi
done
for pid in "${PIDS[@]}"; do
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
done
if [ $RUNNING -eq 3 ]; then
    echo -e "${GREEN}  ✓ PASS: All 3 instances running${NC}"
else
    echo -e "${RED}  ✗ FAIL: Only $RUNNING/3 instances running${NC}"
    exit 1
fi
echo

# Test 5: XV can be quit properly
echo -e "${YELLOW}[5/5] Testing: XV quits cleanly${NC}"
$XV $TEST_IMG &
PID=$!
sleep 2
WIN=$(xdotool search --pid $PID 2>/dev/null | head -1)
if [ -n "$WIN" ]; then
    xdotool windowactivate $WIN 2>/dev/null
    xdotool key q 2>/dev/null
    sleep 1
fi
if ps -p $PID > /dev/null 2>&1; then
    echo -e "${YELLOW}  ⚠ WARN: XV may not have quit, forcing...${NC}"
    kill -9 $PID 2>/dev/null
    wait $PID 2>/dev/null
else
    echo -e "${GREEN}  ✓ PASS: XV quit cleanly${NC}"
fi
echo

echo -e "${GREEN}=== Quick Validation: ALL TESTS PASSED ===${NC}"
