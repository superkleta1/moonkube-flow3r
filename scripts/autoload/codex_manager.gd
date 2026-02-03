extends Node

## CodexManager - Global singleton for managing Codex unlocks
## Tracks which BaseItems and Information entries have been unlocked

## Signals
signal entry_unlocked(entry: Resource)  # Emitted when a new entry is unlocked
signal entry_viewed(entry: Resource)    # Emitted when player views entry details (clears "new" status)

## All registered codex entries
var all_base_items: Array[BaseItem] = []
var all_information: Array[Information] = []

## Dictionaries for fast lookup: entry_id -> entry
var base_items_dict: Dictionary = {}
var information_dict: Dictionary = {}

## Save file path
const SAVE_PATH := "user://codex_progress.save"

## Unlock state storage
var unlocked_entry_ids: Dictionary = {}  # entry_id -> timestamp
var newly_unlocked_ids: Array[String] = []  # IDs that haven't been viewed yet


func _ready() -> void:
	load_progress()


## Register a BaseItem entry (call this when game loads resources)
func register_base_item(item: BaseItem) -> void:
	if item.id.is_empty():
		push_error("Cannot register BaseItem with empty entry_id")
		return

	if base_items_dict.has(item.id):
		push_warning("BaseItem with ID '%s' already registered" % item.id)
		return

	all_base_items.append(item)
	base_items_dict[item.id] = item

	# Apply saved unlock state
	_apply_unlock_state(item)


## Register a Information entry (call this when game loads resources)
func register_information(info: Information) -> void:
	if info.id.is_empty():
		push_error("Cannot register Information with empty entry_id")
		return

	if information_dict.has(info.id):
		push_warning("Information with ID '%s' already registered" % info.id)
		return

	all_information.append(info)
	information_dict[info.id] = info

	# Apply saved unlock state
	_apply_unlock_state(info)


## HELPER: Load and register all BaseItems from a directory
## Example: CodexManager.load_base_items_from_directory("res://resources/codex/base_items/")
func load_base_items_from_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := dir_path.path_join(file_name)
			var resource := load(full_path)

			if resource is BaseItem:
				register_base_item(resource)
			else:
				push_warning("File %s is not a BaseItem" % file_name)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("Loaded BaseItems from: %s" % dir_path)


## HELPER: Load and register all Information from a directory
## Example: CodexManager.load_information_from_directory("res://resources/codex/information/")
func load_information_from_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := dir_path.path_join(file_name)
			var resource := load(full_path)

			if resource is Information:
				register_information(resource)
			else:
				push_warning("File %s is not a Information" % file_name)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("Loaded Information from: %s" % dir_path)


## HELPER: Register multiple BaseItems from an array
## Example: CodexManager.register_base_items([item1, item2, item3])
func register_base_items(items: Array) -> void:
	for item in items:
		if item is BaseItem:
			register_base_item(item)
		else:
			push_warning("Item is not a BaseItem: %s" % item)


## HELPER: Register multiple Information from an array
## Example: CodexManager.register_information_entries([info1, info2, info3])
func register_information_entries(entries: Array) -> void:
	for entry in entries:
		if entry is Information:
			register_information(entry)
		else:
			push_warning("Entry is not a Information: %s" % entry)


## Unlock entries from a content resource (Song, Photo, Album, HistoryEntry)
func unlock_entries_from_content(content: Resource) -> void:
	if not content.get("codex_entries"):
		return

	var codex_entries: Array = content.get("codex_entries")
	for entry in codex_entries:
		if entry is BaseItem:
			unlock_entry(entry.id)
		elif entry is Information:
			unlock_entry(entry.id)


## Unlock a codex entry by ID
func unlock_entry(entry_id: String) -> void:
	var entry: Resource = null

	# Check if it's a BaseItem
	if base_items_dict.has(entry_id):
		entry = base_items_dict[entry_id]
	# Check if it's Information
	elif information_dict.has(entry_id):
		entry = information_dict[entry_id]
	else:
		push_warning("Codex entry with ID '%s' not found" % entry_id)
		return

	# Already unlocked?
	if is_unlocked(entry_id):
		return

	# Unlock it
	var timestamp := Time.get_unix_time_from_system()
	unlocked_entry_ids[entry_id] = timestamp
	newly_unlocked_ids.append(entry_id)

	# Update entry state
	if entry is BaseItem:
		entry.is_unlocked = true
		entry.unlock_timestamp = timestamp
		entry.is_newly_unlocked = true
	elif entry is Information:
		entry.is_unlocked = true
		entry.unlock_timestamp = timestamp
		entry.is_newly_unlocked = true

	# Save and emit signal
	save_progress()
	entry_unlocked.emit(entry)

	print("Codex entry unlocked: %s - %s" % [entry_id, entry.display_name if entry.has_method("get") else ""])


## Check if an entry is unlocked
func is_unlocked(entry_id: String) -> bool:
	return unlocked_entry_ids.has(entry_id)


## Check if an entry is newly unlocked (hasn't been viewed yet)
func is_newly_unlocked(entry_id: String) -> bool:
	return newly_unlocked_ids.has(entry_id)


## Mark an entry as viewed (removes "new" highlight)
func mark_as_viewed(entry_id: String) -> void:
	if not is_newly_unlocked(entry_id):
		return

	newly_unlocked_ids.erase(entry_id)

	# Update entry state
	var entry: Resource = null
	if base_items_dict.has(entry_id):
		entry = base_items_dict[entry_id]
	elif information_dict.has(entry_id):
		entry = information_dict[entry_id]

	if entry:
		if entry is BaseItem:
			entry.is_newly_unlocked = false
		elif entry is Information:
			entry.is_newly_unlocked = false

		entry_viewed.emit(entry)

	save_progress()


## Get all BaseItems (sorted by unlock status)
func get_all_base_items() -> Array[BaseItem]:
	return all_base_items


## Get all Information entries (sorted by unlock status)
func get_all_information() -> Array[Information]:
	return all_information


## Get count of unlocked BaseItems
func get_unlocked_base_items_count() -> int:
	var count := 0
	for item in all_base_items:
		if item.is_unlocked:
			count += 1
	return count


## Get count of unlocked Information entries
func get_unlocked_information_count() -> int:
	var count := 0
	for info in all_information:
		if info.is_unlocked:
			count += 1
	return count


## Apply saved unlock state to an entry
func _apply_unlock_state(entry: Resource) -> void:
	var entry_id := ""

	if entry is BaseItem:
		entry_id = entry.id
	elif entry is Information:
		entry_id = entry.id
	else:
		return

	if unlocked_entry_ids.has(entry_id):
		var timestamp: int = unlocked_entry_ids[entry_id]

		if entry is BaseItem:
			entry.is_unlocked = true
			entry.unlock_timestamp = timestamp
			entry.is_newly_unlocked = newly_unlocked_ids.has(entry_id)
		elif entry is Information:
			entry.is_unlocked = true
			entry.unlock_timestamp = timestamp
			entry.is_newly_unlocked = newly_unlocked_ids.has(entry_id)


## Save unlock progress to file
func save_progress() -> void:
	var save_data := {
		"unlocked_entry_ids": unlocked_entry_ids,
		"newly_unlocked_ids": newly_unlocked_ids,
		"version": 1
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
	else:
		push_error("Failed to save codex progress to %s" % SAVE_PATH)


## Load unlock progress from file
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data is Dictionary:
			unlocked_entry_ids = save_data.get("unlocked_entry_ids", {})
			newly_unlocked_ids = save_data.get("newly_unlocked_ids", [])
	else:
		push_error("Failed to load codex progress from %s" % SAVE_PATH)


## Debug: Unlock all entries (for testing)
func unlock_all() -> void:
	for item in all_base_items:
		unlock_entry(item.id)
	for info in all_information:
		unlock_entry(info.id)


## Debug: Reset all progress
func reset_progress() -> void:
	unlocked_entry_ids.clear()
	newly_unlocked_ids.clear()

	for item in all_base_items:
		item.is_unlocked = false
		item.unlock_timestamp = 0
		item.is_newly_unlocked = false

	for info in all_information:
		info.is_unlocked = false
		info.unlock_timestamp = 0
		info.is_newly_unlocked = false

	save_progress()
	print("Codex progress reset")
