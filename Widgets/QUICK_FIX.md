# Quick Fix for Widget Preview Error

## The Problem
Xcode can't preview the widget because it doesn't know which widget bundle to use.

## The Solution (30 seconds)

1. **Click the scheme selector** (top-left, next to play button)
2. **Select "Edit Scheme..."**
3. **Select "Run"** in left sidebar (under MuseWidgetsExtension)
4. **Click "Arguments" tab**
5. **Under "Environment Variables"**, click **+**
6. **Add:**
   - Name: `__WidgetKind` (two underscores!)
   - Value: `MuseWidgets`
7. **Click "Close"**
8. **Try running the widget again**

## Alternative: Skip Preview, Test on Device

Instead of fighting with previews:
1. **Build and run the main app** (not widget extension)
2. **Save some quotes/affirmations** in the app
3. **Long-press home screen** → Tap **+**
4. **Search "Muse"** → Add widgets
5. **Widgets will work!** ✅

The preview is just for development - the widgets will work fine when added to the home screen!

