# Fix Widget Preview Error

## Error
```
Invalid requested widget kind: 'QuoteWidget'. Please specify one of: 'MuseWidgets', 'Ephesian28LLC.Muse.MuseWidgets' in your scheme's Environment Variables using the key '__WidgetKind'.
```

## Solution: Configure Widget Scheme

### Step 1: Edit the Widget Extension Scheme

1. In Xcode, click on the **scheme selector** (next to the stop/play buttons at the top)
2. Select **Edit Scheme...**
3. In the left sidebar, select **Run** (under MuseWidgetsExtension)
4. Click the **Arguments** tab
5. Under **Environment Variables**, click the **+** button
6. Add:
   - **Name**: `__WidgetKind` (two underscores!)
   - **Value**: `MuseWidgets` (or `Ephesian28LLC.Muse.MuseWidgets`)

### Important Notes

- The environment variable name is `__WidgetKind` with **TWO underscores**
- The value should be `MuseWidgets` (the widget bundle name) or the full bundle identifier
- This is different from the individual widget kinds like `QuoteWidget`

### Step 3: Test Different Widgets

To preview different widgets:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Change the `_XCWidgetKind` value to the widget you want to preview
3. Run the widget extension

### Alternative: Run on Device/Simulator

Instead of previewing, you can:
1. Build and run the main app
2. Save some quotes/affirmations
3. Long-press home screen → + → Search "Muse"
4. Add the widgets directly

This way you don't need to configure the scheme for previewing.

