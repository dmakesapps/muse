# Debug Widget Data Access

## Problem
Widgets show default/placeholder content instead of saved quotes/affirmations.

## Possible Causes

### 1. App Groups Not Configured
- Check that both **Muse** and **MuseWidgetsExtension** targets have App Groups capability
- App Group ID should be: `group.Ephesian28LLC.Muse`
- Both targets must have the same App Group ID

### 2. Data Not Syncing
The StorageService now:
- Loads from App Group first (most up-to-date)
- Falls back to regular UserDefaults if App Group is empty
- Syncs data to App Group when loading from regular UserDefaults

### 3. Test Data Access

Add this temporary debug code to test:

```swift
// In StorageService.swift, add this method:
func debugPrintData() {
    print("=== DEBUG: Data Access ===")
    print("App Group ID: \(SharedDataService.appGroupIdentifier)")
    
    // Check regular UserDefaults
    if let data = UserDefaults.standard.data(forKey: "savedQuotes") {
        print("Regular UserDefaults has quotes data: \(data.count) bytes")
    } else {
        print("Regular UserDefaults: NO quotes data")
    }
    
    // Check App Group UserDefaults
    if let sharedData = sharedUserDefaults?.data(forKey: "savedQuotes") {
        print("App Group has quotes data: \(sharedData.count) bytes")
    } else {
        print("App Group: NO quotes data")
    }
    
    print("Saved quotes count: \(savedQuotes.count)")
    print("==========================")
}
```

### 4. Force Sync Existing Data

If you have existing saved quotes/affirmations:
1. The updated `loadQuotes()` and `loadAffirmations()` methods will automatically sync them to App Group
2. Restart the app to trigger the sync
3. Then check the widget

### 5. Verify App Group Access

In the widget extension, add debug logging:

```swift
// In SharedDataService.swift
static func loadQuotes() -> [Quote] {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    print("Widget: App Group ID: \(appGroupIdentifier)")
    print("Widget: UserDefaults suite: \(String(describing: defaults))")
    
    guard let data = defaults?.data(forKey: "savedQuotes") else {
        print("Widget: No quotes data found in App Group")
        return []
    }
    
    print("Widget: Found quotes data: \(data.count) bytes")
    
    guard let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
        print("Widget: Failed to decode quotes")
        return []
    }
    
    print("Widget: Loaded \(decoded.count) quotes")
    return decoded
}
```

## Quick Fix Steps

1. **Make sure App Groups are configured** for both targets
2. **Restart the app** - this will trigger the sync
3. **Save a new quote/affirmation** - this will definitely sync to App Group
4. **Remove and re-add the widget** - this forces the widget to reload data
5. **Check Xcode console** for any error messages

## Expected Behavior

After fixing:
- When you save a quote/affirmation in the app, it should appear in the widget
- Widget should show random quotes/affirmations from your saved items
- Widget should refresh with new random selections based on timeline


