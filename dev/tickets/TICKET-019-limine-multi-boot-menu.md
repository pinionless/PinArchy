# TICKET-019: Limine Multi-Boot Menu Integration

## User Request
Reboot to windows or Reboot to X where "next boot" is set in limine and system restarts

## Q&A
**Q1: Platform scope - Windows only or generic for any bootable entry?**
A: Load limine config, provide option to boot to each of the systems

**Q2: Integration method - command-line, menu, or both?**
A: in omarchy menu

**Q3: Limine interaction - immediate reboot or set for next manual reboot?**
A: I dont think limine suports "next boot", we might have to set "default boot"

**Q4: Entry detection - how to identify available boot entries?**
A: from limine.cfg

**Q5: Error handling approach?**
A: (dismissed as obvious)

## Description
Implement multi-boot functionality within the omarchy menu system that:
- Parses `/boot/limine.cfg` to discover available boot entries
- Presents a menu of all detected bootable systems
- Sets the selected entry as the default boot option in Limine configuration
- Initiates system reboot to the chosen operating system

Since Limine doesn't support "next boot only" functionality, the implementation will modify the default boot entry and reboot immediately.

## Acceptance Criteria
- [ ] Parse `/boot/limine.cfg` to extract all bootable entries
- [ ] Add "Reboot to..." submenu in `omarchy-menu`
- [ ] Display list of detected boot entries (Windows, other Linux distros, etc.)
- [ ] Modify Limine configuration to set selected entry as default
- [ ] Initiate system reboot after configuration change
- [ ] Handle cases where limine.cfg is not found or malformed
- [ ] Restore previous default after successful boot (optional enhancement)

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