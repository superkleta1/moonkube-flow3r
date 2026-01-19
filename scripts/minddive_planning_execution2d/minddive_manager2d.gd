extends Node2D
class_name MindDiveManager2D

enum State { PLANNING, EXECUTION }
var state: State = State.PLANNING

@onready var planning_mode: Node = $Modes/PlanningMode
@onready var execution_mode: Node = $Modes/ExecutionMode
@onready var planning_ui: Control = $UI/PlanningUI
@onready var execution_ui: Control = $UI/ExecutionUI

@onready var world_tilemap = $World/TileMap
@onready var anchors = $World/PlacedConceptItems
@onready var spirit = $World/Spirit

func _ready() -> void:
	enter_planning() # starts off in planning phase

func enter_planning() -> void:
	_set_state(State.PLANNING)

	planning_ui.set_concepts(RunContext.crafted_concepts)
	planning_ui.concept_selected.connect(_on_concept_selected)

func enter_execution() -> void:
	_set_state(State.EXECUTION)

func _on_concept_selected(ci: ConceptItem) -> void:
	print("Selected: ", ci.description) # description for now bc display name not filled out

func _set_state(new_state: State) -> void:
	state = new_state

	var is_planning := state == State.PLANNING
	planning_ui.visible = is_planning

	execution_ui.visible = not is_planning
