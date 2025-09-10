#!/bin/bash

# LG TV Management Setup
# Installs and configures LG TV power management tools

if [ "$PINARCHY_LG_TV" = "y" ]; then
  echo "Setting up LG TV management..."
  
  # Install bscpylgtv using mise
  echo "Installing bscpylgtv..."
  mise exec python -- python -m pip install bscpylgtv
  
else
  echo "LG TV management skipped (not requested in Q&A)"
fi