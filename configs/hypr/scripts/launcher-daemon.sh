#!/bin/sh
i=0
while [ "$i" -lt 10 ]; do
    pgrep -f "qs -c launcher" >/dev/null && exit 0
    qs -c launcher -d 2>/dev/null
    sleep 2
    i=$((i + 1))
done
