extends TextureButton
class_name CodexCard

## UI component for displaying codex entries (both CodexBaseItem and CodexInformation)
## Shows locked/unlocked state and handles click events

@onready var card_image: TextureRect = $CardImage
@onready var highlight_overlay: Panel = $HighlightOverlay
@onready var locked_label: Label = $LockedLabel

var entry: Resource  # Can be CodexBaseItem or CodexInformation
var is_locked: bool = true

signal entry_clicked(entry: Resource)


func _ready() -> void:
	toggle_mode = false
	pressed.connect(_on_pressed)


## Set the codex entry to display
func set_entry(_entry: Resource) -> void:
	entry = _entry

	# Check if it's a CodexBaseItem or CodexInformation
	var unlocked := false
	var newly_unlocked := false
	var front_image: Texture2D = null
	var back_image: Texture2D = null

	if entry is CodexBaseItem:
		unlocked = entry.is_unlocked
		newly_unlocked = entry.is_newly_unlocked
		front_image = entry.card_front_image
		back_image = entry.card_back_image
	elif entry is CodexInformation:
		unlocked = entry.is_unlocked
		newly_unlocked = entry.is_newly_unlocked
		front_image = entry.card_front_image
		back_image = entry.card_back_image

	is_locked = not unlocked

	# Set card image
	if unlocked and front_image:
		card_image.texture = front_image
		locked_label.visible = false
	elif back_image:
		card_image.texture = back_image
		locked_label.visible = true
	else:
		# Fallback: use a solid color or default texture
		locked_label.visible = true

	# Show highlight for newly unlocked entries
	highlight_overlay.visible = newly_unlocked

	# Disable interaction for locked cards
	disabled = is_locked


func _on_pressed() -> void:
	if not is_locked:
		entry_clicked.emit(entry)
