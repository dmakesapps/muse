# Widget Not Appearing on Physical Device - Complete Fix

## The Problem
You've added App Groups to both targets, but the widget still doesn't appear when trying to add it to the home screen.

## Critical Steps (Do These First)

### Step 1: Delete App from Device
**This is crucial!** iOS caches widget extensions. You MUST delete the app completely:

1. On your iPhone, long-press the Muse app icon
2. Tap "Remove App"
3. Tap "Delete App" (not just remove from home screen)
4. Confirm deletion

### Step 2: Clean Build in Xcode
1. In Xcode: **Product → Clean Build Folder** (⇧⌘K)
2. Wait for it to complete

### Step 3: Verify Both Targets Are Selected
1. In Xcode, select **Muse** scheme (main app)
2. Go to **Product → Scheme → Edit Scheme...**
3. Click **Build** in the left sidebar
4. Make sure **MuseWidgetsExtension** is checked and appears in the list
5. If missing, click **+** and add it
6. Make sure it's set to build **Before** the main app

### Step 4: Verify Embedding
1. Select **Muse** target (main app)
2. Go to **Build Phases** tab
3. Expand **Embed App Extensions**
4. Make sure **MuseWidgetsExtension.appex** is listed
5. If missing, click **+** and add it

### Step 5: Rebuild and Install
1. Select your **physical device** (not simulator)
2. Select **Muse** scheme (NOT MuseWidgetsExtension)
3. Build and Run (⌘R)
4. Wait for installation to complete

### Step 6: Verify Installation
1. On your iPhone: **Settings → General → VPN & Device Management**
2. You should see **TWO** entries:
   - **Muse** (main app)
   - **MuseWidgetsExtension** (widget extension)
3. If you only see one, the extension didn't install

### Step 7: Try Adding Widget
1. Long-press on home screen
2. Tap **+** (top-left)
3. Scroll down to find **Muse**
4. If it's still not there, continue to troubleshooting below

## Advanced Troubleshooting

### Check Code Signing
Both targets must be signed with the **same team**:

1. **Muse** target → Signing & Capabilities
   - Team: Should be "Davis Poore" (or your team)
   - Bundle ID: `Ephesian28LLC.Muse`

2. **MuseWidgetsExtension** target → Signing & Capabilities
   - Team: **MUST MATCH** the main app team
   - Bundle ID: `Ephesian28LLC.Muse.MuseWidgets`

### Verify App Groups Match Exactly
1. **Muse** target → Signing & Capabilities → App Groups
   - Should show: `group.Ephesian28LLC.Muse` ✅

2. **MuseWidgetsExtension** target → Signing & Capabilities → App Groups
   - Should show: `group.Ephesian28LLC.Muse` ✅
   - **MUST BE IDENTICAL**

### Check Version Numbers Match
The warning about version mismatch might be causing issues:

1. **Muse** target → General tab
   - Version: `1.02`
   - Build: `3`

2. **MuseWidgetsExtension** target → General tab
   - Version: Should be `1.02` (match main app)
   - Build: Should be `3` (match main app)

**Fix:** Update widget extension version to match main app exactly.

### Verify Widget Bundle
Check that `MuseWidgetsBundle.swift` exists and has `@main`:

```swift
@main
struct MuseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuoteWidget()
        AffirmationWidget()
    }
}
```

### Check Info.plist
The widget extension's `Info.plist` should exist in `MuseWidgets/Info.plist`.

## Nuclear Option: Recreate Widget Extension

If nothing works, you may need to recreate the widget extension:

1. **Backup your widget code** (copy all files from `MuseWidgets/`)
2. Delete the `MuseWidgetsExtension` target in Xcode
3. Create a new Widget Extension target:
   - File → New → Target
   - iOS → Widget Extension
   - Name: `MuseWidgetsExtension`
   - **CHECK** "Include Configuration Intent"
   - Language: Swift
4. **Don't** activate the scheme when prompted
5. Copy your widget code back
6. Add App Groups to both targets
7. Clean build and reinstall

## Common Mistakes

❌ **Running the widget extension scheme directly** - Don't do this!
✅ **Run the main app scheme** - Widget extension builds automatically

❌ **Not deleting the app before reinstalling** - iOS caches extensions
✅ **Always delete app completely** before reinstalling

❌ **Different App Group IDs** - Must be identical
✅ **Same App Group ID**: `group.Ephesian28LLC.Muse`

❌ **Different code signing teams** - Must match
✅ **Same team for both targets**

## Still Not Working?

If after all these steps the widget still doesn't appear:

1. **Check Xcode console** for any errors during build
2. **Check device logs** in Xcode (Window → Devices and Simulators)
3. **Try on a different device** if available
4. **Restart your iPhone** after installation
5. **Check iOS version** - Widgets require iOS 14+

## Success Checklist

- [ ] App Groups added to both targets with same ID
- [ ] App completely deleted from device
- [ ] Clean build performed
- [ ] Widget extension appears in Build Phases → Embed App Extensions
- [ ] Both targets signed with same team
- [ ] Version numbers match
- [ ] Built using Muse scheme (main app)
- [ ] Both Muse and MuseWidgetsExtension appear in Settings → VPN & Device Management
- [ ] Widget appears in widget picker


