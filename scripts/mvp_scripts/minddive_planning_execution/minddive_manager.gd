extends Node3D
class_name MindDiveManager

enum State { PLANNING, EXECUTION }
var state: State = State.PLANNING

@onready var planning_mode: Node = $Modes/PlanningMode
@onready var execution_mode: Node = $Modes/ExecutionMode
@onready var planning_ui: Control = $UI/PlanningUI
@onready var execution_ui: Control = $UI/ExecutionUI

@onready var world_tilemap = $World/GridMapLevel
@onready var anchors = $World/PlacedConceptItems

func _ready() -> void:
	enter_planning() # starts off in planning phase

func enter_planning() -> void:
	execution_mode.set_process(false)
	execution_ui.visible = false

	planning_ui.visible = true
	planning_mode.set_process_unhandled_input(true)

	planning_ui.set_concepts(RunContext.crafted_concepts)
	planning_ui.concept_selected.connect(_on_concept_selected)

func enter_execution() -> void:
	# Disable planning inputs
	planning_mode.set_process_unhandled_input(false)
	planning_ui.visible = false

	# Start execution using node refs
	execution_mode.begin_execution(planning_mode.get_placed_items())

	execution_mode.set_process(true)
	execution_ui.visible = true

func _on_concept_selected(ci: ConceptItem) -> void:
	print("Selected: ", ci.description) # description for now bc display name not filled out
