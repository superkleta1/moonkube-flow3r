#scripts/computer_screen.gd
extends Control

@onready var window_layer: Control = get_node_or_null("WindowLayer")
@onready var texting_app_button: Button = get_node_or_null("TextingAppButton")

# app scenes registry
const APP_SCENES := {
	"texting_app": preload("res://scenes/TextingApp.tscn"),
}

# track open windows so we don't open duplicates
var open_apps: Dictionary = {}  # app_id -> AppBase instance

func _ready() -> void:
	print("=== ComputerScreen _ready ===")
	print_tree_pretty()

	print("window_layer:", window_layer)
	print("texting_app_button:", texting_app_button)

	if texting_app_button:
		texting_app_button.pressed.connect(_on_texting_app_icon_pressed)
		print("Connected button signal.")
	else:
		push_warning("TextingAppButton not found from this node. Check hierarchy/path.")

func _on_texting_app_icon_pressed() -> void:
	print("TextingAppButton pressed")
	open_app("texting_app")

func open_app(app_id: String) -> void:
	# already open? just focus/bring-to-front
	if open_apps.has(app_id):
		_focus_app(open_apps[app_id])
		return

	if not APP_SCENES.has(app_id):
		push_warning("No scene registered for app_id: %s" % app_id)
		return

	var scene: PackedScene = APP_SCENES[app_id]
	var app_instance := scene.instantiate() as AppBase

	app_instance.init(self)
	window_layer.add_child(app_instance)

	# fixed window size (no resizing)
	@warning_ignore("shadowed_variable_base_class")
	var size := app_instance.custom_minimum_size
	if size == Vector2.ZERO:
		size = Vector2(400, 260) # fallback
	app_instance.size = size

	# center on screen
	await get_tree().process_frame  # wait one frame so WindowLayer has proper size
	app_instance.position = Vector2(
		(window_layer.size.x - app_instance.size.x) / 2.0,
		(window_layer.size.y - app_instance.size.y) / 2.0
	)

	_attach_close_button(app_instance)

	open_apps[app_id] = app_instance
	app_instance.on_opened()
	_focus_app(app_instance)

func _attach_close_button(app: AppBase) -> void:
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.anchor_right = 1.0
	close_btn.offset_right = -6
	close_btn.offset_top = 6
	# close_btn.size = Vector2(24, 24)
	close_btn.z_index = 100

	close_btn.pressed.connect(_on_close_button_pressed.bind(app))
	app.add_child(close_btn)

func _on_close_button_pressed(app: AppBase) -> void:
	close_app(app)

func close_app(app: AppBase) -> void:
	var id_to_remove := ""
	for id in open_apps.keys():
		if open_apps[id] == app:
			id_to_remove = id
			break
	if id_to_remove != "":
		open_apps.erase(id_to_remove)

	app.on_closed()
	app.queue_free()

func _focus_app(app: AppBase) -> void:
	var max_z := 0
	for child in window_layer.get_children():
		if child is Control:
			max_z = max(max_z, child.z_index)
	app.z_index = max_z + 1
	app.on_focused()
