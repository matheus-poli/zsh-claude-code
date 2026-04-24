#!/usr/bin/env zsh
# Unified contributor setup for zsh-claude-code.
#
# Runs, in order:
#   1. prereq check (mise is required — everything else is pinned by it)
#   2. `mise install`         — pulls node, bats, lefthook at pinned versions
#   3. `npm install`          — installs commitlint devDependencies
#   4. `lefthook install`     — wires git hooks (commit-msg, pre-commit)
# Then soft-checks for the `claude` CLI (warn, don't fail) and prints a
# summary of the next commands to try.
#
# Idempotent — safe to re-run. Respects NO_COLOR and non-TTY stdout.

emulate -L zsh
setopt err_exit pipefail

cd "${0:A:h}/.."

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != dumb ]]; then
  _b=$'\e[1m' _d=$'\e[2m' _r=$'\e[0m'
  _red=$'\e[31m' _grn=$'\e[32m' _ylw=$'\e[33m' _blu=$'\e[34m'
else
  _b= _d= _r= _red= _grn= _ylw= _blu=
fi

_head() { print -r -- "${_b}${_blu}==>${_r} ${_b}$*${_r}"; }
_step() { print -r -- "${_b}${_blu}[$1/$2]${_r} $3"; }
_ok()   { print -r -- "  ${_grn}ok${_r}    $*"; }
_warn() { print -r -- "  ${_ylw}warn${_r}  $*"; }
_fail() { print -r -- "  ${_red}fail${_r}  $*" >&2; }
_hint() { print -r -- "  ${_d}$*${_r}"; }

TOTAL=4

_head "zsh-claude-code setup"
print

_step 1 $TOTAL "Checking prerequisites"
if ! command -v mise >/dev/null 2>&1; then
  _fail "mise not found in PATH"
  _hint "install: https://mise.jdx.dev/getting-started.html"
  _hint "then re-run: ./scripts/setup.zsh"
  exit 127
fi
_ok "mise   $(mise --version 2>/dev/null | head -1)"
_ok "zsh    $ZSH_VERSION"
print

_step 2 $TOTAL "Installing pinned tools (mise install)"
mise install
print

_step 3 $TOTAL "Installing commitlint (npm install)"
mise exec -- npm install --silent --no-fund --no-audit
print

_step 4 $TOTAL "Installing git hooks (lefthook install)"
mise exec -- lefthook install
print

_head "Soft checks"
if command -v claude >/dev/null 2>&1; then
  _ok "claude CLI detected at $(command -v claude)"
else
  _warn "\`claude\` CLI not found in PATH"
  _hint "plugin no-ops gracefully without it; install: https://claude.ai/claude-code"
  _hint "required only for the smoke test (mise run smoke)"
fi
print

print -r -- "${_b}${_grn}==>${_r} ${_b}Setup complete.${_r}"
print
print -r -- "Next:"
print -r -- "  ${_b}mise run test${_r}     run unit tests"
print -r -- "  ${_b}mise run check${_r}    lint + tests + smoke"
print -r -- "  ${_b}mise run doctor${_r}   diagnose environment"
