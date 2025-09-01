# TICKET-020: Hibernation with Swapfile in Subvolume

## User Request
hibernation with swapfile in a subvolume

## Q&A
**Q: Current setup - Do you currently have a swapfile, or should this ticket include creating one?**
A: create subvolume than swapfile

**Q: Subvolume specifics - Should the swapfile be in the root subvolume (@) or a dedicated subvolume (like @swap)?**
A: research this later

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
- [ ] Research completed on Btrfs swapfile best practices
- [ ] Research completed on CoW implications and solutions  
- [ ] Btrfs subvolume created for swapfile
- [ ] Swapfile created with size equal to system RAM
- [ ] Kernel parameters configured for hibernation
- [ ] Hibernation works with existing FIDO2/LUKS setup
- [ ] System successfully hibernates and resumes
- [ ] Documentation added explaining the implementation

## Priority
Medium

## Status
Todo

## Preparation
[Placeholder. Leave empty.]

## Architecture
[Placeholder. Leave empty.]

## TODOWrite
[Placeholder. Leave empty.]