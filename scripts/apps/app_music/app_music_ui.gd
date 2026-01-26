extends Control
class_name MusicAppUI

@export var song_comment_ui_scene: PackedScene

@onready var play_button: Button = $PlayButton
@onready var pause_button: Button = $PauseButton
@onready var next_button: Button = $NextButton
@onready var previous_button: Button = $PreviousButton
@onready var comments_vbox_container: VBoxContainer = $CommentsContainer
@onready var song_title_text: Label = $SongTitle
# unsure...
@onready var music_app_manager: MusicAppManager = $"../../MusicApp"

var song_comment_uis: Array[SongCommentUI]

signal play_button_pressed()
signal pause_button_pressed()
signal next_button_pressed()
signal previous_button_pressed()

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	
	if music_app_manager != null and music_app_manager.has_signal("song_changed"):
		music_app_manager.connect("song_changed", Callable(self, "_on_song_changed"))
	else:
		push_warning("MusicAppUI is missing signal play_button_pressed()")
	
	pause_button.visible = false
	play_button.visible = true

func _on_play_button_pressed() -> void:
	play_button.visible = false
	pause_button.visible = true
	play_button_pressed.emit()
	
	return

func _on_pause_button_pressed() -> void:
	play_button.visible = true
	pause_button.visible = false
	pause_button_pressed.emit()
	return

func _on_next_button_pressed() -> void:
	next_button_pressed.emit()
	return
	
func _on_previous_button_pressed() -> void:
	previous_button_pressed.emit()
	return

func _update_song_title() -> void:
	var current_song: Song = music_app_manager.get_current_song()
	if current_song == null:
		push_error("current_song is null!")
		return
	
	_set_song_title(current_song.title)
	return

func _build_comments() -> void:
	if song_comment_ui_scene == null:
		push_warning("There is no assigned song comment ui scene!")
		return
	
	for c in comments_vbox_container.get_children():
		c.queue_free()
	song_comment_uis.clear()
	
	var current_comments: Array[Comment] = music_app_manager.get_current_comments()
	
	for comment: Comment in current_comments:
		var song_comment_ui := song_comment_ui_scene.instantiate() as SongCommentUI
		comments_vbox_container.add_child(song_comment_ui)
		
		var user := Database.user_db.get_user(comment.user_id)
		if user == null:
			push_error("User with user id", comment.user_id, "is null!")
			
		song_comment_ui.set_values(user.avatar, user.display_name, comment.time_stamp, comment.content)
		song_comment_uis.append(song_comment_ui)
	
func _on_song_changed() -> void:
	_build_comments()
	_update_song_title()
	play_button.visible = false
	pause_button.visible = true
	return

func _set_song_title(song_title: String) -> void:
	if song_title == "":
		push_warning("song_title is empty!")
	
	song_title_text.text = song_title
	return
