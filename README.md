# Claude Kargos Status Monitor

A kargos/argos menubar plugin that monitors your Claude Code sessions and displays their status in real-time.

## Features

- 🤖 Real-time monitoring of Claude Code sessions
- 📊 **One emoji per session** - see exactly how many sessions you have at a glance
- ⏸️ Visual indicator for each session waiting for your input
- ⚙️ Shows each session that is actively working
- 💤 Displays when no sessions are active
- 🎨 Color-coded: Orange when any session is waiting, green when all are working/ready
- 📋 Lists all active sessions in dropdown menu in consistent order

## Components

### Kargos Script
- `claude-status.5s.rb` - Main kargos script that displays session status (refreshes every 5 seconds)

### Hooks
The `hooks/` directory contains scripts that track Claude Code session state:

- `session-state-helper.rb` - Core helper that manages session state files
- `session-start.sh` - SessionStart hook
- `session-end.sh` - SessionEnd hook
- `notification-idle.sh` - Notification hook for idle prompts
- `stop.sh` - Stop hook when Claude finishes responding
- `settings.json` - Hook configuration template

## Installation

### 1. Install Kargos
First, make sure you have kargos installed. See: https://github.com/lipkau/kargos

### 2. Set up the Kargos Script
Copy or symlink the kargos script to your kargos plugins directory:

```bash
# Option A: Symlink (recommended)
ln -s /home/swistak35/projs/swistak35/claude-kargos/claude-status.5s.rb ~/Library/Application\ Support/kargos/plugins/

# Option B: Copy
cp /home/swistak35/projs/swistak35/claude-kargos/claude-status.5s.rb ~/Library/Application\ Support/kargos/plugins/
```

### 3. Configure Claude Code Hooks

Hooks are what allow the kargos script to track your Claude sessions in real-time. You need to configure them globally so they work for all your Claude Code sessions.

#### Step-by-Step Hook Setup

1. **First, check if you already have a Claude settings file:**
   ```bash
   ls -la ~/.claude/settings.json
   ```

2. **Option A: If the file doesn't exist (new setup)**
   ```bash
   # Create the .claude directory if it doesn't exist
   mkdir -p ~/.claude

   # Copy the hooks configuration
   cp /home/swistak35/projs/swistak35/claude-kargos/hooks/settings.json ~/.claude/settings.json

   # Update the paths in the file to point to your hook scripts
   # Edit the file and replace all instances of the hook script paths
   ```

3. **Option B: If the file exists (merge with existing settings)**

   You need to manually merge the hooks section. Open both files:
   ```bash
   # View the template
   cat /home/swistak35/projs/swistak35/claude-kargos/hooks/settings.json

   # Edit your existing settings
   nano ~/.claude/settings.json  # or use your preferred editor
   ```

   Copy the entire `"hooks"` section from `hooks/settings.json` and add it to your existing settings file. Make sure to:
   - Keep any existing settings you have
   - Add or merge the `"hooks"` object
   - Ensure the JSON is valid (check commas between sections)

4. **Update the hook script paths**

   Edit `~/.claude/settings.json` and replace all hook script paths with the full path to where you cloned this repository:

   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "/FULL/PATH/TO/claude-kargos/hooks/session-start.sh"
             }
           ]
         }
       ],
       ...
     }
   }
   ```

   Replace `/FULL/PATH/TO/claude-kargos` with the actual path, for example:
   - `/home/swistak35/projs/swistak35/claude-kargos`
   - Or wherever you cloned this repository

5. **Verify the hooks are set up correctly**
   ```bash
   # Run the test script
   /home/swistak35/projs/swistak35/claude-kargos/test-hooks.sh
   ```

   If all tests pass, your hooks are configured correctly!

6. **Restart any running Claude Code sessions**

   The hooks will only take effect for new sessions, so restart any Claude Code sessions you have running.

#### Alternative: Per-Project Setup

If you only want hooks for specific projects (not recommended, as you'll miss sessions in other projects):

```bash
mkdir -p /path/to/your/project/.claude
cp /home/swistak35/projs/swistak35/claude-kargos/hooks/settings.json /path/to/your/project/.claude/settings.json
# Then update the paths in that file as described above
```

#### Quick Reference: Final hooks configuration

Your `~/.claude/settings.json` should contain this structure (with paths updated to your actual location):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/swistak35/projs/swistak35/claude-kargos/hooks/session-start.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/swistak35/projs/swistak35/claude-kargos/hooks/session-end.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/home/swistak35/projs/swistak35/claude-kargos/hooks/notification-idle.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/swistak35/projs/swistak35/claude-kargos/hooks/stop.sh"
          }
        ]
      }
    ]
  }
}
```

## How It Works

1. **SessionStart hook** - When you start a Claude Code session, it creates a state file in `~/.claude-sessions/`
2. **Notification hook** - When Claude is idle waiting for input (60+ seconds), it updates the state to "waiting"
3. **Stop hook** - When Claude finishes responding, it updates the state to "ready"
4. **SessionEnd hook** - When the session ends, it removes the state file
5. **Kargos script** - Reads all session files every 5 seconds and displays one emoji per session

## Visual Display Examples

The menubar shows one emoji for each active session:

- **No sessions**: `🤖 💤` (gray)
- **1 working**: `⚙️` (green)
- **3 working**: `⚙️ ⚙️ ⚙️` (green)
- **Mixed states**: Sessions appear in their natural order (alphabetically by session ID)

Sessions maintain a consistent order so you can track which specific session needs attention.

**Color coding:**
- **Orange** - At least one session is waiting for your input (action needed!)
- **Green** - All sessions are working or ready
- **Gray** - No active sessions

## Session Files

Session state files are stored in `~/.claude-sessions/` with one file per session:
- Filename: `{session_id}.json`
- Avoids race conditions by using separate files per session
- Automatically cleaned up when sessions end

## Customization

### Icons
Edit the constants in `claude-status.5s.rb`:
```ruby
ICON_WAITING = "⏸️"
ICON_WORKING = "⚙️"
ICON_IDLE = "💤"
ICON_CLAUDE = "🤖"
```

### Colors
```ruby
COLOR_WAITING = "#FFA500"  # Orange
COLOR_WORKING = "#00FF00"  # Green
COLOR_IDLE = "#808080"     # Gray
```

### Refresh Interval
Rename the file to change the refresh interval:
- `.5s.` = 5 seconds
- `.10s.` = 10 seconds
- `.30s.` = 30 seconds

## Troubleshooting

### No sessions showing up

1. **Run the test script to verify hooks work:**
   ```bash
   /home/swistak35/projs/swistak35/claude-kargos/test-hooks.sh
   ```
   This will tell you exactly what's wrong.

2. **Check if hooks are configured in the right place:**
   ```bash
   cat ~/.claude/settings.json
   ```
   Make sure the `"hooks"` section exists and paths are correct.

3. **Verify hook scripts are executable:**
   ```bash
   chmod +x /home/swistak35/projs/swistak35/claude-kargos/hooks/*.sh
   chmod +x /home/swistak35/projs/swistak35/claude-kargos/hooks/*.rb
   ```

4. **Check if session files are being created:**
   ```bash
   ls -la ~/.claude-sessions/
   ```
   This directory should be created when you start a Claude Code session.

5. **Verify paths in settings.json match your actual script locations:**
   - Open `~/.claude/settings.json`
   - Make sure all four hook paths point to the correct location
   - Use absolute paths (starting with `/`)

6. **Check Claude Code is picking up the hooks:**
   - Restart any running Claude Code sessions
   - Hooks only apply to new sessions started after the configuration was added

### Stale sessions
If sessions show up after Claude Code has closed:
- Manually clean up: `rm -rf ~/.claude-sessions/`
- This can happen if the SessionEnd hook doesn't fire (e.g., forced quit)

### Hooks not firing
If the test script passes but real sessions don't show up:
- Make sure you restarted Claude Code after adding the hooks
- Check that `~/.claude/settings.json` exists (not `.claude/settings.json.local`)
- Try running a hook manually to see if there are any errors:
  ```bash
  CLAUDE_SESSION_ID="test" /home/swistak35/projs/swistak35/claude-kargos/hooks/session-start.sh
  ls -la ~/.claude-sessions/
  ```

## License

MIT
