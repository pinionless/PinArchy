#!/bin/bash

set -e

add_tvapp() {
  local tv_ip="$1"
    
  # Get selected app using fzf
  local selected_app=$(pinarchy-lgtv-tvapp-list "$tv_ip")

  if [ -z "$selected_app" ]; then
    return 1
  fi
  
  # Parse the selected app (format: "Title | app.id")
  local app_title=$(echo "$selected_app" | sed 's/ | .*//')
  local app_id=$(echo "$selected_app" | sed 's/.* | //')
  
  echo "🎯 Selected: $app_title ($app_id)"
  echo
  
  # Prompt for icon URL
  local icon_url=$(gum input --prompt "Icon URL> " --placeholder "See https://dashboardicons.com (must use PNG!)")
  local icon_line=""
  
  if [ -n "$icon_url" ]; then
    echo "📥 Downloading icon..."
    local icon_dir="$HOME/.local/share/applications/icons"
    mkdir -p "$icon_dir"
    local icon_path="$icon_dir/lgtv-${app_id}.png"
    
    if curl -sL -o "$icon_path" "$icon_url"; then
      icon_line="Icon=$icon_path"
      echo "✅ Icon downloaded successfully"
    else
      echo "❌ Failed to download icon, proceeding without icon"
    fi
  else
    echo "ℹ️ No icon URL provided, proceeding without icon"
  fi
  echo
  
  # Create desktop file
  local desktop_file="$HOME/.local/share/applications/lgtv-${tv_ip}-${app_id}.desktop"
  
  cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_title
Comment=Launch $app_title on TV
Exec=pinarchy-cmd-lgtv-launch $tv_ip $app_id
${icon_line}
Terminal=false
Categories=AudioVideo;TV;
StartupNotify=false
EOF
  
  echo "✅ TV app launcher created!"
  echo "   App: $app_title"
  echo "   Desktop file: $desktop_file"
  echo "   You can now find '$app_title' in your application launcher"
  
  return 0
}

get_installed_tvapps() {
  local apps_dir="$HOME/.local/share/applications"
  
  echo "📱 Select installed TV app to remove:" >&2
  
  # Step 1: Find all lgtv-*.desktop files
  local files=()
  readarray -t files < <(find "$apps_dir" -name "lgtv-*.desktop" 2>/dev/null)
  
  # Check if any files found
  if [ ${#files[@]} -eq 0 ]; then
    return 1
  fi
  
  # Step 2: Extract app names and build list for fzf
  local apps_list=""
  for file in "${files[@]}"; do
    local app_name=$(grep "^Name=" "$file" | cut -d'=' -f2-)
    if [ -n "$app_name" ]; then
      apps_list="${apps_list}${app_name}⠀${file}"$'\n'
    fi
  done
  
  # Use fzf to select app (show name, return full line)
  local selected=$(echo -n "$apps_list" | fzf --prompt="Select TV App to Remove: " --height=15 --reverse --border --delimiter='⠀' --with-nth=1)
  
  if [ -n "$selected" ]; then
    echo "$selected"
  fi
  
  return $?
}

remove_tvapp() {
  local selected_app=$(get_installed_tvapps)
  
  if [ -z "$selected_app" ]; then
    return 1
  fi
  
  # Parse the selected app (format: "app_name|desktop_file_path")
  local app_name="${selected_app%%⠀*}"
  local desktop_file="${selected_app##*⠀}"
  
  echo "🗑️ Selected: $app_name"
  
  # Remove desktop file if it exists
  if [ -f "$desktop_file" ]; then
    # Check if there's a custom icon to remove
    local icon_value=$(grep "^Icon=" "$desktop_file" | cut -d'=' -f2-)
    
    rm "$desktop_file"
    echo "✅ Desktop file removed: $desktop_file"
    
    # Remove custom icon if it exists and is in our icons directory
    if [[ "$icon_value" == *"/.local/share/applications/icons/"* ]] && [ -f "$icon_value" ]; then
      rm "$icon_value"
      echo "✅ Custom icon removed: $icon_value"
    fi
    echo "✅ TV app '$app_name' removed successfully"
  else
    echo "⚠️ Desktop file not found: $desktop_file"
  fi
  
  return 0
}