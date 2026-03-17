extends Node
class_name PlanningMode3D

## Cell type enum — values correspond to GridMap mesh library item IDs.
## These must match the IDs in the GridMapLevel mesh library.
enum TileKind { NONE = 0, START = 1, END = 2, DOOR = 3, SLOT = 4, WALL = 5 }

@onready var gridmap: GridMap = $"../..//World/GridMapLevel"
@onready var placed_parent: Node3D = $"../..//World/PlacedConceptItems"
@onready var planning_ui: Control = $"../..//UI/PlanningUI"

@export var planning_camera: Camera3D
@export var placed_concept_item_scene: PackedScene

## Reference to the nav GridMap (walkable cells only) — used to validate PATH placement
@export var gridmap_nav: GridMap

var _selected_concept: ConceptItem = null

## Map GridMap mesh library item ID -> TileKind
var tile_kind_by_item_id: Dictionary = {
	0: TileKind.NONE,
	1: TileKind.START,
	2: TileKind.END,
	3: TileKind.DOOR,
	4: TileKind.SLOT,
	5: TileKind.WALL,
}

signal concept_placed(concept: ConceptItem)
signal concept_removed(concept: ConceptItem)

var _placed_by_cell: Dictionary = {}  # Vector3i -> PlacedConceptItem
var _concept_by_cell: Dictionary = {}  # Vector3i -> ConceptItem

## Whether an Emotion Gate has already been placed (at most one per level)
var _gate_placed: bool = false

func _ready() -> void:
	if planning_camera == null:
		planning_camera = get_viewport().get_camera_3d()
	if planning_camera == null:
		push_error("PlanningMode3D: No Camera3D set or found.")
		return

	if planning_ui != null and planning_ui.has_signal("concept_selected"):
		planning_ui.connect("concept_selected", Callable(self, "_on_concept_selected"))
	else:
		push_warning("PlanningUI is missing signal concept_selected(concept: ConceptItem)")

func _on_concept_selected(ci: ConceptItem) -> void:
	_selected_concept = ci
	print("Selected concept: ", ci.display_name)

func _unhandled_input(event: InputEvent) -> void:
	if planning_ui == null or not planning_ui.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_place_at_mouse((event as InputEventMouseButton).position)

func _try_place_at_mouse(screen_pos: Vector2) -> bool:
	if _selected_concept == null:
		return false

	var hit := _raycast_from_camera(screen_pos)
	if hit.is_empty():
		return false

	var world_pos: Vector3 = hit["position"]
	var cell: Vector3i = gridmap.local_to_map(gridmap.to_local(world_pos))
	cell.y = 0

	var kind := _get_tile_kind(cell)
	var is_path := _selected_concept.placement_type == ConceptItem.PlacementType.PATH

	if is_path:
		# Emotion Gate — must be placed on a PATH cell
		if not _is_path_cell(cell, kind):
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

	_place_concept(cell)
	return true

## Returns true if `cell` is a plain PATH cell (walkable, not a special type).
func _is_path_cell(cell: Vector3i, kind: int) -> bool:
	# Must not be a special named cell type
	if kind != TileKind.NONE:
		return false
	# Must be walkable (present in the nav GridMap)
	if gridmap_nav == null:
		push_warning("PlanningMode3D: gridmap_nav not set; cannot validate PATH placement.")
		return false
	return gridmap_nav.get_cell_item(cell) != GridMap.INVALID_CELL_ITEM

func _raycast_from_camera(screen_pos: Vector2) -> Dictionary:
	var origin: Vector3 = planning_camera.project_ray_origin(screen_pos)
	var dir: Vector3 = planning_camera.project_ray_normal(screen_pos)
	var to: Vector3 = origin + dir * 1000.0

	var space := planning_camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space.intersect_ray(query)

func _get_tile_kind(cell: Vector3i) -> int:
	var item_id: int = gridmap.get_cell_item(cell)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return TileKind.NONE
	if tile_kind_by_item_id.has(item_id):
		return int(tile_kind_by_item_id[item_id])
	return TileKind.NONE

func _place_concept(cell: Vector3i) -> void:
	if _selected_concept == null:
		return
	if placed_concept_item_scene == null:
		push_warning("PlanningMode3D: placed_concept_item_scene not set.")
		return

	var placed := placed_concept_item_scene.instantiate() as PlacedConceptItem
	if placed == null:
		push_warning("placed_concept_item_scene root must have PlacedConceptItem script.")
		return

	placed_parent.add_child(placed)

	var cell_world: Vector3 = gridmap.to_global(gridmap.map_to_local(cell))
	placed.global_position = cell_world
	placed.setup(_selected_concept, cell)

	_placed_by_cell[cell] = placed
	_concept_by_cell[cell] = _selected_concept

	if _selected_concept.placement_type == ConceptItem.PlacementType.PATH:
		_gate_placed = true

	concept_placed.emit(_selected_concept)
	print("Placed ", _selected_concept.display_name, " at cell ", cell)

	_selected_concept = null

func _remove_at_cell(cell: Vector3i) -> void:
	if not _placed_by_cell.has(cell):
		return

	var placed: PlacedConceptItem = _placed_by_cell.get(cell)
	var concept: ConceptItem = placed.concept if placed != null else _concept_by_cell.get(cell)

	if placed != null and is_instance_valid(placed):
		placed.queue_free()

	if concept != null:
		if concept.placement_type == ConceptItem.PlacementType.PATH:
			_gate_placed = false
		concept_removed.emit(concept)

	_concept_by_cell.erase(cell)
	_placed_by_cell.erase(cell)

func get_placed_items() -> Array[PlacedConceptItem]:
	var out: Array[PlacedConceptItem] = []
	for v in _placed_by_cell.values():
		var p := v as PlacedConceptItem
		if p != null and is_instance_valid(p):
			out.append(p)
	return out
