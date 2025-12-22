#!/bin/bash
# Notification hook - Called when Claude is idle waiting for input (60+ seconds)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read STDIN and pass it to the helper script
cat | "$SCRIPT_DIR/session-state-helper.rb" waiting

exit 0
