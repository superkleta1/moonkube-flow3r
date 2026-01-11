extends Resource
class_name BaseItem

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var description: String

@export_range(0, 3, 1) var slot_count: int = 0
