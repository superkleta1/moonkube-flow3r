extends Node3D
class_name MindDiveManager

enum State { PLANNING, EXECUTION }
var state: State = State.PLANNING

@onready var planning_mode: Node = $Modes/PlanningMode
@onready var execution_mode: Node = $Modes/ExecutionMode
@onready var planning_ui: Control = $UI/PlanningUI
@onready var execution_ui: Control = $UI/ExecutionUI

@onready var world_tilemap = $World/GridMapLevel

## Container holding immovable preset concept objects baked into the level.
## Each child should be a PlacedConceptItem node with its concept and cell pre-configured.
## If this node doesn't exist in the scene the dive still runs without presets.
@onready var preset_items_container: Node3D = get_node_or_null("World/PresetConceptItems")

func _ready() -> void:
	enter_planning()

func enter_planning() -> void:
	_set_state(State.PLANNING)

	execution_mode.set_process(false)
	execution_ui.visible = false

	planning_ui.visible = true
	planning_mode.set_process_unhandled_input(true)

	planning_ui.set_concepts(RunContext.crafted_concepts)
	planning_ui.concept_selected.connect(_on_concept_selected)

func enter_execution() -> void:
	_set_state(State.EXECUTION)

	# Disable planning inputs
	planning_mode.set_process_unhandled_input(false)
	planning_ui.visible = false

	# Register any preset concept objects baked into the level
	var presets: Array[PlacedConceptItem] = []
	if preset_items_container != null:
		for child in preset_items_container.get_children():
			var p := child as PlacedConceptItem
			if p != null:
				presets.append(p)
	execution_mode.register_preset_items(presets)

	# Start the dive
	execution_mode.begin_execution(planning_mode.get_placed_items())

	execution_mode.set_process(true)
	execution_ui.visible = true

func _on_concept_selected(ci: ConceptItem) -> void:
	print("Selected: ", ci.display_name)

func _set_state(new_state: State) -> void:
	state = new_state
