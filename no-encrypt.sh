#!/bin/bash

# Function to prompt user for continuation
prompt_continue() {
    local message="$1"
    echo -e "\n${message}"
    read -p "Press Y to continue, any other key to exit: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled by user."
        exit 1
    fi
}

# Function for verbose logging
log_info() {
    echo -e "\n[INFO] $1"
}

log_info "Starting Limine and Snapper setup for unencrypted drive"
log_info "This script will configure:"
log_info "  - mkinitcpio hooks for unencrypted system"
log_info "  - Limine bootloader with proper kernel parameters"
log_info "  - Snapper snapshot management"
log_info "  - Custom boot directory structure"

prompt_continue "Do you want to proceed with the setup?"

if command -v limine &>/dev/null; then
  log_info "Limine bootloader detected - proceeding with configuration"
  
  log_info "Step 1: Detecting root device and filesystem information"
  
  log_info "Detecting root device from chroot environment"
  log_info "Looking for root filesystem mounted at /"
  ROOT_DEVICE=$(findmnt -n -o SOURCE /)
  
  log_info "Root device detected: $ROOT_DEVICE"
  
  prompt_continue "Continue with device UUID detection?"

  # Get device UUID for unencrypted drive
  log_info "Detecting device UUID for kernel command line"
  if [[ "$ROOT_DEVICE" =~ /dev/mapper/ ]]; then
    log_info "Device is a mapper device - getting parent device UUID"
    LUKS_PARENT=$(lsblk -no PKNAME "$ROOT_DEVICE")
    ROOT_UUID=$(sudo blkid -s UUID -o value "/dev/$LUKS_PARENT")
    log_info "Parent device: /dev/$LUKS_PARENT"
  else
    log_info "Direct device - getting UUID directly"
    ROOT_UUID=$(sudo blkid -s UUID -o value "$ROOT_DEVICE")
  fi
  
  log_info "Device UUID: $ROOT_UUID"

  log_info "Detecting Btrfs subvolume information"
  ROOT_SUBVOL=$(findmnt -n -o OPTIONS / | grep -o 'subvol=[^,]*' | cut -d= -f2)
  # Fallback if no subvolume detected
  [[ -z "$ROOT_SUBVOL" ]] && ROOT_SUBVOL="@"
  log_info "Root subvolume: $ROOT_SUBVOL"

  log_info "Detecting filesystem type"
  ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)
  log_info "Root filesystem type: $ROOT_FSTYPE"

  log_info "Step 2: Detecting and selecting hostname"
  
  # Detect available hostname sources
  log_info "Detecting hostname from available sources:"
  
  HOST_FROM_VAR="$HOST"
  if command -v hostname &>/dev/null; then
    HOST_FROM_CMD=$(hostname 2>/dev/null || echo "")
  else
    HOST_FROM_CMD=""
  fi
  
  # Check /etc/hostname file
  if [ -f "/etc/hostname" ]; then
    HOST_FROM_FILE=$(cat /etc/hostname 2>/dev/null | tr -d '\n' || echo "")
  else
    HOST_FROM_FILE=""
  fi
  
  log_info "Available hostname sources:"
  [ -n "$HOST_FROM_VAR" ] && log_info "  1. \$HOST variable: '$HOST_FROM_VAR'"
  [ -n "$HOST_FROM_CMD" ] && log_info "  2. hostname command: '$HOST_FROM_CMD'"
  [ -n "$HOST_FROM_FILE" ] && log_info "  3. /etc/hostname file: '$HOST_FROM_FILE'"
  
  # Present options to user
  echo -e "\nPlease choose which hostname to use for boot directory:"
  HOSTNAME_OPTIONS=()
  [ -n "$HOST_FROM_VAR" ] && { echo "  1) $HOST_FROM_VAR (from \$HOST variable)"; HOSTNAME_OPTIONS[1]="$HOST_FROM_VAR"; }
  [ -n "$HOST_FROM_CMD" ] && { echo "  2) $HOST_FROM_CMD (from hostname command)"; HOSTNAME_OPTIONS[2]="$HOST_FROM_CMD"; }
  [ -n "$HOST_FROM_FILE" ] && { echo "  3) $HOST_FROM_FILE (from /etc/hostname)"; HOSTNAME_OPTIONS[3]="$HOST_FROM_FILE"; }
  echo "  4) Enter custom hostname"
  
  while true; do
    read -p "Enter your choice (1-4): " -n 1 -r HOSTNAME_CHOICE
    echo
    
    case $HOSTNAME_CHOICE in
      1) if [ -n "${HOSTNAME_OPTIONS[1]}" ]; then CHOSEN_HOST="${HOSTNAME_OPTIONS[1]}"; break; fi ;;
      2) if [ -n "${HOSTNAME_OPTIONS[2]}" ]; then CHOSEN_HOST="${HOSTNAME_OPTIONS[2]}"; break; fi ;;
      3) if [ -n "${HOSTNAME_OPTIONS[3]}" ]; then CHOSEN_HOST="${HOSTNAME_OPTIONS[3]}"; break; fi ;;
      4) read -p "Enter custom hostname: " CHOSEN_HOST; if [ -n "$CHOSEN_HOST" ]; then break; fi ;;
      *) echo "Invalid choice. Please try again." ;;
    esac
  done
  
  log_info "Selected hostname: '$CHOSEN_HOST'"
  CLEAN_HOST=$(echo "$CHOSEN_HOST" | sed 's/[^a-zA-Z0-9]//g')
  log_info "Cleaned hostname: $CLEAN_HOST"

  log_info "Step 3: Generating kernel command lines for unencrypted boot"
  CMDLINE_DEFAULT="quiet splash root=UUID=${ROOT_UUID} rootflags=subvol=${ROOT_SUBVOL} rw rootfstype=${ROOT_FSTYPE}"
  CMDLINE_FALLBACK="root=UUID=${ROOT_UUID} rootflags=subvol=${ROOT_SUBVOL} rw rootfstype=${ROOT_FSTYPE}"
  
  log_info "Default kernel command line:"
  log_info "  $CMDLINE_DEFAULT"
  log_info "Fallback kernel command line:"
  log_info "  $CMDLINE_FALLBACK"
  log_info "Note: No LUKS encryption parameters - direct UUID boot"
  
  prompt_continue "Continue with Limine configuration?"

  log_info "Creating /etc/default/limine configuration"
  sudo tee /etc/default/limine <<EOF >/dev/null
TARGET_OS_NAME=$CHOSEN_HOST

ESP_PATH="/boot"

KERNEL_CMDLINE[default]="$CMDLINE_DEFAULT"
KERNEL_CMDLINE[fallback]="$CMDLINE_FALLBACK"

ENABLE_UKI=yes

ENABLE_LIMINE_FALLBACK=yes

FIND_BOOTLOADERS=no

BOOT_ORDER="*, *fallback, Snapshots"

MAX_SNAPSHOT_ENTRIES=10

SNAPSHOT_FORMAT_CHOICE=5
EOF
  log_info "✓ Limine default configuration created"

  log_info "Step 4: Configuring Limine bootloader appearance"
  log_info "This will create /boot/limine.conf with Tokyo Night theme"
  
  prompt_continue "Continue with Limine visual configuration?"

  if [[ ! $(head -1 "/boot/limine.conf" 2>/dev/null) == *"# PINARCHY"* ]]; then
    log_info "Creating /boot/limine.conf with custom branding"
    sudo tee /boot/limine.conf <<EOF >/dev/null
# PINARCHY
timeout: 3
default_entry: 2
#interface_branding: 
interface_branding_color: 2
hash_mismatch_panic: no

term_background: 1a1b26
backdrop: 1a1b26

# Terminal colors (Tokyo Night palette)
term_palette: 15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6
term_palette_bright: 414868;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;c0caf5

# Text colors
term_foreground: c0caf5
term_foreground_bright: c0caf5
term_background_bright: 24283b
EOF
    log_info "✓ Limine visual configuration created with Tokyo Night theme"
  else
    log_info "Limine configuration already exists - skipping visual setup"
  fi

  log_info "Step 5: Setting up custom boot directory structure"
  CUSTOM_BOOT_DIR="/boot/EFI/${CLEAN_HOST}"
  log_info "Custom boot directory: $CUSTOM_BOOT_DIR"
  log_info "This will move kernel files to custom folder, keeping microcode in /boot"
  
  prompt_continue "Continue with boot directory setup?"

  log_info "Creating custom boot directory: $CUSTOM_BOOT_DIR"
  sudo mkdir -p "$CUSTOM_BOOT_DIR"

  log_info "Moving kernel files to custom directory"
  # Move kernel files to custom folder
  if [ -f "/boot/vmlinuz-linux" ]; then
    log_info "Moving vmlinuz-linux to $CUSTOM_BOOT_DIR/"
    sudo mv /boot/vmlinuz-linux "$CUSTOM_BOOT_DIR/"
  else
    log_info "vmlinuz-linux not found - may already be moved"
  fi

  if [ -f "/boot/initramfs-linux.img" ]; then
    log_info "Moving initramfs-linux.img to $CUSTOM_BOOT_DIR/"
    sudo mv /boot/initramfs-linux.img "$CUSTOM_BOOT_DIR/"
  else
    log_info "initramfs-linux.img not found - may already be moved"
  fi

  if [ -f "/boot/initramfs-linux-fallback.img" ]; then
    log_info "Moving initramfs-linux-fallback.img to $CUSTOM_BOOT_DIR/"
    sudo mv /boot/initramfs-linux-fallback.img "$CUSTOM_BOOT_DIR/"
  else
    log_info "initramfs-linux-fallback.img not found - may already be moved"
  fi

  log_info "Updating linux.preset paths to use custom directory"
  sudo sed -i "s|ALL_kver=\"/boot/vmlinuz-linux\"|ALL_kver=\"${CUSTOM_BOOT_DIR}/vmlinuz-linux\"|" /etc/mkinitcpio.d/linux.preset
  sudo sed -i "s|default_image=\"/boot/initramfs-linux.img\"|default_image=\"${CUSTOM_BOOT_DIR}/initramfs-linux.img\"|" /etc/mkinitcpio.d/linux.preset  
  sudo sed -i "s|#fallback_image=\"/boot/initramfs-linux-fallback.img\"|fallback_image=\"${CUSTOM_BOOT_DIR}/initramfs-linux-fallback.img\"|" /etc/mkinitcpio.d/linux.preset
  log_info "✓ Boot directory structure configured"

  log_info "Step 6: Installing Limine packages and updating bootloader"
  log_info "Installing limine-snapper-sync and limine-mkinitcpio-hook packages"
  
  prompt_continue "Continue with package installation?"
  
  sudo pacman -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook
  log_info "✓ Limine packages installed"
  
  log_info "Running limine-update to apply configuration"
  sudo limine-update
  log_info "✓ Limine bootloader updated"

  log_info "Step 7: Configuring Snapper snapshot management"
  log_info "This will create snapshot configurations for root and home"
  
  prompt_continue "Continue with Snapper configuration?"

  log_info "Creating Snapper configurations for snapshots"
  if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
    log_info "Creating Snapper config for root filesystem"
    sudo snapper -c root create-config /
    log_info "✓ Root snapshot configuration created"
  else
    log_info "Root snapshot configuration already exists"
  fi

  if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
    log_info "Creating Snapper config for home filesystem"
    sudo snapper -c home create-config /home
    log_info "✓ Home snapshot configuration created"
  else
    log_info "Home snapshot configuration already exists"
  fi

  log_info "Step 8: Optimizing Snapper settings for desktop use"
  log_info "Tweaking default configurations:"
  log_info "  - Disabling automatic timeline snapshots"
  log_info "  - Reducing snapshot limits for space efficiency"
  
  prompt_continue "Continue with Snapper optimization?"

  # Tweak default Snapper configs
  log_info "Disabling automatic timeline snapshots"
  sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
  
  log_info "Setting snapshot limits to 5 (down from 50)"
  sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}
  log_info "✓ Snapper configurations optimized"

  log_info "Step 9: Enabling Limine-Snapper integration service"
  
  prompt_continue "Continue with service enablement?"

  log_info "Enabling limine-snapper-sync service using systemctl"
  systemctl enable limine-snapper-sync.service
  log_info "✓ limine-snapper-sync.service enabled"

  log_info "Step 10: Adding Limine to UEFI boot entries"
  log_info "This will create a UEFI boot entry for Limine bootloader"
  log_info "Detecting ESP (EFI System Partition) and Limine binary location"
  
  prompt_continue "Continue with UEFI boot entry creation?"

  # Find ESP partition
  ESP_DEVICE=$(findmnt -n -o SOURCE /boot)
  if [[ -z "$ESP_DEVICE" ]]; then
    log_info "❌ Could not detect ESP partition mounted at /boot"
    log_info "Please ensure /boot is properly mounted as ESP"
    exit 1
  fi
  
  log_info "ESP device: $ESP_DEVICE"
  
  # Check for Limine EFI binary
  if [ -f "/boot/EFI/BOOT/BOOTX64.EFI" ]; then
    LIMINE_EFI_PATH="\\EFI\\BOOT\\BOOTX64.EFI"
    log_info "Found Limine EFI binary: /boot/EFI/BOOT/BOOTX64.EFI"
  elif [ -f "/boot/limine.efi" ]; then
    LIMINE_EFI_PATH="\\limine.efi"
    log_info "Found Limine EFI binary: /boot/limine.efi"
  else
    log_info "❌ Could not find Limine EFI binary"
    log_info "Expected locations: /boot/EFI/BOOT/BOOTX64.EFI or /boot/limine.efi"
    exit 1
  fi

  # Remove existing Limine entries to avoid duplicates
  log_info "Removing any existing Limine boot entries"
  efibootmgr | grep -i "limine\|$CHOSEN_HOST" | sed 's/Boot\([0-9A-F]*\).*/\1/' | while read -r entry; do
    if [ -n "$entry" ]; then
      log_info "Removing existing boot entry: $entry"
      efibootmgr -b "$entry" -B >/dev/null 2>&1 || true
    fi
  done

  # Create new UEFI boot entry
  log_info "Creating UEFI boot entry for Limine"
  log_info "Entry label: $CHOSEN_HOST"
  log_info "EFI binary path: $LIMINE_EFI_PATH"
  
  efibootmgr -c -d "$ESP_DEVICE" -p 1 -L "$CHOSEN_HOST" -l "$LIMINE_EFI_PATH"
  
  if [ $? -eq 0 ]; then
    log_info "✓ UEFI boot entry created successfully"
    log_info "Listing current boot entries:"
    efibootmgr | head -10
  else
    log_info "❌ Failed to create UEFI boot entry"
    log_info "You may need to create it manually using:"
    log_info "  efibootmgr -c -d $ESP_DEVICE -p 1 -L \"$CHOSEN_HOST\" -l \"$LIMINE_EFI_PATH\""
  fi

  log_info "🎉 Setup completed successfully!"
  log_info "Your system is now configured with:"
  log_info "  ✓ Limine bootloader for unencrypted boot"
  log_info "  ✓ Custom boot directory structure"
  log_info "  ✓ Snapper snapshot management"
  log_info "  ✓ Tokyo Night themed boot interface"
  log_info "Reboot to see the new bootloader configuration."

else
  log_info "❌ Limine bootloader not found - cannot proceed"
  log_info "Please install Limine first: pacman -S limine"
  exit 1
fi