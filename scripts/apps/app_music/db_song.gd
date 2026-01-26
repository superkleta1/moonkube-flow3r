extends Resource
class_name SongDB

@export var id_to_song: Dictionary[String, Song] = {}

func get_song(song_id: String) -> Song:
	if not id_to_song.has(song_id):
		push_error("id_to_song doesn't contain song_id:", song_id)
		return null
	
	return id_to_song.get(song_id)
