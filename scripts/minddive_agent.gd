# scripts/minddive_agent.gd
extends Node2D
class_name MindDiveAgent

var current_slot: MindDiveTileSlot
var game_manager: MindDiveGameManager

@export var move_interval: float = 1.0
var _move_timer: float = 0.0

@export var tag_attractions: Dictionary[String, float] = {}

func _process(delta: float) -> void:
	if not game_manager or not current_slot:
		return

	_move_timer -= delta
	if _move_timer <= 0.0:
		_move_timer = move_interval
		_step()

func _step() -> void:
	var next_slot := game_manager.choose_next_slot(current_slot)
	if next_slot:
		current_slot = next_slot
		global_position = next_slot.global_position
		game_manager.on_victim_enter_slot(next_slot)
