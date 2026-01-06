extends Control
class_name PreparationManager

@export var config: PrepConfig
@export var slot_button_scene: PackedScene  # assign SlotButton.tscn

@onready var base_row: HBoxContainer = $BaseItemSelection/HBoxContainer
@onready var info_row: HBoxContainer = $InformationSelection/HBoxContainer
@onready var result_row: HBoxContainer = $ConceptItemResult/HBoxContainer  # adjust to your scene

var selected_base: BaseItem = null
var selected_infos: Array[Information] = []
var crafted: Array[ConceptItem] = []

# Fast lookup: key -> concept
var recipe_lookup: Dictionary[String, ConceptItem] = {}

func _ready() -> void:
	_build_recipe_lookup()
	_build_base_row()
	_build_info_row()
	_refresh_result_row()

func _build_recipe_lookup() -> void:
	recipe_lookup.clear()
	if config == null:
		push_warning("Prep config not set.")
		return

	for r: ConceptRecipe in config.recipes:
		if r.base_item == null or r.result == null:
			continue
		var key := _make_recipe_key(r.base_item, r.informations)
		recipe_lookup[key] = r.result

func _make_recipe_key(base_item: BaseItem, infos: Array[Information]) -> String:
	var ids: Array[String] = []
	for i in infos:
		if i != null:
			ids.append(i.id)
	ids.sort()
	return base_item.id + "|" + ",".join(ids)

func _build_base_row() -> void:
	for c in base_row.get_children():
		c.queue_free()

	for b: BaseItem in config.base_items:
		var btn: SlotButton = slot_button_scene.instantiate() as SlotButton
		btn.set_payload(b)
		btn.picked.connect(_on_base_picked)
		base_row.add_child(btn)

func _build_info_row() -> void:
	for c in info_row.get_children():
		c.queue_free()

	for info: Information in config.informations:
		var btn: SlotButton = slot_button_scene.instantiate() as SlotButton
		btn.set_payload(info)
		btn.picked.connect(_on_info_picked)
		info_row.add_child(btn)

func _on_base_picked(res: Resource) -> void:
	selected_base = res as BaseItem
	selected_infos.clear()
	# Optional: visually indicate selection / clear info highlights
	_try_autocraft()

func _on_info_picked(res: Resource) -> void:
	if selected_base == null:
		# MVP: require base first
		return

	var info := res as Information
	if info == null:
		return

	# Toggle behavior feels best for MVP
	var idx := selected_infos.find(info)
	if idx != -1:
		selected_infos.remove_at(idx)
	else:
		# Enforce base slot_count
		if selected_infos.size() >= selected_base.slot_count:
			# MVP: replace oldest
			selected_infos.remove_at(0)
		selected_infos.append(info)

	_try_autocraft()

func _try_autocraft() -> void:
	if selected_base == null:
		return

	# Only craft when filled all slots (strongly recommended)
	if selected_infos.size() < selected_base.slot_count:
		return

	var key := _make_recipe_key(selected_base, selected_infos)
	var result: ConceptItem = recipe_lookup.get(key) as ConceptItem

	if result == null:
		# MVP: if no recipe, do nothing (or show "??" in UI)
		return

	# Add to crafted list (avoid duplicates if you want)
	crafted.append(result)

	# Reset selection for next craft (common crafting UX)
	selected_base = null
	selected_infos.clear()

	_refresh_result_row()

func _refresh_result_row() -> void:
	for c in result_row.get_children():
		c.queue_free()

	for ci: ConceptItem in crafted:
		var btn: SlotButton = slot_button_scene.instantiate() as SlotButton
		btn.set_payload(ci)
		# Optional: clicking a result removes it
		btn.picked.connect(_on_concept_clicked_to_remove)
		result_row.add_child(btn)

func _on_concept_clicked_to_remove(res: Resource) -> void:
	var ci := res as ConceptItem
	if ci == null:
		return
	var idx := crafted.find(ci)
	if idx != -1:
		crafted.remove_at(idx)
	_refresh_result_row()
