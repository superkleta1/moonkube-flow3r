extends TextureButton
class_name SlotButton

signal picked(payload: Resource)

@onready var selected_overlay: CanvasItem = $SelectedOverlay

var payload: Resource = null

func set_payload(r: Resource) -> void:
	payload = r

	if r != null:
		if "icon" in r and r.icon != null:
			texture_normal = r.icon
		else:
			texture_normal = null

		# Set a non-empty tooltip_text so Godot triggers _make_custom_tooltip on hover
		var has_content: bool = ("display_name" in r and r.display_name != "") \
			or ("description" in r and r.description != "")
		tooltip_text = " " if has_content else ""
	else:
		texture_normal = null
		tooltip_text = ""

func _make_custom_tooltip(_for_text: String) -> Object:
	if payload == null:
		return null

	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	if "display_name" in payload and payload.display_name != "":
		var name_label := Label.new()
		name_label.text = payload.display_name
		name_label.add_theme_font_size_override("font_size", 30)
		vbox.add_child(name_label)

	if "description" in payload and payload.description != "":
		var desc_label := Label.new()
		desc_label.text = payload.description
		desc_label.add_theme_font_size_override("font_size", 30)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(280, 0)
		vbox.add_child(desc_label)

	return panel

func set_selected(v: bool) -> void:
	if selected_overlay != null:
		selected_overlay.visible = v

func _ready() -> void:
	# We control selection ourselves; this avoids weird "stuck pressed" states.
	toggle_mode = false
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if payload != null:
		emit_signal("picked", payload)
