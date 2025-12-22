#!/bin/bash
# Stop hook - Called when Claude finishes responding (ready for input)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read STDIN and pass it to the helper script
cat | "$SCRIPT_DIR/session-state-helper.rb" stop

exit 0
