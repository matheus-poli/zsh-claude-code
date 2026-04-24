: ${ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT:='Output exactly one shell command for zsh on Linux. No explanation, no markdown, no backticks, no code fences, no surrounding quotes, no leading or trailing whitespace, no newlines. If the request is ambiguous, pick the most common interpretation.'}

# Widget: rewrites the current BUFFER (natural language) into a shell command.
claude-suggest() {
  emulate -L zsh
  setopt localoptions nomonitor nonotify
  [[ -z "$BUFFER" ]] && return
  local prompt="$BUFFER"
  # POSTDISPLAY shows the spinner after BUFFER without touching it, so the
  # user's typed request stays visible while claude thinks.
  local original_postdisplay="$POSTDISPLAY"

  local out_file err_file
  out_file=$(mktemp) err_file=$(mktemp)
  ( _zsh_claude_code_run "$ZSH_CLAUDE_SUGGEST_MODEL" "$ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT" "$prompt" >"$out_file" 2>"$err_file" ) &
  local pid=$!

  local -a frames
  frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local i=0
  while kill -0 $pid 2>/dev/null; do
    POSTDISPLAY="  🤖 ${frames[$((i % ${#frames} + 1))]} claude thinking how to do it…"
    zle -R
    sleep 0.08
    (( i++ ))
  done
  wait $pid 2>/dev/null
  local rc=$?

  POSTDISPLAY="$original_postdisplay"

  local result stderr_msg
  result=$(<"$out_file")
  stderr_msg=$(<"$err_file")
  rm -f "$out_file" "$err_file"

  if (( rc != 0 )) || [[ -z "$result" ]]; then
    zle -I
    _zsh_claude_code_report_error "$stderr_msg" "$rc" "suggest"
    zle reset-prompt
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
