#!/bin/bash

set -e

get_tv_apps() {
  local tv_ip="$1"
  
  echo "📱 Getting available apps from TV at $tv_ip..."
  
  # Get all apps from TV
  local apps_json=$(bscpylgtvcommand "$tv_ip" get_apps_all true -p "$HOME/.config/lgtv/bscpylgtv.sqlite" 2>/dev/null)
  
  if [ -z "$apps_json" ]; then
    echo "❌ Failed to get apps from TV. Make sure TV is on and connected."
    return 1
  fi
  
  # Extract title and id, filter visible apps only, create fzf format
  echo "$apps_json" | jq -r '.[] | select(.visible == true) | "\(.title) | \(.id)"' | sort | fzf --prompt="Select TV App: " --height=15 --reverse --border
  
  return $?
}

add_tv_app() {
  local tv_ip="$1"
  local tv_name="$2"
  
  echo "📱 Adding TV app to desktop launcher..."
  
  # Get selected app using fzf
  local selected_app=$(get_tv_apps "$tv_ip")
  
  if [ -z "$selected_app" ]; then
    echo "❌ No app selected or failed to get apps"
    return 1
  fi
  
  # Parse the selected app (format: "Title | app.id")
  local app_title=$(echo "$selected_app" | cut -d' | ' -f1)
  local app_id=$(echo "$selected_app" | cut -d' | ' -f2)
  
  echo "🎯 Selected: $app_title ($app_id)"
  
  # Create desktop file
  local desktop_file="$HOME/.local/share/applications/lgtv-${app_id}.desktop"
  
  cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$tv_name - $app_title
Comment=Launch $app_title on $tv_name TV
Exec=pinarchy-cmd-lgtv-launch $tv_ip $app_id
Icon=tv
Terminal=false
Categories=AudioVideo;TV;
StartupNotify=false
EOF
  
  echo "✅ TV app launcher created!"
  echo "   App: $app_title"
  echo "   Desktop file: $desktop_file"
  echo "   You can now find '$tv_name - $app_title' in your application launcher"
  
  return 0
}