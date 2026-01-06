extends TextureButton
class_name SlotButton

signal picked(payload: Resource)

var payload: Resource = null

func set_payload(r: Resource) -> void:
	payload = r
	texture_normal = null
	if r == null:
		return
	if "icon" in r and r.icon != null:
		texture_normal = r.icon

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if payload != null:
		emit_signal("picked", payload)
