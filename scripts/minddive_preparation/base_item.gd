extends Resource
class_name BaseItem

## Base Item - Collectible physical items
## Used for minddive preparation and Codex entries

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String

@export_range(0, 3, 1) var slot_count: int = 0

## Codex-specific fields
@export var card_front_image: Texture2D = null  # Image shown when unlocked in Codex
@export var unlock_hint: String = ""            # Hint text shown on locked cards

## Runtime state - managed by CodexManager
var is_unlocked: bool = false
var unlock_timestamp: int = 0  # Unix timestamp when unlocked
var is_newly_unlocked: bool = false  # For highlight effect
