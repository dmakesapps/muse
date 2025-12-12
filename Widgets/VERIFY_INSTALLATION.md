# Verify Widget Extension Installation

## Widgets Don't Need Separate Permissions

Widgets are automatically available if the widget extension is properly installed. There's no separate "Widgets" permission in Settings.

## How to Verify Widget Extension is Installed

### Method 1: Check Device Settings

1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Find your developer profile (your Apple ID or team name)
3. Tap on it
4. You should see **TWO entries**:
   - ✅ **Muse** (the main app)
   - ✅ **MuseWidgetsExtension** (the widget extension)

**If MuseWidgetsExtension is missing**, the widget extension didn't install, which is why widgets aren't available.

### Method 2: Check Build Output

1. In Xcode, build the app for your device
2. Look at the build log (bottom panel)
3. Search for "MuseWidgetsExtension"
4. You should see:
   - "Building MuseWidgetsExtension..."
   - "Embedding MuseWidgetsExtension.appex"
   - "Installing MuseWidgetsExtension..."

### Method 3: Check Xcode Organizer

1. Window → Organizer (⇧⌘O)
2. Select your device
3. Find "Muse" app
4. Should show both app and extension

## If Widget Extension Didn't Install

### Fix 1: Build Widget Extension Directly

1. Select **MuseWidgetsExtension** scheme
2. Select your **physical device**
3. Build (⌘B)
4. Check for errors
5. If it builds successfully, switch back to **Muse** scheme and build again

### Fix 2: Check Code Signing

**Both targets must have:**
- Same Development Team
- Automatic code signing enabled
- Valid provisioning profiles

### Fix 3: Verify Embedding

1. Select **Muse** target
2. **Build Phases** tab
3. Look for **"Embed Foundation Extensions"**
4. Should contain: `MuseWidgetsExtension.appex`
5. If missing, the widget won't install

### Fix 4: Clean and Rebuild

1. Delete app from device
2. Clean build folder (⇧⌘K)
3. Select **Muse** scheme
4. Build and run (⌘R)
5. Check Settings → VPN & Device Management again

## Expected Result

After successful installation:
- Settings should show both Muse and MuseWidgetsExtension
- When adding widgets, "Muse" should appear in the widget picker
- You should see "Quote Widget" and "Affirmation Widget" options

