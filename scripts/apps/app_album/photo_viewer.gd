extends Control
class_name PhotoViewer

@onready var image: TextureRect = $PanelContainer/VBoxContainer/Image
@onready var location: Label = $PanelContainer/VBoxContainer/HBoxContainer/Location
@onready var time: Label = $PanelContainer/VBoxContainer/HBoxContainer/Time

var photo: Photo

func set_values(_photo: Photo) -> void:
	photo = _photo
	image.texture = _photo.image
	location.text = photo.location
	time.text = photo.time
