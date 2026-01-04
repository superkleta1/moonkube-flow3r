extends Node2D
class_name ItemsOverlay

@export var tilemap_path: NodePath
var tilemap: TileMapLayer

# cell -> Sprite2D
var sprites_by_cell: Dictionary[Vector2i, Sprite2D] = {}

func _ready() -> void:
	tilemap = get_node(tilemap_path) as TileMapLayer
	if tilemap == null:
		push_error("ItemsOverlay: tilemap_path not set or invalid.")

func set_item_sprite(cell: Vector2i, icon: Texture2D) -> void:
	_clear_cell(cell)

	if icon == null:
		return

	var s := Sprite2D.new()
	s.texture = icon
	s.centered = true
	s.scale = Vector2(0.5, 0.5)  # adjust to taste

	# place at tile center
	var world := tilemap.to_global(tilemap.map_to_local(cell))
	s.global_position = world

	add_child(s)
	sprites_by_cell[cell] = s

func clear_all() -> void:
	for cell in sprites_by_cell.keys():
		_clear_cell(cell)
	sprites_by_cell.clear()

func _clear_cell(cell: Vector2i) -> void:
	if sprites_by_cell.has(cell):
		var s := sprites_by_cell[cell]
		if is_instance_valid(s):
			s.queue_free()
		sprites_by_cell.erase(cell)
