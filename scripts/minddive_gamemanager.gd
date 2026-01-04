# scripts/minddive_gamemanager.gd
extends Node2D
# class_name MindDiveGameManager

@export var level_config: MindDiveLevelConfig
@export var slots_root: NodePath = ^"SlotsRoot"
@export var victim_path: NodePath = ^"Victim"

var slots: Array[MindDiveTileSlot] = []
var victim: MindDiveAgent

var doors_passed: int = 0

var item_attractions: Dictionary[String, float] = {}

signal mind_dive_success(victim_id: String)
signal mind_dive_failed(victim_id: String)

func _ready() -> void:
	# Collect slots
	var root: Node = get_node(slots_root)
	for child in root.get_children():
		if child is MindDiveTileSlot:
			slots.append(child)

	# Set up victim
	victim = get_node(victim_path)
	victim.game_manager = self

	# Find start slot
	for s in slots:
		if s.is_start:
			victim.current_slot = s
			victim.global_position = s.global_position
			break

	doors_passed = 0

	# Later: generate random item set from level_config.item_pool and let
	# player place items onto slots (set slot.item = chosen_item)

func choose_next_slot(from_slot: MindDiveTileSlot) -> MindDiveTileSlot:
	var neighbors := _get_neighbor_slots(from_slot)
	if neighbors.is_empty():
		return null

	var best_slot := neighbors[0]
	var best_score := _compute_attraction_score(best_slot)

	for s in neighbors:
		var score := _compute_attraction_score(s)
		if score > best_score:
			best_score = score
			best_slot = s

	return best_slot

func _get_neighbor_slots(slot: MindDiveTileSlot) -> Array[MindDiveTileSlot]:
	var result: Array[MindDiveTileSlot] = []
	for s in slots:
		if abs(s.grid_x - slot.grid_x) + abs(s.grid_y - slot.grid_y) == 1:
			result.append(s)
	return result

func _compute_attraction_score(slot: MindDiveTileSlot) -> float:
	var score: float = 0.0

	if slot.item:
		score += slot.item.base_attraction
		# Later: apply tag-based rules, door bonuses, neighbor interactions, etc.

	if slot.is_door:
		score += 0.5   # generic “doors pull them in” bonus; tune later

	return score

func on_victim_enter_slot(slot: MindDiveTileSlot) -> void:
	if slot.is_door:
		doors_passed += 1

	if slot.is_exit:
		_on_reached_exit()
	# else: continue walking next tick

func _on_reached_exit() -> void:
	var required := level_config.required_doors if level_config else 3
	if doors_passed >= required:
		emit_signal("mind_dive_success", level_config.victim_id if level_config else "")
	else:
		emit_signal("mind_dive_failed", level_config.victim_id if level_config else "")
