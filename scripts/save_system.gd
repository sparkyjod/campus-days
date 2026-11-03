class_name SaveSystem
extends RefCounted

## Phase 2 save system (master prompt Section 15.2 constraint):
## persist world state as DELTAS against a fixed default state, never a
## full world snapshot. NPC positions are NOT stored — on load, NPCs are
## re-placed by their timetables for the restored day/time (Main does
## that), so a loaded world is always logically consistent.
## Slots: 0 = autosave (written at every sleep), 1-3 = manual slots.

static func default_state() -> Dictionary:
	return {
		"version": 1, "day": 1, "game_minutes": 450.0,
		"player_name": "New Student", "player_major": "Computer Science",
		"appearance": 0,
		"money": 500, "energy": 92.0, "gpa": 7.5, "health": 80.0,
		"stress": 30.0, "social": 50.0,
		"skills": {"Study": 1, "Sport": 1, "Music/Art": 1, "Tech": 1, "Communication": 1},
		"friendships": {}, "memories": {}, "dialogue_seen": {},
		"assignments": [], "attended": [], "jobs_done_day": {}, "jobs_done_total": {},
		"quest_index": 0, "messages": [], "buzz": []
	}

static func compute_delta(state: Dictionary) -> Dictionary:
	# Only keys whose value differs from the default are stored.
	var base := default_state()
	var delta := {}
	for k in state.keys():
		if not base.has(k):
			delta[k] = state[k]
		elif str(base[k]) != str(state[k]):
			delta[k] = state[k]
	delta["version"] = 1
	return delta

static func apply_delta(delta: Dictionary) -> Dictionary:
	var state := default_state()
	for k in delta.keys():
		state[k] = delta[k]
	return state

static func slot_path(slot: int) -> String:
	return "user://campus_save_slot%d.json" % slot

static func save(slot: int, state: Dictionary) -> bool:
	var delta := compute_delta(state)
	var f: FileAccess = FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open slot %d for writing" % slot)
		return false
	f.store_string(JSON.stringify(delta))
	f.close()
	return true

static func load_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(slot_path(slot)):
		return {}
	var f: FileAccess = FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	# Godot 4 FileAccess has no get_as_utf8_string(); read raw bytes.
	var text: String = f.get_buffer(f.get_length()).get_string_from_utf8()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return apply_delta(parsed)
	return {}

static func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))
