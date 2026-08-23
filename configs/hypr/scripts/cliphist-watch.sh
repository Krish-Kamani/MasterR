#!/bin/sh
pgrep -f "wl-paste --type text --watch cliphist" >/dev/null || wl-paste --type text --watch cliphist store &
pgrep -f "wl-paste --type image --watch cliphist" >/dev/null || wl-paste --type image --watch cliphist store &
