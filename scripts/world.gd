class_name World
extends RefCounted

## Builds the Northbridge University campus: US-style spacious layout
## (central quad, wide avenues, faculty blocks, landmark library, student
## union, residence hall, sports complex, gate + bus loop) with Indian
## cultural content (chai stall, food court, rickshaw). 1 unit = 1 metre.
## All solids register collision shapes on one StaticBody3D. Also builds
## the AStar3D waypoint graph along avenues and through entrances.

static var _body: StaticBody3D
static var _parent: Node3D

static func _mi(mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation.y = rot_y
	_parent.add_child(mi)
	return mi

static func _box_mesh() -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	return b

static var _shared_box: BoxMesh = null
static var _shared_cyl: CylinderMesh = null
static var _shared_sphere: SphereMesh = null

static func _box(mat: Material, pos: Vector3, size: Vector3, collide: bool = false, rot_y: float = 0.0) -> MeshInstance3D:
	if _shared_box == null:
		_shared_box = _box_mesh()
	var mi := _mi(_shared_box, mat, pos, size, rot_y)
	if collide:
		_add_box_shape(pos, size, rot_y)
	return mi

static func _add_box_shape(pos: Vector3, size: Vector3, rot_y: float = 0.0) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	cs.rotation.y = rot_y
	_body.add_child(cs)

static func _add_cyl_shape(pos: Vector3, radius: float, height: float) -> void:
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	cs.shape = cyl
	cs.position = pos
	_body.add_child(cs)

static func _cyl(mat: Material, pos: Vector3, radius: float, height: float, collide: bool = false) -> MeshInstance3D:
	if _shared_cyl == null:
		_shared_cyl = CylinderMesh.new()
		_shared_cyl.top_radius = 0.5
		_shared_cyl.bottom_radius = 0.5
		_shared_cyl.height = 1.0
		_shared_cyl.radial_segments = 14
	var mi := _mi(_shared_cyl, mat, pos, Vector3(radius * 2.0, height, radius * 2.0))
	if collide:
		_add_cyl_shape(pos, radius, height)
	return mi

static func _sphere(mat: Material, pos: Vector3, scl: Vector3) -> MeshInstance3D:
	if _shared_sphere == null:
		_shared_sphere = SphereMesh.new()
		_shared_sphere.radius = 0.5
		_shared_sphere.height = 1.0
		_shared_sphere.radial_segments = 14
		_shared_sphere.rings = 8
	return _mi(_shared_sphere, mat, pos, scl)

static func _ground_plane(mat: Material, pos: Vector3, size: Vector2) -> void:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	_parent.add_child(mi)

static func _sign(text: String, pos: Vector3, size_px: int = 96, color: Color = Color(1, 1, 1), rot_y: float = 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size_px
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 16
	l.outline_modulate = Color(0, 0, 0, 0.65)
	l.position = pos
	l.rotation.y = rot_y
	_parent.add_child(l)

static func _window(wall_pos: Vector3, horiz: String, fixed: float, w: float, h: float, y: float) -> void:
	# frame + glass slightly proud of the wall surface
	var frame_m := TexGen.mat_color(Color(0.92, 0.90, 0.86), 0.7)
	var glass_m := TexGen.mat_glass()
	var q := QuadMesh.new()
	q.size = Vector2(w + 0.18, h + 0.18)
	var q2 := QuadMesh.new()
	q2.size = Vector2(w, h)
	var rot := 0.0
	var off := Vector3.ZERO
	match horiz:
		"south":
			off = Vector3(0, 0, 0.23)
		"north":
			off = Vector3(0, 0, -0.23)
			rot = PI
		"east":
			off = Vector3(0.23, 0, 0)
			rot = PI / 2.0
		"west":
			off = Vector3(-0.23, 0, 0)
			rot = -PI / 2.0
	var center := wall_pos + off
	center.y = y
	if horiz == "south" or horiz == "north":
		center.x += fixed
	else:
		center.z += fixed
	_mi(q, frame_m, center, Vector3.ONE, rot)
	_mi(q2, glass_m, center + off.normalized() * 0.03, Vector3.ONE, rot)
	# crossbar
	_box(frame_m, center + off.normalized() * 0.04 + Vector3(0, 0, 0), Vector3(w, 0.05, 0.03) if (horiz == "south" or horiz == "north") else Vector3(0.03, 0.05, w), false, 0.0)

static func _wall_run(mat: Material, from: Vector3, to: Vector3, height: float, thickness: float, door_center: float = -9999.0, door_w: float = 2.6, door_h: float = 2.7) -> void:
	# horizontal run along X (from.z == to.z) or along Z; door_center is the
	# coordinate along the run axis where the doorway gap goes.
	var along_x := absf(to.x - from.x) > absf(to.z - from.z)
	var length := (to - from).length()
	var mid := (from + to) * 0.5
	if door_center < -999.0:
		var pos := Vector3(mid.x, height * 0.5, mid.z)
		var size := Vector3(length, height, thickness) if along_x else Vector3(thickness, height, length)
		_box(mat, pos, size, true)
		return
	var a_start := from.x if along_x else from.z
	var a_end := to.x if along_x else to.z
	var lo := minf(a_start, a_end)
	var d0 := door_center - door_w * 0.5
	var d1 := door_center + door_w * 0.5
	var segs := [[lo, d0], [d1, lo + length]]
	for seg in segs:
		var s0: float = seg[0]
		var s1: float = seg[1]
		if s1 - s0 < 0.05:
			continue
		var c := (s0 + s1) * 0.5
		var pos2 := Vector3(c, height * 0.5, mid.z) if along_x else Vector3(mid.x, height * 0.5, c)
		var size2 := Vector3(s1 - s0, height, thickness) if along_x else Vector3(thickness, height, s1 - s0)
		_box(mat, pos2, size2, true)
	# lintel above the door
	var lpos := Vector3(door_center, door_h + (height - door_h) * 0.5, mid.z) if along_x else Vector3(mid.x, door_h + (height - door_h) * 0.5, door_center)
	var lsize := Vector3(door_w, height - door_h, thickness) if along_x else Vector3(thickness, height - door_h, door_w)
	_box(mat, lpos, lsize, true)

static func _building(cfg: Dictionary) -> void:
	var center: Vector3 = cfg["center"]
	var w: float = cfg["w"]
	var d: float = cfg["d"]
	var h: float = cfg["h"]
	var wall_tex: Texture2D = cfg.get("wall_tex", TexGen.tex_brick())
	var tint: Color = cfg.get("tint", Color.WHITE)
	var door_side: String = cfg.get("door_side", "south")
	var name_text: String = cfg.get("name", "")
	var wall_m := TexGen.mat_tex(wall_tex, tint, Vector2(w / 3.2, h / 3.2))
	var trim_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.95, 0.93, 0.88), Vector2(w / 3.0, 0.4))
	var roof_m := TexGen.mat_tex(TexGen.tex_roof(), Color.WHITE, Vector2(w / 2.6, d / 2.6))
	var x0 := center.x - w * 0.5
	var x1 := center.x + w * 0.5
	var z0 := center.z - d * 0.5
	var z1 := center.z + d * 0.5
	var th := 0.4
	# floor (interior)
	_ground_plane(TexGen.mat_tex(TexGen.tex_marble(), Color(0.96, 0.95, 0.92), Vector2(w / 2.2, d / 2.2), 0.35), Vector3(center.x, 0.03, center.z), Vector2(w, d))
	# walls (door on door_side)
	_wall_run(wall_m, Vector3(x0, 0, z0), Vector3(x1, 0, z0), h, th, center.x if door_side == "north" else -9999.0)
	_wall_run(wall_m, Vector3(x0, 0, z1), Vector3(x1, 0, z1), h, th, center.x if door_side == "south" else -9999.0)
	_wall_run(wall_m, Vector3(x0, 0, z0), Vector3(x0, 0, z1), h, th, center.z if door_side == "west" else -9999.0)
	_wall_run(wall_m, Vector3(x1, 0, z0), Vector3(x1, 0, z1), h, th, center.z if door_side == "east" else -9999.0)
	# trim band + roof slab
	_box(trim_m, Vector3(center.x, h - 0.25, center.z), Vector3(w + 0.3, 0.5, d + 0.3), false)
	_box(roof_m, Vector3(center.x, h + 0.22, center.z), Vector3(w + 1.0, 0.45, d + 1.0), true)
	_box(roof_m, Vector3(center.x, h + 0.75, center.z), Vector3(w * 0.5, 0.7, d * 0.55), false)
	# windows: two rows on long sides, one row on short sides
	var rows := [2.0, h - 1.6] if h > 8.0 else [2.0]
	for ry in rows:
		var nx := int(w / 5.0)
		for i in range(nx):
			var wx := x0 + (float(i) + 0.5) * (w / float(nx))
			if door_side != "north" or absf(wx - center.x) > 2.2:
				_window(Vector3(wx, 0, z0), "north", 0.0, 1.7, 1.5, ry)
			if door_side != "south" or absf(wx - center.x) > 2.2:
				_window(Vector3(wx, 0, z1), "south", 0.0, 1.7, 1.5, ry)
		var nz := int(d / 5.0)
		for j in range(nz):
			var wz := z0 + (float(j) + 0.5) * (d / float(nz))
			if door_side != "west" or absf(wz - center.z) > 2.2:
				_window(Vector3(x0, 0, wz), "west", 0.0, 1.7, 1.5, ry)
			if door_side != "east" or absf(wz - center.z) > 2.2:
				_window(Vector3(x1, 0, wz), "east", 0.0, 1.7, 1.5, ry)
	# entrance steps + sign
	var door_pos := Vector3(center.x, 0, z1) if door_side == "south" else Vector3(center.x, 0, z0) if door_side == "north" else Vector3(x1, 0, center.z) if door_side == "east" else Vector3(x0, 0, center.z)
	var step_off := Vector3(0, 0, 1.1) if door_side == "south" else Vector3(0, 0, -1.1) if door_side == "north" else Vector3(1.1, 0, 0) if door_side == "east" else Vector3(-1.1, 0, 0)
	_box(TexGen.mat_tex(TexGen.tex_concrete(), Color.WHITE, Vector2(3.4, 1.6)), door_pos + step_off + Vector3(0, 0.09, 0), Vector3(3.6, 0.18, 2.2) if (door_side == "south" or door_side == "north") else Vector3(2.2, 0.18, 3.6), false)
	if name_text != "":
		var sign_pos := door_pos + step_off * 1.4 + Vector3(0, 3.4, 0)
		var rot := 0.0 if door_side == "south" else PI if door_side == "north" else PI / 2.0 if door_side == "east" else -PI / 2.0
		_sign(name_text, sign_pos, 110, Color(1.0, 0.95, 0.80), rot)

static func _tree(pos: Vector3) -> void:
	var trunk_m := TexGen.mat_tex(TexGen.tex_wood(), Color(0.8, 0.7, 0.6), Vector2(1, 2))
	var leaf_m := TexGen.mat_color(Color(0.20, 0.42, 0.16), 1.0)
	_cyl(trunk_m, pos + Vector3(0, 1.4, 0), 0.22, 2.8, true)
	_sphere(leaf_m, pos + Vector3(0, 3.9, 0), Vector3(3.4, 3.0, 3.4))
	_sphere(leaf_m, pos + Vector3(0.9, 3.1, 0.4), Vector3(2.2, 2.0, 2.2))
	_sphere(leaf_m, pos + Vector3(-0.9, 3.2, -0.4), Vector3(2.3, 2.1, 2.3))

static func _bench(pos: Vector3, rot_y: float = 0.0) -> void:
	var wood_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(2, 0.4))
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	_box(wood_m, Vector3(0, 0.46, 0), Vector3(1.9, 0.08, 0.5), false)
	_box(wood_m, Vector3(0, 0.85, -0.24), Vector3(1.9, 0.5, 0.07), false)
	_box(TexGen.mat_color(Color(0.25, 0.25, 0.27), 0.6), Vector3(-0.8, 0.22, 0), Vector3(0.08, 0.45, 0.45), false)
	_box(TexGen.mat_color(Color(0.25, 0.25, 0.27), 0.6), Vector3(0.8, 0.22, 0), Vector3(0.08, 0.45, 0.45), false)
	_parent = saved
	_add_box_shape(pos, Vector3(1.9, 0.9, 0.55), rot_y)

static func _lamp(pos: Vector3) -> OmniLight3D:
	var pole_m := TexGen.mat_color(Color(0.18, 0.19, 0.22), 0.5)
	_cyl(pole_m, pos + Vector3(0, 2.2, 0), 0.09, 4.4, true)
	_sphere(TexGen.mat_emissive(Color(1.0, 0.9, 0.65), 0.6), pos + Vector3(0, 4.5, 0), Vector3(0.42, 0.42, 0.42))
	var omni := OmniLight3D.new()
	omni.position = pos + Vector3(0, 4.4, 0)
	omni.omni_range = 13.0
	omni.light_energy = 0.0
	omni.light_color = Color(1.0, 0.88, 0.66)
	_parent.add_child(omni)
	return omni

static func build(parent: Node3D) -> Dictionary:
	_parent = parent
	_body = StaticBody3D.new()
	_body.name = "CampusStatic"
	parent.add_child(_body)
	var lamps: Array = []

	var grass_m := TexGen.mat_tex(TexGen.tex_grass(), Color.WHITE, Vector2(90, 68))
	var pave_m := TexGen.mat_tex(TexGen.tex_paving(), Color.WHITE, Vector2(30, 30))
	var quad_m := TexGen.mat_tex(TexGen.tex_grass(), Color(1.05, 1.02, 0.9), Vector2(46, 30))

	# --- ground + perimeter
	_ground_plane(grass_m, Vector3(0, 0, 0), Vector2(280, 210))
	_add_box_shape(Vector3(0, -0.6, 0), Vector3(280, 1.0, 210))
	var hedge_m := TexGen.mat_color(Color(0.16, 0.34, 0.13), 1.0)
	for b in [[Vector3(0, 0.9, -103), Vector3(278, 1.8, 1.6)], [Vector3(-139, 0.9, 0), Vector3(1.6, 1.8, 208)], [Vector3(139, 0.9, 0), Vector3(1.6, 1.8, 208)]]:
		_box(hedge_m, b[0], b[1], true)
	# south fence with gate gap x in [-7, 7]
	_box(hedge_m, Vector3(-73, 0.9, 103), Vector3(132, 1.8, 1.6), true)
	_box(hedge_m, Vector3(73, 0.9, 103), Vector3(132, 1.8, 1.6), true)

	# --- avenues (paving)
	_ground_plane(pave_m, Vector3(0, 0.02, 46), Vector2(9, 108)) # main avenue gate->quad
	_ground_plane(pave_m, Vector3(0, 0.02, -5), Vector2(150, 7)) # east-west avenue
	_ground_plane(pave_m, Vector3(0, 0.021, -24), Vector2(124, 6)) # north avenue
	_ground_plane(pave_m, Vector3(-44, 0.02, 7), Vector2(6, 26)) # dorm branch
	_ground_plane(pave_m, Vector3(44, 0.02, 7), Vector2(6, 26)) # food branch
	_ground_plane(pave_m, Vector3(-58, 0.02, -34), Vector2(6, 22)) # lecture branch
	_ground_plane(pave_m, Vector3(58, 0.02, 2), Vector2(6, 100)) # east avenue (library + union)
	_ground_plane(pave_m, Vector3(4, 0.02, 52), Vector2(116, 6)) # south avenue (sports + union)
	_ground_plane(pave_m, Vector3(-24, 0.02, 41), Vector2(6, 24)) # sports branch
	# bus loop at gate
	var loop := CylinderMesh.new()
	loop.top_radius = 16.0
	loop.bottom_radius = 16.0
	loop.height = 0.06
	loop.radial_segments = 28
	_mi(loop, pave_m, Vector3(0, 0.03, 92), Vector3.ONE)

	# --- central quad lawns (4 quadrants around crossing paths)
	for q in [Vector3(-19, 0.015, -15.5), Vector3(19, 0.015, -15.5), Vector3(-19, 0.015, 5.5), Vector3(19, 0.015, 5.5)]:
		_ground_plane(quad_m, q, Vector2(31, 15))

	# --- buildings
	_building({"center": Vector3(-58, 0, -58), "w": 36, "d": 18, "h": 12, "door_side": "south", "name": "LECTURE BLOCK A", "wall_tex": TexGen.tex_brick(), "tint": Color(1.0, 0.92, 0.85)})
	_building({"center": Vector3(58, 0, -58), "w": 34, "d": 18, "h": 13, "door_side": "south", "name": "CENTRAL LIBRARY", "wall_tex": TexGen.tex_concrete(), "tint": Color(1.02, 0.98, 0.90)})
	_building({"center": Vector3(66, 0, 18), "w": 28, "d": 16, "h": 7, "door_side": "west", "name": "FOOD COURT", "wall_tex": TexGen.tex_brick(), "tint": Color(1.05, 0.95, 0.80)})
	_building({"center": Vector3(-66, 0, 18), "w": 30, "d": 16, "h": 11, "door_side": "east", "name": "RESIDENCE HALL", "wall_tex": TexGen.tex_concrete(), "tint": Color(0.92, 0.90, 0.98)})
	_building({"center": Vector3(58, 0, 66), "w": 32, "d": 16, "h": 9, "door_side": "north", "name": "STUDENT UNION", "wall_tex": TexGen.tex_brick(), "tint": Color(0.88, 0.92, 1.02)})
	# library dome + entrance columns (landmark)
	var dome_m := TexGen.mat_color(Color(0.36, 0.44, 0.48), 0.4)
	_sphere(dome_m, Vector3(58, 13.9, -58), Vector3(12, 3.4, 12))
	var col_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(1.05, 1.02, 0.95), Vector2(1, 4))
	for cx in [-6.0, -2.0, 2.0, 6.0]:
		_cyl(col_m, Vector3(58 + cx, 1.7, -47.6), 0.42, 3.4, true)

	# --- interiors & props
	_build_interiors()

	# --- gate: pillars, arch, sign, bus, rickshaw
	var stone_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.84), Vector2(1.5, 5))
	_box(stone_m, Vector3(-7.5, 2.6, 100), Vector3(1.6, 5.2, 1.6), true)
	_box(stone_m, Vector3(7.5, 2.6, 100), Vector3(1.6, 5.2, 1.6), true)
	_box(stone_m, Vector3(0, 5.6, 100), Vector3(17, 1.1, 1.8), true)
	_sign("NORTHBRIDGE UNIVERSITY", Vector3(0, 5.6, 98.9), 120, Color(1.0, 0.9, 0.6), PI)
	_sign("NORTHBRIDGE UNIVERSITY", Vector3(0, 5.6, 101.1), 120, Color(1.0, 0.9, 0.6), 0.0)
	_build_bus(Vector3(-11, 0, 90), 0.3)
	_build_rickshaw(Vector3(10.5, 0, 86))
	_sign("BUS STOP", Vector3(-11, 3.4, 95.5), 72, Color(1, 1, 1), PI)

	# --- chai stall near quad south-east
	_build_chai_stall(Vector3(15, 0, 24))

	# --- sports complex: pitch, lines, goals, stands, floodlights
	_build_sports()

	# --- trees, benches, lamps, notice board
	var tree_spots := [Vector3(-30, 0, -20), Vector3(30, 0, -20), Vector3(-30, 0, 10), Vector3(30, 0, 10), Vector3(-12, 0, -19), Vector3(12, 0, 9), Vector3(-95, 0, -30), Vector3(95, 0, -30), Vector3(-100, 0, 40), Vector3(100, 0, 40), Vector3(-20, 0, 84), Vector3(22, 0, 84), Vector3(90, 0, -70), Vector3(-90, 0, -70), Vector3(0, 0, -34), Vector3(-104, 0, -6), Vector3(104, 0, -6), Vector3(30, 0, 34), Vector3(-32, 0, 34)]
	for t in tree_spots:
		_tree(t)
	for b in [[Vector3(-8, 0, -12), 0.4], [Vector3(9, 0, 2), -0.5], [Vector3(-14, 0, 3), 0.2], [Vector3(15, 0, -14), 2.8], [Vector3(0, 0, 40), 0.0], [Vector3(-40, 0, -14), 1.57], [Vector3(40, 0, -14), -1.57]]:
		_bench(b[0], b[1])
	for lp in [Vector3(-4.5, 0, 30), Vector3(4.5, 0, 62), Vector3(-20, 0, -8), Vector3(20, 0, -8), Vector3(-61, 0, -30), Vector3(61, 0, -30), Vector3(-44, 0, 22), Vector3(48, 0, 22), Vector3(54, 0, 48), Vector3(-4.5, 0, 88)]:
		lamps.append(_lamp(lp))
	# notice board near quad
	_box(TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(3, 2)), Vector3(5.5, 1.5, 16), Vector3(3.4, 2.0, 0.18), true)
	_sign("NOTICE BOARD\n• Fest auditions next week\n• Debate selections open", Vector3(5.5, 1.6, 15.85), 54, Color(1.0, 0.97, 0.85), PI)

	# --- zone spots (where NPCs stand/sit inside each zone)
	var spots := {
		"dorm": _grid_spots(Vector3(-66, 0, 18), 5, 3, 4.6, 3.6),
		"lecture": _grid_spots(Vector3(-58, 0, -57), 6, 3, 4.4, 3.2),
		"library": _grid_spots(Vector3(58, 0, -57), 5, 3, 4.8, 3.4),
		"foodcourt": _grid_spots(Vector3(64, 0, 18), 4, 3, 4.2, 3.6),
		"union": _grid_spots(Vector3(58, 0, 66), 5, 3, 4.6, 3.6),
		"quad": [Vector3(-8, 0, -12), Vector3(9, 0, 2), Vector3(-14, 0, 3), Vector3(15, 0, -14), Vector3(-19, 0, -15), Vector3(19, 0, 6), Vector3(-19, 0, 6), Vector3(19, 0, -16), Vector3(3, 0, -20), Vector3(-3, 0, 11), Vector3(26, 0, -5), Vector3(-26, 0, -5)],
		"sports": [Vector3(-40, 0, 58), Vector3(-58, 0, 66), Vector3(-66, 0, 55), Vector3(-35, 0, 72), Vector3(-52, 0, 48), Vector3(-70, 0, 70), Vector3(-28, 0, 50), Vector3(-62, 0, 76)],
		"gate": [Vector3(-6, 0, 94), Vector3(6, 0, 93), Vector3(-12, 0, 96), Vector3(3, 0, 88)]
	}

	# --- waypoint graph (avenues + entrances + interiors)
	var nodes := {
		"gate": Vector3(0, 0, 96), "ave_s1": Vector3(0, 0, 62), "ave_s2": Vector3(0, 0, 30),
		"quad_s": Vector3(0, 0, 12), "quad_c": Vector3(0, 0, -5), "quad_n": Vector3(0, 0, -24),
		"quad_w": Vector3(-24, 0, -5), "quad_e": Vector3(24, 0, -5),
		"ave_w": Vector3(-44, 0, -5), "dorm_path": Vector3(-44, 0, 18), "dorm_front": Vector3(-47.5, 0, 18), "dorm_in": Vector3(-56, 0, 18),
		"ave_e": Vector3(44, 0, -5), "food_path": Vector3(44, 0, 18), "food_front": Vector3(48.5, 0, 18), "food_in": Vector3(57, 0, 18),
		"lec_path": Vector3(-58, 0, -24), "lec_front": Vector3(-58, 0, -46.5), "lec_in": Vector3(-58, 0, -53),
		"lib_path": Vector3(58, 0, -24), "lib_front": Vector3(58, 0, -46.5), "lib_in": Vector3(58, 0, -53),
		"east_mid": Vector3(58, 0, -5), "uni_path": Vector3(58, 0, 52), "uni_front": Vector3(58, 0, 55.5), "uni_in": Vector3(58, 0, 62),
		"south_w": Vector3(-24, 0, 52), "sports_in": Vector3(-38, 0, 58)
	}
	var edges := [
		["gate", "ave_s1"], ["ave_s1", "ave_s2"], ["ave_s2", "quad_s"], ["quad_s", "quad_c"],
		["quad_c", "quad_n"], ["quad_c", "quad_w"], ["quad_c", "quad_e"],
		["quad_w", "ave_w"], ["ave_w", "dorm_path"], ["dorm_path", "dorm_front"], ["dorm_front", "dorm_in"],
		["quad_e", "ave_e"], ["ave_e", "food_path"], ["food_path", "food_front"], ["food_front", "food_in"],
		["quad_n", "lec_path"], ["lec_path", "lec_front"], ["lec_front", "lec_in"],
		["quad_n", "lib_path"], ["lib_path", "lib_front"], ["lib_front", "lib_in"],
		["quad_e", "east_mid"], ["east_mid", "lib_path"], ["east_mid", "uni_path"], ["uni_path", "uni_front"], ["uni_front", "uni_in"],
		["ave_s2", "south_w"], ["south_w", "sports_in"], ["south_w", "uni_path"]
	]
	var astar := AStar3D.new()
	var ids: Dictionary = {}
	var nid := 0
	for k in nodes.keys():
		astar.add_point(nid, nodes[k])
		ids[k] = nid
		nid += 1
	for e in edges:
		astar.connect_points(ids[e[0]], ids[e[1]], true)
	var zone_entry := {"dorm": "dorm_in", "lecture": "lec_in", "library": "lib_in", "foodcourt": "food_in", "union": "uni_in", "quad": "quad_c", "sports": "sports_in", "gate": "gate"}

	return {
		"astar": astar, "ids": ids, "nodes": nodes, "zone_entry": zone_entry,
		"zone_spots": spots, "lamps": lamps,
		"counter_pos": Vector3(74.5, 0, 18), "counter_front": Vector3(72.6, 0, 18),
		"chai_pos": Vector3(15, 0, 24), "chai_front": Vector3(15, 0, 26.2),
		"librarian_pos": Vector3(58, 0, -63.5), "canteen_staff_pos": Vector3(76.2, 0, 18),
		"chai_staff_pos": Vector3(15, 0, 22.6)
	}

static func _grid_spots(center: Vector3, cols: int, rows: int, dx: float, dz: float) -> Array:
	var out: Array = []
	for r in range(rows):
		for c in range(cols):
			out.append(center + Vector3((float(c) - float(cols - 1) * 0.5) * dx, 0, (float(r) - float(rows - 1) * 0.5) * dz))
	return out

static func _build_interiors() -> void:
	var wood_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(1.4, 0.8))
	var dark_m := TexGen.mat_color(Color(0.20, 0.22, 0.26), 0.7)
	# Lecture Block A: tiered-ish desk rows + board
	for r in range(3):
		for c in range(6):
			var p := Vector3(-70.0 + float(c) * 4.4, 0.42, -60.5 + float(r) * 3.2)
			_box(wood_m, p, Vector3(1.7, 0.84, 0.8), true)
	_box(TexGen.mat_color(Color(0.12, 0.25, 0.18), 0.6), Vector3(-58, 2.4, -66.6), Vector3(12, 2.6, 0.15), false)
	_sign("LECTURE BLOCK A — Hall 1", Vector3(-58, 3.2, -66.4), 64, Color(0.9, 1.0, 0.9))
	# Library: shelf rows + reading tables
	var shelf_m := TexGen.mat_tex(TexGen.tex_wood(), Color(0.75, 0.62, 0.5), Vector2(3, 2))
	var book_cols := [Color(0.55, 0.2, 0.15), Color(0.15, 0.3, 0.55), Color(0.2, 0.45, 0.25), Color(0.6, 0.45, 0.12)]
	for r in range(3):
		var z := -63.0 + float(r) * 5.4
		_box(shelf_m, Vector3(49.5, 1.3, z), Vector3(0.8, 2.6, 4.4), true)
		_box(shelf_m, Vector3(66.5, 1.3, z), Vector3(0.8, 2.6, 4.4), true)
		for bidx in range(4):
			_box(TexGen.mat_color(book_cols[bidx], 0.9), Vector3(49.5, 0.9 + float(bidx % 2) * 0.9, z - 1.4 + float(bidx) * 0.8), Vector3(0.86, 0.62, 0.55), false)
	for t in [Vector3(58, 0, -57), Vector3(58, 0, -52)]:
		_box(wood_m, t + Vector3(0, 0.4, 0), Vector3(5.5, 0.8, 1.6), true)
	# Food Court: counter along east wall + tables + menu board
	_box(TexGen.mat_color(Color(0.85, 0.5, 0.15), 0.6), Vector3(77.5, 0.55, 18), Vector3(3.4, 1.1, 11), true)
	_box(TexGen.mat_tex(TexGen.tex_marble(), Color.WHITE, Vector2(3, 1)), Vector3(77.5, 1.16, 18), Vector3(3.6, 0.1, 11.4), false)
	_box(dark_m, Vector3(79.6, 2.9, 18), Vector3(0.15, 1.9, 9.5), false)
	_sign("MENU — Thali ₹60 • Biryani ₹140 • Masala Dosa ₹80\nSamosa (2 pc) ₹20 • Cutlet ₹30 • Cold Drink ₹25", Vector3(79.5, 3.0, 18), 58, Color(1.0, 0.95, 0.8), -PI / 2.0)
	for tx in [58.0, 64.0, 70.0]:
		for tz in [12.5, 23.5]:
			_cyl(TexGen.mat_color(Color(0.9, 0.88, 0.85), 0.4), Vector3(tx, 0.78, tz), 0.95, 0.08, false)
			_cyl(dark_m, Vector3(tx, 0.38, tz), 0.09, 0.76, true)
	# Residence Hall: beds + wardrobes in two rows (common-room style interior)
	for i in range(5):
		var bx := -76.0 + float(i) * 5.2
		_box(TexGen.mat_color(Color(0.75, 0.78, 0.85), 0.9), Vector3(bx, 0.32, 12.4), Vector3(1.1, 0.5, 2.2), true)
		_box(TexGen.mat_color(Color(0.95, 0.95, 0.95), 0.9), Vector3(bx, 0.62, 11.6), Vector3(1.05, 0.14, 0.6), false)
		_box(wood_m, Vector3(bx, 1.0, 24.6), Vector3(1.4, 2.0, 0.6), true)
	# Student Union: stage + sofa blocks + notice pillars
	_box(wood_m, Vector3(58, 0.3, 71.5), Vector3(12, 0.6, 4.4), true)
	for sx in [50.0, 55.0, 61.0, 66.0]:
		_box(TexGen.mat_color(Color(0.55, 0.25, 0.35), 0.95), Vector3(sx, 0.45, 62), Vector3(2.2, 0.9, 1.0), true)
	_sign("CLUBS — Coding • Debate • Dance • Music • Finance • Art", Vector3(58, 3.4, 58.4), 60, Color(1.0, 0.95, 0.85), PI)

static func _build_bus(pos: Vector3, rot_y: float) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var body_m := TexGen.mat_color(Color(0.92, 0.62, 0.10), 0.5)
	_box(body_m, Vector3(0, 1.55, 0), Vector3(8.6, 2.3, 2.5), false)
	_box(TexGen.mat_glass(), Vector3(0, 2.05, 0), Vector3(8.0, 0.8, 2.56), false)
	_box(TexGen.mat_color(Color(0.15, 0.15, 0.16), 0.7), Vector3(0, 0.42, 0), Vector3(8.7, 0.25, 2.55), false)
	for wx in [-3.2, -1.1, 1.6, 3.4]:
		_cyl(TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.9), Vector3(wx, 0.45, 1.15), 0.45, 0.25, false)
		_cyl(TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.9), Vector3(wx, 0.45, -1.15), 0.45, 0.25, false)
	_parent = saved
	_add_box_shape(pos + Vector3(0, 1.4, 0), Vector3(8.8, 2.8, 2.6), rot_y)

static func _build_rickshaw(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = -0.4
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	_box(TexGen.mat_color(Color(0.10, 0.45, 0.20), 0.6), Vector3(0, 0.75, 0), Vector3(1.3, 0.9, 2.4), false)
	_box(TexGen.mat_color(Color(0.95, 0.75, 0.10), 0.7), Vector3(0, 1.65, -0.2), Vector3(1.35, 0.55, 1.9), false)
	_cyl(TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.9), Vector3(0, 0.32, 1.25), 0.32, 0.18, false)
	_cyl(TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.9), Vector3(-0.6, 0.32, -1.0), 0.32, 0.18, false)
	_cyl(TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.9), Vector3(0.6, 0.32, -1.0), 0.32, 0.18, false)
	_parent = saved
	_add_box_shape(pos + Vector3(0, 0.8, 0), Vector3(1.5, 1.7, 2.6), -0.4)

static func _build_chai_stall(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var wood_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(2, 1))
	_box(wood_m, Vector3(0, 0.55, 0), Vector3(3.0, 1.1, 1.2), false)
	for px in [-1.35, 1.35]:
		for pz in [-0.8, 0.8]:
			_box(wood_m, Vector3(px, 1.5, pz), Vector3(0.09, 3.0, 0.09), false)
	_box(TexGen.mat_color(Color(0.75, 0.30, 0.12), 0.9), Vector3(0, 3.05, 0), Vector3(3.4, 0.1, 2.2), false)
	_cyl(TexGen.mat_color(Color(0.6, 0.62, 0.65), 0.3), Vector3(-0.7, 1.28, 0), 0.22, 0.35, false)
	_cyl(TexGen.mat_color(Color(0.85, 0.6, 0.2), 0.4), Vector3(0.4, 1.22, 0.1), 0.16, 0.22, false)
	_sign("CHAI POINT — Chai ₹15 • Bun Maska ₹25", Vector3(0, 2.55, 1.16), 56, Color(1.0, 0.9, 0.6))
	_parent = saved
	_add_box_shape(pos + Vector3(0, 0.8, 0), Vector3(3.0, 1.7, 1.3))

static func _build_sports() -> void:
	var pitch_m := TexGen.mat_tex(TexGen.tex_grass(), Color(0.85, 1.05, 0.85), Vector2(40, 24))
	_ground_plane(pitch_m, Vector3(-52, 0.018, 62), Vector2(56, 34))
	var line_m := TexGen.mat_color(Color(0.96, 0.96, 0.96), 0.8)
	# boundary + halfway lines (thin flat boxes)
	_box(line_m, Vector3(-52, 0.05, 45.4), Vector3(56, 0.03, 0.35), false)
	_box(line_m, Vector3(-52, 0.05, 78.6), Vector3(56, 0.03, 0.35), false)
	_box(line_m, Vector3(-79.8, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	_box(line_m, Vector3(-24.2, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	_box(line_m, Vector3(-52, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	# cricket pitch strip in the middle
	_box(TexGen.mat_color(Color(0.80, 0.72, 0.55), 1.0), Vector3(-52, 0.045, 62), Vector3(3.0, 0.03, 20), false)
	# goals at both ends
	var post_m := TexGen.mat_color(Color(0.95, 0.95, 0.95), 0.5)
	for gx in [-79.0, -25.0]:
		_cyl(post_m, Vector3(gx, 1.2, 58.2), 0.09, 2.4, true)
		_cyl(post_m, Vector3(gx, 1.2, 65.8), 0.09, 2.4, true)
		var bar := _cyl(post_m, Vector3(gx, 2.42, 62), 0.09, 7.6, false)
		bar.rotation.x = PI / 2.0
	# stands (west side, stepped)
	var stand_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.86), Vector2(20, 2))
	for i in range(3):
		_box(stand_m, Vector3(-86.0 - float(i) * 1.6, 0.5 + float(i) * 0.65, 62), Vector3(1.6, 1.0 + float(i) * 0.6, 30), true)
	_sign("SPORTS COMPLEX", Vector3(-84, 4.6, 62), 84, Color(1, 1, 1), -PI / 2.0)
	# basketball hoop near union path
	_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.5), Vector3(-14, 1.6, 46), 0.09, 3.2, true)
	_box(TexGen.mat_color(Color(0.9, 0.5, 0.15), 0.6), Vector3(-14, 3.15, 46), Vector3(1.1, 0.7, 0.08), false)
