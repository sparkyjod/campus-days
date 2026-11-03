class_name Player
extends CharacterBody3D

## Third-person student controller: WASD + mouse look, Shift to run,
## real collision via CharacterBody3D (no walking through walls/props).

var walk_speed: float = 3.4
var run_speed: float = 6.2
var speed_factor: float = 1.0 # energy effects applied by Main
var controls_locked: bool = false
# Phase 5: camera sensitivity (settings), touch joystick vector, both
# feeding the same movement code as WASD/gamepad.
var mouse_sensitivity: float = 1.0
var touch_dir: Vector2 = Vector2.ZERO
var touch_run: bool = false # mobile build's on-screen Run hold-button

var _yaw: float = 0.0
var _pitch: float = -0.32
var _pivot: Node3D
var _spring: SpringArm3D
var _cam: Camera3D
var _model: Dictionary = {}
var _anim: AnimationPlayer = null
var _cur_clip: String = ""

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.72
	shape.shape = cap
	shape.position.y = 0.86
	add_child(shape)
	_model = CharModel.build({
		"height": 1.74, "build": 1.0, "skin": Color(0.60, 0.42, 0.29),
		"hair_style": 0, "hair_color": Color(0.07, 0.05, 0.04),
		"shirt": Color(0.85, 0.75, 0.15), "pants": Color(0.20, 0.22, 0.35),
		"backpack": true, "pack_color": Color(0.25, 0.25, 0.28), "female": false
	})
	add_child(_model["root"])
	_anim = _model.get("anim")
	_play("idle", 1.0)
	_pivot = Node3D.new()
	_pivot.position = Vector3(0, 1.62, 0)
	add_child(_pivot)
	_spring = SpringArm3D.new()
	_spring.spring_length = 5.2
	_spring.margin = 0.35
	_pivot.add_child(_spring)
	_cam = Camera3D.new()
	_cam.fov = 62.0
	_spring.add_child(_cam)
	_cam.current = true

func get_camera() -> Camera3D:
	return _cam

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not controls_locked:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.0026 * mouse_sensitivity
		_pitch = clampf(_pitch - mm.relative.y * 0.0026 * mouse_sensitivity, -1.1, 0.55)

# Phase 5: touch right-half drags and gamepad right stick look through here.
func apply_look(dx: float, dy: float) -> void:
	if controls_locked:
		return
	_yaw -= dx * 0.0026 * mouse_sensitivity
	_pitch = clampf(_pitch - dy * 0.0026 * mouse_sensitivity, -1.1, 0.55)

func _physics_process(delta: float) -> void:
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	var input_dir := Vector2.ZERO
	if not controls_locked:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			input_dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S):
			input_dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_A):
			input_dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			input_dir.x += 1.0
	# Phase 5: gamepad left stick + touch joystick feed the same vector.
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		input_dir.x += jx
	if absf(jy) > 0.2:
		input_dir.y += jy
	input_dir += touch_dir
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(rx) > 0.2 and not controls_locked:
		_yaw -= rx * 2.0 * delta * mouse_sensitivity
	if absf(ry) > 0.2 and not controls_locked:
		_pitch = clampf(_pitch - ry * 2.0 * delta * mouse_sensitivity, -1.1, 0.55)
	var running := (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or touch_run) and input_dir != Vector2.ZERO
	var spd := (run_speed if running else walk_speed) * speed_factor
	var basis_yaw := Basis(Vector3.UP, _yaw)
	var dir3 := (basis_yaw * Vector3(input_dir.x, 0, input_dir.y))
	if dir3.length() > 0.001:
		dir3 = dir3.normalized()
	velocity.x = dir3.x * spd if input_dir != Vector2.ZERO else 0.0
	velocity.z = dir3.z * spd if input_dir != Vector2.ZERO else 0.0
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		var target_yaw := atan2(velocity.x, velocity.z)
		_model["root"].rotation.y = lerp_angle(_model["root"].rotation.y, target_yaw, delta * 10.0)
		if running:
			_play("run", clampf(spd / 3.4, 0.7, 2.4))
		else:
			_play("walk", clampf(spd / 1.55, 0.7, 2.8))
	else:
		_play("idle", 1.0)

## Phase 2 character creation: rebuild the visible model with the
## chosen appearance preset (hair, gendered rig, shirt, skin).
func apply_appearance(cfg: Dictionary) -> void:
	var old_root: Node3D = _model.get("root")
	if old_root != null and old_root.get_parent() == self:
		remove_child(old_root)
		old_root.queue_free()
	_model = CharModel.build(cfg)
	add_child(_model["root"])
	_anim = _model.get("anim")
	_cur_clip = ""
	_play("idle", 1.0)

func _play(clip: String, speed_scale: float = 1.0) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _cur_clip != clip:
		_anim.play(clip)
		_cur_clip = clip
	_anim.speed_scale = speed_scale
