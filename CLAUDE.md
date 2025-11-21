# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XV is a classic image viewer for X11 originally written by John Bradley in 1989-1994. This repository contains a modernized fork maintained by Michael Adams (jasper-software) with numerous improvements including CMake build support, merged patches from various distributions, and ongoing optimizations.

**Current version:** 6.0.4-20250821

## Build System

XV uses CMake as the officially recommended build system.

### Building XV

Standard build process:
```bash
# Configure build in tmp_cmake directory
cmake -H. -Btmp_cmake -DCMAKE_INSTALL_PREFIX=/usr/local

# Build
cmake --build tmp_cmake

# Install
cmake --build tmp_cmake --target install
```

### Build Options

Configure format support via CMake options (all default to ON):
- `XV_ENABLE_JPEG` - JPEG support
- `XV_ENABLE_JP2K` - JPEG-2000 support (requires JasPer library)
- `XV_ENABLE_PNG` - PNG support
- `XV_ENABLE_TIFF` - TIFF support
- `XV_ENABLE_WEBP` - WebP support
- `XV_ENABLE_G3` - G3 fax format support
- `XV_ENABLE_PDS` - PDF support
- `XV_ENABLE_XRANDR` - XRandR support

Example with custom options:
```bash
cmake -H. -Btmp_cmake -DXV_ENABLE_JPEG=OFF -DXV_ENABLE_TIFF=OFF
```

### Dependencies

Required libraries:
- X11 development libraries (libx11-dev, libxt-dev)
- Math library (libm)

Optional libraries (based on enabled features):
- libjpeg (for JPEG)
- libjasper (for JPEG-2000)
- libpng (for PNG)
- libtiff (for TIFF)
- libwebp (for WebP)
- libxrandr (for XRandR support)

## Debian Packaging

### Building a Debian Package

```bash
# Install build dependencies
sudo apt-get install build-essential debhelper devscripts cmake pkg-config \
    libx11-dev libxt-dev libtiff-dev libjpeg-dev libpng-dev libxrandr-dev libwebp-dev

# Build the package
dpkg-buildpackage -us -uc -b

# Install the package
sudo dpkg -i ../xv_*.deb
```

### Package Structure

```
debian/
├── changelog      # Version history
├── control        # Package metadata and dependencies
├── copyright      # License information
├── rules          # CMake-based build rules
├── tests/         # DEP-8 autopkgtest tests
│   ├── control
│   └── test-installed-artifacts.sh
└── watch          # Upstream version tracking
```

### Distribution

- **Target**: Ubuntu 24.04 (Noble Numbat)
- **Upstream**: https://github.com/jasper-software/xv
- **Version**: 6.0.4-2~noble

## Testing

### Test Suite Location

All tests are in the `tests/` directory:
- `run_tests.sh` - Main test runner
- `test_static_analysis.sh` - Source code analysis (no X11 required)
- `test_window_count.sh` - X window allocation measurement
- `test_functionality.sh` - Runtime functional tests

### Running Tests

**Static analysis only (no X11 needed):**
```bash
./tests/test_static_analysis.sh
```

**Full test suite (requires X11):**
```bash
# With existing X display
./tests/run_tests.sh

# Using virtual X server (headless)
xvfb-run -a ./tests/run_tests.sh
```

**Individual test categories:**
```bash
./tests/run_tests.sh --window-count-only
./tests/run_tests.sh --functional-only
```

### Test Requirements

For runtime tests, you need:
- X11 display server (or Xvfb)
- xwininfo (for window counting)
- xdotool (for automation)
- Built XV binary

## Architecture

### High-Level Overview

XV is a traditional X11 application built with raw Xlib (pre-dating modern toolkits like GTK/Qt). It follows 1980s-1990s X Window System design patterns where each UI element is a separate X window.

### Major Components

**Core Source Files:**
- `xv.c` - Main program, event loop, initialization
- `xvevent.c` - X event handling
- `xvmisc.c` - Miscellaneous utility functions
- `xvimage.c` - Image loading and display

**UI Components:**
- `xvctrl.c` - Control panel window with buttons/menus
- `xvdir.c` - Directory browser window
- `xvinfo.c` - Info window
- `xvbrowse.c` - Visual schnauzer (image browser)
- `xvgam.c` - Gamma/color editor window
- `xvtext.c` - Text viewer windows

**Widget System:**
- `xvbutt.c` - Button and menu button widgets
- `xvdial.c` - Dial/slider widgets
- `xvscrl.c` - Scrollbar widgets
- `xvgraf.c` - Graph widgets

**Format Handlers:**
- `xvjpeg.c` / `xvjp2k.c` - JPEG formats
- `xvpng.c` - PNG format
- `xvtiff.c` / `xvtiffwr.c` - TIFF format
- `xvwebp.c` - WebP format
- `xvgif.c` / `xvgifwr.c` - GIF format
- `xvbmp.c`, `xvpcx.c`, `xvpbm.c`, etc. - Various other formats

**PostScript/Printing:**
- `xvps.c` - PostScript output dialog

### Resource Allocation Architecture

**Critical Background:** XV originally created ~140 X windows per instance because of its 1989-era architecture where every UI element (button, slider, etc.) is a separate X window. This caused severe performance issues on modern compositing window managers.

**Optimization Strategy:** The codebase has been optimized to use lazy window creation - windows are only created when actually needed, not at startup.

### Lazy Creation Patterns

**Browser Windows** (`xvbrowse.c`):
- Originally: All 16 browser slots pre-allocated at startup (80 windows)
- Now: Browser windows initialized to `None`, created on-demand via `createBrowserWindow()`
- Check pattern: `if (br->win == None)` before creating

**Format Dialog Windows** (`xv.c`, format-specific files):
- Originally: All format dialogs created eagerly in `main()`
- Now: Created on-demand when user saves in that format
- Example: JPEG dialog created in `DoSave()` when needed

**Gamma/Color Editor** (`xvgam.c`):
- Originally: Created at startup (18 windows)
- Now: Parameters saved via `SaveGamParams()`, window created when first opened

**Menu Button Popups** (`xvbutt.c`):
- Originally: Popup windows created in `MBCreate()`
- Now: Initialized to `None`, created in `createMBPopupWindow()` on first use

**PostScript Dialog** (`xvps.c`):
- Originally: Created at startup
- Now: Created on-demand when user initiates PS save

## Code Style and Conventions

### Language

- Written in C (C99 preferred but not required)
- Uses raw Xlib API (X11/Xlib.h)
- Pre-ANSI compatibility maintained for some systems

### Naming Conventions

- Global functions: CamelCase (e.g., `CreateBrowse()`, `BTCreate()`)
- Static/local functions: camelCase or lowercase_with_underscores
- Window variables: descriptive names ending in `W` (e.g., `ctrlW`, `gamW`)
- Widget structures: descriptive names (e.g., `bp` for button pointer, `mb` for menu button)

### Memory Management

- Manual memory management (malloc/free)
- X resources must be freed explicitly (XDestroyWindow, XFreeGC, etc.)
- Many global variables for UI state

### Error Handling

- Use `FatalError()` for unrecoverable errors
- Use `SetISTR()` for user-visible error messages in info window
- Many functions return void, use side effects for status

## Key Implementation Details

### Window Initialization

All dialog/component windows should be initialized to `None` (0) before lazy creation:
```c
Window myDialogWindow = None;
```

Check before operations:
```c
if (myDialogWindow == None) {
    createMyDialog();  // Create on first use
}
```

### Button and Widget Patterns

Buttons created with `BTCreate()` draw into parent window (no separate X window).

Menu buttons use `MBCreate()` with lazy popup creation:
```c
void MBCreate(MBUTT *mb, ...) {
    mb->mwin = None;  // Popup created on-demand
    // ... other initialization
}
```

### Event Loop

Main event loop in `xv.c:mainLoop()` handles all X events. When adding new windows:
1. Register appropriate event masks
2. Add handlers in event switch statement
3. Update window tracking data structures

### Global State

Many UI components store state in global variables declared in `xv.c` and `extern`'d in `xv.h`. When adding new components, follow this pattern.

## Important Investigation Documents

The repository contains detailed analysis documents from optimization work:

- `X_WINDOW_ALLOCATION_ANALYSIS.md` - Complete breakdown of window allocation (142 windows identified)
- `XV-WINDOW-COUNT-INVESTIGATION.md` - Investigation of Cinnamon freeze issues caused by excessive windows
- `TESTING_SUMMARY.md` - Test suite implementation and status
- `RUNTIME_TESTING_STATUS.md` - Runtime testing status and known issues

These documents provide critical context for understanding the window allocation optimizations and performance characteristics.

## Common Development Workflows

### Adding a New Image Format

1. Create `xvNEWFORMAT.c` with load/save functions
2. Add format detection in `xv.c:ReadFileType()`
3. Add to build system in `src/CMakeLists.txt`
4. Add format dialog if needed (use lazy creation pattern)
5. Update format menu in `xvctrl.c`

### Modifying Window Creation

When changing window creation code:
1. Verify lazy creation pattern is maintained
2. Ensure window initialized to `None`
3. Add NULL/None checks before operations
4. Document the lazy creation in comments
5. Test with `test_window_count.sh` to verify window count reduction

### Debugging Window Issues

Common issues and solutions:
- **Segfault in widget code**: Check if window is `None` before operations
- **Window not appearing**: Verify creation function called before mapping
- **Event not received**: Check event mask registration
- **Resource leak**: Verify `XDestroyWindow()` called in cleanup

### Working with the Test Suite

Static analysis validates code patterns:
```bash
# Check all optimizations are present
./tests/test_static_analysis.sh
```

Runtime tests require full X11 environment:
```bash
# Build with debugging
cmake -H. -Btmp_cmake -DCMAKE_BUILD_TYPE=Debug

# Run with virtual X server
xvfb-run -a ./tests/run_tests.sh
```

## Known Issues and Limitations

### Runtime Segfault in Optimized Build

The optimized code with lazy window creation passes static analysis but has a runtime segfault during early initialization (in `BTRedraw()` during color map setup). This appears to be an initialization order dependency that needs investigation with proper debugging tools on real hardware.

Workaround: Test on real X11 system (not Xvfb) with full library support.

### Compositor Performance

XV's multi-window architecture (even optimized) can stress modern compositors:
- Muffin (Cinnamon): Poor scaling beyond 1,000 windows
- Mutter (GNOME): Better scaling but still degrades
- Non-compositing WMs (Openbox, etc.): No issues

### Missing Libraries

Some format support requires optional libraries. Build will disable features if libraries not found:
- Missing libjasper → JP2K disabled
- Missing libtiff → TIFF disabled
- etc.

Check CMake output to see which features are enabled.

## Resources

- **Main repository:** https://github.com/jasper-software/xv
- **Original XV site:** https://xv.trilon.com
- **Wikipedia:** https://en.wikipedia.org/wiki/Xv_(software)
- **Jumbo patches:** Various community patches merged into this fork

## Git Workflow

This repository uses standard Git workflow:
- `main` branch for stable releases
- Feature branches for development (e.g., `claude/optimize-resource-allocation-*`)
- GitHub Actions CI for automated builds on Ubuntu and macOS with GCC and Clang

Current branch structure indicates active optimization work on window allocation.
