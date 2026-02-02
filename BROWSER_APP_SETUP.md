# Browser App Setup Guide (Updated)

All the scripts for the Browser App have been created with the new page navigation system. Now you need to set up the scenes and resources in the Godot editor.

## Files Created

### Scripts
- `scripts/apps/app_browser/history_entry.gd` - Data model for a single history entry (now includes `page_scene` field)
- `scripts/apps/app_browser/browser_history.gd` - Collection of history entries
- `scripts/apps/app_browser/history_entry_button.gd` - UI component for each history item
- `scripts/apps/app_browser/browser_app_manager.gd` - Business logic, search, and navigation
- `scripts/apps/app_browser/browser_app_ui.gd` - UI management with three views (history, search results, page viewer)
- `scripts/apps/app_browser/page_base.gd` - Base class for individual page scenes

### Modified Files
- `scripts/autoload/db.gd` - Added `browser_history` export variable

---

## Key Features

### 1. History View
- Shows all browser history entries
- Each entry has an "Open" button that navigates to its page scene

### 2. Search Results View
- Appears when you search for something
- Shows filtered results matching the search query
- Clicking entries opens their page scenes
- "Back to History" button returns to the history view

### 3. Page Viewer
- Displays the actual page content (PackedScene)
- Your UI/UX designer creates custom page scenes
- Pages can extend `PageBase` to get back navigation functionality
- Automatically returns to previous view when closed

---

## Step-by-Step Setup in Godot Editor

### 1. Create Sample Page Scenes

**IMPORTANT:** Your UI/UX designer will create the actual page content scenes. For now, let's create a simple template:

1. Create a new Scene with root node: **Control**
2. Rename it to `SamplePage`
3. Attach the script `page_base.gd` to it
4. Add a simple structure:
   ```
   SamplePage (Control) [extends PageBase]
   ├── ColorRect (ColorRect)
   │   └── Layout: Full Rect
   │   └── Color: Choose any color
   ├── BackButton (Button)
   │   └── Text: "← Back"
   │   └── Position: Top-left corner
   └── ContentLabel (Label)
       └── Text: "Sample Page Content"
       └── Position: Center
   ```

5. In the script editor, modify the scene's script to connect the back button:
   ```gdscript
   extends PageBase

   @onready var back_button: Button = $BackButton

   func _ready() -> void:
       super._ready()  # Call parent _ready
       back_button.pressed.connect(_on_back_pressed)

   func _on_back_pressed() -> void:
       close_page()  # This emits back_pressed signal
   ```

6. Save as `scenes/apps/app_browser/pages/sample_page.tscn`

7. Create a few variations (e.g., `godot_page.tscn`, `github_page.tscn`) with different colors/content

### 2. Create History Entry Resources

1. In the FileSystem panel, navigate to `resources/` and create: `browser_history/`
2. In `resources/browser_history/`, create a new Resource:
   - Right-click → New Resource → Select "Resource"
   - In the Inspector, set Script to `history_entry.gd`
   - Fill in the exported properties:
     - `url`: "https://godotengine.org"
     - `title`: "Godot Engine - Free and open source 2D and 3D game engine"
     - `timestamp`: "2026-01-28 14:30"
     - `description`: "Official Godot Engine website"
     - **`page_scene`**: Drag `scenes/apps/app_browser/pages/godot_page.tscn` here
   - Save as `resources/browser_history/entry_godot.tres`

3. Create 5-10 sample entries:
   - `entry_github.tres` - "https://github.com", "GitHub", `github_page.tscn`, etc.
   - `entry_youtube.tres` - "https://youtube.com", "YouTube", `sample_page.tscn`, etc.
   - Each entry should have a `page_scene` assigned!

### 3. Create Browser History Collection Resource

1. In `resources/browser_history/`, create a new Resource
2. Set Script to `browser_history.gd`
3. In the `history_entries` array:
   - Set array size to match your entries (e.g., 5)
   - Drag each history entry resource into the array slots
4. Save as `resources/browser_history/browser_history_main.tres`

### 4. Create HistoryEntryButton Scene

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

4. Attach the script `history_entry_button.gd` to the root HBoxContainer
5. Verify @onready paths match node names
6. Save as `scenes/apps/app_browser/history_entry_button.tscn`

### 5. Create BrowserAppUI Scene

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
   │
   ├── HistoryViewContainer (Control)
   │   └── Layout: Full Rect (below SearchBar)
   │   └── HistoryScrollContainer (ScrollContainer)
   │       └── HistoryListContainer (VBoxContainer)
   │           └── Size Flags Horizontal: Expand Fill
   │
   ├── SearchResultsViewContainer (Control)
   │   └── Layout: Full Rect (below SearchBar)
   │   └── Visible: false
   │   ├── SearchResultsTitle (Label)
   │   │   └── Text: "Search results for: ..."
   │   ├── BackToHistoryButton (Button)
   │   │   └── Text: "← Back to History"
   │   └── SearchResultsScrollContainer (ScrollContainer)
   │       └── SearchResultsListContainer (VBoxContainer)
   │           └── Size Flags Horizontal: Expand Fill
   │
   └── PageViewerAnchor (Control)
       └── Layout: Full Rect
       └── Visible: false
   ```

4. Set `BrowserAppUI` layout: Full Rect
5. Position `SearchBar` at the top with proper margins
6. Make sure the three view containers (History, SearchResults, PageViewer) occupy the space below SearchBar
7. Attach the script `browser_app_ui.gd` to the root Control node
8. Save as `scenes/apps/app_browser/browser_app_ui.tscn`

### 6. Create BrowserAppManager Scene

1. Create a new Scene with root node: **Control**
2. Rename it to `BrowserAppManager`
3. Attach the script `browser_app_manager.gd` to it
4. Instance the BrowserAppUI scene:
   - Right-click BrowserAppManager → Instantiate Child Scene
   - Select `browser_app_ui.tscn`
   - Should be named `BrowserAppUI`

5. In the Inspector for `BrowserAppManager`:
   - **Browser History**: Drag `resources/browser_history/browser_history_main.tres`
   - **History Entry Button Scene**: Drag `scenes/apps/app_browser/history_entry_button.tscn`

6. Save as `scenes/apps/app_browser/browser_app_manager.tscn`

### 7. Update Database Singleton

1. In the Scene tree, find the Database autoload node (or open the Database scene)
2. In the Inspector, find the `Browser History` export variable
3. Drag `resources/browser_history/browser_history_main.tres` into this field
4. Save the scene

---

## Testing

### Test 1: History View
1. Run your project
2. Open the Browser App (you'll need to instance the BrowserAppManager scene for testing)
3. You should see:
   - Search bar at the top
   - List of all history entries below
   - Each entry showing title, URL, timestamp
   - "Open" button on each entry

### Test 2: Opening Pages
1. Click "Open" on any history entry
2. The page scene should appear (covering the history view)
3. Click the "Back" button in the page
4. You should return to the history view

### Test 3: Search
1. Type something in the search bar (e.g., "godot")
2. Click "Search" or press Enter
3. Search results view should appear showing:
   - "Search results for: godot" title
   - "Back to History" button
   - Filtered list of matching entries
4. Click an entry to open its page
5. Click back to return to search results
6. Click "Back to History" to return to main history view

### Test 4: Clear Search
1. After searching, click "Clear" button
2. Should return to the history view with all entries

---

## For Your UI/UX Designer

When creating page scenes:

### Option 1: Extend PageBase (Recommended)
```gdscript
extends PageBase

@onready var back_button: Button = $BackButton

func _ready() -> void:
    super._ready()
    back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
    close_page()  # Emits back_pressed signal
```

### Option 2: Manual Signal
If not extending PageBase, just add this signal:
```gdscript
extends Control

signal back_pressed()

func close_page() -> void:
    back_pressed.emit()
```

The BrowserAppUI will automatically detect and connect to the `back_pressed` signal.

---

## Architecture Overview

```
User Flow:
1. [History View] → Click "Open" → [Page Viewer]
2. [History View] → Type & Search → [Search Results View]
3. [Search Results View] → Click entry → [Page Viewer]
4. [Page Viewer] → Click "Back" → [Previous View]
5. [Search Results View] → Click "Back to History" → [History View]

Signal Flow:
BrowserAppUI.search_requested
  → BrowserAppManager._on_search_requested
  → BrowserAppManager.show_search_results
  → BrowserAppUI._on_show_search_results

BrowserAppUI.entry_clicked
  → BrowserAppManager._on_entry_clicked
  → BrowserAppManager.show_page
  → BrowserAppUI._on_show_page
  → Instantiates page_scene
  → Connects to page.back_pressed
  → BrowserAppUI.close_page_viewer
```

---

## Troubleshooting

**Pages don't appear when clicking "Open"**
- Check that each HistoryEntry has a `page_scene` assigned
- Look for errors in the console: "Entry has no page_scene assigned!"
- Verify the page scene path is correct

**Back button doesn't work on pages**
- Make sure the page extends `PageBase` or has `signal back_pressed()`
- Check that the back button calls `close_page()`
- Verify the signal is being connected in BrowserAppUI._on_show_page

**Search results don't appear**
- Check that SearchResultsViewContainer is properly set up in the UI scene
- Verify the node names match the @onready paths in browser_app_ui.gd
- Check console for connection warnings

**Can't return to previous view**
- Check that view visibility is being managed correctly
- Add debug prints to _show_history_view, _on_show_search_results, etc.
- Verify signal connections are working

---

## File Structure Summary

```
scripts/apps/app_browser/
├── history_entry.gd (includes page_scene field)
├── browser_history.gd
├── history_entry_button.gd
├── browser_app_manager.gd (handles navigation signals)
├── browser_app_ui.gd (manages three views)
└── page_base.gd (base class for pages)

scenes/apps/app_browser/
├── history_entry_button.tscn
├── browser_app_ui.tscn (3 view containers)
├── browser_app_manager.tscn
└── pages/
    ├── sample_page.tscn
    ├── godot_page.tscn
    └── (more page scenes by UI/UX designer)

resources/browser_history/
├── entry_godot.tres (includes page_scene reference)
├── entry_github.tres
├── (more entry resources)
└── browser_history_main.tres
```

Good luck! The browser app now has proper page navigation and search results views.
