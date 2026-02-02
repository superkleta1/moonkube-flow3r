extends Control
class_name CodexDetailViewer

## Detail view for viewing unlocked codex entries
## Shows full image, title, description, and unlock date

@onready var entry_image: TextureRect = $PanelContainer/VBoxContainer/ImageContainer/EntryImage
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/VBoxContainer/DescriptionScroll/DescriptionLabel
@onready var unlock_info_label: Label = $PanelContainer/VBoxContainer/UnlockInfoLabel
@onready var exit_button: Button = $ExitButton

var entry: Resource  # Can be CodexBaseItem or CodexInformation

signal exit_pressed()


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_button_pressed)


## Set the codex entry to display
func set_entry(_entry: Resource) -> void:
	entry = _entry

	var title_text := ""
	var description_text := ""
	var image: Texture2D = null
	var unlock_timestamp: int = 0
	var category_or_rarity := ""

	if entry is CodexBaseItem:
		title_text = entry.title
		description_text = entry.description
		image = entry.card_front_image
		unlock_timestamp = entry.unlock_timestamp
		category_or_rarity = "Rarity: %s" % entry.rarity.capitalize()
	elif entry is CodexInformation:
		title_text = entry.title
		description_text = entry.description
		image = entry.card_front_image
		unlock_timestamp = entry.unlock_timestamp
		category_or_rarity = "Category: %s" % entry.category.capitalize()

	# Set UI elements
	title_label.text = title_text
	description_label.text = description_text
	entry_image.texture = image

	# Format unlock date
	if unlock_timestamp > 0:
		var datetime := Time.get_datetime_dict_from_unix_time(unlock_timestamp)
		var date_str := "%04d-%02d-%02d %02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute
		]
		unlock_info_label.text = "%s\nUnlocked: %s" % [category_or_rarity, date_str]
	else:
		unlock_info_label.text = category_or_rarity

	# Mark as viewed in CodexManager
	if entry is CodexBaseItem:
		CodexManager.mark_as_viewed(entry.entry_id)
	elif entry is CodexInformation:
		CodexManager.mark_as_viewed(entry.entry_id)


func _on_exit_button_pressed() -> void:
	exit_pressed.emit()
