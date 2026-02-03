extends TextureButton
class_name CodexCard

## UI component for displaying codex entries (both BaseItem and Information)
## Shows locked/unlocked state and handles click events

@onready var card_image: TextureRect = $CardImage
@onready var highlight_overlay: Panel = $HighlightOverlay
@onready var locked_label: Label = $LockedLabel

var entry: Resource  # Can be BaseItem or Information
var is_locked: bool = true

signal entry_clicked(entry: Resource)


func _ready() -> void:
	toggle_mode = false
	pressed.connect(_on_pressed)


## Set the codex entry to display
func set_entry(_entry: Resource) -> void:
	entry = _entry

	# Check if it's a BaseItem or Information
	var unlocked := false
	var newly_unlocked := false
	var front_image: Texture2D = null

	if entry is BaseItem:
		unlocked = entry.is_unlocked
		newly_unlocked = entry.is_newly_unlocked
		front_image = entry.card_front_image
	elif entry is Information:
		unlocked = entry.is_unlocked
		newly_unlocked = entry.is_newly_unlocked
		front_image = entry.card_front_image

	is_locked = not unlocked

	# Set card image
	if unlocked and front_image:
		card_image.texture = front_image
		locked_label.visible = false
	else:
		# Locked state - show locked label, clear image
		card_image.texture = null
		locked_label.visible = true

	# Show highlight for newly unlocked entries
	highlight_overlay.visible = newly_unlocked

	# Disable interaction for locked cards
	disabled = is_locked


func _on_pressed() -> void:
	if not is_locked:
		entry_clicked.emit(entry)
