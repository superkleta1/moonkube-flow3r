extends Resource
class_name Playlist

@export var songs: Array[Song]

func get_song_ids() -> Array[String]:
	var song_ids: Array[String]
	for song: Song in songs:
		song_ids.append(song.song_id)
		
	return song_ids
