#!/usr/bin/env bash

# Colors
R=$'\e[38;2;224;86;59m'
RH=$'\e[38;2;239;106;79m'
D=$'\e[38;2;51;55;63m'
K=$'\e[38;2;63;69;80m'
S=$'\e[38;2;139;145;156m'
T=$'\e[38;2;196;204;218m'
DIM=$'\e[38;2;91;102;120m'
G=$'\e[38;2;91;191;115m'
X=$'\e[0m'

# Clock & Day (using Bash built-in printf for instant formatting)
printf -v clock '%(%H:%M)T' -1 2>/dev/null || clock=$(date +%H:%M)
printf -v day '%(%A · %-d %b)T' -1 2>/dev/null || day=$(LC_TIME=C date "+%A · %-d %b")

# Uptime (pure bash /proc/uptime read, zero forks)
if [ -r /proc/uptime ]; then
    read -r up _ < /proc/uptime
    up=${up%.*}
    ud=$((up / 86400)); uh=$(((up % 86400) / 3600)); um=$(((up % 3600) / 60))
    if [ "$ud" -gt 0 ]; then upt="${ud}d ${uh}h"; else upt="${uh}h ${um}m"; fi
else
    upt="--"
fi

# CPU % (zero sleep: compute delta from previous check in /dev/shm or fallback to loadavg)
cpu="0"
if [ -r /proc/stat ]; then
    read -ra b < /proc/stat
    stat_file="/dev/shm/.torii_cpu_stat"
    if [ -r "$stat_file" ]; then
        read -ra a < "$stat_file"
        t1=0; for v in "${a[@]:1}"; do t1=$((t1 + v)); done
        t2=0; for v in "${b[@]:1}"; do t2=$((t2 + v)); done
        id1=$((a[4] + a[5])); id2=$((b[4] + b[5]))
        dt=$((t2 - t1)); di=$((id2 - id1))
        if [ "$dt" -gt 0 ]; then
            cpu=$(( 100 * (dt - di) / dt ))
            [ "$cpu" -lt 0 ] && cpu=0
            [ "$cpu" -gt 100 ] && cpu=100
        fi
    fi
    printf '%s\n' "${b[*]}" > "$stat_file" 2>/dev/null
    if [ "$cpu" = "0" ] && [ -r /proc/loadavg ]; then
        read -r l1 _ < /proc/loadavg
        cpu="${l1%.*}"
    fi
fi

# CPU Temperature (hwmon sysfs read using builtins)
ctemp="--"
for hw in /sys/class/hwmon/hwmon*; do
    [ -d "$hw" ] || continue
    hname=""
    [ -r "$hw/name" ] && read -r hname < "$hw/name"
    if [ "$hname" = "k10temp" ] || [ "$hname" = "coretemp" ] || [ "$hname" = "zenpower" ]; then
        for lbl in "$hw"/temp*_label; do
            [ -r "$lbl" ] || continue
            read -r lname < "$lbl"
            if [ "$lname" = "Tctl" ] || [ "$lname" = "Package id 0" ] || [ "$lname" = "Tdie" ]; then
                inp="${lbl%_label}_input"
                if [ -r "$inp" ]; then
                    read -r rawtemp < "$inp"
                    ctemp=$(( rawtemp / 1000 ))
                    break 2
                fi
            fi
        done
        if [ "$ctemp" = "--" ] && [ -r "$hw/temp1_input" ]; then
            read -r rawtemp < "$hw/temp1_input"
            ctemp=$(( rawtemp / 1000 ))
            break
        fi
    fi
done

# GPU utilization & temp (Asynchronously cached in /dev/shm to eliminate slow nvidia-smi blocking)
gpu="--"; gtemp="--"
gpu_cache="/dev/shm/.torii_gpu"
if [ -r "$gpu_cache" ]; then
    IFS=',' read -r gpu gtemp < "$gpu_cache"
    gpu=${gpu// /}; gtemp=${gtemp// /}
fi

# Background job to refresh GPU stats without blocking terminal startup
(
    if command -v nvidia-smi >/dev/null 2>&1; then
        g=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [ -n "$g" ]; then
            echo "$g" > /dev/shm/.torii_gpu
        fi
    fi
) >/dev/null 2>&1 &
disown $! 2>/dev/null

# RAM usage (pure bash parsing of /proc/meminfo, zero subshells)
rused="0.0"; rtot="0"; rpct="0"
if [ -r /proc/meminfo ]; then
    while read -r key val _; do
        case "$key" in
            MemTotal:) mt=$val ;;
            MemAvailable:) ma=$val; break ;;
        esac
    done < /proc/meminfo
    if [ -n "$mt" ] && [ -n "$ma" ] && [ "$mt" -gt 0 ]; then
        mu=$((mt - ma))
        rused_int=$((mu / 1048576))
        rused_dec=$(( (mu % 1048576) * 10 / 1048576 ))
        rused="${rused_int}.${rused_dec}"
        rtot=$(( (mt + 524288) / 1048576 ))
        rpct=$((100 * mu / mt))
    fi
fi

# Disk usage
read -r dpct davail < <(df -BG --output=pcent,avail / 2>/dev/null | tail -1)
dpct=${dpct// /}; davail=${davail// /}; davail=${davail%G}

i3="${R}${clock}${X}"
i4="${DIM}${day} · up ${upt}${X}"
i6="${DIM}cpu  ${G}${cpu}%${DIM} · ${ctemp}°C${X}"
i7="${DIM}gpu  ${G}${gpu}%${DIM} · ${gtemp}°C${X}"
i8="${DIM}ram  ${T}${rused} ${DIM}/ ${rtot} GB · ${T}${rpct}%${X}"
i9="${DIM}disk ${T}${dpct} ${DIM}· ${davail} GB free${X}"

echo
printf '%s\n' "${K}      ╱▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔╲${X}"
printf '%s\n' "${K}   ▗▄████████████████████▄▖${X}"
printf '%s\n' "${D}      ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀${X}        ${i3}"
printf '%s\n' "${R}        ███   ${D}▐▌${R}   ███${X}          ${i4}"
printf '%s\n' "${R}    ▄▄▄▄███▄▄▄▄▄▄▄▄███▄▄▄▄${X}"
printf '%s\n' "${RH}    ▀▀▀▀███▀▀▀▀▀▀▀▀███▀▀▀▀${X}      ${i6}"
printf '%s\n' "${R}        ███        ███${X}          ${i7}"
printf '%s\n' "${R}        ███        ███${X}          ${i8}"
printf '%s\n' "${R}        ███        ███${X}          ${i9}"
printf '%s\n' "${R}        ███        ███${X}"
printf '%s\n' "${S}       ▟███▙      ▟███▙${X}"
echo
