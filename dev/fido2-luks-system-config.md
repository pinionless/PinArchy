# FIDO2 LUKS System Configuration Guide

Configuration changes required for FIDO2 authentication with LUKS disk encryption during system startup.

## Required Package Dependencies

### Critical Missing Dependency
- **`libfido2`** - MUST be installed before running `mkinitcpio -P`
  - Missing this package causes `systemd-cryptsetup` to fail during boot
  - Discovered through `strace` analysis showing missing `/usr/lib/libfido2.so.1`

### Additional Dependencies
- `systemd` (version 248+) - provides systemd-cryptenroll utility
- Base system with FIDO2-compatible hardware key

## mkinitcpio Configuration

### Required Hooks in `/etc/mkinitcpio.conf`
```bash
HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)
```

**Critical Hook Changes:**
- **`systemd`** - Required instead of `udev` for systemd-based initramfs
- **`sd-vconsole`** - Replaces `keymap` for systemd hook chain  
- **`sd-encrypt`** - Replaces `encrypt` hook for systemd cryptsetup support

**Hook Order Requirements:**
- `systemd` must come before `sd-encrypt`
- `keyboard` and `sd-vconsole` must come before `sd-encrypt`
- `block` must come before `sd-encrypt`

## Bootloader Configuration (Limine)

### Kernel Parameters Required
Add to Limine configuration file (`/boot/limine.cfg`):

```toml
:Arch Linux FIDO2
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz-linux
CMDLINE=rd.luks.name=<UUID>=<mapper-name> rd.luks.options=fido2-device=auto root=/dev/mapper/<mapper-name> rw
MODULE_PATH=boot:///initramfs-linux.img
```

**Parameter Breakdown:**
- `rd.luks.name=<UUID>=<mapper-name>` - Maps encrypted device UUID to device mapper name
- `rd.luks.options=fido2-device=auto` - Enables FIDO2 automatic device detection
- `root=/dev/mapper/<mapper-name>` - Points to decrypted root filesystem

**Complete Example:**
```toml
:Arch Linux FIDO2
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz-linux
CMDLINE=rd.luks.name=0e916d16-2e29-4651-b074-6588f57dd596=luksdev rd.luks.options=fido2-device=auto root=/dev/mapper/luksdev rw
MODULE_PATH=boot:///initramfs-linux.img
```

### Optional Parameters
- `rd.luks.options=fido2-device=auto,password-echo=no` - Disable password echo
- `rd.luks.options=fido2-device=auto,timeout=20` - Set unlock timeout

**Extended Example with Options:**
```toml
CMDLINE=rd.luks.name=0e916d16-2e29-4651-b074-6588f57dd596=luksdev rd.luks.options=fido2-device=auto,password-echo=no,timeout=20 root=/dev/mapper/luksdev rw
```

## Alternative Configuration: crypttab.initramfs

### Using `/etc/crypttab.initramfs`
```bash
<mapper-name> UUID=<device-uuid> none fido2-device=auto,luks
```

**Example:**
```bash
luksdev UUID=0e916d16-2e29-4651-b074-6588f57dd596 none fido2-device=auto,luks
```

**Important Notes:**
- Use `UUID` not `PARTUUID` for the encrypted device
- The `none` parameter is required for FIDO2 (no password file)
- Adding this file may conflict with kernel parameters - choose one method

## System Files Modified

### 1. `/etc/mkinitcpio.conf`
- Update HOOKS array with systemd-based hooks
- Ensure `systemd`, `sd-vconsole`, and `sd-encrypt` are included

### 2. Bootloader Configuration File
- `/boot/limine.cfg` (Limine)
- Add required kernel parameters to CMDLINE

### 3. `/etc/crypttab.initramfs` (Optional)
- Alternative to kernel parameters
- Processed during initramfs generation

## Post-Configuration Steps

### Required Commands After Changes
```bash
# Install missing dependency if not present
sudo pacman -S libfido2

# Regenerate initramfs with new configuration
sudo mkinitcpio -P

# No bootloader regeneration needed for Limine
# Configuration changes take effect immediately
```

### Verification Steps
```bash
# Check FIDO2 device detection
systemd-cryptenroll --fido2-device=list

# Verify initramfs includes systemd components
lsinitcpio /boot/initramfs-linux.img | grep systemd

# Test manual unlock (before reboot)
cryptsetup open /dev/sdX <mapper-name>
```

## Common Pitfalls

### Boot Failures
- **Missing `libfido2`** - Most common cause of boot hanging
- **Wrong hook order** - `sd-encrypt` must come after `systemd`
- **Conflicting configurations** - Don't use both kernel parameters and crypttab.initramfs

### Compatibility Issues  
- **BIOS/Legacy systems** - FIDO2 requires UEFI boot
- **Older systemd versions** - Requires systemd 248+
- **Hardware compatibility** - Not all FIDO2 keys work with all systems

### Debugging Failed Boots
- Check `systemd-cryptsetup@<mapper-name>.service` status
- Use `rd.debug` kernel parameter for verbose boot logging
- Emergency shell access for troubleshooting

## Integration with Omarchy

### Installation Phase Integration
Add to appropriate installation phase:
```bash
# Install required packages
pacman -S --needed libfido2

# Configure mkinitcpio hooks for FIDO2
sed -i 's/HOOKS=(base udev/HOOKS=(base systemd/' /etc/mkinitcpio.conf
sed -i 's/encrypt/sd-encrypt/' /etc/mkinitcpio.conf
sed -i 's/keymap/sd-vconsole/' /etc/mkinitcpio.conf
```

### Migration Considerations
- Existing LUKS setups need hook migration
- Backup existing configurations before changes
- Test in VM environment first