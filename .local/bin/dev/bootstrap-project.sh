#!/usr/bin/env bash
set -euo pipefail

# Configuration with environment variable overrides
SEARCH_DEPTH="${BOOTSTRAP_SEARCH_DEPTH:-3}"
SEARCH_PATHS="${BOOTSTRAP_SEARCH_PATHS:-$HOME/code:$HOME/projects:$HOME/workspace:$HOME/repos}"
FZF_PROMPT="${BOOTSTRAP_FZF_PROMPT:-Select project: }"
DOCKER_COMPOSE_FILES="${BOOTSTRAP_DOCKER_FILES:-docker-compose.yml:compose.yml:docker-compose.yaml:compose.yaml}"
DEV_SETUP_FILES="${BOOTSTRAP_DEV_FILES:-.ops/devup:scripts/dev:bin/dev:Makefile:justfile}"
TMUX_LAYOUT_FILES="${BOOTSTRAP_TMUX_FILES:-.tmux.layout:.tmux.conf:.tmux-layout}"

# Parse command line arguments for additional flexibility
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--depth)
      SEARCH_DEPTH="$2"
      shift 2
      ;;
    -p|--paths)
      SEARCH_PATHS="$2"
      shift 2
      ;;
    --prompt)
      FZF_PROMPT="$2"
      shift 2
      ;;
    --no-tmux)
      SKIP_TMUX=true
      shift
      ;;
    --no-docker)
      SKIP_DOCKER=true
      shift
      ;;
    --no-direnv)
      SKIP_DIRENV=true
      shift
      ;;
    -h|--help)
      cat << EOF
Bootstrap Project - Flexible project environment setup

Usage: $0 [options]

Options:
  -d, --depth DEPTH        Search depth for projects (default: $SEARCH_DEPTH)
  -p, --paths PATHS        Colon-separated search paths (default: $SEARCH_PATHS)
  --prompt PROMPT          fzf prompt text (default: "$FZF_PROMPT")
  --no-tmux               Skip tmux session setup
  --no-docker             Skip docker/compose setup
  --no-direnv             Skip direnv environment loading
  -h, --help              Show this help

Environment Variables:
  BOOTSTRAP_SEARCH_DEPTH   Search depth (default: 3)
  BOOTSTRAP_SEARCH_PATHS   Colon-separated search paths
  BOOTSTRAP_FZF_PROMPT     fzf prompt text
  BOOTSTRAP_DOCKER_FILES   Colon-separated docker compose filenames to look for
  BOOTSTRAP_DEV_FILES      Colon-separated dev setup files to look for
  BOOTSTRAP_TMUX_FILES     Colon-separated tmux layout files to look for

Examples:
  $0                                    # Use defaults
  $0 -d 5 -p "\$HOME/work:\$HOME/personal"  # Custom depth and paths
  $0 --no-tmux --no-docker             # Skip tmux and docker setup
EOF
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'. Use --help for usage information." >&2
      exit 1
      ;;
  esac
done

# Check dependencies
for cmd in fd fzf; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command '$cmd' not found. Please install it first." >&2
    exit 1
  fi
done

# Build search command dynamically
search_paths=()
IFS=':' read -ra path_array <<< "$SEARCH_PATHS"
for path in "${path_array[@]}"; do
  # Expand environment variables in paths
  expanded_path=$(eval echo "$path")
  if [[ -d "$expanded_path" ]]; then
    search_paths+=("$expanded_path")
  else
    echo "Warning: Search path '$expanded_path' does not exist, skipping..." >&2
  fi
done

if [[ ${#search_paths[@]} -eq 0 ]]; then
  echo "Error: No valid search paths found. Please check BOOTSTRAP_SEARCH_PATHS or use -p option." >&2
  exit 1
fi

echo "Searching for projects in: ${search_paths[*]}"
echo "Search depth: $SEARCH_DEPTH"

# Build and execute fd command
fd_args=()
for path in "${search_paths[@]}"; do
  fd_args+=("$path")
done

# Select project directory
if ! sel="$(fd . "${fd_args[@]}" -t d -d "$SEARCH_DEPTH" | fzf --prompt="$FZF_PROMPT")"; then
  echo "No project selected. Exiting." >&2
  exit 1
fi

# Validate and change to selected directory
if [[ ! -d "$sel" ]]; then
  echo "Error: Selected directory '$sel' no longer exists." >&2
  exit 1
fi

echo "Entering project: $sel"
cd "$sel" || {
  echo "Error: Failed to change to directory '$sel'" >&2
  exit 1
}

# Load direnv if available and not skipped
if [[ "${SKIP_DIRENV:-}" != "true" ]] && command -v direnv >/dev/null 2>&1; then
  echo "Loading direnv environment..."
  eval "$(direnv export bash)" || echo "Warning: direnv failed to load environment"
fi

# Find and execute development setup
if [[ "${SKIP_DOCKER:-}" != "true" ]]; then
  echo "Looking for development environment setup..."

  # Check for custom dev setup files first
  dev_setup_found=false
  IFS=':' read -ra dev_files <<< "$DEV_SETUP_FILES"
  for dev_file in "${dev_files[@]}"; do
    if [[ -f "$dev_file" ]]; then
      if [[ -x "$dev_file" ]]; then
        echo "Running $dev_file..."
        "./$dev_file" || echo "Warning: $dev_file failed"
        dev_setup_found=true
        break
      elif [[ "$dev_file" == "Makefile" ]] && command -v make >/dev/null 2>&1; then
        echo "Running make (found Makefile)..."
        make || echo "Warning: make failed"
        dev_setup_found=true
        break
      elif [[ "$dev_file" == "justfile" ]] && command -v just >/dev/null 2>&1; then
        echo "Running just (found justfile)..."
        just || echo "Warning: just failed"
        dev_setup_found=true
        break
      fi
    fi
  done

  # Fallback to docker compose if no custom setup found
  if [[ "$dev_setup_found" == "false" ]]; then
    docker_compose_found=false
    IFS=':' read -ra docker_files <<< "$DOCKER_COMPOSE_FILES"
    for docker_file in "${docker_files[@]}"; do
      if [[ -f "$docker_file" ]]; then
        echo "Starting docker compose ($docker_file)..."
        docker compose up -d || echo "Warning: docker compose failed"
        docker_compose_found=true
        break
      fi
    done

    if [[ "$docker_compose_found" == "false" ]]; then
      echo "No development environment configuration found"
      echo "Looked for: ${DEV_SETUP_FILES//:/, }, ${DOCKER_COMPOSE_FILES//:/, }"
    fi
  fi
fi

# Handle tmux session if not skipped
if [[ "${SKIP_TMUX:-}" != "true" ]]; then
  tmux_layout_found=false
  IFS=':' read -ra tmux_files <<< "$TMUX_LAYOUT_FILES"
  for tmux_file in "${tmux_files[@]}"; do
    if [[ -f "$tmux_file" ]]; then
      tmux_layout_found=true
      session_name="$(basename "$sel")"

      if [[ -n "${TMUX:-}" ]]; then
        echo "Already inside tmux. Sourcing layout ($tmux_file) in current session..."
        tmux source-file "$tmux_file" || echo "Warning: Failed to source tmux layout"
      else
        echo "Starting new tmux session '$session_name' with layout ($tmux_file)..."
        # Check if session already exists
        if tmux has-session -t "$session_name" 2>/dev/null; then
          echo "Session '$session_name' already exists, attaching..."
          tmux attach-session -t "$session_name"
        else
          tmux new-session -d -s "$session_name" \; source-file "$tmux_file" \; attach || {
            echo "Warning: Failed to start tmux session with layout, starting regular session..."
            tmux new-session -s "$session_name" || echo "Warning: Failed to start tmux"
          }
        fi
      fi
      break
    fi
  done

  if [[ "$tmux_layout_found" == "false" ]]; then
    echo "No tmux layout found. Looked for: ${TMUX_LAYOUT_FILES//:/, }"
  fi
fi

echo "Project setup complete. Current directory: $(pwd)"
