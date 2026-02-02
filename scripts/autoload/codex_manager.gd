extends Node

## CodexManager - Global singleton for managing Codex unlocks
## Tracks which BaseItems and Information entries have been unlocked

## Signals
signal entry_unlocked(entry: Resource)  # Emitted when a new entry is unlocked
signal entry_viewed(entry: Resource)    # Emitted when player views entry details (clears "new" status)

## All registered codex entries
var all_base_items: Array[CodexBaseItem] = []
var all_information: Array[CodexInformation] = []

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


## Register a CodexBaseItem entry (call this when game loads resources)
func register_base_item(item: CodexBaseItem) -> void:
	if item.entry_id.is_empty():
		push_error("Cannot register CodexBaseItem with empty entry_id")
		return

	if base_items_dict.has(item.entry_id):
		push_warning("CodexBaseItem with ID '%s' already registered" % item.entry_id)
		return

	all_base_items.append(item)
	base_items_dict[item.entry_id] = item

	# Apply saved unlock state
	_apply_unlock_state(item)


## Register a CodexInformation entry (call this when game loads resources)
func register_information(info: CodexInformation) -> void:
	if info.entry_id.is_empty():
		push_error("Cannot register CodexInformation with empty entry_id")
		return

	if information_dict.has(info.entry_id):
		push_warning("CodexInformation with ID '%s' already registered" % info.entry_id)
		return

	all_information.append(info)
	information_dict[info.entry_id] = info

	# Apply saved unlock state
	_apply_unlock_state(info)


## Unlock entries from a content resource (Song, Photo, Album, HistoryEntry)
func unlock_entries_from_content(content: Resource) -> void:
	if not content.get("codex_entries"):
		return

	var codex_entries: Array = content.get("codex_entries")
	for entry in codex_entries:
		if entry is CodexBaseItem:
			unlock_entry(entry.entry_id)
		elif entry is CodexInformation:
			unlock_entry(entry.entry_id)


## Unlock a codex entry by ID
func unlock_entry(entry_id: String) -> void:
	var entry: Resource = null

	# Check if it's a CodexBaseItem
	if base_items_dict.has(entry_id):
		entry = base_items_dict[entry_id]
	# Check if it's CodexInformation
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
	if entry is CodexBaseItem:
		entry.is_unlocked = true
		entry.unlock_timestamp = timestamp
		entry.is_newly_unlocked = true
	elif entry is CodexInformation:
		entry.is_unlocked = true
		entry.unlock_timestamp = timestamp
		entry.is_newly_unlocked = true

	# Save and emit signal
	save_progress()
	entry_unlocked.emit(entry)

	print("Codex entry unlocked: %s - %s" % [entry_id, entry.title if entry.has_method("get") else ""])


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
		if entry is CodexBaseItem:
			entry.is_newly_unlocked = false
		elif entry is CodexInformation:
			entry.is_newly_unlocked = false

		entry_viewed.emit(entry)

	save_progress()


## Get all CodexBaseItems (sorted by unlock status)
func get_all_base_items() -> Array[CodexBaseItem]:
	return all_base_items


## Get all CodexInformation entries (sorted by unlock status)
func get_all_information() -> Array[CodexInformation]:
	return all_information


## Get count of unlocked CodexBaseItems
func get_unlocked_base_items_count() -> int:
	var count := 0
	for item in all_base_items:
		if item.is_unlocked:
			count += 1
	return count


## Get count of unlocked CodexInformation entries
func get_unlocked_information_count() -> int:
	var count := 0
	for info in all_information:
		if info.is_unlocked:
			count += 1
	return count


## Apply saved unlock state to an entry
func _apply_unlock_state(entry: Resource) -> void:
	var entry_id := ""

	if entry is CodexBaseItem:
		entry_id = entry.entry_id
	elif entry is CodexInformation:
		entry_id = entry.entry_id
	else:
		return

	if unlocked_entry_ids.has(entry_id):
		var timestamp: int = unlocked_entry_ids[entry_id]

		if entry is CodexBaseItem:
			entry.is_unlocked = true
			entry.unlock_timestamp = timestamp
			entry.is_newly_unlocked = newly_unlocked_ids.has(entry_id)
		elif entry is CodexInformation:
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
		unlock_entry(item.entry_id)
	for info in all_information:
		unlock_entry(info.entry_id)


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
