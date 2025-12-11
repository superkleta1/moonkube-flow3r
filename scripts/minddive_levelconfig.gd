# scripts/minddive_levelconfig.gd
extends Resource
class_name MindDiveLevelConfig

@export var level_id: String
@export var victim_id: String

# Items that can appear in this level (you’ll pick a random subset each run)
@export var item_pool: Array[MindDiveItem] = []

# How many doors the victim must pass to “open their heart”
@export var required_doors: int = 3

# The total steps that the victim agent can run
@export var total_steps: int
