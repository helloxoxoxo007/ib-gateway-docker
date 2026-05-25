#!/bin/sh

echo "=== [TradingBoat] Starting IB Gateway + IBC ==="

export DISPLAY=:1
rm -f /tmp/.X1-lock
Xvfb :1 -ac -screen 0 1024x768x16 &

if [ -n "$VNC_SERVER_PASSWORD" ]; then
  echo "Starting VNC server"
  /root/scripts/run_x11_vnc.sh &
fi

# Java 17+ fix
VMOPTIONS="/root/Jts/ibgateway/${IB_GATEWAY_VERSION}/ibgateway.vmoptions"
cat > "$VMOPTIONS" << EOF
--add-opens=java.desktop/javax.swing=ALL-UNNAMED
--add-opens=java.base/java.util=ALL-UNNAMED
--add-opens=java.desktop/java.awt=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.plaf=ALL-UNNAMED
-Xmx1536m
-Xms768m
EOF

# Generate config
envsubst < "${IBC_INI}.tmpl" > "${IBC_INI}"

echo "=== Launching IBC (with no login dialog wait) ==="

/root/ibc/scripts/ibcstart.sh "${TWS_MAJOR_VRSN}" -g \
    "--tws-path=${TWS_PATH}" \
    "--ibc-path=${IBC_PATH}" \
    "--ibc-ini=${IBC_INI}" \
    "--user=${TWS_USERID}" \
    "--pw=${TWS_PASSWORD}" \
    "--mode=${TRADING_MODE}" \
    "--on2fatimeout=exit" 

echo "=== Waiting for API port to open ==="
for i in {1..60}; do
    if ss -tlnp 2>/dev/null | grep -q ':4001'; then
        echo "SUCCESS: Port 4001 is listening!"
        break
    fi
    sleep 3
done

echo "Final listening ports:"
ss -tlnp | grep -E '400|590'
echo "=== Startup completed ==="

# Start TradingBoat Flask app on port 5000
FLASK_SCRIPT="/home/tbot/develop/github/tbot-tradingboat/tbottmux/run_docker_flask_tbot.sh"
if [ -f "$FLASK_SCRIPT" ]; then
  echo "=== Starting TradingBoat Flask on port ${TVWB_HTTPS_PORT:-5000} ==="
  chmod a+x "$FLASK_SCRIPT"
  "$FLASK_SCRIPT" &
else
  echo "WARNING: $FLASK_SCRIPT not found — port 5000 will not be available"
fi

tail -f /dev/null
