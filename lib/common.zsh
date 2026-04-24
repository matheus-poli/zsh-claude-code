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
