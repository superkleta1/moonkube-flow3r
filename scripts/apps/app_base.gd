# scripts/app_base.gd
extends Panel
class_name AppBase

@export var app_id: String = ""
@export var app_title: String = ""

var os: Node = null  # reference to ComputerScreen

func init(os_ref: Node) -> void:
	os = os_ref

func on_opened() -> void:
	# Called when the window is first shown
	pass

func on_focused() -> void:
	# Called when brought to front
	pass

func on_closed() -> void:
	# Called right before closing
	pass
