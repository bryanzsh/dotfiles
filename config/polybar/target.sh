#!/bin/sh
t=$(cat ~/.config/polybar/target.txt 2>/dev/null)
if [ -n "$t" ]; then
    printf '%s' "%{F#f38ba8}target: $t%{F-}"
else
    printf '%s' "%{F#666666}target: none%{F-}"
fi