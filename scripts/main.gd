extends Node3D

## Campus Days — Phase 0 + Phase 1 root.
## Builds the campus (World), runs the day clock + sun, spawns the Ten
## mains + background students + staff, drives timetable-based movement
## over the AStar waypoint graph, and handles all UI/interactions.

const ZONE_NAMES := {
	"dorm": "Residence Hall", "lecture": "Lecture Block A", "library": "Central Library",
	"foodcourt": "Food Court", "quad": "Central Quad", "union": "Student Union",
	"sports": "Sports Complex", "gate": "Main Gate",
	"lectureb": "Lecture Block B", "lecturec": "Lecture Block C",
	"admin": "Admin Block", "shops": "Campus Shops", "garden": "Gardens & Amphitheatre"
}

var _world: Dictionary = {}
var _astar: AStar3D
var _ids: Dictionary = {}
var _zone_entry: Dictionary = {}
var _zone_spots: Dictionary = {}

var _player: Player
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _lamps: Array = []

var _mains: Array = []
var _bgs: Array = []
var _staff: Array = []
var _all_npcs: Array = []

var day: int = 1
var game_minutes: float = 450.0 # 07:30
var speed_mult: float = 1.0 # 1 game-minute per real second at 1x
var paused: bool = false
var money: int = 500
var energy: float = 92.0

var _test_mode: bool = false
var _capture_mode: bool = false
var _test_start_ms: int = 0
var _test_arrivals: Dictionary = {}
var _rng := RandomNumberGenerator.new()

# UI refs
var _hud_day: Label
var _hud_clock: Label
var _hud_period: Label
var _hud_money: Label
var _hud_energy: ProgressBar
var _prompt_label: Label
var _toast_label: Label
var _toast_timer: float = 0.0
var _class_panel: PanelContainer
var _class_box: VBoxContainer
var _dialog_panel: PanelContainer
var _dlg_title: Label
var _dlg_text: RichTextLabel
var _dlg_friend: Label
var _dlg_btns: HBoxContainer
var _current_npc: NPC = null
var _interact_kind: String = ""
var _interact_npc: NPC = null
var _chat_cooldown: float = 0.0
var _ui_timer: float = 0.0

func _ready() -> void:
	_rng.randomize()
	var args := OS.get_cmdline_user_args()
	_test_mode = args.has("--campus-test")
	_capture_mode = args.has("--capture")
	_build_environment()
	_world = World.build(self)
	_astar = _world["astar"]
	_ids = _world["ids"]
	_zone_entry = _world["zone_entry"]
	_zone_spots = _world["zone_spots"]
	_lamps = _world["lamps"]
	_spawn_player()
	_spawn_people()
	_build_ui()
	if _test_mode:
		Engine.time_scale = 6.0
		speed_mult = 6.0
		for n in _all_npcs:
			(n as NPC).speed *= 6.0
		_test_start_ms = Time.get_ticks_msec()
		print("[TEST] Campus Days headless test started. Mains: ", _mains.size(), " BG: ", _bgs.size(), " Staff: ", _staff.size())
	elif _capture_mode:
		game_minutes = 630.0
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://preview"))
		_run_captures()
	else:
		_show_toast("Welcome to Northbridge University! Click to capture the mouse. WASD move, Shift run, E talk.")
	print("[CampusDays] Ready. Day 1, 07:30. NPCs in world: ", _all_npcs.size())

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	_env = Environment.new()
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color(0.25, 0.5, 0.85)
	_sky_mat.sky_horizon_color = Color(0.75, 0.85, 0.95)
	_sky_mat.ground_bottom_color = Color(0.55, 0.58, 0.52)
	_sky_mat.ground_horizon_color = Color(0.78, 0.86, 0.94)
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.55
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.background_energy_multiplier = 1.05
	_env.ambient_light_sky_contribution = 0.75
	# GTA-style colour grade + distance haze (Compatibility-safe: no glow)
	_env.adjustment_enabled = true
	_env.adjustment_brightness = 1.0
	_env.adjustment_contrast = 1.09
	_env.adjustment_saturation = 1.14
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.79, 0.84, 0.91)
	_env.fog_light_energy = 0.55
	_env.fog_density = 0.0022
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.light_energy = 1.1
	_sun.shadow_blur = 1.6
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_max_distance = 300.0
	add_child(_sun)
	# soft sky-bounce fill from the opposite side (no shadows)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(-0.9, 2.4, 0)
	fill.light_energy = 0.22
	fill.light_color = Color(0.75, 0.84, 1.0)
	fill.shadow_enabled = false
	add_child(fill)
	_build_clouds()

func _build_clouds() -> void:
	# soft billboard-free cloud blobs: flattened sphere clusters, high up
	var cloud_m := StandardMaterial3D.new()
	cloud_m.albedo_color = Color(0.97, 0.98, 1.0, 0.88)
	cloud_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_m.roughness = 1.0
	cloud_m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	var clusters := [Vector3(-70, 62, -60), Vector3(40, 68, -30), Vector3(95, 60, 40), Vector3(-110, 66, 30), Vector3(0, 72, 80), Vector3(-30, 58, -110), Vector3(120, 64, -90)]
	var ci := 0
	for c in clusters:
		for k in range(3):
			var mi := MeshInstance3D.new()
			mi.mesh = sm
			mi.material_override = cloud_m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var off := Vector3(float((ci * 7 + k * 13) % 17) - 8.0, float(k % 2) * 1.5, float((ci * 5 + k * 7) % 11) - 5.0)
			mi.position = c + off
			mi.scale = Vector3(15.0 + float(k * 4), 4.4, 9.0 + float(k * 2))
			add_child(mi)
		ci += 1

func _spawn_player() -> void:
	_player = Player.new()
	_player.position = Vector3(0, 0.1, 84)
	add_child(_player)

func _pick_spot(npc: NPC, zone: String, idx: int) -> Vector3:
	var spots: Array = _zone_spots[zone]
	var spot: Vector3 = spots[idx % spots.size()]
	npc.seated = false
	var seat_list: Array = (_world.get("seats", {}) as Dictionary).get(zone, [])
	for st in seat_list:
		if (st["pos"] as Vector3).distance_to(spot) < 0.05:
			npc.seated = true
			npc.seat_yaw = st["yaw"]
			break
	return spot

func _npc_common(data: Dictionary, is_main_flag: bool, zone: String, idx: int) -> NPC:
	var npc := NPC.new()
	add_child(npc)
	var start: Vector3 = _pick_spot(npc, zone, idx)
	npc.setup(data, is_main_flag, start, _rng.randf_range(1.35, 1.6))
	npc.current_zone = zone
	npc.target_zone = zone
	npc.spot = start
	_all_npcs.append(npc)
	return npc

func _spawn_people() -> void:
	var mains_data := CharData.mains()
	var mi := 0
	for d in mains_data:
		var start_zone: String = _segment_for(d, 7.5)
		var npc := _npc_common(d, true, start_zone, mi + 2)
		npc.friendship = 22 + (mi * 3) % 14
		_mains.append(npc)
		mi += 1
	# Background students — working NPCs with simple schedules
	var names := CharData.background_names()
	var shirt_cols := [Color(0.75, 0.3, 0.25), Color(0.25, 0.5, 0.75), Color(0.9, 0.7, 0.2), Color(0.4, 0.7, 0.4), Color(0.7, 0.45, 0.7), Color(0.3, 0.65, 0.65), Color(0.85, 0.55, 0.3), Color(0.5, 0.5, 0.55)]
	var skin_cols := [Color(0.78, 0.60, 0.45), Color(0.70, 0.52, 0.38), Color(0.62, 0.43, 0.30), Color(0.55, 0.38, 0.25), Color(0.48, 0.33, 0.22)]
	var templates := [
		{"morning": "dorm", "am1": "lecture", "am2": "library", "pm": "lecture", "club": "quad", "evening": "quad", "night": "dorm"},
		{"morning": "foodcourt", "am1": "lecture", "am2": "lecture", "pm": "library", "club": "union", "evening": "foodcourt", "night": "library"},
		{"morning": "dorm", "am1": "library", "am2": "lecture", "pm": "quad", "club": "sports", "evening": "sports", "night": "dorm"},
		{"morning": "quad", "am1": "lecture", "am2": "library", "pm": "library", "club": "library", "evening": "quad", "night": "dorm"},
		{"morning": "dorm", "am1": "lectureb", "am2": "library", "pm": "lecturec", "club": "garden", "evening": "shops", "night": "dorm"},
		{"morning": "foodcourt", "am1": "lecturec", "am2": "lectureb", "pm": "library", "club": "sports", "evening": "garden", "night": "library"}
	]
	var female_names := {"Priya": true, "Sneha": true, "Kavya": true, "Meera": true, "Ishita": true, "Pooja": true, "Ananya": true, "Nisha": true, "Tanya": true, "Riya": true, "Gauri": true, "Jyoti": true, "Lakshmi": true, "Neha": true}
	for i in range(24):
		var tpl: Dictionary = templates[i % templates.size()]
		var d := {
			"name": names[i], "major": "Student", "year": 1 + (i % 4),
			"height": _rng.randf_range(1.58, 1.86), "build": _rng.randf_range(0.88, 1.1),
			"skin": skin_cols[i % skin_cols.size()],
			"hair_style": i % 8, "hair_color": Color(0.08, 0.06, 0.05),
			"shirt": shirt_cols[i % shirt_cols.size()], "pants": Color(0.22, 0.23, 0.3),
			"female": female_names.has(names[i]),
			"pattern": "stripe" if i % 5 == 3 else ("check" if i % 7 == 4 else ""),
			"backpack": i % 3 == 0, "pack_color": shirt_cols[(i + 3) % shirt_cols.size()],
			"morning": tpl["morning"], "am1": tpl["am1"], "am2": tpl["am2"], "pm": tpl["pm"],
			"club": tpl["club"], "evening": tpl["evening"], "night": tpl["night"],
			"greeting": CharData.background_greetings()[i % CharData.background_greetings().size()]
		}
		var zone: String = _segment_for(d, 7.5)
		var npc := _npc_common(d, false, zone, i + 1)
		_bgs.append(npc)
	# Staff (stationary, role greetings)
	var staff_defs := [
		{"name": "Mrs. Iyer (Librarian)", "pos": _world["librarian_pos"], "zone": "library", "female": true,
			"line": "Shhh — welcome to the Central Library, beta. Reading hall rules: mobiles on silent, books back by 8 PM. Shreya practically lives here, you'll find her by the medical shelves."},
		{"name": "Mr. Khan (Food Court)", "pos": _world["canteen_staff_pos"], "zone": "foodcourt",
			"line": "Welcome, welcome! Lunch counter opens 1 to 2 — thali is only ₹60 for students, full ghee tadka. Come hungry, leave happy, that's our policy."},
		{"name": "Ramesh (Chai Stall)", "pos": _world["chai_staff_pos"], "zone": "quad",
			"line": "Chai, bhaiya/didi? Kadak masala, ₹15 only. Twenty years I've run this stall — half the professors did their PhD on my chai, I'm telling you."},
		{"name": "Bhola (Shops)", "pos": _world["shop_staff_pos"], "zone": "shops",
			"line": "Welcome to the campus shops lane! Xerox at ₹1 a page, juice fresh, books at student discount. Exam week, this whole lane stays open till midnight."}
	]
	for sd in staff_defs:
		var d := {
			"name": sd["name"], "major": "Staff", "year": 0,
			"height": 1.70, "build": 1.0, "skin": Color(0.60, 0.43, 0.30),
			"hair_style": 7, "hair_color": Color(0.2, 0.18, 0.16),
			"female": sd.get("female", false),
			"shirt": Color(0.88, 0.86, 0.82), "pants": Color(0.3, 0.28, 0.26),
			"greeting": sd["line"]
		}
		var npc := NPC.new()
		add_child(npc)
		npc.setup(d, false, sd["pos"], 1.4)
		npc.stationary = true
		npc.is_staff = true
		npc.current_zone = sd["zone"]
		npc.target_zone = sd["zone"]
		_all_npcs.append(npc)
		_staff.append(npc)

func _segment_for(data: Dictionary, hour: float) -> String:
	if hour < 9.0:
		return str(data.get("morning", "dorm"))
	elif hour < 11.0:
		return str(data.get("am1", "lecture"))
	elif hour < 13.0:
		return str(data.get("am2", "library"))
	elif hour < 14.0:
		return "foodcourt"
	elif hour < 16.0:
		return str(data.get("pm", "lecture"))
	elif hour < 18.0:
		return str(data.get("club", "quad"))
	elif hour < 20.0:
		return str(data.get("evening", "quad"))
	elif hour < 22.0:
		return str(data.get("night", "dorm"))
	return "dorm"

func _period_name(hour: float) -> String:
	if hour < 9.0:
		return "Morning"
	elif hour < 11.0:
		return "Lectures — Morning I"
	elif hour < 13.0:
		return "Lectures — Morning II"
	elif hour < 14.0:
		return "Lunch Break"
	elif hour < 16.0:
		return "Lectures — Afternoon"
	elif hour < 18.0:
		return "Clubs & Societies"
	elif hour < 20.0:
		return "Evening"
	elif hour < 22.0:
		return "Night Study"
	return "Wind Down"

func _path_to(from_pos: Vector3, zone: String, spot: Vector3) -> Array:
	var entry_node: String = _zone_entry[zone]
	var from_id: int = _astar.get_closest_point(from_pos)
	var to_id: int = _ids[entry_node]
	var pts := _astar.get_point_path(from_id, to_id)
	var out: Array = []
	for p in pts:
		out.append(p)
	if out.is_empty() or (out[out.size() - 1] as Vector3).distance_to(spot) > 0.6:
		out.append(spot)
	return out

func _update_schedules() -> void:
	var hour := game_minutes / 60.0
	for n in _all_npcs:
		var npc := n as NPC
		if npc.is_staff or npc.talking:
			continue
		var zone := _segment_for(npc.data, hour)
		if zone != npc.target_zone:
			npc.target_zone = zone
			var idx := _all_npcs.find(npc)
			var spot: Vector3 = _pick_spot(npc, zone, idx)
			npc.spot = spot
			npc.set_path(_path_to(npc.global_position, zone, spot))
			if _test_mode:
				print("[TEST_ZONE] ", npc.data["name"], " -> ", zone, " @ ", _clock_str())
		elif npc.path_idx >= npc.path.size() and npc.global_position.distance_to(npc.spot) > 1.2:
			# arrived near entry but not at spot (or got nudged) — walk to spot
			npc.set_path([npc.spot])

func _process(delta: float) -> void:
	if not paused and not _capture_mode:
		game_minutes += delta * speed_mult
		energy = maxf(0.0, energy - delta * speed_mult * (3.2 / 60.0))
		if game_minutes >= 1440.0:
			game_minutes = 360.0
			day += 1
			energy = 85.0
			for n in _mains:
				(n as NPC).compliments_today = 0
			_show_toast("Day %d — a new morning at Northbridge. (Full sleep/save arrives in Phase 2.)" % day)
			if _test_mode:
				_finish_test()
				return
	_update_sun()
	_update_schedules()
	_update_interaction_prompt()
	_player.speed_factor = 0.55 if energy <= 5.0 else 1.0
	if _chat_cooldown > 0.0:
		_chat_cooldown -= delta
	else:
		_chat_cooldown = _rng.randf_range(6.0, 11.0)
		_npc_small_talk()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.text = ""
	_ui_timer -= delta
	if _ui_timer <= 0.0:
		_ui_timer = 0.5
		_refresh_hud()
	if _test_mode:
		for n in _all_npcs:
			var npc := n as NPC
			if not npc.is_staff and npc.path_idx >= npc.path.size() and npc.target_zone == _segment_for(npc.data, game_minutes / 60.0):
				if not _test_arrivals.has(npc.data["name"]):
					_test_arrivals[npc.data["name"]] = npc.target_zone
					print("[TEST_ARRIVE] ", npc.data["name"], " arrived @ ", npc.target_zone)
		if Time.get_ticks_msec() - _test_start_ms > 300000:
			print("[TEST] TIMEOUT — day=", day, " minutes=", int(game_minutes))
			get_tree().quit(2)

func _finish_test() -> void:
	var arrived := _test_arrivals.size()
	print("[TEST_PASS] Day rolled over to Day ", day, ". Mains=", _mains.size(), " BG=", _bgs.size(), " NPCs that physically arrived at scheduled zones during test: ", arrived)
	for n in _mains:
		print("[TEST_MAIN] ", (n as NPC).data["name"], " zone=", (n as NPC).target_zone)
	get_tree().quit(0)

func _clock_str() -> String:
	var h := int(game_minutes) / 60
	var m := int(game_minutes) % 60
	return "%02d:%02d" % [h, m]

func _update_sun() -> void:
	var hour := game_minutes / 60.0
	var day_frac := clampf((hour - 6.0) / 12.0, 0.0, 1.0)
	var elev := sin(day_frac * PI) # 0..1..0
	var sun_ang := lerpf(-0.15, -PI + 0.15, day_frac)
	_sun.rotation = Vector3(-elev * 1.1 - 0.05, sun_ang * 0.4, 0)
	var is_day := hour > 6.2 and hour < 18.8
	_sun.light_energy = clampf(elev * 1.5, 0.03, 1.25) if is_day else 0.05
	_sun.light_color = Color(1.0, lerpf(0.75, 0.98, elev), lerpf(0.55, 0.92, elev))
	_env.ambient_light_energy = lerpf(0.15, 0.52, clampf(elev + 0.25, 0.0, 1.0))
	_sky_mat.sky_top_color = Color(0.10, 0.16, 0.35).lerp(Color(0.25, 0.5, 0.86), clampf(elev * 1.6, 0.0, 1.0))
	_sky_mat.sky_horizon_color = Color(0.25, 0.25, 0.35).lerp(Color(0.78, 0.86, 0.95), clampf(elev * 1.6 + 0.15, 0.0, 1.0))
	var lamp_on := 1.3 if (hour < 6.6 or hour > 18.2) else 0.0
	for l in _lamps:
		(l as OmniLight3D).light_energy = lamp_on

func _npc_small_talk() -> void:
	# two NPCs in the same area chat; show a bubble on one of them
	var candidates: Array = []
	for n in _all_npcs:
		var npc := n as NPC
		if not npc.is_staff and not npc.talking and not npc.is_moving():
			candidates.append(npc)
	if candidates.size() < 2:
		return
	var a: NPC = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var best: NPC = null
	var best_d := 8.0
	for n in candidates:
		var o := n as NPC
		if o != a:
			var d := a.global_position.distance_to(o.global_position)
			if d < best_d:
				best_d = d
				best = o
	if best == null:
		return
	var lines := CharData.npc_chat_pairs()
	var line: String = lines[_rng.randi_range(0, lines.size() - 1)]
	a.show_bubble(line.replace("{other}", str(best.data["name"])), 3.6)

# ---------------- interactions ----------------

func _update_interaction_prompt() -> void:
	_interact_kind = ""
	_interact_npc = null
	if _current_npc != null:
		_prompt_label.text = ""
		return
	var pp := _player.global_position
	if pp.distance_to(_world["counter_front"]) < 2.8:
		_interact_kind = "counter"
		_prompt_label.text = "[E] Food Court counter — Thali ₹60 (lunch 13:00–14:00)"
		return
	if pp.distance_to(_world["chai_front"]) < 2.6:
		_interact_kind = "chai"
		_prompt_label.text = "[E] Chai Point — Masala chai ₹15"
		return
	var best_d := 2.6
	for n in _all_npcs:
		var npc := n as NPC
		var d := pp.distance_to(npc.global_position)
		if d < best_d:
			best_d = d
			_interact_npc = npc
	if _interact_npc != null:
		_interact_kind = "npc"
		_prompt_label.text = "[E] Talk to %s" % _interact_npc.data["name"]
	else:
		_prompt_label.text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _current_npc == null and not _capture_mode:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_ESCAPE:
			if _current_npc != null:
				_close_dialogue()
			elif _class_panel.visible:
				_class_panel.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif k == KEY_E:
			if _current_npc != null:
				_close_dialogue()
			elif _interact_kind == "counter":
				_buy_counter()
			elif _interact_kind == "chai":
				_buy_chai()
			elif _interact_kind == "npc" and _interact_npc != null:
				_open_dialogue(_interact_npc)
		elif k == KEY_C and not _capture_mode:
			_class_panel.visible = not _class_panel.visible

func _buy_counter() -> void:
	var hour := game_minutes / 60.0
	if hour >= 13.0 and hour < 14.0:
		if money >= 60:
			money -= 60
			energy = minf(100.0, energy + 35.0)
			_show_toast("Hot thali served! −₹60, energy restored. Mr. Khan adds extra papad, on the house.")
		else:
			_show_toast("Not enough money for the thali (₹60). You have ₹%d." % money)
	else:
		_show_toast("Counter is closed — lunch service is 13:00–14:00. The chai stall by the quad is open, though.")
	_refresh_hud()

func _buy_chai() -> void:
	var hour := game_minutes / 60.0
	if hour >= 7.0 and hour < 21.0:
		if money >= 15:
			money -= 15
			energy = minf(100.0, energy + 8.0)
			_show_toast("Kadak masala chai! −₹15, +energy. Ramesh winks: 'Exam season fuel, ready.'")
		else:
			_show_toast("₹15 needed for chai. Ramesh would give credit, but the stall ledger says no.")
	else:
		_show_toast("Chai Point is shut for the night (open 07:00–21:00).")
	_refresh_hud()

# ---------------- dialogue ----------------

func _tier_name(f: int) -> String:
	if f < 20:
		return "New face"
	elif f < 40:
		return "Acquaintance"
	elif f < 60:
		return "Friend"
	elif f < 80:
		return "Close Friend"
	return "Best Friend"

func _open_dialogue(npc: NPC) -> void:
	_current_npc = npc
	npc.talking = true
	_player.controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_dialog_panel.visible = true
	_dlg_title.text = "%s — %s, Year %s" % [npc.data["name"], npc.data.get("major", ""), str(npc.data.get("year", ""))]
	for b in _dlg_btns.get_children():
		(b as Button).visible = npc.is_main
	if npc.is_main:
		_dlg_text.text = "%s\n\n%s" % [npc.data.get("personality", ""), _pick_chat_line(npc)]
	else:
		_dlg_text.text = str(npc.data.get("greeting", "Hello!"))
	_update_dlg_friend()

func _pick_chat_line(npc: NPC) -> String:
	var lines: Array = npc.data.get("chat", ["Hello!"])
	var line: String = lines[npc.chats % lines.size()]
	if npc.chats >= 2:
		line = "Good to see you again. " + line
	return line

func _update_dlg_friend() -> void:
	if _current_npc != null and _current_npc.is_main:
		_dlg_friend.text = "Friendship: %d / 100 — %s   •   Chats so far: %d" % [_current_npc.friendship, _tier_name(_current_npc.friendship), _current_npc.chats]
	else:
		_dlg_friend.text = ""

func _dlg_choice(kind: String) -> void:
	var npc := _current_npc
	if npc == null or not npc.is_main:
		return
	if kind == "chat":
		npc.chats += 1
		npc.friendship = mini(100, npc.friendship + 2)
		_dlg_text.text = _pick_chat_line(npc)
	elif kind == "compliment":
		if npc.compliments_today < 2:
			npc.compliments_today += 1
			npc.chats += 1
			npc.friendship = mini(100, npc.friendship + 4)
			_dlg_text.text = str(npc.data.get("compliment", "Thank you!"))
		else:
			_dlg_text.text = "You've praised me enough for one day — I'll start suspecting you're buttering me up for notes. (Compliment limit per day reached.)"
	elif kind == "ask":
		npc.chats += 1
		var extra := ""
		if not npc.learned_hobby:
			npc.learned_hobby = true
			npc.friendship = mini(100, npc.friendship + 2)
			extra = "\n\n%s" % str(npc.data.get("hobby_line", ""))
		if npc.friendship >= 55 and not npc.learned_secret:
			npc.learned_secret = true
			npc.friendship = mini(100, npc.friendship + 3)
			extra += "\n\n[Something personal] %s" % str(npc.data.get("secret_line", ""))
			_dlg_text.text = "I'm a %s student (Year %s). My thing is %s. Friends: %s. Rival: %s.%s" % [npc.data.get("major", ""), str(npc.data.get("year", "")), npc.data.get("hobby", ""), npc.data.get("friends", ""), npc.data.get("rival", ""), extra]
		else:
			_dlg_text.text = "I'm a %s student (Year %s). My thing is %s. Friends: %s. Rival: %s.%s" % [npc.data.get("major", ""), str(npc.data.get("year", "")), npc.data.get("hobby", ""), npc.data.get("friends", ""), npc.data.get("rival", ""), extra]
	_update_dlg_friend()

func _close_dialogue() -> void:
	if _current_npc != null:
		_current_npc.talking = false
		_current_npc = null
	_dialog_panel.visible = false
	_player.controls_locked = false

# ---------------- UI ----------------

func _mk_label(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# top-left status panel
	var panel := PanelContainer.new()
	panel.position = Vector2(14, 12)
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)
	_hud_day = _mk_label("Day 1 • Week 1 of 12", 20, Color(1.0, 0.95, 0.75))
	_hud_clock = _mk_label("07:30", 30)
	_hud_period = _mk_label("Morning", 18, Color(0.85, 0.92, 1.0))
	_hud_money = _mk_label("₹ 500", 20, Color(0.75, 1.0, 0.75))
	vb.add_child(_hud_day)
	vb.add_child(_hud_clock)
	vb.add_child(_hud_period)
	vb.add_child(_hud_money)
	var erow := HBoxContainer.new()
	erow.add_child(_mk_label("Energy", 16))
	_hud_energy = ProgressBar.new()
	_hud_energy.min_value = 0
	_hud_energy.max_value = 100
	_hud_energy.value = energy
	_hud_energy.custom_minimum_size = Vector2(150, 16)
	erow.add_child(_hud_energy)
	vb.add_child(erow)
	# top-right buttons
	var bb := HBoxContainer.new()
	bb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bb.position = Vector2(-330, 12)
	bb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	layer.add_child(bb)
	var b_class := Button.new()
	b_class.text = "👥 Classmates (C)"
	b_class.pressed.connect(func() -> void: _class_panel.visible = not _class_panel.visible)
	bb.add_child(b_class)
	var b_pause := Button.new()
	b_pause.text = "⏸"
	b_pause.pressed.connect(func() -> void: paused = not paused; _show_toast("Paused" if paused else "Resumed"))
	bb.add_child(b_pause)
	var b_1x := Button.new()
	b_1x.text = "1x"
	b_1x.pressed.connect(func() -> void: speed_mult = 1.0; paused = false)
	bb.add_child(b_1x)
	var b_3x := Button.new()
	b_3x.text = "3x"
	b_3x.pressed.connect(func() -> void: speed_mult = 3.0; paused = false)
	bb.add_child(b_3x)
	# help / prompt / toast
	var help := _mk_label("WASD move • Mouse look (click to capture) • Shift run • E talk/buy • C classmates • Esc release mouse", 15, Color(0.9, 0.9, 0.9))
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(14, -34)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(help)
	_prompt_label = _mk_label("", 22, Color(1.0, 0.95, 0.6))
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = Vector2(-260, -90)
	_prompt_label.custom_minimum_size = Vector2(520, 30)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_prompt_label)
	_toast_label = _mk_label("", 19, Color(1.0, 1.0, 1.0))
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_label.position = Vector2(-420, -140)
	_toast_label.custom_minimum_size = Vector2(840, 60)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_toast_label)
	# classmates panel
	_class_panel = PanelContainer.new()
	_class_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_class_panel.position = Vector2(-360, -260)
	_class_panel.custom_minimum_size = Vector2(345, 520)
	_class_panel.visible = false
	layer.add_child(_class_panel)
	var scroll := ScrollContainer.new()
	_class_panel.add_child(scroll)
	_class_box = VBoxContainer.new()
	_class_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_class_box)
	_class_box.add_child(_mk_label("THE TEN — MAIN CHARACTERS", 17, Color(1.0, 0.95, 0.7)))
	for n in _mains:
		var l := _mk_label("", 15)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(320, 0)
		_class_box.add_child(l)
	# dialogue panel
	_dialog_panel = PanelContainer.new()
	_dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialog_panel.position = Vector2(-340, -300)
	_dialog_panel.custom_minimum_size = Vector2(680, 285)
	_dialog_panel.visible = false
	layer.add_child(_dialog_panel)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	_dialog_panel.add_child(dv)
	_dlg_title = _mk_label("", 22, Color(1.0, 0.95, 0.75))
	dv.add_child(_dlg_title)
	_dlg_text = RichTextLabel.new()
	_dlg_text.fit_content = true
	_dlg_text.custom_minimum_size = Vector2(640, 120)
	_dlg_text.add_theme_font_size_override("normal_font_size", 17)
	dv.add_child(_dlg_text)
	_dlg_friend = _mk_label("", 15, Color(0.8, 1.0, 0.85))
	dv.add_child(_dlg_friend)
	_dlg_btns = HBoxContainer.new()
	_dlg_btns.add_theme_constant_override("separation", 8)
	dv.add_child(_dlg_btns)
	var b_chat := Button.new()
	b_chat.text = "💬 Chat (+2)"
	b_chat.pressed.connect(func() -> void: _dlg_choice("chat"))
	_dlg_btns.add_child(b_chat)
	var b_comp := Button.new()
	b_comp.text = "⭐ Compliment (+4)"
	b_comp.pressed.connect(func() -> void: _dlg_choice("compliment"))
	_dlg_btns.add_child(b_comp)
	var b_ask := Button.new()
	b_ask.text = "🎓 Ask about major & hobby"
	b_ask.pressed.connect(func() -> void: _dlg_choice("ask"))
	_dlg_btns.add_child(b_ask)
	var b_close := Button.new()
	b_close.text = "Close (E)"
	b_close.pressed.connect(func() -> void: _close_dialogue())
	_dlg_btns.add_child(b_close)
	_refresh_hud()
	_refresh_classmates()

func _show_toast(text: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = text
	_toast_timer = 5.0

func _refresh_hud() -> void:
	if _hud_clock == null:
		return
	_hud_day.text = "Day %d • Week %d of 12" % [day, mini(12, (day - 1) / 7 + 1)]
	_hud_clock.text = _clock_str()
	_hud_period.text = _period_name(game_minutes / 60.0)
	_hud_money.text = "₹ %d" % money
	_hud_energy.value = energy
	_refresh_classmates()

func _refresh_classmates() -> void:
	if _class_box == null:
		return
	var i := 0
	for child in _class_box.get_children():
		if i == 0:
			i += 1
			continue
		var npc := _mains[i - 1] as NPC
		(child as Label).text = "%s — %s Yr%s\n♥ %d (%s) • at %s" % [npc.data["name"], npc.data["major"], str(npc.data["year"]), npc.friendship, _tier_name(npc.friendship), ZONE_NAMES.get(npc.target_zone, npc.target_zone)]
		i += 1

# ---------------- screenshots (capture mode) ----------------

func _run_captures() -> void:
	# A free camera tours fixed viewpoints; saves PNGs into res://preview/
	var cam := Camera3D.new()
	cam.fov = 60.0
	add_child(cam)
	cam.current = true
	_player.visible = true
	await get_tree().create_timer(1.2).timeout
	_shot(cam, Vector3(30, 24, 92), Vector3(0, 3, -30))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot1_campus_wide.png")
	# character close-up: Anirudh posed on the quad lawn (deterministic —
	# free-roaming NPCs rotate away while walking to their timetable zone)
	var ani: NPC = _mains[0]
	ani.stationary = true
	ani.set_path([])
	ani.global_position = Vector3(14, 0, 22)
	ani.rotation.y = 0.6
	var ap := ani.global_position
	_shot(cam, ap + Vector3(1.45, 1.52, 1.95), ap + Vector3(0, 1.28, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot2_character_closeup.png")
	# dialogue: teleport player next to Jatin and open the panel
	var jatin: NPC = _mains[4]
	_player.global_position = jatin.global_position + Vector3(1.4, 0.1, 1.4)
	_open_dialogue(jatin)
	var jp := jatin.global_position
	_shot(cam, jp + Vector3(2.0, 1.7, 2.6), jp + Vector3(0, 1.2, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot3_dialogue.png")
	_close_dialogue()
	# food court interior
	_shot(cam, Vector3(58, 2.3, 25), Vector3(77, 1.4, 18))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot4_foodcourt.png")
	# library facade + quad
	_shot(cam, Vector3(28, 7, -18), Vector3(58, 5, -56))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot5_library_quad.png")
	# street level on the main avenue (GTA-style street scene)
	_shot(cam, Vector3(3.4, 1.7, 80), Vector3(-1.5, 1.9, 40))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot6_avenue.png")
	# shops row
	_shot(cam, Vector3(12.0, 1.9, 90), Vector3(25, 1.2, 84))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot7_shops.png")
	# gardens + pond
	_shot(cam, Vector3(92, 3.4, 58), Vector3(117, 0.6, 33))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot8_garden.png")
	# mid-walk-cycle: send a background student across the frame
	var walker: NPC = _bgs[2]
	walker.stationary = true
	walker.set_path([])
	walker.global_position = Vector3(2.5, 0, 34)
	walker.rotation.y = -PI / 2.0 # side-on to camera
	await get_tree().create_timer(0.3).timeout
	# freeze the walk cycle mid-stride (legs split) as animation proof
	var wanim: AnimationPlayer = walker._anim
	if wanim != null and wanim.has_animation("walk"):
		wanim.play("walk")
		wanim.seek(0.05, true)
		wanim.pause()
	var wp := walker.global_position
	_shot(cam, wp + Vector3(0.3, 1.32, 3.6), wp + Vector3(0, 0.95, 0))
	await get_tree().create_timer(0.5).timeout
	await _shot_file("shot9_walk_cycle.png")
	# seated on a quad bench
	var sitter: NPC = _bgs[3]
	var seat0: Dictionary = (_world["seats"]["quad"] as Array)[0]
	sitter.target_zone = _segment_for(sitter.data, game_minutes / 60.0)
	sitter.global_position = seat0["pos"]
	sitter.spot = seat0["pos"]
	sitter.set_path([])
	sitter.seated = true
	sitter.seat_yaw = seat0["yaw"]
	sitter.rotation.y = seat0["yaw"]
	await get_tree().create_timer(0.6).timeout
	var sp2 := sitter.global_position
	_shot(cam, sp2 + Vector3(1.8, 1.35, 2.2), sp2 + Vector3(0, 0.85, 0))
	await get_tree().create_timer(0.5).timeout
	await _shot_file("shot10_seated.png")
	print("[CAPTURE] done")
	get_tree().quit(0)

func _shot(cam: Camera3D, pos: Vector3, look: Vector3) -> void:
	cam.global_position = pos
	cam.look_at(look, Vector3.UP)

func _shot_file(fname: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://preview/" + fname))
	print("[CAPTURE] saved ", fname)
