# TICKET-018: TV Management for LG TVs

## User Request
TV managment. For users of TVs (not monitors) add management that will auto turn on/off the TV. For now using bscpylgtvcommand for LG TVs

## Q&A
**TV Management Integration:**
- Q: Should this be integrated into existing omarchy-menu system, or be standalone utility?
- A: yes, add in menu under setup or somewhere
- Q: Where should TV management option be placed in menu structure?
- A: idk, setup menu seams fine, we should check if its best

**Auto Power Management:**
- Q: What should trigger TV auto turn-on?
- A: boot/wake
- Q: What should trigger TV auto turn-off?
- A: system shutdown and sleep

**LG TV Configuration:**
- Q: How should users configure their LG TV connection (IP discovery, MAC address, authentication)?
- A: IDK, we check what that lib needs to work later
- Q: Should there be support for multiple TVs, or single TV per system?
- A: 1 for now

**Installation & Dependencies:**
- Q: Should bscpylgtvcommand be installed automatically, via personal.sh, or user responsibility?
- A: yes, installed during setup
- Q: How should TV management settings be stored?
- A: per system /etc/something

**Future Expansion:**
- Q: Should architecture support other TV brands later, or focus only on LG for now?
- A: LG for now

## Description
Create automated TV power management for LG TVs using the `bscpylgtvcommand` library. This feature allows users with LG TVs (instead of monitors) to have their TV automatically turn on when the system boots/wakes and turn off when the system shuts down or goes to sleep.

Key components:
- Add TV management option to omarchy-menu (likely under "Setup", but verify best placement)
- Install `bscpylgtvcommand` dependency during system setup
- Create TV configuration script for LG TV connection setup
- Implement systemd services for boot/wake TV turn-on
- Implement systemd services for shutdown/sleep TV turn-off
- Store configuration in `/etc/tv/` or similar system directory
- Support single TV per system initially
- Research and implement LG TV connection requirements (IP, authentication, etc.)

## Acceptance Criteria
- [x] `bscpylgtvcommand` installed automatically during setup
- [x] TV management option added to omarchy-menu (under setup menu)
- [x] TV configuration script created for LG TV setup (`pinarchy-lgtv-setup`)
- [x] System configuration stored in `~/.config/lgtv/config.json` (JSON format)
- [x] TV automatically turns on during system boot/wake (systemd integration)
- [x] TV automatically turns off during system shutdown/sleep (systemd integration)
- [x] Multiple LG TV support implemented (improved from single TV requirement)
- [x] Connection requirements implemented (IP, MAC address, WebOS authentication)
- [x] Error handling for TV communication failures
- [x] TV app installation and removal system (`pinarchy-install-tvapp`, `pinarchy-remove-tvapp`)
- [x] Waybar integration for volume and brightness controls
- [x] Wake-on-LAN support for TV power management

## Priority
Low

## Status
Done

## Preparation

## Architecture

## Implementation Notes
Focus on LG TV support only for initial implementation. Architecture should be clean enough to potentially add other brands later, but LG-specific implementation is acceptable for now.