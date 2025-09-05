# TICKET-024: Fix FIDO2 Setup - Skip PIN/Touch Prompts for Security Component Only

## User Request
fix fido2-setup - dont ask pin/touch if only setting up the security component

## Q&A
**Q: Scope clarification - Are you referring to the `pinarchy-setup-fido2` script where it asks for PIN/touch even when the user only selects the "security" component (for device monitoring)?**
A: yes

**Q: Expected behavior - When setting up only the security component, should the script skip all PIN/touch prompts entirely, or just skip specific prompts while still detecting the device?**
A: skip the pin/touch question when adding only the security key

**Q: Current problem details - Does this happen during device registration for security monitoring, or during the initial FIDO2 key detection phase?**
A: during add key in setup-fido2 script when only security is selected

**Q: Related components - Should this fix also apply to the security configuration in `pinarchy-security-fido2`, or just the main setup script?**
A: not relevant

## Description
The `pinarchy-setup-fido2` script currently prompts for PIN/touch when adding FIDO2 keys, even when the user only selects the "security" component. Since security monitoring only needs device identification (vendor:product ID) and doesn't require FIDO2 authentication operations, these prompts are unnecessary and create poor user experience.

The fix should modify the add key functionality to skip PIN/touch prompts when only the security component is selected, while maintaining normal PIN/touch prompts for other components (sudo, login, polkit, luks) that require actual FIDO2 authentication.

## Acceptance Criteria
- [ ] PIN/touch prompts skipped when only "security" component selected
- [ ] Normal PIN/touch prompts maintained for other components
- [ ] Security key registration still works correctly without PIN/touch
- [ ] No regression in other FIDO2 setup functionality

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