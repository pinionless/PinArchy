#!/bin/bash

# Hibernation with Swapfile in Btrfs Subvolume Setup
# Implementation for TICKET-020

set -e

# Check if hibernation setup was requested
if [[ "${PINARCHY_HIBERNATION,,}" != "y" ]]; then
  echo "Hibernation setup skipped (user preference)"
  return 0
fi

echo -e "\e[32m🛏️ Setting up hibernation with swapfile in Btrfs subvolume...\e[0m"

# Validate system prerequisites
echo -e "\e[33mValidating system prerequisites...\e[0m"

# Check if we're on a Btrfs filesystem
if ! findmnt -n -o FSTYPE / | grep -q "btrfs"; then
    echo -e "\e[31mRoot filesystem is not Btrfs. This script is designed for Btrfs systems only.\e[0m"
    return 1
fi
echo "Root filesystem is Btrfs ✓"

# ------------------------------------------
# STEP 1: Btrfs Swapfile Creation
# ------------------------------------------

# Get system information
ram_size_bytes=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
ram_size_gb=$((ram_size_bytes / 1024 / 1024 / 1024))
device_root=$(df / | tail -1 | awk '{print $1}' | sed 's/\[.*\]//')

echo "Detected system RAM: ${ram_size_gb}GB"
echo "Root device: $device_root"

# Check available disk space
available_space_kb=$(df / | tail -1 | awk '{print $4}')
ram_size_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')

echo "Available disk space: $((available_space_kb / 1024)) MB"
echo "System RAM size: $((ram_size_kb / 1024)) MB"

if [[ $available_space_kb -lt $((ram_size_kb + 1048576)) ]]; then
    echo -e "\e[31mInsufficient disk space for swapfile (need RAM size + 1GB buffer)\e[0m"
    echo "Required: $((ram_size_kb / 1024 + 1024)) MB, Available: $((available_space_kb / 1024)) MB"
    exit 1
else
    echo "Sufficient disk space available ✓"
fi

echo -e "\e[32m\n=== STEP 1: Btrfs Swapfile Creation ===\e[0m"

# 1.1: Create top-level @swapfile subvolume if it doesn't exist
if ! sudo btrfs subvolume list / | grep -q "@swapfile"; then
    echo "Creating top-level @swapfile subvolume..."
    
    # Mount the Btrfs filesystem root (not the @ subvolume)
    echo "Mounting Btrfs filesystem root temporarily..."
    sudo mkdir -p /mnt/btrfs-root
    sudo mount "$device_root" /mnt/btrfs-root
    
    # Create the subvolume at the top level (sibling to @ and @home)
    echo "Creating @swapfile subvolume at top level..."
    sudo btrfs subvolume create /mnt/btrfs-root/@swapfile
    
    # Unmount and clean up
    echo "Cleaning up temporary mount..."
    sudo umount /mnt/btrfs-root
    sudo rmdir /mnt/btrfs-root
    
    echo "Top-level @swapfile subvolume created ✓"
else
    echo "Top-level @swapfile subvolume already exists ✓"
fi

# 1.2: Set up /swap mount point and mount @swapfile subvolume
echo "Setting up /swap mount point..."

if [[ ! -d /swap ]]; then
    echo "Creating /swap directory..."
    sudo mkdir -p /swap
else
    echo "/swap directory exists ✓"
fi

# Mount the @swapfile subvolume to /swap if not already mounted
if ! mountpoint -q /swap 2>/dev/null; then
    echo "Mounting @swapfile subvolume to /swap..."
    sudo mount -o subvol=@swapfile "$device_root" /swap
    echo "@swapfile subvolume mounted to /swap ✓"
else
    echo "/swap is already mounted ✓"
    # Verify it's the correct subvolume
    mounted_subvol=$(findmnt -n -o OPTIONS /swap | grep -o 'subvol=[^,]*' | cut -d= -f2 2>/dev/null || echo "unknown")
    if [[ "$mounted_subvol" != "/@swapfile" ]]; then
        echo -e "\e[33mWrong subvolume mounted at /swap (found: $mounted_subvol, expected: @swapfile)\e[0m"
        echo "Remounting correct subvolume..."
        sudo umount /swap
        sudo mount -o subvol=@swapfile "$device_root" /swap
        echo "Correct @swapfile subvolume mounted ✓"
    else
        echo "Correct @swapfile subvolume already mounted ✓"
    fi
fi

# 1.3: Disable COW for the entire subvolume (CRITICAL)
echo "Disabling Copy-on-Write (COW) for swapfile subvolume..."

if lsattr -d /swap 2>/dev/null | grep -q "C"; then
    echo "COW is already disabled for /swap ✓"
else
    echo "Disabling COW for /swap directory..."
    sudo chattr +C /swap
    echo "COW disabled for /swap directory ✓"
    
    # Verify the change
    if lsattr -d /swap 2>/dev/null | grep -q "C"; then
        echo "COW disable verified ✓"
    else
        echo -e "\e[31mFailed to disable COW for /swap\e[0m"
        exit 1
    fi
fi

# 1.4: Create swapfile using Btrfs-specific methods
echo "Creating swapfile with size equal to RAM..."

# Check if swapfile already exists
if [[ -f /swap/swapfile ]]; then
    echo -e "\e[33mSwapfile already exists at /swap/swapfile\e[0m"
    existing_size=$(stat -c%s /swap/swapfile 2>/dev/null || echo 0)
    existing_size_gb=$((existing_size / 1024 / 1024 / 1024))
    echo "Existing swapfile size: ${existing_size_gb}GB"
    
    if [[ $existing_size -eq $ram_size_bytes ]]; then
        echo "Existing swapfile size matches RAM size ✓"
        # Ensure it's activated
        if ! swapon --show | grep -q "/swap/swapfile"; then
            echo "Activating existing swapfile..."
            sudo swapon /swap/swapfile
            echo "Existing swapfile activated ✓"
        else
            echo "Existing swapfile is already active ✓"
        fi
    else
        echo -e "\e[33mRecreating swapfile with correct size...\e[0m"
        sudo swapoff /swap/swapfile 2>/dev/null || true
        sudo rm -f /swap/swapfile
        echo "Existing swapfile removed"
    fi
fi

# Create new swapfile if needed
if [[ ! -f /swap/swapfile ]]; then
    echo "Creating new swapfile with size: ${ram_size_gb}GB (${ram_size_bytes} bytes)"
    
    # Try modern Btrfs filesystem mkswapfile command (kernel 6.1+)
    if command -v btrfs >/dev/null && btrfs filesystem mkswapfile --help >/dev/null 2>&1; then
        echo "Using modern 'btrfs filesystem mkswapfile' command..."
        sudo btrfs filesystem mkswapfile --size "$ram_size_bytes" /swap/swapfile
        echo "Swapfile created using modern Btrfs method ✓"
        USED_MODERN_METHOD=true
    else
        echo -e "\e[33mModern btrfs mkswapfile not available, using manual method...\e[0m"
        
        # Manual method (compatible with older kernels) - following research document exactly
        echo "Step 1: Creating empty file..."
        sudo truncate -s 0 /swap/swapfile
        
        echo "Step 2: Disabling COW for swapfile..."
        sudo chattr +C /swap/swapfile
        
        echo "Step 3: Disabling compression..."
        sudo btrfs property set /swap/swapfile compression none
        
        echo "Step 4: Allocating space (${ram_size_gb}GB)..."
        sudo fallocate -l "$ram_size_bytes" /swap/swapfile
        
        echo "Step 5: Setting secure permissions..."
        sudo chmod 600 /swap/swapfile
        
        echo "Step 6: Formatting as swap..."
        sudo mkswap /swap/swapfile
        
        echo "Swapfile created using manual method ✓"
        USED_MODERN_METHOD=false
    fi
    
    # Verify swapfile properties
    echo "Verifying swapfile properties..."
    
    # Check size
    actual_size=$(stat -c%s /swap/swapfile)
    actual_size_gb=$((actual_size / 1024 / 1024 / 1024))
    echo "Swapfile size: ${actual_size_gb}GB"
    
    if [[ $actual_size -eq $ram_size_bytes ]]; then
        echo "Swapfile size matches RAM size ✓"
    else
        echo -e "\e[33mSwapfile size doesn't exactly match RAM size\e[0m"
        size_diff=$((actual_size - ram_size_bytes))
        echo "Size difference: $size_diff bytes (acceptable)"
    fi
    
    # Check permissions
    perms=$(stat -c%a /swap/swapfile)
    if [[ "$perms" == "600" ]]; then
        echo "Swapfile permissions are secure (600) ✓"
    else
        echo -e "\e[33mSwapfile permissions are $perms (should be 600)\e[0m"
        echo "Fixing permissions..."
        sudo chmod 600 /swap/swapfile
        echo "Permissions fixed to 600 ✓"
    fi
    
    # Check COW status for swapfile
    if [[ "${USED_MODERN_METHOD:-false}" == "true" ]]; then
        echo "COW is disabled for swapfile (handled internally by modern method) ✓"
    else
        # Only verify lsattr for manual method
        if lsattr /swap/swapfile 2>/dev/null | grep -q "C"; then
            echo "COW is disabled for swapfile ✓"
        else
            echo -e "\e[31mCOW is NOT disabled for swapfile - this will cause problems\e[0m"
            exit 1
        fi
    fi
    
    # Check compression
    compression=$(btrfs property get /swap/swapfile compression 2>/dev/null || echo "unknown")
    echo "Swapfile compression: $compression"
    if [[ "$compression" == "compression=none" ]] || [[ "$compression" == "none" ]]; then
        echo "Compression is disabled for swapfile ✓"
    else
        echo -e "\e[33mCompression setting: $compression\e[0m"
    fi
fi

# 1.5: Activate swapfile
if ! swapon --show | grep -q "/swap/swapfile"; then
    echo "Activating swapfile..."
    sudo swapon /swap/swapfile
    echo "Swapfile activated ✓"
else
    echo "Swapfile is already active ✓"
fi

# Configure swappiness for hibernation-only usage
echo "Configuring swappiness for hibernation-only usage..."

# Set swappiness to 1 (minimum) - only swap when critically low on RAM
if ! grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
    echo "vm.swappiness=1" | sudo tee -a /etc/sysctl.conf >/dev/null
    echo "Added vm.swappiness=1 to /etc/sysctl.conf ✓"
else
    echo "vm.swappiness already configured in /etc/sysctl.conf ✓"
fi

# Apply immediately for current session
sudo sysctl vm.swappiness=1 >/dev/null
echo "Current swappiness: $(cat /proc/sys/vm/swappiness)"

# Show current swap status
echo "Current swap status:"
swapon --show

# 1.6: Add to fstab for persistence
echo "Configuring fstab for persistence..."

echo "DEBUG: device_root = '$device_root'"
device_uuid=$(blkid -s UUID -o value "$device_root")
echo "DEBUG: device_uuid = '$device_uuid'"
echo "Device UUID: $device_uuid"

# Check if entries already exist and add if missing
if ! grep -q "subvol=@swapfile" /etc/fstab; then
    echo "Adding @swapfile subvolume to fstab..."
    echo "UUID=$device_uuid /swap btrfs subvol=@swapfile,rw,relatime,nodatasum,nodatacow,space_cache=v2 0 0" | sudo tee -a /etc/fstab >/dev/null
    echo "@swapfile subvolume added to fstab ✓"
else
    echo "@swapfile subvolume entry exists in fstab ✓"
fi

if ! grep -q "/swap/swapfile.*swap" /etc/fstab; then
    echo "Adding swapfile to fstab..."
    echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab >/dev/null
    echo "Swapfile added to fstab ✓"
else
    echo "Swapfile entry exists in fstab ✓"
fi

# ------------------------------------------
# STEP 2: Kernel Configuration (mkinitcpio hooks)
# ------------------------------------------

echo -e "\e[32m\n=== STEP 2: Kernel Configuration ===\e[0m"

# Check if PinArchy hooks configuration file exists
hooks_file="/etc/mkinitcpio.conf.d/pinarchy_hooks.conf"

if [[ -f "$hooks_file" ]]; then
    echo "Found PinArchy hooks configuration: $hooks_file"
    
    # Read current HOOKS configuration
    current_hooks=$(grep "^HOOKS=" "$hooks_file" | cut -d'=' -f2)
    echo "Current HOOKS: $current_hooks"
    
    # Check if resume hook is already present
    if echo "$current_hooks" | grep -q "resume"; then
        echo "Resume hook already present in HOOKS ✓"
    else
        echo "Adding resume hook after filesystems..."
        
        # Add resume hook after filesystems hook
        # Current: HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole consolefont block sd-encrypt filesystems fsck btrfs-overlayfs)
        # Target:  HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole consolefont block sd-encrypt filesystems resume fsck btrfs-overlayfs)
        
        updated_hooks=$(echo "$current_hooks" | sed 's/filesystems /filesystems resume /')
        
        # Backup original file
        echo "Creating backup: ${hooks_file}.backup"
        sudo cp "$hooks_file" "${hooks_file}.backup"
        
        # Update the HOOKS line
        sudo sed -i "s/^HOOKS=.*/HOOKS=$updated_hooks/" "$hooks_file"
        
        # Verify the change
        new_hooks=$(grep "^HOOKS=" "$hooks_file" | cut -d'=' -f2)
        echo "Updated HOOKS: $new_hooks"
        
        if echo "$new_hooks" | grep -q "resume"; then
            echo "Resume hook successfully added ✓"
            
            # Rebuild initramfs
            echo "Rebuilding initramfs..."
            sudo limine-mkinitcpio
            echo "Initramfs rebuilt ✓"
        else
            echo -e "\e[31mFailed to add resume hook\e[0m"
            exit 1
        fi
    fi
else
    echo -e "\e[33mPinArchy hooks file not found: $hooks_file\e[0m"
    echo "Checking for standard mkinitcpio configuration..."
    
    standard_file="/etc/mkinitcpio.conf"
    if [[ -f "$standard_file" ]]; then
        echo "Found standard mkinitcpio configuration: $standard_file"
        
        # Read current HOOKS configuration
        current_hooks=$(grep "^HOOKS=" "$standard_file" | cut -d'=' -f2)
        echo "Current HOOKS: $current_hooks"
        
        # Check if resume hook is already present
        if echo "$current_hooks" | grep -q "resume"; then
            echo "Resume hook already present in HOOKS ✓"
        else
            echo "Adding resume hook after filesystems..."
            
            # Add resume hook after filesystems hook
            updated_hooks=$(echo "$current_hooks" | sed 's/filesystems /filesystems resume /')
            
            # Backup original file
            echo "Creating backup: ${standard_file}.backup"
            sudo cp "$standard_file" "${standard_file}.backup"
            
            # Update the HOOKS line
            sudo sed -i "s/^HOOKS=.*/HOOKS=$updated_hooks/" "$standard_file"
            
            # Verify the change
            new_hooks=$(grep "^HOOKS=" "$standard_file" | cut -d'=' -f2)
            echo "Updated HOOKS: $new_hooks"
            
            if echo "$new_hooks" | grep -q "resume"; then
                echo "Resume hook successfully added ✓"
                
                # Rebuild initramfs
                echo "Rebuilding initramfs..."
                sudo limine-mkinitcpio
                echo "Initramfs rebuilt ✓"
            else
                echo -e "\e[31mFailed to add resume hook\e[0m"
                exit 1
            fi
        fi
    else
        echo -e "\e[31mNo mkinitcpio configuration file found\e[0m"
        exit 1
    fi
fi

# ------------------------------------------
# STEP 3: Bootloader Configuration (Limine)
# ------------------------------------------

echo -e "\e[32m\n=== STEP 3: Bootloader Configuration ===\e[0m"

# Check if limine configuration exists
limine_config="/etc/default/limine"

if [[ -f "$limine_config" ]]; then
    echo "Found Limine configuration: $limine_config"
    
    # Calculate resume offset using Btrfs-specific method
    echo "Calculating resume offset for swapfile..."
    if command -v btrfs >/dev/null && [[ -f /swap/swapfile ]]; then
        resume_offset=$(sudo btrfs inspect-internal map-swapfile -r /swap/swapfile)
        echo "Resume offset: $resume_offset"
        
        if [[ -n "$resume_offset" && "$resume_offset" =~ ^[0-9]+$ ]]; then
            echo "Valid resume offset calculated ✓"
            
            # Check if resume parameters already present
            if grep -q "resume=" "$limine_config"; then
                echo "Resume parameters already present in Limine config ✓"
            else
                echo "Adding resume parameters to kernel command line..."
                
                # Create backup
                echo "Creating backup: ${limine_config}.backup"
                sudo cp "$limine_config" "${limine_config}.backup"
                
                # Find line number for KERNEL_CMDLINE[default] and insert resume parameters above it
                # Extract root device from existing limine config to match format
                root_device=$(grep "CMDLINE_DEFAULT\|KERNEL_CMDLINE\[default\]" "$limine_config" | grep -o 'root=[^[:space:]]*' | head -1 | cut -d'=' -f2-)
                
                if [[ -n "$root_device" ]]; then
                    resume_params="resume=$root_device resume_offset=$resume_offset"
                    echo "Using root device format: $root_device"
                else
                    # Fallback to /dev/mapper/root for encrypted systems
                    resume_params="resume=/dev/mapper/root resume_offset=$resume_offset"
                    echo "Could not detect root device, using fallback: /dev/mapper/root"
                fi
                
                echo "Adding resume parameters: $resume_params"
                
                # Find the line number of KERNEL_CMDLINE[default]
                line_num=$(grep -n "^KERNEL_CMDLINE\[default\]+=" "$limine_config" | cut -d: -f1)
                
                if [[ -n "$line_num" ]]; then
                    echo "Found KERNEL_CMDLINE[default] at line $line_num"
                    
                    # Insert new line above with resume parameters only
                    sudo sed -i "${line_num}i\\KERNEL_CMDLINE[default]+=\"$resume_params\"" "$limine_config"
                else
                    echo -e "\e[31mCould not find KERNEL_CMDLINE[default] line\e[0m"
                    exit 1
                fi
                
                # Verify the addition
                if grep -q "resume=" "$limine_config"; then
                    echo "Resume parameters added successfully ✓"
                    
                    # Update Limine bootloader
                    echo "Updating Limine bootloader..."
                    sudo limine-update
                    echo "Limine bootloader updated ✓"
                else
                    echo -e "\e[31mFailed to add resume parameters\e[0m"
                    exit 1
                fi
            fi
        else
            echo -e "\e[31mFailed to calculate valid resume offset\e[0m"
            echo "Resume offset: '$resume_offset'"
            exit 1
        fi
    else
        echo -e "\e[31mCannot calculate resume offset - btrfs command not available or swapfile not found\e[0m"
        exit 1
    fi
else
    echo -e "\e[33mLinime configuration not found: $limine_config\e[0m"
    echo "This system may not be using Limine bootloader"
    echo "Hibernation setup incomplete - manual bootloader configuration required"
    exit 1
fi

# ------------------------------------------
# STEP 4: NVIDIA Hibernation Configuration
# ------------------------------------------

echo -e "\e[32m\n=== STEP 4: NVIDIA Hibernation Configuration ===\e[0m"

# 4.1: NVIDIA Detection
echo "Checking for NVIDIA GPU..."
if lspci | grep -i nvidia >/dev/null 2>&1; then
    echo "NVIDIA GPU detected ✓"
    
    # 4.2: NVIDIA Driver Parameters
    echo "Configuring NVIDIA driver parameters for hibernation..."
    
    nvidia_conf="/etc/modprobe.d/nvidia.conf"
    echo "Updating NVIDIA modprobe configuration: $nvidia_conf"
    
    # Create backup if file exists
    if [[ -f "$nvidia_conf" ]]; then
        echo "Creating backup: ${nvidia_conf}.backup"
        sudo cp "$nvidia_conf" "${nvidia_conf}.backup"
        echo "Existing nvidia.conf found - updating with hibernation parameters"
    else
        echo "Creating new nvidia.conf with hibernation parameters"
    fi
    
    # Define hibernation-specific parameters to add
    hibernation_params=(
        "options nvidia_drm fbdev=1"
        "options nvidia NVreg_PreserveVideoMemoryAllocations=1"
        "options nvidia NVreg_EnableGpuFirmware=0"
        "options nvidia NVreg_TemporaryFilePath=/var/tmp"
        "blacklist nouveau"
    )
    
    # Add each parameter if not already present
    for param in "${hibernation_params[@]}"; do
        param_key=$(echo "$param" | cut -d' ' -f1-2)
        if [[ -f "$nvidia_conf" ]] && grep -q "^$param_key" "$nvidia_conf"; then
            echo "$param_key already configured ✓"
        else
            echo "Adding: $param"
            echo "$param" | sudo tee -a "$nvidia_conf" >/dev/null
        fi
    done
    
    echo "NVIDIA modprobe configuration updated ✓"
    
    # 4.3: NVIDIA Hibernation Services
    echo "Enabling NVIDIA hibernation services..."
    
    # List of NVIDIA hibernation services to enable
    nvidia_services=(
        "nvidia-suspend.service"
        "nvidia-hibernate.service"
        "nvidia-resume.service"
        "nvidia-suspend-then-hibernate.service"
    )
    
    for service in "${nvidia_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            if systemctl is-enabled "$service" >/dev/null 2>&1; then
                echo "$service is already enabled ✓"
            else
                echo "Enabling $service..."
                sudo systemctl enable "$service"
                echo "$service enabled ✓"
            fi
        else
            echo -e "\e[33m$service not found (may not be available with current driver)\e[0m"
        fi
    done
    
    # 4.4: Validation
    echo "Performing NVIDIA hibernation validation..."
    
    # Check /var/tmp space
    if [[ -d "/var/tmp" ]]; then
        var_tmp_space=$(df /var/tmp | tail -1 | awk '{print $4}')
        var_tmp_space_mb=$((var_tmp_space / 1024))
        echo "/var/tmp available space: ${var_tmp_space_mb} MB"
        
        # Get GPU memory info if nvidia-smi is available
        if command -v nvidia-smi >/dev/null; then
            gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
            if [[ -n "$gpu_memory" && "$gpu_memory" =~ ^[0-9]+$ ]]; then
                echo "GPU memory: ${gpu_memory} MB"
                
                if [[ $var_tmp_space_mb -ge $gpu_memory ]]; then
                    echo "/var/tmp space sufficient for GPU memory ✓"
                else
                    echo -e "\e[33m/var/tmp space may be insufficient for GPU memory\e[0m"
                    echo "Consider freeing space in /var/tmp or monitoring hibernation closely"
                fi
            else
                echo "Could not determine GPU memory size"
            fi
        else
            echo "nvidia-smi not available - cannot check GPU memory size"
        fi
    else
        echo -e "\e[33m/var/tmp directory not found\e[0m"
        echo "Creating /var/tmp directory..."
        sudo mkdir -p /var/tmp
        echo "/var/tmp directory created ✓"
    fi
    
    # Verify NVIDIA hibernation services
    echo "Verifying NVIDIA hibernation services..."
    enabled_services=0
    for service in "${nvidia_services[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            enabled_services=$((enabled_services + 1))
        fi
    done
    
    if [[ $enabled_services -gt 0 ]]; then
        echo "NVIDIA hibernation services enabled: $enabled_services/${#nvidia_services[@]} ✓"
    else
        echo -e "\e[33mNo NVIDIA hibernation services were enabled\e[0m"
        echo "This may be normal if services are not available with current driver version"
    fi
    
    echo -e "\e[32m\nNVIDIA hibernation configuration completed ✓\e[0m"
    echo -e "\e[33mNOTE: Reboot required for NVIDIA driver parameter changes to take effect\e[0m"
    
else
    echo "No NVIDIA GPU detected - skipping NVIDIA hibernation configuration ✓"
fi
