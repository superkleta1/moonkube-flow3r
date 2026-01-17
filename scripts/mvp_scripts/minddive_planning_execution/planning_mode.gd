extends Node
class_name PlanningMode3D

enum TileKind { NONE = 0, START = 1, EXIT = 2, DOOR = 3, ITEM_SLOT = 4, ROADBLOCK = 5 }

@onready var gridmap: GridMap = $"../..//World/GridMapLevel"
@onready var placed_parent: Node3D = $"../..//World/PlacedConceptItems"
@onready var planning_ui: Control = $"../..//UI/PlanningUI"

@export var planning_camera: Camera3D
@export var placed_concept_item_scene: PackedScene

var _selected_concept: ConceptItem = null
# Map GridMap "cell item index" (mesh library item id) -> TileKind
var tile_kind_by_item_id: Dictionary = {
	0: TileKind.NONE,
	1: TileKind.START,
	2: TileKind.EXIT,
	3: TileKind.DOOR,
	4: TileKind.ITEM_SLOT,
	5: TileKind.ROADBLOCK
}

signal concept_placed(concept: ConceptItem)
signal concept_removed(concept: ConceptItem)

var _placed_by_cell: Dictionary = {} # Vector3i -> PlacedConceptItem
var _concept_by_cell: Dictionary = {} # Vector3i -> ConceptItem  (optional now)

func _ready() -> void:
	if planning_camera == null:
		# try to auto-find (safe fallback)
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

	# Convert world position -> grid cell
	var world_pos: Vector3 = hit["position"]
	var cell: Vector3i = gridmap.local_to_map(gridmap.to_local(world_pos))
	cell.y = 0
	
	print("hit world:", world_pos)
	print("grid global:", gridmap.global_position, " basis:", gridmap.global_transform.basis)
	print("grid local:", gridmap.to_local(world_pos))
	print("cell:", cell)
	print("item at cell:", gridmap.get_cell_item(cell))
	
	var kind := _get_tile_kind(cell)
	if kind != TileKind.ITEM_SLOT:
		return false

	# Occupied? MVP behavior: remove then allow place (or just block)
	if _placed_by_cell.has(cell):
		_remove_at_cell(cell)
		# If you prefer "replace", continue to place; if you prefer "block", return false.
		# We'll "replace" for nicer UX:
		# return false

	_place_concept(cell)
	return true

func _raycast_from_camera(screen_pos: Vector2) -> Dictionary:
	# Ray into world using physics
	var origin: Vector3 = planning_camera.project_ray_origin(screen_pos)
	var dir: Vector3 = planning_camera.project_ray_normal(screen_pos)
	var to: Vector3 = origin + dir * 1000.0

	var space := planning_camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	# Optional: set collision mask so you only hit your floor/grid collider
	# query.collision_mask = 1 << 0

	return space.intersect_ray(query)

func _get_tile_kind(cell: Vector3i) -> int:
	var item_id: int = gridmap.get_cell_item(cell)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return TileKind.NONE

	# dictionary lookup returns Variant
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

	# Position wrapper at cell center
	var cell_world: Vector3 = gridmap.to_global(gridmap.map_to_local(cell))
	placed.global_position = cell_world

	# Store data on wrapper and let it spawn its own visual
	placed.setup(_selected_concept, cell)

	_placed_by_cell[cell] = placed
	_concept_by_cell[cell] = _selected_concept

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
