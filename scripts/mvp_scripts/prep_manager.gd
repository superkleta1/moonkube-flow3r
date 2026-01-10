extends Control
class_name PreparationManager

@export var config: PrepConfig
@export var slot_button_scene: PackedScene  # assign SlotButton.tscn

@onready var base_row: GridContainer = $BaseItemSelection/GridContainer
@onready var info_row: GridContainer = $InformationSelection/GridContainer
@onready var result_row: GridContainer = $ConceptItemResult/GridContainer
@onready var concept_item_count: Label = $ConceptItemCount
@onready var finished_prep_button: Button = $FinishedPrepButton

var selected_base: BaseItem = null
var selected_infos: Array[Information] = []
var used_base_items: Array[BaseItem] = []
var used_infos: Array[Information] = []
var crafted: Array[ConceptItem] = []

var base_buttons: Dictionary[BaseItem, SlotButton] = {}
var info_buttons: Dictionary[Information, SlotButton] = {}

# Fast lookup: key -> concept
var recipe_lookup: Dictionary[String, ConceptItem] = {}
var recipes: Dictionary[ConceptItem, ConceptRecipe] = {}

func _ready() -> void:
	# fill out the containers
	_build_recipe_lookup()
	_build_base_row()
	_build_info_row()
	
	# refresh the visuals
	_refresh_result_row()
	_refresh_concept_item_count()
	
	# setup callbacks
	finished_prep_button.pressed.connect(_on_finished_prep_button_clicked)
	
	# debugging info
	var g := $"BaseItemSelection/GridContainer" as GridContainer
	print("h_sep = ", g.get_theme_constant("h_separation"))
	print("v_sep = ", g.get_theme_constant("v_separation"))

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
		recipes[r.result] = r

func _make_recipe_key(base_item: BaseItem, infos: Array[Information]) -> String:
	var ids: Array[String] = []
	for i in infos:
		if i != null:
			ids.append(i.id)
	ids.sort()
	return base_item.id + "|" + ",".join(ids)

func _build_base_row() -> void:
	base_buttons.clear()
	for c in base_row.get_children():
		c.queue_free()

	for b: BaseItem in config.base_items:
		if b in used_base_items:
			continue
		var btn: SlotButton = slot_button_scene.instantiate() as SlotButton
		btn.set_payload(b)
		btn.picked.connect(_on_base_picked)
		base_row.add_child(btn)
		base_buttons[b] = btn

func _build_info_row() -> void:
	info_buttons.clear()
	for c in info_row.get_children():
		c.queue_free()

	for info: Information in config.informations:
		if info in used_infos:
			continue
		var btn: SlotButton = slot_button_scene.instantiate() as SlotButton
		btn.set_payload(info)
		btn.picked.connect(_on_info_picked)
		info_row.add_child(btn)
		info_buttons[info] = btn
		
func _refresh_highlights() -> void:
	# Base highlight
	for b in base_buttons.keys():
		var btn := base_buttons[b]
		btn.set_selected(b == selected_base)

	# Info highlight
	for info in info_buttons.keys():
		var btn := info_buttons[info]
		btn.set_selected(selected_infos.has(info))

func _refresh_concept_item_count() -> void:
	concept_item_count.text = "%d / %d" % [crafted.size(), config.max_concept_items]

func _on_base_picked(res: Resource) -> void:
	if selected_base == (res as BaseItem):
		_try_autocraft()
	else:
		selected_base = res as BaseItem
		selected_infos.clear()
	_refresh_highlights()

func _on_info_picked(res: Resource) -> void:
	if selected_base == null:
		return

	var info := res as Information
	if info == null:
		return

	var idx := selected_infos.find(info)
	if idx != -1:
		selected_infos.remove_at(idx)
	else:
		if selected_infos.size() >= selected_base.slot_count:
			selected_infos.remove_at(0)
		selected_infos.append(info)

	_refresh_highlights()
	_try_autocraft()

func _try_autocraft() -> void:
	if selected_base == null:
		return
	if selected_infos.size() != 0 and selected_infos.size() < selected_base.slot_count:
		return
	if crafted.size() >= config.max_concept_items:
		# early out for now, later will add logic to display error notice
		return

	var key := _make_recipe_key(selected_base, selected_infos)
	var result: ConceptItem = recipe_lookup.get(key) as ConceptItem
	if result == null:
		return

	crafted.append(result)
	used_base_items.append(selected_base)
	for info in selected_infos:
		used_infos.append(info)

	selected_base = null
	selected_infos.clear()
	_refresh_highlights()
	_refresh_result_row()
	_build_base_row()
	_build_info_row()
	_refresh_concept_item_count()

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
	
	if ci in recipes:
		var base_to_remove: BaseItem = recipes[ci].base_item
		if base_to_remove != null:
			used_base_items.erase(base_to_remove)
		var infos_to_remove: Array[Information] = recipes[ci].informations
		for info in infos_to_remove:
			used_infos.erase(info)
	_refresh_result_row()
	_build_base_row()
	_build_info_row()
	_refresh_concept_item_count()

func _on_finished_prep_button_clicked() -> void:
	if crafted.size() != config.max_concept_items:
		return
	
	print("KABOOM!")
