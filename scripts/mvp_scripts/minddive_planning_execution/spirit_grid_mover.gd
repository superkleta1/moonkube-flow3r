extends CharacterBody3D
class_name SpiritGridMover

@export var gridmap_nav: GridMap
@export var gridmap_level: GridMap
@export var start_item_id: int = 1

@export var speed_tiles_per_second: float = 4.0
@export var snap_epsilon: float = 0.05
@export var use_four_dirs: bool = true

# Vision parameters (Spirit-owned)
@export var vision_radius: float = 8.0
@export var vision_angle_degrees: float = 70.0

# Behavior tuning
@export var inertia_bonus: float = 0.35        # prefer continuing direction
@export var noise_amount: float = 0.08         # small randomness to avoid ties/loops

var _execution: ExecutionMode = null
var _placed_items: Array[PlacedConceptItem] = []

var _current_cell: Vector3i
var _target_cell: Vector3i
var _moving: bool = false
var _last_step_dir: Vector3i = Vector3i.ZERO

signal arrived_at_cell(cell: Vector3i)

func set_execution(exec: ExecutionMode) -> void:
	_execution = exec

func set_placed_items(items: Array[PlacedConceptItem]) -> void:
	_placed_items = items

func start() -> void:
	_current_cell = _find_start_cell()
	_target_cell = _current_cell

	# One-time: keep physics happy by letting it settle first
	global_position.y = 1.0

	_snap_to_cell(_current_cell)
	_take_next_step()

func _physics_process(delta: float) -> void:
	if not _moving:
		return
	
	var target_pos := _cell_center_world(_target_cell) # already keeps y = current
	var to_target := target_pos - global_position
	to_target.y = 0.0

	if to_target.length() <= snap_epsilon:
		_snap_to_cell(_target_cell)
		_current_cell = _target_cell
		_moving = false
		arrived_at_cell.emit(_current_cell)
		_take_next_step()
		return

	var dir := to_target.normalized()
	var speed := speed_tiles_per_second * _tile_size_world()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0

	_face_dir(dir, delta)
	move_and_slide()

# ---------- Decision ----------
func _take_next_step() -> void:
	var next := choose_next_cell_local()
	if next == _current_cell:
		print("No move chosen; stuck at ", _current_cell)
		return
	_last_step_dir = next - _current_cell
	
	print("chosen next cell", next)
	
	move_one_step_to(next)

func choose_next_cell_local() -> Vector3i:
	var candidates: Array[Vector3i] = []
	for n in _neighbors(_current_cell):
		if is_walkable(n):
			candidates.append(n)

	if candidates.is_empty():
		return _current_cell

	var best_cell := candidates[0]
	var best_score := -INF

	for c in candidates:
		var score := score_cell(c)
		if score > best_score:
			best_score = score
			best_cell = c

	return best_cell

func score_cell(cell: Vector3i) -> float:
	# Evaluate as if standing on that neighbor cell.
	var test_pos := _cell_center_world(cell)
	var forward := -global_transform.basis.z # Godot forward

	var score := 0.0

	# Inertia: keep going same direction to look less jittery
	var step_dir := cell - _current_cell
	if step_dir == _last_step_dir and step_dir != Vector3i.ZERO:
		score += inertia_bonus

	# Sum item influences
	for placed in _placed_items:
		if placed == null or placed.concept == null:
			continue
		if not _is_item_perceivable(placed, test_pos, forward):
			continue
		if _execution != null:
			score += _execution.calc_item_influence(placed, test_pos)

	# Small noise so ties don’t create loops
	score += randf_range(-noise_amount, noise_amount)
	print("Cell ", cell, "score is ", score)
	return score

func _is_item_perceivable(placed: PlacedConceptItem, spirit_pos: Vector3, forward: Vector3) -> bool:
	var c := placed.concept
	if c == null:
		return false

	match c.sense_type:
		ConceptItem.SenseType.SEE:
			# Distance check
			var to_item := placed.global_position - spirit_pos
			to_item.y = 0.0
			var dist := to_item.length()
			if dist > vision_radius:
				return false

			# Angle check
			var f := forward
			f.y = 0.0
			f = f.normalized()

			var d := to_item.normalized()
			var cos_angle := f.dot(d)
			var max_cos := cos(deg_to_rad(vision_angle_degrees * 0.5))
			return cos_angle >= max_cos

		ConceptItem.SenseType.HEAR, ConceptItem.SenseType.SMELL:
			# Global detect; ExecutionMode handles falloff
			return true

		_:
			return true

# ---------- Movement API ----------
func move_one_step_to(cell: Vector3i) -> void:
	cell.y = 0
	if not is_walkable(cell):
		return
	_target_cell = cell
	_moving = true

func is_walkable(cell: Vector3i) -> bool:
	cell.y = 0
	var item_id := gridmap_nav.get_cell_item(cell)
	return item_id != GridMap.INVALID_CELL_ITEM

# ---------- Helpers ----------
func _neighbors(cell: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if use_four_dirs:
		out.append(cell + Vector3i(1, 0, 0))
		out.append(cell + Vector3i(-1, 0, 0))
		out.append(cell + Vector3i(0, 0, 1))
		out.append(cell + Vector3i(0, 0, -1))
	else:
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				out.append(cell + Vector3i(dx, 0, dz))
	return out

func _cell_center_world(cell: Vector3i) -> Vector3:
	cell.y = 0
	var p := gridmap_nav.to_global(gridmap_nav.map_to_local(cell))
	# IMPORTANT: keep the body's current Y so physics doesn't fight you
	p.y = global_position.y
	return p

func _snap_to_cell(cell: Vector3i) -> void:
	var p := _cell_center_world(cell)
	global_position = p

func _tile_size_world() -> float:
	var a := _cell_center_world(_current_cell)
	var b := _cell_center_world(_current_cell + Vector3i(1, 0, 0))
	return max(0.001, (b - a).length())

func _face_dir(dir: Vector3, delta: float) -> void:
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, min(1.0, delta * 12.0))

func _find_start_cell() -> Vector3i:
	for cell in gridmap_level.get_used_cells():
		var c := cell as Vector3i
		c.y = 0
		if gridmap_level.get_cell_item(c) == start_item_id:
			return c

	var fallback := gridmap_nav.local_to_map(gridmap_nav.to_local(global_position))
	fallback.y = 0
	push_warning("Start cell not found; using current cell: %s" % str(fallback))
	return fallback
