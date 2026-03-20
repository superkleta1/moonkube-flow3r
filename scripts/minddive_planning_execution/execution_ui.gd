extends Control
class_name ExecutionUI

@export var camera: Camera3D
@export var execution_mode: ExecutionMode

## How close (in screen pixels) the mouse must be to a concept item's projected
## centre before the tooltip appears.
const _HOVER_PX_THRESHOLD: float = 64.0
const _TOOLTIP_OFFSET: Vector2 = Vector2(16.0, 16.0)

var _tooltip: PanelContainer
var _tooltip_name_label: Label
var _tooltip_desc_label: Label
var _hovered_item: PlacedConceptItem = null

# ── Speed controls ───────────────────────────────────────────────────────────
const _SPEED_PRESETS: Array[float]  = [0.25, 0.5, 1.0, 2.0, 4.0]
const _SPEED_LABELS:  Array[String] = ["x¼", "x½", "x1", "x2", "x4"]
const _DEFAULT_SPEED_INDEX: int     = 2   # x1.0

var _speed_panel: PanelContainer
var _speed_buttons: Array[Button]   = []
var _speed_button_group: ButtonGroup

# ── Door counter ─────────────────────────────────────────────────────────────
var _door_panel: PanelContainer
var _door_count_label: Label

# ── Emotion status bar ────────────────────────────────────────────────────────
var _emotion_panel: PanelContainer
var _emotion_bar: ProgressBar
var _emotion_state_label: Label
var _emotion_left_label: Label
var _emotion_right_label: Label
var _emotion_fill_style: StyleBoxFlat

# Fill colours per state
const _COLOR_LEFT_POLE  := Color(0.65, 0.10, 0.10)   # deep red
const _COLOR_NEUTRAL    := Color(0.30, 0.50, 0.72)   # cool blue-grey
const _COLOR_RIGHT_POLE := Color(0.90, 0.75, 0.10)   # warm gold

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tooltip()
	_build_emotion_bar()
	_build_door_counter()
	_build_speed_panel()
	_build_back_button()
	if execution_mode != null:
		execution_mode.emotion_changed.connect(_on_emotion_changed)
		_refresh_emotion_bar(execution_mode.emotion_value, execution_mode.emotion_state)
		execution_mode.door_opened.connect(_on_door_opened)
	visibility_changed.connect(_on_visibility_changed)

# ── Tooltip construction ──────────────────────────────────────────────────────

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	_tooltip.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_tooltip_name_label = Label.new()
	_tooltip_name_label.add_theme_font_size_override("font_size", 30)
	vbox.add_child(_tooltip_name_label)

	_tooltip_desc_label = Label.new()
	_tooltip_desc_label.add_theme_font_size_override("font_size", 30)
	_tooltip_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc_label.custom_minimum_size = Vector2(280.0, 0.0)
	vbox.add_child(_tooltip_desc_label)

	add_child(_tooltip)

# ── Per-frame hover update ────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not visible or camera == null or execution_mode == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var hit := _find_item_at_screen(mouse_pos)

	if hit != _hovered_item:
		_hovered_item = hit
		_show_tooltip_for(_hovered_item)

	if _tooltip.visible:
		_move_tooltip_to(mouse_pos)

# ── Hover detection ───────────────────────────────────────────────────────────

## Projects every active concept item to screen space and returns the closest
## one within _HOVER_PX_THRESHOLD pixels of the mouse, or null if none qualify.
func _find_item_at_screen(screen_pos: Vector2) -> PlacedConceptItem:
	var best: PlacedConceptItem = null
	var best_dist := _HOVER_PX_THRESHOLD

	for item in execution_mode.get_all_items():
		if item == null or not is_instance_valid(item):
			continue
		var item_screen := camera.unproject_position(item.global_position)
		var dist := item_screen.distance_to(screen_pos)
		if dist < best_dist:
			best_dist = dist
			best = item

	return best

# ── Tooltip display ───────────────────────────────────────────────────────────

func _show_tooltip_for(item: PlacedConceptItem) -> void:
	if item == null or item.concept == null:
		_tooltip.visible = false
		return

	var c := item.concept
	var has_name := "display_name" in c and c.display_name != ""
	var has_desc  := "description"  in c and c.description  != ""

	if not has_name and not has_desc:
		_tooltip.visible = false
		return

	_tooltip_name_label.text    = c.display_name if has_name else ""
	_tooltip_name_label.visible = has_name
	_tooltip_desc_label.text    = c.description  if has_desc else ""
	_tooltip_desc_label.visible = has_desc

	_tooltip.visible = true

func _move_tooltip_to(mouse_pos: Vector2) -> void:
	var vp      := get_viewport_rect().size
	var tip_size := _tooltip.size
	if tip_size == Vector2.ZERO:
		tip_size = _tooltip.get_combined_minimum_size()

	var pos := mouse_pos + _TOOLTIP_OFFSET
	pos.x = min(pos.x, vp.x - tip_size.x)
	pos.y = min(pos.y, vp.y - tip_size.y)
	_tooltip.position = pos

# ── Emotion status bar ────────────────────────────────────────────────────────

func _build_emotion_bar() -> void:
	# Outer panel anchored to top-left corner
	_emotion_panel = PanelContainer.new()
	_emotion_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emotion_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_emotion_panel.position = Vector2(20.0, 20.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	_emotion_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Spirit Emotion"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Bar row: left-pole label | ProgressBar | right-pole label
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	_emotion_left_label = Label.new()
	_emotion_left_label.add_theme_font_size_override("font_size", 18)
	_emotion_left_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_emotion_left_label)

	_emotion_bar = ProgressBar.new()
	_emotion_bar.custom_minimum_size = Vector2(220.0, 22.0)
	_emotion_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emotion_bar.show_percentage = false
	# Fill style — reused each refresh to update colour
	_emotion_fill_style = StyleBoxFlat.new()
	_emotion_fill_style.bg_color = _COLOR_NEUTRAL
	_emotion_fill_style.corner_radius_top_left    = 4
	_emotion_fill_style.corner_radius_top_right   = 4
	_emotion_fill_style.corner_radius_bottom_left = 4
	_emotion_fill_style.corner_radius_bottom_right = 4
	_emotion_bar.add_theme_stylebox_override("fill", _emotion_fill_style)
	hbox.add_child(_emotion_bar)

	_emotion_right_label = Label.new()
	_emotion_right_label.add_theme_font_size_override("font_size", 18)
	_emotion_right_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_emotion_right_label)

	# Current state label centred below the bar
	_emotion_state_label = Label.new()
	_emotion_state_label.add_theme_font_size_override("font_size", 20)
	_emotion_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_emotion_state_label)

	add_child(_emotion_panel)

	# Populate pole names and bar range from execution_mode if available
	if execution_mode != null:
		_emotion_left_label.text  = execution_mode.left_pole_name
		_emotion_right_label.text = execution_mode.right_pole_name
		_emotion_bar.min_value = execution_mode.emotion_min
		_emotion_bar.max_value = execution_mode.emotion_max
	else:
		_emotion_left_label.text  = "–"
		_emotion_right_label.text = "–"
		_emotion_bar.min_value = -100.0
		_emotion_bar.max_value =  100.0

	_emotion_bar.value = 0.0
	_emotion_state_label.text = "Neutral"


func _refresh_emotion_bar(value: float, state: ExecutionMode.EmotionState) -> void:
	_emotion_bar.value = value

	match state:
		ExecutionMode.EmotionState.LEFT_POLE:
			_emotion_fill_style.bg_color = _COLOR_LEFT_POLE
			_emotion_state_label.text = execution_mode.left_pole_name if execution_mode else "Left"
		ExecutionMode.EmotionState.RIGHT_POLE:
			_emotion_fill_style.bg_color = _COLOR_RIGHT_POLE
			_emotion_state_label.text = execution_mode.right_pole_name if execution_mode else "Right"
		_:
			_emotion_fill_style.bg_color = _COLOR_NEUTRAL
			_emotion_state_label.text = "Neutral"


func _on_emotion_changed(value: float, state: ExecutionMode.EmotionState) -> void:
	_refresh_emotion_bar(value, state)

# ── Door counter ──────────────────────────────────────────────────────────────

func _build_door_counter() -> void:
	_door_panel = PanelContainer.new()
	_door_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_door_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_door_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_door_panel.position = Vector2(-180.0, 20.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	_door_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Doors"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_door_count_label = Label.new()
	_door_count_label.add_theme_font_size_override("font_size", 28)
	_door_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_door_count_label.text = "0 / 0"
	vbox.add_child(_door_count_label)

	add_child(_door_panel)


func _on_door_opened(_cell: Vector3i, opened_count: int, total_doors: int) -> void:
	_door_count_label.text = "%d / %d" % [opened_count, total_doors]


# ── Speed controls ────────────────────────────────────────────────────────────

func _build_speed_panel() -> void:
	_speed_panel = PanelContainer.new()
	_speed_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_speed_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_speed_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_speed_panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_speed_panel.position        = Vector2(-200.0, -80.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	_speed_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Speed"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	_speed_button_group = ButtonGroup.new()

	for i: int in _SPEED_PRESETS.size():
		var btn := Button.new()
		btn.text        = _SPEED_LABELS[i]
		btn.toggle_mode = true
		btn.button_group = _speed_button_group
		btn.custom_minimum_size = Vector2(64.0, 40.0)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_speed_preset_pressed.bind(i))
		hbox.add_child(btn)
		_speed_buttons.append(btn)

	# Select x1 by default
	_speed_buttons[_DEFAULT_SPEED_INDEX].button_pressed = true

	add_child(_speed_panel)


func _on_speed_preset_pressed(index: int) -> void:
	if execution_mode == null or execution_mode.spirit_grid_mover == null:
		return
	execution_mode.spirit_grid_mover.speed_multiplier = _SPEED_PRESETS[index]


# ── Back to planning button ───────────────────────────────────────────────────

func _build_back_button() -> void:
	var btn := Button.new()
	btn.text = "<  Back to Planning"
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(220.0, 50.0)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	btn.position = Vector2(20.0, -70.0)
	btn.pressed.connect(_on_back_to_planning_pressed)
	add_child(btn)


func _on_back_to_planning_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MindDivePrep.tscn")


func _on_visibility_changed() -> void:
	if visible and execution_mode != null:
		_door_count_label.text = "%d / %d" % [
			execution_mode.get_opened_doors(),
			execution_mode.get_total_doors()
		]
