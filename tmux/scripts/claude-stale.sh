#!/usr/bin/env bash
# Find Claude Code sessions still running a binary that an upgrade deleted.
# macOS cannot verify such a process, so it and everything it spawns lose
# ~/Documents access a while after the upgrade.
#
#   claude-stale.sh            list stale sessions
#   claude-stale.sh --status   tmux status segment (empty when none)
#   claude-stale.sh --restart  restart idle stale sessions in their tmux pane

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
SESSIONS_DIR="$HOME/.claude/sessions"

# Prints "pid<TAB>status<TAB>pane<TAB>sessionId<TAB>cwd<TAB>exe" per stale session.
stale_sessions() {
  local f pid exe
  for f in "$SESSIONS_DIR"/*.json; do
    [[ -e $f ]] || continue
    pid=$(jq -r '.pid // empty' "$f" 2>/dev/null) || continue
    [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null || continue
    exe=$(lsof -a -p "$pid" -d txt -Fn 2>/dev/null | awk '/^n/{print substr($0,2); exit}')
    [[ $exe == */claude && ! -e $exe ]] || continue
    jq -r --arg exe "$exe" \
      '[.pid, .status, (.tmux // "" | sub(".*\\."; "")), .sessionId, .cwd, $exe] | @tsv' "$f"
  done
}

status_segment() {
  local n
  n=$(stale_sessions | wc -l | tr -d ' ')
  (( n > 0 )) && printf '#[fg=red,bold] ⚠ %s stale claude #[default]' "$n"
  return 0
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

restart_all() {
  local pid status pane sid cwd exe args restarted=0 skipped=0
  while IFS=$'\t' read -r pid status pane sid cwd exe; do
    if [[ $status != idle ]]; then
      echo "skip $pid ($status): finish or interrupt it, then run again"
      (( skipped++ )); continue
    fi
    if [[ -z $pane ]] || ! tmux display -p -t "$pane" '#{pane_id}' >/dev/null 2>&1; then
      echo "skip $pid: not in a tmux pane, restart it by hand (claude --resume $sid)"
      (( skipped++ )); continue
    fi
    args=$(relaunch_args "$pid")
    kill -TERM "$pid"
    for _ in {1..20}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
    if kill -0 "$pid" 2>/dev/null; then
      echo "skip $pid: did not exit after SIGTERM"
      (( skipped++ )); continue
    fi
    tmux send-keys -t "$pane" -l "cd $(printf '%q' "$cwd") && claude ${args}--resume $sid"
    tmux send-keys -t "$pane" Enter
    echo "restarted $pid in $pane"
    (( restarted++ ))
  done < <(stale_sessions)
  echo "restarted $restarted, skipped $skipped"
}

case ${1:-} in
  --status)  status_segment ;;
  --restart) restart_all ;;
  "")        stale_sessions | cut -f1-4 ;;
  *)         sed -n '2,8p' "$0"; exit 1 ;;
esac
