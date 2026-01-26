extends Node
class_name DB

@export var song_db: SongDB
@export var user_db: UserDB
@export_file("*.csv") var comments_csv_path: String

var comments: Array[Comment]

func _ready() -> void:
	# optional: validate here
	if song_db == null:
		push_error("song_db not assigned")
	if user_db == null:
		push_error("user_db not assigned")
	
	_parse_csv_to_comments()

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
		comment.time_stamp = row[col.get("timestamp", 3)]
		
		comments.append(comment)
	
	file.close()
	
	return

func get_comments(song_id: String) -> Array[Comment]:
	var song_comments: Array[Comment] = []
	
	for comment: Comment in comments:
		if comment.song_id == song_id:
			song_comments.append(comment)
			
	return song_comments
