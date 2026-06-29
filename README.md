# zsh-how

A `how` command that tells you how to run the project in the current directory. Run `how` and it detects the project files (justfile, package.json, pyproject.toml, Cargo.toml, go.mod, Makefile, Docker) and prints the available commands and scripts.

```
~/> how
▸ Node  (package.json → pnpm)
  pnpm run dev                 next dev
  pnpm run build               next build
  pnpm run test                vitest run

▸ Make  (Makefile)
  make up                      start all services
  make down                    stop all services
```

## Setup

oh-my-zsh:

```sh
git clone https://github.com/OverloadUT/zsh-how "$ZSH_CUSTOM/plugins/zsh-how"
```

Then add `zsh-how` to `plugins=(...)` in your `.zshrc` and restart your shell.

Without oh-my-zsh, source it directly: `source /path/to/zsh-how.plugin.zsh`.
