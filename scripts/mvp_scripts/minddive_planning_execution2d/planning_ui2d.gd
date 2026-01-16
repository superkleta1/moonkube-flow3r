extends Control
class_name PlanningUI2D

@export var slot_button_scene: PackedScene

@onready var vcontainer: VBoxContainer = $AvailableConceptItems/ScrollContainer/VBoxContainer
@onready var planning_mode: Node = $"../..//Modes/PlanningMode"
@onready var start_execution_button: Button = $StartExecutionButton
@onready var minddive_manager: Node2D = $"../../..//MindDive"

var selected_concept_item: ConceptItem

signal concept_selected(concept: ConceptItem)

var _concepts: Array[ConceptItem] = []
var _placed_concepts: Array[ConceptItem] = []

func _ready() -> void:
	if planning_mode.has_signal("concept_placed"):
		planning_mode.connect("concept_placed", Callable(self, "_on_concept_placed"))
	else:
		push_warning("PlanningMode is missing signal concept_placed(concept: ConceptItem)")
	
	if planning_mode.has_signal("concept_removed"):
		planning_mode.connect("concept_removed", Callable(self, "_on_concept_removed"))
	else:
		push_warning("PlanningMode is missing signal concept_removed(concept: ConceptItem)")
	
	start_execution_button.pressed.connect(_on_start_execution_button_pressed)

func set_concepts(concepts: Array[ConceptItem]) -> void:
	_concepts = concepts
	_rebuild()

func _rebuild() -> void:
	for c in vcontainer.get_children():
		c.queue_free()

	for ci: ConceptItem in _concepts:
		if ci in _placed_concepts:
			continue
		var btn := slot_button_scene.instantiate() as SlotButton
		btn.set_payload(ci)
		btn.picked.connect(_on_picked)
		vcontainer.add_child(btn)
		btn.set_selected(ci == selected_concept_item)

func _on_picked(res: Resource) -> void:
	var ci := res as ConceptItem
	if ci == null:
		return
	concept_selected.emit(ci)
	selected_concept_item = ci
	_rebuild()

func _on_concept_placed(concept: ConceptItem) -> void:
	_placed_concepts.append(concept)
	selected_concept_item = null
	_rebuild()

func _on_concept_removed(concept: ConceptItem) -> void:
	_placed_concepts.erase(concept)
	selected_concept_item = null
	_rebuild()

func _on_start_execution_button_pressed() -> void:
	minddive_manager.enter_execution()
