# TICKET-002: LUKS Component Implementation Plan
## YubiKey Authentication System - Final Component

Based on TICKET-002 analysis, this implementation plan focuses on the **remaining LUKS encryption component** to complete the YubiKey authentication system.

## 🎯 Current Status Assessment

### ✅ **COMPLETED COMPONENTS (2/3)**
- **login-sudo**: Full PAM integration with 4 security levels ✅
- **ssh**: Hardware SSH keys with ECDSA-SK implementation ✅

### ❌ **REMAINING COMPONENT (1/3)**  
- **luks**: LUKS disk encryption with FIDO2 + PIN support ❌

## 🚀 Implementation Plan: LUKS Component

### **Phase 1: Research & Discovery**
**Duration: 1-2 hours**

**Goals:**
- Understand current PinArchy disk encryption setup
- Research systemd-cryptenroll integration patterns
- Identify FIDO2 + PIN configuration requirements

**Tasks:**
1. **Analyze Current Encryption Setup**
   - Review existing LUKS configuration in PinArchy
   - Check current crypttab and mkinitcpio setup
   - Identify encryption workflow and boot process

2. **Research systemd-cryptenroll**
   - Study systemd-cryptenroll FIDO2 functionality
   - Review PIN configuration options and requirements  
   - Understand recovery key generation and management

3. **FIDO2 + PIN Integration**
   - Research FIDO2 device PIN requirements
   - Study PIN prompting during boot process
   - Identify integration with existing Plymouth theme

### **Phase 2: Architecture Design**
**Duration: 2-3 hours**

**Goals:**
- Design LUKS component architecture
- Plan integration with existing pinarchy-setup-fido2 script
- Design security levels and backup strategies

**Architecture Components:**

#### **1. LUKS Setup Function Structure**
Following the established pattern from existing components:

**Main Script Integration:**
```bash
# Location: bin/pinarchy-setup-fido2 (main script)
# Add "luks" to COMPONENTS array
# Source the luks component file
source "$(dirname "$0")/pinarchy-setup-fido2-luks"
# Call process_luks_component function
process_luks_component
```

**Component Implementation:**
```bash
# Location: bin/pinarchy-setup-fido2-luks (sourced by main script)

# Function called by main script to process luks component
process_luks_component() {
  if [[ " ${SELECTED[@]} " =~ " luks " ]]; then
    echo "🔒 Processing LUKS component..."
    setup_luks_fido2 "${OPTIONS[@]}"
  fi
}

setup_luks_fido2() {
  local options=("$@")
  
  # Important: Display LUKS-specific recommendation
  echo ""
  echo "⚠️  LUKS FIDO2 Key Recommendation:"
  echo "   For disk encryption, it's recommended to enroll only ONE FIDO2 key"
  echo "   Multiple FIDO2 keys can complicate boot process and recovery"
  echo "   Use recovery keys and password fallback for backup access"
  echo ""
  if ! gum confirm "Continue with LUKS FIDO2 setup?"; then
    echo "LUKS setup cancelled."
    return 0
  fi
  
  # 1. Detect current LUKS devices
  # 2. Validate FIDO2 device compatibility  
  # 3. Configure systemd-cryptenroll with security options
  # 4. Generate recovery keys
  # 5. Register in keymap-luks
}
```

**Removal Script Integration:**
```bash
# Location: bin/pinarchy-remove-fido2-luks (sourced by removal script)

get_luks_keys() {
  # Filter keymap-luks for luks entries and populate FILTERED_KEYS/DISPLAY_KEYS arrays
}

remove_luks_keys() {
  local selected_keys=("$@")
  # Remove systemd-cryptenroll FIDO2 enrollments
  # Remove from keymap-luks
}
```

#### **2. Security Level Integration**
Support existing 4-level security pattern:
- **no-touch**: FIDO2 presence only (no touch, no PIN)
- **touch-required**: Physical touch required
- **pin-required**: PIN entry required (no touch)
- **touch-pin-required**: Both touch AND PIN required

#### **3. Integration Points**
- **Main Script**: Extend `pinarchy-setup-fido2` with luks component
- **GUM Interface**: Add LUKS to component selection menu
- **Security Options**: Apply touch/PIN requirements to LUKS enrollment
- **Keymap Tracking**: Add LUKS entries to `/etc/fido2/keymap-luks`

### **Phase 3: Core Implementation**
**Duration: 4-6 hours**

**Goals:**
- Implement LUKS FIDO2 enrollment functionality
- Add removal/management capabilities
- Integrate with existing script architecture

**Implementation Tasks:**

#### **1. Device Discovery & Validation**
```bash
get_luks_devices() {
  # Find all LUKS devices on system
  lsblk -f | grep crypto_LUKS
  # Validate devices are eligible for FIDO2 enrollment
}

validate_fido2_luks_support() {
  # Check systemd-cryptenroll availability
  # Verify FIDO2 device is compatible
  # Test PIN setup on device
}
```

#### **2. FIDO2 Enrollment Process**
```bash
enroll_fido2_luks() {
  local device="$1"
  local security_level="$2"
  
  # Configure systemd-cryptenroll based on security level
  case "$security_level" in
    "no-touch")
      systemd-cryptenroll --fido2-device=auto --fido2-with-user-presence=no "$device"
      ;;
    "touch-required") 
      systemd-cryptenroll --fido2-device=auto --fido2-with-user-presence=yes "$device"
      ;;
    "pin-required")
      systemd-cryptenroll --fido2-device=auto --fido2-with-user-verification=yes "$device"
      ;;
    "touch-pin-required")
      systemd-cryptenroll --fido2-device=auto --fido2-with-user-presence=yes --fido2-with-user-verification=yes "$device"
      ;;
  esac
}
```

#### **3. Recovery Key Management**
```bash
generate_recovery_keys() {
  # Generate systemd recovery keys for each LUKS device
  # Store securely with user guidance
  # Document recovery procedures
}
```

#### **4. Keymap Integration**
```bash
# Add LUKS entries to /etc/fido2/keymap-luks
# Format: keyname:luks_device:key_hash:timestamp:security_level
register_luks_keymap-luks() {
  local keyname="$1"
  local device="$2" 
  local security_level="$3"
  
  # Generate unique identifier for this LUKS enrollment
  local enrollment_id=$(systemd-cryptenroll "$device" --fido2-device=list | tail -1)
  local key_hash=$(echo "$enrollment_id" | sha256sum | cut -c1-10)
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "$keyname:$device:$key_hash:$timestamp:$security_level" | sudo tee -a /etc/fido2/keymap-luks
}
```

### **Phase 4: Testing & Integration**
**Duration: 2-3 hours**

**Goals:**
- Test LUKS FIDO2 enrollment and boot process
- Validate recovery procedures
- Integrate with existing script components

**Testing Tasks:**

#### **1. Enrollment Testing**
- Test each security level (no-touch, touch, PIN, touch+PIN)
- Verify FIDO2 device detection and enrollment
- Test multiple device enrollment for redundancy

#### **2. Boot Process Testing**
- Test FIDO2 + PIN unlock during boot
- Verify Plymouth integration (if applicable)
- Test fallback to password authentication

#### **3. Recovery Testing**
- Test recovery key functionality
- Verify password unlock still works
- Test FIDO2 device removal/replacement scenarios

#### **4. Integration Testing**
- Test with existing login-sudo and SSH components
- Verify keymap-luks tracking consistency
- Test removal functionality

### **Phase 5: Documentation & Finalization**
**Duration: 1-2 hours**

**Goals:**
- Document LUKS component usage
- Update existing documentation
- Mark TICKET-002 as complete

**Documentation Tasks:**

#### **1. Usage Documentation**
```bash
# Add to pinarchy-setup-fido2 help text
echo "LUKS Component:"
echo "  Encrypts disk partitions with FIDO2 hardware authentication"
echo "  Supports PIN requirements and multiple backup devices"
echo "  Generates recovery keys for emergency access"
```

#### **2. Security Documentation**
- Document recovery procedures
- Explain security level implications for disk encryption
- Provide troubleshooting guidance for boot issues

#### **3. Integration Documentation**
- Update TICKET-002 with completion status
- Document architectural decisions
- Provide maintenance procedures

## 🔒 Security Considerations

### **1. Recovery Strategy**
- **Recovery Keys**: Generate systemd recovery keys for each device
- **Password Fallback**: Maintain password access as backup
- **⚠️ Single FIDO2 Device**: Unlike login/SSH, recommend only ONE FIDO2 key per LUKS device
  - Multiple FIDO2 enrollments can create boot complexity
  - systemd-cryptenroll has practical limitations with multiple devices
  - Recovery keys provide safer backup strategy than multiple hardware tokens

### **2. Boot Process Security**
- **PIN Prompting**: Secure PIN entry during early boot
- **Device Detection**: Robust FIDO2 device detection
- **Fallback Mechanisms**: Graceful degradation to password auth

### **3. Device Management** 
- **Device Replacement**: Procedures for YubiKey replacement
- **Enrollment Limits**: systemd-cryptenroll device limits
- **Token Expiration**: Handle device token refresh

## 🎯 Success Criteria

### **Functional Requirements**
- ✅ LUKS devices can be enrolled with FIDO2 authentication
- ✅ Four security levels supported (no-touch, touch, PIN, touch+PIN)  
- ✅ Boot process successfully prompts for FIDO2 + PIN
- ✅ Recovery keys generated and documented
- ✅ Multiple FIDO2 devices supported per LUKS device
- ✅ Removal functionality works correctly

### **Integration Requirements**
- ✅ Integrated with existing `pinarchy-setup-fido2` script
- ✅ GUM interface includes LUKS component option
- ✅ Keymap tracking includes LUKS entries
- ✅ Consistent security level patterns with other components

### **Documentation Requirements**
- ✅ Usage procedures documented
- ✅ Recovery procedures documented  
- ✅ Security implications explained
- ✅ Troubleshooting guide provided

## 📋 Implementation Checklist

### **Phase 1: Research & Discovery**
- [ ] Analyze current PinArchy LUKS setup
- [ ] Research systemd-cryptenroll FIDO2 functionality
- [ ] Study PIN configuration requirements
- [ ] Review boot process integration points

### **Phase 2: Architecture Design**  
- [ ] Design LUKS component function structure
- [ ] Plan security level integration
- [ ] Design keymap-luks tracking for LUKS
- [ ] Plan recovery key management

### **Phase 3: Core Implementation**
- [ ] Implement device discovery and validation
- [ ] Create FIDO2 enrollment functions
- [ ] Add security level support
- [ ] Implement keymap-luks integration
- [ ] Create removal functionality

### **Phase 4: Testing & Integration**
- [ ] Test enrollment for all security levels
- [ ] Test boot process with FIDO2 + PIN
- [ ] Test recovery procedures
- [ ] Validate integration with existing components

### **Phase 5: Documentation & Finalization**
- [ ] Write usage documentation
- [ ] Document security considerations
- [ ] Update TICKET-002 status
- [ ] Create troubleshooting guide

## 🚀 Next Steps

1. **Begin Phase 1**: Research current LUKS setup and systemd-cryptenroll integration
2. **Validate Approach**: Ensure compatibility with existing PinArchy encryption setup
3. **Create Implementation Branch**: Start development work on LUKS component
4. **Test Incremental Changes**: Validate each component before integration

**Estimated Total Time: 10-16 hours**

**Priority: High** (Final component to complete TICKET-002)