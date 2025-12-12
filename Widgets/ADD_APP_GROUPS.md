# Add App Groups Capability to Widget Extension

## The Problem
Your widget extension target is missing the **App Groups** capability. This is why widgets aren't working!

## The Fix (2 minutes)

### Step 1: Add App Groups to Widget Extension

1. In Xcode, make sure **MuseWidgetsExtension** target is selected (you have this)
2. Go to **Signing & Capabilities** tab (you're already here)
3. Click the **+ Capability** button (top-left of the capabilities section)
4. Search for and select **App Groups**
5. Click the **+** button under App Groups
6. Add: `group.Ephesian28LLC.Muse`
7. Make sure it's **CHECKED/ENABLED**

### Step 2: Verify Main App Has App Groups

1. Select **Muse** target (main app)
2. Go to **Signing & Capabilities** tab
3. Look for **App Groups** capability
4. If missing, add it the same way
5. Make sure it has the **SAME** App Group ID: `group.Ephesian28LLC.Muse`
6. Make sure it's **CHECKED/ENABLED**

### Step 3: Verify Both Match

**Main App (Muse):**
- App Groups → `group.Ephesian28LLC.Muse` ✅

**Widget Extension (MuseWidgetsExtension):**
- App Groups → `group.Ephesian28LLC.Muse` ✅

Both must be identical!

### Step 4: Rebuild

1. Clean build folder (⇧⌘K)
2. Build and run the **Muse** scheme (main app)
3. Check Settings → VPN & Device Management
4. You should see both Muse and MuseWidgetsExtension
5. Try adding widgets - should work now!

## Why This Matters

Without App Groups:
- Widget extension can't access shared UserDefaults
- Data saved in the app won't appear in widgets
- Widgets will show empty/default content

With App Groups:
- Both app and widget can share data
- Saved quotes/affirmations will appear in widgets
- Everything works! ✅

