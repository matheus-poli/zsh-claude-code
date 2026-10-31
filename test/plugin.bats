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

@test "guard: plugin re-sources cleanly once ask/explain aliases exist" {
  stub_claude
  # After the first load, `ask`/`explain` are aliases (lib/ask.zsh,
  # lib/explain.zsh). Re-sourcing must not alias-expand the guard stub
  # names while the if-block is parsed (regression: "defining function
  # based on alias `ask'" + "parse error near `()'").
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh' && print -r -- resourced_ok
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"resourced_ok"* ]]
  [[ "$output" != *"parse error"* ]]
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
  [[ "$output" == *"ask=sonnet"* ]]
  [[ "$output" == *"explain=sonnet"* ]]
  [[ "$output" == *"suggest=haiku"* ]]
  [[ "$output" == *"sk=^X"* ]]
  [[ "$output" == *"ek=^[e"* ]]
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

@test "ask: prints login hint when claude exits non-zero" {
  # Stub claude that simulates a logged-out CLI.
  cat > "$STUB_DIR/claude" <<'SH'
#!/bin/sh
echo "Invalid API key. Please run /login" >&2
exit 1
SH
  chmod +x "$STUB_DIR/claude"
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_ask hello 2>&1
    print -r -- \"rc=\$?\"
  "
  [[ "$output" == *"Invalid API key"* ]]
  [[ "$output" == *"claude auth login"* ]]
  [[ "$output" == *"ask failed"* ]]
  [[ "$output" == *"rc=1"* ]]
}

@test "report_error: generic non-auth error does not force login hint" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_report_error 'Network timeout' 2 suggest
  "
  [[ "$output" == *"suggest failed (exit 2)"* ]]
  [[ "$output" == *"Network timeout"* ]]
  [[ "$output" != *"claude auth login"* ]]
}

@test "report_error: auth-ish error adds login hint" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_report_error 'Unauthorized: missing credential' 1 suggest
  "
  [[ "$output" == *"claude auth login"* ]]
}

@test "report_error: claude's own not-logged-in message adds login hint" {
  stub_claude
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_report_error 'Not logged in · Please run /login' 1 suggest
  "
  [[ "$output" == *"Not logged in"* ]]
  [[ "$output" == *"claude auth login"* ]]
}

# Fake claude for the login flow: `auth status` reports logged out (and, like
# the real CLI, exits 1) until `auth login` creates $STUB_DIR/logged-in;
# -p calls fail the same way.
stub_claude_auth() {
  cat > "$STUB_DIR/claude" <<SH
#!/bin/sh
state='$STUB_DIR/logged-in'
case "\$1 \$2" in
  "auth status")
    if [ -f "\$state" ]; then echo '{ "loggedIn": true }'; exit 0; fi
    echo '{ "loggedIn": false }'; exit 1 ;;
  "auth login")
    touch "\$state"; echo "Login successful."; exit 0 ;;
esac
if [ -f "\$state" ]; then echo "answer"; exit 0; fi
echo "Not logged in · Please run /login"
exit 1
SH
  chmod +x "$STUB_DIR/claude"
}

@test "auth_state: reads claude auth status, not its exit code" {
  stub_claude_auth
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_auth_state
    touch '$STUB_DIR/logged-in'
    _zsh_claude_code_auth_state
    rm -f '$STUB_DIR/claude'
    print -r -- \"[\$(_zsh_claude_code_auth_state)]\"
  "
  [[ "$output" == $'out\nin\n[]' ]]
}

@test "ask: logged in but failing, no login hint" {
  cat > "$STUB_DIR/claude" <<'SH'
#!/bin/sh
if [ "$1 $2" = "auth status" ]; then echo '{ "loggedIn": true }'; exit 0; fi
echo "There's an issue with the selected model" ; exit 1
SH
  chmod +x "$STUB_DIR/claude"
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_ask hello </dev/null 2>&1
  "
  [[ "$output" == *"ask failed (exit 1)."* ]]
  [[ "$output" != *"claude auth login"* ]]
}

@test "ask: without a terminal, prints the hint and does not prompt" {
  stub_claude_auth
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_ask hello </dev/null 2>&1
    print -r -- \"rc=\$?\"
  "
  [[ "$output" == *"claude auth login"* ]]
  [[ "$output" != *"[y/N]"* ]]
  [[ "$output" == *"rc=1"* ]]
  [ ! -f "$STUB_DIR/logged-in" ]
}

@test "ask: at a terminal, offers login, runs it on y, and retries" {
  command -v script >/dev/null || skip "script(1) not available"
  stub_claude_auth
  local cmd="export PATH='$STUB_PATH'; source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'; _zsh_claude_code_ask hello; print -r -- rc=\$?"
  # script(1) gives the command a pty; its flags differ between util-linux and BSD.
  if script --version >/dev/null 2>&1; then
    run sh -c "printf y | script -qec \"zsh -c \\\"$cmd\\\"\" /dev/null"
  else
    run sh -c "printf y | script -q /dev/null zsh -c \"$cmd\""
  fi
  [[ "$output" == *"[y/N]"* ]]
  [[ "$output" == *"Login successful."* ]]
  [[ "$output" == *"answer"* ]]
  [[ "$output" == *"rc=0"* ]]
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

@test "run: skips the user's MCP servers" {
  # Stub that prints every arg on its own line, so we can assert on flags.
  cat > "$STUB_DIR/claude" <<'SH'
#!/bin/sh
printf '%s\n' "$@"
SH
  chmod +x "$STUB_DIR/claude"
  run zsh -c "
    export PATH='$STUB_PATH'
    source '$PLUGIN_DIR/zsh-claude-code.plugin.zsh'
    _zsh_claude_code_run sonnet 'sys' 'prompt'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\n--strict-mcp-config\n'* ]]
}
