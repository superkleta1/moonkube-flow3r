# Codex Implementation Summary

## What's Been Implemented

### Core Resources
- [base_item.gd](scripts/minddive_preparation/base_item.gd) - Resource for physical collectible items (also used for minddive preparation)
- [information.gd](scripts/minddive_preparation/information.gd) - Resource for lore/story entries

### Manager System
- [codex_manager.gd](scripts/autoload/codex_manager.gd) - Global singleton for tracking unlocks
  - Register entries
  - Unlock entries by ID or from content resources
  - Track newly unlocked entries
  - Save/load progress
  - Provide debug commands (unlock_all, reset_progress)

### UI Components
- [codex_card.gd](scripts/apps/app_codex/codex_card.gd) - Card UI with locked/unlocked states
- [codex_detail_viewer.gd](scripts/apps/app_codex/codex_detail_viewer.gd) - Detail view modal
- [codex_app_manager.gd](scripts/apps/app_codex/codex_app_manager.gd) - Main Codex app with tabs

### Integration Points
All existing apps now trigger codex unlocks:
- **MusicApp** - Unlocks when songs play ([app_music_manager.gd:66,85,97](scripts/apps/app_music/app_music_manager.gd))
- **AlbumApp** - Unlocks when albums open and photos viewed ([app_album_ui_manager.gd:19,51](scripts/apps/app_album/app_album_ui_manager.gd))
- **BrowserApp** - Unlocks when pages visited ([browser_app_ui.gd:97](scripts/apps/app_browser/browser_app_ui.gd))

### Updated Resources
Added `codex_entries` array to:
- [song.gd](scripts/apps/app_music/song.gd)
- [photo.gd](scripts/apps/app_album/photo.gd)
- [albums.gd](scripts/apps/app_album/albums.gd)
- [history_entry.gd](scripts/apps/app_browser/history_entry.gd)

---

## What You Need to Do Next

### 1. Add CodexManager as Autoload (REQUIRED)
**This is the most important step!**

1. Open Godot
2. Go to **Project -> Project Settings -> Autoload**
3. Click the folder icon and select: `res://scripts/autoload/codex_manager.gd`
4. Set Node Name to: `CodexManager`
5. Click **Add**
6. Click **Close**

This will fix all the "CodexManager not declared" errors.

### 2. Create the UI Scenes

You need to create 3 scene files (.tscn) in the Godot editor:

#### A. CodexCard Scene
- **Path**: `res://scenes/apps/codex/codex_card.tscn`
- **Root**: TextureButton with script `codex_card.gd`
- **Children**:
  - TextureRect (name: CardImage)
  - Panel (name: HighlightOverlay) - for the "new" glow effect
  - Label (name: LockedLabel) - shows "???" for locked cards

#### B. CodexDetailViewer Scene
- **Path**: `res://scenes/apps/codex/codex_detail_viewer.tscn`
- **Root**: Control with script `codex_detail_viewer.gd`
- **Children**: See detailed structure in CODEX_SETUP_GUIDE.md

#### C. CodexApp Scene
- **Path**: `res://scenes/apps/codex/codex_app.tscn`
- **Root**: Control with script `codex_app_manager.gd`
- **Main Structure**: TabContainer with "Base Items" and "Information" tabs
- **Each Tab**: Label (counter) + ScrollContainer + GridContainer
- **Important**: Set the export variables to point to your card and detail viewer scenes

### 3. Create Example Codex Entries

Create a few test resources to verify everything works:

1. Right-click in FileSystem -> New Resource -> Search "BaseItem"
2. Fill in properties (id, display_name, description, card_front_image, etc.)
3. Save as `res://resources/codex/base_items/test_item.tres`
4. Repeat for Information

### 4. Link Entries to Content

Open an existing Song/Photo/Album resource and:
1. Find the `codex_entries` array
2. Drag your test codex entry into the array
3. Save

### 5. Register Entries

**Easiest way** - just load from directories:
```gdscript
# res://scripts/autoload/codex_loader.gd
extends Node

func _ready() -> void:
    # Automatically loads all .tres files from these directories!
    CodexManager.load_base_items_from_directory("res://resources/codex/base_items/")
    CodexManager.load_information_from_directory("res://resources/codex/information/")
```
Then add as autoload (make sure it loads AFTER CodexManager).

**Alternative** - register from arrays:
```gdscript
func _ready() -> void:
    CodexManager.register_base_items([
        preload("res://resources/codex/base_items/test_item.tres"),
        # Add more...
    ])
```

### 6. Test!

1. Run the game
2. Interact with content that has codex entries
3. Open the Codex app
4. Verify entries unlock and display correctly

---

## Architecture Overview

```
Content Interaction (Song plays, Photo viewed, etc.)
    |
    v
CodexManager.unlock_entries_from_content()
    |
    v
Checks codex_entries array on resource
    |
    v
For each entry: CodexManager.unlock_entry(id)
    |
    v
Updates entry state (is_unlocked = true)
    |
    v
Saves progress to user://codex_progress.save
    |
    v
Emits entry_unlocked signal
    |
    v
CodexApp listens and refreshes UI
```

---

## Key Features

- **Two Categories**: Base Items (objects) and Information (lore)
- **Lock/Unlock System**: Cards show "???" when locked, image when unlocked
- **Highlight Effect**: Newly unlocked cards have a visual indicator
- **Progress Tracking**: "Unlocked: X / Y" counters
- **Persistent Save**: Progress saved to disk automatically
- **Flexible Integration**: Easy to add codex entries to any content
- **Manager Pattern**: Centralized unlock logic via CodexManager singleton
- **Detail View**: Click cards to see full information
- **Easy Registration**: Load entire directories with one line of code!
- **Shared Resources**: BaseItem and Information are also used for minddive preparation

---

## File Reference

### Resource Classes
```
scripts/minddive_preparation/
|- base_item.gd      # BaseItem class (collectibles + minddive items)
|- information.gd    # Information class (lore entries)
```

### Codex System Files
```
scripts/
|- autoload/
|  - codex_manager.gd
- apps/
   - app_codex/
      |- codex_app_manager.gd
      |- codex_card.gd
      - codex_detail_viewer.gd
```

### Modified Files
```
scripts/apps/
|- app_music/
|  |- song.gd (added codex_entries)
|  - app_music_manager.gd (added unlock triggers)
|- app_album/
|  |- photo.gd (added codex_entries)
|  |- albums.gd (added codex_entries)
|  - app_album_ui_manager.gd (added unlock triggers)
- app_browser/
   |- history_entry.gd (added codex_entries)
   - browser_app_ui.gd (added unlock triggers)
```

---

## Tips for Getting Started

1. Start small - create 2-3 test entries first
2. Use placeholder images initially (can be simple colored rectangles)
3. Test the unlock flow before creating lots of content
4. Once verified, bulk create your codex entries
5. Consider creating a spreadsheet to plan all your entries and their unlock conditions

---

## Additional Resources

See [CODEX_SETUP_GUIDE.md](CODEX_SETUP_GUIDE.md) for:
- Detailed UI scene setup instructions
- Best practices and tips
- Troubleshooting guide
- Recommended file structure

---

## Next Steps

1. **Add CodexManager autoload** <- Start here!
2. Create the 3 UI scenes
3. Create a few test codex entries
4. Link them to existing content
5. Register them with CodexManager
6. Test and iterate!

Good luck with your Codex implementation! <3
