extends Resource
class_name CodexBaseItem

## Codex Base Item - Collectible physical items for the Codex
## These represent physical objects, artworks, or items discovered in the game

@export var entry_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var card_front_image: Texture2D = null  # Image shown when unlocked
@export var card_back_image: Texture2D = null   # Image shown when locked (can be generic)
@export var rarity: String = "common"           # e.g., "common", "rare", "legendary"
@export var unlock_hint: String = ""            # Hint text shown on locked cards

## Runtime state - managed by CodexManager
var is_unlocked: bool = false
var unlock_timestamp: int = 0  # Unix timestamp when unlocked
var is_newly_unlocked: bool = false  # For highlight effect
