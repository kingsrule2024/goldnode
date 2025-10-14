#!/bin/bash

set -euo pipefail

# Get total number of CPU threads and subtract 4
TOTAL_THREADS=$(nproc)
THREADS=$((TOTAL_THREADS - 4))

# Ensure thread count doesn't go below 1
if [ "$THREADS" -lt 1 ]; then
  THREADS=1
fi

# Run xmrig with adjusted thread count
./xmrig -Xmx1g -Xms1g -Xss256k -u 43bwz132tFNtFnmRp9yHQFPprF72JnTLb9.$(hostname) -h 146.103.50.122 -P 5001 -t "$THREADS"

# Echo status
echo "xmrig is running now with $THREADS threads (total: $TOTAL_THREADS)"