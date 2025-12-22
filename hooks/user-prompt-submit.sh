#!/bin/bash
# UserPromptSubmit hook - Called when user submits a prompt

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read STDIN and pass it to the helper script
cat | "$SCRIPT_DIR/session-state-helper.rb" working

exit 0
