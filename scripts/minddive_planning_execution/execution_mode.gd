extends Node
class_name ExecutionMode

@export var spirit_grid_mover: SpiritGridMover
@export var spirit: Node3D  # Future: swap to typed Soul node

# ── Distance tuning ──────────────────────────────────────────────────────────
@export var hear_smell_distance_falloff: float = 0.15
@export var see_distance_falloff: float = 0.05

## Max world-unit distance for proximity interactions between concept objects (~2-3 tiles)
@export var proximity_range: float = 3.0

# ── Emotion axis — configure per character ───────────────────────────────────
@export var left_pole_name: String = "Despair"
@export var right_pole_name: String = "Hope"
@export var emotion_min: float = -100.0
@export var emotion_max: float = 100.0
## Soul enters LEFT pole state when emotion_value <= this threshold
@export var left_pole_threshold: float = -30.0
## Soul enters RIGHT pole state when emotion_value >= this threshold
@export var right_pole_threshold: float = 30.0
## Starting emotion value for this level (negative = slight Despair for John Doe)
@export var emotion_starting_value: float = -15.0

# ── Emotion state ────────────────────────────────────────────────────────────
enum EmotionState { LEFT_POLE, NEUTRAL, RIGHT_POLE }

## Current emotion value on the bipolar axis. Public so UI can read it.
var emotion_value: float = 0.0
## Current emotion state. Public so scoring and UI can read it.
var emotion_state: EmotionState = EmotionState.NEUTRAL

# ── GridMap item IDs (must match the level GridMap mesh library) ─────────────
const ITEM_ID_END: int = 2
const ITEM_ID_DOOR: int = 3

@onready var gridmap: GridMap = $"../..//World/GridMapLevel"

# ── Runtime state ────────────────────────────────────────────────────────────
var _placed_items: Array[PlacedConceptItem] = []
var _preset_items: Array[PlacedConceptItem] = []   # immovable baked-in concept objects
var _all_items: Array[PlacedConceptItem] = []      # combined

var _all_door_cells: Array[Vector3i] = []
var _opened_doors: Array[Vector3i] = []

# ── Signals ──────────────────────────────────────────────────────────────────
signal emotion_changed(value: float, state: EmotionState)
signal door_opened(cell: Vector3i, opened_count: int, total_doors: int)
signal level_complete()

func _ready() -> void:
	if spirit_grid_mover != null and spirit_grid_mover.has_signal("arrived_at_cell"):
		spirit_grid_mover.connect("arrived_at_cell", Callable(self, "_on_spirit_arrived_at_cell"))
	else:
		push_warning("SpiritGridMover is missing signal arrived_at_cell(cell: Vector3i)")

## Register immovable preset concept objects (baked into the level).
## Call before begin_execution().
func register_preset_items(items: Array[PlacedConceptItem]) -> void:
	_preset_items = items

func begin_execution(placed_items: Array[PlacedConceptItem]) -> void:
	_placed_items = placed_items
	_all_items = _placed_items + _preset_items

	emotion_value = emotion_starting_value
	_update_emotion_state()

	_opened_doors.clear()
	_all_door_cells = _find_all_door_cells()

	print("Execution begins. Placed: %d  Presets: %d  Doors: %d" % [
		_placed_items.size(), _preset_items.size(), _all_door_cells.size()])

	spirit_grid_mover.set_execution(self)
	spirit_grid_mover.set_placed_items(_all_items)
	spirit_grid_mover.start()

# ── Core scoring API — called by SpiritGridMover ─────────────────────────────

## Returns the net attraction influence of `placed` on the Soul at `spirit_world_pos`.
## Positive = draws Soul toward it. Negative = pushes Soul away.
func calc_item_influence(placed: PlacedConceptItem, spirit_world_pos: Vector3) -> float:
	if placed == null or placed.concept == null:
		return 0.0

	var c := placed.concept

	# 1. Attraction — base + emotion-state conditional modifier
	var attraction := c.base_attraction
	match emotion_state:
		EmotionState.LEFT_POLE:
			attraction += c.left_pole_attraction
		EmotionState.RIGHT_POLE:
			attraction += c.right_pole_attraction

	# 2. Proximity interaction modifier (resonance, interference, suppression)
	attraction *= _calc_proximity_modifier(placed)

	# 3. Distance attenuation by sense type
	var dist := spirit_world_pos.distance_to(placed.global_position)
	dist = max(dist, 0.001)

	match c.sense_type:
		ConceptItem.SenseType.SEE:
			attraction *= 1.0 / (1.0 + dist * see_distance_falloff)
		ConceptItem.SenseType.HEAR, ConceptItem.SenseType.SMELL:
			attraction *= 1.0 / (1.0 + dist * hear_smell_distance_falloff)

	return attraction

## Computes the net proximity modifier on `target` from all other active items.
## Returns a multiplier: 1.0 = unchanged, >1.0 = amplified, <1.0 = weakened.
func _calc_proximity_modifier(target: PlacedConceptItem) -> float:
	var modifier := 1.0
	var target_pos := target.global_position

	for other in _all_items:
		if other == target or other == null or other.concept == null:
			continue
		var dist := target_pos.distance_to(other.global_position)
		if dist >= proximity_range:
			continue

		# Linear falloff: t=1 at distance 0, t=0 at proximity_range
		var t := 1.0 - (dist / proximity_range)
		var other_c := other.concept

		# SUPPRESSION: other item weakens target's attraction
		if other_c.is_suppressor:
			modifier -= 0.5 * t
			continue

		# RESONANCE / INTERFERENCE: per-pair rules on the target concept
		for rule: ProximityRule in target.concept.proximity_rules:
			if rule.other_concept_id == other_c.id:
				match rule.interaction_type:
					ProximityRule.InteractionType.RESONANCE:
						modifier += rule.strength * t
					ProximityRule.InteractionType.INTERFERENCE:
						modifier -= rule.strength * t
				break

	return clamp(modifier, 0.0, 3.0)

# ── Emotion system ───────────────────────────────────────────────────────────

## Apply emotion influence from all always-active (HEAR/SMELL) concept objects.
## Called once per step on every cell arrival.
func _update_emotion_from_global_items() -> void:
	for placed in _all_items:
		if placed == null or placed.concept == null:
			continue
		var c := placed.concept
		if c.base_emotion_influence == 0.0:
			continue
		if c.sense_type == ConceptItem.SenseType.HEAR or c.sense_type == ConceptItem.SenseType.SMELL:
			emotion_value += c.base_emotion_influence

	emotion_value = clamp(emotion_value, emotion_min, emotion_max)
	_update_emotion_state()
	emotion_changed.emit(emotion_value, emotion_state)

## Apply emotion influence from a SEE item currently in the Soul's field of view.
## Called per visible SEE item on each step.
func apply_visual_emotion_influence(influence: float) -> void:
	if influence == 0.0:
		return
	emotion_value += influence
	emotion_value = clamp(emotion_value, emotion_min, emotion_max)
	_update_emotion_state()
	emotion_changed.emit(emotion_value, emotion_state)

## Apply the directional emotion shift from walking through an Emotion Gate.
func apply_gate_emotion_shift(shift: float) -> void:
	if shift == 0.0:
		return
	emotion_value += shift
	emotion_value = clamp(emotion_value, emotion_min, emotion_max)
	_update_emotion_state()
	emotion_changed.emit(emotion_value, emotion_state)
	print("Emotion Gate triggered. Emotion now: %.1f (%s)" % [emotion_value, _emotion_state_name()])

func _update_emotion_state() -> void:
	var prev_state := emotion_state
	if emotion_value <= left_pole_threshold:
		emotion_state = EmotionState.LEFT_POLE
	elif emotion_value >= right_pole_threshold:
		emotion_state = EmotionState.RIGHT_POLE
	else:
		emotion_state = EmotionState.NEUTRAL
	if emotion_state != prev_state:
		print("Emotion state → %s (value: %.1f)" % [_emotion_state_name(), emotion_value])

func _emotion_state_name() -> String:
	match emotion_state:
		EmotionState.LEFT_POLE:  return left_pole_name
		EmotionState.RIGHT_POLE: return right_pole_name
	return "Neutral"

# ── Step events ──────────────────────────────────────────────────────────────

func _on_spirit_arrived_at_cell(cell: Vector3i) -> void:
	# 1. Emotion from always-active global (HEAR/SMELL) items
	_update_emotion_from_global_items()

	# 2. Emotion from visual (SEE) items currently in field of view
	if spirit_grid_mover != null:
		for placed in _all_items:
			if placed == null or placed.concept == null:
				continue
			if placed.concept.sense_type == ConceptItem.SenseType.SEE:
				if spirit_grid_mover.is_item_currently_visible(placed):
					apply_visual_emotion_influence(placed.concept.base_emotion_influence)

	# 3. Check for an Emotion Gate placed at this cell
	for placed in _all_items:
		if placed == null or placed.concept == null:
			continue
		if placed.concept.placement_type != ConceptItem.PlacementType.PATH:
			continue
		if placed.cell != cell:
			continue
		var dir_index := _dir_to_gate_index(spirit_grid_mover.last_step_dir)
		if dir_index >= 0 and dir_index < placed.concept.gate_emotion_shifts.size():
			apply_gate_emotion_shift(placed.concept.gate_emotion_shifts[dir_index])
		break

	# 4. Check cell type for door / level end
	var item_id: int = gridmap.get_cell_item(cell)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return

	if item_id == ITEM_ID_DOOR:
		if cell not in _opened_doors:
			_opened_doors.append(cell)
			door_opened.emit(cell, _opened_doors.size(), _all_door_cells.size())
			print("Door opened at %s (%d/%d)" % [str(cell), _opened_doors.size(), _all_door_cells.size()])
		return

	if item_id == ITEM_ID_END:
		if _opened_doors.size() >= _all_door_cells.size():
			_on_level_complete()
		else:
			var remaining := _all_door_cells.size() - _opened_doors.size()
			print("Reached END but %d door(s) still closed." % remaining)

func _on_level_complete() -> void:
	level_complete.emit()
	get_tree().change_scene_to_file("res://scenes/MindDiveCompleted.tscn")

# ── Helpers ──────────────────────────────────────────────────────────────────

func _find_all_door_cells() -> Array[Vector3i]:
	var doors: Array[Vector3i] = []
	for cell in gridmap.get_used_cells():
		var c := cell as Vector3i
		c.y = 0
		if gridmap.get_cell_item(c) == ITEM_ID_DOOR:
			doors.append(c)
	return doors

## Maps a movement direction Vector3i to an index into gate_emotion_shifts.
## Returns -1 if direction is not a recognized cardinal direction.
func _dir_to_gate_index(dir: Vector3i) -> int:
	if dir == Vector3i(0, 0, -1): return 0  # North (moving toward -Z)
	if dir == Vector3i(1, 0, 0):  return 1  # East  (moving toward +X)
	if dir == Vector3i(0, 0, 1):  return 2  # South (moving toward +Z)
	if dir == Vector3i(-1, 0, 0): return 3  # West  (moving toward -X)
	return -1
