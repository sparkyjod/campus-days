class_name NPC
extends Node3D

## A campus person: main character, background student or staff member.
## Moves along waypoint paths supplied by Main (AStar3D graph — never
## beelines through buildings), idles at zone spots, shows name + bubbles.

var data: Dictionary = {}
var is_main: bool = false
var is_staff: bool = false
var stationary: bool = false
var role_line: String = ""

var friendship: int = 25
var chats: int = 0
var compliments_today: int = 0
var learned_hobby: bool = false
var learned_secret: bool = false

var current_zone: String = "dorm"
var target_zone: String = "dorm"
var spot: Vector3 = Vector3.ZERO
var path: Array = [] # Array[Vector3]
var path_idx: int = 0
var speed: float = 1.45
var talking: bool = false
var rng := RandomNumberGenerator.new()

var _model: Dictionary = {}
var _label: Label3D = null
var _bubble: Label3D = null
var _bubble_timer: float = 0.0
var _walk_phase: float = 0.0
var _idle_timer: float = 0.0
var _moving: bool = false

func setup(p_data: Dictionary, p_is_main: bool, start_pos: Vector3, p_speed: float) -> void:
	data = p_data
	is_main = p_is_main
	speed = p_speed
	rng.randomize()
	global_position = start_pos
	spot = start_pos
	_model = StudentFactory.build_student(data)
	add_child(_model["root"])
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

func show_bubble(text: String, dur: float = 3.5) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_timer = dur

func is_moving() -> bool:
	return _moving

func _process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.visible = false
	_moving = false
	if talking or stationary:
		_idle_animate(delta)
		return
	if path_idx < path.size():
		var target: Vector3 = path[path_idx]
		target.y = global_position.y
		var to := target - global_position
		to.y = 0
		var dist := to.length()
		if dist < 0.35:
			path_idx += 1
		else:
			var dir := to / dist
			global_position += dir * speed * delta
			_moving = true
			# face movement
			var target_yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)
			_walk_phase += delta * speed * 4.4
	else:
		_idle_animate(delta)
	_animate_limbs()

func _idle_animate(delta: float) -> void:
	_idle_timer += delta
	_walk_phase = lerpf(_walk_phase, round(_walk_phase / PI) * PI, delta * 6.0)
	# gentle breathing / look-around using head
	var head: Node3D = _model.get("head")
	if head:
		head.rotation.y = sin(_idle_timer * 0.4 + float(rng.seed % 10)) * 0.18

func _animate_limbs() -> void:
	var swing := sin(_walk_phase) * (0.55 if _moving else 0.0)
	var legs: Array = _model.get("legs", [])
	var arms: Array = _model.get("arms", [])
	if legs.size() == 2:
		(legs[0] as Node3D).rotation.x = swing
		(legs[1] as Node3D).rotation.x = -swing
	if arms.size() == 2:
		(arms[0] as Node3D).rotation.x = -swing * 0.8
		(arms[1] as Node3D).rotation.x = swing * 0.8
	var root: Node3D = _model.get("root")
	if root:
		root.position.y = abs(sin(_walk_phase)) * 0.035 if _moving else 0.0
