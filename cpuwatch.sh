#!/bin/bash
# ==============================
# Get CPU worker name
# ==============================
CPU_INFO=$(lscpu | grep "Model name" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
CPU_MODEL=$(echo "$CPU_INFO" | sed -E 's/(Intel|AMD)[^(]*//; s/[^A-Za-z0-9]//g')
ORDER_NUM=$(hostname)
WORKERNAME="${CPU_MODEL}_${ORDER_NUM}"
echo "🧠 CPU worker name: $WORKERNAME"

# ==============================
# Config
# ==============================
APP="/root/xmrig"   # full path to miner binary

# Dynamically get CPU thread count minus 4
TOTAL_THREADS=$(nproc)
THREADS=$((TOTAL_THREADS - 4))
if [ "$THREADS" -lt 1 ]; then
  THREADS=1
fi

# Append workername to wallet
WALLET="43bwz132tFNtFnmRp9yHQFPprF72JnTLb9"
ARGS="-Xmx1g -Xms1g -Xss256k -u $WALLET.$(hostname) -h 146.103.50.122 -P 5001 -t $THREADS"
CHECK_INTERVAL=10                # seconds between checks
LOGFILE="/root/CPU_watch.log"

# ==============================
# Loop
# ==============================
echo "[WATCHDOG] Starting watchdog for CPU miner..."
while true; do
    if pgrep -x "$(basename "$APP")" > /dev/null; then
        echo "[WATCHDOG] Miner is running." | tee -a "$LOGFILE"
    else
        echo "[WATCHDOG] Miner not running. Starting..." | tee -a "$LOGFILE"
        $APP $ARGS &
    fi
    sleep $CHECK_INTERVAL
done
