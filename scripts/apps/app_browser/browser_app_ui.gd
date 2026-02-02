extends Control
class_name BrowserAppUI

@onready var search_input: LineEdit = $SearchBar/SearchInput
@onready var search_button: Button = $SearchBar/SearchButton
@onready var clear_button: Button = $SearchBar/ClearButton
@onready var history_view_container: Control = $HistoryViewContainer
@onready var history_list_container: VBoxContainer = $HistoryViewContainer/HistoryScrollContainer/HistoryListContainer
@onready var search_results_view_container: Control = $SearchResultsViewContainer
@onready var search_results_list_container: VBoxContainer = $SearchResultsViewContainer/SearchResultsScrollContainer/SearchResultsListContainer
@onready var search_results_title: Label = $SearchResultsViewContainer/SearchResultsTitle
@onready var back_to_history_button: Button = $SearchResultsViewContainer/BackToHistoryButton
@onready var page_viewer_anchor: Control = $PageViewerAnchor
@onready var browser_app_manager: BrowserAppManager = get_parent()

var history_entry_buttons: Array[HistoryEntryButton] = []

signal search_requested(query: String)
signal entry_clicked(entry: HistoryEntry)

func _ready() -> void:
	search_button.pressed.connect(_on_search_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	search_input.text_submitted.connect(_on_search_text_submitted)
	back_to_history_button.pressed.connect(_on_back_to_history_pressed)

	if browser_app_manager != null and browser_app_manager.has_signal("history_updated"):
		browser_app_manager.connect("history_updated", Callable(self, "_on_history_updated"))
	else:
		push_warning("BrowserAppManager is missing signal history_updated()")

	if browser_app_manager != null and browser_app_manager.has_signal("show_page"):
		browser_app_manager.connect("show_page", Callable(self, "_on_show_page"))
	else:
		push_warning("BrowserAppManager is missing signal show_page()")

	if browser_app_manager != null and browser_app_manager.has_signal("show_search_results"):
		browser_app_manager.connect("show_search_results", Callable(self, "_on_show_search_results"))
	else:
		push_warning("BrowserAppManager is missing signal show_search_results()")

	# Start with history view visible
	_show_history_view()

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

func _on_show_page(entry: HistoryEntry) -> void:
	# Unlock codex entries when page is visited
	CodexManager.unlock_entries_from_content(entry)

	# Instantiate and show the page scene
	if entry.page_scene == null:
		push_error("Entry '%s' has no page_scene!" % entry.title)
		return

	# Clear any existing page
	for child in page_viewer_anchor.get_children():
		child.queue_free()

	# Instantiate the page
	var page_instance := entry.page_scene.instantiate()
	page_viewer_anchor.add_child(page_instance)

	# Connect back button if page extends PageBase
	if page_instance.has_signal("back_pressed"):
		page_instance.connect("back_pressed", Callable(self, "close_page_viewer"))

	# Show page viewer, hide other views
	page_viewer_anchor.visible = true
	history_view_container.visible = false
	search_results_view_container.visible = false

func _on_show_search_results(query: String, results: Array[HistoryEntry]) -> void:
	# Update search results title
	search_results_title.text = "Search results for: \"%s\"" % query

	# Build the search results list
	_build_search_results_list(results)

	# Show search results view, hide history view
	search_results_view_container.visible = true
	history_view_container.visible = false
	page_viewer_anchor.visible = false

func _on_back_to_history_pressed() -> void:
	_show_history_view()

func _show_history_view() -> void:
	# Clear search input
	search_input.text = ""

	# Show history view, hide others
	history_view_container.visible = true
	search_results_view_container.visible = false
	page_viewer_anchor.visible = false

func _build_search_results_list(results: Array[HistoryEntry]) -> void:
	var history_entry_button_scene := browser_app_manager.get_history_entry_button_scene()

	if history_entry_button_scene == null:
		push_warning("There is no assigned history entry button scene!")
		return

	# Clear existing buttons
	for c in search_results_list_container.get_children():
		c.queue_free()

	if results.is_empty():
		# Show "No results" message
		var no_results_label := Label.new()
		no_results_label.text = "No results found"
		no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		search_results_list_container.add_child(no_results_label)
		return

	# Create button for each result
	for entry: HistoryEntry in results:
		var history_entry_button := history_entry_button_scene.instantiate() as HistoryEntryButton
		search_results_list_container.add_child(history_entry_button)
		history_entry_button.set_values(entry)

		# Connect signal
		history_entry_button.entry_clicked.connect(_on_history_entry_clicked)

func close_page_viewer() -> void:
	# Clear the page viewer
	for child in page_viewer_anchor.get_children():
		child.queue_free()

	# Return to previous view (check if we were in search results or history)
	if search_results_view_container.visible or browser_app_manager.current_search_query != "":
		search_results_view_container.visible = true
		page_viewer_anchor.visible = false
	else:
		_show_history_view()
