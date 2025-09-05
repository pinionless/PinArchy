# Hibernation with Swapfile in Btrfs Subvolume - Comprehensive Research

**Research Date:** September 2025  
**Target System:** Arch Linux with LUKS encryption, Btrfs filesystem, NVIDIA drivers  
**Scope:** Production-ready hibernation implementation for TICKET-020

---

## Executive Summary

Hibernation with swapfiles on Btrfs in Arch Linux is **technically feasible but complex**, with several critical gotchas that must be handled correctly. Success requires:

1. **Proper Btrfs subvolume architecture** (top-level `@swapfile`)
2. **Correct COW disabling** with specific attribute settings
3. **Btrfs-specific offset calculation** (NOT using `filefrag`)
4. **NVIDIA-specific configurations** for 2024 drivers
5. **Careful kernel parameter management** for encrypted systems

**Risk Assessment:** Medium-High complexity with several failure modes reported in real-world usage.

---

## Architecture Overview

### Recommended Btrfs Subvolume Structure
```
/dev/sda2 (btrfs root, encrypted with LUKS)
├── @ (root filesystem)           → /
├── @home (user data)             → /home
├── @swapfile (swap data)         → /swap
└── @snapshots (backup data)      → /.snapshots
```

**Critical Decision:** Top-level `@swapfile` subvolume prevents inclusion in system snapshots and provides clean separation.

---

## Implementation Guide

### 1. Btrfs Swapfile Creation (Modern Method - Kernel 6.1+)

**Important:** The `/mnt` paths shown below are for **installation time only**. In the final system, the swapfile will be located at `/swap/swapfile` in the root filesystem.

```bash
# INSTALLATION TIME: Create top-level swapfile subvolume
btrfs subvolume create /mnt/@swapfile

# INSTALLATION TIME: Mount the swapfile subvolume (temporary)
mkdir -p /mnt/swap
mount -o subvol=@swapfile /dev/mapper/cryptroot /mnt/swap

# Disable COW for the entire subvolume (CRITICAL)
chattr +C /mnt/swap

# Create swapfile using modern Btrfs command (preferred method)
btrfs filesystem mkswapfile --size $(free -h | awk 'NR==2{print $2}') /mnt/swap/swapfile

# Alternative manual method (if modern command unavailable)
# truncate -s 0 /mnt/swap/swapfile
# chattr +C /mnt/swap/swapfile
# btrfs property set /mnt/swap/swapfile compression none
# fallocate -l $(free -b | awk 'NR==2{print $2}') /mnt/swap/swapfile
# chmod 600 /mnt/swap/swapfile
# mkswap /mnt/swap/swapfile

# Activate swapfile
swapon /mnt/swap/swapfile
```

**PRODUCTION SYSTEM:** After installation and reboot, the swapfile will be accessible at `/swap/swapfile`:

```bash
# Final system directory structure:
# / (@ subvolume)
# ├── home/     (@home subvolume mounted here) 
# ├── swap/     (@swapfile subvolume mounted here)
# └── other system directories...

# Production swapfile location: /swap/swapfile
# Production mount point: /swap (not /mnt/swap)
```

### 2. Resume Offset Calculation (CRITICAL - Btrfs Specific)

```bash
# NEVER use filefrag with Btrfs - it gives incorrect offsets!
# Use Btrfs-specific command instead:
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r /swap/swapfile)
echo "Resume offset: $RESUME_OFFSET"

# For older systems (pre-6.1), compile and use btrfs_map_physical.c
# Available at: https://github.com/osandov/osandov-linux/blob/master/scripts/btrfs_map_physical.c
```

### 3. Kernel Configuration

**PinArchy System Configuration:** The system uses a modern systemd-based hook configuration in `/etc/mkinitcpio.conf.d/pinarchy_hooks.conf`:

```bash
# Current PinArchy hooks (systemd-based)
HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole consolefont block sd-encrypt filesystems fsck btrfs-overlayfs)

# For hibernation, add 'resume' hook after 'filesystems':
HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole consolefont block sd-encrypt filesystems resume fsck btrfs-overlayfs)
```

**Important:** 
- PinArchy uses **systemd hooks** (`sd-encrypt` vs `encrypt`) and **plymouth** for boot splash
- The `resume` hook must come AFTER `filesystems` and `sd-encrypt`
- System uses **limine bootloader** (not GRUB) with FIDO2 auto-unlock
- Configuration goes in `/etc/mkinitcpio.conf.d/` not `/etc/mkinitcpio.conf`

**Alternative Classic Configuration (for reference):**
```bash
# Traditional non-systemd hooks
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems resume fsck)
```

### 4. Bootloader Configuration

**PinArchy System (Limine Bootloader):** The system uses limine bootloader with automatic FIDO2 unlock configured in `/etc/default/limine`:

```bash
# Get device UUID and resume offset
DEVICE_UUID=$(blkid -s UUID -o value /dev/sda2)  # encrypted device UUID
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r /swap/swapfile)

# Edit /etc/default/limine - add resume parameters to KERNEL_CMDLINE entries
CMDLINE_DEFAULT="quiet splash rd.luks.name=${LUKS_UUID}=root rd.luks.options=fido2-device=auto root=/dev/mapper/root rootflags=subvol=${ROOT_SUBVOL} rw rootfstype=${ROOT_FSTYPE} resume=/dev/mapper/root resume_offset=$RESUME_OFFSET"

# Apply configuration
sudo limine-update
```

**Alternative GRUB Configuration (for reference):**
```bash
# Traditional GRUB setup (if using GRUB instead)
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=$DEVICE_UUID:cryptroot root=/dev/mapper/cryptroot resume=/dev/mapper/cryptroot resume_offset=$RESUME_OFFSET"
grub-mkconfig -o /boot/grub/grub.cfg
```

### 5. fstab Configuration

```bash
# Add swapfile subvolume to /etc/fstab
UUID=$DEVICE_UUID /swap btrfs subvol=@swapfile,defaults,noatime 0 0

# Add swapfile
/swap/swapfile none swap defaults 0 0
```

---

## NVIDIA-Specific Configurations (2024)

### Critical NVIDIA Services
```bash
# Enable required systemd services (often disabled by default)
systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service

# For suspend-then-hibernate users
systemctl enable nvidia-suspend-then-hibernate.service
```

### NVIDIA Driver Parameters (2024 Issues)
```bash
# Create/edit /etc/modprobe.d/nvidia.conf
# Disable GSP firmware (major 2024 hibernation issue with driver 555+)
options nvidia NVreg_EnableGpuFirmware=0

# Video memory preservation (default in Arch but ensure it's set)
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# Temporary file path (NOT /tmp - survives reboot)
options nvidia NVreg_TemporaryFilePath=/var/tmp
```

### Early KMS Considerations

**PinArchy NVIDIA Configuration Conflict:** The system automatically adds NVIDIA modules to initramfs in `/install/config/hardware/nvidia.sh`:

```bash
# Current PinArchy NVIDIA setup (line 62-70 in nvidia.sh)
NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
# These get added to MODULES array in /etc/mkinitcpio.conf
```

**For Hibernation Compatibility:** The NVIDIA hibernation research indicates these modules should NOT be in initramfs, but PinArchy adds them by default. **This creates a conflict that needs resolution.**

```bash
# Hibernation-compatible approach (conflicts with current setup)
# Remove nvidia modules from initramfs MODULES array
# Keep 'kms' hook but don't load nvidia modules early

# Alternative: Test if hibernation works with early KMS
# Some newer drivers may handle this better
```

**Recommendation:** The current `nvidia.sh` script needs hibernation-specific enhancements:
- Add hibernation-required modprobe options to `/etc/modprobe.d/nvidia.conf`
- Add conditional logic to skip early module loading when hibernation is enabled
- Enable NVIDIA hibernation systemd services

---

## PinArchy System Integration

### Current System Architecture
- **Bootloader:** Limine with FIDO2 auto-unlock
- **Encryption:** LUKS with systemd hooks (`sd-encrypt`)  
- **Boot Process:** Plymouth splash screen + systemd boot
- **NVIDIA:** Early KMS loading enabled by default
- **Power Management:** Power button ignored (configured for power menu)

### Integration Requirements for Hibernation
1. **Modify NVIDIA Configuration:** Skip early module loading when hibernation enabled
2. **Update Limine Configuration:** Add resume parameters to kernel command line  
3. **Handle Plymouth Compatibility:** Ensure splash screen works with hibernation resume
4. **FIDO2 Integration:** Hibernation must work with FIDO2 unlock process
5. **Systemd Service Management:** Enable NVIDIA hibernation services properly

### Implementation Priority for PinArchy
- **High:** Resolve NVIDIA early KMS vs hibernation conflict
- **High:** Integrate with existing limine bootloader setup
- **Medium:** Ensure FIDO2 unlock works post-hibernation resume
- **Low:** Plymouth compatibility testing

---

## Known Issues and Mitigation Strategies

### Issue 1: SystemD vs Manual Hibernation
**Problem:** SystemD hibernate may fail while manual hibernation works  
**Cause:** SystemD ignores kernel parameters and calculates offset incorrectly  
**Mitigation:** Test both methods; may need manual hibernation scripts

```bash
# Manual hibernation test
echo disk > /sys/power/state

# If this works but systemctl hibernate doesn't, implement custom hibernate script
```

### Issue 2: Resume Failures After Long Sessions  
**Problem:** Intermittent resume failures, especially after extended work  
**Cause:** Video memory corruption or insufficient temporary space  
**Mitigation:** 
- Ensure `/var/tmp` has sufficient space (>= GPU memory)
- Regular hibernation testing during long sessions

### Issue 3: Btrfs Snapshot Conflicts
**Problem:** Cannot snapshot subvolumes with active swapfiles  
**Cause:** Btrfs limitation with active swap  
**Mitigation:** 
- Use dedicated `@swapfile` subvolume (excluded from snapshots)
- Deactivate swap before snapshots if needed: `swapoff /swap/swapfile`

### Issue 4: Driver Version Compatibility
**Problem:** Hibernation broken with certain driver/kernel combinations  
**Latest Working:** NVIDIA 565.57.01+ with Linux 6.12+  
**Mitigation:** Monitor driver updates, test hibernation after updates

---

## Testing and Validation

### Hibernation Test Sequence
```bash
# 1. Basic functionality test
echo disk > /sys/power/state

# 2. SystemD hibernation test
systemctl hibernate

# 3. Suspend-then-hibernate test (if used)
systemctl suspend-then-hibernate

# 4. Load test - hibernation under memory pressure
stress --vm-bytes $(awk '/MemAvailable/{printf "%d\n", $2 * 0.9;}' < /proc/meminfo)k --vm-keep -m 1 &
sleep 5
echo disk > /sys/power/state
killall stress
```

### Validation Checklist
- [ ] Swapfile created with correct size (= RAM)
- [ ] COW disabled (`lsattr -d /swap` shows `C` attribute)
- [ ] Resume offset calculated with Btrfs-specific tools
- [ ] NVIDIA services enabled and configured
- [ ] Kernel parameters correct in GRUB
- [ ] mkinitcpio HOOKS in correct order
- [ ] Hibernation works under normal conditions
- [ ] Hibernation works under memory pressure
- [ ] Resume works after hibernation
- [ ] Video functionality intact after resume

---

## Alternative Approaches

### If Btrfs Hibernation Proves Problematic
Based on real-world reports, some users ultimately switched away from Btrfs for hibernation:

> "I never found the culprit and gave up on using Btrfs. I stuck with LVM on LUKS and ext4, no issue."

**Alternative Stack:** LVM on LUKS with ext4
- More reliable hibernation support
- Simpler offset calculation (uses `filefrag`)
- No COW complications
- Better SystemD integration

### Hybrid Approach
- Use ext4 for root filesystem (better hibernation support)
- Use Btrfs for `/home` (advanced features where hibernation not needed)

---

## Implementation Priority and Risk Assessment

### High Priority (Must Implement)
1. **Proper subvolume structure** - Foundation for everything else
2. **COW disabling** - Fundamental requirement for swapfiles
3. **Btrfs-specific offset calculation** - Standard tools will fail
4. **NVIDIA service configuration** - Required for modern drivers

### Medium Priority (Important for Stability)  
1. **Kernel parameter validation** - Critical for resume
2. **Temporary file path configuration** - Prevents resume failures
3. **Early KMS handling** - May be required for NVIDIA hibernation

### Low Priority (Nice to Have)
1. **Automated testing scripts** - Helpful for validation
2. **Fallback mechanisms** - Recovery if hibernation fails

### Risk Factors
- **High:** Btrfs + NVIDIA + hibernation is a complex combination
- **Medium:** Limited real-world success reports for this exact stack
- **Low:** Well-documented individual components

---

## Recommendations for TICKET-020

### Phase 1: Research Implementation (Completed ✓)
This research document provides comprehensive foundation.

### Phase 2: Basic Implementation
1. Implement swapfile creation with proper COW disabling
2. Add Btrfs-specific offset calculation
3. Configure kernel parameters and GRUB

### Phase 3: NVIDIA Integration  
1. Add NVIDIA-specific service management
2. Configure driver parameters for hibernation
3. Handle early KMS conflicts

### Phase 4: Validation and Testing
1. Implement automated testing suite
2. Add error handling and recovery mechanisms
3. Document troubleshooting procedures

### Recommended User Question
Add to QnA: *"Hibernation on Btrfs with NVIDIA can be complex. Use simpler ext4 setup instead? (y/N)"*

This provides users an escape hatch to a more reliable configuration if they prefer stability over advanced Btrfs features.

---

## Conclusion

Hibernation with swapfiles in Btrfs subvolumes is **achievable but requires careful implementation** of multiple interdependent components. The combination of Btrfs, LUKS encryption, and NVIDIA drivers creates a complex system with several potential failure modes.

**Success Factors:**
- Meticulous attention to Btrfs-specific requirements
- Proper NVIDIA driver configuration for 2024 hardware
- Thorough testing and validation procedures
- Fallback options for users who prefer stability

**Implementation should proceed cautiously** with extensive testing and clear documentation of limitations and alternatives.