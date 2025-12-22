#!/bin/bash
# PostToolUse hook - Called after each tool use

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read STDIN and pass it to the helper script
cat | "$SCRIPT_DIR/session-state-helper.rb" working

exit 0
