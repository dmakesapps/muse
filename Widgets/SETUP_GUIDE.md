# Widget Setup Guide - Static vs Configurable

## Two Widget Options

I've created **two versions** of each widget:

### 1. Static Widgets (Simple)
- **Files**: `QuoteWidget.swift`, `AffirmationWidget.swift`
- **Refresh**: Automatically every hour
- **User Control**: None - just works out of the box
- **Best For**: Users who want a simple, set-it-and-forget-it widget

### 2. Configurable Widgets (Customizable)
- **Files**: `QuoteWidgetConfigurable.swift`, `AffirmationWidgetConfigurable.swift`
- **Refresh**: User chooses - Every Minute, Every Hour, or Every Day
- **User Control**: Full control over refresh frequency
- **Best For**: Users who want to customize their widget experience

## Setup Instructions

### Option A: Static Widgets Only (Simpler)

1. **Add Widget Extension Target**
   - File > New > Target > Widget Extension
   - Name: `MuseWidgets`
   - **UNCHECK** "Include Configuration Intent"
   - Finish

2. **Configure App Groups** (for both targets)
   - Add App Groups capability
   - Add: `group.Ephesian28LLC.Muse`

3. **Add Files to Widget Target**
   - `Widgets/MuseWidget.swift`
   - `Widgets/QuoteWidget/QuoteWidget.swift`
   - `Widgets/AffirmationWidget/AffirmationWidget.swift`
   - `Widgets/Shared/SharedDataService.swift`
   - `Widgets/Shared/Models.swift`
   - `Widgets/Shared/Color+Hex.swift`

### Option B: Configurable Widgets (More Features)

1. **Add Widget Extension Target**
   - File > New > Target > Widget Extension
   - Name: `MuseWidgets`
   - **CHECK** "Include Configuration Intent" ✅
   - Finish

2. **Configure App Groups** (for both targets)
   - Add App Groups capability
   - Add: `group.Ephesian28LLC.Muse`

3. **Add Files to Widget Target**
   - `Widgets/MuseWidget.swift`
   - `Widgets/QuoteWidget/QuoteWidget.swift`
   - `Widgets/QuoteWidget/QuoteWidgetConfigurable.swift`
   - `Widgets/AffirmationWidget/AffirmationWidget.swift`
   - `Widgets/AffirmationWidget/AffirmationWidgetConfigurable.swift`
   - `Widgets/Shared/SharedDataService.swift`
   - `Widgets/Shared/Models.swift`
   - `Widgets/Shared/Color+Hex.swift`

## How Refresh Works

### Static Widgets
- Timeline creates 24 entries (one per hour)
- Widget automatically refreshes when each entry's date is reached
- iOS handles the refresh based on system "wakes" and battery optimization

### Configurable Widgets
- Timeline creates entries based on user's selected frequency
- User can choose:
  - **Every Minute**: 60 entries (1 hour ahead)
  - **Every Hour**: 24 entries (24 hours ahead)
  - **Every Day**: 7 entries (7 days ahead)
- iOS respects the timeline policy and refreshes accordingly

## Important Notes

⚠️ **iOS Widget Refresh Limitations:**
- iOS controls when widgets actually refresh based on:
  - System "wakes" (when device is active)
  - Battery optimization
  - User activity patterns
- **Every minute** refresh may not actually update every minute - iOS may batch updates
- **Every hour** and **Every day** are more reliable
- Widgets refresh more reliably when:
  - Device is unlocked
  - User is actively using the device
  - Widget is visible on screen

## Recommendation

I recommend using **Configurable Widgets** (Option B) because:
1. Users get choice and control
2. More flexible for different use cases
3. Still includes the simple static widgets as fallback
4. Better user experience overall

The configurable widgets will show a settings screen when users add the widget, allowing them to choose their preferred refresh frequency.


