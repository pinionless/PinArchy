#!/bin/bash

# FIDO2 Hardware Authentication Setup
# Configures PAM modules for sudo, login, and polkit authentication
# Sections: sudo-login (implemented), ssh (placeholder), luks (placeholder)

#
# SECTION 1: sudo-login - Configure PAM for sudo and login authentication
#

# Install required FIDO2 packages
sudo pacman -S --noconfirm --needed libfido2 pam-u2f openssh

# Create FIDO2 configuration directory and prepare four security level authfiles:
# - /etc/fido2/no-touch: Presence only (no touch, no PIN)
# - /etc/fido2/touch-required: Touch required (default)  
# - /etc/fido2/pin-required: PIN required (no touch)
# - /etc/fido2/touch-pin-required: Both touch AND PIN required
# - /etc/fido2/keymap: Maps key names to authfiles and handles
# This allows per-device security levels - users register keys to appropriate authfile
sudo mkdir -p /etc/fido2

# Create empty authfiles and keymap
sudo touch /etc/fido2/no-touch
sudo touch /etc/fido2/touch-required
sudo touch /etc/fido2/pin-required
sudo touch /etc/fido2/touch-pin-required
sudo touch /etc/fido2/keymap

# Configure sudo PAM with four security levels
# PAM tries each authfile in order with 'sufficient' - first match authenticates
if ! grep -q pam_u2f.so /etc/pam.d/sudo; then
    sudo sed -i '1i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/no-touch userpresence=0' /etc/pam.d/sudo
    sudo sed -i '2i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/touch-required' /etc/pam.d/sudo
    sudo sed -i '3i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/pin-required userpresence=0 pinverification=1' /etc/pam.d/sudo
    sudo sed -i '4i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/touch-pin-required pinverification=1' /etc/pam.d/sudo
fi

# Configure console login PAM with same four security levels
if ! grep -q pam_u2f.so /etc/pam.d/login; then
    sudo sed -i '1i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/no-touch userpresence=0' /etc/pam.d/login
    sudo sed -i '2i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/touch-required' /etc/pam.d/login
    sudo sed -i '3i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/pin-required userpresence=0 pinverification=1' /etc/pam.d/login
    sudo sed -i '4i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/touch-pin-required pinverification=1' /etc/pam.d/login
fi

# Configure polkit PAM for GUI admin operations
if [ -f /etc/pam.d/polkit-1 ] && ! grep -q 'pam_u2f.so' /etc/pam.d/polkit-1; then
    sudo sed -i '1i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/no-touch userpresence=0' /etc/pam.d/polkit-1
    sudo sed -i '2i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/touch-required' /etc/pam.d/polkit-1
    sudo sed -i '3i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/pin-required userpresence=0 pinverification=1' /etc/pam.d/polkit-1
    sudo sed -i '4i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/touch-pin-required pinverification=1' /etc/pam.d/polkit-1
elif [ ! -f /etc/pam.d/polkit-1 ]; then
    sudo tee /etc/pam.d/polkit-1 >/dev/null <<'EOF'
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/no-touch userpresence=0
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/touch-required
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/pin-required userpresence=0 pinverification=1
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/touch-pin-required pinverification=1
auth      required pam_unix.so

account   required pam_unix.so
password  required pam_unix.so
session   required pam_unix.so
EOF
fi

# NOTE: This script only sets up the PAM infrastructure for FIDO2 authentication.
# Actual FIDO2 key registration is done via: bin/pinarchy-setup-fido2
# Users can register keys to different security levels based on their needs.

#
# SECTION 2: ssh - SSH FIDO2 key support (placeholder for future)
#

# TODO: SSH FIDO2 implementation

#
# SECTION 3: luks - LUKS disk encryption with FIDO2 (placeholder for future)
#

# TODO: LUKS FIDO2 implementation
