# zsh-claude-code

A zsh plugin that adds Claude-powered helpers to the terminal:

- **`ask <question>`** — one-shot Q&A, prints a terse answer directly to the terminal.
- **`explain <command>`** — summarize a shell command in natural, concise English.
- **Ctrl+X widget** (`claude-suggest`) — rewrites the current command line (a natural-language request) into an executable shell command, in place. The user reviews and presses Enter to run (or edits first).
- **Alt+E widget** (`claude-explain-widget`) — explains the command currently typed at the prompt, printing the explanation above it while leaving the command intact.

All four use the `claude` CLI (Claude Code) in `--print` mode under the hood. The plugin is a thin, zero-runtime-dependency wrapper that:

1. Passes tuned `--system-prompt` text so Claude behaves like a terminal assistant.
2. Tunes flags for speed (`--no-session-persistence`, `--disable-slash-commands`, `--tools ""`).
3. Uses a cheaper/faster model (Haiku) for the inline-suggest widget, a prose-friendly model (Sonnet) for `explain`, and a more capable model (Opus) for `ask`.

## Target users

zsh users, typically with oh-my-zsh, who already use Claude Code and want low-friction terminal helpers without leaving their current shell/terminal/theme (pure, powerlevel10k, etc).

## Requirements

- `zsh` 5.0+
- The `claude` CLI installed and logged in (`claude login` or `ANTHROPIC_API_KEY` set)
- No other runtime dependencies

Dev-only tooling (managed via `mise`): `bats-core` (tests), `lefthook` + `commitlint` (commit-message linting). None of these are needed to use the plugin.

## Related projects

- [`HundredAcreStudio/zsh-claude`](https://github.com/HundredAcreStudio/zsh-claude) — talks to the Anthropic API directly (curl + jq), requires a personal API key. Different architecture.
- [`ArielTM/zsh-claude-code-shell`](https://github.com/ArielTM/zsh-claude-code-shell) — closest functional overlap. Also wraps the `claude` CLI, but triggers on `# <description>` + Enter (overrides `accept-line` globally) instead of a dedicated keybind. No `ask`/`explain` commands.

We chose a dedicated keybind over an Enter override because it is opt-in per keystroke and does not modify normal Enter behavior.

## Repository layout

```
zsh-claude-code/
├── CLAUDE.md                       # this file — context for Claude Code sessions
├── README.md                       # user-facing install & usage docs
├── CHANGELOG.md                    # maintained by release-please
├── LICENSE                         # MIT
├── version.txt                     # plugin version; bumped by release-please
├── mise.toml                       # pinned dev tools (bats, lefthook, commitlint)
├── lefthook.yml                    # commit-msg hook → commitlint
├── commitlint.config.js            # Conventional Commits rules
├── release-please-config.json      # release automation config
├── .release-please-manifest.json   # current version, per release-please
├── .github/workflows/
│   ├── ci.yml                      # lint + bats on ubuntu & macos, per push/PR
│   └── release-please.yml          # opens/maintains the release PR
├── zsh-claude-code.plugin.zsh      # oh-my-zsh entrypoint: guard + sources lib/*
├── lib/
│   ├── common.zsh                  # env-var defaults + `_zsh_claude_code_run` helper
│   ├── ask.zsh                     # `ask` function + alias
│   ├── explain.zsh                 # `explain` function + alias
│   ├── suggest.zsh                 # Ctrl+X widget (`claude-suggest`)
│   └── explain-widget.zsh          # Alt+E widget (`claude-explain-widget`)
├── scripts/
│   ├── setup.zsh                   # unified contributor bootstrap (`mise run setup`)
│   └── doctor.zsh                  # env diagnostics (`mise run doctor`)
└── test/
    ├── smoke.zsh                   # end-to-end smoke
    └── *.bats                      # bats-core unit tests
```

## Public surface (env vars users can override)

Declared with `: ${VAR:=default}` so user exports in `.zshrc` **before** plugin load take precedence. (Models can be changed at runtime by re-exporting the var; keybinds cannot — the bind happens once at source time.)

- `ZSH_CLAUDE_ASK_MODEL` — default `sonnet`
- `ZSH_CLAUDE_EXPLAIN_MODEL` — default `sonnet`
- `ZSH_CLAUDE_SUGGEST_MODEL` — default `sonnet`
- `ZSH_CLAUDE_SUGGEST_KEY` — default `^X`
- `ZSH_CLAUDE_EXPLAIN_KEY` — default `^[e` (Alt+E; overrides the rarely-used `capitalize-word`)
- `ZSH_CLAUDE_ASK_SYSTEM_PROMPT` — full override of the `ask` system prompt
- `ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT` — full override of the `explain` / explain-widget system prompt
- `ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT` — full override of the suggest-widget system prompt
- `ZSH_CLAUDE_EXTRA_FLAGS` — extra flags appended to every `claude` invocation (advanced)

Name prefixed `ZSH_CLAUDE_` to avoid collisions with the `claude` CLI's own env vars (`CLAUDE_*`, `ANTHROPIC_*`).

## Design notes / decisions

- **Why `--system-prompt` (full replace) instead of `--append-system-prompt`?** Claude Code's default system prompt is large and biased toward agentic tool-use. For quick terminal Q&A we don't want that context — full replace is faster and produces tighter answers.
- **Why `--tools ""`?** These helpers are text-in/text-out. Disabling tools prevents Claude from trying to read files or run commands, which would surprise the user and slow down responses.
- **Why not `--bare`?** `--bare` disables OAuth and the keychain, so users logged in via `claude login` would break. Stick to lighter flags that preserve auth.
- **Model choice.** All three features default to Sonnet. We originally picked Haiku for `suggest` on a "smaller-faster" hypothesis, but live-API measurements showed the opposite — Sonnet was consistently 2-3x faster wall-clock on short tools-disabled prompts. Users can still override per-feature via `ZSH_CLAUDE_*_MODEL` to pick Opus (stronger answers) or Haiku (cheaper tokens, expect higher latency today).
- **Why a dedicated widget keybind instead of overriding Enter or a `#` prefix?** Overriding `accept-line` means every single Enter press goes through our hook forever; a keybind is opt-in per keystroke and leaves default behavior untouched.
- **Suggest widget replaces `BUFFER`; explain widget does not.** `suggest` is a command-authoring flow — the user reviews the generated command and presses Enter. `explain` is a read-only flow — we print above the prompt with `zle -I` + `print` + `zle reset-prompt` so the user's typed command is preserved and can still be run or edited.
- **Why `noglob` on the aliases?** Users type questions/commands with `?`, `*`, `[...]`, which zsh would otherwise try to expand as globs and error out with "no matches found".
- **Why a helper function behind each alias?** `claude -p` only reads its first positional arg as the prompt, so we need to `"$*"`-join all the words into one prompt. Aliases can't do that alone.
- **Widget defensive output scrubbing.** Even with a strict system prompt, models occasionally wrap output in code fences or add stray newlines. The suggest widget strips ``` fences, backticks, and leading/trailing whitespace before dropping the result into `BUFFER`.
- **Suggest widget restores the original `BUFFER` on error**, so a failed call doesn't leave the user with an empty prompt.
- **Guard for missing `claude` lives in the entrypoint**, not `common.zsh`, so we install stubs for `ask`/`explain` and skip widget bindings entirely if `claude` isn't installed.

## Testing approach

- **Smoke test** (`test/smoke.zsh`): fresh zsh, source the plugin, call `ask "say OK"`, assert stdout contains `OK`. Skip silently if `claude` isn't installed/logged in.
- **Unit tests** (`test/*.bats`, bats-core): exercise pure logic that doesn't need the `claude` CLI — env-var defaults, `noglob` behavior, guard stub behavior when `claude` is masked out of PATH, output-scrub string transforms.
- **Manual test checklist** (in README for contributors):
  - `ask` and `explain` with special chars (`?`, `!`, `*`, quotes)
  - Ctrl+X with a clear command request ("find files larger than 10mb")
  - Ctrl+X with an ambiguous request (should still produce one command)
  - Alt+E on a typed command — explanation prints above, original command is preserved
  - All features with `claude` logged out → helpful error, not a crash
  - Custom keybinds via `ZSH_CLAUDE_SUGGEST_KEY` / `ZSH_CLAUDE_EXPLAIN_KEY` set *before* plugin load
- **Why no Bashly?** Bashly generates bash CLIs. The core value here is a zsh ZLE widget, which is zsh-only. A single sourceable `.plugin.zsh` is what oh-my-zsh expects; Bashly would add build-step overhead for no gain.
- **CI** (`.github/workflows/ci.yml`). Runs `mise run lint`, `mise run test`, and `mise run smoke` on every push to `main` and every PR, across `ubuntu-latest` and `macos-latest`. Both platforms are deliberate: the plugin is parsed by whatever zsh the user has, and the two runners give us two builds of 5.9. Ubuntu needs `zsh` apt-installed; macOS ships it as the default shell. Tools come from `mise.toml`, so CI and a contributor's `mise run check` use the same pinned bats. The smoke step has no `claude` credentials, so it is expected to print `smoke: skip` and pass — it runs anyway so the script can't rot unnoticed. Actions is free with unlimited minutes on public repos.
- **Local hooks** are the first gate, before CI: `lefthook` runs `zsh -n` + bats on `pre-commit` and the full `mise run check` on `pre-push`. They only protect contributors who ran `mise run setup`, which is why CI exists.

## Release / versioning

- **Strict [SemVer 2.0](https://semver.org/).** Start at `0.1.0`.
- Automated by **release-please** (`.github/workflows/release-please.yml`). Every push to `main` updates an open release PR carrying the computed bump, the `version.txt` change, and the `CHANGELOG.md` entry. Merging that PR is what cuts the tag and the GitHub release — so a release is one click, and `main` is always releasable without being released.
- The bump comes from the commit history per Conventional Commits:
  - `feat:` → MINOR bump
  - `fix:` → PATCH bump
  - `feat!:` / `BREAKING CHANGE:` footer → MAJOR bump (not MINOR — `bump-minor-pre-major` is left off, so a breaking change at 0.x goes to 1.0.0, per the strict-SemVer line above)
  - `chore:`, `docs:`, `test:`, `refactor:`, `ci:`, `build:`, `style:` → no release
- **In `changelog-sections`, a visible type is also a *releasable* type.** release-please offers no way to list a commit in the changelog without letting it bump the version, so `hidden: true` is what enforces the "no release" line above — that is why `docs:` and `refactor:` are hidden, not because they don't matter. Un-hiding a type to get it into the changelog also signs it up to cut releases: the first attempt at this config left `docs:` visible and release-please immediately proposed a v0.1.2 built entirely from README and CLAUDE.md commits. Only `feat:`, `fix:`, `perf:` and `revert:` reach the changelog.
- **`release-type` is `simple`, not `node`.** `package.json` is `private` and holds dev-only deps (commitlint, lefthook), so the plugin's version lives in `version.txt` instead.
- `.release-please-manifest.json` is the source of truth for the current version. It was seeded at `0.1.1` when the automation was added, so the manually-cut v0.1.0 and v0.1.1 aren't recomputed.
- **`CHANGELOG.md`** is maintained by release-please going forward. The v0.1.0 and v0.1.1 entries predate it and were backfilled once with `git-cliff` under the same visibility rules, so the whole file reflects one policy; git-cliff is not a project dependency.
- **Actions must be allowed to open PRs** for any of this to work: Settings → Actions → General → "Allow GitHub Actions to create and approve pull requests". Without it release-please does all its work and then fails on the final API call with `GitHub Actions is not permitted to create or approve pull requests`. `default_workflow_permissions` stays `read`, since the workflow declares what it needs explicitly.
- Known limitation: release-please runs as `GITHUB_TOKEN`, and a PR opened by that token does not trigger `ci.yml`. So the release PR itself is unchecked. Swap in a PAT via the action's `token:` input if that ever matters.
- Users install by cloning into `$ZSH_CUSTOM/plugins/zsh-claude-code` and adding `zsh-claude-code` to `plugins=(...)`. No package-manager integration for v0.1.
- Later: submit to `zinit`, `antidote`, Homebrew if there's demand.

## Non-goals

- **Chat / multi-turn in the terminal.** Users who want that should run `claude` directly. This plugin is for one-shot helpers.
- **Streaming output into the line editor.** The widget takes the final result only; streaming the greyed-out suggestion as tokens arrive is complex and not worth it for ~1–3s responses.
- **Supporting non-Claude providers.** The value prop is "Claude in your terminal"; a generic wrapper already exists (`llm`, `sgpt`).
- **Shipping additional default keybinds.** Users can set `ZSH_CLAUDE_SUGGEST_KEY` / `ZSH_CLAUDE_EXPLAIN_KEY` if they want something else; we don't guess.

## Conventions

- **Commit style:** [Conventional Commits](https://www.conventionalcommits.org/) — enforced by commitlint via a lefthook `commit-msg` hook. Types allowed: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`, `perf`, `build`, `revert`, `style`. This drives automated semver bumps (see Release section).
- **Branch naming:** `feat/...`, `fix/...`, `docs/...` for PRs; `main` is the default branch.
- **Shell style:** prefer POSIX-ish zsh. Quote expansions. Use `local` for function vars. `emulate -L zsh` at the top of functions that care about option state.
- **No emojis in code or commits** unless a user-facing string benefits from one (e.g. the widget's "⏳ asking claude…" placeholder).
- **Dev environment:** pinned via `mise.toml`. After cloning, run `mise run setup` — it chains `mise install` → `npm install` → `lefthook install` in one shot (see `scripts/setup.zsh`). `mise run doctor` diagnoses a broken env; `mise run check` runs lint + tests + smoke before a PR.

## Known issues / TODO

- Widgets block the prompt while waiting (~1–3s on Haiku, longer for Sonnet/Opus). Async via `zsh/zpty` or a background subshell + `zle -I` would fix it; parked for v0.2.
- No telemetry, no cost tracking. If a user burns through API quota the plugin gives no warning.
- Keybinds are resolved at source time, so changing `ZSH_CLAUDE_SUGGEST_KEY` / `ZSH_CLAUDE_EXPLAIN_KEY` after plugin load has no effect — the user must re-source their `.zshrc`.
