#!/bin/sh
ipv4=$(ip -4 addr show tun0 2>/dev/null | awk '/inet /{gsub(/\/.*/,"",$2); print $2; exit}')
if [ -n "$ipv4" ]; then
    printf 'VPN %s' "%{F#00ff87}${ipv4}%{F-}"
else
    printf '%s' "%{F#666666}VPN disconnected%{F-}"
fi