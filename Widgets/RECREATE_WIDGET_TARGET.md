# Recreate Widget Extension Target - Step by Step

## The Problem
The widget extension target disappeared from the project. We need to recreate it.

## Step-by-Step Instructions

### Step 1: Backup Your Widget Files
Your widget files are safe in `MuseWidgets/` folder. They won't be deleted, but we'll need to reconnect them.

### Step 2: Create New Widget Extension Target

1. **In Xcode**, select the **Muse** project in the navigator (top-level blue icon)

2. **Click the "+" button** at the bottom of the TARGETS list (or right-click and select "Add Target...")

3. **Select "Widget Extension"**:
   - In the template chooser, go to **iOS** tab
   - Select **Widget Extension**
   - Click **Next**

4. **Configure the Widget Extension**:
   - **Product Name**: `MuseWidgetsExtension`
   - **Team**: Select your team (Davis Poore)
   - **Organization Identifier**: `Ephesian28LLC`
   - **Bundle Identifier**: Should auto-fill as `Ephesian28LLC.Muse.MuseWidgets`
   - **Language**: Swift
   - **✅ CHECK** "Include Configuration Intent" (we want configurable widgets)
   - **✅ CHECK** "Include Live Activity" (optional, but good to have)
   - Click **Finish**

5. **When prompted**: 
   - **DO NOT** activate the scheme
   - Click **Cancel** or **Don't Activate**

### Step 3: Delete the Auto-Generated Files

The new target will create some template files. We need to remove them since we already have our widget files:

1. In the Project Navigator, find the new `MuseWidgetsExtension` folder
2. Delete these auto-generated files (if they exist):
   - `MuseWidgetsExtension.swift` (if different from our bundle)
   - Any duplicate widget files

### Step 4: Add Existing Widget Files to New Target

1. **Select all your existing widget files** in `MuseWidgets/` folder:
   - `MuseWidgetsBundle.swift`
   - `QuoteWidget.swift`
   - `AffirmationWidget.swift`
   - `SharedDataService.swift`
   - `Models.swift`
   - `Color+Hex.swift`
   - `AppIntent.swift` (if you have it)

2. **Open File Inspector** (right panel, or ⌥⌘1)

3. **In "Target Membership"**:
   - ✅ Check **MuseWidgetsExtension**
   - ❌ Uncheck **Muse** (if checked)

### Step 5: Configure App Groups

1. **Select MuseWidgetsExtension target**
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Add: `group.Ephesian28LLC.Muse`
7. Make sure it's **CHECKED**

### Step 6: Set Deployment Target

1. **Select MuseWidgetsExtension target**
2. Go to **General** tab
3. Under **Minimum Deployments**, set to **iOS 18.0**
4. Verify **Version** matches main app: `1.02`
5. Verify **Build** matches main app: `3`

### Step 7: Configure Embedding

1. **Select Muse target** (main app)
2. Go to **Build Phases** tab
3. Expand **Embed App Extensions**
4. Make sure **MuseWidgetsExtension.appex** is listed
5. If missing, click **+** and add it
6. Set **Destination**: "Plugins and Foundation Extensions"

### Step 8: Update Widget Bundle

Make sure `MuseWidgetsBundle.swift` has `@main` and includes your widgets:

```swift
@main
struct MuseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuoteWidget()
        AffirmationWidget()
    }
}
```

### Step 9: Clean and Build

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Select Muse scheme** (main app)
3. **Build** (⌘B)

### Step 10: Verify

1. In Xcode, you should see **MuseWidgetsExtension** in the TARGETS list
2. Build should succeed
3. No errors about missing targets

## If You Get Errors

- **"Cannot find MuseWidgetsExtension"**: Make sure the target is in the TARGETS list
- **"App Groups not found"**: Verify App Groups capability is added to both targets
- **"Version mismatch"**: Make sure both targets have Version `1.02` and Build `3`
- **"Deployment target mismatch"**: Both should be iOS 18.0

## Quick Checklist

- [ ] Widget extension target created
- [ ] Existing widget files added to target membership
- [ ] App Groups added to widget extension (`group.Ephesian28LLC.Muse`)
- [ ] Deployment target set to iOS 18.0
- [ ] Version matches main app (1.02)
- [ ] Build number matches main app (3)
- [ ] Widget extension embedded in main app
- [ ] Build succeeds


