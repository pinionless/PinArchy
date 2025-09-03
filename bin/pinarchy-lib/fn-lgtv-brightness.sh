#!/bin/bash

set -e


check_brightness_control_exists() {
  local tv_ip="$1"
  local config_file="$HOME/.config/lgtv/config.json"
  
  local brightness_enabled=$(jq -r --arg ip "$tv_ip" '.tvs[] | select(.ip == $ip) | .enabled_features.brightness_control' "$config_file")
  
  if [ "$brightness_enabled" = "true" ]; then
    return 0  # Brightness control enabled
  else
    return 1  # Brightness control disabled
  fi
}

manage_brightness_control() {
  local tv_ip="$1"
  local tv_name="$2"
  
  if check_brightness_control_exists "$tv_ip"; then
    # Brightness control enabled, ask to remove
    echo "✅ Waybar brightness control is currently enabled for this TV"
    if gum confirm "Do you want to disable waybar brightness control?"; then
      remove_brightness_control "$tv_ip" "$tv_name"
    else
      echo "ℹ️ Waybar brightness control remains enabled"
    fi
  else
    # Brightness control disabled, ask to add
    echo "❌ Waybar brightness control is not enabled for this TV"
    if gum confirm "Do you want to enable waybar brightness control?"; then
      add_brightness_control "$tv_ip" "$tv_name"
    else
      echo "ℹ️ Waybar brightness control remains disabled"
    fi
  fi
}

add_brightness_control() {
  local tv_ip="$1"
  local tv_name="$2"
  
  echo "🔆 Setting up waybar brightness control..."
  
  # Update TV config to mark brightness_control as enabled
  local config_file="$HOME/.config/lgtv/config.json"
  jq --arg ip "$tv_ip" '(.tvs[] | select(.ip == $ip) | .enabled_features.brightness_control) = true' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
  
  # Add TV brightness controls to Waybar config after "mpris"
  local waybar_config="$HOME/.config/waybar/config.jsonc"
  
  # Add brightness control modules to modules-right after mpris
  jq --arg ip "$tv_ip" '
    .["modules-right"] = (
      .["modules-right"][:(.["modules-right"] | index("mpris") + 1)] + 
      ["custom/lgtv-brightness-down", "custom/lgtv-brightness-value", "custom/lgtv-brightness-up"] +
      .["modules-right"][(.["modules-right"] | index("mpris") + 1):]
    ) |
    .["custom/lgtv-brightness-down"] = {
      "format": "󰃞",
      "tooltip": "TV Brightness Down", 
      "on-click": "pinarchy-cmd-lgtv-brightness \($ip) -10"
    } |
    .["custom/lgtv-brightness-value"] = {
      "exec": "pinarchy-cmd-lgtv-brightness-get \($ip)",
      "format": "{}%",
      "interval": 120,
      "tooltip": "TV Brightness Level"
    } |
    .["custom/lgtv-brightness-up"] = {
      "format": "󰃠",
      "tooltip": "TV Brightness Up", 
      "on-click": "pinarchy-cmd-lgtv-brightness \($ip) +10"
    }
  ' "$waybar_config" > "$waybar_config.tmp" && mv "$waybar_config.tmp" "$waybar_config"
  
  # Restart Waybar to apply changes
  omarchy-restart-waybar
  
  echo "✅ Waybar brightness control enabled for $tv_name"
  echo "   TV brightness controls added to Waybar!"
  
  return 0
}

remove_brightness_control() {
  local tv_ip="$1"
  local tv_name="$2"
  
  echo "🔅 Removing waybar brightness control..."
  
  # Update TV config to mark brightness_control as disabled  
  local config_file="$HOME/.config/lgtv/config.json"
  jq --arg ip "$tv_ip" '(.tvs[] | select(.ip == $ip) | .enabled_features.brightness_control) = false' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
  
  # Remove TV brightness controls from Waybar config
  local waybar_config="$HOME/.config/waybar/config.jsonc"
  
  # Remove the three brightness modules from modules-right and delete their definitions
  jq '
    .["modules-right"] = (.["modules-right"] - ["custom/lgtv-brightness-down", "custom/lgtv-brightness-value", "custom/lgtv-brightness-up"]) |
    del(.["custom/lgtv-brightness-down"]) |
    del(.["custom/lgtv-brightness-value"]) |
    del(.["custom/lgtv-brightness-up"])
  ' "$waybar_config" > "$waybar_config.tmp" && mv "$waybar_config.tmp" "$waybar_config"
  
  # Restart Waybar to apply changes
  omarchy-restart-waybar
  
  echo "✅ Waybar brightness control disabled for $tv_name"
  echo "   TV brightness controls removed from Waybar!"
  
  return 0
}