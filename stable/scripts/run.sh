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

# Start TradingBoat Flask app on port 5000 BEFORE ibcstart.sh (which blocks)
FLASK_SCRIPT="/home/tbot/develop/github/tbot-tradingboat/tbottmux/run_docker_flask_tbot.sh"
if [ -f "$FLASK_SCRIPT" ]; then
  echo "=== Starting TradingBoat Flask on port ${TVWB_HTTPS_PORT:-5000} ==="
  chmod a+x "$FLASK_SCRIPT"
  "$FLASK_SCRIPT" &
else
  echo "WARNING: $FLASK_SCRIPT not found — port 5000 will not be available"
fi

echo "=== Launching IBC (with no login dialog wait) ==="

/root/ibc/scripts/ibcstart.sh "${TWS_MAJOR_VRSN}" -g \
    "--tws-path=${TWS_PATH}" \
    "--ibc-path=${IBC_PATH}" \
    "--ibc-ini=${IBC_INI}" \
    "--user=${TWS_USERID}" \
    "--pw=${TWS_PASSWORD}" \
    "--mode=${TRADING_MODE}" \
    "--on2fatimeout=exit"
