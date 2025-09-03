#!/bin/bash

if command -v limine &>/dev/null; then
  sudo tee /etc/mkinitcpio.conf.d/pinarchy_hooks.conf <<EOF >/dev/null
HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole consolefont block sd-encrypt filesystems fsck btrfs-overlayfs)
EOF

  if [ -n "${OMARCHY_CHROOT_INSTALL:-}" ]; then
    ROOT_DEVICE=$(findmnt -n -o SOURCE /mnt 2>/dev/null || findmnt -n -o SOURCE /mnt/root 2>/dev/null)
  else
    ROOT_DEVICE=$(findmnt -n -o SOURCE /)
  fi

  if [[ "$ROOT_DEVICE" =~ /dev/mapper/ ]]; then
    LUKS_PARENT=$(lsblk -no PKNAME "$ROOT_DEVICE")
    LUKS_UUID=$(sudo cryptsetup luksDump "/dev/$LUKS_PARENT" | grep "UUID:" | awk '{print $2}')
  fi

  if [ -n "${OMARCHY_CHROOT_INSTALL:-}" ]; then
      ROOT_SUBVOL=$(findmnt -n -o OPTIONS /mnt 2>/dev/null | grep -o 'subvol=[^,]*' | cut -d= -f2)
      [[ -z "$ROOT_SUBVOL" ]] && ROOT_SUBVOL=$(findmnt -n -o OPTIONS /mnt/root 2>/dev/null | grep -o 'subvol=[^,]*' | cut -d= -f2)
  else
      ROOT_SUBVOL=$(findmnt -n -o OPTIONS / | grep -o 'subvol=[^,]*' | cut -d= -f2)
  fi
  # Fallback if no subvolume detected
  [[ -z "$ROOT_SUBVOL" ]] && ROOT_SUBVOL="@"

  if [ -n "${OMARCHY_CHROOT_INSTALL:-}" ]; then
      ROOT_FSTYPE=$(findmnt -n -o FSTYPE /mnt 2>/dev/null || findmnt -n -o FSTYPE /mnt/root 2>/dev/null)
  else
      ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)
  fi

  CMDLINE_DEFAULT="quiet splash rd.luks.name=${LUKS_UUID}=root rd.luks.options=fido2-device=auto root=/dev/mapper/root rootflags=subvol=${ROOT_SUBVOL} rw rootfstype=${ROOT_FSTYPE}"
  CMDLINE_FALLBACK="rd.luks.name=${LUKS_UUID}=root root=/dev/mapper/root rootflags=subvol=${ROOT_SUBVOL} rw rootfstype=${ROOT_FSTYPE}"

  sudo tee /etc/default/limine <<EOF >/dev/null
TARGET_OS_NAME=$HOST

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

  if [[ ! $(head -1 "/boot/limine.conf" 2>/dev/null) == *"# PINARCHY"* ]]; then
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
  fi

  # linux.preset customization - move kernel to custom folder, keep microcode in /boot
  CLEAN_HOST=$(echo "$HOST" | sed 's/[^a-zA-Z0-9]//g')  # Remove special chars
  CUSTOM_BOOT_DIR="/boot/EFI/${CLEAN_HOST}"

  # Create custom boot directory
  sudo mkdir -p "$CUSTOM_BOOT_DIR"

  # Move kernel files to custom folder
  if [ -f "/boot/vmlinuz-linux" ]; then
    sudo mv /boot/vmlinuz-linux "$CUSTOM_BOOT_DIR/"
  fi

  if [ -f "/boot/initramfs-linux.img" ]; then
    sudo mv /boot/initramfs-linux.img "$CUSTOM_BOOT_DIR/"
  fi

  if [ -f "/boot/initramfs-linux-fallback.img" ]; then
    sudo mv /boot/initramfs-linux-fallback.img "$CUSTOM_BOOT_DIR/"
  fi

  # Update linux.preset paths for kernel and initramfs only
  sudo sed -i "s|ALL_kver=\"/boot/vmlinuz-linux\"|ALL_kver=\"${CUSTOM_BOOT_DIR}/vmlinuz-linux\"|" /etc/mkinitcpio.d/linux.preset
  sudo sed -i "s|default_image=\"/boot/initramfs-linux.img\"|default_image=\"${CUSTOM_BOOT_DIR}/initramfs-linux.img\"|" /etc/mkinitcpio.d/linux.preset  
  sudo sed -i "s|#fallback_image=\"/boot/initramfs-linux-fallback.img\"|fallback_image=\"${CUSTOM_BOOT_DIR}/initramfs-linux-fallback.img\"|" /etc/mkinitcpio.d/linux.preset

  # Create pacman hook to automate kernel file moves
  sudo mkdir -p /etc/pacman.d/hooks
  sudo tee /etc/pacman.d/hooks/89-efi-sync.hook <<EOF >/dev/null
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux

[Action]
Description = Moving kernel files to /boot/EFI/${CLEAN_HOST}/...
When = PostTransaction
Exec = /bin/sh -c 'if [ -f /boot/vmlinuz-linux ]; then mv -f /boot/vmlinuz-linux /boot/EFI/${CLEAN_HOST}/vmlinuz-linux; fi'
EOF

  sudo pacman -S --noconfirm --needed limine-snapper-sync limine-mkinitcpio-hook
  sudo limine-update

  # Match Snapper configs if not installing from the ISO
  if [ -z "${OMARCHY_CHROOT_INSTALL:-}" ]; then
    if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
      sudo snapper -c root create-config /
    fi

    if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
      sudo snapper -c home create-config /home
    fi
  fi

  # Tweak default Snapper configs
  sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home}
  sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home}

  chrootable_systemctl_enable limine-snapper-sync.service

fi