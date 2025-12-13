# Muse Widgets Setup Guide

This guide will help you set up the widget extension for the Muse app.

## Step 1: Add Widget Extension Target in Xcode

1. Open your project in Xcode
2. Go to **File > New > Target...**
3. Select **Widget Extension** under iOS
4. Click **Next**
5. Name it: `MuseWidgets`
6. Make sure **Include Configuration Intent** is **UNCHECKED** (we're using static configuration)
7. Click **Finish**
8. When prompted, click **Activate** to activate the scheme

## Step 2: Configure App Groups

### For Main App Target:
1. Select the **Muse** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.Ephesian28LLC.Muse`
6. Make sure it's checked/enabled

### For Widget Extension Target:
1. Select the **MuseWidgets** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Add the same group: `group.Ephesian28LLC.Muse`
6. Make sure it's checked/enabled

## Step 3: Add Files to Widget Extension

1. In Xcode, select the **MuseWidgets** target
2. Go to **Build Phases** > **Compile Sources**
3. Add these files to the widget target:
   - `Widgets/Shared/SharedDataService.swift`
   - `Widgets/Shared/Models.swift`
   - `Widgets/Shared/Color+Hex.swift`
   - `Widgets/MuseWidget.swift`
   - `Widgets/QuoteWidget/QuoteWidget.swift`
   - `Widgets/AffirmationWidget/AffirmationWidget.swift`

## Step 4: Update Widget Extension Info.plist

1. Select the **MuseWidgets** target
2. Go to **Info** tab
3. Make sure the bundle identifier is: `Ephesian28LLC.Muse.MuseWidgets`

## Step 5: Update StorageService

The `StorageService.swift` has been updated to automatically sync data to the App Group UserDefaults when quotes or affirmations are saved/removed.

## Step 6: Build and Test

1. Build the project (⌘B)
2. Run the app on a device or simulator
3. Save some quotes or affirmations
4. Long-press on the home screen
5. Tap the **+** button in the top-left
6. Search for "Muse" and add the widgets!

## Widget Features

- **Quote Widget**: Displays random saved quotes, refreshes hourly
- **Affirmation Widget**: Displays random saved affirmations, refreshes hourly
- **Multiple Sizes**: Supports small, medium, and large widget sizes
- **Glassmorphism Design**: Matches the app's design system

## Troubleshooting

- If widgets show "No data", make sure:
  1. App Groups are configured correctly for both targets
  2. You have saved at least one quote or affirmation in the app
  3. The widget extension has the correct bundle identifier


