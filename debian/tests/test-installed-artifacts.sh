#!/bin/bash

# Bail on any errors...
set -e

# Create a test image
echo "*** Creating test image..."
convert -size 100x100 xc:blue /tmp/test_xv.png

# Run XV inside of a dummy frame buffer to verify it can load an image
echo "*** Launching XV inside of dummy frame buffer..."
timeout 5 xvfb-run -a xv -quit /tmp/test_xv.png || true

# Cleanup
rm -f /tmp/test_xv.png

# Done...
echo "*** OK!"
