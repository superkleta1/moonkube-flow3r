extends Control
class_name PlanningUI

@export var slot_button_scene: PackedScene
@onready var vcontainer: VBoxContainer = $AvailableConceptItems/ScrollContainer/VBoxContainer

signal concept_selected(concept: ConceptItem)

var _concepts: Array[ConceptItem] = []

func set_concepts(concepts: Array[ConceptItem]) -> void:
	_concepts = concepts
	_rebuild()

func _rebuild() -> void:
	for c in vcontainer.get_children():
		c.queue_free()

	for ci: ConceptItem in _concepts:
		var btn := slot_button_scene.instantiate() as SlotButton
		btn.set_payload(ci)
		btn.picked.connect(_on_picked)
		vcontainer.add_child(btn)

func _on_picked(res: Resource) -> void:
	var ci := res as ConceptItem
	if ci == null:
		return
	concept_selected.emit(ci)
