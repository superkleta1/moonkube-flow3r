extends Control
class_name BrowserAppManager

@export var browser_history: BrowserHistory
@export var history_entry_button_scene: PackedScene

@onready var browser_app_ui: BrowserAppUI = $BrowserAppUI

var all_entries: Array[HistoryEntry] = []
var current_entries: Array[HistoryEntry] = []
var current_search_query: String = ""

signal history_updated()
signal show_page(entry: HistoryEntry)
signal show_search_results(query: String, results: Array[HistoryEntry])

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
	current_search_query = trimmed_query

	if trimmed_query.is_empty():
		# Show all history if search is empty (back to history view)
		current_entries = all_entries.duplicate()
		history_updated.emit()
	else:
		# Filter entries by search query
		var search_results: Array[HistoryEntry] = []
		for entry: HistoryEntry in all_entries:
			if _matches_query(entry, trimmed_query):
				search_results.append(entry)

		current_entries = search_results
		show_search_results.emit(trimmed_query, search_results)

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
	# Show the page scene for this entry
	if entry.page_scene != null:
		show_page.emit(entry)
	else:
		push_warning("Entry '%s' has no page_scene assigned!" % entry.title)

func get_current_entries() -> Array[HistoryEntry]:
	return current_entries

func get_history_entry_button_scene() -> PackedScene:
	return history_entry_button_scene
