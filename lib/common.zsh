# Shared defaults and runner for zsh-claude-code.
# Users may override any ZSH_CLAUDE_* var in .zshrc before loading the plugin.

: ${ZSH_CLAUDE_ASK_MODEL:=sonnet}
: ${ZSH_CLAUDE_EXPLAIN_MODEL:=sonnet}
: ${ZSH_CLAUDE_SUGGEST_MODEL:=haiku}
: ${ZSH_CLAUDE_SUGGEST_KEY:=^X}
: ${ZSH_CLAUDE_EXPLAIN_KEY:=^[e}
: ${ZSH_CLAUDE_EXTRA_FLAGS:=}

# Invoke `claude -p` with shared tuned flags.
# Full system-prompt replace (not append) keeps responses terse and tool-free.
# --strict-mcp-config skips the user's MCP servers: `--tools ""` doesn't drop
# their tool definitions, which can add 200k+ input tokens to every call.
_zsh_claude_code_run() {
  emulate -L zsh
  local model=$1 sys=$2 prompt=$3
  local -a extra
  [[ -n "$ZSH_CLAUDE_EXTRA_FLAGS" ]] && extra=(${=ZSH_CLAUDE_EXTRA_FLAGS})
  claude -p \
    --no-session-persistence \
    --disable-slash-commands \
    --tools "" \
    --strict-mcp-config \
    --model "$model" \
    --system-prompt "$sys" \
    "${extra[@]}" \
    "$prompt"
}

# Friendly error reporter for widgets. Detects common auth failures and
# appends a one-line hint pointing the user at `claude auth login`.
# Usage: _zsh_claude_code_report_error <error_text> <exit_code> [feature_name]
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
    print -r -- "  hint: not logged in? run \`claude auth login\` (or set ANTHROPIC_API_KEY)"
  fi
}

# Prints "in" or "out" from `claude auth status`, or nothing if it can't
# tell. Reads the JSON rather than the exit code: the command exits 1 when
# logged out.
_zsh_claude_code_auth_state() {
  emulate -L zsh
  setopt localoptions extendedglob
  local status_json
  status_json=$(claude auth status 2>/dev/null </dev/null)
  if [[ "$status_json" == *'"loggedIn":'[[:space:]]#'false'* ]]; then
    print -r -- out
  elif [[ "$status_json" == *'"loggedIn":'[[:space:]]#'true'* ]]; then
    print -r -- in
  fi
}

# After a failed ask/explain: if the user is logged out and at a terminal,
# offer to run `claude auth login`. Returns 0 when the login succeeded, so
# the caller can retry; otherwise reports the failure and returns 1. The
# login hint is skipped when the user is known to be logged in, since the
# failure is then something else (claude's own message has already shown).
# Usage: _zsh_claude_code_offer_login <exit_code> [feature_name]
_zsh_claude_code_offer_login() {
  emulate -L zsh
  local rc=$1 feature=${2:-claude}
  local state=$(_zsh_claude_code_auth_state)
  if [[ $state == out && -t 0 && -t 2 ]]; then
    print -rn -u2 -- "zsh-claude-code: you're not logged in to Claude. Run \`claude auth login\` now? [y/N] "
    if read -q; then
      print -u2
      claude auth login && return 0
      print -r -- "zsh-claude-code: \`claude auth login\` failed." >&2
      return 1
    fi
    print -u2
  fi
  if [[ $state == in ]]; then
    print -r -- "zsh-claude-code: $feature failed (exit $rc)." >&2
  else
    _zsh_claude_code_command_hint $rc $feature
  fi
  return 1
}

# Friendly error reporter for non-widget commands (ask / explain). Prints
# a single hint line to stderr after claude's own error has already shown.
_zsh_claude_code_command_hint() {
  emulate -L zsh
  local rc=$1 feature=${2:-claude}
  print -r -- "zsh-claude-code: $feature failed (exit $rc). Not logged in? Run \`claude auth login\` (or set ANTHROPIC_API_KEY)." >&2
}
