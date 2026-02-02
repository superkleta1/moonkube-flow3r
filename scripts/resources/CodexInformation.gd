extends Resource
class_name CodexInformation

## Codex Information - Collectible lore/story entries for the Codex
## These represent knowledge, facts, or story fragments discovered in the game

@export var entry_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var card_front_image: Texture2D = null  # Icon/image shown when unlocked
@export var card_back_image: Texture2D = null   # Image shown when locked (can be generic)
@export var category: String = "general"        # e.g., "characters", "locations", "events"
@export var unlock_hint: String = ""            # Hint text shown on locked cards

## Runtime state - managed by CodexManager
var is_unlocked: bool = false
var unlock_timestamp: int = 0  # Unix timestamp when unlocked
var is_newly_unlocked: bool = false  # For highlight effect
