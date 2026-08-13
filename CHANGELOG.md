# Changelog

## [0.1.1](https://github.com/matheus-poli/zsh-claude-code/compare/v0.1.0...v0.1.1) (2026-08-13)


### Bug Fixes

* parse error when plugin is re-sourced after aliases exist ([#1](https://github.com/matheus-poli/zsh-claude-code/pull/1)) ([5c4becd](https://github.com/matheus-poli/zsh-claude-code/commit/5c4becd4fe385cdfd1832eb65b5ad33049b3f23f))


### Documentation

* update live demo ([b20b24f](https://github.com/matheus-poli/zsh-claude-code/commit/b20b24f755111bcf3a994e44da2fb915c99f2afe))
* quote explain command example in README ([833e3d2](https://github.com/matheus-poli/zsh-claude-code/commit/833e3d261d1ee312cccd13ec360a90db6b7085a4))
* explain why the guard stubs use the function keyword ([a6a3241](https://github.com/matheus-poli/zsh-claude-code/commit/a6a3241cb497c54cd43344d89f0711d305037c8c))
* correct the CI and release claims in CLAUDE.md ([076bf9b](https://github.com/matheus-poli/zsh-claude-code/commit/076bf9bf1518c6a4c8a45da37e25f77fde65e03b))

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


### Documentation

* replace em dashes with plain hyphens in README ([1d8721a](https://github.com/matheus-poli/zsh-claude-code/commit/1d8721a386f60784d4d7b4809c72a23d9ae9294b))
* remove Related projects section ([dafffb0](https://github.com/matheus-poli/zsh-claude-code/commit/dafffb0801b351a3227252406930056f59f35be6))
* fix Claude Code link and add oh-my-zsh link ([915f276](https://github.com/matheus-poli/zsh-claude-code/commit/915f276c2d98e1022b3e47d7484fc5df5dab0f3f))
* render keyboard shortcuts with <kbd> tags ([9df715d](https://github.com/matheus-poli/zsh-claude-code/commit/9df715dbb4c519a48a1f344d96499b720029341f))
* use bash language tag for shell examples ([be05308](https://github.com/matheus-poli/zsh-claude-code/commit/be05308e0f2f48540cc84be5cda39bfb1cf13cc0))
* recommend zinit as primary install method ([0a89a6f](https://github.com/matheus-poli/zsh-claude-code/commit/0a89a6fbca9ef25c19128e5dcd4581359ac2d355))
* add a live demo ([9b506b6](https://github.com/matheus-poli/zsh-claude-code/commit/9b506b60bcf0163799288794d32efa7277ad3c77))
* update live demo ([d2d284c](https://github.com/matheus-poli/zsh-claude-code/commit/d2d284c8f3b0c6bb36844394d2c32436c6fe96d9))
* add widget keybind quick-reference above Features ([9e42102](https://github.com/matheus-poli/zsh-claude-code/commit/9e4210265299952d817f77148b1228de15209e5a))
