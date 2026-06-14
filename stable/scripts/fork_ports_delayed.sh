#!/bin/sh

TARGET_PORT=4001

# Wait until IB Gateway is actually listening — no fixed sleep
printf "Waiting for IB Gateway on port %s...\n" "$TARGET_PORT"
until ss -tlnp 2>/dev/null | grep -q ":${TARGET_PORT}"; do
    sleep 5
done
printf "IB Gateway is up on port %s\n" "$TARGET_PORT"

if [ "$TRADING_MODE" = "paper" ]; then
    printf "Forking :::4001 onto 0.0.0.0:4002\n"
    # Restart socat whenever IB Gateway cycles (daily reset, restart, etc.)
    while true; do
        socat TCP-LISTEN:4002,fork TCP:127.0.0.1:4001
        printf "socat exited — waiting for IB Gateway to return on port %s...\n" "$TARGET_PORT"
        until ss -tlnp 2>/dev/null | grep -q ":${TARGET_PORT}"; do
            sleep 5
        done
        printf "IB Gateway back on port %s — restarting socat\n" "$TARGET_PORT"
    done
else
    printf "Forking :::4001 onto 0.0.0.0:4001\n"
    socat TCP-LISTEN:4001,fork TCP:127.0.0.1:4001
fi
