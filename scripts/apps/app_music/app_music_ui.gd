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

func _on_ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	
func _on_play_button_pressed() -> void:
	play_button_pressed.emit()
	return

func _on_pause_button_pressed() -> void:
	pause_button_pressed.emit()
	return

func _on_next_button_pressed() -> void:
	next_button_pressed.emit()
	return
	
func _on_previous_button_pressed() -> void:
	previous_button_pressed.emit()
	return

func _update_comments() -> void:
	
	return

func _update_song_title() -> void:
	return

func _build_comments() -> void:
	if song_comment_ui_scene == null:
		push_warning("There is no assigned song comment ui scene!")
		return
	
func update_music_app_ui() -> void:
	return
