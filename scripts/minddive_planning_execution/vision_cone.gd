extends Node3D
class_name VisionCone

## Translucent cone (or disc for 360°) that visualises the Spirit's current vision area.
## Spawned as a child of SpiritGridMover — reads vision_radius and vision_angle_degrees
## from its parent automatically, and converts them to correct local-space units.

@export var fill_color: Color = Color(1.00, 0.90, 0.30, 0.18)
@export var edge_color: Color = Color(1.00, 0.90, 0.30, 0.75)
@export var arc_segments: int = 40

var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _local_radius: float  = 1.0
var _half_rad: float      = 0.0
var _is_full_circle: bool = false

func _ready() -> void:
	# ── Sync vision params from SpiritGridMover parent ──────────────────────
	var vision_radius: float        = 8.0
	var vision_angle_degrees: float = 70.0

	var parent: SpiritGridMover = get_parent() as SpiritGridMover
	if parent != null:
		vision_radius        = parent.vision_radius
		vision_angle_degrees = parent.vision_angle_degrees

	# Convert world-space radius → this node's local space (accounts for parent scale)
	var gs: Vector3 = global_transform.basis.get_scale()
	_local_radius   = vision_radius / max(gs.x, 0.001)
	_half_rad       = deg_to_rad(clampf(vision_angle_degrees, 0.0, 360.0) * 0.5)
	_is_full_circle = vision_angle_degrees >= 360.0

	# ── Build mesh ───────────────────────────────────────────────────────────
	_immediate_mesh = ImmediateMesh.new()

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color               = Color.WHITE

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh              = _immediate_mesh
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	_build_mesh()


func _build_mesh() -> void:
	_immediate_mesh.clear_surfaces()

	if _local_radius <= 0.0 or _half_rad <= 0.0:
		return

	# ── Filled fan ───────────────────────────────────────────────────────────
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_immediate_mesh.surface_set_color(fill_color)

	for i: int in arc_segments:
		var t0: float = float(i)     / float(arc_segments)
		var t1: float = float(i + 1) / float(arc_segments)
		var a0: float = -_half_rad + (_half_rad - (-_half_rad)) * t0
		var a1: float = -_half_rad + (_half_rad - (-_half_rad)) * t1
		var p0 := Vector3(sin(a0) * _local_radius, 0.0, -cos(a0) * _local_radius)
		var p1 := Vector3(sin(a1) * _local_radius, 0.0, -cos(a1) * _local_radius)

		_immediate_mesh.surface_add_vertex(Vector3.ZERO)
		_immediate_mesh.surface_add_vertex(p0)
		_immediate_mesh.surface_add_vertex(p1)

	_immediate_mesh.surface_end()

	# ── Outline ──────────────────────────────────────────────────────────────
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_set_color(edge_color)

	# Arc perimeter
	for i: int in arc_segments:
		var t0: float = float(i)     / float(arc_segments)
		var t1: float = float(i + 1) / float(arc_segments)
		var a0: float = -_half_rad + (_half_rad - (-_half_rad)) * t0
		var a1: float = -_half_rad + (_half_rad - (-_half_rad)) * t1
		var p0 := Vector3(sin(a0) * _local_radius, 0.0, -cos(a0) * _local_radius)
		var p1 := Vector3(sin(a1) * _local_radius, 0.0, -cos(a1) * _local_radius)
		_immediate_mesh.surface_add_vertex(p0)
		_immediate_mesh.surface_add_vertex(p1)

	# Side edges from apex (only for a cone, not a full disc)
	if not _is_full_circle:
		var p_left  := Vector3(sin(-_half_rad) * _local_radius, 0.0, -cos(-_half_rad) * _local_radius)
		var p_right := Vector3(sin( _half_rad) * _local_radius, 0.0, -cos( _half_rad) * _local_radius)
		_immediate_mesh.surface_add_vertex(Vector3.ZERO)
		_immediate_mesh.surface_add_vertex(p_left)
		_immediate_mesh.surface_add_vertex(Vector3.ZERO)
		_immediate_mesh.surface_add_vertex(p_right)

	_immediate_mesh.surface_end()
