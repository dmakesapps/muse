# Widget Not Showing on Physical Device - Troubleshooting

If you can't find "Muse" when trying to add widgets, follow these steps:

## Step 1: Verify Widget Extension is Built

1. In Xcode, select your **physical device** (not simulator)
2. Select **MuseWidgetsExtension** scheme (next to the play button)
3. Build the widget extension: **Product → Build** (⌘B)
4. Check for any errors - fix them if present

## Step 2: Check Code Signing

### Main App (Muse target):
1. Select **Muse** target
2. **Signing & Capabilities** tab
3. Verify:
   - ✅ **Automatically manage signing** is checked
   - **Team** is selected
   - **Bundle Identifier**: `Ephesian28LLC.Muse`

### Widget Extension (MuseWidgetsExtension target):
1. Select **MuseWidgetsExtension** target  
2. **Signing & Capabilities** tab
3. Verify:
   - ✅ **Automatically manage signing** is checked
   - **Team** is THE SAME as main app
   - **Bundle Identifier**: `Ephesian28LLC.Muse.MuseWidgets`

## Step 3: Verify App Groups

**Both targets must have:**
- App Groups capability
- Same App Group: `group.Ephesian28LLC.Muse`
- Both checked/enabled

## Step 4: Clean and Rebuild

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Select your physical device**
3. **Select Muse scheme** (main app, not widget extension)
4. **Product → Build** (⌘B) - should build both app and extension
5. **Product → Run** (⌘R)

## Step 5: Check Installation

After running:
1. On your device, go to **Settings → General → VPN & Device Management**
2. Find your developer profile
3. Verify both **Muse** and **MuseWidgetsExtension** are listed
4. If MuseWidgetsExtension is missing, the extension didn't install

## Step 6: Force Widget Refresh

1. **Delete the app** completely from your device
2. **Clean build folder** (⇧⌘K)
3. **Rebuild and reinstall**
4. **Wait 30 seconds** after app installs
5. Try adding widgets again

## Step 7: Verify Widget Extension Build Phase

1. Select **Muse** target
2. **Build Phases** tab
3. Look for **Embed Foundation Extensions**
4. Should contain: `MuseWidgetsExtension.appex`
5. If missing, the widget won't be available

## Common Issues

### "No widgets available"
- Widget extension didn't build successfully
- Check build errors in Xcode
- Make sure widget extension scheme builds without errors

### "App not found when adding widget"
- Widget extension not embedded in main app
- Check "Embed Foundation Extensions" build phase
- Both targets must be signed with same team

### "Widget extension not installed"
- Code signing mismatch between app and extension
- Verify both use same Development Team
- Clean and rebuild

## Quick Test

1. Build widget extension directly:
   - Select **MuseWidgetsExtension** scheme
   - Build (⌘B)
   - Should succeed without errors

2. Build main app:
   - Select **Muse** scheme  
   - Build (⌘B)
   - Should build both app and extension

3. Check build log:
   - Look for "MuseWidgetsExtension.appex" in build output
   - Should see "Embedding MuseWidgetsExtension.appex"

If you see errors, share them and I can help fix!


