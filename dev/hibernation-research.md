# NVIDIA Hibernation Configuration - Research Document

**Research Date:** September 2025  
**Target System:** Arch Linux with LUKS encryption, Btrfs filesystem, NVIDIA drivers  
**Scope:** NVIDIA-specific hibernation configurations and compatibility

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

## NVIDIA-Specific Known Issues and Mitigation Strategies

### Issue 1: Resume Failures After Long Sessions  
**Problem:** Intermittent resume failures, especially after extended work  
**Cause:** Video memory corruption or insufficient temporary space  
**Mitigation:** 
- Ensure `/var/tmp` has sufficient space (>= GPU memory)
- Regular hibernation testing during long sessions

### Issue 2: Driver Version Compatibility
**Problem:** Hibernation broken with certain driver/kernel combinations  
**Latest Working:** NVIDIA 565.57.01+ with Linux 6.12+  
**Mitigation:** Monitor driver updates, test hibernation after updates

### Issue 3: SystemD vs Manual Hibernation with NVIDIA
**Problem:** SystemD hibernate may fail while manual hibernation works with NVIDIA systems
**Cause:** SystemD service conflicts with NVIDIA hibernation services
**Mitigation:** 
- Test both methods; may need manual hibernation scripts for NVIDIA
- Ensure proper service ordering

---

## NVIDIA Hibernation Testing and Validation

### NVIDIA-Specific Test Sequence
```bash
# 1. Basic functionality test
echo disk > /sys/power/state

# 2. SystemD hibernation test
systemctl hibernate

# 3. Suspend-then-hibernate test (if used)
systemctl suspend-then-hibernate

# 4. Load test - hibernation under GPU memory pressure
# Run GPU-intensive application, then hibernate
nvidia-smi  # Check GPU memory usage
echo disk > /sys/power/state

# 5. Extended session test
# Long work session with GPU usage, then hibernation
```

### NVIDIA Validation Checklist
- [ ] NVIDIA hibernation services enabled and configured
- [ ] Driver parameters correctly applied in modprobe
- [ ] Early KMS handling appropriate for hibernation
- [ ] Video functionality intact after resume
- [ ] GPU applications work correctly after resume
- [ ] No video memory corruption issues
- [ ] Hibernation works under GPU load
- [ ] Compatible with current driver versions
- [ ] FIDO2 unlock works post-hibernation resume
- [ ] Plymouth splash screen works with hibernation resume

---

## Risk Assessment and Alternatives

### Complexity Warning
- **High:** Btrfs + NVIDIA + hibernation is a complex combination
- **Medium:** Limited real-world success reports for this exact stack
- **Low:** Well-documented individual NVIDIA hibernation components

### Alternative Approaches for NVIDIA Systems

#### If NVIDIA Hibernation Proves Problematic
Based on real-world reports, some NVIDIA users ultimately switched configurations:

**Alternative Stack for Reliability:** 
- Use ext4 for root filesystem (better hibernation support)
- Use Btrfs for `/home` (advanced features where hibernation not needed)
- Simpler NVIDIA hibernation without Btrfs complications

#### Recommended User Question
Add to QnA: *"Hibernation on Btrfs with NVIDIA can be complex. Use simpler ext4 setup instead? (y/N)"*

This provides users an escape hatch to a more reliable configuration if they prefer stability over advanced Btrfs features for NVIDIA systems.

---

## Implementation Recommendations for NVIDIA

### High Priority NVIDIA Requirements
1. **NVIDIA service configuration** - Required for modern drivers
2. **Driver parameter validation** - Critical for resume functionality  
3. **Early KMS handling** - May be required for NVIDIA hibernation compatibility

### Integration Strategy
1. **Modify nvidia.sh script** to add hibernation-specific configurations
2. **Add conditional logic** to handle hibernation vs standard NVIDIA setup
3. **Implement NVIDIA hibernation service management**
4. **Create NVIDIA-specific hibernation testing procedures**

---

## Conclusion

NVIDIA hibernation support requires careful implementation of multiple interdependent components. The combination of Btrfs, LUKS encryption, and NVIDIA drivers creates a complex system with several potential failure modes.

**Success Factors for NVIDIA:**
- Meticulous attention to NVIDIA-specific hibernation requirements
- Proper driver configuration for 2024 hardware
- Resolution of early KMS vs hibernation conflicts
- Thorough testing and validation procedures
- Fallback options for users who prefer stability

**NVIDIA hibernation implementation should proceed cautiously** with extensive testing and clear documentation of limitations and alternatives.