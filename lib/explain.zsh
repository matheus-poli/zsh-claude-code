: ${ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT:='You explain shell commands for a zsh user. First one line on what the command does overall, then a short bullet per flag/argument. Plain text, no markdown headers. No preamble ("This command..."), start directly.'}

(( $+functions[explain] )) && unfunction explain

_zsh_claude_code_explain() {
  emulate -L zsh
  if [[ -z "$*" ]]; then
    print -r -- "usage: explain <command>" >&2
    return 2
  fi
  _zsh_claude_code_run "$ZSH_CLAUDE_EXPLAIN_MODEL" "$ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT" "$*"
  local rc=$?
  (( rc != 0 )) && _zsh_claude_code_command_hint $rc explain
  return $rc
}
alias explain='noglob _zsh_claude_code_explain'
