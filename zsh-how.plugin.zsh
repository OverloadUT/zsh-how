#!/usr/bin/env zsh
# how - instantly see how to run the project in the current directory
# Drop this in your .zshrc or use as a zsh plugin

function how() {
  local found=0
  local dim='\033[2m'
  local bold='\033[1m'
  local cyan='\033[36m'
  local green='\033[32m'
  local yellow='\033[33m'
  local magenta='\033[35m'
  local reset='\033[0m'

  # ── Helper: pick the best available command from a ranked list ──
  _how_pick() {
    for cmd in "$@"; do
      if command -v "$cmd" &>/dev/null; then
        echo "$cmd"
        return
      fi
    done
  }

  # ── Helper: section header ──
  _how_header() {
    printf "${bold}${cyan}▸ %s${reset}  ${dim}(%s)${reset}\n" "$1" "$2"
  }

  # ── Helper: print a command line ──
  _how_cmd() {
    printf "  ${green}%s${reset}\n" "$1"
  }

  # ── Helper: print a labeled command ──
  _how_labeled() {
    printf "  ${green}%-28s${reset} ${dim}%s${reset}\n" "$1" "$2"
  }

  # ═══════════════════════════════════════════════════════════════
  # Justfile
  # ═══════════════════════════════════════════════════════════════
  if [[ -f justfile || -f Justfile || -f .justfile ]]; then
    found=1
    local jfile jline jsig jdesc
    for f in justfile Justfile .justfile; do
      [[ -f "$f" ]] && jfile="$f" && break
    done

    # Recipes come from `just --list` only — it resolves imports, modules,
    # [private], [doc()], and parameter defaults, which file parsing can't
    if ! command -v just &>/dev/null; then
      _how_header "Just" "$jfile → just not installed"
      _how_labeled "brew install just" "install just to list recipes"
    else
      local jlist=$(just --list --unsorted 2>/dev/null)
      if [[ -n "$jlist" ]]; then
        _how_header "Just" "$jfile"
        echo "$jlist" | tail -n +2 | while IFS= read -r jline; do
          # just --list output: "    recipe-name <params> # description"
          jline="${jline#"${jline%%[![:space:]]*}"}"
          [[ -z "$jline" || "$jline" == \[*\] ]] && continue # skip group headers
          jsig=$(echo "$jline" | sed 's/ *#.*//')
          if [[ "$jline" == *"#"* ]]; then
            jdesc=$(echo "$jline" | sed 's/^[^#]*# *//')
            _how_labeled "just $jsig" "$jdesc"
          else
            _how_cmd "just $jsig"
          fi
        done
      else
        _how_header "Just" "$jfile → just --list failed"
        _how_labeled "just --list" "run to see the parse error"
      fi
    fi
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Node / JS / TS — package.json
  # ═══════════════════════════════════════════════════════════════
  if [[ -f package.json ]]; then
    found=1
    # Pick the best runner: bun > pnpm > yarn > npm
    local runner=$(_how_pick bun pnpm yarn npm)

    if [[ -z "$runner" ]]; then
      runner="npm" # fallback label even if not installed
    fi

    _how_header "Node" "package.json → $runner"

    # Extract scripts from package.json
    if command -v jq &>/dev/null; then
      jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' package.json 2>/dev/null | while IFS=$'\t' read -r key val; do
        _how_labeled "$runner run $key" "$val"
      done
    else
      printf "  ${dim}(install jq to list scripts)${reset}\n"
    fi
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Python — pyproject.toml
  # ═══════════════════════════════════════════════════════════════
  if [[ -f pyproject.toml ]]; then
    found=1
    local py_runner=$(_how_pick uv poetry)

    if [[ "$py_runner" == "uv" ]]; then
      _how_header "Python" "pyproject.toml → uv"

      # uv scripts (defined in [tool.uv.scripts] or [project.scripts])
      # Try to extract scripts section
      local in_scripts=0
      local script_section=""

      # Check for [project.scripts] entry points
      if command -v python3 &>/dev/null || command -v python &>/dev/null; then
        local py=$(_how_pick python3 python)
        $py -c "
import tomllib
with open('pyproject.toml', 'rb') as f:
    data = tomllib.load(f)
def desc(v):
    if isinstance(v, str): return v
    if isinstance(v, dict): return v.get('help') or v.get('cmd') or v.get('shell') or v.get('script') or ''
    if isinstance(v, list): return 'task sequence'
    return ''
for k, v in data.get('project', {}).get('scripts', {}).items():
    print(f'{k}\t{v}')
for k, v in data.get('tool', {}).get('uv', {}).get('scripts', {}).items():
    print(f'{k}\t{v}')
for k, v in data.get('tool', {}).get('poe', {}).get('tasks', {}).items():
    print(f'poe {k}\t{desc(v)}')
" 2>/dev/null | while IFS=$'\t' read -r key val; do
          _how_labeled "uv run $key" "$val"
        done
      fi

      # Always show the common uv commands
      _how_cmd "uv run python <file>"
      _how_cmd "uv sync"

    elif [[ "$py_runner" == "poetry" ]]; then
      _how_header "Python" "pyproject.toml → poetry"

      if command -v python3 &>/dev/null || command -v python &>/dev/null; then
        local py=$(_how_pick python3 python)
        $py -c "
import tomllib
with open('pyproject.toml', 'rb') as f:
    data = tomllib.load(f)
def desc(v):
    if isinstance(v, str): return v
    if isinstance(v, dict): return v.get('help') or v.get('cmd') or v.get('shell') or v.get('script') or ''
    if isinstance(v, list): return 'task sequence'
    return ''
for k, v in data.get('tool', {}).get('poetry', {}).get('scripts', {}).items():
    print(f'{k}\t{v}')
for k, v in data.get('project', {}).get('scripts', {}).items():
    print(f'{k}\t{v}')
for k, v in data.get('tool', {}).get('poe', {}).get('tasks', {}).items():
    print(f'poe {k}\t{desc(v)}')
" 2>/dev/null | while IFS=$'\t' read -r key val; do
          _how_labeled "poetry run $key" "$val"
        done
      fi

      _how_cmd "poetry run python <file>"
      _how_cmd "poetry install"

    else
      _how_header "Python" "pyproject.toml"
      _how_cmd "pip install -e ."
      _how_cmd "python -m <module>"
    fi
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Python — requirements.txt (only if no pyproject.toml)
  # ═══════════════════════════════════════════════════════════════
  if [[ ! -f pyproject.toml && -f requirements.txt ]]; then
    found=1
    local py_runner=$(_how_pick uv pip)

    if [[ "$py_runner" == "uv" ]]; then
      _how_header "Python" "requirements.txt → uv"
      _how_cmd "uv pip install -r requirements.txt"
      _how_cmd "uv run python <file>"
    else
      _how_header "Python" "requirements.txt → pip"
      _how_cmd "pip install -r requirements.txt"
      _how_cmd "python <file>"
    fi
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Rust — Cargo.toml
  # ═══════════════════════════════════════════════════════════════
  if [[ -f Cargo.toml ]]; then
    found=1
    _how_header "Rust" "Cargo.toml"

    _how_labeled "cargo run" "run the default binary"
    _how_labeled "cargo build" "compile (debug)"
    _how_labeled "cargo build --release" "compile (release)"
    _how_labeled "cargo test" "run tests"

    # List binary targets if there are multiple
    if command -v cargo &>/dev/null; then
      local bins
      bins=$(cargo metadata --no-deps --format-version=1 2>/dev/null | jq -r '.packages[0].targets[] | select(.kind[] == "bin") | .name' 2>/dev/null)
      local bin_count=$(echo "$bins" | grep -c .)
      if [[ $bin_count -gt 1 ]]; then
        printf "  ${dim}binaries:${reset}\n"
        echo "$bins" | while read -r b; do
          _how_cmd "cargo run --bin $b"
        done
      fi
    fi
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Go — go.mod
  # ═══════════════════════════════════════════════════════════════
  if [[ -f go.mod ]]; then
    found=1
    _how_header "Go" "go.mod"
    _how_labeled "go run ." "run the package"
    _how_labeled "go build" "compile"
    _how_labeled "go test ./..." "run all tests"
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Makefile
  # ═══════════════════════════════════════════════════════════════
  if [[ -f Makefile || -f makefile || -f GNUmakefile ]]; then
    found=1
    local mkfile
    for f in Makefile makefile GNUmakefile; do
      [[ -f "$f" ]] && mkfile="$f" && break
    done

    _how_header "Make" "$mkfile"

    # Extract targets: lines matching "target:" that aren't variables or comments
    grep -E '^[a-zA-Z_][a-zA-Z0-9_.-]*:' "$mkfile" 2>/dev/null \
      | grep -v ':=' \
      | sed 's/:.*//' \
      | sort -u \
      | while read -r target; do
        # Try to find a comment on the same line as a description
        desc=$(grep -E "^${target}:" "$mkfile" | head -1 | sed -n 's/.*#\s*//p')
        if [[ -n "$desc" ]]; then
          _how_labeled "make $target" "$desc"
        else
          _how_cmd "make $target"
        fi
      done
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Docker
  # ═══════════════════════════════════════════════════════════════
  if [[ -f docker-compose.yml || -f docker-compose.yaml || -f compose.yml || -f compose.yaml ]]; then
    found=1
    local compose_file
    for f in compose.yml compose.yaml docker-compose.yml docker-compose.yaml; do
      [[ -f "$f" ]] && compose_file="$f" && break
    done

    _how_header "Docker Compose" "$compose_file"
    _how_labeled "docker compose up" "start services"
    _how_labeled "docker compose up -d" "start (detached)"
    _how_labeled "docker compose down" "stop services"
    echo
  elif [[ -f Dockerfile ]]; then
    found=1
    _how_header "Docker" "Dockerfile"
    _how_labeled "docker build -t <name> ." "build image"
    _how_labeled "docker run <name>" "run container"
    echo
  fi

  # ═══════════════════════════════════════════════════════════════
  # Nothing found
  # ═══════════════════════════════════════════════════════════════
  if [[ $found -eq 0 ]]; then
    printf "${yellow}¯\\_(ツ)_/¯${reset}  No recognized project files in ${bold}$(basename $PWD)${reset}\n"
    printf "${dim}Looked for: justfile, package.json, pyproject.toml, Cargo.toml, go.mod, Makefile, docker-compose.yml${reset}\n"
    return 1
  fi
}
