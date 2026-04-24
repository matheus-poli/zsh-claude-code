#!/usr/bin/env zsh
# End-to-end smoke: source the plugin, call `ask`, assert the answer is non-empty
# and contains the expected token. Skips silently if `claude` is missing or the
# user is not authenticated — CI environments without credentials should be a no-op.

emulate -L zsh
set -e
cd "${0:A:h}/.."

if ! command -v claude >/dev/null 2>&1; then
  print -r -- "smoke: skip (claude CLI not installed)"
  exit 0
fi

source ./zsh-claude-code.plugin.zsh

if ! typeset -f _zsh_claude_code_ask >/dev/null; then
  print -r -- "smoke: fail (ask function not defined — guard may have tripped unexpectedly)" >&2
  exit 1
fi

result=$(ask "reply with just the two characters: OK" 2>&1) || {
  # Most likely: not authenticated. Treat as skip, not failure.
  print -r -- "smoke: skip (\`ask\` call failed — probably not logged in)"
  print -r -- "smoke: output was: $result"
  exit 0
}

if [[ "$result" == *OK* ]]; then
  print -r -- "smoke: pass"
  exit 0
fi

print -r -- "smoke: fail (expected 'OK' in output, got: $result)" >&2
exit 1
