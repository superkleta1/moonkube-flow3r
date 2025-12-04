# scripts/minddive_item.gd
extends Resource
class_name MindDiveItem

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var base_attraction: float = 1.0

# Optional: Narrative “keywords”, can be used for interaction rules later
@export var tags: Array[String] = []   # e.g. ["childhood", "guilt", "door_opener"]

# Optional: interaction rules (you can ignore for now)
# Example idea: { "near_tag:door": 0.5, "adjacent_tag:childhood": 1.0 }
@export var interaction_rules: Dictionary = {}
