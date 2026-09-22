#!/usr/bin/env bash
# Cursor stop hook: notify on agent completion/error via notify-send.
# Reads JSON from stdin. Always prints {} so the agent does not auto-continue.
# Copied with minor modification from: https://github.com/glira/cursor-agent-notifier/blob/main/hooks/notify-on-stop.sh
set -euo pipefail

input="$(cat || true)"

status="$(printf '%s' "$input" | jq -r '.status // empty' 2>/dev/null || true)"

# Always acknowledge the hook so Cursor does not treat missing output as failure.
emit_ok() {
  printf '%s\n' '{}'
}

if [[ -z "$status" ]]; then
  emit_ok
  exit 0
fi

# Skip manual cancellations.
if [[ "$status" == "aborted" ]]; then
  emit_ok
  exit 0
fi

if ! command -v notify-send >/dev/null 2>&1; then
  echo "notify-send not found; skipping desktop notification" >&2
  emit_ok
  exit 0
fi

case "$status" in
  completed)
    title="Cursor Agent Finished"
    message="An agent has completed"
    urgency="normal"
    ;;
  error)
    title="Cursor Agent Error"
    message="Agent terminated with an error"
    urgency="critical"
    ;;
  *)
    title="Cursor Agent"
    message="Status: $status"
    urgency="normal"
    ;;
esac

# Fail open: notification errors must not break the agent stop lifecycle.
if ! notify-send \
  --app-name="Cursor" \
  --urgency="$urgency" \
  --icon=dialog-information \
  "$title" \
  "$message" 2>/dev/null; then
  echo "notify-send failed; continuing without notification" >&2
fi

emit_ok
exit 0
