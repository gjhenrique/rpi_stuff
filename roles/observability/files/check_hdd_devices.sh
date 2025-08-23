#!/bin/bash
set -euo pipefail
# Script to check HDD devices and their accessibility
# Run this script to verify your HDD monitoring configuration

echo "=== HDD Device Check for Smartctl Exporter ==="
echo ""

# Check if smartctl is available
if ! command -v smartctl &> /dev/null; then
    echo "❌ smartctl not found. Please install smartmontools:"
    echo "   - Debian/Ubuntu: sudo apt install smartmontools"
    echo "   - Arch: sudo pacman -S smartmontools"
    exit 1
fi

echo "✅ smartctl found: $(smartctl --version | head -n1)"
echo ""

# List all block devices
echo "=== Available Block Devices ==="
lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(sd|hd|nvme)"
echo ""

# Check for common HDD devices
echo "=== Checking Common HDD Devices ==="
for device in /dev/sd[a-z] /dev/hd[a-z] /dev/nvme[0-9]n[0-9]; do
    if [ -b "$device" ]; then
        echo "🔍 Found device: $device"

        # Try to get basic info
        if smartctl -i "$device" &>/dev/null; then
            echo "   ✅ Accessible via smartctl"

            # Get device info
            model=$(smartctl -i "$device" | grep "Device Model" | cut -d: -f2 | xargs)
            serial=$(smartctl -i "$device" | grep "Serial Number" | cut -d: -f2 | xargs)

            if [ -n "$model" ]; then
                echo "   📝 Model: $model"
            fi
            if [ -n "$serial" ]; then
                echo "   🏷️  Serial: $serial"
            fi

            # Check mount point
            mount_point=$(findmnt -n -o TARGET "$device" 2>/dev/null || echo "Not mounted")
            echo "   📁 Mount: $mount_point"

        else
            echo "   ❌ Not accessible via smartctl (may need sudo or device not supported)"
        fi
        echo ""
    fi
done

echo "=== Configuration Example ==="
echo "Add this to your vars.yml file:"
echo ""
echo "observability_enable_hdd_monitoring: true"
echo "observability_hdd_devices:"
echo "  - device: \"/dev/sda\""
echo "    mount_point: \"/mnt/storage\""
echo "    description: \"Your drive description\""
echo ""

echo "=== Port Check ==="
echo "Smartctl exporter will use port: 9633"
echo "Make sure this port doesn't conflict with other services"
echo ""

echo "=== Next Steps ==="
echo "1. Update your vars.yml with the devices you want to monitor"
echo "2. Run your Ansible playbook"
echo "3. Check Prometheus targets at http://your-host:9090/targets"
echo "4. Look for 'smartctl_exporter' job in the targets list"
