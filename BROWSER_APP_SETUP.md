# Browser App Setup Guide

All the scripts for the Browser App have been created. Now you need to set up the scenes and resources in the Godot editor.

## Files Created

### Scripts
- `scripts/apps/app_browser/history_entry.gd` - Data model for a single history entry
- `scripts/apps/app_browser/browser_history.gd` - Collection of history entries
- `scripts/apps/app_browser/history_entry_button.gd` - UI component for each history item
- `scripts/apps/app_browser/browser_app_manager.gd` - Business logic and search
- `scripts/apps/app_browser/browser_app_ui.gd` - UI management

### Modified Files
- `scripts/autoload/db.gd` - Added browser_history export variable

---

## Step-by-Step Setup in Godot Editor

### 1. Create History Entry Resources

First, create some sample history entries:

1. In the FileSystem panel, navigate to `resources/` and create a new folder: `browser_history/`
2. In `resources/browser_history/`, create a new Resource:
   - Right-click → New Resource → Search for "Resource" → Select it
   - In the Inspector, click on the "Script" dropdown and select `history_entry.gd`
   - Fill in the exported properties:
     - `url`: "https://godotengine.org"
     - `title`: "Godot Engine - Free and open source 2D and 3D game engine"
     - `timestamp`: "2026-01-28 14:30"
     - `description`: "Official Godot Engine website"
   - Save as `resources/browser_history/entry_godot.tres`

3. Repeat to create 5-10 sample entries (examples):
   - `entry_github.tres` - "https://github.com", "GitHub", etc.
   - `entry_youtube.tres` - "https://youtube.com", "YouTube", etc.
   - `entry_reddit.tres` - "https://reddit.com", "Reddit", etc.

### 2. Create Browser History Collection Resource

1. In `resources/browser_history/`, create a new Resource
2. In the Inspector, set the Script to `browser_history.gd`
3. In the `history_entries` array:
   - Set the array size to match your number of entries (e.g., 5)
   - Drag each history entry resource you created into the array slots
4. Save as `resources/browser_history/browser_history_main.tres`

### 3. Create HistoryEntryButton Scene

1. Create a new Scene with root node: **HBoxContainer**
2. Rename it to `HistoryEntryButton`
3. Add the following children:
   ```
   HistoryEntryButton (HBoxContainer)
   ├── FaviconTexture (TextureRect)
   │   └── Custom Minimum Size: 32x32
   │   └── Expand Mode: Keep Aspect Centered
   ├── ContentVBox (VBoxContainer)
   │   ├── TitleLabel (Label)
   │   │   └── Theme Overrides > Font Sizes > Font Size: 14
   │   │   └── Autowrap Mode: Word (Smart)
   │   └── URLLabel (Label)
   │       └── Theme Overrides > Font Sizes > Font Size: 10
   │       └── Theme Overrides > Colors > Font Color: Gray
   ├── Spacer (Control)
   │   └── Size Flags Horizontal: Expand Fill
   ├── TimestampLabel (Label)
   │   └── Vertical Alignment: Center
   └── OpenButton (Button)
       └── Text: "Open"
   ```

4. Attach the script `history_entry_button.gd` to the root HBoxContainer node
5. Verify the @onready paths match your node names
6. Save as `scenes/apps/app_browser/history_entry_button.tscn`

### 4. Create BrowserAppUI Scene

1. Create a new Scene with root node: **Control**
2. Rename it to `BrowserAppUI`
3. Add the following structure:
   ```
   BrowserAppUI (Control)
   ├── SearchBar (HBoxContainer)
   │   ├── SearchInput (LineEdit)
   │   │   └── Placeholder Text: "Search history..."
   │   │   └── Size Flags Horizontal: Expand Fill
   │   ├── SearchButton (Button)
   │   │   └── Text: "Search"
   │   └── ClearButton (Button)
   │       └── Text: "Clear"
   └── HistoryScrollContainer (ScrollContainer)
       └── HistoryListContainer (VBoxContainer)
           └── Size Flags Horizontal: Expand Fill
   ```

4. Set `BrowserAppUI` layout:
   - Layout: Full Rect (anchor all edges to parent)

5. Set `SearchBar` properties:
   - Add some margin/padding if desired

6. Attach the script `browser_app_ui.gd` to the root Control node
7. Save as `scenes/apps/app_browser/browser_app_ui.tscn`

### 5. Create BrowserAppManager Scene

1. Create a new Scene with root node: **Control**
2. Rename it to `BrowserAppManager`
3. Attach the script `browser_app_manager.gd` to it
4. Add a child node: **Instance the BrowserAppUI scene** you just created
   - Right-click BrowserAppManager → Instantiate Child Scene → Select `browser_app_ui.tscn`
   - It should be named `BrowserAppUI`

5. In the Inspector for `BrowserAppManager`:
   - Set `Browser History`: Drag `resources/browser_history/browser_history_main.tres`
   - Set `History Entry Button Scene`: Drag `scenes/apps/app_browser/history_entry_button.tscn`

6. Save as `scenes/apps/app_browser/browser_app_manager.tscn`

### 6. Create BrowserApp Scene (Main App Scene)

1. Create a new Scene with root node: **Panel** (or the base type you use for apps)
2. Rename it to `BrowserApp`
3. Attach the script (if you have an `AppBase` script, inherit from it):
   - You may need to create `browser_app.gd` that extends `AppBase`
   - Set the `app_id` and `app_title` exports

4. Instance `BrowserAppManager` as a child:
   - Right-click BrowserApp → Instantiate Child Scene → Select `browser_app_manager.tscn`

5. Configure the Panel/AppBase properties:
   - Set appropriate size
   - Set app_id: "browser"
   - Set app_title: "Browser"

6. Save as `scenes/apps/app_browser/browser_app.tscn`

### 7. Register Browser App in Computer Screen

1. Open your main computer screen scene or app manager scene
2. Find where apps are registered (look for APP_SCENES dictionary or similar)
3. Add the browser app to the available apps list
4. You may need to create an app icon for the desktop/launcher

### 8. Update Database Singleton

1. Open the Database node in the Scene tree (it's an autoload)
2. In the Inspector, find the new `Browser History` export variable
3. Drag `resources/browser_history/browser_history_main.tres` into this field
4. Save the scene

---

## Testing

1. Run your project
2. Open the Browser App from the computer desktop/launcher
3. You should see:
   - A search bar at the top
   - List of all history entries below
   - Each entry showing title, URL, and timestamp
   - An "Open" button that opens the URL in your default browser

4. Test search functionality:
   - Type text in the search bar
   - Click "Search" or press Enter
   - The list should filter to show only matching entries
   - Click "Clear" to reset

---

## Optional Enhancements

### Add Favicons
- Create small icon images (32x32 or 16x16) for different websites
- Add them to `assets/images/favicons/`
- Set the `favicon` property in each HistoryEntry resource

### Improve Styling
- Add custom theme/styling to the buttons and labels
- Add hover effects
- Add separators between entries
- Customize colors

### Add Sorting
- Add buttons to sort by date, alphabetically, etc.
- Modify `browser_app_manager.gd` to implement sorting logic

### Add Categories/Tags
- Extend HistoryEntry to include categories or tags
- Add filter buttons for different categories

---

## Troubleshooting

**Error: "BrowserAppUI is missing signal search_requested()"**
- Make sure `browser_app_ui.gd` is attached to the UI scene
- Verify the signals are defined at the top of the script

**Error: "browser_history is null or empty!"**
- Check that you've created the browser_history resource
- Verify it's assigned in the BrowserAppManager inspector
- Make sure the history_entries array has items

**History entries don't show up**
- Check the console for errors
- Verify `history_entry_button.tscn` is assigned in BrowserAppManager
- Check that node names in the button scene match the @onready paths

**Search doesn't work**
- Check that SearchInput and SearchButton are connected in `browser_app_ui.gd`
- Verify the signal connections in the _ready() function
- Test by adding print statements to see if signals are firing

---

## File Structure Summary

```
scripts/apps/app_browser/
├── history_entry.gd
├── browser_history.gd
├── history_entry_button.gd
├── browser_app_manager.gd
└── browser_app_ui.gd

scenes/apps/app_browser/
├── history_entry_button.tscn
├── browser_app_ui.tscn
├── browser_app_manager.tscn
└── browser_app.tscn

resources/browser_history/
├── entry_godot.tres
├── entry_github.tres
├── (more entry resources)
└── browser_history_main.tres
```

Good luck! Let me know if you encounter any issues.
