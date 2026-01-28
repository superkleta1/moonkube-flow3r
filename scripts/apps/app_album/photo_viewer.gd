extends Control
class_name PhotoViewer

@onready var image: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/Image
@onready var location: Label = $PanelContainer/VBoxContainer/HBoxContainer1/Location
@onready var time: Label = $PanelContainer/VBoxContainer/HBoxContainer1/Time
@onready var exit_button: Button = $ExitButton

var photo: Photo

signal exit_pressed()

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_button_pressed)

func set_values(_photo: Photo) -> void:
	photo = _photo
	image.texture = _photo.image_photo_view
	location.text = photo.location
	time.text = photo.time

func _on_exit_button_pressed() -> void:
	exit_pressed.emit()
