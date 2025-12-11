# scripts/minddive_item.gd
extends Resource
class_name MindDiveItem

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var base_attraction: float = 1.0

@export var tags: Array[String] = []   # e.g. ["childhood", "guilt", "door_opener"]

# for now to keep things simple, only gonna do easy arithmetics
# {String: String ("+-*/")}
# use Expression class to parse
@export var tag_interaction_rules: Dictionary[String, String] = {}
@export var item_interaction_rules: Dictionary[String, String] = {}
