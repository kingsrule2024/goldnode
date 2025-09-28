#!/bin/bash

set -euo pipefail

./gpuminer --pubkey=3jdRadLZyw1FPCMdzM4KKcDXgk3EWeg4ZX9mfD8ZeGPJ8TAwpLHxrwTD97MmQ64KWHAQ4y41Au7T4881N1JzFG3SGRxj3SXgHRFLbHxdKHCYLWW31BaQuzCFecMciyhkMUPB --name=$(hostname) --label=Rental

# Echo status
echo "gpuminer is running now"
