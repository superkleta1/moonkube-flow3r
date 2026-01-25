extends Control
class_name MusicAppManager

@export var playlist: Playlist
@export_file("*.csv") var comments_csv_path: String
@onready var music_app_ui: MusicAppUI = $MusicAppUI

var comments: Array[Comment]
var id_to_song: Dictionary[String, Song]
var song_to_id: Dictionary[Song, String]
var songs: Array[Song]
var id_to_user: Dictionary[String, User]
var user_to_id: Dictionary[User, String]

var current_song_id: String
var current_song: Song
var current_comments: Array[Comment]

func _on_ready() -> void:
	_parse_csv_to_comments()
	
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

func set_playlist(_playlist: Playlist) -> void:
	playlist = _playlist

func _parse_csv_to_comments() -> void:
	if comments_csv_path == null:
		push_error("comments_csv_path has not been set!")
		return
	
	if not FileAccess.file_exists(comments_csv_path):
		push_error("comments_csv_path is not a valid file path!")
		return
	
	var file := FileAccess.open(comments_csv_path, FileAccess.READ)
	if file == null:
		push_error("comments_csv_path opens to a null file!")
		return
	
	# header
	var header := file.get_csv_line()
	var col := {}
	for i in header.size():
		col[header[i]] = i

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 0:
			continue
		# skip blank lines that sometimes appear at EOF
		if row.size() == 1 and String(row[0]).strip_edges() == "":
			continue
		
		var comment:= Comment.new()
		comment.song_id = row[col.get("song_id", 0)]
		comment.user_id = row[col.get("user_id", 1)]
		comment.content = row[col.get("content", 2)]
		comment.timestamp = row[col.get("timestamp", 3)]
		
		comments.append(comment)
	
	current_comments = comments
	file.close()
	
	return

func _play() -> void:
	return

func _pause() -> void:
	return

func _next() -> void:
	return

func _previous() -> void:
	return

func get_songs() -> Array[Song]:
	return songs
	
func get_current_comments() -> Array[Comment]:
	return current_comments

func get_user(user_id: String) -> User:
	if not id_to_user.has(user_id):
		push_error("Given user_id", user_id, "is not in id_to_user!")
		return null
	
	return id_to_user[user_id]
