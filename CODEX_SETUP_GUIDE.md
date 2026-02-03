# Codex System Setup Guide

The Codex system allows players to collect and view Base Items and Information entries as they explore your game. This guide will help you set up and use the system.

---

## Setup Checklist

### 1. Add CodexManager as an Autoload

**IMPORTANT:** You must add CodexManager to your project's autoload list:

1. Go to **Project -> Project Settings -> Autoload**
2. Add a new autoload entry:
   - **Path**: `res://scripts/autoload/codex_manager.gd`
   - **Node Name**: `CodexManager`
   - **Enable**: checked
3. Click **Add** and then **Close**

This will make `CodexManager` globally accessible throughout your project.

---

## Creating Codex Entries

### Creating a BaseItem

Base Items represent physical objects, artworks, or collectibles.

1. In the FileSystem, right-click and select **New Resource**
2. Search for `BaseItem` and create it
3. Configure the following properties:
   - **id**: Unique identifier (e.g., `"item_guitar"`)
   - **display_name**: Display name (e.g., `"Acoustic Guitar"`)
   - **description**: Detailed description of the item
   - **icon**: Optional icon texture
   - **card_front_image**: Image shown when unlocked in Codex
   - **unlock_hint**: Hint text shown on locked cards (e.g., `"Play Aki's favorite song"`)
   - **slot_count**: Number of slots (for minddive preparation, 0-3)
4. Save as `res://resources/codex/base_items/item_guitar.tres`

### Creating an Information Entry

Information entries represent lore, facts, or story fragments.

1. In the FileSystem, right-click and select **New Resource**
2. Search for `Information` and create it
3. Configure the following properties:
   - **id**: Unique identifier (e.g., `"info_aki_backstory"`)
   - **display_name**: Display name (e.g., `"Aki's Past"`)
   - **description**: The information content
   - **icon**: Optional icon texture
   - **card_front_image**: Image shown when unlocked in Codex
   - **category**: `"characters"`, `"locations"`, `"events"`, etc.
   - **unlock_hint**: Hint text for locked cards
4. Save as `res://resources/codex/information/info_aki_backstory.tres`

---

## Linking Codex Entries to Content

### Adding Entries to Songs

1. Open a Song resource (e.g., `res://resources/songs/song_colors_flying_high.tres`)
2. Find the **codex_entries** array property
3. Drag and drop your BaseItem or Information resources into the array
4. Save the resource

When this song plays, the linked codex entries will be unlocked!

### Adding Entries to Photos

1. Open a Photo resource
2. Add codex entries to the **codex_entries** array
3. These will unlock when the photo is viewed

### Adding Entries to Albums

1. Open an Album resource
2. Add codex entries to the **codex_entries** array
3. These will unlock when the album is opened

### Adding Entries to Browser History

1. Open a HistoryEntry resource
2. Add codex entries to the **codex_entries** array
3. These will unlock when the page is visited

---

## Registering Codex Entries

Before codex entries can be tracked, they need to be registered with the CodexManager. Choose the method that works best for you:

### Option A: Load from Directory (EASIEST!)

The simplest approach - just point to your directories and all .tres files will be loaded automatically:

```gdscript
# res://scripts/autoload/codex_loader.gd
extends Node

func _ready() -> void:
    # Automatically load all codex entries from directories
    CodexManager.load_base_items_from_directory("res://resources/codex/base_items/")
    CodexManager.load_information_from_directory("res://resources/codex/information/")
```

Then add this script as an autoload (after CodexManager). That's it! No need to preload each file.

### Option B: Register from Arrays

If you want more control or only want to register specific entries:

```gdscript
# In your main scene or autoload
func _ready() -> void:
    # Pass arrays directly - no individual preload() needed!
    CodexManager.register_base_items([
        preload("res://resources/codex/base_items/item_guitar.tres"),
        preload("res://resources/codex/base_items/item_photo.tres"),
    ])

    CodexManager.register_information_entries([
        preload("res://resources/codex/information/info_aki_backstory.tres"),
        preload("res://resources/codex/information/info_location_cafe.tres"),
    ])
```

### Option C: Register Individually

For fine-grained control (rarely needed):

```gdscript
func _ready() -> void:
    var item := preload("res://resources/codex/base_items/item_guitar.tres")
    CodexManager.register_base_item(item)

    var info := preload("res://resources/codex/information/info_aki_backstory.tres")
    CodexManager.register_information(info)
```

---

## Building the Codex UI Scenes

### 1. Create CodexCard Scene

File: `res://scenes/apps/codex/codex_card.tscn`

Structure:
```
TextureButton (root) - Script: codex_card.gd
|- TextureRect (name: CardImage)
|  - Properties: expand_mode = "Ignore Size", stretch_mode = "Keep Aspect Centered"
|- Panel (name: HighlightOverlay)
|  - Properties: visible = false
|  - Add a StyleBox with glowing border for highlight effect
|- Label (name: LockedLabel)
   - Properties: text = "???", align = Center, visible = false
```

Set custom_minimum_size to something like (150, 200) for card dimensions.

### 2. Create CodexDetailViewer Scene

File: `res://scenes/apps/codex/codex_detail_viewer.tscn`

Structure:
```
Control (root, anchors fill screen) - Script: codex_detail_viewer.gd
|- ColorRect (semi-transparent background overlay)
|- PanelContainer (centered modal)
|  - VBoxContainer
|     |- Control (name: ImageContainer)
|     |  - TextureRect (name: EntryImage)
|     |- Label (name: TitleLabel) - large font
|     |- ScrollContainer (name: DescriptionScroll)
|     |  - Label (name: DescriptionLabel)
|     |- Label (name: UnlockInfoLabel) - small font
|- Button (name: ExitButton) - positioned top-right
```

### 3. Create CodexApp Scene

File: `res://scenes/apps/codex/codex_app.tscn`

Structure:
```
Control (root) - Script: codex_app_manager.gd
|- TabContainer (name: TabContainer)
|  |- Control (tab name: "Base Items")
|  |  |- Label (name: CountLabel) - shows "Unlocked: X / Y"
|  |  |- ScrollContainer
|  |     - GridContainer (name: GridContainer)
|  |        - Properties: columns = 4
|  |- Control (tab name: "Information")
|     |- Label (name: CountLabel)
|     |- ScrollContainer
|        - GridContainer (name: GridContainer)
|           - Properties: columns = 4
|- Control (name: DetailViewerAnchor, anchors fill screen)
   - This is where detail viewer instances spawn
```

**Export Variables to Set:**
- **codex_card_scene**: Drag `codex_card.tscn`
- **codex_detail_viewer_scene**: Drag `codex_detail_viewer.tscn`

### 4. Integrate CodexApp into Computer Screen

If you have a computer screen system, add CodexApp to the app list:

```gdscript
# In computerscreen.gd
const APP_SCENES := {
    "music_app": preload("res://scenes/apps/music/MusicApp.tscn"),
    "album_app": preload("res://scenes/apps/album/AlbumApp.tscn"),
    "browser_app": preload("res://scenes/apps/browser/BrowserApp.tscn"),
    "codex_app": preload("res://scenes/apps/codex/CodexApp.tscn"),  # Add this
}
```

---

## Testing the System

### Test Unlock Flow

1. Run your game
2. Play a song that has codex_entries attached
3. Open the Codex app
4. You should see:
   - Newly unlocked cards with a highlight
   - Locked cards showing "???" label
   - Correct unlock counts (e.g., "Unlocked: 1 / 5")

### Debug Commands

You can add debug commands to test the system:

```gdscript
# In your debug console or test scene
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_unlock_all"):
        CodexManager.unlock_all()

    if event.is_action_pressed("debug_reset_codex"):
        CodexManager.reset_progress()
```

---

## Recommended File Structure

```
res://
|- scenes/
|  - apps/
|     - codex/
|        |- CodexApp.tscn
|        |- codex_card.tscn
|        |- codex_detail_viewer.tscn
|- scripts/
|  |- apps/
|  |  - app_codex/
|  |     |- codex_app_manager.gd
|  |     |- codex_card.gd
|  |     |- codex_detail_viewer.gd
|  |- minddive_preparation/
|  |  |- base_item.gd        # BaseItem resource class
|  |  |- information.gd      # Information resource class
|  - autoload/
|     |- codex_manager.gd
|     |- codex_loader.gd (optional)
|- resources/
   - codex/
      |- base_items/
      |  |- item_guitar.tres
      |  |- item_photo.tres
      |  - ...
      - information/
         |- info_aki_backstory.tres
         |- info_location_cafe.tres
         - ...
```

---

## Tips & Best Practices

1. **Card Images**: Create consistent card designs with the same aspect ratio (e.g., 3:4)
2. **Entry IDs**: Use descriptive prefixes like `item_`, `info_`, `char_`, `loc_`
3. **Unlock Hints**: Make hints specific but not spoilery
4. **Categories**: Use consistent category names across your information entries
5. **Testing**: Register a few test entries early to verify the unlock flow

---

## Troubleshooting

### "CodexManager not declared in scope"
- Make sure you added CodexManager as an autoload in Project Settings

### Cards not showing up
- Verify you've called `CodexManager.register_base_item()` or `register_information()`
- Check that id is not empty in your resources

### Entries not unlocking
- Confirm codex_entries array is filled in Song/Photo/Album/HistoryEntry resources
- Check console for any error messages about missing properties

### Highlight not disappearing
- This is normal until the player clicks on the card to view details
- `mark_as_viewed()` is automatically called when viewing details

---

## You're Ready!

The Codex system is now fully set up! Start creating codex entries and linking them to your game content. Players will enjoy discovering and collecting these entries as they explore your game's world!
