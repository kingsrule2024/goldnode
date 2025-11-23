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
require nvidia-smi

# ==============================
# Auto-detect threads-per-card
# ==============================
CPU_THREADS=$(nproc)
GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

if [[ "$GPU_COUNT" -eq 0 ]]; then
  echo "❌ No GPUs detected!"
  exit 1
fi

mapfile -t VRAM_LIST < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

MAX_THREADS_NEEDED=0
for vram in "${VRAM_LIST[@]}"; do
  vram_gb=$((vram / 1024))
  rec=$((vram_gb - 3))
  if (( rec > MAX_THREADS_NEEDED )); then
    MAX_THREADS_NEEDED=$rec
  fi
done

CPU_LIMIT=$((CPU_THREADS / GPU_COUNT))

if (( CPU_LIMIT < MAX_THREADS_NEEDED )); then
  THREADS_PER_CARD=$CPU_LIMIT
else
  THREADS_PER_CARD=$MAX_THREADS_NEEDED
fi

if (( THREADS_PER_CARD < 1 )); then
  THREADS_PER_CARD=1
fi

echo "🧠 CPU threads: $CPU_THREADS"
echo "🎮 GPU count: $GPU_COUNT"
echo "💾 VRAM list: ${VRAM_LIST[*]}"
echo "⚙️ Final --threads-per-card=$THREADS_PER_CARD"

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

echo "Killing stray miner processes…"
pkill miner || true

# ==============================
# Start gpuminer in screen
# ==============================
SESSION_NAME="GPU_restarted"

MINER_CMD="./miner --pubkey=5yuRCLRTqij1SSFfUutoA3PeqAkB5kcXwuEdGdjXTYN1FQMhMotaYGK \
  --name=$(hostname) --label=Rental --threads-per-card=$THREADS_PER_CARD"

echo "Starting gpuminer in screen session: $SESSION_NAME"
screen -dmS "$SESSION_NAME" bash -lc "$MINER_CMD"

echo "✅ gpuminer is running now in screen session '$SESSION_NAME'"
