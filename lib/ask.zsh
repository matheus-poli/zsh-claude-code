: ${ZSH_CLAUDE_ASK_SYSTEM_PROMPT:='You answer quick terminal/dev questions for a developer on Linux, zsh + oh-my-zsh. Be terse. No preamble, no closing summary. When a command is the answer, show it first in a fenced code block, then at most one short line if truly needed. Prefer zsh-compatible syntax.'}

unfunction ask 2>/dev/null

_zsh_claude_code_ask() {
  emulate -L zsh
  if [[ -z "$*" ]]; then
    print -r -- "usage: ask <question>" >&2
    return 2
  fi
  _zsh_claude_code_run "$ZSH_CLAUDE_ASK_MODEL" "$ZSH_CLAUDE_ASK_SYSTEM_PROMPT" "$*"
  local rc=$?
  (( rc != 0 )) && _zsh_claude_code_command_hint $rc ask
  return $rc
}
# noglob so `?`, `*`, `[...]` in questions don't get expanded by zsh.
alias ask='noglob _zsh_claude_code_ask'
