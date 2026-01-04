extends Node2D
class_name MindDiveGameManagerMVP

enum TileKind { NONE = 0, START = 1, EXIT = 2, DOOR = 3, ITEM_SLOT = 4, ROADBLOCK = 5 }
enum Phase { PLANNING, RUNNING, RESULT }

@export var level_config: MindDiveLevelConfig
@export var auto_step_interval: float = 0.6

# Camera fit settings (MVP)
@export var camera_padding_tiles: float = 1.0
@export var camera_min_zoom: float = 0.2
@export var camera_max_zoom: float = 6.0

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var victim: Victim = $Victim
@onready var camera: Camera2D = $Camera2D

@onready var item_bar: HBoxContainer = $UI/Panel/VBox/ItemBar
@onready var play_button: Button = $UI/Panel/VBox/Controls/PlayButton
@onready var back_button: Button = $UI/Panel/VBox/Controls/BackButton
@onready var title_label: Label = $UI/Panel/VBox/Title

var items_on_cells: Dictionary[Vector2i, Item] = {}
var hand: Array[Item] = []
var selected_item: Item = null

var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO
var doors_passed: int = 0

var phase: Phase = Phase.PLANNING
var _auto_t: float = 0.0

signal mind_dive_success(victim_id: String)
signal mind_dive_failed(victim_id: String)

func _ready() -> void:
	randomize()

	_scan_map()

	victim.game_manager = self
	_reset_victim_to_start()

	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)

	phase = Phase.PLANNING
	doors_passed = 0

	_init_hand_from_config()
	_build_hand_ui()
	_update_ui()

	_fit_camera_to_used_tiles()

func _process(delta: float) -> void:
	if phase != Phase.RUNNING:
		return

	_auto_t -= delta
	if _auto_t <= 0.0:
		_auto_t = auto_step_interval
		victim.step_once()

func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.PLANNING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selected_item == null:
			return
		var cell: Vector2i = _mouse_to_cell()
		if can_place_item(cell):
			place_item(cell, selected_item)

# -------------------------
# UI / Phases
# -------------------------

func _on_play_pressed() -> void:
	phase = Phase.RUNNING
	doors_passed = 0
	_reset_victim_to_start()
	_auto_t = 0.0
	_update_ui()

func _on_back_pressed() -> void:
	phase = Phase.PLANNING
	doors_passed = 0
	_reset_victim_to_start()
	_update_ui()

func _update_ui() -> void:
	var phase_name: String = "PLANNING"
	if phase == Phase.RUNNING:
		phase_name = "RUNNING"
	elif phase == Phase.RESULT:
		phase_name = "RESULT"

	title_label.text = "Mind Dive MVP — " + phase_name

	play_button.disabled = (phase != Phase.PLANNING)
	back_button.disabled = (phase == Phase.PLANNING)

# -------------------------
# TileMap access (TileMapLayer API)
# -------------------------

func get_tile_kind(cell: Vector2i) -> TileKind:
	# IMPORTANT: TileMapLayer.get_cell_tile_data takes ONLY (cell)
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return TileKind.NONE
	return td.get_custom_data("kind") as TileKind

func can_walk(cell: Vector2i) -> bool:
	var k: TileKind = get_tile_kind(cell)
	return k != TileKind.NONE and k != TileKind.ROADBLOCK

func can_place_item(cell: Vector2i) -> bool:
	return get_tile_kind(cell) == TileKind.ITEM_SLOT

func neighbors4(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]

func cell_to_world(cell: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(cell))

func _mouse_to_cell() -> Vector2i:
	return tilemap.local_to_map(to_local(get_global_mouse_position()))

# -------------------------
# Map scan
# -------------------------

func _scan_map() -> void:
	var found_start: bool = false
	var found_exit: bool = false

	for cell: Vector2i in tilemap.get_used_cells():
		match get_tile_kind(cell):
			TileKind.START:
				start_cell = cell
				found_start = true
			TileKind.EXIT:
				exit_cell = cell
				found_exit = true

	if not found_start:
		push_error("No START tile found. Set TileSet custom data kind=1 and paint it.")
	if not found_exit:
		push_error("No EXIT tile found. Set TileSet custom data kind=2 and paint it.")

func _reset_victim_to_start() -> void:
	victim.reset_to(start_cell)

# -------------------------
# Hand
# -------------------------

func _init_hand_from_config() -> void:
	hand.clear()
	selected_item = null

	if level_config == null:
		push_warning("No level_config assigned.")
		return

	var pool: Array[Item] = []
	pool.append_array(level_config.item_pool)
	pool.shuffle()

	var count: int = clamp(level_config.draw_count, 0, pool.size())
	for i in range(count):
		hand.append(pool[i])

	if hand.size() > 0:
		# Avoid Variant inference from indexing
		selected_item = hand[0] as Item

func _build_hand_ui() -> void:
	for c in item_bar.get_children():
		c.queue_free()

	for it: Item in hand:
		var b: Button = Button.new()
		b.text = it.display_name
		if it.icon:
			b.icon = it.icon
		b.pressed.connect(_on_item_selected.bind(it))
		item_bar.add_child(b)

func _on_item_selected(item: Item) -> void:
	selected_item = item

# -------------------------
# Placement
# -------------------------

func place_item(cell: Vector2i, item: Item) -> void:
	items_on_cells[cell] = item

# -------------------------
# Victim movement logic
# -------------------------

func choose_next_cell(from_cell: Vector2i) -> Vector2i:
	var best_cell: Vector2i = from_cell
	var best_score: float = -INF

	for n: Vector2i in neighbors4(from_cell):
		if not can_walk(n):
			continue
		var s: float = compute_attraction(n)
		s += randf() * 0.001
		if s > best_score:
			best_score = s
			best_cell = n

	return best_cell

func compute_attraction(cell: Vector2i) -> float:
	var score: float = 0.0

	var k: TileKind = get_tile_kind(cell)
	if k == TileKind.DOOR:
		score += 0.4
	elif k == TileKind.EXIT:
		score += 0.2

	var item: Item = items_on_cells.get(cell) as Item
	if item != null:
		var inspired: float = victim.inspired
		var laziness: float = victim.laziness

		var scale: float = 1.0 + inspired * item.inspired_scalar + laziness * item.laziness_scalar
		scale = max(scale, 0.0)

		score += item.base_attraction * scale

	return score

func on_victim_enter_cell(cell: Vector2i) -> void:
	match get_tile_kind(cell):
		TileKind.DOOR:
			doors_passed += 1
		TileKind.EXIT:
			_on_reached_exit()

func _on_reached_exit() -> void:
	phase = Phase.RESULT
	_update_ui()

	var required: int = 1
	var victim_id: String = ""
	if level_config != null:
		required = level_config.required_doors
		victim_id = level_config.victim_id

	if doors_passed >= required:
		emit_signal("mind_dive_success", victim_id)
	else:
		emit_signal("mind_dive_failed", victim_id)

# -------------------------
# Camera auto-fit
# -------------------------

func _fit_camera_to_used_tiles() -> void:
	if camera == null:
		return
	camera.enabled = true

	var used: Array[Vector2i] = tilemap.get_used_cells()
	if used.is_empty():
		return

	# Avoid Variant inference from indexing
	var first: Vector2i = used[0] as Vector2i
	var min_c: Vector2i = first
	var max_c: Vector2i = first

	for c: Vector2i in used:
		min_c.x = min(min_c.x, c.x)
		min_c.y = min(min_c.y, c.y)
		max_c.x = max(max_c.x, c.x)
		max_c.y = max(max_c.y, c.y)

	var pad_i: int = int(ceil(camera_padding_tiles))
	var pad: Vector2i = Vector2i(pad_i, pad_i)
	min_c -= pad
	max_c += pad

	var top_left: Vector2 = tilemap.to_global(tilemap.map_to_local(min_c))
	var bottom_right: Vector2 = tilemap.to_global(tilemap.map_to_local(max_c))

	var center: Vector2 = (top_left + bottom_right) * 0.5
	camera.global_position = center

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_size: Vector2 = Vector2(abs(bottom_right.x - top_left.x), abs(bottom_right.y - top_left.y))
	world_size.x = max(world_size.x, 1.0)
	world_size.y = max(world_size.y, 1.0)

	var zx: float = world_size.x / viewport_size.x
	var zy: float = world_size.y / viewport_size.y
	var z: float = max(zx, zy)
	z = clamp(z, camera_min_zoom, camera_max_zoom)

	camera.zoom = Vector2(z, z)
