#!/bin/bash
# Idle-gated Time Machine (erb-m2). Replaces TM's own fixed-interval schedule
# (disable that with `sudo tmutil disable`; manual/--auto backups still work).
# Every 15 min (launchd com.erik.tm-idle-backup):
#   - backup due (last success >= MIN_AGE) and machine idle (load, AC) -> start
#   - overdue (>= FORCE_AGE) -> start regardless of load
#   - a backup is running but the machine got swamped -> stop it (resumes later)
# Small frequent incrementals are cheap; big catch-up runs while busy are not.
# See erbot memory reference_timemachine_server3.md.
MIN_AGE_H=20
FORCE_AGE_H=336
NCPU=$(sysctl -n hw.ncpu)
START_MAX_LOAD=$((NCPU / 2))
STOP_MIN_LOAD=$((NCPU * 3))

log() { echo "$(date '+%F %T') $*"; }

load=$(sysctl -n vm.loadavg | awk '{printf "%d", $2}')
age_h=$(defaults export /Library/Preferences/com.apple.TimeMachine - | /usr/bin/python3 -c '
import plistlib, sys, datetime as dt
p = plistlib.loads(sys.stdin.buffer.read())
ds = [d for x in p.get("Destinations", []) for d in x.get("SnapshotDates", [])]
now = dt.datetime.now(dt.timezone.utc)
print(int((now - max(ds).replace(tzinfo=dt.timezone.utc)).total_seconds() // 3600) if ds else 99999)')

# fail safe: never act on an unparseable date or load
case "$age_h$load" in ''|*[!0-9]*) log "could not read age='$age_h' load='$load': doing nothing"; exit 1;; esac

if tmutil status | grep -q 'Running = 1'; then
  if [ "$load" -ge "$STOP_MIN_LOAD" ] && [ "$age_h" -lt "$FORCE_AGE_H" ]; then
    log "load $load >= $STOP_MIN_LOAD while backing up (last success ${age_h}h ago): stopping"
    tmutil stopbackup
  fi
  exit 0
fi

[ "$age_h" -lt "$MIN_AGE_H" ] && exit 0

if [ "$age_h" -lt "$FORCE_AGE_H" ]; then
  pmset -g ps | grep -q "AC Power" || exit 0
  [ "$load" -gt "$START_MAX_LOAD" ] && exit 0
  log "last success ${age_h}h ago, load $load: starting backup"
else
  log "last success ${age_h}h ago (overdue), load $load: forcing backup"
fi
tmutil startbackup --auto
