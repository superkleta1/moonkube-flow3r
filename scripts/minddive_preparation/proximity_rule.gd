extends Resource
class_name ProximityRule

## Defines how two specific concept objects interact when within proximity range.
## Proximity interactions modify each object's attraction weight based on distance.
## SUPPRESSION is a property of the item itself (is_suppressor on ConceptItem),
## not a per-pair rule — so it is not listed here.

enum InteractionType {
	NEUTRAL,       # No effect on each other
	RESONANCE,     # Both amplify each other's attraction weight
	INTERFERENCE,  # Both weaken each other's attraction weight
}

## The ID of the other ConceptItem this rule applies to.
## Must match ConceptItem.id of the partner concept.
@export var other_concept_id: String

## How the two objects interact when within proximity range.
@export var interaction_type: InteractionType = InteractionType.NEUTRAL

## How strongly the interaction scales (multiplier on the falloff factor).
## 0.5 = moderate, 1.0 = full-strength resonance/interference
@export_range(0.0, 2.0, 0.01) var strength: float = 0.5
