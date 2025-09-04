#!/bin/bash

set -e

get_tv_apps() {
  local tv_ip="$1"
  
  echo "📱 Getting available apps from TV at $tv_ip..." >&2
  
  # Get all apps from TV
  local apps_json=$(bscpylgtvcommand "$tv_ip" get_apps_all true -p "$HOME/.config/lgtv/bscpylgtv.sqlite" 2>/dev/null)
  
  if [ -z "$apps_json" ]; then
    echo "❌ Failed to get apps from TV. Make sure TV is on and connected." >&2
    return 1
  fi
  
  # Extract title and id, filter visible apps only, create fzf format
  local apps_list=$(echo "$apps_json" | jq -r '.[] | select(.visible == true) | "\(.title) | \(.id)"' | sort)
  echo "DEBUG: apps_list = '$apps_list'" >&2
  local fzf_result=$(echo "$apps_list" | fzf --prompt="Select TV App: " --height=15 --reverse --border)
  echo "DEBUG: fzf_result = '$fzf_result'" >&2
  echo "$fzf_result"
  
  return $?
}

add_tv_app() {
  local tv_ip="$1"
  local tv_name="$2"
  
  echo "📱 Adding TV app to desktop launcher..."
  
  # Get selected app using fzf
  local selected_app=$(get_tv_apps "$tv_ip")
  
  echo "DEBUG: selected_app = '$selected_app'" >&2
  
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
Name=$app_title
Comment=Launch $app_title on $tv_name TV
Exec=pinarchy-cmd-lgtv-launch $tv_ip $app_id
Icon=tv
Terminal=false
Categories=AudioVideo;TV;
StartupNotify=false
EOF
  
  # Track installed app
  local tvapps_file="$HOME/.config/lgtv/tvapps"
  echo "${app_title}:${app_id}:${desktop_file}" >> "$tvapps_file"
  
  echo "✅ TV app launcher created!"
  echo "   App: $app_title"
  echo "   Desktop file: $desktop_file"
  echo "   You can now find '$app_title' in your application launcher"
  
  return 0
}

get_installed_tvapps() {
  local tvapps_file="$HOME/.config/lgtv/tvapps"
  
  echo "📱 Select installed TV app to remove:"
  
  # Read file and create fzf format (show only title, but return full line for processing)
  local temp_file=$(mktemp)
  cat "$tvapps_file" > "$temp_file"
  
  # Create display format (just title) but track line numbers
  local selected_line=$(cat "$temp_file" | nl -nln | while read -r line_num line_content; do
    local title=$(echo "$line_content" | cut -d':' -f1)
    echo "$title|$line_num"
  done | fzf --prompt="Select TV App to Remove: " --height=15 --reverse --border --delimiter='|' --with-nth=1 | cut -d'|' -f2)
  
  if [ -n "$selected_line" ]; then
    sed -n "${selected_line}p" "$temp_file"
  fi
  
  rm -f "$temp_file"
  
  return $?
}

remove_tvapp() {
  local selected_app=$(get_installed_tvapps)
  
  if [ -z "$selected_app" ]; then
    echo "❌ No app selected"
    return 1
  fi
  
  # Parse the selected app (format: "title:app_id:desktop_file")
  local app_title=$(echo "$selected_app" | cut -d':' -f1)
  local app_id=$(echo "$selected_app" | cut -d':' -f2)
  local desktop_file=$(echo "$selected_app" | cut -d':' -f3)
  
  echo "🗑️ Removing TV app: $app_title"
  
  # Remove desktop file if it exists
  if [ -f "$desktop_file" ]; then
    rm "$desktop_file"
    echo "✅ Desktop file removed: $desktop_file"
  else
    echo "⚠️ Desktop file not found: $desktop_file"
  fi
  
  # Remove from tracking file
  local tvapps_file="$HOME/.config/lgtv/tvapps"
  local temp_file="${tvapps_file}.tmp"
  
  # Create temp file without the selected line
  grep -v "^${app_title}:${app_id}:${desktop_file}$" "$tvapps_file" > "$temp_file" || true
  mv "$temp_file" "$tvapps_file"
  
  echo "✅ TV app '$app_title' removed successfully"
  
  return 0
}