#!/bin/bash

# External Review Stop Hook
# When Claude considers stopping, check if there are uncommitted changes.
# If so, send a system message prompting Claude to ask about external review.
# Uses session_id from hook input to scope the state — only asks once per session.

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract session_id from hook input to scope state per session
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')

if [[ -z "$SESSION_ID" ]]; then
  # No session_id available — can't track state, allow stop
  exit 0
fi

# Store state outside the repo in Claude's temp directory
STATE_DIR="/tmp/claude-external-review"
STATE_FILE="$STATE_DIR/$SESSION_ID"

# If we already asked this session, don't ask again
if [[ -f "$STATE_FILE" ]]; then
  exit 0
fi

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# Check for uncommitted changes (staged, unstaged, or untracked)
# This works even in repos with no commits (no HEAD)
CHANGES=$(git status --porcelain 2>/dev/null)

if [[ -z "$CHANGES" ]]; then
  # No changes — allow stop without prompting
  exit 0
fi

# Count changed files for context
CHANGED_COUNT=$(echo "$CHANGES" | wc -l | tr -d ' ')

# Mark that we've asked for this session
mkdir -p "$STATE_DIR"
touch "$STATE_FILE"

# There are uncommitted changes — block the stop and ask Claude to offer a review
# The "reason" field is what Claude sees as the continuation prompt, so the
# ask-the-user instruction goes there, not in systemMessage.
jq -n \
  --arg count "$CHANGED_COUNT" \
  --arg reason "There are $CHANGED_COUNT file(s) with uncommitted changes. Before ending the session, ask the user if they'd like to send these changes for external review by Codex (use the external-review skill). If they decline, stop normally." \
  '{
    "decision": "block",
    "reason": $reason
  }'

exit 0
