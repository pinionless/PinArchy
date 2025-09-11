#!/bin/bash

set -e

check_boot_hook_exists() {
  local tv_ip="$1"
  local service_name="lgtv-poweron@${tv_ip}.service"
  
  if systemctl is-enabled "$service_name" &>/dev/null; then
    echo "true"  # Hook exists
  else
    echo "false"  # Hook does not exist
  fi
}

add_boot_hook() {
  local tv_ip="$1"
  
  echo "🚀 Setting up TV startup on boot..."
  
  # Create systemd service for TV power on at boot
  local service_name="lgtv-poweron@${tv_ip}.service"
  
  sudo tee "/etc/systemd/system/$service_name" <<EOF >/dev/null
[Unit]
Description=Power on LG TV at boot
After=network.target
Wants=network.target

[Service]
Type=oneshot
User=$USER
ExecStart=/home/$USER/.local/share/omarchy/bin-pinarchy/lgtv/pinarchy-cmd-lgtv-wol $tv_ip
RemainAfterExit=yes
TimeoutStartSec=30

[Install]
WantedBy=multi-user.target
EOF

  # Enable the service
  sudo systemctl enable "$service_name"
  
  echo "✅ TV will now turn on automatically at system boot"
  echo "   Service: $service_name"
  
  return 0
}

remove_boot_hook() {
  local tv_ip="$1"
  
  echo "🗑️ Removing TV startup on boot..."
  
  local service_name="lgtv-poweron@${tv_ip}.service"
  
  # Disable and remove the service
  sudo systemctl disable "$service_name" &>/dev/null || true
  sudo rm -f "/etc/systemd/system/$service_name"
  
  echo "✅ TV boot startup removed"
  
  return 0
}