extends Resource
class_name Album

@export var photos: Array[Photo]

## Codex entries unlocked when this album is opened
@export var codex_entries: Array[Resource] = []  # Can contain BaseItem or Information
