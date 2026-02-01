extends HBoxContainer
class_name HistoryEntryButton

@onready var favicon_texture: TextureRect = $FaviconTexture
@onready var title_label: Label = $ContentVBox/TitleLabel
@onready var url_label: Label = $ContentVBox/URLLabel
@onready var timestamp_label: Label = $TimestampLabel
@onready var open_button: Button = $OpenButton

var history_entry: HistoryEntry

signal entry_clicked(entry: HistoryEntry)

func _ready() -> void:
	open_button.pressed.connect(_on_open_button_pressed)

func set_values(_history_entry: HistoryEntry) -> void:
	history_entry = _history_entry

	# Set favicon (use default if none)
	if history_entry.favicon != null:
		favicon_texture.texture = history_entry.favicon

	# Set title
	title_label.text = history_entry.title if history_entry.title != "" else "Untitled"

	# Set URL
	url_label.text = history_entry.url

	# Set timestamp
	timestamp_label.text = history_entry.timestamp

func _on_open_button_pressed() -> void:
	entry_clicked.emit(history_entry)
