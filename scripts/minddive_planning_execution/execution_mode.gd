extends Node
class_name ExecutionMode

@export var spirit_grid_mover: SpiritGridMover # use your mover script type here (or CharacterBody3D)
@export var spirit: Node3D # later swap to Victim script (or a Resource). Keep Node for MVP.

# Tuning knobs (global)
@export var hear_smell_distance_falloff: float = 0.15
@export var see_distance_falloff: float = 0.05

@onready var gridmap: GridMap = $"../..//World/GridMapLevel"

var _placed_items: Array[PlacedConceptItem] = []

func _ready() -> void:
	if spirit_grid_mover != null and spirit_grid_mover.has_signal("arrived_at_cell"):
		spirit_grid_mover.connect("arrived_at_cell", Callable(self, "_on_spirit_arrived_at_cell"))
	else:
		push_warning("SpiritGridMover is missing signal arrived_at_cell(cell: Vector3i)")

func begin_execution(placed_items: Array[PlacedConceptItem]) -> void:
	_placed_items = placed_items

	print("Execution begins. Placed items:", _placed_items.size())
	for p in _placed_items:
		print(" - ", p.concept.display_name, " @ ", p.cell)

	# Give Spirit Grid Mover the references it needs
	spirit_grid_mover.set_execution(self)
	spirit_grid_mover.set_placed_items(_placed_items)

	spirit_grid_mover.start()

# --- Core scoring API: Spirit calls this ---
func calc_item_influence(
	placed: PlacedConceptItem,
	spirit_world_pos: Vector3) -> float:
	if placed == null or placed.concept == null:
		return 0.0

	var c := placed.concept

	# 1) Base attraction modified by victim emotions (MVP: assume victim has inspired/laziness floats)
	var inspired := 0.5
	var laziness := 0.5
	if spirit != null:
		# If you have Victim script with fields, plug them here:
		# inspired = victim.inspired
		# laziness = victim.laziness
		pass

	var attraction := c.base_attraction
	attraction += c.inspired_scalar * inspired
	attraction += c.laziness_scalar * laziness

	# 2) Distance attenuation
	var placed_pos := placed.global_position
	var dist := spirit_world_pos.distance_to(placed_pos)
	dist = max(dist, 0.001)

	# 3) Sense gating
	match c.sense_type:
		ConceptItem.SenseType.SEE:
			# Cone check is Spirit-owned, so Spirit should only call this if it can see it.
			attraction *= 1.0 / (1.0 + dist * see_distance_falloff)
		ConceptItem.SenseType.HEAR, ConceptItem.SenseType.SMELL:
			attraction *= 1.0 / (1.0 + dist * hear_smell_distance_falloff)
		_:
			pass

	return attraction

func _on_spirit_reached_target() -> void:
	get_tree().change_scene_to_file("res://scenes/MindDiveCompleted.tscn")

func _on_spirit_arrived_at_cell(cell: Vector3i) -> void:
	var item_id: int = gridmap.get_cell_item(cell)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return
	
	# hard coded exit for now.... WTF
	if item_id == 2:
		_on_spirit_reached_target()
