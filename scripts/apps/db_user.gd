extends Resource
class_name UserDB

@export var id_to_user: Dictionary[String, User] = {}

func get_user(user_id: String) -> User:
	if not  id_to_user.has(user_id):
		push_error("id_to_user doesn't contain user_id:", user_id)
		return null
	
	return id_to_user.get(user_id)
