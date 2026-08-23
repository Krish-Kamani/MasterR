#!/bin/sh
mon=$(hyprctl activeworkspace -j | jq -r '.monitor')
qs -c pill ipc call pill quickRecord "$mon"
