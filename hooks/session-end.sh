#!/bin/bash
# SessionEnd hook - Called when a Claude Code session ends

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read STDIN and pass it to the helper script
cat | "$SCRIPT_DIR/session-state-helper.rb" end

exit 0
