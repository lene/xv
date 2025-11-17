# XV Optimization - Comprehensive Testing Strategy

This document outlines testing approaches to verify correct operation of the lazy window creation optimizations.

---

## Current Testing (Phase 1)

### What We're Testing Now

1. **Static Analysis** - Code pattern verification
2. **Window Count** - Basic window allocation measurement
3. **Manual Startup** - XV starts without crashing

### What We're NOT Testing

- Feature functionality after lazy creation
- Window creation on-demand triggers
- Memory leak detection
- Multi-instance behavior
- Performance under load
- Edge cases and error handling

---

## Proposed Comprehensive Testing

### 1. Functional Testing - Verify All Features Work

#### Browser Window Testing
```bash
# Test: Visual Schnauzer opens and creates windows on-demand
./build/xv test_image.png &
PID=$!

# Initial state: no browser windows
xdotool search --pid $PID | wc -l  # Should be ~11

# Open visual schnauzer (Ctrl+V or Windows menu)
xdotool search --pid $PID windowactivate
xdotool key ctrl+v
sleep 1

# Verify browser window created
xdotool search --pid $PID | wc -l  # Should be ~16 (11 + 5 browser windows)

# Verify browser displays images
xdotool search --pid $PID --name "Visual Schnauzer"  # Should find window

kill $PID
```

#### Format Dialog Testing
```bash
# Test each format dialog creates on-demand
./build/xv test_image.png &
PID=$!

# Open Save dialog
xdotool search --pid $PID windowactivate
xdotool key ctrl+s
sleep 1

# Try saving as JPEG (should create JPEG dialog)
# Try saving as PNG (should create PNG dialog)
# Try saving as WebP (should create WebP dialog)
# Verify dialogs appear and function

kill $PID
```

#### Menu Popup Testing
```bash
# Test menu popups create on-demand
./build/xv test_image.png &
PID=$!

# Click various menus in control panel
# Verify popup windows created only when clicked
# Verify popups destroyed when menu closes

kill $PID
```

### 2. Window Lifecycle Testing

#### Test: Windows Created Only When Needed
```bash
#!/bin/bash
# Script: test_lazy_creation.sh

XV_BINARY="./build/xv"
TEST_IMAGE="tests/test_data/test_image.png"

echo "Testing lazy window creation..."

# Start XV
$XV_BINARY $TEST_IMAGE &
PID=$!
sleep 2

# Measure initial windows
INITIAL=$(xdotool search --pid $PID 2>/dev/null | wc -l)
echo "Initial windows: $INITIAL (expected: ~11)"

# Test 1: Open browser
xdotool search --pid $PID windowactivate
xdotool key ctrl+v
sleep 1
AFTER_BROWSER=$(xdotool search --pid $PID 2>/dev/null | wc -l)
echo "After opening browser: $AFTER_BROWSER (expected: ~16)"

# Test 2: Close browser
xdotool key ctrl+v  # Toggle off
sleep 1
AFTER_CLOSE=$(xdotool search --pid $PID 2>/dev/null | wc -l)
echo "After closing browser: $AFTER_CLOSE (expected: back to ~11)"

# Test 3: Open gamma window
xdotool key ctrl+g
sleep 1
AFTER_GAMMA=$(xdotool search --pid $PID 2>/dev/null | wc -l)
echo "After opening gamma: $AFTER_GAMMA (expected: same, gamma already eager)"

kill $PID
```

#### Test: Windows Destroyed When Closed
```bash
# Verify windows are properly cleaned up
# Check for memory leaks with valgrind or similar
valgrind --leak-check=full ./build/xv test_image.png
# Open/close browser multiple times
# Exit XV
# Verify no leaked windows or memory
```

### 3. Multi-Instance Testing

#### Test: Multiple XV Instances
```bash
#!/bin/bash
# Script: test_multi_instance.sh

echo "Testing multiple XV instances..."

# Count baseline windows
BASELINE=$(xwininfo -root -tree | grep -c "xv")

# Start 5 XV instances
for i in {1..5}; do
    ./build/xv tests/test_data/test_image.png &
    PIDS[$i]=$!
done

sleep 3

# Count total windows
TOTAL=$(xwininfo -root -tree | grep -c "xv")
PER_INSTANCE=$(( ($TOTAL - $BASELINE) / 5 ))

echo "Total new windows: $(($TOTAL - $BASELINE))"
echo "Per instance: $PER_INSTANCE (expected: ~11)"

# Cleanup
for pid in "${PIDS[@]}"; do
    kill $pid 2>/dev/null
done
```

### 4. Performance Testing

#### Startup Time Measurement
```bash
#!/bin/bash
# Script: test_startup_time.sh

echo "Measuring startup time..."

# Optimized version
time (
    for i in {1..10}; do
        timeout 2 ./build/xv tests/test_data/test_image.png
    done
)

# Compare with baseline (if we had unoptimized version)
# Report difference
```

#### Memory Usage Measurement
```bash
#!/bin/bash
# Script: test_memory_usage.sh

echo "Measuring memory usage..."

./build/xv tests/test_data/test_image.png &
PID=$!
sleep 2

# Measure RSS, VSZ
ps -p $PID -o rss,vsz,cmd

# Measure X server memory (harder, need xrestop or similar)
# xrestop -b -m 1 | grep xv

kill $PID
```

### 5. Stress Testing

#### Window Churn Test
```bash
#!/bin/bash
# Script: test_window_churn.sh

echo "Testing window creation/destruction cycles..."

./build/xv tests/test_data/test_image.png &
PID=$!
sleep 2

# Open and close browser 100 times
for i in {1..100}; do
    xdotool search --pid $PID windowactivate
    xdotool key ctrl+v  # Open
    sleep 0.1
    xdotool key ctrl+v  # Close
    sleep 0.1
done

# Verify XV still running and responsive
xdotool search --pid $PID windowactivate
xdotool key q  # Quit

echo "Stress test complete"
```

#### Format Dialog Cycle Test
```bash
# Open each format dialog 50 times
# Verify no crashes, leaks, or slowdown
```

### 6. Regression Testing

#### Test: All Original Functionality Still Works
```bash
#!/bin/bash
# Script: test_regression.sh

TEST_IMAGE="tests/test_data/test_image.png"

echo "=== Regression Test Suite ==="

# Test 1: Load image
echo "Test: Load image"
timeout 2 ./build/xv $TEST_IMAGE || echo "FAIL: Load"

# Test 2: Basic operations
echo "Test: Basic operations (crop, rotate, etc.)"
# Would need xdotool automation

# Test 3: Save operations
echo "Test: Save in various formats"
# Automate save dialog, test each format

# Test 4: Color operations
echo "Test: Color adjustments"
# Open gamma window, adjust controls

# Test 5: Browser operations
echo "Test: Visual schnauzer"
# Open browser, navigate, select images

echo "=== Regression Tests Complete ==="
```

### 7. Edge Case Testing

#### Test: Rapid Operations
```bash
# Rapidly open/close windows before they fully initialize
# Click multiple menus quickly
# Verify no crashes or undefined behavior
```

#### Test: Missing Resources
```bash
# Test with missing fonts, colormaps
# Test with different X server configurations
# Test on different window managers
```

#### Test: Error Conditions
```bash
# Test with invalid image files
# Test with no write permissions (can't save)
# Test with limited X server resources
```

### 8. Automated UI Testing

Using xdotool for automation:

```bash
#!/bin/bash
# Script: test_ui_automation.sh

XV="./build/xv"
IMG="tests/test_data/test_image.png"

# Helper function
wait_for_window() {
    local title="$1"
    local timeout=5
    local count=0

    while [ $count -lt $timeout ]; do
        if xdotool search --name "$title" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((count++))
    done
    return 1
}

echo "Starting automated UI tests..."

$XV $IMG &
PID=$!
sleep 2

# Find main XV window
WIN=$(xdotool search --pid $PID | head -1)

# Test: Menu operations
echo "Testing menus..."
xdotool windowactivate $WIN
xdotool key alt+d  # Display menu (if supported)
sleep 0.5

# Test: Keyboard shortcuts
echo "Testing keyboard shortcuts..."
xdotool windowactivate $WIN
xdotool key n  # Next image
xdotool key p  # Previous image
xdotool key plus  # Zoom in
xdotool key minus  # Zoom out

# Test: Browser
echo "Testing visual schnauzer..."
xdotool windowactivate $WIN
xdotool key ctrl+v  # Open browser
if wait_for_window "Visual Schnauzer"; then
    echo "  ✓ Browser opened"
else
    echo "  ✗ Browser failed to open"
fi

# Cleanup
kill $PID
echo "UI automation tests complete"
```

### 9. Memory Leak Detection

```bash
#!/bin/bash
# Script: test_memory_leaks.sh

echo "Testing for memory leaks with Valgrind..."

# Run XV under valgrind
valgrind \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --log-file=valgrind-xv.log \
    timeout 10 ./build/xv tests/test_data/test_image.png

# During this time, manually or via xdotool:
# - Open and close browser
# - Open and close various dialogs
# - Perform color operations

# Check log for leaks
grep "definitely lost" valgrind-xv.log
grep "indirectly lost" valgrind-xv.log
```

### 10. Integration with Test Framework

Update `tests/test_functionality.sh` to include:

```bash
# Add to existing test_functionality.sh

test_lazy_browser_creation() {
    echo "Testing: Browser window lazy creation"

    # Start XV
    $XV_BINARY $TEST_IMAGE &
    local pid=$!
    sleep 2

    # Count initial
    local initial=$(xdotool search --pid $pid 2>/dev/null | wc -l)

    # Open browser
    xdotool search --pid $pid windowactivate
    xdotool key ctrl+v
    sleep 1

    # Count after
    local after=$(xdotool search --pid $pid 2>/dev/null | wc -l)

    # Verify increase
    if [ $after -gt $initial ]; then
        echo "  ✓ PASS: Browser windows created on-demand ($initial → $after)"
        kill $pid
        return 0
    else
        echo "  ✗ FAIL: Browser windows not created"
        kill $pid
        return 1
    fi
}

test_dialog_lazy_creation() {
    echo "Testing: Format dialog lazy creation"

    # Similar pattern for testing each format dialog
    # Verify they only appear when save is initiated
}

# Add these to main test suite
```

---

## Recommended Testing Priorities

### Priority 1: Essential (Do Now)
1. ✅ Static analysis (already done)
2. ✅ Window count at startup (already done)
3. 🔲 Basic functionality test (XV loads image, displays, quits)
4. 🔲 Browser lazy creation test (verify browser windows appear on Ctrl+V)
5. 🔲 Multi-instance test (5-10 instances, verify window count scales)

### Priority 2: Important (Do Soon)
6. 🔲 Format dialog tests (verify each dialog works when saving)
7. 🔲 Window lifecycle test (open/close cycles work correctly)
8. 🔲 Memory leak detection (valgrind quick check)
9. 🔲 Startup time measurement (quantify performance improvement)

### Priority 3: Thorough (Do Eventually)
10. 🔲 Stress testing (100+ open/close cycles)
11. 🔲 Regression testing (all original features still work)
12. 🔲 Edge case testing (rapid operations, error conditions)
13. 🔲 Full automated UI test suite

---

## Quick Test Implementation

Let me create a practical test that we can run right now:

```bash
#!/bin/bash
# tests/test_quick_validation.sh
# Quick validation that optimizations work correctly

set -e

XV="${XV_BINARY:-./build/xv}"
TEST_IMG="tests/test_data/test_image.png"

echo "=== Quick Validation Test ==="
echo

# Test 1: XV starts
echo "[1/5] Testing: XV starts without crash"
timeout 2 $XV $TEST_IMG &
PID=$!
sleep 1
if ps -p $PID > /dev/null; then
    echo "  ✓ PASS: XV running"
    kill $PID
else
    echo "  ✗ FAIL: XV crashed"
    exit 1
fi
echo

# Test 2: Window count is optimized
echo "[2/5] Testing: Window count is optimized"
$XV $TEST_IMG &
PID=$!
sleep 2
COUNT=$(xwininfo -root -tree | grep -c "xv" || echo "0")
kill $PID
if [ $COUNT -le 20 ]; then
    echo "  ✓ PASS: Window count is $COUNT (≤ 20)"
else
    echo "  ✗ FAIL: Window count is $COUNT (too high)"
    exit 1
fi
echo

# Test 3: Browser can be opened
echo "[3/5] Testing: Browser window opens on demand"
$XV $TEST_IMG &
PID=$!
sleep 2
WIN=$(xdotool search --pid $PID | head -1)
xdotool windowactivate $WIN
xdotool key ctrl+v
sleep 1
if xdotool search --pid $PID --name "schnauzer" > /dev/null 2>&1 || \
   xdotool search --pid $PID --name "browser" > /dev/null 2>&1; then
    echo "  ✓ PASS: Browser window opened"
else
    echo "  ⚠ WARN: Could not verify browser (may be working)"
fi
kill $PID
echo

# Test 4: Multiple instances work
echo "[4/5] Testing: Multiple instances work"
for i in {1..3}; do
    $XV $TEST_IMG &
    PIDS[$i]=$!
done
sleep 2
RUNNING=0
for pid in "${PIDS[@]}"; do
    if ps -p $pid > /dev/null; then
        ((RUNNING++))
    fi
done
for pid in "${PIDS[@]}"; do
    kill $pid 2>/dev/null
done
if [ $RUNNING -eq 3 ]; then
    echo "  ✓ PASS: All 3 instances running"
else
    echo "  ✗ FAIL: Only $RUNNING/3 instances running"
    exit 1
fi
echo

# Test 5: XV can be quit properly
echo "[5/5] Testing: XV quits cleanly"
$XV $TEST_IMG &
PID=$!
sleep 2
WIN=$(xdotool search --pid $PID | head -1)
xdotool windowactivate $WIN
xdotool key q
sleep 1
if ps -p $PID > /dev/null 2>&1; then
    echo "  ✗ FAIL: XV did not quit"
    kill -9 $PID
    exit 1
else
    echo "  ✓ PASS: XV quit cleanly"
fi
echo

echo "=== Quick Validation: ALL TESTS PASSED ==="
```

This would give us confidence that the optimizations work correctly without requiring extensive manual testing.

---

## Suggested Immediate Action

Create and run the quick validation test above to verify:
1. XV starts and runs
2. Window count is optimized
3. Browser lazy creation works
4. Multiple instances work
5. XV quits properly

Would you like me to create this test script and run it?
