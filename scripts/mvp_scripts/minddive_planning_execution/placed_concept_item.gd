extends Node2D
class_name PlacedConceptItem

@onready var sprite: Sprite2D = $Sprite2D
@onready var button: Button = $Button
var concept: ConceptItem

func set_concept(ci: ConceptItem) -> void:
	concept = ci
	if sprite:
		sprite.texture = ci.icon
	
	if button:
		button.tooltip_text = ci.description
