class_name StudentFactory
extends RefCounted

## Builds a stylised-but-proportioned student from shared unit meshes.
## Returns a Dictionary of animated parts so NPC/Player can swing limbs.
## All MeshInstance3D nodes share ONE box mesh / ONE capsule / ONE sphere,
## and materials come from TexGen's cache — draw setup stays cheap.

static var _box: BoxMesh = null
static var _sphere: SphereMesh = null
static var _capsule: CapsuleMesh = null
static var _cyl: CylinderMesh = null

static func _meshes() -> void:
	if _box != null:
		return
	_box = BoxMesh.new()
	_box.size = Vector3.ONE
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 16
	_sphere.rings = 8
	_capsule = CapsuleMesh.new()
	_capsule.radius = 0.5
	_capsule.height = 2.0 # radius 0.5 -> total height 2.0, so scale y = desired_height / 2
	_capsule.radial_segments = 12
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 0.5
	_cyl.bottom_radius = 0.5
	_cyl.height = 1.0
	_cyl.radial_segments = 12

static func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	if name != "":
		mi.name = name
	parent.add_child(mi)
	return mi

static func build_student(cfg: Dictionary) -> Dictionary:
	_meshes()
	var height: float = cfg.get("height", 1.72)
	var build_w: float = cfg.get("build", 1.0) # width factor
	var skin: Color = cfg.get("skin", Color(0.62, 0.44, 0.32))
	var shirt: Color = cfg.get("shirt", Color(0.3, 0.4, 0.8))
	var pants: Color = cfg.get("pants", Color(0.2, 0.2, 0.25))
	var hair_c: Color = cfg.get("hair_color", Color(0.10, 0.07, 0.05))
	var hair_style: int = cfg.get("hair_style", 0)
	var s := height / 1.72

	var root := Node3D.new()
	root.name = "Model"
	var skin_m := TexGen.mat_color(skin, 0.65)
	var shirt_m := TexGen.mat_color(shirt, 0.9)
	var pants_m := TexGen.mat_color(pants, 0.9)
	var hair_m := TexGen.mat_color(hair_c, 0.95)
	var shoe_m := TexGen.mat_color(Color(0.12, 0.12, 0.13), 0.6)
	var dark_m := TexGen.mat_color(Color(0.08, 0.06, 0.06), 0.5)

	var leg_len := 0.82 * s
	var torso_h := 0.60 * s
	var hip_y := leg_len

	# Legs (pivots at hip so they can swing)
	var legs: Array = []
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.11 * side * build_w * s, hip_y, 0)
		root.add_child(pivot)
		_part(pivot, _box, pants_m, Vector3(0, -leg_len * 0.5 + 0.06, 0), Vector3(0.15 * s, leg_len - 0.10, 0.17 * s))
		_part(pivot, _box, shoe_m, Vector3(0, -leg_len + 0.035, 0.03), Vector3(0.15 * s, 0.07, 0.26 * s))
		legs.append(pivot)

	# Torso
	var torso := _part(root, _capsule, shirt_m, Vector3(0, hip_y + torso_h * 0.5, 0), Vector3(0.50 * build_w * s, torso_h * 0.5, 0.30 * s), "Torso")
	# Collar hint
	_part(root, _box, skin_m, Vector3(0, hip_y + torso_h + 0.015, 0), Vector3(0.13 * s, 0.05, 0.13 * s))

	# Arms (pivots at shoulder): upper = shirt, forearm + hand = skin
	var arms: Array = []
	var shoulder_y := hip_y + torso_h - 0.06
	for side in [-1.0, 1.0]:
		var pivot2 := Node3D.new()
		pivot2.position = Vector3(0.31 * side * build_w * s, shoulder_y, 0)
		root.add_child(pivot2)
		_part(pivot2, _box, shirt_m, Vector3(0, -0.16 * s, 0), Vector3(0.11 * s, 0.32 * s, 0.12 * s))
		_part(pivot2, _capsule, skin_m, Vector3(0, -0.44 * s, 0), Vector3(0.095 * s, 0.16 * s, 0.095 * s))
		arms.append(pivot2)

	# Head group (pivot at neck for look/talk nods)
	var head_g := Node3D.new()
	head_g.position = Vector3(0, hip_y + torso_h + 0.05, 0)
	head_g.name = "Head"
	root.add_child(head_g)
	var hr := 0.115 * s
	_part(head_g, _sphere, skin_m, Vector3(0, hr + 0.02, 0), Vector3(hr * 2.0 * 0.92, hr * 2.15, hr * 2.0))
	# Ears
	_part(head_g, _sphere, skin_m, Vector3(-hr * 0.95, hr + 0.02, 0), Vector3(0.035, 0.06, 0.03))
	_part(head_g, _sphere, skin_m, Vector3(hr * 0.95, hr + 0.02, 0), Vector3(0.035, 0.06, 0.03))
	# Nose
	_part(head_g, _sphere, skin_m, Vector3(0, hr * 0.95, hr * 1.02), Vector3(0.035, 0.05, 0.04))
	# Eyes (front = +Z)
	for side in [-1.0, 1.0]:
		_part(head_g, _sphere, dark_m, Vector3(0.042 * side * s, hr * 1.22, hr * 0.94), Vector3(0.026, 0.034, 0.014))
		# brows
		_part(head_g, _box, hair_m, Vector3(0.045 * side * s, hr * 1.42, hr * 0.95), Vector3(0.055, 0.012, 0.012))
	# Mouth
	_part(head_g, _box, TexGen.mat_color(Color(0.55, 0.30, 0.28), 0.7), Vector3(0, hr * 0.62, hr * 0.97), Vector3(0.05, 0.012, 0.01))

	# Hair styles: 0 short, 1 long, 2 bun, 3 curly, 4 cap, 5 ponytail, 6 wavy medium, 7 buzz
	var top_y := hr * 2.05
	match hair_style:
		0:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.01, -0.012), Vector3(hr * 2.02, hr * 1.15, hr * 2.05))
		1:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.01, -0.012), Vector3(hr * 2.02, hr * 1.15, hr * 2.05))
			_part(head_g, _box, hair_m, Vector3(0, hr * 0.55, -hr * 0.92), Vector3(hr * 1.85, hr * 1.9, 0.05))
		2:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.01, -0.012), Vector3(hr * 2.02, hr * 1.15, hr * 2.05))
			_part(head_g, _sphere, hair_m, Vector3(0, top_y + 0.055, -hr * 0.55), Vector3(0.09, 0.09, 0.09))
		3:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y + 0.02, 0), Vector3(hr * 2.25, hr * 1.55, hr * 2.25))
		4:
			_part(head_g, _cyl, TexGen.mat_color(shirt.darkened(0.25), 0.9), Vector3(0, top_y + 0.01, 0), Vector3(hr * 2.1, 0.045, hr * 2.1))
			_part(head_g, _box, TexGen.mat_color(shirt.darkened(0.25), 0.9), Vector3(0, top_y - 0.005, hr * 1.25), Vector3(hr * 1.5, 0.018, hr * 0.8))
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.03, -hr * 0.5), Vector3(hr * 1.8, hr * 0.8, hr * 1.2))
		5:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.01, -0.012), Vector3(hr * 2.02, hr * 1.15, hr * 2.05))
			_part(head_g, _capsule, hair_m, Vector3(0, hr * 1.15, -hr * 1.12), Vector3(0.055, 0.17, 0.055))
		6:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.005, -0.01), Vector3(hr * 2.08, hr * 1.35, hr * 2.1))
			_part(head_g, _box, hair_m, Vector3(-hr * 0.98, hr * 1.0, 0), Vector3(0.04, hr * 1.3, hr * 1.6))
			_part(head_g, _box, hair_m, Vector3(hr * 0.98, hr * 1.0, 0), Vector3(0.04, hr * 1.3, hr * 1.6))
		_:
			_part(head_g, _sphere, hair_m, Vector3(0, top_y - 0.025, -0.008), Vector3(hr * 1.98, hr * 1.0, hr * 2.0))

	# Backpack for some (flag in cfg)
	if cfg.get("backpack", false):
		_part(root, _box, TexGen.mat_color(cfg.get("pack_color", Color(0.7, 0.25, 0.2)), 0.9), Vector3(0, hip_y + torso_h * 0.55, -0.21 * s), Vector3(0.36 * s, 0.44 * s, 0.15 * s))

	return {"root": root, "legs": legs, "arms": arms, "head": head_g, "torso": torso}
