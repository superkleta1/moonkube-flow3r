#scripts/texting_app.gd
extends "res://scripts/apps/app_base.gd"

@onready var messages_list: ItemList = $VBoxContainer/Messages
@onready var input_field: LineEdit = $VBoxContainer/InputRow/PlayerInputText
@onready var send_button: Button = $VBoxContainer/InputRow/SendButton

func _ready() -> void:
	app_id = "texting_app"
	app_title = "Texts"

	send_button.pressed.connect(_on_send_pressed)

	# demo messages
	messages_list.add_item("Aki: you alive?")
	messages_list.add_item("You: barely.")

func on_opened() -> void:
	input_field.grab_focus()

func _on_send_pressed() -> void:
	var text := input_field.text.strip_edges()
	if text == "":
		return
	messages_list.add_item("You: %s" % text)
	input_field.text = ""
	input_field.grab_focus()
