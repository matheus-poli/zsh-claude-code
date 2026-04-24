# zsh-claude-code

Claude-powered helpers for your zsh prompt. Ask questions, explain commands, and turn natural language into shell commands - without leaving the terminal.

All four features wrap the [`claude` CLI](https://claude.ai/claude-code) (Claude Code) in `--print` mode, so if you're already logged in with `claude login` there's nothing else to set up.

## Features

| | What | Trigger | Default model |
|---|---|---|---|
| **Ask** | Terse answer to any dev/terminal question | `ask <question>` | `opus` |
| **Explain** | Summarize a command in natural, concise English | `explain <command>` | `sonnet` |
| **Suggest widget** | Rewrite the current line (natural language) → one shell command, in place | `Ctrl+X` | `haiku` |
| **Explain widget** | Explain the command currently at the prompt, above it (command stays intact) | `Alt+E` | `sonnet` |

## Requirements

- `zsh` 5.0+
- [`claude` CLI](https://claude.ai/claude-code) installed and authenticated (either `claude login` or `ANTHROPIC_API_KEY` in the environment)
- No other runtime dependencies

## Installation

### oh-my-zsh

```sh
git clone https://github.com/matheus-poli/zsh-claude-code \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-claude-code"
```

Add `zsh-claude-code` to your `plugins=(...)` in `~/.zshrc`, then restart your shell or `source ~/.zshrc`.

### Manual

```sh
git clone https://github.com/matheus-poli/zsh-claude-code ~/.zsh-claude-code
echo 'source ~/.zsh-claude-code/zsh-claude-code.plugin.zsh' >> ~/.zshrc
```

### zinit

```sh
zinit light matheus-poli/zsh-claude-code
```

## Usage

### `ask`

```sh
ask how do I list files modified in the last 24 hours
ask "what's the difference between \$* and \$@ in zsh?"
```

Prints a terse answer. If the answer is a command, it shows the command first in a fenced block, then at most one short line of context.

### `explain`

```sh
explain find . -type f -exec md5sum {} + | sort | uniq -w32 -dD
```

Prints one overview line + a short bullet per flag/argument.

### Suggest widget (`Ctrl+X`)

Type a natural-language request, then press **Ctrl+X**:

```text
find all js files larger than 100kb modified in the last week
```

becomes:

```sh
find . -name "*.js" -size +100k -mtime -7
```

Review the command, press **Enter** to run (or edit first).

### Explain widget (`Alt+E`)

Type or paste a command at the prompt, then press **Alt+E**. The explanation prints above the prompt; your command stays intact so you can still edit or run it.

## Configuration

Set any of these in `~/.zshrc` **before** the plugin loads (especially keybinds - they're resolved at source time).

| Variable | Default | Description |
|---|---|---|
| `ZSH_CLAUDE_ASK_MODEL` | `opus` | Model for `ask` |
| `ZSH_CLAUDE_EXPLAIN_MODEL` | `sonnet` | Model for `explain` + explain widget |
| `ZSH_CLAUDE_SUGGEST_MODEL` | `haiku` | Model for the suggest widget |
| `ZSH_CLAUDE_SUGGEST_KEY` | `^X` | Keybind for the suggest widget |
| `ZSH_CLAUDE_EXPLAIN_KEY` | `^[e` | Keybind for the explain widget (`^[e` = Alt+E) |
| `ZSH_CLAUDE_ASK_SYSTEM_PROMPT` | *(built-in)* | Full override of the `ask` system prompt |
| `ZSH_CLAUDE_EXPLAIN_SYSTEM_PROMPT` | *(built-in)* | Full override of the `explain` system prompt |
| `ZSH_CLAUDE_SUGGEST_SYSTEM_PROMPT` | *(built-in)* | Full override of the suggest system prompt |
| `ZSH_CLAUDE_EXTRA_FLAGS` | *(empty)* | Extra flags appended to every `claude -p` call (advanced) |

### Example: change keybind and use a stronger suggest model

```sh
# ~/.zshrc - BEFORE the plugins=(...) line
export ZSH_CLAUDE_SUGGEST_KEY='^G'         # Ctrl+G instead of Ctrl+X
export ZSH_CLAUDE_SUGGEST_MODEL='sonnet'   # more accurate, slightly slower
```

## Troubleshooting

- **"command not found: claude"** - the plugin no-ops gracefully when `claude` isn't on `$PATH`. Install Claude Code and run `claude login`.
- **Widget doesn't fire** - another plugin may have rebound `^X`. Try setting `ZSH_CLAUDE_SUGGEST_KEY` to something else, or use `bindkey | grep claude` to confirm the binding.
- **Output has stray backticks / code fences** - please open an issue with the input that produced it. The suggest widget already scrubs fences defensively, but prompts evolve.

## Contributing

Contributions welcome - PRs, bug reports, feature ideas. Quick start:

```sh
git clone https://github.com/matheus-poli/zsh-claude-code
cd zsh-claude-code
mise install   # pins zsh, bats, lefthook, commitlint
lefthook install
bats test/
```

**Commits follow [Conventional Commits](https://www.conventionalcommits.org/)** (`feat:`, `fix:`, `docs:`, `chore:`, …) - enforced by commitlint via a lefthook `commit-msg` hook. This drives automated semver releases.

**Manual test checklist** before sending a PR that touches the plugin code:

- `ask` and `explain` with `?`, `!`, `*`, and quoted strings
- Ctrl+X with a clear request and an ambiguous one
- Alt+E on a typed command - original command must stay intact
- All four features with `claude` logged out → helpful error, not a crash
- Custom keybinds set before plugin load

See [CLAUDE.md](./CLAUDE.md) for design notes and the full rationale behind each decision.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/matheus-poli"><img src="https://avatars.githubusercontent.com/u/25781749?v=4?s=100" width="100px;" alt="Matheus Poli"/><br /><sub><b>Matheus Poli</b></sub></a><br /><a href="https://github.com/matheus-poli/zsh-claude-code/commits?author=matheus-poli" title="Code">💻</a> <a href="https://github.com/matheus-poli/zsh-claude-code/commits?author=matheus-poli" title="Documentation">📖</a> <a href="#maintenance-matheus-poli" title="Maintenance">🚧</a> <a href="#design-matheus-poli" title="Design">🎨</a> <a href="#ideas-matheus-poli" title="Ideas, Planning, & Feedback">🤔</a></td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification. Contributions of any kind welcome!

To add yourself after a merged PR, comment on the PR:

```
@all-contributors please add @your-username for code, doc
```

## License

[MIT](./LICENSE) © Matheus Poli
