#!/bin/bash

# FIDO2 Hardware Authentication Setup
# Configures PAM modules for sudo, login, and polkit authentication
# Sections: sudo and login (implemented), ssh (placeholder), luks (placeholder)

#
# SECTION 1: sudo and login - Configure PAM for separate sudo and login authentication
#

# Install required FIDO2 packages
sudo pacman -S --noconfirm --needed libfido2 pam-u2f openssh

# Create FIDO2 configuration directory and prepare separate authfiles for sudo and login:
# SUDO authfiles:
# - /etc/fido2/sudo-no-touch: Sudo with presence only (no touch, no PIN)
# - /etc/fido2/sudo-touch-required: Sudo with touch required
# - /etc/fido2/sudo-pin-required: Sudo with PIN required (no touch)
# - /etc/fido2/sudo-touch-pin-required: Sudo with both touch AND PIN required
# LOGIN authfiles:
# - /etc/fido2/login-no-touch: Login with presence only (no touch, no PIN)
# - /etc/fido2/login-touch-required: Login with touch required
# - /etc/fido2/login-pin-required: Login with PIN required (no touch)
# - /etc/fido2/login-touch-pin-required: Login with both touch AND PIN required
# KEYMAPS:
# - /etc/fido2/keymap-sudo: Maps sudo key names to authfiles and handles
# - /etc/fido2/keymap-login: Maps login key names to authfiles and handles
# - /etc/fido2/keymap-luks: Maps LUKS key names to device credentials
sudo mkdir -p /etc/fido2

# Create separate authfiles for sudo and login
sudo touch /etc/fido2/sudo-no-touch
sudo touch /etc/fido2/sudo-touch-required
sudo touch /etc/fido2/sudo-pin-required
sudo touch /etc/fido2/sudo-touch-pin-required
sudo touch /etc/fido2/login-no-touch
sudo touch /etc/fido2/login-touch-required
sudo touch /etc/fido2/login-pin-required
sudo touch /etc/fido2/login-touch-pin-required

# Create separate keymaps
sudo touch /etc/fido2/keymap-sudo
sudo touch /etc/fido2/keymap-login
sudo touch /etc/fido2/keymap-luks

# Configure sudo PAM with separate sudo-specific authfiles
# PAM tries each authfile in order with 'sufficient' - first match authenticates
if ! grep -q pam_u2f.so /etc/pam.d/sudo; then
    sudo sed -i '1i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-no-touch userpresence=0' /etc/pam.d/sudo
    sudo sed -i '2i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-required' /etc/pam.d/sudo
    sudo sed -i '3i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-pin-required userpresence=0 pinverification=1' /etc/pam.d/sudo
    sudo sed -i '4i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-pin-required pinverification=1' /etc/pam.d/sudo
fi

# Configure console login PAM with separate login-specific authfiles
if ! grep -q pam_u2f.so /etc/pam.d/login; then
    sudo sed -i '1i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/login-no-touch userpresence=0' /etc/pam.d/login
    sudo sed -i '2i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/login-touch-required' /etc/pam.d/login
    sudo sed -i '3i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/login-pin-required userpresence=0 pinverification=1' /etc/pam.d/login
    sudo sed -i '4i auth    sufficient pam_u2f.so cue authfile=/etc/fido2/login-touch-pin-required pinverification=1' /etc/pam.d/login
fi

# Configure polkit PAM for GUI admin operations (use sudo authfiles since polkit is for admin tasks)
if [ -f /etc/pam.d/polkit-1 ] && ! grep -q 'pam_u2f.so' /etc/pam.d/polkit-1; then
    sudo sed -i '1i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-no-touch userpresence=0' /etc/pam.d/polkit-1
    sudo sed -i '2i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-required' /etc/pam.d/polkit-1
    sudo sed -i '3i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-pin-required userpresence=0 pinverification=1' /etc/pam.d/polkit-1
    sudo sed -i '4i auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-pin-required pinverification=1' /etc/pam.d/polkit-1
elif [ ! -f /etc/pam.d/polkit-1 ]; then
    sudo tee /etc/pam.d/polkit-1 >/dev/null <<'EOF'
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-no-touch userpresence=0
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-required
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-pin-required userpresence=0 pinverification=1
auth      sufficient pam_u2f.so cue authfile=/etc/fido2/sudo-touch-pin-required pinverification=1
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
