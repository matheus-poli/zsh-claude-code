#!/usr/bin/env zsh
# Diagnostic for the zsh-claude-code contributor environment.
#
# Checks: mise + pinned tools, npm deps installed, lefthook git hooks wired,
# and the `claude` CLI runtime dependency. Exits 0 if healthy, 1 if any
# critical piece is missing.

emulate -L zsh
setopt pipefail

cd "${0:A:h}/.."

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != dumb ]]; then
  _b=$'\e[1m' _d=$'\e[2m' _r=$'\e[0m'
  _red=$'\e[31m' _grn=$'\e[32m' _ylw=$'\e[33m' _blu=$'\e[34m'
else
  _b= _d= _r= _red= _grn= _ylw= _blu=
fi

_head() { print -r -- "${_b}${_blu}==>${_r} ${_b}$*${_r}"; }
_ok()   { print -r -- "  ${_grn}ok${_r}    $1${2:+  ${_d}$2${_r}}"; }
_warn() { print -r -- "  ${_ylw}warn${_r}  $1${2:+  ${_d}$2${_r}}"; }
_fail() { print -r -- "  ${_red}fail${_r}  $1${2:+  ${_d}$2${_r}}" >&2; }

typeset -i failures=0
_record_fail() { failures=$(( failures + 1 )); }

_head "zsh-claude-code doctor"
print

_head "Tools"
if command -v mise >/dev/null 2>&1; then
  _ok "mise" "$(mise --version 2>/dev/null | head -1)"
else
  _fail "mise" "not installed — https://mise.jdx.dev"
  _record_fail
fi
_ok "zsh" "$ZSH_VERSION"

if v=$(mise exec -- node --version 2>/dev/null); then
  _ok "node" "$v"
else
  _fail "node" "missing — run \`mise install\`"
  _record_fail
fi

if v=$(mise exec -- bats --version 2>/dev/null); then
  _ok "bats" "$v"
else
  _fail "bats" "missing — run \`mise install\`"
  _record_fail
fi

if v=$(mise exec -- lefthook version 2>/dev/null); then
  _ok "lefthook" "$v"
else
  _fail "lefthook" "missing — run \`mise install\`"
  _record_fail
fi
print

_head "Dependencies & git hooks"
if [[ -d node_modules ]]; then
  _ok "node_modules/" "present"
else
  _fail "node_modules/" "missing — run \`mise run setup\`"
  _record_fail
fi

if [[ -f .git/hooks/commit-msg ]] && grep -q lefthook .git/hooks/commit-msg 2>/dev/null; then
  _ok ".git/hooks/commit-msg" "lefthook wired"
else
  _fail ".git/hooks/commit-msg" "not wired — run \`mise run setup\`"
  _record_fail
fi

if [[ -f .git/hooks/pre-commit ]] && grep -q lefthook .git/hooks/pre-commit 2>/dev/null; then
  _ok ".git/hooks/pre-commit" "lefthook wired"
else
  _warn ".git/hooks/pre-commit" "not wired — run \`mise run setup\`"
fi

if [[ -f .git/hooks/pre-push ]] && grep -q lefthook .git/hooks/pre-push 2>/dev/null; then
  _ok ".git/hooks/pre-push" "lefthook wired"
else
  _warn ".git/hooks/pre-push" "not wired — run \`mise run setup\`"
fi
print

_head "Runtime (claude CLI)"
if command -v claude >/dev/null 2>&1; then
  _ok "claude" "$(command -v claude)"
else
  _warn "claude" "not found — https://claude.ai/claude-code"
fi
print

if (( failures > 0 )); then
  print -r -- "${_b}${_red}==>${_r} ${_b}$failures issue(s) found.${_r} Fix with ${_b}mise run setup${_r}."
  exit 1
fi
print -r -- "${_b}${_grn}==>${_r} ${_b}All good.${_r}"
