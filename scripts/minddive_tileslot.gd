# scripts/minddive_tileslot.gd
extends Node2D
class_name MindDiveTileSlot

@export var grid_x: int
@export var grid_y: int

@export var can_place_item: bool = true
@export var is_start: bool = false
@export var is_door: bool = false
@export var is_exit: bool = false   # where they died

# The item currently placed here (if any)
@export var item: MindDiveItem = null

func has_item() -> bool:
	return item != null
