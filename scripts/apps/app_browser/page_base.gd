extends Control
class_name PageBase

## Base class for browser pages
## Your UI/UX designer can extend this for custom page implementations

@onready var back_button: Button = $BackButton

signal back_pressed()

func _ready() -> void:
	# Override this in child classes for custom initialization
	back_button.pressed.connect(close_page)
	pass

func close_page() -> void:
	# Call this to close the page and return to browser
	back_pressed.emit()
