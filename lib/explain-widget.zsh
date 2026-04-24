# Widget: explains the current BUFFER (a typed command) above the prompt,
# leaving the command intact so the user can still edit or run it.
claude-explain-widget() {
  emulate -L zsh
  setopt localoptions nomonitor nonotify
  [[ -z "$BUFFER" ]] && return
  local cmd="$BUFFER"

  local out_file err_file
  out_file=$(mktemp) err_file=$(mktemp)
  ( _zsh_claude_code_run "$ZSH_CLAUDE_EXPLAIN_MODEL" "$ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT" "$cmd" >"$out_file" 2>"$err_file" ) &
  local pid=$!

  zle -I

  local -a frames
  frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local i=0
  while kill -0 $pid 2>/dev/null; do
    # \r: cursor to start of line, \e[2K: clear whole line — redraw in place.
    print -n -- $'\r\e[2K'"🤖 ${frames[$((i % ${#frames} + 1))]} asking claude to explain…"
    sleep 0.08
    (( i++ ))
  done
  wait $pid 2>/dev/null
  local rc=$?

  # Clear the spinner line before printing the final output.
  print -n -- $'\r\e[2K'

  local result stderr_msg
  result=$(<"$out_file")
  stderr_msg=$(<"$err_file")
  rm -f "$out_file" "$err_file"

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
