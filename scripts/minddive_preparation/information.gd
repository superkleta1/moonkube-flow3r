extends Resource
class_name Information

## Information - Collectible lore/story entries
## Used for Codex entries representing knowledge, facts, or story fragments

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String

## Codex-specific fields
@export var card_front_image: Texture2D = null  # Image shown when unlocked in Codex
@export var category: String = "general"        # e.g., "characters", "locations", "events"
@export var unlock_hint: String = ""            # Hint text shown on locked cards

## Runtime state - managed by CodexManager
var is_unlocked: bool = false
var unlock_timestamp: int = 0  # Unix timestamp when unlocked
var is_newly_unlocked: bool = false  # For highlight effect
