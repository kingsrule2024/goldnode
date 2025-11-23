#!/bin/bash

set -euo pipefail

# -----------------------------
# Detect CPU threads
# -----------------------------
CPU_THREADS=$(nproc)

# -----------------------------
# Detect NVIDIA GPU count + VRAM
# -----------------------------
if ! command -v nvidia-smi &>/dev/null; then
  echo "Error: nvidia-smi not found!"
  exit 1
fi

GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

if [[ "$GPU_COUNT" -eq 0 ]]; then
  echo "Error: No GPUs detected!"
  exit 1
fi

# Get VRAM (in GB) of each GPU into an array
mapfile -t VRAM_LIST < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

# -----------------------------
# Determine per-GPU recommended threads
# -----------------------------
MAX_THREADS_NEEDED=0

for vram in "${VRAM_LIST[@]}"; do
  # Convert MB → GB
  vram_gb=$((vram / 1024))
  recommended=$((vram_gb - 3))

  # Example: 8GB → 5, 12GB → 9, etc.
  if (( recommended > MAX_THREADS_NEEDED )); then
    MAX_THREADS_NEEDED=$recommended
  fi
done

# -----------------------------
# Check CPU limitation
# -----------------------------
# Threads available per GPU if CPU is limiting
CPU_LIMIT=$((CPU_THREADS / GPU_COUNT))

# Final threads-per-card is minimum of:
#   - GPU VRAM logic (vram-3)
#   - CPU limit (CPU_THREADS / GPU_COUNT)
if (( CPU_LIMIT < MAX_THREADS_NEEDED )); then
  THREADS_PER_CARD=$CPU_LIMIT
else
  THREADS_PER_CARD=$MAX_THREADS_NEEDED
fi

# Safety: must be at least 1
if (( THREADS_PER_CARD < 1 )); then
  THREADS_PER_CARD=1
fi

echo "CPU threads: $CPU_THREADS"
echo "GPUs: $GPU_COUNT"
echo "VRAM list: ${VRAM_LIST[*]}"
echo "Final --threads-per-card=$THREADS_PER_CARD"

# -----------------------------
# Run miner
# -----------------------------
./miner \
  --pubkey=5yuRCLRTqij1SSFfUutoA3PeqAkB5kcXwuEdGdjXTYN1FQMhMotaYGK \
  --name=$(hostname) \
  --label=Rental \
  --threads-per-card="$THREADS_PER_CARD"

echo "gpu miner is running now"
