# XV Optimization Test Suite

This directory contains automated tests to verify the X window allocation optimizations (Phase 1 and Phase 2) and ensure continued correct operation of XV.

## Overview

The XV optimization project reduced X window allocation from ~142 windows to ~8 windows at startup (94% reduction). These tests verify:

1. **Resource Savings**: Window count is within the optimized range
2. **Functionality**: All lazy-loaded features work correctly

## Test Suites

### 1. Window Count Test (`test_window_count.sh`)

**Purpose**: Measures X window allocation at XV startup

**What it tests**:
- Counts total X windows created by XV at launch
- Verifies count is within expected range (5-15 windows)
- Calculates savings compared to baseline (~142 windows)

**Expected results**:
- Before optimizations: ~142 windows
- After Phase 1 + 2: ~8 windows
- Test passes if: 5 ≤ window_count ≤ 15

### 2. Functional Test (`test_functionality.sh`)

**Purpose**: Verifies lazy-loaded features work correctly

**What it tests**:
1. Initial window count is low
2. Browser windows create on-demand when opened
3. Gamma/color editor creates on-demand when opened
4. Format dialogs create on-demand when saving
5. Menu button popups work correctly
6. XV remains responsive after all operations
7. Window count remains optimized after operations

**Test methodology**:
- Uses `xdotool` to simulate user interactions
- Monitors window count before/after each operation
- Verifies windows are created only when needed

## Requirements

### System Requirements

- **X11 server**: Tests must run in an X11 environment
- **Operating System**: Linux with X11 or Xvfb

### Required Tools

```bash
# Ubuntu/Debian
sudo apt-get install x11-utils xdotool imagemagick

# Fedora/RHEL
sudo dnf install xorg-x11-utils xdotool ImageMagick

# Arch Linux
sudo pacman -S xorg-xwininfo xdotool imagemagick
```

**Tool descriptions**:
- `xwininfo`: X window information utility (window counting)
- `xdotool`: X automation tool (simulating user input)
- `imagemagick`: Image manipulation (creating test images)

### Build Requirements

XV must be built before running tests:

```bash
mkdir -p build && cd build
cmake ..
make
```

## Running Tests

### Quick Start

Run all tests:

```bash
cd tests
chmod +x run_tests.sh
./run_tests.sh
```

### Individual Test Suites

Run only window count test:

```bash
./run_tests.sh --window-count-only
```

Run only functional tests:

```bash
./run_tests.sh --functional-only
```

### Using Xvfb (Headless Testing)

For CI/CD or headless environments:

```bash
# Install Xvfb
sudo apt-get install xvfb

# Run tests in virtual framebuffer
xvfb-run -a ./run_tests.sh
```

### Verbose Output

```bash
./run_tests.sh --verbose
```

## Test Output

### Successful Run

```
=========================================
XV Optimization Test Suite
=========================================

Checking prerequisites...
✓ X11 display available: :0
✓ xwininfo available
✓ xdotool available
✓ XV binary found

Running tests...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Suite 1: Window Count Measurement
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total windows allocated: 8

✓ PASS: Window count is within expected range (5-15)
  Saved: 134 windows (94% reduction)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Suite 2: Functional Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Testing: Initial window allocation
  ✓ PASS: Initial windows (8) within optimized range

Testing: Browser window lazy creation
  ✓ PASS: Browser window created on-demand (+5 windows)

Testing: Gamma window lazy creation
  ✓ PASS: Gamma window created on-demand (+18 windows)

...

=========================================
Final Results
=========================================
✓ ALL TESTS PASSED
```

## Optimization Details

### Phase 1: Lazy Allocation (117 windows saved)

1. **Browser Windows** - 80 windows saved
   - Before: All 16 browser windows created at startup
   - After: Created only when browser is opened
   - Test: Opens browser, verifies window creation

2. **Format Dialogs** - ~15 windows saved
   - Before: All format dialogs (JPEG, PNG, etc.) created at startup
   - After: Created when saving in specific format
   - Test: Opens save dialog, checks window count

3. **Gamma Window** - 18 windows saved
   - Before: Color editor created at startup
   - After: Created when user opens color editor
   - Test: Opens gamma dialog, verifies creation

4. **PostScript Dialog** - 4 windows saved
   - Before: PS dialog created at startup
   - After: Created when saving to PS format
   - Test: Included in save dialog test

### Phase 2: Menu Button Popups (17 windows saved)

1. **Menu Button Popups** - ~17 windows saved
   - Before: All menu popup windows created at startup
   - After: Created when menu button is clicked
   - Test: Clicks menus, verifies popups work

## Troubleshooting

### "No X11 display available"

**Solution**: Run in X11 environment or use Xvfb:

```bash
xvfb-run -a ./run_tests.sh
```

### "xdotool not found"

**Solution**: Install xdotool:

```bash
sudo apt-get install xdotool
```

### "XV binary not found"

**Solution**: Build XV first:

```bash
cd .. && mkdir -p build && cd build
cmake .. && make
cd ../tests
```

### Tests fail with "Too many windows"

**Possible causes**:
1. Optimizations not applied correctly
2. Running older XV version
3. Window counting includes other applications

**Debug**:

```bash
# Check git branch
git status

# Verify optimizations are present
grep "lazy creation" ../src/xvbrowse.c ../src/xvbutt.c

# Run window count test manually
./test_window_count.sh
```

### Functional tests skip all tests

**Possible causes**:
1. No test image available
2. XV keyboard shortcuts differ
3. XV built without certain features

**Solution**: Tests will skip unavailable features. This is normal if:
- XV built without browser support
- XV built without certain format support
- Test image creation failed

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: XV Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y xvfb x11-utils xdotool \
            cmake build-essential libx11-dev libxt-dev

      - name: Build XV
        run: |
          mkdir -p build && cd build
          cmake ..
          make

      - name: Run tests
        run: |
          cd tests
          chmod +x run_tests.sh
          xvfb-run -a ./run_tests.sh
```

## Manual Testing

For manual verification beyond automated tests:

### Verify Window Count Manually

```bash
# Start XV
./build/xv &
XV_PID=$!

# Count windows
xdotool search --pid $XV_PID | wc -l

# Should show ~8 windows
```

### Verify Lazy Creation Manually

1. Start XV: `./build/xv`
2. Open browser (Ctrl+B) - windows should increase
3. Open gamma editor (Ctrl+E) - windows should increase
4. Open save dialog (Ctrl+S) - verify format dialogs work
5. Click menu buttons - verify menus appear

### Performance Testing

```bash
# Measure startup time
time ./build/xv test_image.png

# Compare with unoptimized version
# Optimized version should start faster
```

## Contributing

When adding new optimizations:

1. Update expected window counts in `test_window_count.sh`
2. Add functional tests for new lazy-loaded features
3. Update this README with optimization details
4. Ensure all tests pass before committing

## License

Same as XV (distributable, see main LICENSE file)
