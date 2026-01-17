extends Node3D
class_name PlacedConceptItem

@export var concept: ConceptItem
@export var cell: Vector3i

# Optional: if you want consistent vertical offset for visuals
@export var visual_offset: Vector3 = Vector3.ZERO

@onready var visual_anchor: Node3D = get_node_or_null("VisualAnchor") as Node3D

var _visual_instance: Node3D = null

func setup(p_concept: ConceptItem, p_cell: Vector3i) -> void:
	concept = p_concept
	cell = p_cell
	_build_visual()

func _ready() -> void:
	# If dropped into scene in editor with exported fields set, build visuals automatically.
	if concept != null and _visual_instance == null:
		_build_visual()

func _build_visual() -> void:
	_clear_visual()

	if concept == null:
		return
	if concept.mesh_scene == null:
		push_warning("PlacedConceptItem: concept has no mesh_scene: %s" % concept.display_name)
		return

	var inst := concept.mesh_scene.instantiate()
	_visual_instance = inst as Node3D
	if _visual_instance == null:
		push_warning("PlacedConceptItem: mesh_scene root must be Node3D.")
		return

	var parent := visual_anchor if visual_anchor != null else self
	parent.add_child(_visual_instance)
	_visual_instance.position = visual_offset

	# Optional: pass the concept down to the visual if it supports it
	if _visual_instance.has_method("set_concept"):
		_visual_instance.call("set_concept", concept)

func _clear_visual() -> void:
	if _visual_instance != null and is_instance_valid(_visual_instance):
		_visual_instance.queue_free()
	_visual_instance = null

func to_data() -> Dictionary:
	# Use this if you ever need to rebuild after scene change/save/load.
	return {
		"concept_id": concept.id if concept != null else "",
		"cell": cell,
	}
