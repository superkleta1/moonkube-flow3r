extends Resource
class_name MindDiveLevelConfig

@export var level_id: String
@export var victim_id: String

@export var item_pool: Array[Item] = []
@export var draw_count: int = 3
@export var required_doors: int = 1
