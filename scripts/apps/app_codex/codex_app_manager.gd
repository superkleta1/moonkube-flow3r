extends Control
class_name CodexAppManager

## Manager for the Codex App
## Handles building card grids for Base Items and Information tabs

@export var codex_card_scene: PackedScene
@export var codex_detail_viewer_scene: PackedScene

@onready var tab_container: TabContainer = $TabContainer
@onready var base_items_grid: GridContainer = $TabContainer/BaseItems/ScrollContainer/GridContainer
@onready var information_grid: GridContainer = $TabContainer/Information/ScrollContainer/GridContainer
@onready var detail_viewer_anchor: Control = $DetailViewerAnchor

@onready var base_items_count_label: Label = $TabContainer/BaseItems/CountLabel
@onready var information_count_label: Label = $TabContainer/Information/CountLabel

var current_viewer: CodexDetailViewer = null


func _ready() -> void:
	if codex_card_scene == null:
		push_error("codex_card_scene not assigned")
	if codex_detail_viewer_scene == null:
		push_error("codex_detail_viewer_scene not assigned")

	# Build both grids
	_build_base_items_grid()
	_build_information_grid()

	# Listen for codex unlock events to refresh UI
	CodexManager.entry_unlocked.connect(_on_entry_unlocked)
	CodexManager.entry_viewed.connect(_on_entry_viewed)


## Build the Base Items grid
func _build_base_items_grid() -> void:
	# Clear existing cards
	for child in base_items_grid.get_children():
		child.queue_free()

	var all_items := CodexManager.get_all_base_items()

	if all_items.is_empty():
		push_warning("No BaseItems registered in CodexManager")
		return

	# Create a card for each item
	for item: BaseItem in all_items:
		var card := codex_card_scene.instantiate() as CodexCard
		base_items_grid.add_child(card)
		card.set_entry(item)
		card.entry_clicked.connect(_on_entry_clicked)

	# Update count
	var unlocked_count := CodexManager.get_unlocked_base_items_count()
	var total_count := all_items.size()
	base_items_count_label.text = "Unlocked: %d / %d" % [unlocked_count, total_count]


## Build the Information grid
func _build_information_grid() -> void:
	# Clear existing cards
	for child in information_grid.get_children():
		child.queue_free()

	var all_info := CodexManager.get_all_information()

	if all_info.is_empty():
		push_warning("No Information registered in CodexManager")
		return

	# Create a card for each information entry
	for info: Information in all_info:
		var card := codex_card_scene.instantiate() as CodexCard
		information_grid.add_child(card)
		card.set_entry(info)
		card.entry_clicked.connect(_on_entry_clicked)

	# Update count
	var unlocked_count := CodexManager.get_unlocked_information_count()
	var total_count := all_info.size()
	information_count_label.text = "Unlocked: %d / %d" % [unlocked_count, total_count]


## Handle card click - show detail viewer
func _on_entry_clicked(entry: Resource) -> void:
	# Close existing viewer if any
	_close_detail_viewer()

	# Create new detail viewer
	current_viewer = codex_detail_viewer_scene.instantiate() as CodexDetailViewer
	detail_viewer_anchor.add_child(current_viewer)
	current_viewer.set_entry(entry)
	current_viewer.exit_pressed.connect(_close_detail_viewer)


## Close the detail viewer
func _close_detail_viewer() -> void:
	if current_viewer:
		current_viewer.queue_free()
		current_viewer = null
	else:
		# Fallback: clear all children from anchor
		for child in detail_viewer_anchor.get_children():
			child.queue_free()


## Handle new unlock - refresh the grids
func _on_entry_unlocked(entry: Resource) -> void:
	if entry is BaseItem:
		_build_base_items_grid()
	elif entry is Information:
		_build_information_grid()


## Handle entry viewed - refresh to remove highlight
func _on_entry_viewed(entry: Resource) -> void:
	if entry is BaseItem:
		_build_base_items_grid()
	elif entry is Information:
		_build_information_grid()
