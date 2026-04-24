: ${ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT:='Output exactly one shell command for zsh on Linux. No explanation, no markdown, no backticks, no code fences, no surrounding quotes, no leading or trailing whitespace, no newlines. If the request is ambiguous, pick the most common interpretation.'}

# Widget: rewrites the current BUFFER (natural language) into a shell command.
claude-suggest() {
  emulate -L zsh
  [[ -z "$BUFFER" ]] && return
  local prompt="$BUFFER"
  local original="$BUFFER"
  BUFFER="⏳ asking claude…"
  zle -R
  local result rc
  result=$(_zsh_claude_code_run "$ZSH_CLAUDE_SUGGEST_MODEL" "$ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT" "$prompt" 2>/dev/null)
  rc=$?
  if (( rc != 0 )) || [[ -z "$result" ]]; then
    BUFFER="$original"
    CURSOR=${#BUFFER}
    zle -R
    return $rc
  fi
  # Defensive scrub: strip fences, backticks, collapse newlines, trim whitespace.
  result="${result//\`\`\`*$'\n'/}"
  result="${result//\`\`\`/}"
  result="${result//\`/}"
  result="${result//$'\n'/ }"
  result="${result## }"
  result="${result%% }"
  BUFFER="$result"
  CURSOR=${#BUFFER}
  zle -R
}
zle -N claude-suggest
bindkey "$ZSH_CLAUDE_SUGGEST_KEY" claude-suggest
