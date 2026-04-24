# Widget: explains the current BUFFER (a typed command) above the prompt,
# leaving the command intact so the user can still edit or run it.
claude-explain-widget() {
  emulate -L zsh
  [[ -z "$BUFFER" ]] && return
  local cmd="$BUFFER"
  zle -I
  print -r -- "⏳ asking claude to explain…"
  local result stderr_msg rc stderr_file
  stderr_file=$(mktemp)
  result=$(_zsh_claude_code_run "$ZSH_CLAUDE_EXPLAIN_MODEL" "$ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT" "$cmd" 2>"$stderr_file")
  rc=$?
  stderr_msg=$(<"$stderr_file")
  rm -f "$stderr_file"
  if (( rc != 0 )) || [[ -z "$result" ]]; then
    _zsh_claude_code_report_error "$stderr_msg" "$rc" "explain"
    zle reset-prompt
    return $rc
  fi
  print -r -- "$result"
  print
  zle reset-prompt
}
zle -N claude-explain-widget
bindkey "$ZSH_CLAUDE_EXPLAIN_KEY" claude-explain-widget
