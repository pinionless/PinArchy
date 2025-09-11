#!/bin/bash

set -e

check_shutdown_hook_exists() {
  local tv_ip="$1"
  local service_name="lgtv-poweroff@${tv_ip}.service"
  
  if systemctl is-enabled "$service_name" &>/dev/null; then
    echo "true"  # Hook exists
  else
    echo "false"  # Hook does not exist
  fi
}

add_shutdown_hook() {
  local tv_ip="$1"
  
  echo "⏹️ Setting up TV poweroff on shutdown..."
  
  # Create systemd service for TV power off on shutdown
  local service_name="lgtv-poweroff@${tv_ip}.service"
  
  sudo tee "/etc/systemd/system/$service_name" <<EOF >/dev/null
[Unit]
Description=Power off LG TV on shutdown
DefaultDependencies=no
Before=shutdown.target suspend.target halt.target sleep.target

[Service]
Type=oneshot
RemainAfterExit=true
User=$USER
ExecStart=/bin/true
ExecStop=/home/$USER/.local/share/omarchy/bin-pinarchy/pinarchy-lgtv-cmd-shutdown $tv_ip
TimeoutStopSec=30

[Install]
WantedBy=halt.target suspend.target shutdown.target
EOF

  # Enable the service
  sudo systemctl enable "$service_name"
  
  echo "✅ TV will now turn off automatically on system shutdown"
  echo "   Service: $service_name"
  
  return 0
}

remove_shutdown_hook() {
  local tv_ip="$1"
  
  echo "🗑️ Removing TV hook poweroff on shutdown..."
  
  local service_name="lgtv-poweroff@${tv_ip}.service"
  
  # Disable and remove the service
  sudo systemctl disable "$service_name" &>/dev/null || true
  sudo rm -f "/etc/systemd/system/$service_name"
  
  echo "✅ TV poweroff on shutdown hook removed"
  
  return 0
}