# Shared defaults and runner for zsh-claude-code.
# Users may override any ZSH_CLAUDE_* var in .zshrc before loading the plugin.

: ${ZSH_CLAUDE_ASK_MODEL:=opus}
: ${ZSH_CLAUDE_EXPLAIN_MODEL:=sonnet}
: ${ZSH_CLAUDE_SUGGEST_MODEL:=haiku}
: ${ZSH_CLAUDE_SUGGEST_KEY:=^X}
: ${ZSH_CLAUDE_EXPLAIN_KEY:=^[e}
: ${ZSH_CLAUDE_EXTRA_FLAGS:=}

# Invoke `claude -p` with shared tuned flags.
# Full system-prompt replace (not append) keeps responses terse and tool-free.
_zsh_claude_code_run() {
  emulate -L zsh
  local model=$1 sys=$2 prompt=$3
  local -a extra
  [[ -n "$ZSH_CLAUDE_EXTRA_FLAGS" ]] && extra=(${=ZSH_CLAUDE_EXTRA_FLAGS})
  claude -p \
    --no-session-persistence \
    --disable-slash-commands \
    --tools "" \
    --model "$model" \
    --system-prompt "$sys" \
    "${extra[@]}" \
    "$prompt"
}

# Friendly error reporter for widgets. Detects common auth failures and
# appends a one-line hint pointing the user at `claude login`.
# Usage: _zsh_claude_code_report_error <stderr_text> <exit_code> [feature_name]
_zsh_claude_code_report_error() {
  emulate -L zsh
  local msg=$1 rc=$2 feature=${3:-claude}
  print -r -- "zsh-claude-code: $feature failed (exit $rc)"
  if [[ -n "$msg" ]]; then
    local -a lines
    lines=("${(@f)msg}")
    [[ -n "${lines[1]}" ]] && print -r -- "  ${lines[1]}"
  fi
  local lmsg=${msg:l}
  if [[ -z "$msg" \
     || "$lmsg" == *login* \
     || "$lmsg" == *"api key"* \
     || "$lmsg" == *auth* \
     || "$lmsg" == *unauthorized* \
     || "$lmsg" == *unauthorised* \
     || "$lmsg" == *forbidden* \
     || "$lmsg" == *credential* \
     || "$lmsg" == *token* ]]; then
    print -r -- "  hint: not logged in? run \`claude login\` (or set ANTHROPIC_API_KEY)"
  fi
}

# Friendly error reporter for non-widget commands (ask / explain). Prints
# a single hint line to stderr after claude's own error has already shown.
_zsh_claude_code_command_hint() {
  emulate -L zsh
  local rc=$1 feature=${2:-claude}
  print -r -- "zsh-claude-code: $feature failed (exit $rc). Not logged in? Run \`claude login\` (or set ANTHROPIC_API_KEY)." >&2
}


