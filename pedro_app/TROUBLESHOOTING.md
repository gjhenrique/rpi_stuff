# Homelab System Freeze Troubleshooting

## Problem Summary
The homelab server experiences complete system freezes where:
- Video output stops
- USB devices (keyboard) stop working
- Network connectivity is lost
- System requires forced reboot

## Analysis Results

### Key Findings
1. **Hardware Lockup Confirmed**: Logs stop abruptly without any kernel panic, OOM, or software errors
2. **BERT Hardware Errors**: Boot Error Record Table shows hardware errors from previous boot cycles
3. **Memory Configuration**: Only 8GB RAM installed (single DIMM, single-channel mode)
4. **No Software Issues**: No kernel panics, OOM kills, thermal throttling, or ZFS errors detected

### Log Analysis
- Last boot (boot -1) crashed at: Jan 13 02:22:00 UTC
- System uptime before crash: ~15 hours
- Previous crashes show pattern of freezes after varying uptimes (38 minutes to ~15 hours)
- Logs show normal operations right up to the freeze point

## Root Cause Assessment
The symptoms strongly indicate a **hardware issue**, most likely:
1. **Power Supply**: Under-voltage or power delivery issues
2. **RAM Instability**: Single-channel configuration or faulty RAM stick
3. **Motherboard**: PCIe/USB controller issues
4. **CPU**: Less likely but possible

## Immediate Actions Recommended

### 1. Memory Testing
Run a comprehensive memory test:
```bash
# Install memtest86+ or use built-in memory test from GRUB
apt-get install memtest86+
# Reboot and select memory test from GRUB menu
```

### 2. Enable Hardware Error Logging
```bash
# Install and enable rasdaemon for hardware error reporting (modern replacement for mcelog)
apt-get install rasdaemon
systemctl enable rasdaemon
systemctl start rasdaemon

# Check for hardware errors
ras-mc-ctl --errors
ras-mc-ctl --summary
dmesg | grep -i -E '(mce|hardware error|ras|aer)'
```

### 3. Power Supply Verification
- Check PSU voltage rails (if accessible via IPMI/BMC)
- Monitor power consumption and voltage stability
- Consider testing with a different power supply
- Check for loose power connections

### 4. RAM Configuration
- Current: 8GB single DIMM (Corsair CMK16GX4M2A2400C14)
- Recommended: Install matching second DIMM for dual-channel operation
- Test with known-good RAM if available

### 5. BIOS/UEFI Updates
- Check for BIOS updates from motherboard manufacturer
- Review BIOS settings for stability:
  - Memory voltage/timing settings
  - Power management settings
  - PCIe/USB power management

### 6. Monitoring Setup
Set up monitoring to capture freeze events:
```bash
# Enable watchdog timer (if available)
apt-get install watchdog
systemctl enable watchdog

# Monitor hardware errors
journalctl -f | grep -i -E '(mce|hardware error|bert)'
```

### 7. Kernel Parameters (Temporary Diagnostic)
Add kernel parameters to capture more information:
```bash
# Add to /etc/default/grub GRUB_CMDLINE_LINUX:
# "mce=verbose loglevel=7"

# Then:
update-grub
reboot
```

## Prevention Strategies

### Short-term
1. Enable hardware error logging (mcelog)
2. Set up automated memory testing on boot
3. Monitor system temperature and power consumption
4. Consider reducing system load to see if freezes occur less frequently

### Long-term
1. **Fix RAM configuration**: Install second DIMM for dual-channel (recommended)
2. **Power Supply**: Replace if testing reveals voltage issues
3. **Hardware Testing**: Run stress tests (memtest, prime95, etc.)
4. **BIOS Update**: Apply latest firmware updates
5. **Hardware Replacement**: If issues persist, consider replacing suspected components

## Monitoring Commands
```bash
# Check hardware errors
dmesg | grep -i -E '(mce|hardware error|bert|aer)'
journalctl -k | grep -i -E '(mce|hardware|error)'

# Monitor system health
watch -n 5 'free -h && echo "---" && sensors 2>/dev/null || cat /sys/class/thermal/thermal_zone*/temp'

# Check memory errors (if EDAC available)
cat /sys/devices/system/edac/mc/mc*/csrow*/ch*_ce_count 2>/dev/null
cat /sys/devices/system/edac/mc/mc*/csrow*/ch*_ue_count 2>/dev/null
```

## Next Steps
1. Run memory test (memtest86+) - **Priority 1**
2. Install and enable mcelog - **Priority 1**
3. Check power supply/voltage - **Priority 2**
4. Consider adding second RAM stick - **Priority 2**
5. Update BIOS if available - **Priority 3**
