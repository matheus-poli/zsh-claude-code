# Widget: explains the current BUFFER (a typed command) above the prompt,
# leaving the command intact so the user can still edit or run it.
claude-explain-widget() {
  emulate -L zsh
  [[ -z "$BUFFER" ]] && return
  local cmd="$BUFFER"
  zle -I
  print -r -- "⏳ asking claude to explain…"
  local result rc
  result=$(_zsh_claude_code_run "$ZSH_CLAUDE_EXPLAIN_MODEL" "$ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT" "$cmd" 2>/dev/null)
  rc=$?
  if (( rc != 0 )) || [[ -z "$result" ]]; then
    print -r -- "zsh-claude-code: explain failed" >&2
    zle reset-prompt
    return $rc
  fi
  print -r -- "$result"
  print
  zle reset-prompt
}
zle -N claude-explain-widget
bindkey "$ZSH_CLAUDE_EXPLAIN_KEY" claude-explain-widget
