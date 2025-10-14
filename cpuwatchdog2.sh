#!/bin/bash

# Load environment
source /etc/profile
[ -f ~/.bashrc ] && source ~/.bashrc

cd /root/ || exit 1

set -euo pipefail

# ==============================
# Requirements
# ==============================
require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' not found. Please install it."; exit 1; }
}

require screen

# ==============================
# Cleanup old miner sessions
# ==============================
echo "Cleaning up old miner_* screen sessions…"
OLD_SESSIONS=$(screen -ls | awk '/miner_/ {print $1}' || true)

if [[ -n "$OLD_SESSIONS" ]]; then
  for s in $OLD_SESSIONS; do
    echo "Attempting to kill $s"
    screen -S "$s" -X quit || true
  done
fi

screen -wipe >/dev/null || true

# Kill any miner processes outside screen
echo "Killing stray miner processes…"
pkill xmrig || true

# ==============================
# Start gpuminer in screen
# ==============================

# Dynamically determine CPU thread count minus 4
TOTAL_THREADS=$(nproc)
THREADS=$((TOTAL_THREADS - 4))
if [ "$THREADS" -lt 1 ]; then
  THREADS=1
fi

SESSION_NAME="CPU_restarted"
MINER_CMD="./xmrig -Xmx1g -Xms1g -Xss256k -u 43bwz132tFNtFnmRp9yHQFPprF72JnTLb9.$(hostname) -h 146.103.50.122 -P 5001 -t $THREADS"

echo "Starting gpuminer in screen session: $SESSION_NAME"
screen -dmS "$SESSION_NAME" bash -lc "$MINER_CMD"

echo "✅ gpuminer is running now in screen session '$SESSION_NAME'"
