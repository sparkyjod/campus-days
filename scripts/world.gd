class_name World
extends RefCounted

## Builds the Northbridge University campus: US-style spacious layout
## (central quad, wide avenues, faculty blocks, landmark library, student
## union, residence hall, sports complex, gate + bus loop) with Indian
## cultural content (chai stall, food court, rickshaw). 1 unit = 1 metre.
## All solids register collision shapes on one StaticBody3D. Also builds
## the AStar3D waypoint graph along avenues and through entrances.
##
## Overhaul pass (user review, Phase 0+1 change round): GTA-style street
## scene — asphalt avenues with lane markings/zebra crossings/kerbs,
## detailed cars/scooters/bicycles, glass-front Lecture Block C, Blocks
## B + Admin, shops row, gardens + pond + amphitheatre, running track,
## basketball court, and dense street furniture everywhere.

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
static var _shared_torus: TorusMesh = null

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

static func _torus(mat: Material, pos: Vector3, inner_r: float, outer_r: float, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner_r
	t.outer_radius = outer_r
	t.rings = 20
	t.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_parent.add_child(mi)
	return mi

static func _ground_plane(mat: Material, pos: Vector3, size: Vector2, rot_y: float = 0.0) -> void:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
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

static func _window(wall_pos: Vector3, horiz: String, fixed: float, w: float, h: float, y: float, ac: bool = false) -> void:
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
	if ac:
		# window AC unit under the sill
		_box(TexGen.mat_color(Color(0.82, 0.83, 0.85), 0.6), center + off.normalized() * 0.16 + Vector3(0, -h * 0.5 - 0.32, 0), Vector3(0.95, 0.52, 0.4) if (horiz == "south" or horiz == "north") else Vector3(0.4, 0.52, 0.95), false)

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
	# lintel above the door (only when the run is taller than the door —
	# skirting runs reuse this with height < door_h and need no lintel)
	if height > door_h + 0.05:
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
	var glass_front: bool = cfg.get("glass_front", false)
	var accent: Color = cfg.get("accent", tint.darkened(0.35))
	var wall_m := TexGen.mat_tex(wall_tex, tint, Vector2(w / 3.2, h / 3.2))
	var trim_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.95, 0.93, 0.88), Vector2(w / 3.0, 0.4))
	var accent_m := TexGen.mat_color(accent, 0.8)
	var skirt_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.55, 0.54, 0.52), Vector2(w / 3.0, 0.3))
	var roof_m := TexGen.mat_tex(TexGen.tex_roof(), Color.WHITE, Vector2(w / 2.6, d / 2.6))
	var x0 := center.x - w * 0.5
	var x1 := center.x + w * 0.5
	var z0 := center.z - d * 0.5
	var z1 := center.z + d * 0.5
	var th := 0.4
	var door_axis := center.x if (door_side == "south" or door_side == "north") else center.z
	# floor (interior)
	_ground_plane(TexGen.mat_tex(TexGen.tex_marble(), Color(0.96, 0.95, 0.92), Vector2(w / 2.2, d / 2.2), 0.35), Vector3(center.x, 0.03, center.z), Vector2(w, d))
	# walls (door on door_side)
	_wall_run(wall_m, Vector3(x0, 0, z0), Vector3(x1, 0, z0), h, th, center.x if door_side == "north" else -9999.0)
	_wall_run(wall_m, Vector3(x0, 0, z1), Vector3(x1, 0, z1), h, th, center.x if door_side == "south" else -9999.0)
	_wall_run(wall_m, Vector3(x0, 0, z0), Vector3(x0, 0, z1), h, th, center.z if door_side == "west" else -9999.0)
	_wall_run(wall_m, Vector3(x1, 0, z0), Vector3(x1, 0, z1), h, th, center.z if door_side == "east" else -9999.0)
	# skirting / plinth band (with door gap on the door side)
	_wall_run(skirt_m, Vector3(x0, 0, z0), Vector3(x1, 0, z0), 0.55, 0.48, center.x if door_side == "north" else -9999.0)
	_wall_run(skirt_m, Vector3(x0, 0, z1), Vector3(x1, 0, z1), 0.55, 0.48, center.x if door_side == "south" else -9999.0)
	_wall_run(skirt_m, Vector3(x0, 0, z0), Vector3(x0, 0, z1), 0.55, 0.48, center.z if door_side == "west" else -9999.0)
	_wall_run(skirt_m, Vector3(x1, 0, z0), Vector3(x1, 0, z1), 0.55, 0.48, center.z if door_side == "east" else -9999.0)
	# accent floor band + cornice + roof slab
	_box(accent_m, Vector3(center.x, h * 0.52, center.z), Vector3(w + 0.34, 0.30, d + 0.34), false)
	_box(trim_m, Vector3(center.x, h - 0.25, center.z), Vector3(w + 0.3, 0.5, d + 0.3), false)
	_box(trim_m, Vector3(center.x, h + 0.02, center.z), Vector3(w + 0.62, 0.22, d + 0.62), false)
	_box(roof_m, Vector3(center.x, h + 0.22, center.z), Vector3(w + 1.0, 0.45, d + 1.0), true)
	_box(roof_m, Vector3(center.x, h + 0.75, center.z), Vector3(w * 0.5, 0.7, d * 0.55), false)
	# parapet railing on taller blocks
	if h >= 9.0:
		var rail_m := TexGen.mat_color(Color(0.25, 0.26, 0.30), 0.45)
		for ry in [h + 0.72, h + 1.02]:
			_box(rail_m, Vector3(center.x, ry, z0 + 0.35), Vector3(w - 0.4, 0.05, 0.05), false)
			_box(rail_m, Vector3(center.x, ry, z1 - 0.35), Vector3(w - 0.4, 0.05, 0.05), false)
			_box(rail_m, Vector3(x0 + 0.35, ry, center.z), Vector3(0.05, 0.05, d - 0.4), false)
			_box(rail_m, Vector3(x1 - 0.35, ry, center.z), Vector3(0.05, 0.05, d - 0.4), false)
	# roof props: water tank + AC units + corner downpipe
	var tank_m := TexGen.mat_color(Color(0.16, 0.17, 0.19), 0.7)
	_cyl(tank_m, Vector3(center.x + w * 0.28, h + 1.35, center.z - d * 0.22), 1.0, 1.8, false)
	_box(TexGen.mat_color(Color(0.4, 0.4, 0.42), 0.6), Vector3(center.x + w * 0.28, h + 0.5, center.z - d * 0.22), Vector3(1.6, 0.25, 1.6), false)
	var unit_m := TexGen.mat_color(Color(0.72, 0.73, 0.75), 0.55)
	_box(unit_m, Vector3(center.x - w * 0.30, h + 0.85, center.z + d * 0.18), Vector3(1.4, 0.8, 0.95), false)
	_box(unit_m, Vector3(center.x - w * 0.12, h + 0.85, center.z - d * 0.25), Vector3(1.2, 0.8, 0.9), false)
	_cyl(TexGen.mat_color(Color(0.45, 0.46, 0.48), 0.6), Vector3(x0 + 0.3, h * 0.5, z1 + 0.30), 0.07, h, false)
	# windows: two rows on long sides, one row on short sides
	var rows := [2.0, h - 1.6] if h > 8.0 else [2.0]
	for ry in rows:
		var nx := int(w / 5.0)
		for i in range(nx):
			var wx := x0 + (float(i) + 0.5) * (w / float(nx))
			var ac := (i + int(ry)) % 3 == 0
			if not (glass_front and door_side == "north"):
				if door_side != "north" or absf(wx - center.x) > 2.2:
					_window(Vector3(wx, 0, z0), "north", 0.0, 1.7, 1.5, ry, ac)
			if not (glass_front and door_side == "south"):
				if door_side != "south" or absf(wx - center.x) > 2.2:
					_window(Vector3(wx, 0, z1), "south", 0.0, 1.7, 1.5, ry, ac)
		var nz := int(d / 5.0)
		for j in range(nz):
			var wz := z0 + (float(j) + 0.5) * (d / float(nz))
			if door_side != "west" or absf(wz - center.z) > 2.2:
				_window(Vector3(x0, 0, wz), "west", 0.0, 1.7, 1.5, ry)
			if door_side != "east" or absf(wz - center.z) > 2.2:
				_window(Vector3(x1, 0, wz), "east", 0.0, 1.7, 1.5, ry)
	# glass curtain front (modern block): floor-to-near-roof panes + mullions
	if glass_front:
		var gz := z1 if door_side == "south" else z0
		var out := 1.0 if door_side == "south" else -1.0
		var npan := int(w / 4.4)
		for i in range(npan):
			var px := x0 + (float(i) + 0.5) * (w / float(npan))
			if absf(px - center.x) < 1.8:
				continue # entrance gap
			var q := QuadMesh.new()
			q.size = Vector2(w / float(npan) - 0.35, h - 1.9)
			_mi(q, TexGen.mat_glass(), Vector3(px, (h - 1.9) * 0.5 + 0.75, gz + out * 0.24), Vector3.ONE, 0.0 if out > 0 else PI)
			_box(TexGen.mat_color(Color(0.30, 0.31, 0.34), 0.4), Vector3(px - w / float(npan) * 0.5, h * 0.5, gz + out * 0.22), Vector3(0.14, h - 0.8, 0.08), false)
		_box(TexGen.mat_color(Color(0.30, 0.31, 0.34), 0.4), Vector3(center.x, h - 1.05, gz + out * 0.22), Vector3(w, 0.16, 0.08), false)
	# entrance: steps, canopy on columns, door leaf ajar, sign on backing panel
	var door_pos := Vector3(center.x, 0, z1) if door_side == "south" else Vector3(center.x, 0, z0) if door_side == "north" else Vector3(x1, 0, center.z) if door_side == "east" else Vector3(x0, 0, center.z)
	var step_off := Vector3(0, 0, 1.1) if door_side == "south" else Vector3(0, 0, -1.1) if door_side == "north" else Vector3(1.1, 0, 0) if door_side == "east" else Vector3(-1.1, 0, 0)
	var out_dir := step_off.normalized()
	var along := Vector3(out_dir.z, 0, out_dir.x)
	_box(TexGen.mat_tex(TexGen.tex_concrete(), Color.WHITE, Vector2(3.4, 1.6)), door_pos + step_off + Vector3(0, 0.09, 0), Vector3(3.6, 0.18, 2.2) if (door_side == "south" or door_side == "north") else Vector3(2.2, 0.18, 3.6), false)
	# canopy slab + two slim columns
	_box(trim_m, door_pos + out_dir * 1.15 + Vector3(0, 3.02, 0), Vector3(3.8, 0.14, 1.9) if along.x != 0.0 else Vector3(1.9, 0.14, 3.8), false)
	for cs in [-1.55, 1.55]:
		_cyl(TexGen.mat_color(Color(0.35, 0.36, 0.38), 0.4), door_pos + out_dir * 1.85 + along * cs + Vector3(0, 1.5, 0), 0.07, 3.0, true)
	# door leaf, half-open
	_box(TexGen.mat_tex(TexGen.tex_wood(), Color(0.8, 0.65, 0.5), Vector2(1, 2)), door_pos + along * 0.95 + out_dir * 0.28 + Vector3(0, 1.32, 0), Vector3(1.05, 2.64, 0.09) if along.x != 0.0 else Vector3(0.09, 2.64, 1.05), false, 0.5 if along.x != 0.0 else 0.5 + PI / 2.0)
	if name_text != "":
		var sign_pos := door_pos + step_off * 1.4 + Vector3(0, 3.4, 0)
		var rot := 0.0 if door_side == "south" else PI if door_side == "north" else PI / 2.0 if door_side == "east" else -PI / 2.0
		# scale the lettering to the facade so small buildings (shops)
		# don't get 13 m signboards swallowing their neighbours
		var face_w := w if along.x != 0.0 else d
		var font_px := int(110.0 * clampf(face_w / 22.0, 0.34, 1.0))
		var panel_w := clampf(name_text.length() * font_px * 0.0058 + 0.8, 2.2, face_w - 0.3)
		var panel_h := 1.12 * clampf(face_w / 22.0, 0.34, 1.0) + 0.25
		_box(TexGen.mat_color(Color(0.13, 0.16, 0.24), 0.5), sign_pos - out_dir * 0.10, Vector3(panel_w, panel_h, 0.14) if along.x != 0.0 else Vector3(0.14, panel_h, panel_w), false)
		_sign(name_text, sign_pos, font_px, Color(1.0, 0.95, 0.80), rot)

static func _tree(pos: Vector3, scl: float = 1.0, shade: int = 0) -> void:
	var trunk_m := TexGen.mat_tex(TexGen.tex_wood(), Color(0.8, 0.7, 0.6), Vector2(1, 2))
	var leaf_cols := [Color(0.20, 0.42, 0.16), Color(0.16, 0.36, 0.13), Color(0.26, 0.48, 0.18)]
	var leaf_m := TexGen.mat_color(leaf_cols[shade % 3], 1.0)
	_cyl(trunk_m, pos + Vector3(0, 1.4 * scl, 0), 0.22 * scl, 2.8 * scl, true)
	_sphere(leaf_m, pos + Vector3(0, 3.9 * scl, 0), Vector3(3.4, 3.0, 3.4) * scl)
	_sphere(leaf_m, pos + Vector3(0.9 * scl, 3.1 * scl, 0.4 * scl), Vector3(2.2, 2.0, 2.2) * scl)
	_sphere(leaf_m, pos + Vector3(-0.9 * scl, 3.2 * scl, -0.4 * scl), Vector3(2.3, 2.1, 2.3) * scl)

static func _bush(pos: Vector3, scl: float = 1.0) -> void:
	var leaf_m := TexGen.mat_color(Color(0.15, 0.33, 0.12), 1.0)
	_sphere(leaf_m, pos + Vector3(0, 0.32 * scl, 0), Vector3(1.1, 0.65, 1.1) * scl)
	_sphere(leaf_m, pos + Vector3(0.4 * scl, 0.24 * scl, 0.2 * scl), Vector3(0.7, 0.5, 0.7) * scl)

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

static func _street_pole(pos: Vector3, arm_dir: Vector3) -> void:
	# decorative streetlight (no extra light node — performance)
	var pole_m := TexGen.mat_color(Color(0.20, 0.21, 0.24), 0.5)
	_cyl(pole_m, pos + Vector3(0, 2.9, 0), 0.08, 5.8, true)
	_box(pole_m, pos + Vector3(0, 5.75, 0) + arm_dir * 0.7, Vector3(1.5, 0.09, 0.12) if absf(arm_dir.x) > 0.5 else Vector3(0.12, 0.09, 1.5), false)
	_box(TexGen.mat_emissive(Color(1.0, 0.92, 0.7), 0.5), pos + Vector3(0, 5.62, 0) + arm_dir * 1.35, Vector3(0.55, 0.09, 0.24) if absf(arm_dir.x) > 0.5 else Vector3(0.24, 0.09, 0.55), false)

static func _dustbin(pos: Vector3) -> void:
	_cyl(TexGen.mat_color(Color(0.13, 0.35, 0.18), 0.7), pos + Vector3(0, 0.36, 0), 0.27, 0.72, true)
	_cyl(TexGen.mat_color(Color(0.10, 0.10, 0.11), 0.6), pos + Vector3(0, 0.75, 0), 0.29, 0.07, false)

static func _notice_board(pos: Vector3, rot_y: float, lines: String) -> void:
	_box(TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(3, 2)), pos + Vector3(0, 1.5, 0), Vector3(3.4, 2.0, 0.18), true, rot_y)
	var fwd := Vector3(sin(rot_y), 0, cos(rot_y))
	_sign(lines, pos + Vector3(0, 1.6, 0) - fwd * 0.13, 54, Color(1.0, 0.97, 0.85), rot_y + PI)

static func _signpost(pos: Vector3, entries: Array) -> void:
	_cyl(TexGen.mat_color(Color(0.22, 0.23, 0.26), 0.5), pos + Vector3(0, 1.5, 0), 0.06, 3.0, true)
	var board_m := TexGen.mat_color(Color(0.15, 0.30, 0.45), 0.6)
	var y := 2.75
	for e in entries:
		var rot: float = e[1]
		_box(board_m, pos + Vector3(0, y, 0), Vector3(1.7, 0.34, 0.05), false, rot)
		var fwd := Vector3(sin(rot), 0, cos(rot))
		_sign(e[0], pos + Vector3(0, y + 0.01, 0) + fwd * 0.05, 44, Color(1, 1, 1), rot)
		y -= 0.48

static func build(parent: Node3D) -> Dictionary:
	_parent = parent
	_body = StaticBody3D.new()
	_body.name = "CampusStatic"
	parent.add_child(_body)
	var lamps: Array = []
	var seats: Dictionary = {"quad": [], "garden": []}

	var grass_m := TexGen.mat_tex(TexGen.tex_grass(), Color.WHITE, Vector2(90, 68))
	var pave_m := TexGen.mat_tex(TexGen.tex_paving(), Color.WHITE, Vector2(30, 30))
	var quad_m := TexGen.mat_tex(TexGen.tex_grass(), Color(1.05, 1.02, 0.9), Vector2(46, 30))
	var asphalt_m := TexGen.mat_tex(TexGen.tex_asphalt(), Color.WHITE, Vector2(26, 26))
	var paint_m := TexGen.mat_color(Color(0.94, 0.94, 0.92), 0.75)
	var kerb_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.92, 0.90, 0.86), Vector2(20, 0.4))

	# --- ground + perimeter
	_ground_plane(grass_m, Vector3(0, 0, 0), Vector2(280, 210))
	_add_box_shape(Vector3(0, -0.6, 0), Vector3(280, 1.0, 210))
	var hedge_m := TexGen.mat_color(Color(0.16, 0.34, 0.13), 1.0)
	for b in [[Vector3(0, 0.9, -103), Vector3(278, 1.8, 1.6)], [Vector3(-139, 0.9, 0), Vector3(1.6, 1.8, 208)], [Vector3(139, 0.9, 0), Vector3(1.6, 1.8, 208)]]:
		_box(hedge_m, b[0], b[1], true)
	# south fence with gate gap x in [-7, 7]
	_box(hedge_m, Vector3(-73, 0.9, 103), Vector3(132, 1.8, 1.6), true)
	_box(hedge_m, Vector3(73, 0.9, 103), Vector3(132, 1.8, 1.6), true)

	# --- avenues: main + east-west are ASPHALT streets now (GTA-style),
	#     branch paths stay paving
	_ground_plane(asphalt_m, Vector3(0, 0.02, 46), Vector2(9, 108)) # main avenue gate->quad
	_ground_plane(asphalt_m, Vector3(0, 0.02, -5), Vector2(150, 7)) # east-west avenue
	_ground_plane(pave_m, Vector3(0, 0.021, -24), Vector2(252, 6)) # north avenue (extended to Blocks B/C)
	_ground_plane(pave_m, Vector3(-44, 0.02, 7), Vector2(6, 26)) # dorm branch
	_ground_plane(pave_m, Vector3(44, 0.02, 7), Vector2(6, 26)) # food branch
	_ground_plane(pave_m, Vector3(-58, 0.02, -34), Vector2(6, 22)) # lecture branch
	_ground_plane(pave_m, Vector3(58, 0.02, 2), Vector2(6, 100)) # east avenue (library + union)
	_ground_plane(pave_m, Vector3(4, 0.02, 52), Vector2(116, 6)) # south avenue (sports + union)
	_ground_plane(pave_m, Vector3(-24, 0.02, 41), Vector2(6, 24)) # sports branch
	_ground_plane(pave_m, Vector3(82, 0.02, 52), Vector2(52, 4)) # garden path
	# bus loop at gate (asphalt disc)
	var loop := CylinderMesh.new()
	loop.top_radius = 16.0
	loop.bottom_radius = 16.0
	loop.height = 0.06
	loop.radial_segments = 28
	_mi(loop, asphalt_m, Vector3(0, 0.03, 92), Vector3.ONE)
	# kerbs along the main avenue + painted kerb blocks near the gate
	for kx in [-4.85, 4.85]:
		_box(kerb_m, Vector3(kx, 0.07, 55), Vector3(0.3, 0.14, 82), false)
	for i in range(6):
		_box(paint_m if i % 2 == 0 else TexGen.mat_color(Color(0.9, 0.7, 0.15), 0.7), Vector3(-4.85, 0.15, 90.0 + float(i) * 1.6), Vector3(0.32, 0.05, 1.4), false)
		_box(paint_m if i % 2 == 1 else TexGen.mat_color(Color(0.9, 0.7, 0.15), 0.7), Vector3(4.85, 0.15, 90.0 + float(i) * 1.6), Vector3(0.32, 0.05, 1.4), false)
	# dashed centre lines on the asphalt avenues
	for z in range(18, 92, 7):
		_box(paint_m, Vector3(0, 0.035, float(z)), Vector3(0.18, 0.012, 3.0), false)
	for x in range(-70, 72, 7):
		if absf(float(x)) < 6.0:
			continue
		_box(paint_m, Vector3(float(x), 0.035, -5), Vector3(3.0, 0.012, 0.18), false)
	# zebra crossings: at the gate and at the quad crossing
	for cx in [-3.4, -1.7, 0.0, 1.7, 3.4]:
		_box(paint_m, Vector3(cx, 0.036, 97.5), Vector3(1.1, 0.012, 3.4), false)
		_box(paint_m, Vector3(cx, 0.036, 15.5), Vector3(1.1, 0.012, 3.4), false)
	# avenue banners (fest / library week) on both sides
	var banner_cols := [Color(0.75, 0.25, 0.20), Color(0.15, 0.35, 0.65), Color(0.85, 0.55, 0.12), Color(0.30, 0.55, 0.30)]
	var bi := 0
	for bz in [30.0, 46.0, 62.0, 78.0]:
		for bx in [-5.4, 5.4]:
			_cyl(TexGen.mat_color(Color(0.22, 0.23, 0.26), 0.5), Vector3(bx, 2.6, bz), 0.06, 5.2, true)
			_box(TexGen.mat_color(banner_cols[bi % 4], 0.9), Vector3(bx - signf(bx) * 0.45, 4.1, bz), Vector3(0.85, 1.9, 0.05), false)
			bi += 1
	# streetlight poles (decorative heads; real light nodes stay the 10 lamps)
	for sp in [[Vector3(-4.8, 0, 22), Vector3(1, 0, 0)], [Vector3(4.8, 0, 40), Vector3(-1, 0, 0)], [Vector3(-4.8, 0, 58), Vector3(1, 0, 0)], [Vector3(4.8, 0, 76), Vector3(-1, 0, 0)], [Vector3(-30, 0, -8.6), Vector3(0, 0, 1)], [Vector3(30, 0, -1.4), Vector3(0, 0, -1)], [Vector3(-64, 0, -8.6), Vector3(0, 0, 1)], [Vector3(64, 0, -1.4), Vector3(0, 0, -1)]]:
		_street_pole(sp[0], sp[1])

	# --- central quad lawns (4 quadrants around crossing paths)
	for q in [Vector3(-19, 0.015, -15.5), Vector3(19, 0.015, -15.5), Vector3(-19, 0.015, 5.5), Vector3(19, 0.015, 5.5)]:
		_ground_plane(quad_m, q, Vector2(31, 15))

	# --- buildings (Phase 1 set)
	_building({"center": Vector3(-58, 0, -58), "w": 36, "d": 18, "h": 12, "door_side": "south", "name": "LECTURE BLOCK A", "wall_tex": TexGen.tex_brick(), "tint": Color(1.0, 0.92, 0.85), "accent": Color(0.55, 0.25, 0.18)})
	_building({"center": Vector3(58, 0, -58), "w": 34, "d": 18, "h": 13, "door_side": "south", "name": "CENTRAL LIBRARY", "wall_tex": TexGen.tex_concrete(), "tint": Color(1.02, 0.98, 0.90), "accent": Color(0.35, 0.38, 0.45)})
	_building({"center": Vector3(66, 0, 18), "w": 28, "d": 16, "h": 7, "door_side": "west", "name": "FOOD COURT", "wall_tex": TexGen.tex_brick(), "tint": Color(1.05, 0.95, 0.80), "accent": Color(0.75, 0.40, 0.12)})
	_building({"center": Vector3(-66, 0, 18), "w": 30, "d": 16, "h": 11, "door_side": "east", "name": "RESIDENCE HALL", "wall_tex": TexGen.tex_concrete(), "tint": Color(0.92, 0.90, 0.98), "accent": Color(0.40, 0.35, 0.55)})
	_building({"center": Vector3(58, 0, 66), "w": 32, "d": 16, "h": 9, "door_side": "north", "name": "STUDENT UNION", "wall_tex": TexGen.tex_brick(), "tint": Color(0.88, 0.92, 1.02), "accent": Color(0.65, 0.30, 0.35)})
	# --- buildings (overhaul additions: Blocks B & C, Admin)
	_building({"center": Vector3(-104, 0, -72), "w": 34, "d": 18, "h": 12, "door_side": "south", "name": "LECTURE BLOCK B", "wall_tex": TexGen.tex_concrete(), "tint": Color(0.98, 0.94, 0.88), "accent": Color(0.20, 0.40, 0.55)})
	_building({"center": Vector3(104, 0, -72), "w": 34, "d": 18, "h": 11, "door_side": "south", "name": "LECTURE BLOCK C", "wall_tex": TexGen.tex_concrete(), "tint": Color(0.94, 0.96, 0.98), "accent": Color(0.25, 0.30, 0.35), "glass_front": true})
	_building({"center": Vector3(-104, 0, -34), "w": 26, "d": 14, "h": 8, "door_side": "south", "name": "ADMIN BLOCK", "wall_tex": TexGen.tex_brick(), "tint": Color(0.95, 0.90, 0.82), "accent": Color(0.45, 0.30, 0.20)})
	# library dome + entrance columns (landmark)
	var dome_m := TexGen.mat_color(Color(0.36, 0.44, 0.48), 0.4)
	_sphere(dome_m, Vector3(58, 13.9, -58), Vector3(12, 3.4, 12))
	var col_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(1.05, 1.02, 0.95), Vector2(1, 4))
	for cx in [-6.0, -2.0, 2.0, 6.0]:
		_cyl(col_m, Vector3(58 + cx, 1.7, -47.6), 0.42, 3.4, true)

	# --- interiors & props
	_build_interiors()
	_lecture_interior_at(Vector3(-104, 0, -72), "LECTURE BLOCK B — Hall 1")
	_lecture_interior_at(Vector3(104, 0, -72), "LECTURE BLOCK C — Hall 1")
	_admin_interior()

	# --- gate: pillars, arch, sign, bus, rickshaw, glass bus shelter
	var stone_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.84), Vector2(1.5, 5))
	_box(stone_m, Vector3(-7.5, 2.6, 100), Vector3(1.6, 5.2, 1.6), true)
	_box(stone_m, Vector3(7.5, 2.6, 100), Vector3(1.6, 5.2, 1.6), true)
	_box(stone_m, Vector3(0, 5.6, 100), Vector3(17, 1.1, 1.8), true)
	_sign("NORTHBRIDGE UNIVERSITY", Vector3(0, 5.6, 98.9), 120, Color(1.0, 0.9, 0.6), PI)
	_sign("NORTHBRIDGE UNIVERSITY", Vector3(0, 5.6, 101.1), 120, Color(1.0, 0.9, 0.6), 0.0)
	# flags on the gate arch
	for fx in [-6.5, 6.5]:
		_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.5), Vector3(fx, 6.9, 100), 0.04, 1.6, false)
		_box(TexGen.mat_color(Color(0.95, 0.55, 0.15) if fx < 0 else Color(0.15, 0.45, 0.25), 0.9), Vector3(fx + 0.45, 7.35, 100), Vector3(0.9, 0.55, 0.04), false)
	_build_bus(Vector3(-11, 0, 90), 0.3)
	_build_rickshaw(Vector3(10.5, 0, 86))
	_sign("BUS STOP", Vector3(-11, 3.4, 95.5), 72, Color(1, 1, 1), PI)
	_build_bus_shelter(Vector3(-14.5, 0, 78))

	# --- chai stall near quad south-east (+ umbrellas, tables, stools)
	_build_chai_stall(Vector3(15, 0, 24))
	_build_chai_seating()

	# --- shops row + parking (near gate)
	_build_shops()
	_build_parking()

	# --- gardens + pond + amphitheatre (south-east)
	_build_gardens(seats)

	# --- sports complex: pitch, track, goals, stands, floodlights, basketball
	_build_sports()

	# --- trees, bushes, benches, lamps, boards, bins, signposts
	var tree_spots := [Vector3(-30, 0, -20), Vector3(30, 0, -20), Vector3(-30, 0, 10), Vector3(30, 0, 10), Vector3(-12, 0, -19), Vector3(12, 0, 9), Vector3(-95, 0, -30), Vector3(95, 0, -30), Vector3(-100, 0, 40), Vector3(100, 0, 40), Vector3(-20, 0, 84), Vector3(22, 0, 84), Vector3(90, 0, -70), Vector3(-90, 0, -70), Vector3(0, 0, -34), Vector3(-104, 0, -6), Vector3(104, 0, -6), Vector3(30, 0, 34), Vector3(-32, 0, 34),
		Vector3(-7.5, 0, 20), Vector3(7.5, 0, 52), Vector3(-7.5, 0, 66), Vector3(7.5, 0, 34), Vector3(-122, 0, -88), Vector3(122, 0, -88), Vector3(-126, 0, -50), Vector3(126, 0, -50), Vector3(12, 0, 70), Vector3(-38, 0, 72), Vector3(36, 0, 92), Vector3(-88, 0, 6), Vector3(88, 0, 8), Vector3(-14, 0, -34), Vector3(16, 0, -36), Vector3(-52, 0, 30), Vector3(84, 0, -30)]
	var ti := 0
	for t in tree_spots:
		_tree(t, 0.9 + float(ti % 4) * 0.12, ti % 3)
		ti += 1
	for bp in [Vector3(-40, 0, -46), Vector3(-76, 0, -46), Vector3(42, 0, -46), Vector3(74, 0, -46), Vector3(-6, 0, 12), Vector3(6, 0, -22), Vector3(-48, 0, 8), Vector3(48, 0, 8), Vector3(-84, 0, 28), Vector3(84, 0, 28), Vector3(20, 0, 30), Vector3(-22, 0, 26), Vector3(44, 0, 58), Vector3(-46, 0, 58), Vector3(126, 0, 20), Vector3(-126, 0, 16)]:
		_bush(bp, 0.9 + float(int(bp.x) % 3) * 0.15)
	# quad flower beds
	var flower_m := TexGen.mat_tex(TexGen.tex_flowers(), Color.WHITE, Vector2(3, 1))
	var edging_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.84), Vector2(3, 0.3))
	for fb in [Vector3(-33, 0, -23), Vector3(33, 0, -23), Vector3(-33, 0, 13), Vector3(33, 0, 13), Vector3(46, 0, -44), Vector3(70, 0, -44)]:
		_box(edging_m, fb + Vector3(0, 0.16, 0), Vector3(4.4, 0.32, 1.5), false)
		_box(flower_m, fb + Vector3(0, 0.30, 0), Vector3(4.1, 0.10, 1.2), false)
	var bench_defs := [[Vector3(-8, 0, -12), 0.4], [Vector3(9, 0, 2), -0.5], [Vector3(-14, 0, 3), 0.2], [Vector3(15, 0, -14), 2.8], [Vector3(0, 0, 40), 0.0], [Vector3(-40, 0, -14), 1.57], [Vector3(40, 0, -14), -1.57], [Vector3(-20, 0, -16), 0.9], [Vector3(22, 0, 8), -2.2], [Vector3(17, 0, 78), 1.57]]
	for b in bench_defs:
		_bench(b[0], b[1])
		# two seat spots per quad bench (garden benches handled in _build_gardens)
		if absf(b[0].x) < 30.0 and absf(b[0].z) < 30.0:
			var rot: float = b[1]
			var side := Vector3(cos(rot), 0, -sin(rot))
			for so in [-0.45, 0.45]:
				seats["quad"].append({"pos": b[0] + side * so + Vector3(0, 0, 0.0), "yaw": rot})
	for lp in [Vector3(-4.5, 0, 30), Vector3(4.5, 0, 62), Vector3(-20, 0, -8), Vector3(20, 0, -8), Vector3(-61, 0, -30), Vector3(61, 0, -30), Vector3(-44, 0, 22), Vector3(48, 0, 22), Vector3(54, 0, 48), Vector3(-4.5, 0, 88)]:
		lamps.append(_lamp(lp))
	for db in [Vector3(6, 0, 18), Vector3(-6.5, 0, -2), Vector3(20, 0, 26), Vector3(-46, 0, -20), Vector3(50, 0, -20), Vector3(16, 0, 80), Vector3(60, 0, 56), Vector3(-60, 0, 56)]:
		_dustbin(db)
	_notice_board(Vector3(5.5, 0, 16), 0.0, "NOTICE BOARD\n• Fest auditions next week\n• Debate selections open")
	_notice_board(Vector3(50, 0, -44), PI, "LIBRARY\n• New arrivals: Gate prep shelf\n• Reading hall till 10 PM")
	_notice_board(Vector3(50, 0, 54), 0.0, "STUDENT UNION\n• Club registrations open\n• Music society jam Fridays")
	_signpost(Vector3(6.5, 0, 14), [["LIBRARY →", PI / 2.0], ["← HOSTEL", -PI / 2.0], ["SHOPS ↓", 0.0]])
	_signpost(Vector3(-50, 0, -20), [["← BLOCK B", PI], ["ADMIN →", -PI / 2.0]])
	_signpost(Vector3(52, 0, -20), [["BLOCK C →", 0.0], ["← LIBRARY", PI / 2.0]])
	# cycle stands near library + dorm
	_build_cycle_stand(Vector3(44, 0, -40), 0.3)
	_build_cycle_stand(Vector3(-48, 0, 26), -0.2)

	# --- zone spots (where NPCs stand/sit inside each zone)
	var spots := {
		"dorm": _grid_spots(Vector3(-66, 0, 18), 5, 3, 4.6, 3.6),
		"lecture": _grid_spots(Vector3(-58, 0, -57), 6, 3, 4.4, 3.2),
		"library": _grid_spots(Vector3(58, 0, -57), 5, 3, 4.8, 3.4),
		"foodcourt": _grid_spots(Vector3(64, 0, 18), 4, 3, 4.2, 3.6),
		"union": _grid_spots(Vector3(58, 0, 66), 5, 3, 4.6, 3.6),
		"quad": [Vector3(-8, 0, -12), Vector3(9, 0, 2), Vector3(-14, 0, 3), Vector3(15, 0, -14), Vector3(-19, 0, -15), Vector3(19, 0, 6), Vector3(-19, 0, 6), Vector3(19, 0, -16), Vector3(3, 0, -20), Vector3(-3, 0, 11), Vector3(26, 0, -5), Vector3(-26, 0, -5)],
		"sports": [Vector3(-40, 0, 58), Vector3(-58, 0, 66), Vector3(-66, 0, 55), Vector3(-35, 0, 72), Vector3(-52, 0, 48), Vector3(-70, 0, 70), Vector3(-28, 0, 50), Vector3(-62, 0, 76)],
		"gate": [Vector3(-6, 0, 94), Vector3(6, 0, 93), Vector3(-12, 0, 96), Vector3(3, 0, 88)],
		"lectureb": _grid_spots(Vector3(-104, 0, -71), 6, 3, 4.4, 3.2),
		"lecturec": _grid_spots(Vector3(104, 0, -71), 6, 3, 4.4, 3.2),
		"admin": _grid_spots(Vector3(-104, 0, -34), 4, 3, 4.2, 3.2),
		"shops": [Vector3(19.5, 0, 74), Vector3(19.5, 0, 80), Vector3(19.5, 0, 86), Vector3(19.5, 0, 92), Vector3(21.5, 0, 77), Vector3(21.5, 0, 83), Vector3(21.5, 0, 89), Vector3(17.5, 0, 95)],
		"garden": [Vector3(98, 0, 44), Vector3(106, 0, 52), Vector3(112, 0, 46), Vector3(100, 0, 58), Vector3(116, 0, 54), Vector3(94, 0, 36), Vector3(108, 0, 36), Vector3(118, 0, 64), Vector3(96, 0, 66), Vector3(98, 0, 78), Vector3(104, 0, 80), Vector3(92, 0, 82)]
	}
	for s in seats["quad"]:
		spots["quad"].append(s["pos"])
	for s in seats["garden"]:
		spots["garden"].append(s["pos"])

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
		"south_w": Vector3(-24, 0, 52), "sports_in": Vector3(-38, 0, 58),
		"nw1": Vector3(-52, 0, -24), "nw2": Vector3(-104, 0, -24), "lecb_front": Vector3(-104, 0, -59), "lecb_in": Vector3(-104, 0, -67), "admin_in": Vector3(-104, 0, -30),
		"ne1": Vector3(86, 0, -24), "lecc_front": Vector3(104, 0, -59), "lecc_in": Vector3(104, 0, -67),
		"shops": Vector3(17, 0, 84), "gard_mid": Vector3(84, 0, 52), "garden_in": Vector3(100, 0, 50)
	}
	var edges := [
		["gate", "ave_s1"], ["ave_s1", "ave_s2"], ["ave_s2", "quad_s"], ["quad_s", "quad_c"],
		["quad_c", "quad_n"], ["quad_c", "quad_w"], ["quad_c", "quad_e"],
		["quad_w", "ave_w"], ["ave_w", "dorm_path"], ["dorm_path", "dorm_front"], ["dorm_front", "dorm_in"],
		["quad_e", "ave_e"], ["ave_e", "food_path"], ["food_path", "food_front"], ["food_front", "food_in"],
		["quad_n", "lec_path"], ["lec_path", "lec_front"], ["lec_front", "lec_in"],
		["quad_n", "lib_path"], ["lib_path", "lib_front"], ["lib_front", "lib_in"],
		["quad_e", "east_mid"], ["east_mid", "lib_path"], ["east_mid", "uni_path"], ["uni_path", "uni_front"], ["uni_front", "uni_in"],
		["ave_s2", "south_w"], ["south_w", "sports_in"], ["south_w", "uni_path"],
		["quad_n", "nw1"], ["nw1", "nw2"], ["nw2", "lecb_front"], ["lecb_front", "lecb_in"], ["nw2", "admin_in"],
		["lib_path", "ne1"], ["ne1", "lecc_front"], ["lecc_front", "lecc_in"],
		["gate", "shops"], ["ave_s1", "shops"],
		["uni_path", "gard_mid"], ["gard_mid", "garden_in"]
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
	var zone_entry := {"dorm": "dorm_in", "lecture": "lec_in", "library": "lib_in", "foodcourt": "food_in", "union": "uni_in", "quad": "quad_c", "sports": "sports_in", "gate": "gate",
		"lectureb": "lecb_in", "lecturec": "lecc_in", "admin": "admin_in", "shops": "shops", "garden": "garden_in"}

	return {
		"astar": astar, "ids": ids, "nodes": nodes, "zone_entry": zone_entry,
		"zone_spots": spots, "lamps": lamps, "seats": seats,
		"counter_pos": Vector3(74.5, 0, 18), "counter_front": Vector3(72.6, 0, 18),
		"chai_pos": Vector3(15, 0, 24), "chai_front": Vector3(15, 0, 26.2),
		"librarian_pos": Vector3(58, 0, -63.5), "canteen_staff_pos": Vector3(76.2, 0, 18),
		"chai_staff_pos": Vector3(15, 0, 22.6), "shop_staff_pos": Vector3(21.0, 0, 82.5)
	}

static func _grid_spots(center: Vector3, cols: int, rows: int, dx: float, dz: float) -> Array:
	var out: Array = []
	for r in range(rows):
		for c in range(cols):
			out.append(center + Vector3((float(c) - float(cols - 1) * 0.5) * dx, 0, (float(r) - float(rows - 1) * 0.5) * dz))
	return out

static func _lecture_interior_at(center: Vector3, title: String) -> void:
	var wood_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(1.4, 0.8))
	for r in range(3):
		for c in range(6):
			var p := center + Vector3(-12.0 + float(c) * 4.4, 0.42, -2.5 + float(r) * 3.2)
			_box(wood_m, p, Vector3(1.7, 0.84, 0.8), true)
	_box(TexGen.mat_color(Color(0.12, 0.25, 0.18), 0.6), center + Vector3(0, 2.4, -8.55), Vector3(12, 2.6, 0.15), false)
	_sign(title, center + Vector3(0, 3.2, -8.35), 64, Color(0.9, 1.0, 0.9))

static func _admin_interior() -> void:
	var wood_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(1.4, 0.8))
	var center := Vector3(-104, 0, -34)
	# front counter + office desks + visitor chairs
	_box(wood_m, center + Vector3(0, 0.55, 3.4), Vector3(9.0, 1.1, 0.9), true)
	for i in range(4):
		_box(wood_m, center + Vector3(-8.4 + float(i) * 5.6, 0.42, -3.4), Vector3(1.9, 0.84, 0.9), true)
	for i in range(3):
		_box(TexGen.mat_color(Color(0.30, 0.35, 0.55), 0.9), center + Vector3(-4.0 + float(i) * 4.0, 0.30, 5.6), Vector3(0.55, 0.6, 0.55), true)
	_sign("ADMIN BLOCK — Admissions • Fees • Exam Cell", center + Vector3(0, 3.1, -6.8), 58, Color(1.0, 0.97, 0.85))

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

static func _build_chai_seating() -> void:
	# two umbrella tables with stools beside the chai stall
	var umb_cols := [Color(0.85, 0.35, 0.15), Color(0.15, 0.5, 0.65)]
	var i := 0
	for tp in [Vector3(20.5, 0, 28.5), Vector3(10.0, 0, 29.0)]:
		_cyl(TexGen.mat_color(Color(0.35, 0.3, 0.25), 0.6), tp + Vector3(0, 1.05, 0), 0.05, 2.1, true)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 1.5
		cone.height = 0.5
		cone.radial_segments = 12
		_mi(cone, TexGen.mat_color(umb_cols[i % 2], 0.9), tp + Vector3(0, 2.25, 0), Vector3.ONE)
		_cyl(TexGen.mat_color(Color(0.92, 0.90, 0.86), 0.4), tp + Vector3(0, 0.72, 0), 0.55, 0.06, false)
		for a in [0.4, 2.5, 4.4]:
			_cyl(TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(0.4, 0.4)), tp + Vector3(sin(a) * 0.95, 0.24, cos(a) * 0.95), 0.19, 0.48, true)
		i += 1

static func _build_bus_shelter(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var frame_m := TexGen.mat_color(Color(0.25, 0.27, 0.30), 0.4)
	var glass_m := TexGen.mat_glass()
	for px in [-2.6, 0.0, 2.6]:
		_box(frame_m, Vector3(px, 1.3, -0.8), Vector3(0.09, 2.6, 0.09), false)
	_box(glass_m, Vector3(0, 1.35, -0.82), Vector3(5.4, 1.9, 0.04), false)
	_box(glass_m, Vector3(-2.68, 1.35, 0), Vector3(0.04, 1.9, 1.6), false)
	_box(glass_m, Vector3(2.68, 1.35, 0), Vector3(0.04, 1.9, 1.6), false)
	_box(TexGen.mat_color(Color(0.55, 0.57, 0.60), 0.35), Vector3(0, 2.72, 0), Vector3(5.8, 0.12, 2.0), false)
	_box(TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(2, 0.4)), Vector3(0, 0.55, -0.45), Vector3(4.6, 0.09, 0.4), false)
	_sign("CITY BUS — Route 12 • University Gate", Vector3(0, 2.35, -0.9), 46, Color(1, 1, 1), PI)
	_parent = saved
	_add_box_shape(pos + Vector3(0, 1.0, -0.7), Vector3(5.6, 2.0, 0.4))

static func _build_shops() -> void:
	# row of small shops east of the main avenue, doors facing west
	_ground_plane(TexGen.mat_tex(TexGen.tex_paving(), Color.WHITE, Vector2(10, 18)), Vector3(18.5, 0.022, 82.5), Vector2(15, 26))
	var defs := [
		{"center": Vector3(25, 0, 72.5), "name": "JUICE JUNCTION", "tex": "brick", "tint": Color(1.05, 0.9, 0.7), "accent": Color(0.85, 0.5, 0.12)},
		{"center": Vector3(25, 0, 79.5), "name": "STATIONERY & PRINTS", "tex": "concrete", "tint": Color(0.95, 0.97, 1.0), "accent": Color(0.15, 0.35, 0.65)},
		{"center": Vector3(25, 0, 86.5), "name": "XEROX POINT", "tex": "brick", "tint": Color(0.9, 0.95, 0.9), "accent": Color(0.3, 0.5, 0.3)},
		{"center": Vector3(25, 0, 93.5), "name": "CAMPUS BOOKS", "tex": "concrete", "tint": Color(1.0, 0.95, 0.85), "accent": Color(0.55, 0.25, 0.35)}
	]
	for d in defs:
		_building({"center": d["center"], "w": 5.5, "d": 6.0, "h": 3.9, "door_side": "west", "name": d["name"], "wall_tex": TexGen.tex_brick() if d["tex"] == "brick" else TexGen.tex_concrete(), "tint": d["tint"], "accent": d["accent"]})
		# striped awning over the door
		var awn := _box(TexGen.mat_color(d["accent"], 0.9), d["center"] + Vector3(-3.6, 2.95, 0), Vector3(1.7, 0.07, 5.2), false)
		awn.rotation.z = 0.28
	# goods crates + a hand cart outside the shops
	var crate_m := TexGen.mat_tex(TexGen.tex_wood(), Color(0.9, 0.8, 0.65), Vector2(1, 1))
	_box(crate_m, Vector3(20.5, 0.35, 69.5), Vector3(0.7, 0.7, 0.7), true)
	_box(crate_m, Vector3(20.5, 1.05, 69.5), Vector3(0.6, 0.6, 0.6), false)
	_box(crate_m, Vector3(21.4, 0.3, 96.5), Vector3(0.65, 0.6, 0.65), true)
	_box(TexGen.mat_color(Color(0.6, 0.2, 0.15), 0.7), Vector3(19.8, 0.75, 90.0), Vector3(1.6, 0.08, 0.9), false)
	_cyl(TexGen.mat_color(Color(0.15, 0.15, 0.16), 0.8), Vector3(19.3, 0.3, 89.6), 0.3, 0.12, false)
	_cyl(TexGen.mat_color(Color(0.15, 0.15, 0.16), 0.8), Vector3(20.3, 0.3, 90.4), 0.3, 0.12, false)
	# overhead wire span across the shops lane
	_wire(Vector3(13.5, 6.4, 70), Vector3(13.5, 5.9, 84))
	_wire(Vector3(13.5, 5.9, 84), Vector3(13.5, 6.4, 98))

static func _wire(p1: Vector3, p2: Vector3) -> void:
	var mid := (p1 + p2) * 0.5
	mid.y -= 0.35 # sag
	var len := p1.distance_to(mid)
	for pair in [[p1, mid], [mid, p2]]:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		var m := (a + b) * 0.5
		var dir := (b - a).normalized()
		var t := Transform3D(Basis.looking_at(dir, Vector3.UP), m)
		var mi := MeshInstance3D.new()
		if _shared_box == null:
			_shared_box = _box_mesh()
		mi.mesh = _shared_box
		mi.material_override = TexGen.mat_color(Color(0.08, 0.08, 0.09), 0.8)
		mi.transform = t
		mi.scale = Vector3(0.035, 0.035, a.distance_to(b))
		_parent.add_child(mi)

static func _build_car(pos: Vector3, rot_y: float, color: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var body_m := TexGen.mat_color(color, 0.35)
	var dark_m := TexGen.mat_color(Color(0.10, 0.10, 0.11), 0.8)
	_box(body_m, Vector3(0, 0.58, 0), Vector3(1.78, 0.52, 4.3), false) # lower body (length along Z)
	_box(body_m, Vector3(0, 0.92, -0.15), Vector3(1.62, 0.30, 2.2), false) # shoulder line
	_box(TexGen.mat_glass(), Vector3(0, 1.13, -0.15), Vector3(1.58, 0.42, 2.05), false) # glasshouse
	_box(body_m, Vector3(0, 1.38, -0.15), Vector3(1.66, 0.07, 1.7), false) # roof
	_box(dark_m, Vector3(0, 0.28, 2.16), Vector3(1.8, 0.18, 0.1), false)
	_box(dark_m, Vector3(0, 0.28, -2.16), Vector3(1.8, 0.18, 0.1), false)
	for sx in [-0.78, 0.78]:
		_box(TexGen.mat_emissive(Color(1.0, 0.95, 0.8), 0.8), Vector3(sx * 0.72, 0.66, 2.16), Vector3(0.34, 0.13, 0.04), false)
		_box(TexGen.mat_emissive(Color(0.85, 0.15, 0.12), 0.7), Vector3(sx * 0.72, 0.66, -2.16), Vector3(0.34, 0.13, 0.04), false)
	for wx in [-0.82, 0.82]:
		for wz in [-1.45, 1.45]:
			var wheel := _cyl(dark_m, Vector3(wx, 0.34, wz), 0.34, 0.22, false)
			wheel.rotation.z = PI / 2.0
			_cyl(TexGen.mat_color(Color(0.62, 0.63, 0.66), 0.35), Vector3(wx * 1.01, 0.34, wz), 0.17, 0.23, false).rotation.z = PI / 2.0
	_parent = saved
	_add_box_shape(pos, Vector3(1.9, 1.3, 4.4), rot_y)

static func _build_scooter(pos: Vector3, rot_y: float, color: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var body_m := TexGen.mat_color(color, 0.4)
	var dark_m := TexGen.mat_color(Color(0.10, 0.10, 0.11), 0.85)
	_box(body_m, Vector3(0, 0.42, 0.1), Vector3(0.42, 0.30, 1.15), false) # floor + body spine
	var shield := _box(body_m, Vector3(0, 0.78, 0.72), Vector3(0.44, 0.62, 0.14), false)
	shield.rotation.x = -0.22
	_box(TexGen.mat_glass(), Vector3(0, 1.16, 0.80), Vector3(0.36, 0.28, 0.03), false) # windscreen
	_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.4), Vector3(0, 1.12, 0.66), 0.03, 0.5, false).rotation.z = PI / 2.0
	_box(dark_m, Vector3(0, 0.82, -0.28), Vector3(0.40, 0.13, 0.72), false) # seat
	_box(body_m, Vector3(0, 0.55, -0.62), Vector3(0.40, 0.42, 0.35), false) # rear body
	_box(TexGen.mat_emissive(Color(1.0, 0.95, 0.8), 0.8), Vector3(0, 0.92, 0.80), Vector3(0.16, 0.11, 0.04), false)
	for wz in [0.78, -0.72]:
		var wheel := _cyl(dark_m, Vector3(0, 0.26, wz), 0.26, 0.13, false)
		wheel.rotation.z = PI / 2.0
	_parent = saved
	_add_box_shape(pos, Vector3(0.6, 1.1, 1.9), rot_y)

static func _build_bicycle(pos: Vector3, rot_y: float, color: Color, lean: float = 0.0) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	g.rotation.z = lean
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	var frame_m := TexGen.mat_color(color, 0.4)
	var dark_m := TexGen.mat_color(Color(0.12, 0.12, 0.13), 0.7)
	for wz in [0.52, -0.52]:
		_torus(dark_m, Vector3(0, 0.34, wz), 0.30, 0.345, Vector3(0, 0, PI / 2.0))
	# frame tubes (thin boxes in the YZ plane)
	var tube1 := _box(frame_m, Vector3(0, 0.62, 0.02), Vector3(0.045, 0.045, 0.78), false)
	tube1.rotation.x = 0.10
	var tube2 := _box(frame_m, Vector3(0, 0.55, 0.28), Vector3(0.045, 0.62, 0.045), false)
	tube2.rotation.x = 0.65
	var tube3 := _box(frame_m, Vector3(0, 0.55, -0.30), Vector3(0.045, 0.60, 0.045), false)
	tube3.rotation.x = -0.55
	_box(dark_m, Vector3(0, 0.88, -0.38), Vector3(0.16, 0.05, 0.24), false) # saddle
	_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.4), Vector3(0, 0.92, 0.52), 0.025, 0.42, false).rotation.x = PI / 2.0
	_parent = saved

static func _build_cycle_stand(pos: Vector3, rot_y: float) -> void:
	var rail_m := TexGen.mat_color(Color(0.35, 0.36, 0.40), 0.35)
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	_parent.add_child(g)
	var saved := _parent
	_parent = g
	_cyl(rail_m, Vector3(0, 0.55, 0), 0.035, 4.6, false).rotation.x = PI / 2.0
	for pz in [-2.2, 2.2]:
		_cyl(rail_m, Vector3(0, 0.28, pz), 0.035, 0.56, false)
	_parent = saved
	_add_box_shape(pos, Vector3(0.4, 0.7, 4.8), rot_y)
	var cols := [Color(0.75, 0.25, 0.2), Color(0.2, 0.4, 0.75), Color(0.15, 0.55, 0.3), Color(0.85, 0.6, 0.15), Color(0.5, 0.3, 0.6)]
	for i in range(4):
		var bp := pos + Vector3(sin(rot_y), 0, cos(rot_y)) * 0.0 + Vector3(cos(rot_y), 0, -sin(rot_y)) * (0.55 + float(i) * 0.15)
		_build_bicycle(bp + Vector3(0.35, 0, -1.6 + float(i) * 1.05), rot_y + 0.06 * float(i % 2), cols[i % cols.size()], 0.10)

static func _build_parking() -> void:
	var asphalt_m := TexGen.mat_tex(TexGen.tex_asphalt(), Color.WHITE, Vector2(16, 12))
	_ground_plane(asphalt_m, Vector3(-26, 0.024, 84), Vector2(27, 21))
	var paint_m := TexGen.mat_color(Color(0.9, 0.9, 0.88), 0.8)
	for i in range(4): # bay lines
		_box(paint_m, Vector3(-36.0 + float(i) * 6.4, 0.034, 79), Vector3(0.14, 0.012, 9.0), false)
	_sign("PARKING — Students & Staff", Vector3(-26, 3.1, 74.2), 64, Color(1, 1, 1), PI)
	_cyl(TexGen.mat_color(Color(0.25, 0.26, 0.3), 0.5), Vector3(-33, 1.5, 74.2), 0.06, 3.0, true)
	_cyl(TexGen.mat_color(Color(0.25, 0.26, 0.3), 0.5), Vector3(-19, 1.5, 74.2), 0.06, 3.0, true)
	_build_car(Vector3(-32, 0, 79), 0.06, Color(0.72, 0.74, 0.78)) # silver hatchback
	_build_car(Vector3(-25, 0, 79.5), -0.04, Color(0.65, 0.16, 0.14)) # red
	_build_car(Vector3(-18.5, 0, 79), 0.02, Color(0.16, 0.28, 0.55)) # blue
	_build_car(Vector3(30, 0, 89), 0.9, Color(0.92, 0.90, 0.86)) # white car near shops
	_build_scooter(Vector3(-15.5, 0, 88), 1.35, Color(0.15, 0.35, 0.6))
	_build_scooter(Vector3(-15.2, 0, 90.3), 1.5, Color(0.75, 0.3, 0.15))
	_build_scooter(Vector3(-15.6, 0, 92.6), 1.42, Color(0.2, 0.2, 0.22))
	_build_scooter(Vector3(50, 0, 27), -0.7, Color(0.8, 0.65, 0.15))
	_build_cycle_stand(Vector3(-35, 0, 90), 0.0)

static func _build_gardens(seats: Dictionary) -> void:
	var lawn_m := TexGen.mat_tex(TexGen.tex_grass(), Color(1.04, 1.0, 0.88), Vector2(30, 26))
	_ground_plane(lawn_m, Vector3(106, 0.016, 52), Vector2(62, 62))
	# paths
	var pave_m := TexGen.mat_tex(TexGen.tex_paving(), Color.WHITE, Vector2(10, 2))
	_ground_plane(pave_m, Vector3(100, 0.026, 50), Vector2(20, 3), 0.15)
	_ground_plane(pave_m, Vector3(110, 0.026, 42), Vector2(3, 18), -0.1)
	_ground_plane(pave_m, Vector3(98, 0.026, 66), Vector2(3, 22), 0.05)
	# pond with stone rim
	_cyl(TexGen.mat_tex(TexGen.tex_concrete(), Color(0.88, 0.86, 0.82), Vector2(6, 1)), Vector3(118, 0.11, 32), 5.9, 0.22, false)
	var water := CylinderMesh.new()
	water.top_radius = 5.45
	water.bottom_radius = 5.45
	water.height = 0.05
	water.radial_segments = 24
	_mi(water, TexGen.mat_tex(TexGen.tex_water(), Color(0.8, 0.92, 1.0), Vector2(4, 4), 0.3), Vector3(118, 0.235, 32), Vector3.ONE)
	_sign("THE LAKE CORNER", Vector3(112, 1.6, 26.5), 56, Color(1, 1, 1), PI * 0.85)
	# flower beds + bushes + trees
	var flower_m := TexGen.mat_tex(TexGen.tex_flowers(), Color.WHITE, Vector2(3, 1))
	var edging_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.84), Vector2(3, 0.3))
	for fb in [Vector3(96, 0, 40), Vector3(104, 0, 60), Vector3(122, 0, 46), Vector3(92, 0, 56), Vector3(124, 0, 66), Vector3(100, 0, 28), Vector3(109, 0, 47), Vector3(113, 0, 38)]:
		_box(edging_m, fb + Vector3(0, 0.16, 0), Vector3(4.4, 0.32, 1.5), false)
		_box(flower_m, fb + Vector3(0, 0.30, 0), Vector3(4.1, 0.10, 1.2), false)
	for bp in [Vector3(90, 0, 34), Vector3(126, 0, 38), Vector3(88, 0, 62), Vector3(120, 0, 58), Vector3(102, 0, 70)]:
		_bush(bp, 1.1)
	for tp in [Vector3(90, 0, 44), Vector3(124, 0, 26), Vector3(128, 0, 56), Vector3(94, 0, 70), Vector3(126, 0, 76), Vector3(104, 0, 44), Vector3(98, 0, 29), Vector3(122, 0, 52), Vector3(88, 0, 52)]:
		_tree(tp, 1.05, 1)
	# benches around the pond/lawn + seat spots
	var gbench := [[Vector3(110, 0, 27.5), 0.3], [Vector3(124, 0, 38), -1.2], [Vector3(98, 0, 46), 1.9], [Vector3(108, 0, 62), -0.6]]
	for b in gbench:
		_bench(b[0], b[1])
		var rot: float = b[1]
		var side := Vector3(cos(rot), 0, -sin(rot))
		for so in [-0.45, 0.45]:
			seats["garden"].append({"pos": b[0] + side * so, "yaw": rot})
	# ---- amphitheatre: stage + backdrop + stepped seating (open-air theatre)
	var stage_m := TexGen.mat_tex(TexGen.tex_wood(), Color.WHITE, Vector2(6, 3))
	_box(stage_m, Vector3(98, 0.3, 85), Vector3(13, 0.6, 5.5), true)
	_box(TexGen.mat_tex(TexGen.tex_concrete(), Color(0.95, 0.92, 0.88), Vector2(8, 2)), Vector3(98, 1.9, 88.2), Vector3(14, 3.8, 0.5), true)
	_sign("OPEN-AIR THEATRE", Vector3(98, 3.6, 87.9), 72, Color(0.98, 0.95, 0.85), PI)
	var step_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.92, 0.90, 0.86), Vector2(10, 1))
	for i in range(4):
		_box(step_m, Vector3(98, 0.28 + float(i) * 0.42, 76.5 - float(i) * 2.3), Vector3(15, 0.55 + float(i) * 0.42, 2.2), true)
	for sx in [89.5, 106.5]:
		_box(TexGen.mat_color(Color(0.75, 0.3, 0.18), 0.8), Vector3(sx, 1.5, 85), Vector3(0.35, 3.0, 0.35), true)
	_sign("FEST '26 — auditions open!", Vector3(98, 2.2, 82.1), 54, Color(1.0, 0.9, 0.6), PI)

static func _build_sports() -> void:
	var pitch_m := TexGen.mat_tex(TexGen.tex_grass(), Color(0.85, 1.05, 0.85), Vector2(40, 24))
	_ground_plane(pitch_m, Vector3(-52, 0.018, 62), Vector2(56, 34))
	# running track ring around the pitch
	var track_m := TexGen.mat_tex(TexGen.tex_track(), Color.WHITE, Vector2(24, 2))
	_ground_plane(track_m, Vector3(-52, 0.017, 42), Vector2(68, 6))
	_ground_plane(track_m, Vector3(-52, 0.017, 82), Vector2(68, 6))
	_ground_plane(track_m, Vector3(-83, 0.017, 62), Vector2(6, 34))
	_ground_plane(track_m, Vector3(-21, 0.017, 62), Vector2(6, 34))
	var line_m := TexGen.mat_color(Color(0.96, 0.96, 0.96), 0.8)
	# boundary + halfway lines (thin flat boxes)
	_box(line_m, Vector3(-52, 0.05, 45.4), Vector3(56, 0.03, 0.35), false)
	_box(line_m, Vector3(-52, 0.05, 78.6), Vector3(56, 0.03, 0.35), false)
	_box(line_m, Vector3(-79.8, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	_box(line_m, Vector3(-24.2, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	_box(line_m, Vector3(-52, 0.05, 62), Vector3(0.35, 0.03, 33), false)
	# cricket pitch strip in the middle
	_box(TexGen.mat_color(Color(0.80, 0.72, 0.55), 1.0), Vector3(-52, 0.045, 62), Vector3(3.0, 0.03, 20), false)
	# stumps at both ends of the cricket strip
	for sz in [53.0, 71.0]:
		for sx in [-0.35, 0.0, 0.35]:
			_cyl(TexGen.mat_color(Color(0.85, 0.75, 0.45), 0.7), Vector3(-52 + sx, 0.36, sz), 0.035, 0.71, false)
	# goals at both ends
	var post_m := TexGen.mat_color(Color(0.95, 0.95, 0.95), 0.5)
	for gx in [-79.0, -25.0]:
		_cyl(post_m, Vector3(gx, 1.2, 58.2), 0.09, 2.4, true)
		_cyl(post_m, Vector3(gx, 1.2, 65.8), 0.09, 2.4, true)
		var bar := _cyl(post_m, Vector3(gx, 2.42, 62), 0.09, 7.6, false)
		bar.rotation.x = PI / 2.0
	# stands (west side, stepped) + east bleachers
	var stand_m := TexGen.mat_tex(TexGen.tex_concrete(), Color(0.9, 0.88, 0.86), Vector2(20, 2))
	for i in range(3):
		_box(stand_m, Vector3(-86.0 - float(i) * 1.6, 0.5 + float(i) * 0.65, 62), Vector3(1.6, 1.0 + float(i) * 0.6, 30), true)
		_box(stand_m, Vector3(-13.5 + float(i) * 1.6, 0.5 + float(i) * 0.65, 66), Vector3(1.6, 1.0 + float(i) * 0.6, 20), true)
	_sign("SPORTS COMPLEX", Vector3(-84, 4.6, 62), 84, Color(1, 1, 1), -PI / 2.0)
	# floodlight pylons (visual heads; no extra light nodes)
	for fp in [Vector3(-80, 0, 44), Vector3(-24, 0, 44), Vector3(-80, 0, 80), Vector3(-24, 0, 80)]:
		_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.5), fp + Vector3(0, 5.0, 0), 0.12, 10.0, true)
		_box(TexGen.mat_emissive(Color(0.95, 0.97, 1.0), 0.7), fp + Vector3(0, 10.1, 0), Vector3(1.6, 0.7, 0.15), false)
	# basketball court (asphalt, painted lines, two hoops)
	_ground_plane(TexGen.mat_tex(TexGen.tex_asphalt(), Color(1.15, 0.95, 0.85), Vector2(10, 8)), Vector3(-14, 0.019, 34), Vector2(17, 12))
	_box(line_m, Vector3(-14, 0.032, 34), Vector3(0.25, 0.012, 12), false)
	_box(line_m, Vector3(-14, 0.032, 28.2), Vector3(17, 0.012, 0.25), false)
	_box(line_m, Vector3(-14, 0.032, 39.8), Vector3(17, 0.012, 0.25), false)
	for hx in [-21.5, -6.5]:
		_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.5), Vector3(hx, 1.9, 34), 0.09, 3.8, true)
		_box(TexGen.mat_color(Color(0.92, 0.92, 0.94), 0.5), Vector3(hx, 3.45, 34), Vector3(0.08, 0.75, 1.15), false)
		_torus(TexGen.mat_color(Color(0.85, 0.35, 0.1), 0.5), Vector3(hx + (0.35 if hx < -14 else -0.35), 3.02, 34), 0.20, 0.24)
	# practice hoop (kept from Phase 1)
	_cyl(TexGen.mat_color(Color(0.3, 0.3, 0.33), 0.5), Vector3(-14, 1.6, 46), 0.09, 3.2, true)
	_box(TexGen.mat_color(Color(0.9, 0.5, 0.15), 0.6), Vector3(-14, 3.15, 46), Vector3(1.1, 0.7, 0.08), false)
