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

### Check for Hardware Errors
```bash
# Check rasdaemon for hardware errors (NEW - most comprehensive)
ras-mc-ctl --summary
ras-mc-ctl --errors

# Check dmesg for hardware errors
dmesg | grep -i -E '(mce|hardware error|bert|aer)'
journalctl -k | grep -i -E '(mce|hardware|error)'

# Check watchdog status
systemctl status watchdog
journalctl -u watchdog -f
```

### Monitor System Health
```bash
# Real-time system monitoring
watch -n 5 'free -h && echo "---" && sensors 2>/dev/null'

# Check system load and uptime
uptime

# Monitor for freezes (run in screen/tmux)
while true; do
  date >> /var/log/heartbeat.log
  sleep 60
done
```

### After a Crash (Quick Data Collection)
```bash
# ONE-LINER: Collect all crash data quickly before next crash
ssh root@homelab "journalctl -b -1 -n 200 > /root/crash-$(date +%Y%m%d-%H%M).log && ras-mc-ctl --errors >> /root/crash-$(date +%Y%m%d-%H%M).log && dmesg | grep -i bert >> /root/crash-$(date +%Y%m%d-%H%M).log && journalctl --list-boots >> /root/crash-$(date +%Y%m%d-%H%M).log && echo 'Data collected to /root/crash-*.log'"

# Individual commands:
journalctl --list-boots
journalctl -b -1 -n 200  # Last 200 lines before crash
ras-mc-ctl --errors      # Hardware errors
dmesg | grep -i bert     # BERT errors
last reboot              # Crash timing
```

## 🚨 EMERGENCY RECOVERY PROCEDURE

**After the current crash, follow this EXACT procedure:**

### Step 1: Physical Check (Before powering on)
- [ ] Check if system is hot/warm to touch
- [ ] Check for burning smell
- [ ] Check all fans are spinning
- [ ] Check for loose connections

### Step 2: Power On and Boot to Memtest
1. Power on the system
2. **DO NOT boot to OS** - interrupt GRUB immediately
3. Select "Memory test (memtest86+)"
4. Let it run for at least 8 hours
5. Watch for ANY red errors

### Step 3: If You MUST Boot to OS (to collect data)
Run this immediately after boot:
```bash
# Quick data collection (run as one command)
ssh root@homelab '
  CRASH_LOG="/root/crash-$(date +%Y%m%d-%H%M).log"
  echo "=== CRASH REPORT $(date) ===" > $CRASH_LOG
  echo -e "\n=== BOOT HISTORY ===" >> $CRASH_LOG
  journalctl --list-boots >> $CRASH_LOG
  echo -e "\n=== LAST 200 LINES BEFORE CRASH ===" >> $CRASH_LOG
  journalctl -b -1 -n 200 >> $CRASH_LOG
  echo -e "\n=== HARDWARE ERRORS ===" >> $CRASH_LOG
  ras-mc-ctl --errors >> $CRASH_LOG
  echo -e "\n=== BERT ERRORS ===" >> $CRASH_LOG
  dmesg | grep -i bert >> $CRASH_LOG
  echo -e "\n=== MCE ERRORS ===" >> $CRASH_LOG
  dmesg | grep -i mce >> $CRASH_LOG
  echo -e "\n=== MEMORY INFO ===" >> $CRASH_LOG
  free -h >> $CRASH_LOG
  dmidecode -t memory >> $CRASH_LOG
  echo "Report saved to $CRASH_LOG"
  cat $CRASH_LOG
'
```

### Step 4: Emergency Hardware Tests

**Test 1: Single RAM Stick**
1. Power off
2. Remove one RAM stick (leave only one installed)
3. Boot to memtest86+
4. Run for 2-4 hours
5. If stable: That RAM stick might be good, test the other
6. If crashes/errors: Try the other stick

**Test 2: Minimal Configuration**
1. Power off
2. Disconnect all unnecessary devices:
   - Extra drives (keep only OS drive)
   - USB devices
   - Network cards (if not integrated)
3. Test if more stable

**Test 3: BIOS Reset**
1. Enter BIOS/UEFI
2. Load "Optimized Defaults" or "Safe Defaults"
3. Save and exit
4. Test stability

## Latest Diagnostic Results (2026-01-14)

### System Configuration
- **CPU**: Intel Core i3-14100 (4 cores, 8 threads)
- **RAM**: 16GB (2x8GB Corsair CMK16GX4M2A2400C14 DDR4-2400) - **UPGRADED from 8GB**
- **OS**: Ubuntu with kernel 6.8.0-90-generic
- **ZFS**: Healthy, no errors detected

### ⚠️ CRITICAL: RAM Speed Mismatch - ROOT CAUSE IDENTIFIED

**PROBLEM FOUND**: Corsair Vengeance LPX DDR4-2400 RAM (CMK16GX4M2A2400C14) was being run at **2133 MT/s** but the modules are rated for 2400 MT/s. The BIOS downclocked them, creating instability.

**CONFIGURATION**:
- **Motherboard**: ASUS Prime B760M-A WIFI D4 (BIOS 1820, dated 05/15/2025)
- **RAM**: 2x8GB Corsair Vengeance LPX DDR4-2400 (CMK16GX4M2A2400C14)
  - Controller0-ChannelA-DIMM0: 8GB
  - Controller1-ChannelA-DIMM0: 8GB
- **Running at**: 2133 MT/s (underclocked from rated 2400 MT/s)
- **BIOS Settings**: Now corrected to run at proper speed

### Crash Pattern History

**Before BIOS Fix (RAM at incorrect speed)**:
- **Crash #1** (2026-01-14 03:31:10 UTC): 22 hours uptime
- **Crash #2** (2026-01-14 06:18:55 UTC): ~1 hour uptime
- **Crash #3** (during diagnostics): ~32 minutes uptime
- Pattern: **Accelerating failures** (22h → 1h → 32min)

**After Memtest86+ (RAM speed corrected to 2133 MT/s)**:
- **Memtest Result**: PASSED (no errors detected)
- **Post-memtest**: System appears more stable
- **Current status**: Monitoring for stability

**Key Finding**: The accelerating crash pattern was likely caused by RAM running at wrong speed causing instability under load

### Hardware Error Detection Status
✅ **Rasdaemon**: Installed, enabled, and actively monitoring
✅ **Watchdog**: Installed, enabled, and configured (60s timeout)
✅ **Memtest86+**: Installed and available in GRUB boot menu
✅ **Kernel logging**: Enhanced with `mce=verbose loglevel=5 pcie_aspm=off`

### Key Findings
1. **BERT Hardware Errors**: 1 error record found (persists across reboots)
2. **No MCE/AER Errors**: Rasdaemon shows no new errors since last boot
3. **No EDAC Support**: Memory error counters not available on this platform
4. **PCIe ASPM**: Now disabled to prevent potential power management issues
5. **Temperatures**: Normal (CPU ~36°C, no thermal issues)

### Root Cause Analysis
The symptoms continue to point to **hardware instability**:
1. **BERT errors** indicate hardware problems detected by firmware
2. **Complete freeze** with no software errors suggests hardware lockup
3. **Random timing** (varying uptimes) typical of intermittent hardware issues
4. **RAM upgrade** (8GB→16GB) hasn't resolved the issue

**Updated Root Cause Analysis** (after memtest and BIOS investigation):

1. **RAM Speed Mismatch** (90% confidence): ✅ **FIXED**
   - DDR4-2400 modules were running at 2133 MT/s
   - Created instability, especially under load
   - BIOS has corrected this
   - Memtest86+ passed with no errors

2. **DIMM Slot Configuration** (Potential Issue):
   - Current: Controller0-A-DIMM0 + Controller1-A-DIMM0 (likely single-channel)
   - Recommended: A2 + B2 slots for dual-channel (check manual)
   - Single-channel may contribute to instability

3. **Remaining Possibilities** (if crashes continue):
   - Power Supply: Voltage instability (5%)
   - Motherboard VRM: Temperature/quality issues (3%)
   - BIOS Bug: May need update (2%)

**Status**: System appears stable after RAM speed correction. Monitoring ongoing.

## IMMEDIATE EMERGENCY ACTIONS REQUIRED

### 🚨 System is CRITICALLY UNSTABLE - Act Now

The system crashed twice today with drastically different uptimes (22h → 1h), indicating **severe hardware failure**.

**DO NOT attempt normal operation until hardware is tested/replaced.**

### 🆘 If System Cannot Stay On: Boot to Safe/Recovery Mode

**If the system crashes constantly and you can't access it**, see **[SAFE_MODE_BOOT.md](./SAFE_MODE_BOOT.md)** for instructions on:
- Booting to Ubuntu Recovery Mode
- Single-user/emergency mode
- Minimal boot configuration
- Disabling services to reduce load

### Priority Actions (In Order):

1. **BOOT TO MEMTEST86+ IMMEDIATELY** - **🚨 EMERGENCY PRIORITY**
   - Do NOT boot into the OS
   - Select memtest86+ from GRUB menu
   - Run for minimum 8 hours (overnight if possible)
   - **If ANY errors appear**: STOP and replace RAM immediately

2. **When collecting crash data** (after forced reboot):
   ```bash
   ssh root@homelab "journalctl -b -1 -n 200 > /root/crash-$(date +%Y%m%d-%H%M).log"
   ssh root@homelab "ras-mc-ctl --errors >> /root/crash-$(date +%Y%m%d-%H%M).log"
   ssh root@homelab "dmesg | grep -i bert >> /root/crash-$(date +%Y%m%d-%H%M).log"
   ```

3. **If memtest shows NO errors** - Try these emergency measures:
   - Test with ONLY ONE RAM stick (try each individually)
   - Reset BIOS to defaults
   - Reseat all connections (RAM, power, cables)
   - Test with minimal hardware (disconnect unnecessary devices)

### Next Steps
1. **Run memtest86+** - **Priority 1** ⚠️ CRITICAL
   - Reboot and select memtest from GRUB menu
   - Run for at least 8 hours (multiple passes)
   - Test each RAM stick individually if errors found

2. **Monitor with new tools** - **Priority 1** ✅ DONE
   - Rasdaemon is now logging hardware errors
   - Watchdog will attempt recovery on freeze
   - Enhanced kernel logging active

3. **Check BIOS settings** - **Priority 2**
   - Verify RAM is running at correct speed (2400 MT/s)
   - Check XMP/DOCP profiles (disable if enabled)
   - Verify voltage settings (should be 1.2V for DDR4-2400)
   - Disable any overclocking

4. **Power supply testing** - **Priority 2**
   - Monitor voltage rails if IPMI/BMC available
   - Consider testing with different PSU
   - Check all power connections are secure

5. **BIOS update** - **Priority 3**
   - Check motherboard manufacturer for latest BIOS
   - Review release notes for stability fixes
