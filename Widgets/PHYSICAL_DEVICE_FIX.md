# Fix Widgets on Physical Device

If widgets aren't showing up on a physical device, check these settings:

## 1. Code Signing (CRITICAL)

### Main App Target (Muse):
1. Select **Muse** target
2. Go to **Signing & Capabilities** tab
3. Make sure:
   - ✅ **Automatically manage signing** is checked
   - **Team** is selected (your development team)
   - **Bundle Identifier**: `Ephesian28LLC.Muse`

### Widget Extension Target (MuseWidgetsExtension):
1. Select **MuseWidgetsExtension** target
2. Go to **Signing & Capabilities** tab
3. Make sure:
   - ✅ **Automatically manage signing** is checked
   - **Team** is the SAME as the main app
   - **Bundle Identifier**: `Ephesian28LLC.Muse.MuseWidgets`

## 2. App Groups (CRITICAL)

### Both Targets Must Have:
1. **App Groups** capability added
2. **Same App Group ID**: `group.Ephesian28LLC.Muse`
3. Both must be checked/enabled

### To Check:
- **Muse** target → Signing & Capabilities → App Groups → Should show `group.Ephesian28LLC.Muse`
- **MuseWidgetsExtension** target → Signing & Capabilities → App Groups → Should show `group.Ephesian28LLC.Muse`

## 3. Widget Extension Embedding

The widget extension should be automatically embedded. To verify:
1. Select **Muse** target
2. Go to **Build Phases** tab
3. Look for **Embed Foundation Extensions**
4. Should include: `MuseWidgetsExtension.appex`

## 4. Build Settings

### Both Targets Should Have:
- **Code Signing Style**: Automatic
- **Development Team**: Same team for both
- **Provisioning Profile**: Should be auto-generated

## 5. Common Issues

### Issue: "Widget not available"
- **Fix**: Make sure both targets are signed with the same team
- **Fix**: Verify App Groups are configured identically

### Issue: "Widget shows but no data"
- **Fix**: Check App Groups are enabled for both targets
- **Fix**: Verify the App Group ID matches exactly: `group.Ephesian28LLC.Muse`

### Issue: "Can't add widget to home screen"
- **Fix**: Clean build folder (⇧⌘K)
- **Fix**: Delete app from device and reinstall
- **Fix**: Make sure widget extension builds successfully

## 6. Testing Steps

1. **Clean Build**:
   - Product → Clean Build Folder (⇧⌘K)

2. **Build for Device**:
   - Select your physical device
   - Build and run (⌘R)

3. **Verify Installation**:
   - Check that both app and widget extension install
   - Long-press home screen → + → Search "Muse"
   - Widgets should appear in the list

4. **If Still Not Working**:
   - Delete the app from device
   - Clean build folder
   - Rebuild and reinstall
   - Try adding widgets again

## 7. Debug Checklist

- [ ] Both targets have same Development Team
- [ ] Both targets have App Groups capability
- [ ] App Group ID is identical: `group.Ephesian28LLC.Muse`
- [ ] Widget extension is embedded in main app
- [ ] Both targets build without errors
- [ ] App installs successfully on device
- [ ] Widget extension appears in device's installed extensions

