#!/bin/bash
# Quick test to check if XV starts

cd /home/user/xv

# Try starting XV without image
echo "Attempting to start XV without image..."
xvfb-run -a timeout 3 ./build/xv 2>&1 &
XV_PID=$!
sleep 2

if kill -0 $XV_PID 2>/dev/null; then
    echo "✓ XV is running"
    WINDOW_COUNT=$(xvfb-run -a xdotool search --pid $XV_PID 2>/dev/null | wc -l)
    echo "Windows created: $WINDOW_COUNT"
    kill $XV_PID 2>/dev/null
    wait $XV_PID 2>/dev/null
else
    echo "✗ XV crashed or exited"
fi
