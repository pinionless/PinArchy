# TICKET-021: Limine Snapper Pacman Hook for vmlinuz Movement

## User Request
HIGH in the limane-snapper.sh add pacman hook that will move vmlinuz.
NO QUESTIONS. quick ADD

## Q&A
No clarifying questions requested - quick addition requested.

## Description
Add a pacman hook to the limine-snapper.sh script that will automatically move the vmlinuz kernel image when kernel packages are updated. This ensures the bootloader can find the correct kernel location after system updates.

## Acceptance Criteria
- [ ] Pacman hook added to limine-snapper.sh script
- [ ] Hook triggers on kernel package updates
- [ ] vmlinuz is moved to correct location for Limine bootloader
- [ ] Hook is properly integrated with existing snapper snapshot workflow

## Priority
High

## Status
Done

## Preparation
[Placeholder. Leave empty.]

## Architecture
[Placeholder. Leave empty.]

## TODOWrite
[Placeholder. Leave empty.]