#!/usr/bin/env bats
# Unit tests that don't require a working `claude` CLI. We either stub `claude`
# in a temp PATH, or remove it entirely to exercise the guard path.

setup() {
  PLUGIN_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  STUB_DIR="$(mktemp -d)"
  # Minimal PATH: stub dir + /usr/bin + /bin, so zsh built-ins and basic tools
  # (mktemp, rm) work but we control whether `claude` is visible.
  STUB_PATH="$STUB_DIR:/usr/bin:/bin"
  EMPTY_DIR="$(mktemp -d)"
  EMPTY_PATH="$EMPTY_DIR:/usr/bin:/bin"
}

teardown() {
  rm -rf "$STUB_DIR" "$EMPTY_DIR"
}

# Create a fake `claude` binary that just echoes its last arg.
stub_claude() {
  cat > "$STUB_DIR/claude" <<'SH'
#!/bin/sh
# consume flags, echo last positional
while [ $# -gt 1 ]; do shift; done
printf '%s' "$1"
SH
  chmod +x "$STUB_DIR/claude"
}

@test "guard: missing claude installs ask/explain stubs returning 127" {
  run zsh -c "
    export PATH='$EMPTY_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    typeset -f ask >/dev/null && print -r -- ask_defined
    typeset -f explain >/dev/null && print -r -- explain_defined
    ask 2>&1 | grep -q 'not found in PATH' && print -r -- message_shown
    ask; print -r -- \"rc=\$?\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ask_defined"* ]]
  [[ "$output" == *"explain_defined"* ]]
  [[ "$output" == *"message_shown"* ]]
  [[ "$output" == *"rc=127"* ]]
}

@test "guard: missing claude does NOT bind the suggest widget" {
  run zsh -c "
    export PATH='$EMPTY_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    # zle -la lists widgets; should not include claude-suggest
    if zle -la claude-suggest 2>/dev/null; then
      print -r -- widget_bound_unexpectedly
    else
      print -r -- widget_not_bound
    fi
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"widget_not_bound"* ]]
}

@test "env: defaults are applied when nothing is set" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    unset ZSH_CLAUDE_ASK_MODEL ZSH_CLAUDE_EXPLAIN_MODEL ZSH_CLAUDE_SUGGEST_MODEL
    unset ZSH_CLAUDE_SUGGEST_KEY ZSH_CLAUDE_EXPLAIN_KEY
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    print -r -- \"ask=\$ZSH_CLAUDE_ASK_MODEL\"
    print -r -- \"explain=\$ZSH_CLAUDE_EXPLAIN_MODEL\"
    print -r -- \"suggest=\$ZSH_CLAUDE_SUGGEST_MODEL\"
    print -r -- \"sk=\$ZSH_CLAUDE_SUGGEST_KEY\"
    print -r -- \"ek=\$ZSH_CLAUDE_EXPLAIN_KEY\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"ask=opus"* ]]
  [[ "$output" == *"explain=sonnet"* ]]
  [[ "$output" == *"suggest=haiku"* ]]
  [[ "$output" == *"sk=^X"* ]]
  [[ "$output" == *"ek=^X^E"* ]]
}

@test "env: user overrides set before load are preserved" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    export ZSH_CLAUDE_ASK_MODEL=sonnet
    export ZSH_CLAUDE_SUGGEST_MODEL=opus
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    print -r -- \"\$ZSH_CLAUDE_ASK_MODEL \$ZSH_CLAUDE_SUGGEST_MODEL\"
  "
  [ "$status" -eq 0 ]
  [[ "${output}" == *"sonnet opus"* ]]
}

@test "alias: ask and explain use noglob" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    alias ask
    alias explain
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"noglob _zsh_claude_code_ask"* ]]
  [[ "$output" == *"noglob _zsh_claude_code_explain"* ]]
}

@test "widget: claude-suggest is registered when claude is present" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    typeset -f claude-suggest >/dev/null && print -r -- suggest_defined
    typeset -f claude-explain-widget >/dev/null && print -r -- explain_widget_defined
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"suggest_defined"* ]]
  [[ "$output" == *"explain_widget_defined"* ]]
}

@test "ask: joins multiple words into one prompt arg" {
  stub_claude
  # Call the underlying function directly — the `noglob` alias only expands
  # in interactive zsh, so we bypass it here and separately assert the alias
  # form in the `noglob` test above.
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_ask what is two plus two
  "
  [ "$status" -eq 0 ]
  [[ "$output" == "what is two plus two" ]]
}
