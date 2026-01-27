extends TextureButton
class_name PhotoButton

@onready var image: TextureRect = $Image

var photo: Photo

signal photo_picked(photo: Photo)

func _ready() -> void:
	# We control selection ourselves; this avoids weird "stuck pressed" states.
	toggle_mode = false
	pressed.connect(_on_pressed)

func set_values(_photo: Photo) -> void:
	photo = _photo
	image.texture = _photo.image

func _on_pressed() -> void:
	photo_picked.emit(photo)
