#!/bin/bash

set -e

add_volume_control() {
  local tv_ip="$1"
  local step="$2"
  
  echo "🔊 Setting up waybar volume control..."
  
  # Update TV config to mark waybar_volume_control as enabled
  local config_file="$HOME/.config/lgtv/config.json"
  jq --arg ip "$tv_ip" '(.tvs[] | select(.ip == $ip) | .enabled_features.waybar_volume_control) = true' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
  
  # Add TV volume controls to Waybar config after "mpris"
  local waybar_config="$HOME/.config/waybar/config.jsonc"
  
  # Add the three modules to modules-right after "mpris"
  jq --arg ip "$tv_ip" '
    .["modules-right"] = (
      .["modules-right"][:(.["modules-right"] | index("mpris") + 1)] + 
      ["custom/lgtv-volume-down", "custom/lgtv-tv-icon", "custom/lgtv-volume-up"] +
      .["modules-right"][(.["modules-right"] | index("mpris") + 1):]
    ) |
    .["custom/lgtv-volume-down"] = {
      "format": "󰝞",
      "tooltip": "TV Volume Down",
      "on-click": "pinarchy-lgtv-cmd-volume \($ip) -$step"
    } |
    .["custom/lgtv-tv-icon"] = {
      "format": "",
      "tooltip": "Turn screen off",
      "on-click": "pinarchy-lgtv-cmd-screenoff \($ip)"
    } |
    .["custom/lgtv-volume-up"] = {
      "format": "󰝝",
      "tooltip": "TV Volume Up", 
      "on-click": "pinarchy-lgtv-cmd-volume \($ip) +$step"
    }
  ' "$waybar_config" > "$waybar_config.tmp" && mv "$waybar_config.tmp" "$waybar_config"
  
  # Add CSS styling for volume controls
  local waybar_css="$HOME/.config/waybar/style.css"
  
  # Check if volume styles already exist
  if ! grep -q "#custom-lgtv-volume-down" "$waybar_css" 2>/dev/null; then
    cat >> "$waybar_css" << 'EOF'

#custom-lgtv-volume-down {
  min-width: 12px;
  margin-left: 7.5px;
}
#custom-lgtv-tv-icon {
  min-width: 12px;
  padding-right: 5px;
  padding-left: 1px;
}
#custom-lgtv-volume-up {
  min-width: 12px;
  margin-right: 7.5px;
}
EOF
  fi
  
  # Restart Waybar to apply changes
  omarchy-restart-waybar
  
  echo "✅ Waybar volume control enabled"
  
  return 0
}

remove_volume_control() {
  local tv_ip="$1"
  
  echo "🔇 Removing waybar volume control..."
  
  # Update TV config to mark waybar_volume_control as disabled  
  local config_file="$HOME/.config/lgtv/config.json"
  jq --arg ip "$tv_ip" '(.tvs[] | select(.ip == $ip) | .enabled_features.waybar_volume_control) = false' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
  
  # Remove TV volume controls from Waybar config
  local waybar_config="$HOME/.config/waybar/config.jsonc"
  
  # Remove the three TV modules from modules-right and delete their definitions
  jq '
    .["modules-right"] = (.["modules-right"] - ["custom/lgtv-volume-down", "custom/lgtv-tv-icon", "custom/lgtv-volume-up"]) |
    del(.["custom/lgtv-volume-down"]) |
    del(.["custom/lgtv-tv-icon"]) |
    del(.["custom/lgtv-volume-up"])
  ' "$waybar_config" > "$waybar_config.tmp" && mv "$waybar_config.tmp" "$waybar_config"
  
  # Remove CSS styling for volume controls
  local waybar_css="$HOME/.config/waybar/style.css"
  
  # Remove the volume CSS block
  if grep -q "#custom-lgtv-volume-down" "$waybar_css" 2>/dev/null; then
    sed -i '/^$/,/^#custom-lgtv-volume-up/{ /^#custom-lgtv-volume-down/,/^}$/d; /^#custom-lgtv-tv-icon/,/^}$/d; /^#custom-lgtv-volume-up/,/^}$/d; }' "$waybar_css"
  fi
  
  # Restart Waybar to apply changes
  omarchy-restart-waybar
  
  echo "✅ Waybar volume control disabled"
  
  return 0
}
