# TICKET-020: Hibernation with Swapfile in Subvolume

## User Request
hibernation with swapfile in a subvolume

## Q&A
**Q: Current setup - Do you currently have a swapfile, or should this ticket include creating one?**
A: create subvolume than swapfile

**Q: Subvolume specifics - Should the swapfile be in the root subvolume (@) or a dedicated subvolume (like @swap)?**
A: Create top-level @swapfile subvolume (next to @root/@home, not nested inside them)

**Q: Hibernation scope - Are you looking for just the swapfile setup for hibernation, full hibernation configuration including kernel parameters, or integration with your existing FIDO2/LUKS setup?**
A: full hibernation research and implementation

**Q: Size requirements - Any specific swapfile size, or should it auto-detect based on RAM?**
A: =RAM

**Q: Btrfs considerations - Should this handle the special Btrfs requirements (like disabling CoW for the swapfile)?**
A: I dont know what CoW is, research later

## Description
Implement complete hibernation functionality using a swapfile located within a Btrfs subvolume. This includes:

1. **Research Phase**: 
   - Investigate optimal Btrfs subvolume structure for swapfiles
   - Research Btrfs Copy-on-Write (CoW) implications for swapfiles
   - Determine best practices for hibernation on encrypted Btrfs systems

2. **Implementation Phase**:
   - Create appropriate Btrfs subvolume for swap
   - Create swapfile sized equal to RAM
   - Configure kernel parameters for hibernation
   - Handle Btrfs-specific swapfile requirements
   - Integration with existing FIDO2/LUKS encryption setup
   - Test hibernation/resume functionality

## Acceptance Criteria
- [x] Research completed on Btrfs swapfile best practices
- [x] Research completed on CoW implications and solutions  
- [x] Btrfs subvolume created for swapfile
- [x] Swapfile created with size equal to system RAM
- [x] Kernel parameters configured for hibernation
- [x] Hibernation works with existing FIDO2/LUKS setup
- [x] System successfully hibernates and resumes
- [x] Documentation added explaining the implementation

## Implementation Status
**COMPLETED** ✅ - Hibernation implementation completed in 3 phases:

### Phase 1: Research & Planning
- Comprehensive hibernation research documented in `dev/hibernation-research.md`
- Identified Btrfs-specific requirements and NVIDIA compatibility issues
- Documented PinArchy system integration requirements

### Phase 2: Core Implementation  
- Created `install/system/hibernation.sh` script with 3-step implementation:
  1. **Step 1**: Btrfs swapfile creation with proper top-level `@swapfile` subvolume
  2. **Step 2**: Kernel configuration (mkinitcpio hooks with `resume` hook)
  3. **Step 3**: Bootloader configuration (Limine) with resume parameters
- Added hibernation script to `install.sh` execution pipeline
- Created migration `1757155150.sh` for existing users

### Phase 3: Integration & Testing
- Integrated with existing FIDO2/LUKS encryption system
- Fixed resume parameter format matching for encrypted/non-encrypted systems
- Tested hibernation and boot functionality successfully
- Dynamic root device detection from limine config

## Key Features Implemented
- **Smart Subvolume Creation**: Top-level `@swapfile` subvolume to avoid snapshot conflicts
- **COW Handling**: Proper Copy-on-Write disabling using `chattr +C`
- **Btrfs-Specific Tools**: Uses `btrfs inspect-internal map-swapfile` for correct offset calculation
- **LUKS Integration**: Works with both encrypted and non-encrypted root devices
- **Limine Integration**: Automatic resume parameter injection into bootloader config
- **Error Handling**: Comprehensive validation and graceful error handling

## Priority
~~Medium~~ **COMPLETED**

## Notes
NVIDIA-specific hibernation features extracted to [TICKET-025](./TICKET-025-nvidia-hibernation-support.md) for future implementation.

## Status
Todo

## Preparation
[Placeholder. Leave empty.]

## Architecture
[Placeholder. Leave empty.]

## TODOWrite
[Placeholder. Leave empty.]