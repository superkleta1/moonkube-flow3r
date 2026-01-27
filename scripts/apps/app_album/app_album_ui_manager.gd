extends Control
class_name AlbumAppUIManager

@export var album: Album
@export var photo_button_ui_scene: PackedScene
@export var photo_viewer_ui_scene: PackedScene

@onready var photos_grid_container: GridContainer = $MarginContainer/ScrollContainer/GridContainer
@onready var photo_viewer_anchor: Control = $PhotoViewerAnchor

func _ready() -> void:
	if photo_button_ui_scene == null:
		push_error("photo_button not assigned")
	if photo_viewer_ui_scene == null:
		push_error("photo_viewer not assigned")
	
	_build_photos()

func set_album(_album: Album) -> void:
	album = _album
	return

func _build_photos() -> void:
	for c in photos_grid_container.get_children():
		c.queue_free()
	
	if album == null || album.photos.is_empty():
		push_error("album is null or empty!")
		return
	
	for photo: Photo in album.photos:
		var photo_button := photo_button_ui_scene.instantiate() as PhotoButton
		photos_grid_container.add_child(photo_button)
		photo_button.set_values(photo)
		
		print("PATH=", photo_button_ui_scene.resource_path,
			"  class=", photo_button.get_class(),
			"  script=", photo_button.get_script(),
			"  is PhotoButton? ", photo_button is PhotoButton)
		
		photo_button.photo_picked.connect(_on_photo_picked)
		
	return

func _on_photo_picked(photo: Photo) -> void:
	var photo_viewer := photo_viewer_ui_scene.instantiate() as PhotoViewer
	photo_viewer_anchor.add_child(photo_viewer)
	photo_viewer.set_values(photo)
	return
