extends TextureButton
class_name SlotButton

signal picked(payload: Resource)

@onready var selected_overlay: CanvasItem = $SelectedOverlay

var payload: Resource = null

func set_payload(r: Resource) -> void:
	payload = r

	# If you use TextureButton's built-in textures:
	if r != null and "icon" in r and r.icon != null:
		texture_normal = r.icon
	else:
		texture_normal = null
		
	if r != null:
		if "icon" in r and r.icon != null:
			texture_normal = r.icon
		else:
			texture_normal = null
		
		if "description" in r and r.description != null:
			tooltip_text = r.description
	else:
		texture_normal = null

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
