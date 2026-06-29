# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`zsh-how` is an oh-my-zsh plugin that provides a single `how` function. When run in any directory, it detects project files and displays the available commands/scripts for that project (e.g., npm scripts, make targets, cargo commands).

## Architecture

The entire plugin is a single file: `zsh-how.plugin.zsh`. It defines one public function `how()` with internal helpers prefixed `_how_`.

### Helpers (local to `how()`)
- `_how_pick` — selects the first available command from a ranked preference list
- `_how_header` — prints a styled section header
- `_how_cmd` — prints a command
- `_how_labeled` — prints a command with a description

### Detection Order
The function checks for project files in this order, printing relevant commands for each that is found (multiple can match):
1. **Justfile** (also `Justfile`/`.justfile`) — lists recipes via `just --list` only (never parses the file); if `just` isn't installed or `--list` fails, shows a hint instead
2. **package.json** — lists npm scripts (prefers bun > pnpm > yarn > npm); uses `jq` to parse (prints a hint if `jq` is missing)
3. **pyproject.toml** — detects uv/poetry; parses TOML via Python's `tomllib`; lists `[project.scripts]`, `[tool.uv.scripts]`/`[tool.poetry.scripts]`, and poethepoet `[tool.poe.tasks]`
4. **requirements.txt** — only if no pyproject.toml; shows pip/uv install commands
5. **Cargo.toml** — standard cargo commands; lists multiple binary targets via `cargo metadata`
6. **go.mod** — standard go commands
7. **Makefile** — extracts targets via grep, includes inline `#` comments as descriptions
8. **Docker Compose / Dockerfile** — compose up/down or docker build/run

## Testing

No test framework. To test manually, run `source zsh-how.plugin.zsh` then `how` in directories containing various project files.
