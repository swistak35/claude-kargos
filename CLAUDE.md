# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Kargos is a menubar plugin that monitors Claude Code sessions in real-time. It consists of:
- A Kargos/Argos menubar script that displays session status
- Claude Code hooks that track session lifecycle events
- A Ruby helper library for managing session state files

## Architecture

### Session State Management

The system uses **file-based state tracking** to avoid race conditions:
- Each Claude Code session creates a separate JSON file in `~/.claude-sessions/`
- Files are named `{session_id}.json` where session_id comes from hook input JSON via STDIN
- State transitions: `waiting` → `working` → `ready` → `waiting` (or directly to end)

**Key state transitions:**
- `SessionStart` hook → creates file with `waiting` state (includes session source)
- `UserPromptSubmit` hook → updates to `working` state (user submitted a new prompt)
- `PostToolUse` hook → updates to `working` state (Claude is actively working)
- `Stop` hook → updates to `ready` state (Claude finished responding)
- `Notification` hook (idle_prompt matcher) → updates to `waiting` state (60+ seconds idle)
- `SessionEnd` hook → deletes the file

### Component Responsibilities

**session-state-helper.rb** (hooks/session-state-helper.rb:1)
- Core state management library used by all hooks
- Commands: `start`, `stop`, `waiting`, `working`, `end`
- Reads JSON input from STDIN as per Claude Code hooks specification
- Extracts session_id, cwd, transcript_path, and other metadata from hook input
- Creates/updates/deletes session files atomically

**Hook scripts** (hooks/*.sh)
- Thin bash wrappers that pipe STDIN to session-state-helper.rb with appropriate commands
- All hooks use relative paths to find session-state-helper.rb
- Pattern: `cat | "$SCRIPT_DIR/session-state-helper.rb" <command>`
- Must be executable (`chmod +x`)

**claude-status.5s.rb**
- Kargos plugin that reads all session files every 5 seconds
- Displays one emoji per session in menubar
- Color coding: Orange (waiting), Green (working/ready), Gray (no sessions)
- Refresh interval controlled by filename: `.5s.` = 5 seconds

## Testing

**test-hooks.sh** - Comprehensive test suite that verifies:
1. Session file creation on SessionStart
2. State transitions (working → ready → waiting)
3. Kargos script output for each state
4. Session cleanup on SessionEnd

Run tests:
```bash
./test-hooks.sh
```

The test pipes properly formatted JSON input (including session_id, cwd, etc.) to each hook to simulate real Claude Code hook events.

## Development Commands

### Making hooks executable
```bash
chmod +x hooks/*.sh hooks/*.rb
```

### Manual hook testing
```bash
# Create sample hook input JSON
echo '{
  "session_id": "manual-test-123",
  "cwd": "'$(pwd)'",
  "transcript_path": "~/.claude/test.jsonl",
  "permission_mode": "default",
  "hook_event_name": "SessionStart",
  "source": "manual"
}' | ./hooks/session-start.sh

# Check the created session file
cat ~/.claude-sessions/*.json | jq

# Clean up
echo '{
  "session_id": "manual-test-123",
  "hook_event_name": "SessionEnd"
}' | ./hooks/session-end.sh
```

### Manual state inspection
```bash
ls -la ~/.claude-sessions/
cat ~/.claude-sessions/*.json | jq
```

### Running kargos script manually
```bash
./claude-status.5s.rb
```

### Cleaning stale sessions
```bash
rm -rf ~/.claude-sessions/
```

## Code Patterns

### Hook Input Format
The helper script reads JSON from STDIN as per Claude Code hooks specification (session-state-helper.rb:13-23).
- All hooks receive JSON input with `session_id`, `cwd`, `transcript_path`, `permission_mode`, etc.
- The script will exit with an error if no input is received or session_id is missing
- This ensures session tracking only works within Claude Code contexts with proper hook data

**Example hook input:**
```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf.jsonl",
  "cwd": "/path/to/project",
  "permission_mode": "default",
  "hook_event_name": "SessionStart"
}
```

### Hook Integration
All hooks follow this pattern:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat | "$SCRIPT_DIR/session-state-helper.rb" <command>
```

The `cat` command pipes STDIN to the helper script, which parses the JSON and extracts session information. This allows hooks to work regardless of where they're installed, as they always find the helper script relative to themselves.

### Session File Format
```json
{
  "session_id": "abc123",
  "pid": 12345,
  "state": "working|ready|waiting",
  "timestamp": 1234567890,
  "pwd": "/path/to/project",
  "metadata": {
    "cwd": "/path/to/project",
    "transcript_path": "~/.claude/projects/.../00893aaf.jsonl",
    "permission_mode": "default",
    "project_dir": "/path/to/project",
    "source": "startup",
    "notification_type": "idle_prompt",
    "message": "...",
    "prompt": "user's prompt text"
  }
}
```

The metadata object contains event-specific fields captured from the hook input JSON.

## Configuration Files

**hooks/settings.json** - Template for Claude Code hooks configuration
- Must be copied/merged into `~/.claude/settings.json` (global) or `.claude/settings.json` (per-project)
- Paths must be updated to absolute paths pointing to this repository's hooks directory
- Uses `idle_prompt` matcher for Notification hook to detect 60+ second idle state

## Important Notes

- Session files persist across Claude Code restarts until SessionEnd hook fires
- If Claude Code crashes, the kargos script automatically detects stale sessions by checking if the stored PID is still running, and removes the session file
- Kargos script gracefully handles missing/malformed session files (rescue block in claude-status.5s.rb:28-33)
- Each hook must exit 0 to avoid breaking Claude Code workflow
- The helper script uses `File.write` with `JSON.pretty_generate` for atomic file updates
