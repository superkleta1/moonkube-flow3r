extends Resource
class_name ConceptItem

enum SenseType { SEE = 0, HEAR = 1, SMELL = 2}

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var description: String
@export var natsu_notes: String
@export var mesh_scene: PackedScene
@export var sense_type: SenseType

@export var base_attraction: float = 1.0
@export var inspired_scalar: float = 0.0
@export var laziness_scalar: float = 0.0
@export var inspiration_gain: float = 0.0
@export var laziness_gain: float = 0.0
