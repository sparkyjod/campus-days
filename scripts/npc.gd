class_name NPC
extends Node3D

## A campus person: main character, background student or staff member.
## Moves along waypoint paths supplied by Main (AStar3D graph — never
## beelines through buildings), idles at zone spots, shows name + bubbles.
## Visuals: Blender-built rigged GLB (CharModel) with baked clips —
## idle / walk (speed-matched) / sit (on bench seats) / talk (dialogue
## and speech bubbles).

var data: Dictionary = {}
var is_main: bool = false
var is_staff: bool = false
var is_teacher: bool = false # Phase 2: named faculty (Section 19.1)
var subject: String = ""
var stationary: bool = false
var role_line: String = ""

var friendship: int = 25
var chats: int = 0
var compliments_today: int = 0
var learned_hobby: bool = false
var learned_secret: bool = false
# Phase 2 dialogue state (persisted via save deltas, see SaveSystem):
var dialogue_seen: Dictionary = {} # topic -> Array[int] used bank indices
var memory_notes: Array = [] # short strings other lines can call back to
var office_help_day: int = -1 # last day this teacher gave office-hour help

var current_zone: String = "dorm"
var target_zone: String = "dorm"
var spot: Vector3 = Vector3.ZERO
var path: Array = [] # Array[Vector3]
var path_idx: int = 0
var speed: float = 1.45
var talking: bool = false
var seated: bool = false
# Phase 4 (Section 15.2): distance-based simulation tiers. 0 = near
# (full sim), 1 = mid (half movement rate), 2 = far (schedule-only:
# straight-line stepping to the spot, idle clip, no pathfinding).
# Main forces tier 0 in test/capture mode so arrival evidence stays valid.
var sim_tier: int = 0
var _move_speed: float = 1.45
# Capture-only: when true, _process skips movement and animation updates so
# a frozen mid-stride pose set by the screenshot tour is not overridden by
# the idle clip (the cause of the old shot9 straight-leg frame).
var anim_frozen: bool = false
var seat_yaw: float = 0.0
var rng := RandomNumberGenerator.new()

var _model: Dictionary = {}
var _anim: AnimationPlayer = null
var _cur_clip: String = ""
var _label: Label3D = null
var _bubble: Label3D = null
var _bubble_timer: float = 0.0
var _idle_timer: float = 0.0
var _moving: bool = false
# Phase 5 mannerisms: a pose/speed flavour layered on the baked clips
# (Jatin bounces, Shadow slouches, Yumi gestures... — master prompt §10).
var _manner: String = "steady"

static func manner_for_name(nm: String) -> String:
	match nm:
		"Jatin":
			return "bounce"
		"Shadow":
			return "slouch"
		"Yumi":
			return "gesture"
		"Gulshan", "Chirag":
			return "sway"
		"Zannat", "Diya":
			return "crisp"
		_:
			return "steady"

func setup(p_data: Dictionary, p_is_main: bool, start_pos: Vector3, p_speed: float) -> void:
	data = p_data
	is_main = p_is_main
	speed = p_speed
	_manner = manner_for_name(str(p_data.get("name", "")))
	rng.randomize()
	global_position = start_pos
	spot = start_pos
	_model = CharModel.build(data)
	add_child(_model["root"])
	_anim = _model.get("anim")
	_play("idle", 1.0)
	# Name label
	_label = Label3D.new()
	_label.text = str(data.get("name", "?"))
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.0042 if is_main else 0.0032
	_label.font_size = 64
	_label.outline_size = 12
	_label.modulate = Color(1, 1, 1) if is_main else Color(0.82, 0.84, 0.88)
	_label.outline_modulate = Color(0, 0, 0, 0.75)
	_label.position = Vector3(0, float(data.get("height", 1.72)) + 0.34, 0)
	add_child(_label)
	# Speech bubble
	_bubble = Label3D.new()
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.pixel_size = 0.0038
	_bubble.font_size = 56
	_bubble.outline_size = 16
	_bubble.modulate = Color(1.0, 0.98, 0.85)
	_bubble.outline_modulate = Color(0.1, 0.08, 0.02, 0.9)
	_bubble.position = Vector3(0, float(data.get("height", 1.72)) + 0.78, 0)
	_bubble.visible = false
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.width = 900.0
	add_child(_bubble)

func set_path(points: Array) -> void:
	path = points.duplicate()
	path_idx = 0
	if points.size() > 0:
		seated = false

func show_bubble(text: String, dur: float = 3.5) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_timer = dur

func is_moving() -> bool:
	return _moving

func _play(clip: String, speed_scale: float = 1.0) -> void:
	if _anim == null:
		return
	if not _anim.has_animation(clip):
		return
	if _cur_clip != clip:
		_anim.play(clip)
		_cur_clip = clip
	_anim.speed_scale = speed_scale

func _update_anim() -> void:
	if talking:
		_play("talk", 1.3 if _manner == "gesture" else (1.1 if _manner == "crisp" else 1.0))
	elif _moving:
		var mf := 1.18 if _manner == "bounce" else (0.88 if _manner == "slouch" else (1.05 if _manner == "crisp" else 1.0))
		_play("walk", clampf(_move_speed / 1.55, 0.6, 2.6) * mf)
	elif seated:
		_play("sit", 1.0)
	elif _bubble.visible:
		_play("talk", 1.0)
	else:
		_play("idle", 1.0)
	# Phase 5 mannerism pose layer on the model root. NPC code yaws the
	# NPC node itself, never the model root, so tilting/bobbing the root
	# is safe and never fights facing. Skipped while anim_frozen (the
	# capture walk-freeze) because _update_anim is not called then.
	var mroot: Node3D = _model.get("root")
	if mroot != null:
		var t := Time.get_ticks_msec() / 1000.0
		match _manner:
			"bounce":
				mroot.position.y = absf(sin(t * 9.0)) * 0.045 if _moving else 0.0
				mroot.rotation.x = 0.0
				mroot.rotation.z = 0.0
			"slouch":
				mroot.position.y = 0.0
				mroot.rotation.x = 0.10
				mroot.rotation.z = 0.0
			"sway":
				mroot.position.y = 0.0
				mroot.rotation.x = 0.0
				mroot.rotation.z = 0.0 if _moving else sin(t * 1.4) * 0.035
			_:
				mroot.position.y = 0.0
				mroot.rotation.x = 0.0
				mroot.rotation.z = 0.0

func _process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.visible = false
	_moving = false
	if anim_frozen:
		return
	if talking or stationary:
		_update_anim()
		return
	# Phase 4 far tier: schedule-only stepping — straight toward the spot
	# (no pathfinding, idle clip). The player is >70 m away, so the
	# simplification is invisible in play and free in test mode (tier 0).
	if sim_tier == 2:
		var to_spot := Vector3(spot.x - global_position.x, 0, spot.z - global_position.z)
		var d := to_spot.length()
		if d > 0.5:
			var dir := to_spot / d
			global_position += dir * speed * 1.6 * delta
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
		_play("idle", 1.0)
		return
	_move_speed = speed * (0.55 if sim_tier == 1 else 1.0)
	if path_idx < path.size():
		var target: Vector3 = path[path_idx]
		# 2D arrival test, but y eases toward the path point's height so
		# tier-seat arrivals rise onto the platform instead of floating.
		var to := Vector2(target.x - global_position.x, target.z - global_position.z)
		var dist := to.length()
		if dist < 0.35:
			path_idx += 1
		else:
			var dir := to / dist
			global_position.x += dir.x * _move_speed * delta
			global_position.z += dir.y * _move_speed * delta
			global_position.y = lerpf(global_position.y, target.y, delta * 6.0)
			_moving = true
			# face movement
			var target_yaw := atan2(dir.x, dir.y)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)
	elif seated:
		rotation.y = lerp_angle(rotation.y, seat_yaw, delta * 5.0)
		# Tier seats sit on platforms: ease y to the seat height on arrival.
		global_position.y = lerpf(global_position.y, spot.y, delta * 5.0)
	_update_anim()
