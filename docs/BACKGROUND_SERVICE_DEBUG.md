# Background Service Debugging Guide

## How to Verify Background Service is Running

### 1. **Check Service Status in App**
- Go to **Settings → Notification Settings**
- Look for the **"Background Service Status"** card
- Green = Service is running ✅
- Red = Service is not running ❌
- Use **"Refresh Status"** button to check current status
- Use **"Restart Service"** button if service is not running

### 2. **Check Logs (When App is Closed)**

#### Using ADB Logcat:

**Windows (PowerShell or CMD):**
```powershell
# Connect your device via USB
adb logcat | findstr "Background Service"

# Or filter for all FemCare logs:
adb logcat | findstr /i "femcare background"

# PowerShell alternative (more powerful):
adb logcat | Select-String "Background Service"
adb logcat | Select-String -Pattern "femcare|background" -CaseSensitive:$false
```

**Linux/Mac:**
```bash
# Connect your device via USB
adb logcat | grep "Background Service"

# Or filter for all FemCare logs:
adb logcat | grep -i "femcare\|background"
```

**Watch for these log messages:**
- 🚀 [Background Service] onStart called at [timestamp]
- ✅ [Background Service] Periodic timer started with interval: X minutes
- 🔄 [Background Service] Periodic check started at [timestamp]
- ✅ [Background Service] Checked for due notifications at [timestamp]

#### What to Look For:
- **Service Started**: `🚀 [Background Service] onStart called`
- **Periodic Checks**: `🔄 [Background Service] Periodic check started` (every X minutes)
- **Notification Checks**: `✅ [Background Service] Checked for due notifications`
- **Errors**: `❌ [Background Service] Error at [timestamp]`

### 3. **Test Notification When App is Closed**

1. **Create a test reminder**:
   - Go to Notification Settings
   - Click "Create Reminder"
   - Set time to 2-3 minutes in the future
   - Save the reminder

2. **Close the app completely**:
   - Swipe away from recent apps
   - Or use "Force Stop" in Android Settings

3. **Wait for the scheduled time**

4. **Check if notification appears**

5. **Check logs** (if notification didn't appear):
   
   **Windows:**
   ```powershell
   adb logcat | findstr "Background Service"
   # Or PowerShell:
   adb logcat | Select-String "Background Service"
   ```
   
   **Linux/Mac:**
   ```bash
   adb logcat | grep "Background Service"
   ```

### 4. **Common Issues & Solutions**

#### Issue: Service shows as "Not Running"
**Solutions**:
- Click "Restart Service" button
- Restart the app
- Check if battery optimization is disabled for the app
- Check Android Settings → Apps → FemCare+ → Battery → Unrestricted

#### Issue: Service stops when app is closed
**Solutions**:
- Enable "Unrestricted" battery usage in Android Settings
- Disable battery optimization for the app
- Some devices (Xiaomi, Huawei, Oppo) have aggressive battery management - check manufacturer-specific settings

#### Issue: Notifications don't fire when app is closed
**Possible Causes**:
1. Service is not running (check status in app)
2. Battery optimization is killing the service
3. Device-specific restrictions (check manufacturer settings)
4. Notification permissions not granted

**Solutions**:
- Check service status in Notification Settings
- Grant all notification permissions
- Disable battery optimization
- Check device-specific battery management settings

### 5. **Device-Specific Settings**

#### Xiaomi/MIUI:
- Settings → Apps → FemCare+ → Battery → No restrictions
- Settings → Battery → App battery saver → FemCare+ → No restrictions
- Settings → Apps → Permissions → Autostart → Enable for FemCare+

#### Huawei/EMUI:
- Settings → Battery → App launch → FemCare+ → Manual → Enable all
- Settings → Apps → FemCare+ → Battery → Unrestricted

#### Oppo/ColorOS:
- Settings → Battery → Battery optimization → FemCare+ → Don't optimize
- Settings → Apps → Startup Manager → Enable for FemCare+

#### Samsung:
- Settings → Apps → FemCare+ → Battery → Unrestricted
- Settings → Device care → Battery → App power management → FemCare+ → Unrestricted

### 6. **Foreground Service Notification**

When the background service is running, you should see a persistent notification:
- **Title**: "FemCare+"
- **Content**: "Last check: [time]" (updates every check interval)

This notification indicates the service is actively running. **Do not dismiss this notification** if you want background notifications to work.

### 7. **Verification Checklist**

- [ ] Service status shows "Running" in Notification Settings
- [ ] Foreground service notification is visible in notification tray
- [ ] Logs show periodic checks when app is closed
- [ ] Test reminder fires notification when app is closed
- [ ] Battery optimization is disabled for the app
- [ ] All notification permissions are granted

### 8. **Debug Commands**

**Windows (PowerShell/CMD):**
```powershell
# Check if service process is running
adb shell ps | findstr femcare

# Check service logs in real-time
adb logcat -s flutter:V | findstr "Background Service"
# Or PowerShell:
adb logcat -s flutter:V | Select-String "Background Service"

# Clear logs and start fresh
adb logcat -c
adb logcat | findstr "Background Service"
```

**Linux/Mac:**
```bash
# Check if service process is running
adb shell ps | grep femcare

# Check service logs in real-time
adb logcat -s flutter:V | grep "Background Service"

# Clear logs and start fresh
adb logcat -c
adb logcat | grep "Background Service"
```

### 9. **Expected Behavior**

**When App is Open**:
- Service runs in background
- In-app checker runs every 30 seconds (or half the configured interval)
- Background service runs every X minutes (configured interval)

**When App is Closed**:
- Background service continues running
- Checks for due notifications every X minutes
- Fires notifications immediately when due
- Updates foreground notification with last check time

**When App is Resumed**:
- Service status is checked
- Any missed notifications are fired immediately
- Service continues running

### 10. **Troubleshooting Steps**

1. **Check service status** in Notification Settings
2. **Restart service** if not running
3. **Check logs** using adb logcat
4. **Verify permissions** are granted
5. **Disable battery optimization**
6. **Check device-specific settings**
7. **Test with a short interval** (1-2 minutes) to verify it's working
8. **Check if foreground notification is visible**

If all else fails, the in-app checker (when app is open) and OS-level scheduled notifications should still work, even if the background service doesn't.

