extends Resource
class_name HistoryEntry

@export var url: String = ""
@export var title: String = ""
@export var timestamp: String = ""
@export var favicon: Texture = null
@export var description: String = ""
@export var page_scene: PackedScene = null  # The actual page content scene

## Codex entries unlocked when this page is visited
@export var codex_entries: Array[Resource] = []  # Can contain BaseItem or Information
