extends Node
class_name DB

@export var song_db: SongDB
@export var user_db: UserDB

func _ready() -> void:
	# optional: validate here
	if song_db == null:
		push_error("song_db not assigned")
	if user_db == null:
		push_error("user_db not assigned")
