extends Resource
class_name ConceptItem

## A Concept Object — the player places these on the grid before the dive begins.
## They influence the Soul through three core effect types:
##   1. Attraction Weight (positive = draws Soul toward it, negative = repels)
##   2. Emotion Value Influence (shifts Soul's emotion axis per tick while active)
##   3. (Indirect) Proximity interactions with other concept objects (see ProximityRule)

enum SenseType {
	SEE   = 0,  # Visual — cone FOV, line-of-sight required, influence stops when out of view
	HEAR  = 1,  # Auditory — global, always active regardless of position
	SMELL = 2,  # Olfactory — global, always active regardless of position
}

enum PlacementType {
	SLOT = 0,  # Standard — placed on SLOT cells during pre-dive phase
	PATH = 1,  # Emotion Gate — placed on any PATH cell; Soul walks through it
}

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var description: String
@export var mesh_scene: PackedScene

## Where this concept can be placed on the grid
@export var placement_type: PlacementType = PlacementType.SLOT

## How this concept is perceived by the Soul
@export var sense_type: SenseType

# ── Attraction ───────────────────────────────────────────────────────────────

## Unconditional attraction weight — applied regardless of the Soul's emotion state.
## Positive = draws Soul toward this object. Negative = pushes Soul away (repulsion).
@export var base_attraction: float = 0.0

## Additional attraction modifier when the Soul is in the LEFT pole state (e.g. Despair).
## Added on top of base_attraction while the Soul is in that state.
@export var left_pole_attraction: float = 0.0

## Additional attraction modifier when the Soul is in the RIGHT pole state (e.g. Hope).
## Added on top of base_attraction while the Soul is in that state.
@export var right_pole_attraction: float = 0.0

# ── Emotion Influence ────────────────────────────────────────────────────────

## Emotion influence applied per tick while this concept is active via its sense channel.
## Positive = shifts toward RIGHT pole (e.g. Hope).
## Negative = shifts toward LEFT pole (e.g. Despair).
## For HEAR/SMELL: applied every step globally.
## For SEE: applied only while the object is within the Soul's field of view.
@export var base_emotion_influence: float = 0.0

# ── Proximity Interactions ───────────────────────────────────────────────────

## If true, this object suppresses ALL other nearby concept objects,
## reducing their attraction weights based on proximity distance.
@export var is_suppressor: bool = false

## Per-pair proximity interaction rules for RESONANCE or INTERFERENCE with specific concepts.
## When another placed concept matching a rule's other_concept_id is within range,
## both objects' attraction weights are amplified (resonance) or weakened (interference).
@export var proximity_rules: Array[ProximityRule] = []

# ── Emotion Gate (only used when placement_type == PATH) ─────────────────────

## Emotion shift applied when the Soul walks through this gate, indexed by movement direction.
## [0] = North (moving toward -Z)  [1] = East (moving toward +X)
## [2] = South (moving toward +Z)  [3] = West (moving toward -X)
## Positive = toward RIGHT pole (Hope). Negative = toward LEFT pole (Despair).
@export var gate_emotion_shifts: Array[float] = [0.0, 0.0, 0.0, 0.0]
