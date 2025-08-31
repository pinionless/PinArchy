# TICKET-002: YubiKey Authentication System

## User Request
Integrate YubiKey hardware authentication into Omarchy system for enhanced security

## Q&A
**YubiKey Integration Scope:**
- Q: Should YubiKey be required for all sudo operations, or only specific sensitive commands?
- A: If yubikey is inserted I want all sudo to run - no touch
- Q: Should YubiKey be optional or required for Hyprland screen unlock?
- A: we start with password OR yubikey implementation  
- Q: What backup authentication should we configure if YubiKey is lost/unavailable?
- A: EXTRA YUBIKEYS. Each account should be able to add multiple

**Hardware Compatibility:**
- Q: Do you have specific YubiKey models, or should we support all YubiKey 5 series?
- A: I think PAM is suported by many different keys
- Q: Do you want support for multiple YubiKey devices as backups?
- A: YES

**Installation & Integration:**
- Q: Should YubiKey setup be in the main installation flow, or as an optional post-install configuration?
- A: I think there is yubikey config included in the omarchy menus, we should edit/enchance this
- Q: Should this be optional (like personal.sh apps) or mandatory for all Omarchy installations?
- A: we install in personal.sh all extra for easy upstream merge

## Description
Enhance the existing Omarchy YubiKey configuration system with improved multi-device support and seamless authentication integration.

Key requirements:
- Install YubiKey stack via personal.sh for easy upstream merging
- Configure PAM for automatic sudo authentication when YubiKey is inserted (no touch required)
- Implement password OR YubiKey authentication for screen unlock
- Support multiple YubiKey devices per user account for backup
- Enhance existing omarchy menu YubiKey configuration options
- Support broad hardware compatibility via PAM (not just YubiKey 5 series)

## Implementation Details

### Package Installation
Install required YubiKey packages via main installation:
- `yubikey-manager` - YubiKey configuration utility
- `pam-u2f` - PAM module for FIDO U2F authentication
- `libfido2` - FIDO2 library for WebAuthn support
- `yubikey-personalization` - YubiKey personalization tools

### PAM Configuration
Configure PAM modules for secure authentication:
- Modify `/etc/pam.d/sudo` for YubiKey-required admin operations
- Configure `/etc/pam.d/hyprlock` for optional YubiKey screen unlock
- Setup backup authentication mechanisms

### SSH Integration  
- Generate SSH keys stored on YubiKey hardware
- Configure SSH client for YubiKey-based authentication
- Setup SSH agent integration with YubiKey

### Browser Integration
- Install FIDO2 browser extensions and libraries
- Configure Firefox for hardware security key support
- Test WebAuthn functionality with common services

### Bitwarden Integration
- Configure Bitwarden to require YubiKey as second factor
- Setup emergency access codes as backup
- Test vault unlock with hardware authentication

## Acceptance Criteria
- [ ] YubiKey packages installed and configured
- [ ] PAM modules configured for sudo (required) and screen lock (optional)
- [ ] SSH keys generated and stored on YubiKey hardware
- [ ] SSH authentication working with YubiKey
- [ ] Firefox WebAuthn/FIDO2 support enabled and tested
- [ ] Bitwarden second-factor authentication configured
- [ ] Backup authentication methods configured and tested
- [ ] YubiKey presence detection for sensitive file access
- [ ] Documentation for YubiKey setup and usage
- [ ] Emergency recovery procedures documented

## Priority
High

## Status
Done

## Preparation

### Requirements Analysis
- **Hardware Security**: Enhance Omarchy's security posture with hardware-based authentication
- **Multi-factor Authentication**: Implement "something you have" factor alongside passwords
- **SSH Hardening**: Replace/supplement traditional SSH keys with hardware-backed keys
- **Web Security**: Enable hardware security keys for web-based authentication
- **Administrative Security**: Require hardware presence for sensitive system operations

### Integration Points
1. **PAM System**: Modify PAM configuration for various authentication points
2. **SSH Configuration**: Update SSH client/server configuration for hardware keys
3. **Browser Integration**: Configure Firefox and other browsers for FIDO2/WebAuthn
4. **Bitwarden Enhancement**: Add YubiKey as second factor for password manager
5. **Hyprland Integration**: Optional YubiKey unlock for screen lock

### Security Considerations
- Backup authentication methods to prevent lockout
- Emergency recovery procedures
- YubiKey device backup/replacement procedures
- Integration with existing authentication systems
- Graceful fallback for when YubiKey is not available

## Architecture

### Component Design

**1. Package Installation Component**
- Location: `install/development/` or `install/config/` phase
- Function: Install YubiKey software stack
- Packages: yubikey-manager, pam-u2f, libfido2, yubikey-personalization

**2. PAM Configuration Component**
- Location: `config/` directory with installation phase configuration
- Function: Configure PAM modules for various authentication points
- Files: pam.d configurations for sudo, hyprlock, login

**3. SSH Configuration Component** 
- Location: `config/ssh/` directory
- Function: Configure SSH for YubiKey hardware-backed authentication
- Implementation: SSH client configuration, key generation scripts

**4. Browser Integration Component**
- Location: `config/firefox/` or application configuration
- Function: Enable FIDO2/WebAuthn support in browsers
- Implementation: Browser policy configuration, extension installation

**5. Bitwarden Integration Component**
- Location: Extension to existing Bitwarden configuration
- Function: Add YubiKey as second authentication factor
- Implementation: Bitwarden settings configuration during setup

### Implementation Phases

**Phase 1: Core Installation**
1. Install YubiKey software packages
2. Basic YubiKey detection and configuration
3. Generate initial authentication keys

**Phase 2: PAM Integration**
1. Configure sudo authentication with YubiKey requirement
2. Setup optional screen lock authentication
3. Configure backup authentication methods

**Phase 3: SSH Hardening**
1. Generate SSH keys on YubiKey hardware
2. Configure SSH client for hardware authentication
3. Test remote SSH access with YubiKey

**Phase 4: Web Integration**
1. Configure Firefox FIDO2/WebAuthn support
2. Test hardware authentication with common web services
3. Configure Bitwarden second-factor authentication

**Phase 5: Testing & Documentation**
1. Comprehensive testing of all authentication points
2. Document usage procedures and emergency recovery
3. Validate backup authentication methods

## Current Implementation Status

### **✅ COMPLETED COMPONENTS**

### **1. Login-Sudo Authentication - ✅ IMPLEMENTED**
**Status:** Fully functional with modular setup and removal
- **Setup**: `pinarchy-setup-fido2` (login-sudo component)  
- **Removal**: `pinarchy-remove-fido2` (login-sudo component)
- **Features**: 
  - Four security levels: no-touch, touch-required, pin-required, touch-pin-required
  - PAM integration (sudo + polkit GUI admin)
  - Multiple key support with keymap tracking
  - Hostname-based origin/appid configuration

### **2. SSH Hardware Keys - ✅ IMPLEMENTED**
**Status:** Fully functional with ECDSA-SK keys and SSH config management
- **Setup**: `pinarchy-setup-fido2` (ssh component)
- **Removal**: `pinarchy-remove-fido2` (ssh component)
- **Features**:
  - ECDSA-SK key generation with proper FIDO2 options
  - Four security levels: no-touch, touch-required, pin-required, touch-pin-required
  - SSH config management via Include directive (`~/.ssh/fido2_keys`)
  - Keymap tracking in SSH config comments
  - Full filename-based key organization

### **❌ REMAINING COMPONENT**

### **3. LUKS Disk Encryption - ❌ NOT IMPLEMENTED**
**Status:** Major feature requiring significant implementation
- LUKS disk encryption with FIDO2
- `systemd-cryptenroll` integration  
- PIN configuration for boot process
- Boot process integration and testing

### **Summary:**
- **✅ 2/3 components completed** (login-sudo + ssh)
- **❌ 1/3 component remaining** (luks)
- **Architecture established** for consistent component addition
- **Next focus:** LUKS encryption component implementation

## Enhanced Script Structure Requirements

The `omarchy-setup-fido2` script needs to be expanded with **multiple configuration options**:

### **1. Sudo & Login** 
```bash
omarchy-setup-fido2 --auth
# or 
omarchy-setup-fido2 --sudo-login
```
- Current sudo functionality (already works)
- Current polkit functionality (GUI admin operations already work)
- **ADD:** Login PAM configuration (`/etc/pam.d/login`)
- **ADD:** Multiple key support
- **ADD:** Proper origin/appid configuration like current setup

  Enhanced Script Implementation:

  HOSTNAME=$(hostname)

  # Registration
  pamu2fcfg -o pam://$HOSTNAME -i $HOSTNAME > /etc/fido2/fido2

  # PAM configuration
  echo "auth sufficient pam_u2f.so cue origin=pam://$HOSTNAME appid://$HOSTNAME userpresence=0 authfile=/etc/fido2/fido2"

### **2. SSH**
```bash
omarchy-setup-fido2 --ssh
```
- Generate FIDO2 SSH keys: `ssh-keygen -t ed25519-sk -O no-touch-required`
- Configure SSH agent integration
- Handle multiple SSH keys for different servers/purposes

### **3. Encryption**
```bash
omarchy-setup-fido2 --luks
# or
omarchy-setup-fido2 --encryption
```
- LUKS disk encryption with FIDO2
- `systemd-cryptenroll` integration
- PIN configuration for boot process

### **Combined Usage:**
```bash
# Setup everything
omarchy-setup-fido2 --all

# Or individual components
omarchy-setup-fido2 --auth --ssh
omarchy-setup-fido2 --luks --pin
```

This modular approach lets users choose which FIDO2 features they want without forcing everything at once.

## PinArchy-Setup-FIDO2 Implementation

### **New Script Created: `bin/pinarchy-setup-fido2`**

To avoid upstream merge conflicts, a new PinArchy-specific FIDO2 management script has been created with the following features:

**UI Framework:**
- Uses GUM for consistent interface matching other Omarchy tools
- Multi-select component selection with space bar
- Separate authentication option checkboxes
- Clean, user-friendly feedback display

**Component Selection:**
- **login-sudo**: System authentication (login + sudo + GUI admin via polkit)
- **ssh**: Hardware-backed SSH keys with no-touch requirement
- **luks**: Disk encryption with FIDO2 + PIN support

**Authentication Options:**
- **touch-required**: Physical touch needed for authentication
- **pin-required**: PIN entry required for authentication
- **Default**: Presence-only authentication (no touch, no PIN)

**Current Status:**
- ✅ **UI Framework Complete**: Full GUM-based interface implemented
- ✅ **Component Selection**: Multi-select for login-sudo, ssh, luks
- ✅ **Authentication Options**: Separate checkboxes for touch/PIN requirements
- ✅ **Login-Sudo Component**: Fully implemented with setup and removal
- ✅ **SSH Component**: Fully implemented with setup and removal
- ❌ **LUKS Component**: Not yet implemented

**Architecture Design:**
```bash
# Usage examples (when implementation complete):
pinarchy-setup-fido2                  # Interactive GUM interface to add
pinarchy-setup-fido2 --remove         # List and remove
```

**Integration with Existing System:**
- Uses hostname-based origin/appid: `pam://$HOSTNAME`
- Maintains compatibility with existing `/etc/fido2/fido2` file structure
- Supports multiple YubiKey devices per user
- Consistent error handling and user feedback

**Remaining Work:**
1. ✅ ~~Implement login-sudo FIDO2 configuration~~ **COMPLETED**
2. ✅ ~~Add hostname-based FIDO2 registration system~~ **COMPLETED**
3. ✅ ~~Integrate with PAM configuration for login authentication~~ **COMPLETED**  
4. ✅ ~~Implement SSH FIDO2 key generation with security options~~ **COMPLETED**
5. ❌ **Add LUKS encryption support with systemd-cryptenroll** - **REMAINING**

**Current Focus:** LUKS component implementation for disk encryption with FIDO2 + PIN support
