# zsh-claude-code — Claude-powered helpers for zsh.
# https://github.com/matheus-poli/zsh-claude-code

if ! command -v claude >/dev/null 2>&1; then
  _zsh_claude_code_missing() {
    print -r -- "zsh-claude-code: \`claude\` CLI not found in PATH. See https://claude.ai/claude-code" >&2
    return 127
  }
  # `function` is load-bearing here, not style: on a re-source `ask`/`explain`
  # are already aliases, and zsh alias-expands this whole if-block at parse time
  # even though the branch is skipped. `ask() { ... }` aborts the file instead.
  function ask     { _zsh_claude_code_missing; }
  function explain { _zsh_claude_code_missing; }
  return 0
fi

_ZSH_CLAUDE_CODE_DIR=${0:A:h}
source "$_ZSH_CLAUDE_CODE_DIR/lib/common.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/ask.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/explain.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/suggest.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/explain-widget.zsh"
unset _ZSH_CLAUDE_CODE_DIR
