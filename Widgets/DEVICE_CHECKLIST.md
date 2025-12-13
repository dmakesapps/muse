# Physical Device Widget Checklist

## Critical Settings to Check in Xcode

### 1. Main App Target (Muse) - Signing & Capabilities

1. Select **Muse** target
2. **Signing & Capabilities** tab:
   - ✅ **Automatically manage signing**: CHECKED
   - **Team**: Select your development team
   - **Bundle Identifier**: `Ephesian28LLC.Muse`
3. **App Groups** capability:
   - Click **+ Capability** if not present
   - Add: `group.Ephesian28LLC.Muse`
   - Make sure it's CHECKED/ENABLED

### 2. Widget Extension Target (MuseWidgetsExtension) - Signing & Capabilities

1. Select **MuseWidgetsExtension** target
2. **Signing & Capabilities** tab:
   - ✅ **Automatically manage signing**: CHECKED
   - **Team**: MUST BE THE SAME as main app
   - **Bundle Identifier**: `Ephesian28LLC.Muse.MuseWidgets`
3. **App Groups** capability:
   - Click **+ Capability** if not present
   - Add: `group.Ephesian28LLC.Muse` (SAME as main app)
   - Make sure it's CHECKED/ENABLED

### 3. Verify Widget Extension is Embedded

1. Select **Muse** target
2. **Build Phases** tab
3. Look for **Embed Foundation Extensions** section
4. Should contain: `MuseWidgetsExtension.appex`
5. If missing, click **+** and add it

### 4. Build Settings - Both Targets

Make sure both targets have:
- **Code Signing Style**: Automatic
- **Development Team**: Same team ID
- **Provisioning Profile**: Should auto-generate

### 5. Common Physical Device Issues

#### Issue: "No widgets available"
**Solution:**
- Both targets must be signed with the same team
- App Groups must be configured identically
- Clean build folder (⇧⌘K) and rebuild

#### Issue: "Widget extension not found"
**Solution:**
- Verify widget extension is in "Embed Foundation Extensions"
- Check that widget extension builds successfully
- Delete app from device and reinstall

#### Issue: "Can't add widget"
**Solution:**
- Make sure widget extension target builds without errors
- Check that both targets have valid provisioning profiles
- Try deleting the app and reinstalling

### 6. Quick Test Steps

1. **Clean**: Product → Clean Build Folder (⇧⌘K)
2. **Select Device**: Choose your physical iPhone
3. **Build**: Product → Build (⌘B) - check for errors
4. **Run**: Product → Run (⌘R)
5. **Check Installation**: 
   - Settings → General → VPN & Device Management
   - Verify both app and extension are installed
6. **Add Widget**: Long-press home screen → + → Search "Muse"

### 7. If Still Not Working

Try this in order:
1. Delete app from device completely
2. Clean build folder (⇧⌘K)
3. Restart Xcode
4. Rebuild and reinstall
5. Check Xcode console for any signing errors
6. Verify App Groups are enabled in Apple Developer portal (if using paid account)


