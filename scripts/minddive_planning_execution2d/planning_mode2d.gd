extends Node
class_name PlanningMode2D

## Cell type enum — values correspond to tile custom data "tile_kind" on the TileMapLayer.
enum TileKind { NONE = 0, START = 1, END = 2, DOOR = 3, SLOT = 4, WALL = 5, PATH = 6 }

@export var tile_layer: int = 0
@export var tile_kind_key: StringName = &"tile_kind"

@export var placed_item_scene: PackedScene

@onready var tilemap: TileMapLayer = $"../..//World/TileMap"
@onready var anchors: Node2D = $"../..//World/PlacedConceptItems"
@onready var planning_ui: Control = $"../..//UI/PlanningUI"

var _selected_concept: ConceptItem = null

signal concept_placed(concept: ConceptItem)
signal concept_removed(concept: ConceptItem)

var _placed_by_cell: Dictionary = {}  # Vector2i -> Node2D
var _concept_by_cell: Dictionary = {}  # Vector2i -> ConceptItem

## Whether an Emotion Gate has already been placed (at most one per level)
var _gate_placed: bool = false

func _ready() -> void:
	if planning_ui.has_signal("concept_selected"):
		planning_ui.connect("concept_selected", Callable(self, "_on_concept_selected"))
	else:
		push_warning("PlanningUI is missing signal concept_selected(concept: ConceptItem)")

func _on_concept_selected(ci: ConceptItem) -> void:
	_selected_concept = ci
	print("Selected concept: ", ci.display_name)

func _unhandled_input(event: InputEvent) -> void:
	if not planning_ui.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var global_mouse := (event as InputEventMouseButton).position
		_try_place_at_mouse(global_mouse)

func _try_place_at_mouse(global_mouse_pos: Vector2) -> bool:
	if _selected_concept == null:
		return false

	var local_to_tilemap := tilemap.to_local(global_mouse_pos)
	var cell: Vector2i = tilemap.local_to_map(local_to_tilemap)
	var kind := _get_tile_kind(cell)
	var is_path := _selected_concept.placement_type == ConceptItem.PlacementType.PATH

	if is_path:
		# Emotion Gate — must be placed on a PATH cell
		if kind != TileKind.PATH:
			print("Emotion Gate requires a PATH cell, not: ", TileKind.keys()[kind])
			return false
		if _gate_placed:
			print("An Emotion Gate is already placed. Remove it first.")
			return false
	else:
		# Standard concept — must be placed on a SLOT cell
		if kind != TileKind.SLOT:
			return false

	# Replace if occupied
	if _placed_by_cell.has(cell):
		_remove_at_cell(cell)
		if is_path:
			return false  # clicking occupied gate cell removes it, don't re-place

	_place_concept(cell)
	return true

func _remove_at_cell(cell: Vector2i) -> void:
	var concept: ConceptItem = _concept_by_cell.get(cell)
	var node: Node2D = _placed_by_cell.get(cell)

	if node != null and is_instance_valid(node):
		anchors.remove_child(node)
		node.queue_free()

	if concept != null:
		if concept.placement_type == ConceptItem.PlacementType.PATH:
			_gate_placed = false
		concept_removed.emit(concept)

	_concept_by_cell.erase(cell)
	_placed_by_cell.erase(cell)

func _get_tile_kind(cell: Vector2i) -> int:
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return TileKind.NONE
	var v = td.get_custom_data(tile_kind_key)
	if typeof(v) == TYPE_INT:
		return int(v)
	return TileKind.NONE

func _place_concept(cell: Vector2i) -> void:
	if placed_item_scene == null:
		push_warning("placed_item_scene not set on PlanningMode2D.")
		return
	if _selected_concept == null:
		return

	var node := placed_item_scene.instantiate() as Node2D
	anchors.add_child(node)

	var cell_local_pos: Vector2 = tilemap.map_to_local(cell)
	var cell_global_pos: Vector2 = tilemap.to_global(cell_local_pos)
	node.global_position = cell_global_pos

	if node.has_method("set_concept"):
		node.call("set_concept", _selected_concept)

	_placed_by_cell[cell] = node
	_concept_by_cell[cell] = _selected_concept

	if _selected_concept.placement_type == ConceptItem.PlacementType.PATH:
		_gate_placed = true

	concept_placed.emit(_selected_concept)
	print("Placed ", _selected_concept.display_name, " at cell ", cell)

	_selected_concept = null
