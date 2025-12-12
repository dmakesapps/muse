# Fix Widget Build Error

## Error Message
```
warning: The CFBundleVersion of an app extension ('1') must match that of its containing parent app ('3').
```

## Solution

### Option 1: Fix in Xcode (Easiest)

1. **Select the Widget Extension Target:**
   - In Xcode, click on the project name in the navigator (top)
   - Under TARGETS, select **MuseWidgetsExtension**

2. **Go to General Tab:**
   - Click the **General** tab

3. **Update Version Numbers:**
   - **Version**: Change from `1` to `3`
   - **Build**: Change from `1` to `3`
   - **Marketing Version**: Change from `1.0` to `1.02`

4. **Do this for BOTH Debug and Release:**
   - Make sure you update both configurations
   - Or set it at the project level if there's a shared setting

### Option 2: Check Build Settings

1. Select **MuseWidgetsExtension** target
2. Go to **Build Settings** tab
3. Search for "CURRENT_PROJECT_VERSION"
4. Change it from `1` to `3`
5. Search for "MARKETING_VERSION"
6. Change it from `1.0` to `1.02`

### Verify

After making changes:
1. Clean build folder: **Product > Clean Build Folder** (⇧⌘K)
2. Build again: **Product > Build** (⌘B)
3. The warning should be gone!

## Additional Checks

Also make sure:
- ✅ App Groups are configured for both targets
- ✅ Widget files are added to the widget extension target
- ✅ Bundle identifier is: `Ephesian28LLC.Muse.MuseWidgets`

