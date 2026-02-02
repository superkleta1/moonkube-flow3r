extends Resource
class_name Song

@export var song_id: String
@export var title: String
@export var audio_stream: AudioStream

## Codex entries unlocked when this song is played
@export var codex_entries: Array[Resource] = []  # Can contain CodexBaseItem or CodexInformation
