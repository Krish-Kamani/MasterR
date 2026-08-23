#!/bin/sh
name="$1"
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/${name}-watchdog.lock"
flock -n 9 || exit 0

# Bring up a fresh instance, then wait for it to actually answer IPC before
# handing back to the liveness loop. quickshell does not guard against a second
# instance of the same config, so a slow cold start under boot load must not be
# read as a dead shell and respawned, or the duplicates stack up and fight over
# the layer surface and keyboard focus. The wait is capped so a launch that
# never comes up still falls back to the normal retry cadence.
launch() {
    qs -c "$name" -d 9>&- 2>/dev/null
    i=0
    while [ "$i" -lt 30 ]; do
        qs -c "$name" ipc show >/dev/null 2>&1 && return
        sleep 1
        i=$((i + 1))
    done
}

while true; do
    qs -c "$name" ipc show >/dev/null 2>&1 || launch
    sleep 5
done
