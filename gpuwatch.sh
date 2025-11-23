#!/bin/bash

set -euo pipefail

# ==============================
# Get GPU worker name
# ==============================
GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
GPU_MODEL=$(echo "$GPU_INFO" | sed -E 's/^(NVIDIA |nvidia )//; s/(GeForce |geforce )//; s/(RTX |rtx )//; s/[Ss][Uu][Pp][Ee][Rr]/S/; s/ //g')
ORDER_NUM=$(hostname)
WORKERNAME="${GPU_MODEL}_${ORDER_NUM}"
echo "🎮 GPU worker name: $WORKERNAME"

# ==============================
# Auto-detect threads-per-card
# ==============================

# CPU threads
CPU_THREADS=$(nproc)

# GPU count
GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
if [[ "$GPU_COUNT" -eq 0 ]]; then
    echo "❌ No NVIDIA GPUs detected!"
    exit 1
fi

# VRAM list (MB)
mapfile -t VRAM_LIST < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

# Determine max VRAM-based recommendation
MAX_THREADS_NEEDED=0
for vram in "${VRAM_LIST[@]}"; do
    vram_gb=$((vram / 1024))
    rec=$((vram_gb - 3))   # VRAM - 3 logic
    if (( rec > MAX_THREADS_NEEDED )); then
        MAX_THREADS_NEEDED=$rec
    fi
done

# CPU limitation
CPU_LIMIT=$((CPU_THREADS / GPU_COUNT))

if (( CPU_LIMIT < MAX_THREADS_NEEDED )); then
    THREADS_PER_CARD=$CPU_LIMIT
else
    THREADS_PER_CARD=$MAX_THREADS_NEEDED
fi

# Safety floor
if (( THREADS_PER_CARD < 1 )); then
    THREADS_PER_CARD=1
fi

echo "🧠 CPU threads: $CPU_THREADS"
echo "🎮 GPU count: $GPU_COUNT"
echo "💾 VRAM list (MB): ${VRAM_LIST[*]}"
echo "⚙️ Final --threads-per-card=$THREADS_PER_CARD"

# ==============================
# Config
# ==============================
APP="/root/miner"   # full path to miner binary
WALLET="5yuRCLRTqij1SSFfUutoA3PeqAkB5kcXwuEdGdjXTYN1FQMhMotaYGK"

# Inject dynamic value
ARGS="--pubkey $WALLET --name=$(hostname) --label=Rental --threads-per-card=$THREADS_PER_CARD"

CHECK_INTERVAL=10
LOGFILE="/root/GPU_watch.log"

# ==============================
# Loop
# ==============================
echo "[WATCHDOG] Starting watchdog for GPU miner..."
while true; do
    if pgrep -x "$(basename "$APP")" > /dev/null; then
        echo "[WATCHDOG] Miner is running." | tee -a "$LOGFILE"
    else
        echo "[WATCHDOG] Miner not running. Starting..." | tee -a "$LOGFILE"
        $APP $ARGS &
    fi
    sleep $CHECK_INTERVAL
done
