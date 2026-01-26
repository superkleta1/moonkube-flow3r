extends Control
class_name MusicAppManager

@export var playlist: Playlist

@onready var music_app_ui: MusicAppUI = $MusicAppUI
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# need to cache this probably somewhere else so we don't parse everything again once starting this scene
var songs: Array[Song]

var current_song_index: int = 0
var current_song_id: String = ""
var current_song: Song
var current_comments: Array[Comment]

signal song_changed()

func _ready() -> void:
	if music_app_ui != null and music_app_ui.has_signal("play_button_pressed"):
		music_app_ui.connect("play_button_pressed", Callable(self, "_on_play"))
	else:
		push_warning("MusicAppUI is missing signal play_button_pressed()")
		
	if music_app_ui != null and music_app_ui.has_signal("pause_button_pressed"):
		music_app_ui.connect("pause_button_pressed", Callable(self, "_on_pause"))
	else:
		push_warning("MusicAppUI is missing signal pause_button_pressed()")
	
	if music_app_ui != null and music_app_ui.has_signal("next_button_pressed"):
		music_app_ui.connect("next_button_pressed", Callable(self, "_on_next"))
	else:
		push_warning("MusicAppUI is missing signal next_button_pressed()")
	
	if music_app_ui != null and music_app_ui.has_signal("previous_button_pressed"):
		music_app_ui.connect("previous_button_pressed", Callable(self, "_on_previous"))
	else:
		push_warning("MusicAppUI is missing signal previous_button_pressed()")
	
	if playlist.songs.is_empty():
		push_error("There's no songs in the playlist!")
		return
	
	# default set song to the first in the playlist
	current_song_index = 0
	songs = playlist.songs
	var song: Song = songs[current_song_index]
	current_song_id = song.song_id
	current_song = song
	audio_player.stream = current_song.audio_stream
	
	_update_current_comments()
	song_changed.emit()

func set_playlist(_playlist: Playlist) -> void:
	playlist = _playlist

func _on_play() -> void:
	if current_song == null:
		push_error("current_song is null!")
		return
	
	if not audio_player.stream_paused:
		audio_player.play()
	else:
		audio_player.stream_paused = false
	
	return

func _on_pause() -> void:
	audio_player.stream_paused = true
	return

func _on_next() -> void:
	current_song_index = (current_song_index + 1) % songs.size()
	current_song = songs[current_song_index]
	current_song_id = current_song.song_id
	audio_player.stream = current_song.audio_stream
	audio_player.play()
	_update_current_comments()
	song_changed.emit()
	return

func _on_previous() -> void:
	current_song_index = (current_song_index - 1) % songs.size()
	current_song = songs[current_song_index]
	current_song_id = current_song.song_id
	audio_player.stream = current_song.audio_stream
	audio_player.play()
	_update_current_comments()
	song_changed.emit()
	return

func _update_current_comments() -> void:
	if current_song_id == "":
		push_error("current_song_id is empty!")
		return
	
	current_comments = Database.get_comments(current_song_id)
	if current_comments.is_empty():
		push_warning("current_comments is empty!")
	
	return

func get_songs() -> Array[Song]:
	return songs

func get_current_comments() -> Array[Comment]:
	return current_comments

func get_current_song() -> Song:
	return current_song
