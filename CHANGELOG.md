# Changelog

## [0.2.0](https://github.com/matheus-poli/zsh-claude-code/compare/v0.1.2...v0.2.0) (2026-10-31)


### Features

* offer to run `claude auth login` from ask and explain ([42e1a9e](https://github.com/matheus-poli/zsh-claude-code/commit/42e1a9ed415d0e71fe08c0ae68880adf4bf95fb0))


### Bug Fixes

* point the login hint at `claude auth login` ([56aedc5](https://github.com/matheus-poli/zsh-claude-code/commit/56aedc5cd5830c7adb4f691da3e89b488d4cc833))

## [0.1.2](https://github.com/matheus-poli/zsh-claude-code/compare/v0.1.1...v0.1.2) (2026-10-31)


### Performance

* default the suggest widget to haiku ([41b6c0f](https://github.com/matheus-poli/zsh-claude-code/commit/41b6c0fce15323de3f66aab3948bef147a8d5c40))
* stop sending the user's MCP servers with every call ([2a6b2bf](https://github.com/matheus-poli/zsh-claude-code/commit/2a6b2bfbf3ce9d55ba28cf515d134821e77c65da))

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
