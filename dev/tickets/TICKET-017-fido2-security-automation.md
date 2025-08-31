# TICKET-017: FIDO2 Security Automation

## User Request
menu option security that will start a bash script in terminal. That script pinarchy-security-fido2 will give the user an option to toggle auto-logout when fido2 key is disconnected from the computer. 
second toggle will give user ability to auto-shutdown when key is removed. shutdown should be configurable - immidiate or wait for key to reconnect (with ability to set time).
if shutdown is selected there should be "forced"/"fast" option. and "normal" option

## Q&A
**Menu Integration:**
- Q: Should this be added to existing omarchy-menu system, or create new standalone security menu?
- A: yes
- Q: Should the security menu option be accessible from main Omarchy menu, or as separate entry point?
- A: omarchy-menu. Under "setup" i think

**Auto-logout Feature:**
- Q: When you say "auto-logout", do you mean log out of current user session, lock screen (hyprlock), or end specific applications?
- A: LOCK THE SCREEN
- Q: Should there be grace period before logout (30 seconds warning), or immediate logout?
- A: LET THE USER CONFIG THIS

**Auto-shutdown Configuration:**
- Q: For "wait for key to reconnect" option - default wait time, acceptable range, show countdown during wait?
- A: 1-5minutes. quiet
- Q: For shutdown types - "Forced/fast" = immediate shutdown, "Normal" = 1 minute delay with notifications?
- A: is there FORCED option? to make all apps quit immidetly - normal can wait for apps to shutdown normally

**Detection & Persistence:**
- Q: How should FIDO2 key detection work - polling, udev rules, integration with fido2-token commands?
- A: UDEV
- Q: Should settings be per-user config files, system-wide settings, stored where?
- A: /etc/fido2/security

## Description
Create an automated FIDO2 security system that monitors hardware key presence and triggers configurable security actions when the key is disconnected. This enhances physical security by ensuring the system locks or shuts down when the user steps away without their hardware key.

Key components:
- Add "Security" option to omarchy-menu under "Setup" section
- Create `pinarchy-security-fido2` configuration script with toggle options
- Implement udev-based FIDO2 key detection daemon
- Support configurable screen lock with user-defined grace periods  
- Support configurable shutdown with reconnection wait times (1-5 minutes)
- Provide "forced" (immediate app termination) and "normal" (graceful shutdown) options
- Store configuration in `/etc/fido2/security` directory

## Acceptance Criteria
- [ ] "Security" menu option added to omarchy-menu under "Setup"
- [ ] `pinarchy-security-fido2` script created with toggle interface
- [ ] Auto-lock toggle with configurable grace period (0-60 seconds)
- [ ] Auto-shutdown toggle with immediate/wait-for-reconnect options
- [ ] Reconnection wait time configurable (1-5 minutes, silent operation)
- [ ] Shutdown method selection: "forced" vs "normal"
- [ ] Udev rules implemented for real-time FIDO2 key detection
- [ ] Background daemon monitors key presence and executes actions
- [ ] Configuration persistence in `/etc/fido2/security/` directory
- [ ] Proper error handling and logging for security actions
- [ ] Integration testing with existing FIDO2 setup from TICKET-002

## Priority
Medium

## Status
Todo

## Preparation

## Architecture

## Implementation Notes
This builds upon the FIDO2 infrastructure from TICKET-002, extending it with automated security monitoring and response capabilities.