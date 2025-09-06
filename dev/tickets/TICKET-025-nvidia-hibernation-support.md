# TICKET-025: NVIDIA Hibernation Support

## Description
Add NVIDIA-specific hibernation support and configurations to complement the basic hibernation functionality implemented in TICKET-020. This focuses on resolving NVIDIA driver conflicts with hibernation and implementing proper NVIDIA hibernation services.

## Background
The hibernation research from TICKET-020 identified significant NVIDIA-specific requirements and conflicts (see detailed research in [`dev/hibernation-research.md`](../hibernation-research.md)):
- NVIDIA hibernation services are disabled by default
- Modern NVIDIA drivers (555+) have GSP firmware hibernation issues
- Early KMS loading in initramfs conflicts with hibernation
- Video memory preservation requires specific configurations
- Driver version compatibility affects hibernation reliability

## Scope
This ticket addresses NVIDIA-specific hibernation enhancements only. Basic hibernation functionality (swapfile, kernel params, bootloader config) is already implemented in TICKET-020.

## Requirements

### 1. NVIDIA Hibernation Services
- Enable NVIDIA hibernation systemd services when hibernation is detected
- Configure services for suspend, hibernate, resume, and suspend-then-hibernate

### 2. Driver Configuration  
- Configure NVIDIA driver parameters for hibernation compatibility
- Add modprobe options to `/etc/modprobe.d/nvidia.conf`
- Handle 2024 driver-specific issues (GSP firmware, video memory preservation)

### 3. Early KMS Conflict Resolution
- Resolve conflict between PinArchy's default early NVIDIA module loading and hibernation requirements
- Implement conditional logic or configuration options for hibernation users

### 4. System Integration
- Ensure FIDO2 compatibility with hibernation resume
- Test Plymouth splash screen integration  
- Integrate with existing power management configuration

## Implementation Strategy

### Phase 1: NVIDIA Services & Parameters
- Modify `install/system/hibernation.sh` to add NVIDIA-specific configurations
- Add hibernation-required modprobe options
- Enable NVIDIA hibernation systemd services when hibernation is detected

### Phase 2: Early KMS Conflict Resolution
- Add hibernation detection logic to `install/system/hibernation.sh`
- Implement conditional early module loading
- Test hibernation with and without early KMS

## Acceptance Criteria
- [ ] NVIDIA hibernation services automatically enabled when hibernation + NVIDIA detected
- [ ] Required NVIDIA modprobe options configured in `/etc/modprobe.d/nvidia.conf`
- [ ] Early KMS conflict resolved (conditional logic or configuration option)
- [ ] Video functionality intact after hibernation resume
- [ ] Integration tested with FIDO2 unlock process

## Known Issues to Address

### Issue 1: Driver Version Compatibility
**Problem**: Hibernation broken with certain driver/kernel combinations  
**Latest Working**: NVIDIA 565.57.01+ with Linux 6.12+  
**Solution**: Add driver version detection and warnings

### Issue 2: Video Memory Space Requirements
**Problem**: Resume failures due to insufficient temporary space  
**Solution**: Ensure `/var/tmp` has space >= GPU memory, add validation

### Issue 3: SystemD vs Manual Hibernation
**Problem**: SystemD hibernate may fail while manual hibernation works  
**Solution**: Provide fallback manual hibernation scripts for NVIDIA systems

## Testing Requirements

### Hibernation Test Sequence for NVIDIA
```bash
# 1. Basic functionality test
echo disk > /sys/power/state

# 2. SystemD hibernation test  
systemctl hibernate

# 3. Load test - hibernation under GPU load
# Run GPU-intensive task, then hibernate

# 4. Extended session test
# Long work session, then hibernation
```

### Validation Checklist
- [ ] NVIDIA services enabled and running
- [ ] Modprobe options correctly applied
- [ ] Early KMS handling appropriate for hibernation
- [ ] Video output functional after resume
- [ ] GPU applications work after resume
- [ ] No video memory corruption issues
- [ ] Hibernation works under GPU load
- [ ] Compatible with current driver versions

## Priority
Medium

## Dependencies
- TICKET-020 (Hibernation with Swapfile) - **COMPLETED**
- Existing NVIDIA configuration in `install/config/hardware/nvidia.sh`

## Notes
This ticket focuses exclusively on NVIDIA-specific hibernation enhancements. The basic hibernation functionality (Btrfs swapfile, kernel parameters, bootloader configuration) is already implemented and working from TICKET-020.

The main challenge is resolving the early KMS loading conflict while maintaining compatibility with existing NVIDIA setups that rely on early module loading for proper boot behavior.

## Research Reference
Comprehensive NVIDIA hibernation research and technical details are documented in [`dev/hibernation-research.md`](../hibernation-research.md), including:
- Detailed NVIDIA service configuration requirements
- Driver parameter explanations and 2024-specific issues
- PinArchy system integration conflicts and solutions
- NVIDIA-specific testing procedures and validation checklists
- Risk assessment and alternative approaches for NVIDIA systems

## Status
Todo