# Claude Code integration

RealNotch can show your live [Claude Code](https://claude.com/claude-code) sessions
in the notch — which agents are **working**, which are **waiting on you** (a question
or a permission prompt), and which are **done**. Click one to bring your terminal
forward. The collapsed notch shows a count when an agent needs you.

## How it works

Claude Code fires **hooks** on session events. A small script turns those events
into a per-session status file that RealNotch watches:

```
~/Library/Application Support/RealNotch/Agents/<session_id>.json
```

No polling of Claude, no network — just local files, same live-reload mechanism as skins.

## Setup

1. Copy the hook script somewhere stable and make it executable:

   ```sh
   cp realnotch-agent-hook.sh ~/.claude/realnotch-agent-hook.sh
   chmod +x ~/.claude/realnotch-agent-hook.sh
   ```

   Requires `jq` (`brew install jq`).

2. Add these hooks to `~/.claude/settings.json` (merge into any existing `"hooks"`):

   ```json
   {
     "hooks": {
       "SessionStart":     [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }],
       "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }],
       "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }],
       "Notification":     [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }],
       "Stop":             [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }],
       "SessionEnd":       [{ "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/realnotch-agent-hook.sh\"" }] }]
     }
   }
   ```

3. Start a Claude Code session — it appears in the notch's **Agents** tab.

## Status mapping

| Claude Code event | RealNotch status |
|---|---|
| `SessionStart`, `UserPromptSubmit`, `PostToolUse` | **working** |
| `Notification` (`permission_prompt` / `agent_needs_input` / `elicitation_dialog`) | **waiting** (needs you) |
| `Notification` (`idle_prompt`), `Stop` | **idle** (done) |
| `SessionEnd` | removed |

## Limitations

- **Clicking focuses the terminal app (Ghostty), not the exact window/tab.** Claude Code
  hooks don't expose a TTY or window id, so precise per-tab focus isn't possible today.
- Sessions that die without a `SessionEnd` (crash / `kill -9`) are pruned after 3h of silence.
