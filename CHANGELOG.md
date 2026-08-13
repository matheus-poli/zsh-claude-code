# Changelog

## [0.1.1](https://github.com/matheus-poli/zsh-claude-code/compare/v0.1.0...v0.1.1) (2026-08-13)


### Bug Fixes

* parse error when plugin is re-sourced after aliases exist ([#1](https://github.com/matheus-poli/zsh-claude-code/pull/1)) ([5c4becd](https://github.com/matheus-poli/zsh-claude-code/commit/5c4becd4fe385cdfd1832eb65b5ad33049b3f23f))

## [0.1.0](https://github.com/matheus-poli/zsh-claude-code/releases/tag/v0.1.0) (2026-04-24)


### Features

* initial plugin scaffold with ask, explain, and widgets ([c394707](https://github.com/matheus-poli/zsh-claude-code/commit/c394707adadebf47ee0a8cc19a2c093e61199b95))
* change explain widget default keybind to Alt+E ([12d5101](https://github.com/matheus-poli/zsh-claude-code/commit/12d510132643b769f06d9cf4b4ea8216295a8c39))
* animated spinner during async claude calls ([7bc43a8](https://github.com/matheus-poli/zsh-claude-code/commit/7bc43a89cd30ff10340952f2f29937e3178ca363))
* keep user request visible during spinner ([dab728f](https://github.com/matheus-poli/zsh-claude-code/commit/dab728fdd16d644302b0e6d683be6f0c6d5504e1))
* show spinner on line below the request ([f83c96a](https://github.com/matheus-poli/zsh-claude-code/commit/f83c96a23027bf85f9892da18244ff124bfc7779))
* default all features to sonnet ([421afe7](https://github.com/matheus-poli/zsh-claude-code/commit/421afe716072f121b30a573b19ebcbffd4f08060))


### Bug Fixes

* surface claude auth/error messages with login hint ([815340c](https://github.com/matheus-poli/zsh-claude-code/commit/815340cca09bd2efc744ef94a11dd069d83d5617))
* run bats on every pre-commit, fix glob syntax ([9478fd5](https://github.com/matheus-poli/zsh-claude-code/commit/9478fd555d2d457dd992c98037f368366c5b8ad7))
* guard unfunction so plugin source survives `set -e` ([faf44fa](https://github.com/matheus-poli/zsh-claude-code/commit/faf44faa06f77c3edf5cd941993791a3ec696c1b))
