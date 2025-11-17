#!/bin/bash
# Static analysis test - verifies optimizations are present in source code
# Can run without X11 or compiled binary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/../src"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
    echo -e "${GREEN}  ✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}  ✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "========================================="
echo "XV Static Code Analysis"
echo "========================================="
echo "Verifying optimizations are present in source code"
echo

# Test 1: Browser window lazy creation
echo -e "${BLUE}[1] Checking browser window lazy creation...${NC}"

if grep -q "br->win = (Window) None" "$SRC_DIR/xvbrowse.c"; then
    test_pass "Browser windows initialized to None (lazy creation)"
else
    test_fail "Browser windows not using lazy creation"
fi

if grep -q "createBrowserWindow" "$SRC_DIR/xvbrowse.c"; then
    test_pass "createBrowserWindow helper function exists"
else
    test_fail "Missing createBrowserWindow function"
fi

echo

# Test 2: Menu button popup lazy creation
echo -e "${BLUE}[2] Checking menu button popup lazy creation...${NC}"

if grep -q "mb->mwin = None" "$SRC_DIR/xvbutt.c"; then
    test_pass "Menu button popups initialized to None (lazy creation)"
else
    test_fail "Menu button popups not using lazy creation"
fi

if grep -q "createMBPopupWindow" "$SRC_DIR/xvbutt.c"; then
    test_pass "createMBPopupWindow helper function exists"
else
    test_fail "Missing createMBPopupWindow function"
fi

if grep -q "if (mb->mwin != None)" "$SRC_DIR/xvbutt.c"; then
    test_pass "Menu button popup check before operations"
else
    test_fail "Missing popup window existence checks"
fi

echo

# Test 3: Gamma window lazy creation
echo -e "${BLUE}[3] Checking gamma window lazy creation...${NC}"

if grep -q "SaveGamParams" "$SRC_DIR/xvgam.c"; then
    test_pass "SaveGamParams function for lazy gamma creation"
else
    test_fail "Missing SaveGamParams function"
fi

if grep -q "saved_gam_geom" "$SRC_DIR/xvgam.c"; then
    test_pass "Gamma window parameters saved for deferred creation"
else
    test_fail "Missing gamma window parameter storage"
fi

echo

# Test 4: Format dialogs lazy creation
echo -e "${BLUE}[4] Checking format dialog lazy creation...${NC}"

# Check that format dialogs are created on-demand in xvdir.c
if grep -q "if (jpegW == None)" "$SRC_DIR/xvdir.c" 2>/dev/null; then
    test_pass "JPEG dialog created on-demand"
else
    test_fail "JPEG dialog not using lazy creation"
fi

if grep -q "if (pngW == None)" "$SRC_DIR/xvdir.c" 2>/dev/null; then
    test_pass "PNG dialog created on-demand"
else
    test_fail "PNG dialog not using lazy creation (may not be compiled in)"
fi

echo

# Test 5: PostScript dialog lazy creation
echo -e "${BLUE}[5] Checking PostScript dialog lazy creation...${NC}"

if grep -q "if (psW == None)" "$SRC_DIR/xvdir.c"; then
    test_pass "PS dialog created on-demand"
else
    test_fail "PS dialog not using lazy creation"
fi

echo

# Test 6: Check for eager allocation patterns (should be removed)
echo -e "${BLUE}[6] Checking for removed eager allocation...${NC}"

# Check that format dialogs are NOT created at startup in xv.c
EAGER_COUNT=0

# Look for CreateJPEGW() at startup (should be commented out or removed)
if grep -E "^\s*CreateJPEGW\(\)" "$SRC_DIR/xv.c" | grep -v "^[[:space:]]*//"; then
    test_fail "CreateJPEGW() still called at startup"
    EAGER_COUNT=$((EAGER_COUNT + 1))
fi

if grep -E "^\s*CreatePNGW\(\)" "$SRC_DIR/xv.c" | grep -v "^[[:space:]]*//"; then
    test_fail "CreatePNGW() still called at startup"
    EAGER_COUNT=$((EAGER_COUNT + 1))
fi

if grep -E "^\s*CreatePSD\(\)" "$SRC_DIR/xv.c" | grep -v "^[[:space:]]*//"; then
    test_fail "CreatePSD() still called at startup"
    EAGER_COUNT=$((EAGER_COUNT + 1))
fi

if [ $EAGER_COUNT -eq 0 ]; then
    test_pass "Format dialogs not eagerly created at startup"
fi

echo

# Test 7: Check for lazy creation comments
echo -e "${BLUE}[7] Checking for documentation...${NC}"

COMMENT_COUNT=0

if grep -qi "lazy creation" "$SRC_DIR/xvbrowse.c"; then
    test_pass "Browser lazy creation documented"
    COMMENT_COUNT=$((COMMENT_COUNT + 1))
fi

if grep -qi "lazy creation" "$SRC_DIR/xvbutt.c"; then
    test_pass "Menu button lazy creation documented"
    COMMENT_COUNT=$((COMMENT_COUNT + 1))
fi

if grep -qi "lazy creation\|deferred.*creation" "$SRC_DIR/xvgam.c"; then
    test_pass "Gamma window lazy creation documented"
    COMMENT_COUNT=$((COMMENT_COUNT + 1))
fi

if [ $COMMENT_COUNT -lt 3 ]; then
    echo -e "${YELLOW}  ⚠ Some optimizations lack documentation comments${NC}"
fi

echo

# Summary
echo "========================================="
echo "Static Analysis Summary"
echo "========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All optimizations verified in source code${NC}"
    echo
    echo "Optimizations detected:"
    echo "  • Browser window lazy creation (Phase 1)"
    echo "  • Format dialog lazy creation (Phase 1)"
    echo "  • Gamma window lazy creation (Phase 1)"
    echo "  • PostScript dialog lazy creation (Phase 1)"
    echo "  • Menu button popup lazy creation (Phase 2)"
    exit 0
else
    echo -e "${RED}✗ Some optimizations missing or incomplete${NC}"
    exit 1
fi
