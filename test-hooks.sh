#!/bin/bash
# Test script to verify hooks are working correctly

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/hooks" && pwd)"
TEST_SESSION_ID="test-session-12345"
TEST_CWD="$(pwd)"

echo "Testing Claude Kargos hooks..."
echo "================================"
echo

# Clean up any existing test sessions
echo "1. Cleaning up existing sessions..."
rm -rf ~/.claude-sessions/
echo "   ✓ Done"
echo

# Test SessionStart
echo "2. Testing SessionStart hook..."
echo "{
  \"session_id\": \"$TEST_SESSION_ID\",
  \"cwd\": \"$TEST_CWD\",
  \"transcript_path\": \"~/.claude/test.jsonl\",
  \"permission_mode\": \"default\",
  \"hook_event_name\": \"SessionStart\",
  \"source\": \"test\"
}" | "$HOOKS_DIR/session-start.sh"
if [ -d ~/.claude-sessions ] && [ "$(ls -A ~/.claude-sessions)" ]; then
    echo "   ✓ Session file created"
    echo "   Contents:"
    cat ~/.claude-sessions/*.json | sed 's/^/   /'
else
    echo "   ✗ FAILED: No session file created"
    exit 1
fi
echo

# Test Stop hook
echo "3. Testing Stop hook (ready state)..."
echo "{
  \"session_id\": \"$TEST_SESSION_ID\",
  \"cwd\": \"$TEST_CWD\",
  \"transcript_path\": \"~/.claude/test.jsonl\",
  \"permission_mode\": \"default\",
  \"hook_event_name\": \"Stop\"
}" | "$HOOKS_DIR/stop.sh"
SESSION_FILE=$(ls ~/.claude-sessions/*.json 2>/dev/null | head -1)
STATE=$(jq -r '.state' "$SESSION_FILE" 2>/dev/null || echo "error")
if [ "$STATE" = "ready" ]; then
    echo "   ✓ State changed to 'ready'"
else
    echo "   ✗ FAILED: Expected state 'ready', got '$STATE'"
    exit 1
fi
echo

# Test Notification hook
echo "4. Testing Notification hook (waiting state)..."
echo "{
  \"session_id\": \"$TEST_SESSION_ID\",
  \"cwd\": \"$TEST_CWD\",
  \"transcript_path\": \"~/.claude/test.jsonl\",
  \"permission_mode\": \"default\",
  \"hook_event_name\": \"Notification\",
  \"notification_type\": \"idle_prompt\",
  \"message\": \"Claude is waiting for input\"
}" | "$HOOKS_DIR/notification-idle.sh"
SESSION_FILE=$(ls ~/.claude-sessions/*.json 2>/dev/null | head -1)
STATE=$(jq -r '.state' "$SESSION_FILE" 2>/dev/null || echo "error")
if [ "$STATE" = "waiting" ]; then
    echo "   ✓ State changed to 'waiting'"
else
    echo "   ✗ FAILED: Expected state 'waiting', got '$STATE'"
    exit 1
fi
echo

# Test kargos script with waiting state
echo "5. Testing kargos script output (waiting state)..."
OUTPUT=$("$(dirname "${BASH_SOURCE[0]}")/claude-status.5s.rb")
if echo "$OUTPUT" | grep -q "waiting for input"; then
    echo "   ✓ Kargos script shows waiting state"
    echo "   Menubar output:"
    echo "$OUTPUT" | head -1 | sed 's/^/   /'
else
    echo "   ✗ FAILED: Kargos script doesn't show waiting state"
    exit 1
fi
echo

# Test SessionEnd
echo "6. Testing SessionEnd hook..."
echo "{
  \"session_id\": \"$TEST_SESSION_ID\",
  \"cwd\": \"$TEST_CWD\",
  \"hook_event_name\": \"SessionEnd\"
}" | "$HOOKS_DIR/session-end.sh"
if [ ! -d ~/.claude-sessions ] || [ ! "$(ls -A ~/.claude-sessions)" ]; then
    echo "   ✓ Session file removed"
else
    echo "   ✗ FAILED: Session file still exists"
    exit 1
fi
echo

# Test kargos script with no sessions
echo "7. Testing kargos script output (no sessions)..."
OUTPUT=$("$(dirname "${BASH_SOURCE[0]}")/claude-status.5s.rb")
if echo "$OUTPUT" | grep -q "No active sessions"; then
    echo "   ✓ Kargos script shows no sessions"
    echo "   Menubar output:"
    echo "$OUTPUT" | head -1 | sed 's/^/   /'
else
    echo "   ✗ FAILED: Kargos script doesn't show idle state"
    exit 1
fi
echo

echo "================================"
echo "All tests passed! ✓"
echo
echo "Next steps:"
echo "1. Copy hooks/settings.json to ~/.claude/settings.json (or merge with existing)"
echo "2. Update paths in settings.json to point to: $HOOKS_DIR"
echo "3. Symlink claude-status.5s.rb to your kargos plugins directory"
