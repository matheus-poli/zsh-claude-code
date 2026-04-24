# zsh-claude-code — Claude-powered helpers for zsh.
# https://github.com/matheuspoli/zsh-claude-code

if ! command -v claude >/dev/null 2>&1; then
  _zsh_claude_code_missing() {
    print -r -- "zsh-claude-code: \`claude\` CLI not found in PATH. See https://claude.ai/claude-code" >&2
    return 127
  }
  ask()     { _zsh_claude_code_missing; }
  explain() { _zsh_claude_code_missing; }
  return 0
fi

_ZSH_CLAUDE_CODE_DIR=${0:A:h}
source "$_ZSH_CLAUDE_CODE_DIR/lib/common.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/ask.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/explain.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/suggest.zsh"
source "$_ZSH_CLAUDE_CODE_DIR/lib/explain-widget.zsh"
unset _ZSH_CLAUDE_CODE_DIR
