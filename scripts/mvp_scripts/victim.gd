extends Node2D
class_name Victim

var game_manager: MindDiveGameManagerMVP
var current_cell: Vector2i

@export_range(0.0, 1.0, 0.01) var inspired: float = 0.5
@export_range(0.0, 1.0, 0.01) var laziness: float = 0.5

func reset_to(cell: Vector2i) -> void:
	current_cell = cell
	if game_manager != null:
		global_position = game_manager.cell_to_world(cell)

func step_once() -> void:
	if game_manager == null:
		return

	var next_cell: Vector2i = game_manager.choose_next_cell(current_cell)
	if next_cell == current_cell:
		return

	current_cell = next_cell
	global_position = game_manager.cell_to_world(next_cell)
	game_manager.on_victim_enter_cell(next_cell)
