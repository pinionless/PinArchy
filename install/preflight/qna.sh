#!/bin/bash

# Q&A script for gathering user preferences before installation
# This script runs first in the preflight phase to collect user choices

echo "=== PinArchy Installation Q&A ==="
echo

# LG TV management
read -p "Install LG TV management tools? (y/N) [N]: " PINARCHY_LG_TV
export PINARCHY_LG_TV="${PINARCHY_LG_TV:-N}"

echo "Q&A complete. Proceeding with installation..."