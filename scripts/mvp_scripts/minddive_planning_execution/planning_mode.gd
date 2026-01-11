extends Node
class_name PlanningMode

enum TileKind { NONE = 0, START = 1, EXIT = 2, DOOR = 3, ITEM_SLOT = 4, ROADBLOCK = 5 }

@export var tile_layer: int = 0
@export var tile_kind_key: StringName = &"tile_kind"

@export var placed_item_scene: PackedScene # e.g. ConceptItemPlaced.tscn (Node2D)

@onready var tilemap: TileMapLayer = $"../..//World/TileMap"
@onready var anchors: Node2D = $"../..//World/PlacedConceptItems"
@onready var planning_ui: Control = $"../..//UI/PlanningUI"

var _selected_concept: ConceptItem = null

# Prevent double-placing on same slot cell
var _placed_by_cell: Dictionary = {} # Vector2i -> Node2D
# Optionally track which concept placed where
var _concept_by_cell: Dictionary = {} # Vector2i -> ConceptItem

func _ready() -> void:
	# Expect PlanningUI to have signal: concept_selected(ConceptItem)
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
	if _selected_concept == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var global_mouse := (event as InputEventMouseButton).position
		_try_place_at_mouse(global_mouse)

func _try_place_at_mouse(global_mouse_pos: Vector2) -> void:
	# Convert mouse -> cell
	var local_to_tilemap := tilemap.to_local(global_mouse_pos)
	var cell: Vector2i = tilemap.local_to_map(local_to_tilemap)

	# Check tile kind at that cell
	var kind := _get_tile_kind(cell)
	if kind != TileKind.ITEM_SLOT:
		return

	# Don't allow placement if already occupied
	if _placed_by_cell.has(cell):
		# later: replace? or show error UI
		print("Slot already occupied at ", cell)
		return

	_place_concept(cell, _selected_concept)

func _get_tile_kind(cell: Vector2i) -> int:
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return TileKind.NONE

	# TileData.get_custom_data returns Variant
	var v = td.get_custom_data(tile_kind_key)
	if typeof(v) == TYPE_INT:
		return int(v)
	return TileKind.NONE

func _place_concept(cell: Vector2i, concept: ConceptItem) -> void:
	if placed_item_scene == null:
		push_warning("placed_item_scene not set on PlanningMode.")
		return

	var node := placed_item_scene.instantiate() as Node2D
	anchors.add_child(node)

	# Position it at the center of the tile (global)
	var cell_local_pos: Vector2 = tilemap.map_to_local(cell)
	var cell_global_pos: Vector2 = tilemap.to_global(cell_local_pos)
	node.global_position = cell_global_pos

	# If your placed node has a method to display icon/name:
	if node.has_method("set_concept"):
		node.call("set_concept", concept)

	_placed_by_cell[cell] = node
	_concept_by_cell[cell] = concept

	print("Placed ", concept.display_name, " at cell ", cell)
