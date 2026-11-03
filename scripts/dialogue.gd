class_name Dialogue
extends RefCounted

## Phase 2 dialogue engine (Section 19.2): topic-based, context-aware,
## no-repeat-until-exhausted per character per topic, with cross-day
## memory callbacks. Banks live in Phase2Data; this class only picks.
## npc.dialogue_seen: Dictionary topic -> Array[int] of used indices.
## npc.memory_notes: Array[String] written by Main after conversations.

static func bank_for(npc: NPC, topic: String) -> Array:
	var name := str(npc.data.get("name", ""))
	if npc.is_teacher:
		var tb: Dictionary = Phase2Data.teachers_dialogue()
		var entry: Dictionary = tb.get(name, {})
		# Teachers: UI topics map — classes->classes, fest->career,
		# gossip->career, personal->personal.
		var key := topic
		if topic == "fest" or topic == "gossip":
			key = "career"
		var lines: Array = entry.get(key, [])
		if lines.is_empty():
			lines = entry.get("classes", [])
		return lines
	var mb: Dictionary = Phase2Data.mains_dialogue()
	var mentry: Dictionary = mb.get(name, {})
	var mlines: Array = mentry.get(topic, [])
	if mlines.is_empty():
		mlines = mentry.get("classes", [])
	return mlines

static func context_prefix(zone: String, hour: float) -> String:
	var snips: Dictionary = Phase2Data.context_snippets()
	var key := ""
	if zone == "library" and hour >= 20.0:
		key = "library_night"
	elif zone == "library":
		key = "library_day"
	elif zone == "foodcourt" and hour >= 13.0 and hour < 14.0:
		key = "foodcourt_lunch"
	elif zone == "quad" and hour >= 18.0:
		key = "quad_evening"
	elif zone == "sports" and hour >= 17.0:
		key = "sports_evening"
	elif zone == "garden" and hour >= 17.0:
		key = "garden_evening"
	elif hour < 9.0:
		key = "morning"
	if key == "":
		return ""
	var arr: Array = snips.get(key, [])
	if arr.is_empty():
		return ""
	return str(arr[0])

static func pick_line(npc: NPC, topic: String, zone: String, hour: float, day: int) -> String:
	var lines: Array = bank_for(npc, topic)
	if lines.is_empty():
		return "Hello! Good to see you around campus."
	# Memory callback: every 3rd chat, recall the last noted moment
	# instead of a fresh bank line (notes persist across days via save).
	if npc.memory_notes.size() > 0 and npc.chats > 0 and npc.chats % 3 == 0:
		var last: String = str(npc.memory_notes[npc.memory_notes.size() - 1])
		return "You know, I was just thinking about %s — funny how that stuck with me." % last
	var seen: Array = npc.dialogue_seen.get(topic, [])
	if seen.size() >= lines.size():
		seen = [] # bank exhausted: only now may lines repeat (after a full cycle)
	var idx := 0
	for i in range(lines.size()):
		if not seen.has(i):
			idx = i
			break
	seen.append(idx)
	npc.dialogue_seen[topic] = seen
	var prefix := context_prefix(zone, hour)
	return prefix + str(lines[idx])

static func tier_name(f: int) -> String:
	if f < 20:
		return "New face"
	elif f < 40:
		return "Acquaintance"
	elif f < 60:
		return "Friend"
	elif f < 80:
		return "Close Friend"
	return "Best Friend"
