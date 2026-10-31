#!/usr/bin/env zsh
# Latency and token benchmark for the plugin's models (`mise run bench`).
#
# Calls the plugin's own runner (_zsh_claude_code_run) with each feature's
# real system prompt, so flags match what users get, and adds
# `--output-format json` through ZSH_CLAUDE_EXTRA_FLAGS to read usage and
# cost. Model order rotates every call so none always runs first.
#
# Usage: mise run bench -- [-n reps] [model ...]
#   defaults: 3 reps; models sonnet haiku opus fable
#
# Makes real API calls (models x 6 prompts x reps) that count against the
# logged-in account. Raw results land in a temp dir printed at the end.

emulate -L zsh
setopt pipefail
zmodload zsh/datetime

repo=${0:A:h:h}

typeset -i reps=3
if [[ $1 == -n ]]; then
  reps=$2
  shift 2
fi
typeset -a models
models=("$@")
(( ${#models} )) || models=(sonnet haiku opus fable)

if ! command -v claude >/dev/null 2>&1; then
  print -r -- "bench: claude CLI not found in PATH" >&2
  exit 127
fi

source "$repo/lib/common.zsh"
# Only the first line of each feature file sets its prompt; the rest binds
# widgets, which needs an interactive shell.
eval "$(head -1 "$repo/lib/suggest.zsh")"
eval "$(head -1 "$repo/lib/explain.zsh")"
eval "$(head -1 "$repo/lib/ask.zsh")"

typeset -A sys
sys=(
  suggest "$ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT"
  explain "$ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT"
  ask     "$ZSH_CLAUDE_ASK_SYSTEM_PROMPT"
)
# feature|prompt
typeset -a cases
cases=(
  "suggest|find files larger than 10mb in the current directory"
  "suggest|list the 5 biggest directories under home, human readable"
  "explain|tar -czvf backup.tar.gz --exclude=node_modules ."
  "explain|git log --oneline --graph --decorate --all | head -20"
  "ask|how do I see which process is listening on port 8080?"
  "ask|difference between \$@ and \$* in zsh?"
)

out=$(mktemp -d "${TMPDIR:-/tmp}/zsh-claude-code-bench.XXXXXX")
# Run from an empty dir: users call the helpers from anywhere, and this
# repo's own CLAUDE.md would otherwise inflate every call's context.
work=$out/cwd
mkdir -p "$work"
cd "$work"

ZSH_CLAUDE_EXTRA_FLAGS="--output-format json${ZSH_CLAUDE_EXTRA_FLAGS:+ $ZSH_CLAUDE_EXTRA_FLAGS}"

typeset -i total=$(( reps * ${#cases} * ${#models} )) done=0
print -r -- "bench: $total calls (${#models} models x ${#cases} prompts x $reps reps)"

for (( r = 1; r <= reps; r++ )); do
  for (( c = 1; c <= ${#cases}; c++ )); do
    feature=${cases[c]%%|*} text=${cases[c]#*|}
    for (( k = 0; k < ${#models}; k++ )); do
      model=${models[(( (k + r + c) % ${#models} + 1 ))]}
      t0=$EPOCHREALTIME
      # </dev/null: with a non-tty stdin, claude -p waits 3s for piped input.
      json=$(_zsh_claude_code_run "$model" "${sys[$feature]}" "$text" 2>/dev/null </dev/null)
      rc=$?
      print -r -- "$json" > "$out/r$r-c$c-$model.json"
      printf '%s\t%s\t%d\t%d\t%.0f\n' "$model" "$feature" "$c" "$rc" \
        "$(( (EPOCHREALTIME - t0) * 1000 ))" >> "$out/index.tsv"
      (( done++ ))
      printf '\r  %d/%d' $done $total
    done
  done
done
print

mise exec -- node "$repo/scripts/bench-report.mjs" "$out"
print -r -- "raw results: $out"
