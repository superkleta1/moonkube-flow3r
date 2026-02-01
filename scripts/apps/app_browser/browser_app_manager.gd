extends Control
class_name BrowserAppManager

@export var browser_history: BrowserHistory
@export var history_entry_button_scene: PackedScene

@onready var browser_app_ui: BrowserAppUI = $BrowserAppUI

var all_entries: Array[HistoryEntry] = []
var current_entries: Array[HistoryEntry] = []

signal history_updated()

func _ready() -> void:
	if browser_app_ui != null and browser_app_ui.has_signal("search_requested"):
		browser_app_ui.connect("search_requested", Callable(self, "_on_search_requested"))
	else:
		push_warning("BrowserAppUI is missing signal search_requested()")

	if browser_app_ui != null and browser_app_ui.has_signal("entry_clicked"):
		browser_app_ui.connect("entry_clicked", Callable(self, "_on_entry_clicked"))
	else:
		push_warning("BrowserAppUI is missing signal entry_clicked()")

	if browser_history == null or browser_history.history_entries.is_empty():
		push_error("browser_history is null or empty!")
		return

	# Initialize with all entries
	all_entries = browser_history.history_entries
	current_entries = all_entries.duplicate()

	history_updated.emit()

func _on_search_requested(query: String) -> void:
	var trimmed_query := query.strip_edges().to_lower()

	if trimmed_query.is_empty():
		# Show all entries if search is empty
		current_entries = all_entries.duplicate()
	else:
		# Filter entries by search query
		current_entries.clear()
		for entry: HistoryEntry in all_entries:
			if _matches_query(entry, trimmed_query):
				current_entries.append(entry)

	history_updated.emit()

func _matches_query(entry: HistoryEntry, query: String) -> bool:
	# Check if query matches title, URL, or description
	if entry.title.to_lower().contains(query):
		return true
	if entry.url.to_lower().contains(query):
		return true
	if entry.description.to_lower().contains(query):
		return true
	return false

func _on_entry_clicked(entry: HistoryEntry) -> void:
	# Open URL in default browser
	if entry.url != "":
		OS.shell_open(entry.url)
	else:
		push_warning("Tried to open entry with empty URL!")

func get_current_entries() -> Array[HistoryEntry]:
	return current_entries

func get_history_entry_button_scene() -> PackedScene:
	return history_entry_button_scene
