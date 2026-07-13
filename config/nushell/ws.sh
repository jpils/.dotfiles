#!/usr/bin/env bash
set -euo pipefail

roots=("$HOME/nixconf" "$HOME/Projects" "$HOME/projects" "$HOME/Code" "$HOME/code")
find_depth=4

usage() {
  cat <<'USAGE'
usage: ws [workspace-name-or-path]
       ws path/inside/workspace

Open or create a tmux cockpit for a JJ workspace.
Search roots: ~/nixconf, ~/Projects, ~/projects, ~/Code, ~/code

Layouts:
  Rust project (nearest Cargo.toml): editor, bacon, shell
  Fallback: editor, shell

When given a path inside a JJ workspace, tmux session identity stays the
workspace root, but editor/shell start in that path.
USAGE
}

sanitize_session_name() {
  local name="$1"
  name="${name//./-}"
  name="${name//:/-}"
  name="${name// /-}"
  printf '%s' "$name"
}

list_workspaces() {
  for root in "${roots[@]}"; do
    [[ -d "$root" ]] || continue
    find "$root" \
      -mindepth 2 \
      -maxdepth "$((find_depth + 1))" \
      -type d \
      -name .jj \
      -printf '%h\n'
  done | sort -u
}

find_workspace() {
  local query="${1:-}"

  if [[ -n "$query" ]]; then
    if [[ -d "$query" ]]; then
      local root
      if root="$(cd "$query" && jj root 2>/dev/null)"; then
        printf '%s\n' "$root"
        return 0
      fi

      printf 'ws: %s is not inside a JJ workspace\n' "$query" >&2
      return 1
    fi

    for root in "${roots[@]}"; do
      [[ -d "$root/$query/.jj" ]] || continue
      realpath "$root/$query"
      return 0
    done

    while IFS= read -r candidate; do
      [[ "$(basename "$candidate")" == *"$query"* ]] || continue
      realpath "$candidate"
      return 0
    done < <(list_workspaces)

    return 1
  fi

  local candidates
  candidates="$(list_workspaces)"

  if command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "$candidates" | fzf --height 40% --layout reverse --border
  else
    printf '%s\n' "$candidates" | head -n 1
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

workspace="$(find_workspace "${1:-}")" || {
  printf 'ws: no workspace found for %q\n' "${1:-}" >&2
  exit 1
}

if [[ ! -d "$workspace/.jj" ]]; then
  printf 'ws: %s is not a JJ workspace (.jj missing)\n' "$workspace" >&2
  exit 1
fi

workdir="$workspace"
if [[ -n "${1:-}" && -d "${1:-}" ]]; then
  workdir="$(realpath "${1:-}")"
  case "$workdir" in
    "$workspace"|"$workspace"/*) ;;
    *)
      printf 'ws: %s is not inside workspace %s\n' "$workdir" "$workspace" >&2
      exit 1
      ;;
  esac
fi

find_upwards() {
  local file_name="$1"
  local dir="$workdir"

  while true; do
    if [[ -f "$dir/$file_name" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi

    [[ "$dir" == "$workspace" ]] && return 1
    dir="$(dirname "$dir")"
  done
}

project_dir="$(find_upwards Cargo.toml || true)"

session="$(sanitize_session_name "$(basename "$workspace")")"

attach_session() {
  if [[ -n "${TMUX:-}" ]]; then
    exec tmux switch-client -t "=$session"
  else
    exec tmux attach-session -t "=$session"
  fi
}

if tmux has-session -t "=$session" 2>/dev/null; then
  attach_session
fi

bash_bin="$(command -v bash)"

shell_quote() {
  printf "'%s'" "${1//\'/\'\\\'\'}"
}

shell_command() {
  printf '%s -lc %s' "$bash_bin" "$(shell_quote "$1")"
}

has_workspace_command() {
  local command_name="$1"

  if command -v direnv >/dev/null 2>&1; then
    direnv exec "$project_dir" bash -lc "command -v '$command_name' >/dev/null 2>&1"
  else
    command -v "$command_name" >/dev/null 2>&1
  fi
}

editor_cmd='if command -v direnv >/dev/null 2>&1; then direnv exec . bash -lc "if command -v yazi >/dev/null 2>&1; then yazi; fi; exec ${SHELL:-sh}"; elif command -v yazi >/dev/null 2>&1; then yazi; exec ${SHELL:-sh}; else exec ${SHELL:-sh}; fi'
bacon_cmd='if command -v direnv >/dev/null 2>&1; then direnv exec . bash -lc "bacon; exec ${SHELL:-sh}"; else bacon; exec ${SHELL:-sh}; fi'
pi_cmd='if command -v direnv >/dev/null 2>&1; then direnv exec . bash -lc "if command -v pi >/dev/null 2>&1; then pi -c; fi; exec ${SHELL:-sh}"; elif command -v pi >/dev/null 2>&1; then pi -c; exec ${SHELL:-sh}; else exec ${SHELL:-sh}; fi'
shell_cmd='if command -v direnv >/dev/null 2>&1; then exec direnv exec . ${SHELL:-sh}; else exec ${SHELL:-sh}; fi'

if ! tmux new-session -d -s "$session" -n editor -c "$workdir" "$(shell_command "$editor_cmd")"; then
  if tmux has-session -t "=$session" 2>/dev/null; then
    attach_session
  fi

  exit 1
fi

if [[ -n "$project_dir" ]] && has_workspace_command bacon; then
  tmux new-window -d -t "=$session:" -n bacon -c "$project_dir" "$(shell_command "$bacon_cmd")"
fi

shell_pane="$(tmux new-window -d -P -F '#{pane_id}' -t "=$session:" -n shell -c "$workdir" "$(shell_command "$pi_cmd")")"
tmux split-window -h -t "$shell_pane" -c "$workdir" "$(shell_command "$shell_cmd")"
tmux select-layout -t "$shell_pane" even-horizontal
tmux select-pane -t "$shell_pane"
tmux select-window -t "=$session:1"

attach_session
