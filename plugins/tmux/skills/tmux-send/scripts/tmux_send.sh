#!/usr/bin/env bash
# tmux_send.sh - Send content to a tmux pane via paste buffer, then press Enter
# Usage: tmux_send.sh <pane_id> <content_or_file>
#   pane_id: tmux pane ID (e.g. %7)
#   content_or_file: text content, or a file path starting with / or ./

set -euo pipefail

PANE_ID="${1:?Usage: tmux_send.sh <pane_id> <content_or_file>}"
[[ "$PANE_ID" != %* ]] && PANE_ID="%${PANE_ID}"
CONTENT="${2:?Usage: tmux_send.sh <pane_id> <content_or_file>}"

# Verify pane exists
if ! tmux list-panes -t "$PANE_ID" >/dev/null 2>&1; then
  echo "Error: pane $PANE_ID not found" >&2
  exit 1
fi

# Resolve sender pane id
SENDER_PANE="${TMUX_PANE:-unknown}"

# Resolve body: file path → read file, otherwise use as-is
if [[ "$CONTENT" =~ ^/ ]] || [[ "$CONTENT" =~ ^\./ ]]; then
  [[ ! -f "$CONTENT" ]] && { echo "Error: file $CONTENT not found" >&2; exit 1; }
  BODY=$(cat "$CONTENT")
else
  BODY="$CONTENT"
fi

tmux load-buffer - <<< "${BODY}
[msg from tmux pane_id ${SENDER_PANE}]"

# Paste content to pane (must be separate from send-keys)
tmux paste-buffer -p -r -t "$PANE_ID"
sleep 0.5
# Send Enter key as a separate command to ensure TUI tools can receive it
tmux send-keys -t "$PANE_ID" Enter
