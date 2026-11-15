#!/usr/bin/env bash
# Close Claude Code sessions that have sat idle for a while, to free memory
# (each session also keeps its own copy of every MCP server running).
# The tmux pane is left with the resume command typed but not run.
#
#   claude-idle.sh [hours]          list sessions idle longer than hours (default 24)
#   claude-idle.sh --close [hours]  close them, leaving "claude --resume <id>" in the pane

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
SESSIONS_DIR="$HOME/.claude/sessions"

# Prints "pid<TAB>idleHours<TAB>pane<TAB>sessionId<TAB>cwd<TAB>name" per live idle session older than $1 hours.
idle_sessions() {
  local hours=$1 now f pid
  now=$(( $(date +%s) * 1000 ))
  for f in "$SESSIONS_DIR"/*.json; do
    [[ -e $f ]] || continue
    pid=$(jq -r '.pid // empty' "$f" 2>/dev/null) || continue
    [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null || continue
    jq -r --argjson now "$now" --argjson hours "$hours" '
      select(.status == "idle")
      | ((($now - (.statusUpdatedAt // .updatedAt // $now)) / 3600000) | floor) as $idle
      | select($idle >= $hours)
      | [.pid, $idle, (.tmux // "" | sub(".*\\."; "")), .sessionId, .cwd, (.name // "")] | @tsv' "$f"
  done
}

# Original arguments minus any resume/continue flag, so --resume <id> can be appended.
relaunch_args() {
  local -a in out=()
  read -r -a in <<<"$(ps -o args= -p "$1")"
  local i=1
  while (( i < ${#in[@]} )); do
    case ${in[i]} in
      -c|--continue) ;;
      -r|--resume)
        [[ ${in[i+1]:-} != -* && -n ${in[i+1]:-} ]] && (( i++ )) ;;
      *) out+=("${in[i]}") ;;
    esac
    (( i++ ))
  done
  printf '%q ' "${out[@]}"
}

close_all() {
  local pid idle pane sid cwd name args closed=0 skipped=0
  while IFS=$'\t' read -r pid idle pane sid cwd name; do
    if [[ -z $pane ]] || ! tmux display -p -t "$pane" '#{pane_id}' >/dev/null 2>&1; then
      echo "skip $name ($pid): not in a tmux pane, close it by hand (claude --resume $sid)"
      (( skipped++ )); continue
    fi
    args=$(relaunch_args "$pid")
    kill -TERM "$pid"
    for _ in {1..20}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
    if kill -0 "$pid" 2>/dev/null; then
      echo "skip $name ($pid): did not exit after SIGTERM"
      (( skipped++ )); continue
    fi
    # Typed, not run: press Enter in the pane to resume
    tmux send-keys -t "$pane" -l "cd $(printf '%q' "$cwd") && claude ${args}--resume $sid"
    echo "closed $name (idle ${idle}h) in $pane"
    (( closed++ ))
  done < <(idle_sessions "$1")
  echo "closed $closed, skipped $skipped"
}

[[ ${2:-${1:-24}} =~ ^[0-9]+$ || ${1:-} != --close ]] || { echo "hours must be a whole number"; exit 1; }

case ${1:-} in
  --close)     close_all "${2:-24}" ;;
  ""|[0-9]*)   idle_sessions "${1:-24}" | cut -f1,2,6 ;;
  *)           sed -n '2,8p' "$0"; exit 1 ;;
esac
