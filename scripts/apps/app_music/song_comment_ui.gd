extends HBoxContainer
class_name SongCommentUI

@onready var user_avatar: TextureRect = $UserAvatar
@onready var user_name: Label = $TextCol/Header/UserName
@onready var time_stamp: Label = $TextCol/Header/TimeStamp
@onready var content: Label = $TextCol/Content

func set_values(_user_avatar: Texture, _user_name: String, _time_stamp: String, _content: String) -> void:
	user_avatar.texture = _user_avatar
	user_name.text = _user_name
	time_stamp.text = _time_stamp
	content.text = _content
	return
