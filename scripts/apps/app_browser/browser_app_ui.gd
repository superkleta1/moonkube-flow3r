extends Control
class_name BrowserAppUI

@onready var search_input: LineEdit = $SearchBar/SearchInput
@onready var search_button: Button = $SearchBar/SearchButton
@onready var clear_button: Button = $SearchBar/ClearButton
@onready var history_list_container: VBoxContainer = $HistoryScrollContainer/HistoryListContainer
@onready var browser_app_manager: BrowserAppManager = get_parent()

var history_entry_buttons: Array[HistoryEntryButton] = []

signal search_requested(query: String)
signal entry_clicked(entry: HistoryEntry)

func _ready() -> void:
	search_button.pressed.connect(_on_search_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	search_input.text_submitted.connect(_on_search_text_submitted)

	if browser_app_manager != null and browser_app_manager.has_signal("history_updated"):
		browser_app_manager.connect("history_updated", Callable(self, "_on_history_updated"))
	else:
		push_warning("BrowserAppManager is missing signal history_updated()")

func _on_search_button_pressed() -> void:
	var query := search_input.text
	search_requested.emit(query)

func _on_clear_button_pressed() -> void:
	search_input.text = ""
	search_requested.emit("")

func _on_search_text_submitted(text: String) -> void:
	search_requested.emit(text)

func _on_history_updated() -> void:
	_build_history_list()

func _build_history_list() -> void:
	var history_entry_button_scene := browser_app_manager.get_history_entry_button_scene()

	if history_entry_button_scene == null:
		push_warning("There is no assigned history entry button scene!")
		return

	# Clear existing buttons
	for c in history_list_container.get_children():
		c.queue_free()
	history_entry_buttons.clear()

	var current_entries: Array[HistoryEntry] = browser_app_manager.get_current_entries()

	if current_entries.is_empty():
		# Show "No results" message
		var no_results_label := Label.new()
		no_results_label.text = "No history entries found"
		no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_list_container.add_child(no_results_label)
		return

	# Create button for each entry
	for entry: HistoryEntry in current_entries:
		var history_entry_button := history_entry_button_scene.instantiate() as HistoryEntryButton
		history_list_container.add_child(history_entry_button)
		history_entry_button.set_values(entry)

		# Connect signal
		history_entry_button.entry_clicked.connect(_on_history_entry_clicked)

		history_entry_buttons.append(history_entry_button)

func _on_history_entry_clicked(entry: HistoryEntry) -> void:
	entry_clicked.emit(entry)
