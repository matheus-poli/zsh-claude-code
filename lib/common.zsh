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
# appends a one-line hint pointing the user at `claude auth login`, unless
# the user is known to be logged in.
# Usage: _zsh_claude_code_report_error <error_text> <exit_code> [feature_name] [auth_state]
_zsh_claude_code_report_error() {
  emulate -L zsh
  local msg=$1 rc=$2 feature=${3:-claude} state=$4
  print -r -- "zsh-claude-code: $feature failed (exit $rc)"
  if [[ -n "$msg" ]]; then
    local -a lines
    lines=("${(@f)msg}")
    [[ -n "${lines[1]}" ]] && print -r -- "  ${lines[1]}"
  fi
  [[ $state == in ]] && return
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

# Replaces claude's own "Not logged in · Please run /login", whose /login
# only works inside a claude session.
_zsh_claude_code_not_logged_in() {
  print -r -- "zsh-claude-code: not logged in to Claude. Run \`claude auth login\` (or set ANTHROPIC_API_KEY)." >&2
}

# Asks [y/N] and runs `claude auth login`. Returns 0 only if the user is
# logged in afterwards: Ctrl+C in the login exits 0, so the exit code alone
# can't be trusted. Used by ask/explain and, after `zle -I`, by the widgets.
_zsh_claude_code_login_now() {
  emulate -L zsh
  print -rn -u2 -- "zsh-claude-code: you're not logged in to Claude. Run \`claude auth login\` now? [y/N] "
  # Read one key in non-canonical mode. Inside a widget, `zle -I` has left
  # the tty in line mode, where read -q/-k would wait for Enter.
  local key saved
  saved=$(stty -g </dev/tty 2>/dev/null)
  stty -icanon min 1 </dev/tty 2>/dev/null
  read -k 1 key </dev/tty
  [[ -n "$saved" ]] && stty "$saved" </dev/tty 2>/dev/null
  print -u2
  [[ $key == [yY] ]] || return 1
  # Run the login as its own foreground job, so Ctrl+C in it reaches only
  # claude. Without job control the signal also hits this shell, aborting
  # the widget mid-way and dropping the user's line. The widgets turn
  # monitor off for their spinner job; options are local here.
  setopt monitor
  # Inside a widget, stdin is not the terminal, so the login couldn't read
  # the pasted code (Enter just moved down a line): give it /dev/tty. And zle
  # leaves bracketed paste on, which would wrap the code in ESC[200~ ESC[201~;
  # turn it off for the login with zle's own sequences, then back on.
  local -a paste=("${zle_bracketed_paste[@]}")
  [[ -n $WIDGET && -n ${paste[2]} ]] && print -rn -- "${paste[2]}" >/dev/tty
  claude auth login </dev/tty
  [[ -n $WIDGET && -n ${paste[1]} ]] && print -rn -- "${paste[1]}" >/dev/tty
  [[ $(_zsh_claude_code_auth_state) == in ]] && return 0
  # Leading newline: a cancelled login leaves the cursor after its "^C".
  print -r -- $'\nzsh-claude-code: still not logged in.' >&2
  return 1
}

# Shared body of ask and explain. Output is captured so a logged-out error
# can be replaced with our own message; claude -p prints its reply in one go
# at the end anyway, so nothing streams less than before.
# Usage: _zsh_claude_code_command <feature> <model> <system_prompt> <prompt>
_zsh_claude_code_command() {
  emulate -L zsh
  local feature=$1 model=$2 sys=$3 prompt=$4
  local out rc
  out=$(_zsh_claude_code_run "$model" "$sys" "$prompt")
  rc=$?
  if (( rc == 0 )); then
    [[ -n "$out" ]] && print -r -- "$out"
    return 0
  fi

  local state=$(_zsh_claude_code_auth_state)
  if [[ $state == out ]]; then
    # Offer the login only at a terminal, never in pipes or scripts.
    if [[ -t 0 && -t 2 ]] && _zsh_claude_code_login_now; then
      _zsh_claude_code_run "$model" "$sys" "$prompt"
      return
    fi
    _zsh_claude_code_not_logged_in
    return $rc
  fi

  [[ -n "$out" ]] && print -r -- "$out" >&2
  if [[ $state == in ]]; then
    # Logged in, so the failure is something else; claude's message says what.
    print -r -- "zsh-claude-code: $feature failed (exit $rc)." >&2
  else
    print -r -- "zsh-claude-code: $feature failed (exit $rc). Not logged in? Run \`claude auth login\` (or set ANTHROPIC_API_KEY)." >&2
  fi
  return $rc
}

# Error path shared by the widgets, called after `zle -I`. When logged out,
# offers the login and, if it worked, re-runs the widget once.
# Usage: _zsh_claude_code_widget_failed <error_text> <exit_code> <feature> <widget>
_zsh_claude_code_widget_failed() {
  emulate -L zsh
  local msg=$1 rc=$2 feature=$3 widget=$4
  local state=$(_zsh_claude_code_auth_state)
  if [[ $state == out ]]; then
    # The guard stops a loop if auth status and claude -p ever disagree.
    if (( ! _ZSH_CLAUDE_CODE_RETRYING )) && _zsh_claude_code_login_now; then
      local -i _ZSH_CLAUDE_CODE_RETRYING=1
      zle "$widget"
      return
    fi
    _zsh_claude_code_not_logged_in
    return $rc
  fi
  _zsh_claude_code_report_error "$msg" "$rc" "$feature" "$state"
  return $rc
}
