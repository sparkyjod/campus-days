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
	"admin": "Admin Block", "shops": "Campus Shops", "garden": "Gardens & Amphitheatre",
	"city": "City District — MG Road"
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
var _rain_particles: GPUParticles3D = null # Phase 4 rain emitter (follows player)
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

# ---------------- Phase 2 state ----------------
var gpa: float = 7.5
var health: float = 80.0
var stress: float = 30.0
var social: float = 50.0
var skills: Dictionary = {"Study": 1, "Sport": 1, "Music/Art": 1, "Tech": 1, "Communication": 1}
var _skill_xp: Dictionary = {"Study": 0, "Sport": 0, "Music/Art": 0, "Tech": 0, "Communication": 0}
var player_name: String = "New Student"
var player_major: String = "Computer Science"
var _appearance_idx: int = 0
var _teachers: Array = []
var _assignments: Array = []
var _attended_keys: Array = [] # "%d_%s" % [day, period] — persisted
var _jobs_today: Dictionary = {}
var _jobs_total: Dictionary = {}
var _earned_total: int = 0
var _messages: Array = [] # {"day": int, "from": String, "text": String}
var _buzz: Array = [] # {"day": int, "text": String}
var _quests: Array = []
var _quest_index: int = 0
# ---------------- Phase 3 state ----------------
var _p3_arc_progress: Dictionary = {} # name -> steps completed (mains)
var _p3_arc_done: Dictionary = {} # name -> bool
var _p3_teacher_progress: Dictionary = {} # teacher name -> steps completed
var _p3_teacher_done: Dictionary = {}
var _p3_story_idx: int = 0 # index into Phase3Data.storyline()
var _p3_favours: Array = [] # active: {giver,title,desc,action,target,day_offered,money,friend,social}
var _p3_favours_done: int = 0
var _p3_invitations: Array = [] # {with,kind,zone,day_due,from,kept}
var _p3_social_posts: Array = [] # {day,author,text} newest appended last
var _p3_gossip_log: Array = [] # {day,text,delta}
var _p3_events_attended: Array = [] # "%d_%s" day_title keys
var _fest_practice: int = 0
var _p3_holi_done: bool = false
var _p3_fest_result: String = ""
var _romance_partner: String = ""
var _teacher_letters: Array = []
var _city_trip_day: int = -1
# ---------------- Phase 4 state ----------------
var _p4_weather: String = "clear"
var _p4_clubs_joined: Array = [] # club ids, max 2 (master prompt Section 8)
var _p4_club_attended: Array = [] # "%d_%s" day_club keys
var _p4_club_sessions: int = 0
var _p4_sport_sessions: int = 0
var _p4_sports_week_sessions: int = 0
var _p4_sports_week_award: bool = false
var _p4_exams_sat: Dictionary = {} # "%d" day -> marks
var _p4_midsem_total: int = 0
var _p4_midsem_count: int = 0
var _p4_final_total: int = 0
var _p4_final_count: int = 0
var _p4_midsem_result: String = ""
var _p4_final_results: String = ""
var _p4_week: Dictionary = {"lectures": 0, "study": 0, "clubs": 0, "sports": 0, "jobs": 0, "earned": 0, "exams": 0}
var _p4_sem: Dictionary = {"lectures": 0, "study": 0, "clubs": 0, "sports": 0, "jobs": 0, "earned": 0, "exams": 0}
var _p4_week_summaries: Array = [] # strings, one per Monday
var _p4_city_visits: int = 0
var _p4_outfit: int = -1 # index into Phase4Data.outfits(), -1 = creation preset
var _p4_hairstyle: int = -1 # hair_style index, -1 = creation preset
var _p4_outfits_owned: Array = [] # outfit indices bought (re-wear free)
var _p4_hairstyles_owned: Array = [] # hair_style indices bought (re-wear free)
var _p4_decor_owned: Array = [] # décor ids owned
var _p4_decor_placed: Array = [] # décor ids currently placed in the room
var _p4_room_guest: String = ""
var _p4_room_guest_day: int = -1
var _p4_room_invite_done: bool = false
var _p4_ext_progress: Dictionary = {} # name -> steps completed (continued arcs)
var _p4_ext_done: Dictionary = {} # name -> bool
var _p4_prompt_club: String = ""
var _p4_decor_node: Node3D = null
var _quest_marker: MeshInstance3D = null
var _mission_timer: float = 0.0
var _npc_msg_timer: float = 45.0
var _qa_teacher: NPC = null
var _qa_answer: int = 0
var _qa_period: String = ""

const ZONE_CENTERS := {
	"dorm": Vector3(-66, 0, 18), "lecture": Vector3(-58, 0, -58),
	"lectureb": Vector3(-104, 0, -72), "lecturec": Vector3(104, 0, -72),
	"library": Vector3(58, 0, -58), "foodcourt": Vector3(66, 0, 18),
	"union": Vector3(58, 0, 66), "sports": Vector3(-50, 0, 60),
	"gate": Vector3(0, 0, 96), "admin": Vector3(-104, 0, -34),
	"shops": Vector3(25, 0, 82), "garden": Vector3(105, 0, 55),
	"quad": Vector3(0, 0, -5), "city": Vector3(0, 0, 140)
}

var _test_mode: bool = false
var _capture_mode: bool = false
var _semester_mode: bool = false
var _test_start_ms: int = 0
var _test_arrivals: Dictionary = {}
var _rng := RandomNumberGenerator.new()

# UI refs
var _hud_day: Label
var _hud_clock: Label
var _hud_period: Label
var _hud_money: Label
var _hud_energy: ProgressBar
var _hud_gpa: Label
var _hud_health: ProgressBar
var _hud_stress: ProgressBar
var _hud_social: Label
var _hud_objective: Label
var _minimap: Minimap
var _phone_panel: PanelContainer
var _phone_text: RichTextLabel
var _phone_tab: String = "Messages"
var _phone_job_row: HBoxContainer
var _phone_city_row: HBoxContainer
var _phone_action_row: HBoxContainer
var _shop_panel: PanelContainer
var _shop_title: Label
var _shop_list: VBoxContainer
var _dlg_btns3: HBoxContainer
var _dlg_btns4: HBoxContainer
var _dlg_invite_btn: Button
var _dlg_romance_btn: Button
var _dlg_letter_btn: Button
var _save_panel: PanelContainer
var _create_panel: PanelContainer
var _create_name: LineEdit
var _create_major: OptionButton
var _create_appear: OptionButton
var _mission_panel: PanelContainer
var _mission_label: Label
var _qa_panel: PanelContainer
var _qa_question: Label
var _qa_btns: HBoxContainer
var _dlg_btns2: HBoxContainer
var _dlg_office_btn: Button
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
	_semester_mode = args.has("--campus-semester")
	if _semester_mode:
		_test_mode = true # same guards as the one-day test (no autosave, no ambient chatter)
	_build_environment()
	_world = World.build(self)
	_astar = _world["astar"]
	_ids = _world["ids"]
	_zone_entry = _world["zone_entry"]
	_zone_spots = _world["zone_spots"]
	_lamps = _world["lamps"]
	_spawn_player()
	_spawn_people()
	_spawn_teachers()
	_build_ui()
	_init_phase2()
	_p4_weather = Phase4Data.weather_for_day(day)
	_p4_refresh_dorm_decor()
	if _semester_mode:
		# Standalone 12-week harness: no one-day sim first, straight to
		# the accelerated semester (see _run_semester_harness).
		var sem_ok := _run_semester_harness()
		get_tree().quit(0 if sem_ok else 1)
		return
	if _test_mode:
		Engine.time_scale = 6.0
		speed_mult = 6.0
		for n in _all_npcs:
			(n as NPC).speed *= 6.0
		_test_start_ms = Time.get_ticks_msec()
		print("[TEST] Campus Days headless test started. Mains: ", _mains.size(), " BG: ", _bgs.size(), " Staff: ", _staff.size())
	elif _capture_mode:
		game_minutes = 780.0 # FIX 2026-11-03 (D1/D2): capture at 13:00 lunch, not 10:30 lectures
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
	_env.background_energy_multiplier = 0.95 # FIX 2026-11-03 (D1/D2): was blowing out white paving/plaza at midday
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
		# Phase 4: three background students spend club period + evenings
		# in the city district, so MG Road has foot traffic via the gate.
		if i % 8 == 7:
			d["club"] = "city"
			d["evening"] = "city"
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
			"line": "Welcome to the campus shops lane! Xerox at ₹1 a page, juice fresh, books at student discount. Exam week, this whole lane stays open till midnight."},
		{"name": "Meena (Style Studio)", "pos": _world["city_shopkeeper_pos"], "zone": "city", "female": true,
			"line": "Welcome to Style Studio, MG Road! Fest kurtas, streetwear, formals — student prices, no bargaining needed. The city bus drops you right here."}
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

func _spawn_teachers() -> void:
	# Phase 2 (Section 19.1): named faculty as WORKING NPCs on the same
	# schedule/pathfinding systems as students — never statues. They run
	# lectures in their blocks, hold office hours (pm/club in office zone),
	# eat at lunch, and leave via the gate in the evening.
	for td in Phase2Data.teachers():
		var d := {
			"name": td["name"], "major": td["subject"], "year": 0,
			"height": td["height"], "build": td["build"], "skin": td["skin"],
			"hair_style": td["hair_style"], "hair_color": td["hair_color"],
			"shirt": td["shirt"], "pants": td["pants"], "female": td["female"],
			"backpack": false,
			"morning": td["morning"], "am1": td["am1"], "am2": td["am2"],
			"pm": td["pm"], "club": td["club"], "evening": td["evening"], "night": td["night"],
			"greeting": td["greeting"], "office": td["office"], "lecture_zone": td["lecture_zone"]
		}
		var zone: String = _segment_for(d, 7.5)
		var npc := _npc_common(d, false, zone, _all_npcs.size() + 1)
		npc.is_teacher = true
		npc.subject = str(td["subject"])
		npc.friendship = 25
		npc._label.modulate = Color(1.0, 0.85, 0.35) # gold labels mark faculty
		_teachers.append(npc)

func _init_phase2() -> void:
	# Assignments from templates; quest chain; welcome messages.
	_assignments = []
	for t in Phase2Data.assignment_templates():
		_assignments.append({"title": t["title"], "subject": t["subject"], "due_day": t["due_day"], "desc": t["desc"], "progress": 0, "submitted": false})
	_quests = [
		{"id": "meet_teacher", "title": "Orientation: talk to a teacher", "desc": "Find any professor on campus and introduce yourself.", "target_zone": "teacher", "done": false},
		{"id": "attend_lecture", "title": "Attend a lecture", "desc": "Go to a lecture block during lecture hours and attend.", "target_zone": "lecture", "done": false},
		{"id": "study_session", "title": "Library study session", "desc": "Study in the Central Library (bring a friend for bonus progress).", "target_zone": "library", "done": false},
		{"id": "job_shift", "title": "First part-time shift", "desc": "Work any part-time job: library, canteen, tutoring or freelance.", "target_zone": "library", "done": false},
		{"id": "sleep_save", "title": "Sleep and save", "desc": "Sleep in your dorm room. The game autosaves at every sleep.", "target_zone": "dorm", "done": false}
	]
	_quest_index = 0
	_apply_major(player_major) # sets quest lecture target + assignment subjects
	_add_message("Northbridge Admin", "Welcome to Northbridge University! Orientation is today. Your lecture block and professor are on the phone calendar (Tab).")
	_add_message("Prof. Raghavan", "This is a reminder to all first-years: lectures start on the minute. See you in class.")
	_buzz.append({"day": 1, "text": "Northbridge Buzz is live! Post updates appear here as campus life happens."})
	if _test_mode or _capture_mode:
		return # defaults only; no creation panel in automated runs
	_player.controls_locked = true
	_create_panel.visible = true
	_show_mission("Welcome to Northbridge!", "Create your student: name, major and look — then start your semester.")

func _apply_major(major: String) -> void:
	player_major = major
	var info := Phase2Data.major_info(major)
	if _quests.size() > 1:
		_quests[1]["target_zone"] = str(info["block"])
	for a in _assignments:
		a["subject"] = str(info["subjects"][0])

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
		# Phase 4: a room guest stays on their visit until it completes
		# or the day ends — the timetable must not yank them away mid-visit.
		if str(npc.data["name"]) == _p4_room_guest:
			continue
		var zone := _segment_for(npc.data, hour)
		# Phase 4 weather: rain moves outdoor crowds indoors.
		if _p4_weather == "rain":
			zone = str(Phase4Data.rain_redirect().get(zone, zone))
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
	_p4_apply_tiers()

func _p4_tier_for(dist: float) -> int:
	if dist < 30.0:
		return 0
	if dist < 70.0:
		return 1
	return 2

func _p4_apply_tiers(force_real: bool = false) -> void:
	# Phase 4 (Section 15.2): near = full sim, mid = half movement rate,
	# far = schedule-only stepping. Test/capture mode forces tier 0 so
	# arrival evidence and staged poses are never disturbed, unless
	# force_real is passed (the Phase 4 tier test does exactly that).
	var pp := _player.global_position
	for n in _all_npcs:
		var npc := n as NPC
		if npc.is_staff:
			npc.sim_tier = 0
			continue
		var old := npc.sim_tier
		if (_test_mode or _capture_mode) and not force_real:
			npc.sim_tier = 0
		else:
			npc.sim_tier = _p4_tier_for(npc.global_position.distance_to(pp))
		# Far -> near/mid transition: the straight-line stepping ignored
		# the graph path, so re-path from the current position.
		if old == 2 and npc.sim_tier < 2:
			npc.set_path(_path_to(npc.global_position, npc.target_zone, npc.spot))

func _process(delta: float) -> void:
	if not paused and not _capture_mode:
		game_minutes += delta * speed_mult
		energy = maxf(0.0, energy - delta * speed_mult * (3.2 / 60.0))
		if game_minutes >= 1440.0:
			_advance_day()
			if _test_mode:
				_finish_test()
				return
	_update_sun()
	_update_schedules()
	_p4_check_room_guest()
	_update_interaction_prompt()
	# Phase 2 ambient systems (normal play only)
	if _mission_timer > 0.0:
		_mission_timer -= delta
		if _mission_timer <= 0.0 and _mission_panel != null:
			_mission_panel.visible = false
	if not _test_mode and not _capture_mode and not paused:
		_npc_msg_timer -= delta
		if _npc_msg_timer <= 0.0:
			_npc_msg_timer = _rng.randf_range(75.0, 120.0)
			_npc_initiated()
	if _quest_marker != null and _quest_index < _quests.size():
		var qp := _quest_target_pos()
		_quest_marker.global_position = Vector3(qp.x, 3.2 + sin(Time.get_ticks_msec() / 500.0) * 0.4, qp.z)
	_player.speed_factor = 0.55 if energy <= 5.0 else 1.0
	if _chat_cooldown > 0.0:
		_chat_cooldown -= delta
	elif not _capture_mode: # capture tour stages poses; small talk would override them
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
	var p2_ok := _run_phase2_tests()
	var p3_ok := _run_phase3_tests()
	var p4_ok := _run_phase4_tests()
	var sem_ok := false
	if p2_ok and p3_ok and p4_ok:
		sem_ok = _run_semester_harness()
	else:
		print("[TEST_P4_SEM] skipped: earlier phase tests failed (p2=", p2_ok, " p3=", p3_ok, " p4=", p4_ok, ")")
	get_tree().quit(0 if (p2_ok and p3_ok and p4_ok and sem_ok) else 1)

func _run_phase2_tests() -> bool:
	# Phase 2 headless evidence: teachers present, dialogue sampling
	# (3 different characters, same topic — lines must be distinct),
	# stats mutation, and a save-delta round-trip.
	var ok := true
	print("[TEST_P2] Teachers in world: ", _teachers.size())
	for t in _teachers:
		print("[TEST_P2_TEACHER] ", (t as NPC).data["name"], " subject=", (t as NPC).subject, " zone=", (t as NPC).target_zone)
	if _teachers.size() < 9:
		print("[TEST_P2_FAIL] expected 9 teachers")
		ok = false
	# Dialogue sampling: Anirudh, Zannat, Shadow on "classes".
	var sample_names := ["Anirudh", "Zannat", "Shadow"]
	var sample_lines: Array = []
	for nm in sample_names:
		for n in _mains:
			var npc := n as NPC
			if str(npc.data["name"]) == nm:
				var line := Dialogue.pick_line(npc, "classes", npc.target_zone, 10.0, day)
				sample_lines.append(line)
				print("[TEST_P2_DIALOGUE] ", nm, " classes: ", line)
	if sample_lines.size() == 3 and (sample_lines[0] == sample_lines[1] or sample_lines[1] == sample_lines[2] or sample_lines[0] == sample_lines[2]):
		print("[TEST_P2_FAIL] sampled dialogue lines are interchangeable between characters")
		ok = false
	else:
		print("[TEST_P2_DIALOGUE] distinct across 3 characters: OK")
	# No-repeat check: 5 consecutive classes lines for one character differ.
	var ani: NPC = _mains[0]
	var seen_lines: Array = []
	for i in range(5):
		seen_lines.append(Dialogue.pick_line(ani, "fest", "quad", 12.0, day))
	var dup := false
	for i in range(seen_lines.size()):
		for j in range(i + 1, seen_lines.size()):
			if seen_lines[i] == seen_lines[j]:
				dup = true
	if dup:
		print("[TEST_P2_FAIL] repeated dialogue line within one bank cycle")
		ok = false
	else:
		print("[TEST_P2_DIALOGUE] 5 fest lines for Anirudh, no repeats: OK")
	# Stats mutation + save round-trip (slot 3, test-only).
	var gpa_before := gpa
	var money_before := money
	gpa = minf(10.0, gpa + 0.06)
	money += 150
	_jobs_total["library"] = int(_jobs_total.get("library", 0)) + 1
	var saved := SaveSystem.save(3, _collect_state())
	gpa = 0.0
	money = 0
	var loaded := SaveSystem.load_slot(3)
	if not saved or loaded.is_empty():
		print("[TEST_P2_FAIL] save/load round-trip failed")
		ok = false
	else:
		_apply_state(loaded)
		print("[TEST_P2_SAVE] round-trip: gpa=", gpa, " money=", money, " day=", day, " quest_index=", _quest_index)
		if absf(gpa - (gpa_before + 0.06)) > 0.001 or money != money_before + 150:
			print("[TEST_P2_FAIL] loaded state does not match saved state")
			ok = false
		else:
			print("[TEST_P2_SAVE] delta round-trip: OK")
	print("[TEST_P2] stats: GPA=", gpa, " health=", health, " stress=", stress, " social=", social, " quests=", _quests.size(), " assignments=", _assignments.size(), " messages=", _messages.size())
	print("[TEST_P2] RESULT: ", "PASS" if ok else "FAIL")
	return ok

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
	_sun.light_energy = clampf(elev * 1.5, 0.03, 1.12) if is_day else 0.05
	_sun.light_color = Color(1.0, lerpf(0.75, 0.98, elev), lerpf(0.55, 0.92, elev))
	_env.ambient_light_energy = lerpf(0.15, 0.48, clampf(elev + 0.25, 0.0, 1.0))
	_sky_mat.sky_top_color = Color(0.10, 0.16, 0.35).lerp(Color(0.25, 0.5, 0.86), clampf(elev * 1.6, 0.0, 1.0))
	_sky_mat.sky_horizon_color = Color(0.25, 0.25, 0.35).lerp(Color(0.78, 0.86, 0.95), clampf(elev * 1.6 + 0.15, 0.0, 1.0))
	var lamp_on := 1.3 if (hour < 6.6 or hour > 18.2) else 0.0
	for l in _lamps:
		(l as OmniLight3D).light_energy = lamp_on
	# Phase 4 weather visuals: rain dulls the sun and thickens the haze;
	# cloudy softens it. Day 1 is clear, so captures/tests are unaffected.
	if _p4_weather == "rain":
		_sun.light_energy *= 0.35
		_env.ambient_light_energy *= 0.7
		_env.fog_density = 0.012
		_sky_mat.sky_top_color = _sky_mat.sky_top_color.lerp(Color(0.42, 0.44, 0.47), 0.85)
		_sky_mat.sky_horizon_color = _sky_mat.sky_horizon_color.lerp(Color(0.55, 0.57, 0.60), 0.85)
	elif _p4_weather == "cloudy":
		_sun.light_energy *= 0.8
		_env.fog_density = 0.0035
		_sky_mat.sky_top_color = _sky_mat.sky_top_color.lerp(Color(0.45, 0.48, 0.52), 0.25)
	else:
		_env.fog_density = 0.0022
	# Phase 4 rain particles: one shared emitter that follows the player
	# and only emits while it rains (created lazily on first sun update).
	if _rain_particles == null:
		_rain_particles = GPUParticles3D.new()
		_rain_particles.amount = 1500
		_rain_particles.lifetime = 0.9
		_rain_particles.emitting = false
		_rain_particles.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
		var rmat := ParticleProcessMaterial.new()
		rmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		rmat.emission_box_extents = Vector3(35, 12, 35)
		rmat.direction = Vector3(0, -1, 0)
		rmat.spread = 5.0
		rmat.initial_velocity_min = 16.0
		rmat.initial_velocity_max = 22.0
		rmat.gravity = Vector3(0, -12, 0)
		_rain_particles.process_material = rmat
		var rmesh := BoxMesh.new()
		rmesh.size = Vector3(0.03, 0.6, 0.03)
		var rmm := StandardMaterial3D.new()
		rmm.albedo_color = Color(0.75, 0.82, 0.90, 0.55)
		rmm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmesh.material = rmm
		_rain_particles.draw_pass_1 = rmesh
		add_child(_rain_particles)
	_rain_particles.global_position = _player.global_position + Vector3(0, 14, 0)
	_rain_particles.emitting = (_p4_weather == "rain")

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
		return
	# Phase 4 interactions (checked before the Phase 2 zone activities;
	# club sessions and exams take precedence in their windows).
	var zone := _player_zone()
	var hour := game_minutes / 60.0
	var pp2 := _player.global_position
	if pp2.distance_to(Vector3(7, 0, 120)) < 5.0:
		_interact_kind = "city_bus_back"
		_prompt_label.text = "[E] Bus back to campus — Route 12 (₹20)"
		return
	if zone == "gate" and pp2.distance_to(Vector3(-11, 0, 90)) < 5.0:
		_interact_kind = "city_bus_out"
		_prompt_label.text = "[E] Bus to the City District — Route 12 (₹20)"
		return
	if pp2.distance_to(Vector3(-14, 0, 134)) < 5.0 or pp2.distance_to(Vector3(14, 0, 134)) < 5.0 or pp2.distance_to(_world["shop_staff_pos"]) < 4.0:
		_interact_kind = "shop"
		_prompt_label.text = "[E] Browse shops — outfits, décor, café"
		return
	_p4_prompt_club = ""
	for cid in Phase4Data.clubs().keys():
		var c: Dictionary = Phase4Data.clubs()[cid]
		var wd := (day - 1) % 7
		if zone == str(c["venue"]) and wd == int(c["weekday"]) and hour >= float(c["hour_start"]) and hour < float(c["hour_end"]):
			_p4_prompt_club = str(cid)
			_interact_kind = "club"
			_prompt_label.text = "[E] %s session — %s" % [str(c["title"]), "attend" if _p4_clubs_joined.has(cid) else "join + attend"]
			return
	for kind in ["gym", "swim", "basketball", "football", "running"]:
		var s: Dictionary = Phase4Data.sports()[kind]
		var anchor: Vector3 = s["anchor"]
		# Gym/pool/court sit outside the sports zone radius, so their
		# anchor alone gates them; pitch/track actions need the zone too.
		if pp2.distance_to(anchor) < float(s["radius"]) and (kind == "gym" or kind == "swim" or kind == "basketball" or zone == "sports"):
			_interact_kind = "sport_" + kind
			_prompt_label.text = "[E] %s (Sport XP, health +)" % str(s["title"])
			return
	if (Phase4Data.midsem_days().has(day) or Phase4Data.final_days().has(day)) and (zone == "lecture" or zone == "lectureb" or zone == "lecturec") and hour >= 9.0 and hour < 16.0:
		if not _p4_exams_sat.has("%d" % day):
			_interact_kind = "exam"
			_prompt_label.text = "[E] Sit exam: %s" % str(Phase2Data.major_info(player_major)["subjects"][0])
			return
	# Phase 2 zone activities (only when no NPC is in talk range)
	var period := _lecture_period(hour)
	if zone == "dorm":
		_interact_kind = "sleep"
		_prompt_label.text = "[E] Sleep — end the day (autosaves)"
		return
	if (zone == "lecture" or zone == "lectureb" or zone == "lecturec") and period != "":
		_interact_kind = "lecture"
		_prompt_label.text = "[E] Attend lecture (%s)" % period
		return
	if zone == "library":
		var cur: Variant = _current_assignment()
		if cur != null and int(cur["progress"]) >= 100 and not bool(cur["submitted"]):
			_interact_kind = "submit"
			_prompt_label.text = "[E] Submit assignment: %s" % str(cur["title"])
			return
		var friend := _nearby_main(12.0)
		if friend != null:
			_interact_kind = "groupstudy"
			_prompt_label.text = "[E] Group study with %s (bonus progress)" % str(friend.data["name"])
		else:
			_interact_kind = "study"
			_prompt_label.text = "[E] Study session (library)"
		return
	if zone == "foodcourt" and hour >= 12.0 and hour < 15.0:
		_interact_kind = "job_canteen"
		_prompt_label.text = "[E] Canteen shift — help Mr. Khan (₹120)"
		return
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
			elif _phone_panel != null and _phone_panel.visible:
				_phone_panel.visible = false
			elif _save_panel != null and _save_panel.visible:
				_save_panel.visible = false
			elif _shop_panel != null and _shop_panel.visible:
				_shop_panel.visible = false
			elif _qa_panel != null and _qa_panel.visible:
				_qa_panel.visible = false
			elif _class_panel.visible:
				_class_panel.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif k == KEY_E:
			if _current_npc != null:
				_close_dialogue()
			elif _qa_panel != null and _qa_panel.visible:
				pass # answer with the buttons, not E
			elif _interact_kind == "counter":
				_buy_counter()
			elif _interact_kind == "chai":
				_buy_chai()
			elif _interact_kind == "lecture":
				_attend_lecture()
			elif _interact_kind == "study" or _interact_kind == "groupstudy":
				_do_study(_interact_kind == "groupstudy")
			elif _interact_kind == "submit":
				_do_submit()
			elif _interact_kind == "sleep":
				_do_sleep()
			elif _interact_kind == "job_canteen":
				_do_job("canteen")
			elif _interact_kind == "city_bus_out":
				_p4_bus_to_city()
			elif _interact_kind == "city_bus_back":
				_p4_bus_to_campus()
			elif _interact_kind == "shop":
				_p4_open_shop()
			elif _interact_kind == "club":
				_p4_club_session(_p4_prompt_club)
			elif _interact_kind == "exam":
				_p4_take_exam()
			elif _interact_kind.begins_with("sport_"):
				_p4_sport(_interact_kind.substr(6))
			elif _interact_kind == "npc" and _interact_npc != null:
				_open_dialogue(_interact_npc)
		elif k == KEY_C and not _capture_mode:
			_class_panel.visible = not _class_panel.visible
		elif (k == KEY_TAB or k == KEY_P) and not _capture_mode:
			if _phone_panel != null:
				_phone_panel.visible = not _phone_panel.visible
				if _phone_panel.visible:
					_set_phone_tab(_phone_tab)
		elif k == KEY_M and not _capture_mode:
			if _phone_panel != null:
				_phone_panel.visible = true
				_set_phone_tab("Map")

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
			_p3_on_action("chai")
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
	if npc.is_teacher:
		_dlg_title.text = "%s — %s" % [npc.data["name"], npc.subject]
	else:
		_dlg_title.text = "%s — %s, Year %s" % [npc.data["name"], npc.data.get("major", ""), str(npc.data.get("year", ""))]
	for b in _dlg_btns.get_children():
		(b as Button).visible = npc.is_main or npc.is_teacher
	if _dlg_btns2 != null:
		_dlg_btns2.visible = npc.is_main or npc.is_teacher
		for b in _dlg_btns2.get_children():
			var btn := b as Button
			if btn == _dlg_office_btn:
				btn.visible = npc.is_teacher
				btn.disabled = npc.is_teacher and npc.office_help_day == day
			else:
				btn.visible = true
	if npc.is_main or npc.is_teacher:
		_dlg_text.text = "%s\n\n%s" % [npc.data.get("personality", ""), _pick_chat_line(npc)]
	else:
		_dlg_text.text = str(npc.data.get("greeting", "Hello!"))
	if _dlg_btns3 != null:
		_dlg_btns3.visible = npc.is_main or npc.is_teacher
		if _dlg_romance_btn != null:
			_dlg_romance_btn.visible = npc.is_main
		if _dlg_letter_btn != null:
			_dlg_letter_btn.visible = npc.is_teacher
	if _dlg_btns4 != null:
		_dlg_btns4.visible = npc.is_main
	_update_dlg_friend()
	if npc.is_teacher:
		_complete_quest_if("meet_teacher")
	if not _capture_mode and (npc.is_main or npc.is_teacher):
		var p3note := _p3_on_talk(npc)
		if p3note != "":
			_dlg_text.text += "\n\n" + p3note

func _pick_chat_line(npc: NPC) -> String:
	# Phase 2: route mains + teachers through the Dialogue engine
	# (topic-rotating, context-aware, no repeats until the bank cycles).
	if npc.is_main or npc.is_teacher:
		var topics := ["classes", "fest", "gossip", "personal"]
		var topic: String = str(topics[npc.chats % topics.size()])
		var line := Dialogue.pick_line(npc, topic, npc.target_zone, game_minutes / 60.0, day)
		if npc.chats >= 2:
			line = "Good to see you again. " + line
		return line
	var lines: Array = npc.data.get("chat", ["Hello!"])
	var line2: String = lines[npc.chats % lines.size()]
	if npc.chats >= 2:
		line2 = "Good to see you again. " + line2
	return line2

func _note_memory(npc: NPC, what: String) -> void:
	var note := "%s on Day %d" % [what, day]
	npc.memory_notes.append(note)
	while npc.memory_notes.size() > 8:
		npc.memory_notes.pop_front()

func _update_dlg_friend() -> void:
	if _current_npc != null and (_current_npc.is_main or _current_npc.is_teacher):
		_dlg_friend.text = "Friendship: %d / 100 — %s   •   Chats so far: %d" % [_current_npc.friendship, _tier_name(_current_npc.friendship), _current_npc.chats]
	else:
		_dlg_friend.text = ""

func _dlg_choice(kind: String) -> void:
	var npc := _current_npc
	if npc == null or (not npc.is_main and not npc.is_teacher):
		return
	if kind == "office":
		if npc.office_help_day == day:
			_dlg_text.text = "I have already helped you today. Come back tomorrow with new questions — and attempted answers."
			return
		npc.office_help_day = day
		npc.friendship = mini(100, npc.friendship + 3)
		gpa = minf(10.0, gpa + 0.05)
		var cur: Variant = _current_assignment()
		if cur != null and not bool(cur["submitted"]):
			cur["progress"] = mini(100, int(cur["progress"]) + 20)
		_dlg_text.text = "Office hours, then. %s\n\n(GPA +0.05, assignment +20 progress, friendship +3.)" % Dialogue.pick_line(npc, "career", npc.target_zone, game_minutes / 60.0, day)
		_p3_on_action("office", str(npc.data["name"]))
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p3_story":
		_dlg_text.text = _p3_story_text(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p3_favour":
		_dlg_text.text = _p3_favour_text(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p3_invite":
		_dlg_text.text = _p3_invite_text(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p3_romance":
		_dlg_text.text = _p3_try_romance(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p3_letter":
		_dlg_text.text = _p3_try_letter(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "p4_invite_room":
		_dlg_text.text = _p4_invite_room(npc)
		_update_dlg_friend()
		_refresh_hud()
		return
	if kind == "chat":
		npc.chats += 1
		npc.friendship = mini(100, npc.friendship + 2)
		_dlg_text.text = _pick_chat_line(npc)
		_note_memory(npc, "a chat")
	elif kind == "topic_classes" or kind == "topic_fest" or kind == "topic_gossip" or kind == "topic_personal":
		var topic := kind.substr(6)
		if topic == "personal" and npc.friendship < 20:
			# Section 19.2: personal topics unlock by friendship tier.
			_dlg_text.text = "We have only just met — talk to me a little more first, and I will tell you the real stuff."
			_update_dlg_friend()
			return
		npc.chats += 1
		npc.friendship = mini(100, npc.friendship + 2)
		_dlg_text.text = Dialogue.pick_line(npc, topic, npc.target_zone, game_minutes / 60.0, day)
		_note_memory(npc, "talking about " + topic)
	elif kind == "compliment":
		if npc.compliments_today < 2:
			npc.compliments_today += 1
			npc.chats += 1
			npc.friendship = mini(100, npc.friendship + 4)
			if npc.is_teacher:
				_dlg_text.text = "A compliment from a student who attends — noted, with approval. Keep the work up, and the praise will keep meaning something."
			else:
				_dlg_text.text = str(npc.data.get("compliment", "Thank you!"))
		else:
			_dlg_text.text = "You've praised me enough for one day — I'll start suspecting you're buttering me up for notes. (Compliment limit per day reached.)"
	elif kind == "ask":
		if npc.is_teacher:
			npc.chats += 1
			_dlg_text.text = "I teach %s. My office hours are in the %s — bring questions, and bring your own attempted answers first. That is how office hours help." % [npc.subject, str(npc.data.get("office", "library"))]
			_update_dlg_friend()
			return
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

# ---------------- Phase 2 systems ----------------

func _player_zone() -> String:
	var pp := _player.global_position
	var best := "outdoors"
	var best_d := 24.0
	for z in ZONE_CENTERS.keys():
		var d := Vector2(pp.x, pp.z).distance_to(Vector2(ZONE_CENTERS[z].x, ZONE_CENTERS[z].z))
		if d < best_d:
			best_d = d
			best = str(z)
	if best == "outdoors":
		# near the quad crossing but outside every building radius
		if Vector2(pp.x, pp.z).distance_to(Vector2(0, -5)) < 34.0:
			return "quad"
	return best

func _lecture_period(hour: float) -> String:
	if hour >= 9.0 and hour < 11.0:
		return "am1"
	elif hour >= 11.0 and hour < 13.0:
		return "am2"
	elif hour >= 14.0 and hour < 16.0:
		return "pm"
	return ""

func _nearby_main(dist: float) -> NPC:
	for n in _mains:
		var npc := n as NPC
		if npc.global_position.distance_to(_player.global_position) < dist:
			return npc
	return null

func _current_assignment() -> Variant:
	for a in _assignments:
		if not bool(a["submitted"]):
			return a
	return null

func _add_message(sender: String, text: String) -> void:
	_messages.append({"day": day, "from": sender, "text": text})
	while _messages.size() > 40:
		_messages.pop_front()
	if not _test_mode and not _capture_mode:
		_show_toast("📱 New message from %s" % sender)

func _npc_initiated() -> void:
	# Section 19.2: characters start conversations, not just respond.
	if _mains.is_empty():
		return
	var npc: NPC = _mains[_rng.randi_range(0, _mains.size() - 1)]
	var line := Dialogue.pick_line(npc, "gossip", npc.target_zone, game_minutes / 60.0, day)
	_add_message(str(npc.data["name"]), line)
	if npc.global_position.distance_to(_player.global_position) < 25.0:
		npc.show_bubble(line.substr(0, mini(90, line.length())), 4.0)

func _quest_target_pos() -> Vector3:
	if _quest_index >= _quests.size():
		return _player.global_position
	var q: Dictionary = _quests[_quest_index]
	var tz := str(q["target_zone"])
	if tz == "teacher":
		var best: NPC = null
		var best_d := 1e9
		for t in _teachers:
			var d := (t as NPC).global_position.distance_to(_player.global_position)
			if d < best_d:
				best_d = d
				best = t
		if best != null:
			return best.global_position
		return ZONE_CENTERS["admin"]
	return ZONE_CENTERS.get(tz, Vector3.ZERO)

func _complete_quest_if(qid: String) -> bool:
	if _quest_index >= _quests.size():
		return false
	var q: Dictionary = _quests[_quest_index]
	if str(q["id"]) != qid or bool(q["done"]):
		return false
	q["done"] = true
	match qid:
		"meet_teacher":
			social = minf(100.0, social + 5.0)
		"attend_lecture":
			gpa = minf(10.0, gpa + 0.05)
		"study_session":
			_skill_xp["Study"] = int(_skill_xp["Study"]) + 1
		"job_shift":
			money += 50
		"sleep_save":
			money += 25
	_show_mission("Quest complete: %s" % str(q["title"]), "Next: %s" % (_quests[_quest_index + 1]["title"] if _quest_index + 1 < _quests.size() else "Semester life continues — keep the streak going!"))
	_quest_index += 1
	_refresh_hud()
	return true

func _show_mission(title: String, desc: String) -> void:
	if _mission_label == null:
		return
	_mission_label.text = "🎯 %s\n%s" % [title, desc]
	_mission_panel.visible = true
	_mission_timer = 6.0

func _attend_lecture() -> void:
	var hour := game_minutes / 60.0
	var period := _lecture_period(hour)
	if period == "":
		_show_toast("No lecture right now — lectures run 09:00–11:00, 11:00–13:00 and 14:00–16:00.")
		return
	var key := "%d_%s" % [day, period]
	if _attended_keys.has(key):
		_show_toast("You already attended this lecture slot today. Revise in the library instead.")
		return
	var info := Phase2Data.major_info(player_major)
	var zone := _player_zone()
	var own_block := zone == str(info["block"])
	var qa: Dictionary = Phase2Data.qa_questions().get(player_major, Phase2Data.qa_questions()["Computer Science"])
	_qa_answer = int(qa["answer"])
	_qa_period = key
	_qa_question.text = "%s — %s\n\nQ: %s" % [str(info["subjects"][0]), ("Your lecture" if own_block else "Visiting lecture"), str(qa["q"])]
	var opts: Array = qa["options"]
	for i in range(3):
		(_qa_btns.get_child(i) as Button).text = str(opts[i])
	_qa_panel.visible = true
	_player.controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_toast("Lecture in progress… answer the question to take notes.")

func _qa_answer_pressed(idx: int) -> void:
	_qa_panel.visible = false
	_player.controls_locked = false
	var info := Phase2Data.major_info(player_major)
	var zone := _player_zone()
	var own_block := zone == str(info["block"])
	_attended_keys.append(_qa_period)
	energy = maxf(0.0, energy - 5.0)
	if idx == _qa_answer:
		gpa = minf(10.0, gpa + (0.06 if own_block else 0.03))
		_show_toast("Correct! Notes taken, professor impressed. GPA up.")
		_add_message(str(info["teacher"]), "Good answer in class today. Keep that standard up — and do not be late tomorrow.")
	else:
		gpa = minf(10.0, gpa + 0.02)
		_show_toast("Not quite — but attending and trying still counts. Review the topic in the library.")
	_complete_quest_if("attend_lecture")
	_p3_on_action("lecture")
	_p4_bump("lectures")
	_refresh_hud()

func _do_study(group: bool) -> void:
	if energy < 8.0:
		_show_toast("Too tired to study. Eat something or rest first.")
		return
	energy = maxf(0.0, energy - 8.0)
	_skill_xp["Study"] = int(_skill_xp["Study"]) + 1
	if int(_skill_xp["Study"]) % 3 == 0 and int(skills["Study"]) < 10:
		skills["Study"] = int(skills["Study"]) + 1
		_show_toast("Study skill up! Now level %d." % int(skills["Study"]))
	var cur: Variant = _current_assignment()
	var gain := 25
	var friend: NPC = null
	if group:
		friend = _nearby_main(12.0)
		if friend != null:
			gain = 40
			friend.friendship = mini(100, friend.friendship + 2)
	if cur != null and not bool(cur["submitted"]):
		cur["progress"] = mini(100, int(cur["progress"]) + gain)
		if int(cur["progress"]) >= 100:
			_show_toast("Assignment complete! Submit it here in the library (E) before the deadline.")
		else:
			_show_toast("Study session done. Assignment progress: %d%%.%s" % [int(cur["progress"]), " Group bonus applied!" if group else ""])
	else:
		_show_toast("Study session done. No open assignment — GPA still benefits from revision.")
	gpa = minf(10.0, gpa + 0.03)
	stress = maxf(0.0, stress - 2.0)
	_complete_quest_if("study_session")
	_p3_on_action("study")
	_p4_bump("study")
	_refresh_hud()

func _do_submit() -> void:
	var cur: Variant = _current_assignment()
	if cur == null or int(cur["progress"]) < 100 or bool(cur["submitted"]):
		_show_toast("Nothing ready to submit yet — finish it in the library first.")
		return
	cur["submitted"] = true
	gpa = minf(10.0, gpa + 0.15)
	var info := Phase2Data.major_info(player_major)
	_add_message(str(info["teacher"]), "Received your %s. Well structured — marks after review." % str(cur["title"]))
	_show_toast("Assignment submitted! GPA +0.15.")
	_refresh_hud()

func _do_job(job_id: String) -> void:
	var jobs := Phase2Data.jobs()
	if not jobs.has(job_id):
		return
	var job: Dictionary = jobs[job_id]
	if bool(_jobs_today.get(job_id, false)):
		_show_toast("You already worked this job today. Come back tomorrow.")
		return
	if job_id == "library" and _player_zone() != "library":
		_show_toast("Library Assistant shifts happen in the Central Library.")
		return
	if job_id == "canteen" and _player_zone() != "foodcourt":
		_show_toast("Canteen shifts happen at the Food Court.")
		return
	if job_id == "tutoring" and gpa < 7.0:
		_show_toast("Tutoring needs GPA 7.0+ — juniors trust toppers. Study first!")
		return
	var cost := int(job["energy"])
	if energy < float(cost):
		_show_toast("Too tired for a shift. Rest or eat first.")
		return
	energy = maxf(0.0, energy - float(cost))
	money += int(job["pay"])
	_earned_total += int(job["pay"])
	_jobs_today[job_id] = true
	_jobs_total[job_id] = int(_jobs_total.get(job_id, 0)) + 1
	stress = minf(100.0, stress + 3.0)
	_show_toast("%s done! +₹%d. Total earned: ₹%d." % [str(job["title"]), int(job["pay"]), _earned_total])
	_complete_quest_if("job_shift")
	_p3_on_action("job")
	_p4_bump("jobs")
	_p4_bump("earned", int(job["pay"]))
	_refresh_hud()

func _do_sleep() -> void:
	if _player_zone() != "dorm":
		_show_toast("Sleep happens in your dorm room in the Residence Hall.")
		return
	_complete_quest_if("sleep_save")
	_advance_day()
	_show_toast("Day %d — you wake up rested. Autosaved." % day)

func _advance_day() -> void:
	# Shared end-of-day logic for sleep AND the midnight rollover:
	# attendance consequences + professor remarks, overdue assignments,
	# calendar events, fresh messages/buzz, daily resets, autosave.
	var weekday := (day - 1) % 7 # 0=Mon .. 4=Fri are lecture days
	# Phase 3: no attendance penalty during the Diwali break (Days 49-51).
	if weekday < 5 and not (day >= 49 and day <= 51):
		var missed := 0
		for p in ["am1", "am2", "pm"]:
			if not _attended_keys.has("%d_%s" % [day, p]):
				missed += 1
		if missed > 0:
			gpa = maxf(0.0, gpa - 0.08 * float(missed))
			stress = minf(100.0, stress + 2.0 * float(missed))
			var info := Phase2Data.major_info(player_major)
			_add_message(str(info["teacher"]), "Attendance note: you missed %d lecture slot(s) today. GPA reflects attendance — see me in office hours." % missed)
	day += 1
	game_minutes = 360.0 # 06:00
	_p3_on_day_start()
	_p4_on_day_start()
	energy = 95.0
	health = minf(100.0, health + 5.0)
	stress = maxf(0.0, stress - 10.0)
	for n in _mains:
		(n as NPC).compliments_today = 0
	for t in _teachers:
		(t as NPC).compliments_today = 0
	_jobs_today = {}
	# overdue assignments
	for a in _assignments:
		if not bool(a["submitted"]) and int(a["due_day"]) < day:
			if not bool(a.get("penalised", false)):
				a["penalised"] = true
				gpa = maxf(0.0, gpa - 0.30)
				var info2 := Phase2Data.major_info(player_major)
				_add_message(str(info2["teacher"]), "Overdue: %s was due Day %d. Late penalty applied (-0.30 GPA). Submit it now to stop further damage." % [str(a["title"]), int(a["due_day"])])
	# today's calendar event, if any
	for ev in Phase2Data.calendar_events():
		if int(ev["day"]) == day:
			_add_message("Northbridge Admin", "Today: %s — %s" % [str(ev["title"]), str(ev["desc"])])
	# fresh NPC messages + buzz (deterministic rotation, no repeats spam)
	if not _mains.is_empty():
		var n1: NPC = _mains[(day * 2) % _mains.size()]
		var n2: NPC = _mains[(day * 2 + 3) % _mains.size()]
		_add_message(str(n1.data["name"]), Dialogue.pick_line(n1, "gossip", n1.target_zone, 9.0, day))
		_add_message(str(n2.data["name"]), Dialogue.pick_line(n2, "fest", n2.target_zone, 9.0, day))
	var buzz_tpl: Array = Phase2Data.buzz_templates()
	var bname := str(_mains[(day * 3) % _mains.size()].data["name"]) if not _mains.is_empty() else "Campus"
	_buzz.append({"day": day, "text": str(buzz_tpl[day % buzz_tpl.size()]).replace("{name}", bname)})
	if not _test_mode and not _capture_mode:
		SaveSystem.save(0, _collect_state())
	_refresh_hud()

# ---------------- Phase 2 save / state ----------------

func _collect_state() -> Dictionary:
	var fr: Dictionary = {}
	var mem: Dictionary = {}
	var seen: Dictionary = {}
	for n in _mains + _teachers:
		var npc := n as NPC
		fr[str(npc.data["name"])] = npc.friendship
		if not npc.memory_notes.is_empty():
			mem[str(npc.data["name"])] = npc.memory_notes.duplicate()
		if not npc.dialogue_seen.is_empty():
			seen[str(npc.data["name"])] = npc.dialogue_seen.duplicate(true)
	var msgs: Array = []
	for m in _messages:
		msgs.append(m.duplicate())
	var bz: Array = []
	for b in _buzz:
		bz.append(b.duplicate())
	var asg: Array = []
	for a in _assignments:
		asg.append(a.duplicate())
	return {
		"version": 1, "day": day, "game_minutes": game_minutes,
		"player_name": player_name, "player_major": player_major, "appearance": _appearance_idx,
		"money": money, "energy": energy, "gpa": gpa, "health": health,
		"stress": stress, "social": social, "skills": skills.duplicate(),
		"friendships": fr, "memories": mem, "dialogue_seen": seen,
		"assignments": asg, "attended": _attended_keys.duplicate(),
		"jobs_done_day": _jobs_today.duplicate(), "jobs_done_total": _jobs_total.duplicate(),
		"quest_index": _quest_index, "messages": msgs, "buzz": bz,
		"p3": _p3_collect_state(), "p4": _p4_collect_state()
	}

func _apply_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	day = int(state.get("day", 1))
	game_minutes = float(state.get("game_minutes", 450.0))
	player_name = str(state.get("player_name", player_name))
	_appearance_idx = int(state.get("appearance", 0))
	money = int(state.get("money", 500))
	energy = float(state.get("energy", 92.0))
	gpa = float(state.get("gpa", 7.5))
	health = float(state.get("health", 80.0))
	stress = float(state.get("stress", 30.0))
	social = float(state.get("social", 50.0))
	var sk: Dictionary = state.get("skills", {})
	for k in sk.keys():
		skills[k] = sk[k]
	var fr: Dictionary = state.get("friendships", {})
	var mem: Dictionary = state.get("memories", {})
	var seen: Dictionary = state.get("dialogue_seen", {})
	for n in _mains + _teachers:
		var npc := n as NPC
		var nm := str(npc.data["name"])
		if fr.has(nm):
			npc.friendship = int(fr[nm])
		if mem.has(nm):
			npc.memory_notes = (mem[nm] as Array).duplicate()
		if seen.has(nm):
			npc.dialogue_seen = (seen[nm] as Dictionary).duplicate(true)
	var asg: Array = state.get("assignments", [])
	if not asg.is_empty():
		_assignments = []
		for a in asg:
			_assignments.append((a as Dictionary).duplicate())
	_attended_keys = (state.get("attended", []) as Array).duplicate()
	_jobs_today = (state.get("jobs_done_day", {}) as Dictionary).duplicate()
	_jobs_total = (state.get("jobs_done_total", {}) as Dictionary).duplicate()
	_quest_index = int(state.get("quest_index", 0))
	if state.has("p3") and state["p3"] is Dictionary:
		_p3_apply_state(state["p3"])
	if state.has("p4") and state["p4"] is Dictionary:
		_p4_apply_state(state["p4"])
	_messages = []
	for m in state.get("messages", []):
		_messages.append((m as Dictionary).duplicate())
	_buzz = []
	for b in state.get("buzz", []):
		_buzz.append((b as Dictionary).duplicate())
	_apply_major(player_major)
	# Re-place every non-staff NPC by timetable for the restored time
	# (delta saves store no positions — this keeps loads consistent).
	var hour := game_minutes / 60.0
	for n in _all_npcs:
		var npc := n as NPC
		if npc.is_staff or npc.talking:
			continue
		var zone := _segment_for(npc.data, hour)
		var idx := _all_npcs.find(npc)
		var spot: Vector3 = _pick_spot(npc, zone, idx)
		npc.global_position = spot
		npc.spot = spot
		npc.target_zone = zone
		npc.set_path([])
	# Rebuild the player model for a restored appearance choice.
	var presets := Phase2Data.appearance_presets()
	if _appearance_idx >= 0 and _appearance_idx < presets.size():
		var pr: Dictionary = presets[_appearance_idx]
		_player.apply_appearance({"height": 1.74, "build": 1.0, "skin": pr["skin"], "hair_style": pr["hair_style"], "hair_color": Color(0.07, 0.05, 0.04), "shirt": pr["shirt"], "pants": Color(0.20, 0.22, 0.35), "female": pr["female"], "backpack": true, "pack_color": Color(0.25, 0.25, 0.28)})
	# Phase 4: re-apply a saved custom outfit/hairstyle on top of the
	# preset rebuild above, and rebuild the placed dorm décor.
	_p4_after_load()
	_refresh_hud()
	_refresh_classmates()

func _save_slot_pressed(slot: int) -> void:
	if SaveSystem.save(slot, _collect_state()):
		_show_toast("Saved to slot %d." % slot)
	else:
		_show_toast("Save failed — could not write slot %d." % slot)

func _load_slot_pressed(slot: int) -> void:
	if not SaveSystem.slot_exists(slot):
		_show_toast("Slot %d is empty." % slot)
		return
	_apply_state(SaveSystem.load_slot(slot))
	_show_toast("Loaded slot %d — Day %d." % [slot, day])

func _create_start_pressed() -> void:
	var nm := _create_name.text.strip_edges()
	if nm != "":
		player_name = nm
	var majors := Phase2Data.majors()
	player_major = majors[_create_major.selected]
	_appearance_idx = _create_appear.selected
	var pr: Dictionary = Phase2Data.appearance_presets()[_appearance_idx]
	_player.apply_appearance({"height": 1.74, "build": 1.0, "skin": pr["skin"], "hair_style": pr["hair_style"], "hair_color": Color(0.07, 0.05, 0.04), "shirt": pr["shirt"], "pants": Color(0.20, 0.22, 0.35), "female": pr["female"], "backpack": true, "pack_color": Color(0.25, 0.25, 0.28)})
	_apply_major(player_major)
	_create_panel.visible = false
	_player.controls_locked = false
	_show_mission("Semester started!", "%s — %s. Your lectures are in %s with %s. Check your phone (Tab)." % [player_name, player_major, str(Phase2Data.major_info(player_major)["block_name"]), str(Phase2Data.major_info(player_major)["teacher"])])
	_add_message("Northbridge Admin", "Student record created: %s, %s. Good luck this semester!" % [player_name, player_major])
	_refresh_hud()

# ---------------- Phase 2 phone ----------------

func _set_phone_tab(tab: String) -> void:
	_phone_tab = tab
	_phone_job_row.visible = (tab == "Jobs")
	if _phone_city_row != null:
		_phone_city_row.visible = (tab == "City Gate")
	if _phone_action_row != null:
		_phone_action_row.visible = (tab == "Stories")
	_phone_text.text = _phone_text_for(tab)

func _phone_text_for(tab: String) -> String:
	match tab:
		"Messages":
			if _messages.is_empty():
				return "No messages yet. Characters message you about real events — talk to people and sleep to advance days."
			var out := ""
			for m in _messages:
				out += "Day %d — %s:\n%s\n\n" % [int(m["day"]), str(m["from"]), str(m["text"])]
			return out
		"Buzz":
			if _buzz.is_empty():
				return "Campus Buzz is quiet. It fills up as days pass."
			var out2 := "CAMPUS BUZZ — what campus is posting:\n\n"
			for b in _buzz:
				out2 += "Day %d: %s\n\n" % [int(b["day"]), str(b["text"])]
			return out2
		"Calendar":
			var info := Phase2Data.major_info(player_major)
			var out3 := "%s — %s\nTimetable (Mon–Fri):\n09:00 Lecture, %s (%s)\n11:00 Seminar / Lab\n13:00 Lunch\n14:00 Lecture / Seminar\n16:00 Clubs & office hours\n\nUpcoming events:\n" % [player_name, player_major, str(info["block_name"]), str(info["teacher"])]
			var shown := 0
			for ev in Phase2Data.calendar_events():
				if int(ev["day"]) >= day and shown < 8:
					out3 += "Day %d: %s — %s\n" % [int(ev["day"]), str(ev["title"]), str(ev["desc"])]
					shown += 1
			out3 += "\nAssignments:\n"
			for a in _assignments:
				out3 += "- %s (due Day %d): %d%% %s\n" % [str(a["title"]), int(a["due_day"]), int(a["progress"]), "SUBMITTED" if bool(a["submitted"]) else ""]
			out3 += "\nWEATHER TODAY: %s%s\n" % [_p4_weather, " — outdoor crowds move indoors" if _p4_weather == "rain" else ""]
			out3 += "\nCLUBS (join max 2; sessions 16:00–17:00, Literature Sun 11:00):\n"
			for cid in Phase4Data.clubs().keys():
				var c: Dictionary = Phase4Data.clubs()[cid]
				out3 += "- %s (%s, %s): %s\n" % [str(c["title"]), ZONE_NAMES.get(str(c["venue"]), str(c["venue"])), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][int(c["weekday"])], "JOINED" if _p4_clubs_joined.has(cid) else "not joined"]
			out3 += "Club sessions attended: %d • Sport sessions: %d\n" % [_p4_club_sessions, _p4_sport_sessions]
			out3 += "\nEXAMS: Mid-sem Days 52–54 (results Day 57) • Finals Days 78–82 (results Day 85) • Sports Meet Week Days 64–70\n"
			if _p4_midsem_result != "":
				out3 += "Mid-sem: %s\n" % _p4_midsem_result
			if _p4_final_results != "":
				out3 += "Finals: %s\n" % _p4_final_results
			if not _p4_week_summaries.is_empty():
				out3 += "\nLAST WEEK SUMMARY:\n%s\n" % str(_p4_week_summaries[_p4_week_summaries.size() - 1])
			return out3
		"Map":
			var out4 := "CAMPUS MAP — you are in: %s\n\n" % _player_zone()
			for z in ZONE_NAMES.keys():
				out4 += "- %s\n" % ZONE_NAMES[z]
			out4 += "\nYellow diamond on the minimap (bottom-right) = your current quest target."
			if _quest_index < _quests.size():
				out4 += "\nCurrent quest: %s" % str(_quests[_quest_index]["title"])
			return out4
		"Wallet":
			return "WALLET\nMoney: ₹%d\nTotal earned from jobs: ₹%d\n\nSTATS\nGPA: %.2f / 10\nHealth: %d\nStress: %d\nSocial: %d\nEnergy: %d\n\nSKILLS\nStudy %d • Sport %d • Music/Art %d • Tech %d • Communication %d" % [money, _earned_total, gpa, int(health), int(stress), int(social), int(energy), int(skills["Study"]), int(skills["Sport"]), int(skills["Music/Art"]), int(skills["Tech"]), int(skills["Communication"])]
		"Jobs":
			var out5 := "PART-TIME JOBS (one shift per job per day):\n\n"

			for jid in Phase2Data.jobs().keys():
				var j: Dictionary = Phase2Data.jobs()[jid]
				out5 += "%s — ₹%d, %s. Done today: %s. Total shifts: %d\n" % [str(j["title"]), int(j["pay"]), str(j["where"]), "yes" if bool(_jobs_today.get(jid, false)) else "no", int(_jobs_total.get(jid, 0))]
			out5 += "\nTap a job button below to work it (location jobs need you to be there)."
			return out5
		"Stories":
			return _p3_stories_text()
		"Social":
			if _p3_social_posts.is_empty():
				return "CAMPUS SOCIAL — no posts yet. Posts appear as arcs, favours, events, gossip and festivals happen."
			var out6 := "CAMPUS SOCIAL — what campus is posting:\n\n"
			for i in range(_p3_social_posts.size() - 1, -1, -1):
				var p: Dictionary = _p3_social_posts[i]
				out6 += "Day %d — %s:\n%s\n\n" % [int(p["day"]), str(p["author"]), str(p["text"])]
			return out6
		"City Gate":
			var out7 := "CITY GATE — day trips by bus from the Main Gate (one trip per day).\nThe MG Road city district is open: ride Route 12 from the Main Gate to shop, eat and explore.\nYou are in: %s%s\n\n" % [_player_zone(), "" if _player_zone() == "gate" else " — go to the Main Gate to catch the bus."]
			for tid in Phase3Data.city_trips().keys():
				var t: Dictionary = Phase3Data.city_trips()[tid]
				out7 += "%s — ₹%d. %s\n\n" % [str(t["title"]), int(t["cost"]), str(t["desc"])]
			out7 += "Tap a trip button below (at the Main Gate) to travel."
			return out7
	return ""

# ---------------- Phase 3 systems ----------------

func _p3_npc_by_name(nm: String) -> NPC:
	for n in _mains + _teachers:
		var npc := n as NPC
		if str(npc.data["name"]) == nm:
			return npc
	return null

func _p3_post(author: String, text: String) -> void:
	_p3_social_posts.append({"day": day, "author": author, "text": text})
	while _p3_social_posts.size() > 50:
		_p3_social_posts.pop_front()

func _p3_add_gossip(text: String, delta: float) -> void:
	social = clampf(social + delta, 0.0, 100.0)
	_p3_gossip_log.append({"day": day, "text": text, "delta": delta})
	_p3_post("Campus Gossip", text)

func _p3_apply_reward(step: Dictionary, giver_name: String) -> String:
	money += int(step.get("money", 0))
	social = clampf(social + float(step.get("social", 0)), 0.0, 100.0)
	gpa = clampf(gpa + float(step.get("gpa", 0.0)), 0.0, 10.0)
	var giver := _p3_npc_by_name(giver_name)
	if giver != null:
		giver.friendship = mini(100, giver.friendship + int(step.get("friend", 0)))
	var bits: Array = []
	if int(step.get("money", 0)) != 0:
		bits.append("₹%d" % int(step.get("money", 0)))
	if int(step.get("friend", 0)) != 0:
		bits.append("friendship +%d" % int(step.get("friend", 0)))
	if int(step.get("social", 0)) != 0:
		bits.append("social +%d" % int(step.get("social", 0)))
	if float(step.get("gpa", 0.0)) != 0.0:
		bits.append("GPA +%.2f" % float(step.get("gpa", 0.0)))
	return ", ".join(PackedStringArray(bits))

func _p3_steps_for(nm: String, is_teacher: bool) -> Array:
	if is_teacher:
		var ta: Dictionary = Phase3Data.teacher_arcs()
		if ta.has(nm):
			return (ta[nm] as Dictionary)["steps"]
		return []
	var ar: Dictionary = Phase3Data.arcs()
	if ar.has(nm):
		return (ar[nm] as Dictionary)["steps"]
	return []

func _p3_progress(nm: String, is_teacher: bool) -> int:
	if is_teacher:
		return int(_p3_teacher_progress.get(nm, 0))
	return int(_p3_arc_progress.get(nm, 0))

func _p3_complete_arc_step(nm: String, is_teacher: bool) -> String:
	var steps: Array = _p3_steps_for(nm, is_teacher)
	var prog := _p3_progress(nm, is_teacher)
	if prog >= steps.size():
		return ""
	var step: Dictionary = steps[prog]
	var reward := _p3_apply_reward(step, nm)
	prog += 1
	if is_teacher:
		_p3_teacher_progress[nm] = prog
	else:
		_p3_arc_progress[nm] = prog
	var done := prog >= steps.size()
	if done:
		if is_teacher:
			_p3_teacher_done[nm] = true
		else:
			_p3_arc_done[nm] = true
		social = minf(100.0, social + 5.0)
		_p3_post(nm, "Finished the '%s' story with you. Campus will hear about this one." % (Phase3Data.teacher_arcs()[nm]["title"] if is_teacher and Phase3Data.teacher_arcs().has(nm) else (Phase3Data.arcs()[nm]["title"] if Phase3Data.arcs().has(nm) else "story")))
		_show_mission("Story complete: %s" % str(step["title"]), "%s's arc is finished! %s" % [nm, reward])
		return "📖 Story complete: %s — %s's arc is finished! (%s, social +5.)" % [str(step["title"]), nm, reward]
	_p3_post(nm, "Story update: %s — %s." % [str(step["title"]), str(step["desc"])])
	_show_toast("📖 Story progress: %s (%s)" % [str(step["title"]), reward])
	return "📖 Story progress: %s (%s)" % [str(step["title"]), reward]

func _p3_complete_favour(fav: Dictionary) -> String:
	_p3_favours.erase(fav)
	_p3_favours_done += 1
	var giver := str(fav["giver"])
	var gnpc := _p3_npc_by_name(giver)
	if gnpc != null:
		gnpc.friendship = mini(100, gnpc.friendship + int(fav.get("friend", 0)))
	money += int(fav.get("money", 0))
	social = clampf(social + float(fav.get("social", 0)), 0.0, 100.0)
	_p3_post(giver, "You came through on a favour — %s. Noted, and remembered." % str(fav["title"]))
	_show_toast("🤝 Favour done: %s (+₹%d, friendship +%d)" % [str(fav["title"]), int(fav.get("money", 0)), int(fav.get("friend", 0))])
	return "🤝 Favour done: %s — %s remembers this." % [str(fav["title"]), giver]

func _p3_advance_storyline(action: String) -> bool:
	var sl: Array = Phase3Data.storyline()
	if _p3_story_idx >= sl.size():
		return false
	var step: Dictionary = sl[_p3_story_idx]
	if str(step["action"]) != action:
		return false
	_p3_story_idx += 1
	social = minf(100.0, social + 4.0)
	_p3_post("Northbridge Admin", "Semester storyline: %s — done." % str(step["title"]))
	_show_mission("Semester storyline: %s" % str(step["title"]), "Next: %s" % (str(sl[_p3_story_idx]["title"]) if _p3_story_idx < sl.size() else "Results are in. What a semester."))
	return true

# Advance every started arc / favour / storyline step whose NEXT step
# matches this action. Arcs only ever advance on their next step, so an
# action can never skip an arc's talk step.
func _p3_on_action(action: String, actor: String = "") -> int:
	var count := 0
	for nm in Phase3Data.arcs().keys():
		var steps: Array = _p3_steps_for(str(nm), false)
		var prog := _p3_progress(str(nm), false)
		if prog < steps.size():
			var st: Dictionary = steps[prog]
			# Visit steps encode the zone in the action itself, so their
			# target field is informational; office steps match the actor.
			if str(st["action"]) == action and (str(st.get("target", "")) == "" or str(st.get("target", "")) == actor or action.begins_with("visit:")):
				_p3_complete_arc_step(str(nm), false)
				count += 1
	for nm in Phase3Data.teacher_arcs().keys():
		var steps2: Array = _p3_steps_for(str(nm), true)
		var prog2 := _p3_progress(str(nm), true)
		if prog2 < steps2.size():
			var st2: Dictionary = steps2[prog2]
			if str(st2["action"]) == action and (str(st2.get("target", "")) == "" or str(st2.get("target", "")) == actor or action.begins_with("visit:")):
				_p3_complete_arc_step(str(nm), true)
				count += 1
	for fav in _p3_favours.duplicate():
		var f: Dictionary = fav
		if str(f.get("match", "")) == action:
			_p3_complete_favour(f)
			count += 1
	if _p3_advance_storyline(action):
		count += 1
	# Phase 4: continued arcs advance on the same action vocabulary.
	count += _p4_advance_extensions(action, actor)
	return count

func _p3_on_talk(npc: NPC) -> String:
	var nm := str(npc.data["name"])
	var notes: Array = []
	# 1) Invitation kept: talking to the inviter on the due day keeps it.
	for plan in _p3_invitations.duplicate():
		var p: Dictionary = plan
		if str(p["with"]) == nm and int(p["day_due"]) == day:
			_p3_invitations.erase(plan)
			npc.friendship = mini(100, npc.friendship + 4)
			social = minf(100.0, social + 3.0)
			_p3_post(nm, "Met up as planned — %s. Plans kept are friendship's currency." % str(p["kind"]))
			notes.append("✉️ Plan kept: %s with %s. (friendship +4, social +3.)" % [str(p["kind"]), nm])
	# 2) Own arc talk step (mains + teachers).
	var steps: Array = _p3_steps_for(nm, npc.is_teacher)
	var prog := _p3_progress(nm, npc.is_teacher)
	if prog < steps.size() and str((steps[prog] as Dictionary)["action"]) == "talk":
		notes.append(_p3_complete_arc_step(nm, npc.is_teacher))
	# 2b) Phase 4 fix: arc steps of the form "talk_to:Name" were never
	# completable (Shadow's step 2 was stuck at 1/2). Talking to the
	# named person now completes any main's base or continued step.
	for other in Phase3Data.arcs().keys():
		var osteps: Array = _p3_steps_for(str(other), false)
		var oprog := _p3_progress(str(other), false)
		if oprog < osteps.size() and str((osteps[oprog] as Dictionary)["action"]) == "talk_to:" + nm:
			notes.append(_p3_complete_arc_step(str(other), false))
	# 2c) Phase 4 continued arcs: a "talk" step on the talked-to
	# character's own continued arc (gated on base-arc completion).
	if not npc.is_teacher and bool(_p3_arc_done.get(nm, false)):
		var esteps: Array = _p4_ext_steps_for(nm)
		var eprog := _p4_ext_prog(nm)
		if eprog < esteps.size() and str((esteps[eprog] as Dictionary)["action"]) == "talk":
			notes.append(_p4_complete_ext_step(nm))
		for other2 in Phase4Data.arc_extensions().keys():
			var e2: Array = _p4_ext_steps_for(str(other2))
			var p2 := _p4_ext_prog(str(other2))
			if bool(_p3_arc_done.get(str(other2), false)) and p2 < e2.size() and str((e2[p2] as Dictionary)["action"]) == "talk_to:" + nm:
				notes.append(_p4_complete_ext_step(str(other2)))
	# 3) Favours delivered by talking to the target person.
	for fav in _p3_favours.duplicate():
		var f: Dictionary = fav
		if str(f.get("match", "")) == "talk_to:" + nm:
			notes.append(_p3_complete_favour(f))
	# 4) Storyline: talking to any teacher.
	if npc.is_teacher:
		if _p3_advance_storyline("talk_teacher"):
			notes.append("🎓 Semester storyline: Orientation complete — you met the faculty.")
	return "\n".join(PackedStringArray(notes))

func _p3_story_text(npc: NPC) -> String:
	var nm := str(npc.data["name"])
	var table: Dictionary = Phase3Data.teacher_arcs() if npc.is_teacher else Phase3Data.arcs()
	if not table.has(nm):
		return "%s has no story arc yet — more arcs arrive with later phases." % nm
	var arc: Dictionary = table[nm]
	var steps: Array = arc["steps"]
	var prog := _p3_progress(nm, npc.is_teacher)
	if prog >= steps.size():
		var done_txt := "📖 '%s' — COMPLETE. %s" % [str(arc["title"]), str(arc["premise"])]
		# Phase 4: continued chapters follow the base arc.
		if not npc.is_teacher and Phase4Data.arc_extensions().has(nm):
			var ext: Dictionary = Phase4Data.arc_extensions()[nm]
			var es: Array = ext["steps"]
			var ep := _p4_ext_prog(nm)
			if ep >= es.size():
				done_txt += "\n📖 Continued '%s' — COMPLETE." % str(ext["title"])
			else:
				done_txt += "\n📖 Continued '%s' — Step %d of %d: %s — %s" % [str(ext["title"]), ep + 1, es.size(), str((es[ep] as Dictionary)["title"]), str((es[ep] as Dictionary)["desc"])]
		return done_txt
	var st: Dictionary = steps[prog]
	return "📖 '%s' — %s\nStep %d of %d: %s — %s" % [str(arc["title"]), str(arc["premise"]), prog + 1, steps.size(), str(st["title"]), str(st["desc"])]

func _p3_offer_favour(npc: NPC) -> Dictionary:
	var idx := 0
	for i in range(_mains.size()):
		if _mains[i] == npc:
			idx = i
			break
	var tpl: Dictionary = Phase3Data.favour_templates()[(idx + day) % Phase3Data.favour_templates().size()]
	var tgt: Dictionary = Phase3Data.favour_targets()[idx % Phase3Data.favour_targets().size()]
	var fav: Dictionary = {"giver": str(npc.data["name"]), "title": str(tpl["title"]), "day_offered": day,
		"money": int(tpl["money"]), "friend": int(tpl["friend"]), "social": int(tpl["social"])}
	if str(tpl["action"]) == "talk_to":
		fav["match"] = "talk_to:" + str(tgt["person"])
		fav["desc"] = str(tpl["desc"]).replace("{name}", str(npc.data["name"])).replace("{target}", str(tgt["person"]))
	elif str(tpl["action"]) == "visit":
		fav["match"] = "visit:" + str(tgt["zone"])
		fav["desc"] = str(tpl["desc"]).replace("{name}", str(npc.data["name"])).replace("{target_name}", str(tgt["zone_name"]))
	else:
		fav["match"] = "job"
		fav["desc"] = str(tpl["desc"]).replace("{name}", str(npc.data["name"]))
	_p3_favours.append(fav)
	return fav

func _p3_favour_text(npc: NPC) -> String:
	var nm := str(npc.data["name"])
	for fav in _p3_favours:
		var f: Dictionary = fav
		if str(f["giver"]) == nm:
			return "🤝 Open favour from %s: %s — %s (reward: ₹%d, friendship +%d.)" % [nm, str(f["title"]), str(f["desc"]), int(f["money"]), int(f["friend"])]
	var fav2 := _p3_offer_favour(npc)
	return "🤝 New favour from %s: %s — %s (reward: ₹%d, friendship +%d. Leave it 2 days and it counts as broken.)" % [nm, str(fav2["title"]), str(fav2["desc"]), int(fav2["money"]), int(fav2["friend"])]

func _p3_invite_text(npc: NPC) -> String:
	var nm := str(npc.data["name"])
	for plan in _p3_invitations:
		var p: Dictionary = plan
		if str(p["with"]) == nm and int(p["day_due"]) >= day:
			return "✉️ Plan already set with %s: %s on Day %d at the %s. Talk to them that day to keep it." % [nm, str(p["kind"]), int(p["day_due"]), str(p["zone"])]
	if npc.friendship < 20:
		return "%s smiles politely but is not sure yet — build a little friendship first (need 20, you are at %d)." % [nm, npc.friendship]
	_p3_invitations.append({"with": nm, "kind": "chai at the Food Court", "zone": "foodcourt", "day_due": day + 1, "from": "player"})
	return "✉️ You invited %s for chai at the Food Court on Day %d. Talk to them that day to keep the plan — breaking it costs friendship and starts gossip." % [nm, day + 1]

func _p3_try_romance(npc: NPC) -> String:
	if not npc.is_main:
		return "Romance is a story for the Ten, not for faculty — nice try, though."
	var nm := str(npc.data["name"])
	if _romance_partner == nm:
		return "💛 You and %s are already together. Sweet, steady, no drama required." % nm
	if _romance_partner != "":
		return "💛 You are already with %s. Campus romance, like a timetable, does not double-book." % _romance_partner
	if npc.friendship < 65:
		return "💛 %s likes you, but not like that — yet. (Need friendship 65+, you are at %d. Finish their story arc first, too.)" % [nm, npc.friendship]
	if not bool(_p3_arc_done.get(nm, false)):
		return "💛 %s wants to know you properly first — finish their story arc, then ask again." % nm
	_romance_partner = nm
	npc.friendship = mini(100, npc.friendship + 5)
	social = minf(100.0, social + 5.0)
	_note_memory(npc, "the day you asked them out")
	_p3_post(nm, "Some news, kept tasteful: you and %s are together now. Campus approves, quietly." % player_name)
	return "💛 %s said yes. You are together now — choices-gated, never forced, and entirely yours to keep." % nm

func _p3_try_letter(npc: NPC) -> String:
	if not npc.is_teacher:
		return "Recommendation letters come from faculty, not fellow students."
	var nm := str(npc.data["name"])
	if _teacher_letters.has(nm):
		return "📜 %s already wrote you a recommendation letter. One per teacher — do not be greedy." % nm
	if gpa < 7.5:
		return "📜 %s is kind but honest: your GPA (%.2f) needs to be 7.5+ before they put their name on a letter." % [nm, gpa]
	if npc.friendship < 40:
		return "📜 %s wants to know your work first — friendship 40+ (you are at %d). Office hours help." % [nm, npc.friendship]
	_teacher_letters.append(nm)
	social = minf(100.0, social + 5.0)
	_add_message(nm, "Recommendation letter: I have written one for you. Use it well — my name travels with it.")
	_p3_post(nm, "%s wrote a recommendation letter for you. That name carries weight on this campus." % nm)
	return "📜 %s wrote you a recommendation letter! (social +5.) It is in your messages." % nm

func _p3_check_zone(zone: String, force: bool = false) -> void:
	if (_capture_mode or _test_mode) and not force:
		return
	_p3_on_action("visit:" + zone)
	if day == 63 and (zone == "quad" or zone == "garden") and not _p3_holi_done:
		_p3_holi_done = true
		social = minf(100.0, social + 5.0)
		_p3_post("Campus Events", "Holi on the Quad: colours, music, and you, right in the middle of it.")
		_show_toast("🎨 Holi! Colours everywhere. Social +5.")

func _p3_attend_event(ev: Dictionary) -> bool:
	var key := "%d_%s" % [day, str(ev["title"])]
	if _p3_events_attended.has(key):
		return false
	_p3_events_attended.append(key)
	social = minf(100.0, social + 4.0)
	if bool(ev.get("practice", false)):
		_fest_practice += 1
	_p3_post("Campus Events", "You joined %s — %s" % [str(ev["title"]), str(ev["desc"])])
	_p3_on_action("group_event")
	_show_toast("🎉 Joined %s! Social +4.%s" % [str(ev["title"]), " Fest practice +1." if bool(ev.get("practice", false)) else ""])
	return true

func _p3_check_in() -> void:
	var weekday := (day - 1) % 7
	var hour := game_minutes / 60.0
	var zone := _player_zone()
	for ev in Phase3Data.group_events():
		var e: Dictionary = ev
		if int(e["weekday"]) == weekday and hour >= float(e["hour_start"]) and hour < float(e["hour_end"]):
			if zone != str(e["zone"]):
				_show_toast("That event (%s) is at the %s — you are in %s." % [str(e["title"]), ZONE_NAMES.get(str(e["zone"]), str(e["zone"])), ZONE_NAMES.get(zone, zone)])
				return
			if not _p3_attend_event(e):
				_show_toast("You already joined %s today." % str(e["title"]))
			_set_phone_tab("Stories")
			return
	if day >= 36 and day <= 40 and (zone == "garden" or zone == "union" or zone == "quad"):
		social = minf(100.0, social + 3.0)
		_p3_post("Campus Events", "Cultural Fest, Day %d: you were there, in the crowd, part of it." % day)
		_show_toast("🎪 Cultural Fest! You soaked it in. Social +3.")
		_set_phone_tab("Stories")
		return
	if day == 63 and (zone == "quad" or zone == "garden"):
		_p3_check_zone(zone, true)
		_set_phone_tab("Stories")
		return
	_show_toast("Nothing to join here right now. Today's group events are on the Stories tab.")

func _do_city_trip(tid: String) -> void:
	var trips := Phase3Data.city_trips()
	if not trips.has(tid):
		return
	var t: Dictionary = trips[tid]
	if _player_zone() != "gate":
		_show_toast("City trips leave from the Main Gate — walk to the gate bus loop first.")
		return
	if _city_trip_day == day:
		_show_toast("You already took a city trip today. One bus ride a day, student budget.")
		return
	if money < int(t["cost"]):
		_show_toast("Not enough money for %s (₹%d). You have ₹%d." % [str(t["title"]), int(t["cost"]), money])
		return
	money -= int(t["cost"])
	_city_trip_day = day
	if tid == "market":
		energy = minf(100.0, energy + 15.0)
		health = minf(100.0, health + 5.0)
	elif tid == "cinema":
		stress = maxf(0.0, stress - 15.0)
		social = minf(100.0, social + 3.0)
	elif tid == "bookstore":
		gpa = minf(10.0, gpa + 0.02)
		var cur: Variant = _current_assignment()
		if cur != null and not bool(cur["submitted"]):
			cur["progress"] = mini(100, int(cur["progress"]) + 10)
	_p3_post("City Bus", "Day trip: %s. %s (The MG Road city district is open — ride Route 12 from the Main Gate.)" % [str(t["title"]), str(t["desc"])])
	_show_toast("🚌 Day trip: %s (−₹%d). The bus drops you back at the gate by evening." % [str(t["title"]), int(t["cost"])])
	_refresh_hud()

func _p3_expire_plans() -> void:
	for plan in _p3_invitations.duplicate():
		var p: Dictionary = plan
		if int(p["day_due"]) < day:
			_p3_invitations.erase(plan)
			var other := _p3_npc_by_name(str(p["with"]))
			if other != null:
				other.friendship = maxi(0, other.friendship - 4)
			social = maxf(0.0, social - 3.0)
			_p3_add_gossip("Gossip: you stood up %s on a %s plan. Campus noticed." % [str(p["with"]), str(p["kind"])], 0.0)
	for fav in _p3_favours.duplicate():
		var f: Dictionary = fav
		if day - int(f["day_offered"]) >= 2:
			_p3_favours.erase(fav)
			var giver := _p3_npc_by_name(str(f["giver"]))
			if giver != null:
				giver.friendship = maxi(0, giver.friendship - 3)
			_p3_add_gossip("Gossip: %s's favour (%s) was left hanging for days." % [str(f["giver"]), str(f["title"])], 0.0)

func _p3_on_day_start() -> void:
	# Festivals, broken plans/favours, NPC invitations, ambient feed posts.
	for fest in Phase3Data.festivals():
		var f: Dictionary = fest
		if day == int(f["day_start"]):
			_add_message("Northbridge Admin", "%s starts today! %s" % [str(f["title"]), str(f["desc"])])
			_p3_post("Campus Events", "%s begins! %s" % [str(f["title"]), str(f["desc"])])
		if str(f["title"]) == "Cultural Fest" and day == int(f["day_end"]):
			var verdict := ""
			if _fest_practice >= 3:
				verdict = "a triumph — the judges (Dr. Kapoor and Prof. D'Souza) praised the performances, and the crowd stayed till the lights went out"
				social = minf(100.0, social + 10.0)
			elif _fest_practice >= 1:
				verdict = "warm and well-attended — practice showed, and the judges noticed"
				social = minf(100.0, social + 5.0)
			else:
				verdict = "quiet — the shows happened, but without rehearsal they never quite lifted off"
				social = minf(100.0, social + 2.0)
			_p3_fest_result = verdict
			_add_message("Dr. Kapoor", "Cultural Fest verdict: %s. (Fest practice sessions attended: %d.)" % [verdict, _fest_practice])
			_p3_post("Campus Events", "Cultural Fest closes: %s." % verdict)
	_p3_expire_plans()
	if day % 3 == 0 and not _mains.is_empty():
		var inviter: NPC = _mains[day % _mains.size()]
		_p3_invitations.append({"with": str(inviter.data["name"]), "kind": "chai at the Food Court", "zone": "foodcourt", "day_due": day, "from": "npc"})
		_add_message(str(inviter.data["name"]), "Hey — chai at the Food Court today? Talk to me today if you can make it, otherwise I will understand (and gossip, gently).")
	if not _mains.is_empty():
		var tpl: Array = Phase3Data.social_templates()
		var poster: NPC = _mains[day % _mains.size()]
		_p3_post(str(poster.data["name"]), str(tpl[day % tpl.size()]).replace("{name}", str(poster.data["name"])))
	if _p3_story_idx == 3 and day >= 85:
		_p3_story_idx = 4
		social = minf(100.0, social + 10.0)
		_add_message("Northbridge Admin", "Results Day: grades are published at the Admin Block. Whatever they say, you lived this semester.")
		_p3_post("Northbridge Admin", "Results Day is here. The semester's story is written — by you.")

func _p3_stories_text() -> String:
	var out := "STORIES — character arcs, storyline, favours, plans:\n\n"
	out += "MAIN STORYLINE:\n"
	var sl: Array = Phase3Data.storyline()
	for i in range(sl.size()):
		var mark := "✓ " if i < _p3_story_idx else ("→ " if i == _p3_story_idx else "○ ")
		out += "%s%s — %s\n" % [mark, str(sl[i]["title"]), str(sl[i]["desc"])]
	out += "\nCHARACTER ARCS (talk to them; Story button shows the next step):\n"
	for nm in Phase3Data.arcs().keys():
		var arc: Dictionary = Phase3Data.arcs()[nm]
		var prog := int(_p3_arc_progress.get(nm, 0))
		var steps: Array = arc["steps"]
		out += "- %s, '%s': %d/%d %s\n" % [str(nm), str(arc["title"]), prog, steps.size(), "COMPLETE" if prog >= steps.size() else str(steps[prog]["title"])]
	out += "\nTEACHER ARCS:\n"
	for nm in Phase3Data.teacher_arcs().keys():
		var arc2: Dictionary = Phase3Data.teacher_arcs()[nm]
		var prog2 := int(_p3_teacher_progress.get(nm, 0))
		var steps2: Array = arc2["steps"]
		out += "- %s, '%s': %d/%d %s\n" % [str(nm), str(arc2["title"]), prog2, steps2.size(), "COMPLETE" if prog2 >= steps2.size() else str(steps2[prog2]["title"])]
	out += "\nPHASE 4 CONTINUED ARCS (finish the base arc first):\n"
	for nm in Phase4Data.arc_extensions().keys():
		var ext: Dictionary = Phase4Data.arc_extensions()[nm]
		var es: Array = ext["steps"]
		var ep := _p4_ext_prog(str(nm))
		if not bool(_p3_arc_done.get(str(nm), false)):
			out += "- %s, '%s': base arc incomplete\n" % [str(nm), str(ext["title"])]
		else:
			out += "- %s, '%s': %d/%d %s\n" % [str(nm), str(ext["title"]), ep, es.size(), "COMPLETE" if ep >= es.size() else str((es[ep] as Dictionary)["title"])]
	out += "\nFAVOURS DONE: %d • OPEN FAVOURS:\n" % _p3_favours_done
	if _p3_favours.is_empty():
		out += "- none. Talk to a main and press Favour.\n"
	for fav in _p3_favours:
		var f: Dictionary = fav
		out += "- %s: %s — %s\n" % [str(f["giver"]), str(f["title"]), str(f["desc"])]
	out += "\nPLANS / INVITATIONS:\n"
	if _p3_invitations.is_empty():
		out += "- none. Invite someone from their dialogue panel.\n"
	for plan in _p3_invitations:
		var p: Dictionary = plan
		out += "- %s: %s, Day %d (%s)\n" % [str(p["with"]), str(p["kind"]), int(p["day_due"]), str(p["from"])]
	out += "\nFESTIVALS: Cultural Fest Days 36–40 (practice: %d sessions) • Diwali Break Days 49–51 • Holi Day 63\n" % _fest_practice
	if _romance_partner != "":
		out += "💛 Together with: %s\n" % _romance_partner
	if not _teacher_letters.is_empty():
		out += "📜 Recommendation letters from: %s\n" % ", ".join(PackedStringArray(_teacher_letters))
	out += "\nTODAY'S GROUP EVENTS (use Check in here while at the venue):\n"
	var weekday := (day - 1) % 7
	for ev in Phase3Data.group_events():
		var e: Dictionary = ev
		if int(e["weekday"]) == weekday:
			out += "- %s at %s, %.0f:00–%.0f:00. %s\n" % [str(e["title"]), ZONE_NAMES.get(str(e["zone"]), str(e["zone"])), float(e["hour_start"]), float(e["hour_end"]), str(e["desc"])]
	return out

func _p3_collect_state() -> Dictionary:
	var favs: Array = []
	for f in _p3_favours:
		favs.append((f as Dictionary).duplicate())
	var plans: Array = []
	for p in _p3_invitations:
		plans.append((p as Dictionary).duplicate())
	var posts: Array = []
	for p in _p3_social_posts:
		posts.append((p as Dictionary).duplicate())
	var gos: Array = []
	for g in _p3_gossip_log:
		gos.append((g as Dictionary).duplicate())
	return {
		"arc_progress": _p3_arc_progress.duplicate(), "arc_done": _p3_arc_done.duplicate(),
		"teacher_progress": _p3_teacher_progress.duplicate(), "teacher_done": _p3_teacher_done.duplicate(),
		"story_idx": _p3_story_idx, "favours": favs, "favours_done": _p3_favours_done,
		"invitations": plans, "social_posts": posts, "gossip": gos,
		"events_attended": _p3_events_attended.duplicate(), "fest_practice": _fest_practice,
		"holi_done": _p3_holi_done, "fest_result": _p3_fest_result,
		"romance": _romance_partner, "letters": _teacher_letters.duplicate(),
		"city_trip_day": _city_trip_day
	}

func _p3_apply_state(d: Dictionary) -> void:
	_p3_arc_progress = (d.get("arc_progress", {}) as Dictionary).duplicate()
	_p3_arc_done = (d.get("arc_done", {}) as Dictionary).duplicate()
	_p3_teacher_progress = (d.get("teacher_progress", {}) as Dictionary).duplicate()
	_p3_teacher_done = (d.get("teacher_done", {}) as Dictionary).duplicate()
	_p3_story_idx = int(d.get("story_idx", 0))
	_p3_favours = []
	for f in d.get("favours", []):
		_p3_favours.append((f as Dictionary).duplicate())
	_p3_favours_done = int(d.get("favours_done", 0))
	_p3_invitations = []
	for p in d.get("invitations", []):
		_p3_invitations.append((p as Dictionary).duplicate())
	_p3_social_posts = []
	for p in d.get("social_posts", []):
		_p3_social_posts.append((p as Dictionary).duplicate())
	_p3_gossip_log = []
	for g in d.get("gossip", []):
		_p3_gossip_log.append((g as Dictionary).duplicate())
	_p3_events_attended = (d.get("events_attended", []) as Array).duplicate()
	_fest_practice = int(d.get("fest_practice", 0))
	_p3_holi_done = bool(d.get("holi_done", false))
	_p3_fest_result = str(d.get("fest_result", ""))
	_romance_partner = str(d.get("romance", ""))
	_teacher_letters = (d.get("letters", []) as Array).duplicate()
	_city_trip_day = int(d.get("city_trip_day", -1))

func _p3_seed_capture_posts() -> void:
	# Capture-only staging (like staged NPCs): the Social tab needs posts
	# to photograph on Day 1, before any arc has been played.
	if not _p3_social_posts.is_empty():
		return
	_p3_post("Anirudh", "Campus app demo at the Union soon. If it crashes live, pretend it is a feature.")
	_p3_post("Yumi", "Dance rehearsal ran over, feet hurt, heart full. Fest piece is coming together.")
	_p3_post("Campus Gossip", "Word is Chirag's chai stall pitch finally found a supplier. Zannat remains sceptical, on principle.")
	_p3_post("Campus Events", "Cultural Fest auditions soon at the amphitheatre. Perform, volunteer, or watch — but be there.")

func _run_phase3_tests() -> bool:
	# Phase 3 headless evidence: one arc start→finish, a favour, an
	# invitation kept + one broken, a gossip effect, storyline progress
	# with Results locked, romance gating, a city trip, fest practice,
	# and social-feed generation.
	var ok := true
	print("[TEST_P3] arcs defined: ", Phase3Data.arcs().size(), " teacher arcs: ", Phase3Data.teacher_arcs().size())
	if Phase3Data.arcs().size() != 10:
		print("[TEST_P3_FAIL] expected 10 character arcs")
		ok = false
	for nm in Phase3Data.arcs().keys():
		if (Phase3Data.arcs()[nm]["steps"] as Array).size() < 2:
			print("[TEST_P3_FAIL] arc ", nm, " has fewer than 2 steps")
			ok = false
	# 1) Anirudh arc start -> finish (acceptance test).
	var ani := _p3_npc_by_name("Anirudh")
	_p3_on_talk(ani)
	if _p3_progress("Anirudh", false) != 1:
		print("[TEST_P3_FAIL] Anirudh arc step 1 (talk) did not complete")
		ok = false
	_player.global_position = ZONE_CENTERS["union"]
	_p3_check_zone("union", true)
	if not bool(_p3_arc_done.get("Anirudh", false)):
		print("[TEST_P3_FAIL] Anirudh arc did not complete end-to-end")
		ok = false
	else:
		print("[TEST_P3_ARC] Anirudh 'Ship It' completed end-to-end: OK")
	# 2) A favour, offered and completed through its own action.
	var chirag := _p3_npc_by_name("Chirag")
	var fav := _p3_offer_favour(chirag)
	var match_str := str(fav["match"])
	if match_str.begins_with("talk_to:"):
		_p3_on_talk(_p3_npc_by_name(match_str.substr(8)))
	elif match_str.begins_with("visit:"):
		_player.global_position = ZONE_CENTERS[match_str.substr(6)]
		_p3_on_action(match_str)
	else:
		_p3_on_action("job")
	if _p3_favours_done < 1:
		print("[TEST_P3_FAIL] favour was not completed via its action (", match_str, ")")
		ok = false
	else:
		print("[TEST_P3_FAVOUR] favour '", str(fav["title"]), "' via ", match_str, ": OK")
	# 3) Invitation kept, then one broken.
	var zannat := _p3_npc_by_name("Zannat")
	zannat.friendship = 30
	_p3_invite_text(zannat)
	var kept := false
	for plan in _p3_invitations:
		var p: Dictionary = plan
		if str(p["with"]) == "Zannat":
			p["day_due"] = day
			kept = true
	if not kept:
		print("[TEST_P3_FAIL] player invitation to Zannat was not created")
		ok = false
	_p3_on_talk(zannat)
	for plan in _p3_invitations:
		if str((plan as Dictionary)["with"]) == "Zannat":
			print("[TEST_P3_FAIL] kept invitation was not cleared on talking")
			ok = false
	print("[TEST_P3_INVITE] invitation kept via talk: OK")
	_p3_invitations.append({"with": "Jatin", "kind": "chai at the Food Court", "zone": "foodcourt", "day_due": day - 1, "from": "npc"})
	var soc_before := social
	_p3_expire_plans()
	if soc_before - social != 3.0:
		print("[TEST_P3_FAIL] broken invitation did not cost exactly social -3 (", soc_before, " -> ", social, ")")
		ok = false
	else:
		print("[TEST_P3_INVITE] broken invitation: social -3, gossip posted: OK")
	# 4) Gossip effect.
	soc_before = social
	_p3_add_gossip("Test gossip: the test suite stood someone up, deliberately.", -2.0)
	if social != soc_before - 2.0:
		print("[TEST_P3_FAIL] gossip delta not applied")
		ok = false
	else:
		print("[TEST_P3_GOSSIP] gossip delta -2 applied, feed post present: OK")
	# 5) Storyline: orientation -> fest event -> exams prep; results locked.
	var rag := _p3_npc_by_name("Prof. Raghavan")
	_p3_on_talk(rag)
	if _p3_story_idx != 1:
		print("[TEST_P3_FAIL] storyline orientation step did not complete (idx=", _p3_story_idx, ")")
		ok = false
	_p3_attend_event(Phase3Data.group_events()[0])
	if _p3_story_idx != 2:
		print("[TEST_P3_FAIL] storyline fest step did not complete on group event (idx=", _p3_story_idx, ")")
		ok = false
	_p3_on_action("study")
	if _p3_story_idx != 3:
		print("[TEST_P3_FAIL] storyline exams-prep step did not complete on study (idx=", _p3_story_idx, ")")
		ok = false
	if _p3_story_idx == 4:
		print("[TEST_P3_FAIL] storyline results step completed before Day 70")
		ok = false
	else:
		print("[TEST_P3_STORY] storyline 3/4 done, Results locked until Day 70: OK")
	# 6) Romance gating: refused before arc done, accepted after.
	var aarya := _p3_npc_by_name("Aarya")
	aarya.friendship = 80
	var refused := _p3_try_romance(aarya)
	if _romance_partner != "":
		print("[TEST_P3_FAIL] romance accepted before arc completion")
		ok = false
	_p3_on_talk(aarya)
	_p3_on_action("job")
	if not bool(_p3_arc_done.get("Aarya", false)):
		print("[TEST_P3_FAIL] Aarya arc did not complete via talk+job")
		ok = false
	_p3_try_romance(aarya)
	if _romance_partner != "Aarya":
		print("[TEST_P3_FAIL] romance not accepted after arc + friendship 80")
		ok = false
	else:
		print("[TEST_P3_ROMANCE] refused first ('", refused.substr(0, 40), "…'), accepted after arc: OK")
	# 7) City-gate trip: real cost, gate requirement honoured.
	_player.global_position = ZONE_CENTERS["gate"]
	var money_before := money
	_do_city_trip("bookstore")
	if money != money_before - 180:
		print("[TEST_P3_FAIL] bookstore trip did not cost exactly ₹180 (", money_before, " -> ", money, ")")
		ok = false
	else:
		print("[TEST_P3_CITY] bookstore trip ₹180, effects applied: OK")
	# 8) Fest practice via a practice event.
	_p3_attend_event(Phase3Data.group_events()[1])
	if _fest_practice < 1:
		print("[TEST_P3_FAIL] fest practice did not increment on Art Jam")
		ok = false
	else:
		print("[TEST_P3_FEST] fest practice=", _fest_practice, ": OK")
	print("[TEST_P3] social posts: ", _p3_social_posts.size(), " gossip entries: ", _p3_gossip_log.size(), " storyline idx: ", _p3_story_idx)
	if _p3_social_posts.size() < 8:
		print("[TEST_P3_FAIL] too few social-feed posts generated")
		ok = false
	print("[TEST_P3] RESULT: ", "PASS" if ok else "FAIL")
	return ok

# ---------------- Phase 4 systems ----------------
# Full Semester: clubs, sports, exams, weather-driven crowds, the city
# district, customisation, dorm life, week/semester summaries, continued
# arcs, and the 12-week playthrough harness. No Phase 5 work lives here.

const _P4_ROOM_SPOT := Vector3(-58, 0, 14)

func _p4_bump(key: String, n: int = 1) -> void:
	_p4_week[key] = int(_p4_week.get(key, 0)) + n
	_p4_sem[key] = int(_p4_sem.get(key, 0)) + n

func _p4_add_skill_xp(skill: String, n: int) -> void:
	if n <= 0:
		return
	_skill_xp[skill] = int(_skill_xp.get(skill, 0)) + n
	if int(_skill_xp[skill]) % 3 == 0 and int(skills[skill]) < 10:
		skills[skill] = int(skills[skill]) + 1
		_show_toast("%s skill up! Now level %d." % [skill, int(skills[skill])])

# --- continued arcs (steps 3-6; gated on the Phase 3 base arc) ---

func _p4_ext_steps_for(nm: String) -> Array:
	var table: Dictionary = Phase4Data.arc_extensions()
	if table.has(nm):
		return (table[nm] as Dictionary)["steps"]
	return []

func _p4_ext_prog(nm: String) -> int:
	return int(_p4_ext_progress.get(nm, 0))

func _p4_complete_ext_step(nm: String) -> String:
	var steps: Array = _p4_ext_steps_for(nm)
	var prog := _p4_ext_prog(nm)
	if prog >= steps.size():
		return ""
	var step: Dictionary = steps[prog]
	var reward := _p3_apply_reward(step, nm)
	prog += 1
	_p4_ext_progress[nm] = prog
	if prog >= steps.size():
		_p4_ext_done[nm] = true
		social = minf(100.0, social + 5.0)
		_p3_post(nm, "Finished the continued story '%s' with you." % str(Phase4Data.arc_extensions()[nm]["title"]))
		_show_mission("Story complete: %s" % str(step["title"]), "%s's continued arc is finished! %s" % [nm, reward])
		return "📖 Story complete: %s — %s's continued arc is finished! (%s, social +5.)" % [str(step["title"]), nm, reward]
	_p3_post(nm, "Story update: %s — %s." % [str(step["title"]), str(step["desc"])])
	_show_toast("📖 Story progress: %s (%s)" % [str(step["title"]), reward])
	return "📖 Story progress: %s (%s)" % [str(step["title"]), reward]

func _p4_advance_extensions(action: String, actor: String = "") -> int:
	var count := 0
	for nm in Phase4Data.arc_extensions().keys():
		var sname := str(nm)
		if not bool(_p3_arc_done.get(sname, false)):
			continue
		var steps: Array = _p4_ext_steps_for(sname)
		var prog := _p4_ext_prog(sname)
		if prog < steps.size():
			var st: Dictionary = steps[prog]
			if str(st["action"]) == action and (str(st.get("target", "")) == "" or str(st.get("target", "")) == actor or action.begins_with("visit:")):
				_p4_complete_ext_step(sname)
				count += 1
	return count

# --- day-start: weather, exams, sports week, summaries ---

func _p4_on_day_start() -> void:
	_p4_weather = Phase4Data.weather_for_day(day)
	if _p4_weather == "rain":
		stress = minf(100.0, stress + 2.0)
		_add_message("Northbridge Admin", "Rain on campus today — outdoor sessions are dulled and crowds move indoors (quad/gardens/sports head inside).")
	if day == 49:
		_add_message("Northbridge Admin", "Heads up: mid-semester exams begin Day 52 (Wed–Fri, Week 8) in your lecture block. Revise, sleep, breathe.")
	if day == 75:
		_add_message("Northbridge Admin", "Heads up: final exams begin Day 78 (Mon–Fri, Week 12) in your lecture block. Everything counts now.")
	if Phase4Data.midsem_days().has(day) or Phase4Data.final_days().has(day):
		_add_message("Northbridge Admin", "Exam today: %s — sit it in your lecture block (09:00–16:00)." % str(Phase2Data.major_info(player_major)["subjects"][0]))
	if day == Phase4Data.midsem_results_day():
		var avg := 0
		if _p4_midsem_count > 0:
			avg = _p4_midsem_total / _p4_midsem_count
		_p4_midsem_result = "Mid-semester average %d%% over %d paper(s)%s." % [avg, _p4_midsem_count, "" if _p4_midsem_count > 0 else " — you sat no mid-sem papers"]
		gpa = clampf(gpa * 0.85 + (float(avg) / 10.0) * 0.15, 0.0, 10.0)
		_add_message("Northbridge Admin", "Mid-semester results: %s (GPA now %.2f.)" % [_p4_midsem_result, gpa])
		_p3_post("Northbridge Admin", "Mid-semester results are out. %s" % _p4_midsem_result)
	if day == Phase4Data.final_results_day():
		var avg2 := 0
		if _p4_final_count > 0:
			avg2 = _p4_final_total / _p4_final_count
		_p4_final_results = "Final average %d%% over %d paper(s)%s." % [avg2, _p4_final_count, "" if _p4_final_count > 0 else " — you sat no final papers"]
		gpa = clampf(gpa * 0.80 + (float(avg2) / 10.0) * 0.20, 0.0, 10.0)
		var verdict := "A semester scraped through — but finished." if gpa < 7.0 else ("A solid semester, well lived." if gpa < 8.5 else "A first-class semester. Northbridge applauds you.")
		var summary := "SEMESTER COMPLETE — lectures %d, study %d, clubs %d, sports %d, shifts %d, earned ₹%d, city trips %d. Final GPA %.2f. %s %s" % [int(_p4_sem["lectures"]), int(_p4_sem["study"]), int(_p4_sem["clubs"]), int(_p4_sem["sports"]), int(_p4_sem["jobs"]), int(_p4_sem["earned"]), _p4_city_visits, gpa, _p4_final_results, verdict]
		_add_message("Northbridge Admin", "Final results: %s %s" % [_p4_final_results, verdict])
		_add_message("Northbridge Admin", summary)
		_p3_post("Northbridge Admin", summary)
	if day == 64:
		_add_message("Northbridge Admin", "Sports Meet Week begins (Days 64–70)! Sports sessions count double XP — 3+ sessions earns the meet prize.")
	if day == 71:
		if _p4_sports_week_sessions >= 3 and not _p4_sports_week_award:
			_p4_sports_week_award = true
			social = minf(100.0, social + 10.0)
			money += 200
			_add_message("Northbridge Admin", "Sports Meet prize! You attended %d sessions during Sports Meet Week — social +10, ₹200 prize." % _p4_sports_week_sessions)
			_p3_post("Campus Events", "Sports Meet prize: %s showed up all week. %s" % [player_name, "Meet champion!" if _p4_sports_week_sessions >= 5 else "Well played."])
		elif not _p4_sports_week_award:
			_add_message("Northbridge Admin", "Sports Meet Week ended — you attended %d sessions (3+ earns the prize)." % _p4_sports_week_sessions)
	var weekday := (day - 1) % 7
	if weekday == 0 and day > 1:
		var week_no := (day - 1) / 7
		var s := "Week %d summary: %d lectures, %d study sessions, %d club sessions, %d sports sessions, %d shifts, ₹%d earned, %d exams. GPA %.2f." % [week_no, int(_p4_week["lectures"]), int(_p4_week["study"]), int(_p4_week["clubs"]), int(_p4_week["sports"]), int(_p4_week["jobs"]), int(_p4_week["earned"]), int(_p4_week["exams"]), gpa]
		_p4_week_summaries.append(s)
		_add_message("Northbridge Admin", s)
		_p4_week = {"lectures": 0, "study": 0, "clubs": 0, "sports": 0, "jobs": 0, "earned": 0, "exams": 0}
	# A room visit that outlived its day quietly lapses.
	if _p4_room_guest != "" and _p4_room_guest_day < day:
		_p4_room_guest = ""
		_p4_room_guest_day = -1

# --- clubs ---

func _p4_club_session(cid: String) -> void:
	var clubs: Dictionary = Phase4Data.clubs()
	if cid == "" or not clubs.has(cid):
		return
	var c: Dictionary = clubs[cid]
	var hour := game_minutes / 60.0
	if _player_zone() != str(c["venue"]) or hour < float(c["hour_start"]) or hour >= float(c["hour_end"]):
		_show_toast("The %s session is at the %s, %.0f:00–%.0f:00." % [str(c["title"]), str(c["venue"]), float(c["hour_start"]), float(c["hour_end"])])
		return
	if not _p4_clubs_joined.has(cid):
		if _p4_clubs_joined.size() >= 2:
			_show_toast("You are already in two clubs — the semester rule is one or two. (No drop-out desk yet; pick your two well.)")
			return
		_p4_clubs_joined.append(cid)
		_show_toast("Joined the %s! Weekly sessions: %s." % [str(c["title"]), str(c["desc"])])
	var key := "%d_%s" % [day, cid]
	if _p4_club_attended.has(key):
		_show_toast("You already attended this session today.")
		return
	if energy < 6.0:
		_show_toast("Too tired for a club session. Eat or rest first.")
		return
	_p4_club_attended.append(key)
	_p4_club_sessions += 1
	_p4_bump("clubs")
	energy = maxf(0.0, energy - 6.0)
	var outdoor := str(c["venue"]) in ["quad", "sports", "garden"]
	if _p4_weather == "rain" and outdoor:
		_show_toast("Rain dulled the %s session — good turnout anyway, but no skill XP in the wet." % str(c["title"]))
	else:
		_p4_add_skill_xp(str(c["skill"]), 1)
	social = minf(100.0, social + 2.0)
	if bool(c["practice"]):
		_fest_practice += 1
	_p3_on_action("club:" + cid)
	_show_toast("Session done: %s. Social +2.%s" % [str(c["title"]), " Fest practice +1." if bool(c["practice"]) else ""])
	_refresh_hud()

# --- sports / gym / swim ---

func _p4_sport(kind: String) -> void:
	var sports: Dictionary = Phase4Data.sports()
	if not sports.has(kind):
		return
	var s: Dictionary = sports[kind]
	var anchor: Vector3 = s["anchor"]
	if _player.global_position.distance_to(anchor) > float(s["radius"]):
		_show_toast("Go to the %s first." % str(s["title"]))
		return
	if energy < 10.0:
		_show_toast("Too tired for sport. Eat or rest first.")
		return
	energy = maxf(0.0, energy - 10.0)
	health = minf(100.0, health + 3.0)
	stress = maxf(0.0, stress - 3.0)
	var outdoor := kind != "gym"
	var xp := 0
	if not (_p4_weather == "rain" and outdoor):
		xp = 1
	if Phase4Data.sports_week_days().has(day):
		xp += 1
		_p4_sports_week_sessions += 1
	_p4_add_skill_xp("Sport", xp)
	_p4_sport_sessions += 1
	_p4_bump("sports")
	social = minf(100.0, social + 1.0)
	_p3_on_action("sport:" + kind)
	_show_toast("%s done! Health +3, stress −3, Sport XP +%d.%s" % [str(s["title"]), xp, " Sports Meet Week: double XP!" if Phase4Data.sports_week_days().has(day) else ""])
	_refresh_hud()

# --- exams ---

func _p4_take_exam() -> void:
	var is_mid := Phase4Data.midsem_days().has(day)
	var is_fin := Phase4Data.final_days().has(day)
	if not is_mid and not is_fin:
		_show_toast("No exam today. Mid-sem: Days 52–54. Finals: Days 78–82.")
		return
	var zone := _player_zone()
	if zone != "lecture" and zone != "lectureb" and zone != "lecturec":
		_show_toast("Exams are sat in the lecture blocks — go to your block.")
		return
	var key := "%d" % day
	if _p4_exams_sat.has(key):
		_show_toast("You already sat today's paper.")
		return
	if energy < 5.0:
		_show_toast("Too tired to sit an exam. Eat or rest first.")
		return
	energy = maxf(0.0, energy - 5.0)
	var submitted := 0
	for a in _assignments:
		if bool(a["submitted"]):
			submitted += 1
	var prep := submitted * 8 + int(skills["Study"]) * 3 + clampi(int((gpa - 5.0) * 4.0), -10, 20)
	var marks := clampi(45 + prep, 35, 98)
	_p4_exams_sat[key] = marks
	_p4_bump("exams")
	if is_mid:
		_p4_midsem_total += marks
		_p4_midsem_count += 1
	else:
		_p4_final_total += marks
		_p4_final_count += 1
	_p3_on_action("exam_midsem" if is_mid else "exam_final")
	_show_toast("Paper submitted: %s — %s exam, Day %d. Marks are computed from attendance, study and submitted work." % [str(Phase2Data.major_info(player_major)["subjects"][0]), "Mid-semester" if is_mid else "Final", day])
	_refresh_hud()

# --- city bus route ---

func _p4_bus_to_city() -> void:
	if _player_zone() != "gate":
		_show_toast("City buses leave from the Main Gate bus loop.")
		return
	var fare := Phase4Data.city_bus_fare()
	if money < fare:
		_show_toast("Bus fare is ₹%d. You have ₹%d." % [fare, money])
		return
	money -= fare
	_p4_city_visits += 1
	_player.global_position = Vector3(0, 0.1, 120)
	_show_toast("🚌 Route 12 to MG Road (−₹%d). Clothing store, café street, apartments and the park — welcome to the city district." % fare)
	_p3_check_zone("city", true)
	_refresh_hud()

func _p4_bus_to_campus() -> void:
	if _player_zone() != "city":
		_show_toast("The return bus leaves from the MG Road terminus.")
		return
	var fare := Phase4Data.city_bus_fare()
	if money < fare:
		_show_toast("Bus fare is ₹%d. You have ₹%d." % [fare, money])
		return
	money -= fare
	_player.global_position = Vector3(0, 0.1, 88)
	_show_toast("🚌 Route 12 back to campus (−₹%d). The bus drops you at the Main Gate." % fare)
	_refresh_hud()

# --- shops: outfits, hairstyles, décor, café ---

func _p4_player_cfg() -> Dictionary:
	var presets: Array = Phase2Data.appearance_presets()
	var idx := clampi(_appearance_idx, 0, presets.size() - 1)
	var pr: Dictionary = presets[idx]
	var shirt: Color = pr["shirt"]
	var pants := Color(0.20, 0.22, 0.35)
	var hair_style: int = pr["hair_style"]
	if _p4_outfit >= 0 and _p4_outfit < Phase4Data.outfits().size():
		var o: Dictionary = Phase4Data.outfits()[_p4_outfit]
		shirt = o["shirt"]
		pants = o["pants"]
	if _p4_hairstyle >= 0:
		hair_style = _p4_hairstyle
	return {"height": 1.74, "build": 1.0, "skin": pr["skin"], "hair_style": hair_style, "hair_color": Color(0.07, 0.05, 0.04), "shirt": shirt, "pants": pants, "female": pr["female"], "backpack": true, "pack_color": Color(0.25, 0.25, 0.28)}

func _p4_apply_custom_appearance() -> void:
	_player.apply_appearance(_p4_player_cfg())

func _p4_buy_outfit(idx: int) -> void:
	var outfits: Array = Phase4Data.outfits()
	if idx < 0 or idx >= outfits.size():
		return
	var o: Dictionary = outfits[idx]
	if not _p4_outfits_owned.has(idx):
		if money < int(o["price"]):
			_show_toast("Not enough money for %s (₹%d). You have ₹%d." % [str(o["label"]), int(o["price"]), money])
			return
		money -= int(o["price"])
		_p4_outfits_owned.append(idx)
	_p4_outfit = idx
	_p4_apply_custom_appearance()
	_p3_on_action("customise")
	_show_toast("Now wearing: %s. It stays in your wardrobe — re-wear it free any time." % str(o["label"]))
	_p4_open_shop()
	_refresh_hud()

func _p4_buy_hairstyle(idx: int) -> void:
	var styles: Array = Phase4Data.hairstyles()
	if idx < 0 or idx >= styles.size():
		return
	var st: Dictionary = styles[idx]
	if not _p4_hairstyles_owned.has(int(st["style"])):
		if money < int(st["price"]):
			_show_toast("Not enough money for %s (₹%d). You have ₹%d." % [str(st["label"]), int(st["price"]), money])
			return
		money -= int(st["price"])
		_p4_hairstyles_owned.append(int(st["style"]))
	_p4_hairstyle = int(st["style"])
	_p4_apply_custom_appearance()
	_p3_on_action("customise")
	_show_toast("New hairstyle: %s. Re-wear it free any time." % str(st["label"]))
	_p4_open_shop()
	_refresh_hud()

func _p4_buy_decor(id: String) -> void:
	for item in Phase4Data.decor_items():
		var it: Dictionary = item
		if str(it["id"]) == id:
			if _p4_decor_owned.has(id):
				_p4_place_decor(id)
				return
			if money < int(it["price"]):
				_show_toast("Not enough money for %s (₹%d). You have ₹%d." % [str(it["label"]), int(it["price"]), money])
				return
			money -= int(it["price"])
			_p4_decor_owned.append(id)
			_p4_decor_placed.append(id)
			_p4_refresh_dorm_decor()
			_show_toast("Bought + placed: %s. It is in your dorm room now — store it from this panel any time." % str(it["label"]))
			_p4_open_shop()
			_refresh_hud()
			return

func _p4_place_decor(id: String) -> void:
	if not _p4_decor_owned.has(id) or _p4_decor_placed.has(id):
		return
	_p4_decor_placed.append(id)
	_p4_refresh_dorm_decor()
	_show_toast("Placed in your room.")
	_p4_open_shop()

func _p4_store_decor(id: String) -> void:
	if not _p4_decor_placed.has(id):
		return
	_p4_decor_placed.erase(id)
	_p4_refresh_dorm_decor()
	_show_toast("Stored. It stays in your inventory — place it again any time.")
	_p4_open_shop()

func _p4_buy_snack(idx: int) -> void:
	var snacks: Array = Phase4Data.cafe_snacks()
	if idx < 0 or idx >= snacks.size():
		return
	var s: Dictionary = snacks[idx]
	if money < int(s["price"]):
		_show_toast("Not enough money for %s (₹%d). You have ₹%d." % [str(s["label"]), int(s["price"]), money])
		return
	money -= int(s["price"])
	energy = minf(100.0, energy + float(s["energy"]))
	health = minf(100.0, health + float(s["health"]))
	stress = clampf(stress + float(s["stress"]), 0.0, 100.0)
	social = clampf(social + float(s["social"]), 0.0, 100.0)
	_show_toast("%s! −₹%d, energy +%d." % [str(s["label"]), int(s["price"]), int(s["energy"])])
	_refresh_hud()

func _p4_open_shop() -> void:
	if _shop_panel == null:
		return
	for child in _shop_list.get_children():
		child.queue_free()
	_shop_title.text = "🛍️ CITY SHOPS — MG Road • You have ₹%d" % money
	var add_btn := func(text: String, fn: Callable) -> void:
		var b := Button.new()
		b.text = text
		b.pressed.connect(fn)
		_shop_list.add_child(b)
	_shop_list.add_child(_mk_label("OUTFITS (city clothing store — buy once, re-wear free):", 16, Color(1.0, 0.95, 0.7)))
	add_btn.call("Creation outfit (free)", func() -> void: _p4_outfit = -1; _p4_apply_custom_appearance(); _p4_open_shop(); _refresh_hud())
	for i in range(Phase4Data.outfits().size()):
		var o: Dictionary = Phase4Data.outfits()[i]
		var owned := _p4_outfits_owned.has(i)
		var worn := _p4_outfit == i
		add_btn.call("%s — ₹%d%s%s" % [str(o["label"]), int(o["price"]), " (owned — wear)" if owned and not worn else "", " (wearing)" if worn else ""], _p4_buy_outfit.bind(i))
	_shop_list.add_child(_mk_label("HAIRSTYLES:", 16, Color(1.0, 0.95, 0.7)))
	add_btn.call("Creation hairstyle (free)", func() -> void: _p4_hairstyle = -1; _p4_apply_custom_appearance(); _p4_open_shop(); _refresh_hud())
	for i in range(Phase4Data.hairstyles().size()):
		var st: Dictionary = Phase4Data.hairstyles()[i]
		var owned2 := _p4_hairstyles_owned.has(int(st["style"]))
		var worn2 := _p4_hairstyle == int(st["style"])
		add_btn.call("%s — ₹%d%s%s" % [str(st["label"]), int(st["price"]), " (owned — wear)" if owned2 and not worn2 else "", " (wearing)" if worn2 else ""], _p4_buy_hairstyle.bind(i))
	_shop_list.add_child(_mk_label("DORM DÉCOR (buy once, place/store freely):", 16, Color(1.0, 0.95, 0.7)))
	for item in Phase4Data.decor_items():
		var it: Dictionary = item
		var id := str(it["id"])
		if _p4_decor_placed.has(id):
			add_btn.call("%s — placed in room (Store it)" % str(it["label"]), _p4_store_decor.bind(id))
		elif _p4_decor_owned.has(id):
			add_btn.call("%s — owned, stored (Place it)" % str(it["label"]), _p4_place_decor.bind(id))
		else:
			add_btn.call("%s — ₹%d (buy + place)" % [str(it["label"]), int(it["price"])], _p4_buy_decor.bind(id))
	_shop_list.add_child(_mk_label("CAFÉ STREET SNACKS:", 16, Color(1.0, 0.95, 0.7)))
	for i in range(Phase4Data.cafe_snacks().size()):
		var s: Dictionary = Phase4Data.cafe_snacks()[i]
		add_btn.call("%s — ₹%d (+%d energy)" % [str(s["label"]), int(s["price"]), int(s["energy"])], _p4_buy_snack.bind(i))
	_shop_panel.visible = true

# --- dorm décor meshes (placed around the player's room corner) ---

func _p4_decor_mesh(mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	_p4_decor_node.add_child(mi)

func _p4_refresh_dorm_decor() -> void:
	if _p4_decor_node == null:
		_p4_decor_node = Node3D.new()
		_p4_decor_node.name = "DormDecor"
		add_child(_p4_decor_node)
	for child in _p4_decor_node.get_children():
		child.queue_free()
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 12
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 12
	sph.rings = 8
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.42, 0.30)
	wood.roughness = 0.85
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.20, 0.45, 0.18)
	leaf.roughness = 1.0
	var pot := StandardMaterial3D.new()
	pot.albedo_color = Color(0.65, 0.35, 0.20)
	pot.roughness = 0.9
	var rug_m := StandardMaterial3D.new()
	rug_m.albedo_color = Color(0.60, 0.25, 0.30)
	rug_m.roughness = 1.0
	var lamp_glow := StandardMaterial3D.new()
	lamp_glow.albedo_color = Color(1.0, 0.9, 0.6)
	lamp_glow.emission_enabled = true
	lamp_glow.emission = Color(1.0, 0.85, 0.5)
	lamp_glow.emission_energy_multiplier = 1.2
	for id in _p4_decor_placed:
		match str(id):
			"plant":
				_p4_decor_mesh(cyl, pot, Vector3(-61, 0.25, 13), Vector3(0.56, 0.5, 0.56))
				_p4_decor_mesh(sph, leaf, Vector3(-61, 0.85, 13), Vector3(0.9, 0.8, 0.9))
				_p4_decor_mesh(sph, leaf, Vector3(-61.3, 0.65, 13.2), Vector3(0.5, 0.45, 0.5))
			"lamp":
				_p4_decor_mesh(cyl, wood, Vector3(-55.5, 0.8, 13), Vector3(0.1, 1.6, 0.1))
				_p4_decor_mesh(sph, lamp_glow, Vector3(-55.5, 1.7, 13), Vector3(0.36, 0.36, 0.36))
			"rug":
				_p4_decor_mesh(box, rug_m, Vector3(-61.5, 0.03, 16), Vector3(2.2, 0.06, 1.6))
			"shelf":
				_p4_decor_mesh(box, wood, Vector3(-55.8, 0.9, 17.5), Vector3(1.2, 1.8, 0.4))
				_p4_decor_mesh(box, rug_m, Vector3(-56.1, 0.6, 17.5), Vector3(0.3, 0.5, 0.3))
				_p4_decor_mesh(box, leaf, Vector3(-55.5, 0.6, 17.5), Vector3(0.3, 0.5, 0.3))

# --- dorm: invite a friend to your room ---

func _p4_invite_room(npc: NPC) -> String:
	if npc == null or not npc.is_main:
		return "Room visits are for the Ten — invite a main character."
	var nm := str(npc.data["name"])
	if npc.friendship < 20:
		return "%s is not sure yet — build a little friendship first (need 20, you are at %d)." % [nm, npc.friendship]
	if _p4_room_guest != "":
		return "You already have %s coming over. One guest at a time — the room is small." % _p4_room_guest
	_p4_room_guest = nm
	_p4_room_guest_day = day
	npc.target_zone = "dorm"
	npc.spot = _P4_ROOM_SPOT
	npc.set_path(_path_to(npc.global_position, "dorm", _P4_ROOM_SPOT))
	return "🏠 You invited %s to your room. They are walking over — be in the Residence Hall when they arrive." % nm

func _p4_check_room_guest() -> void:
	if _p4_room_guest == "":
		return
	var guest := _p3_npc_by_name(_p4_room_guest)
	if guest == null:
		_p4_room_guest = ""
		return
	if _p4_room_guest_day < day:
		_p4_room_guest = ""
		_p4_room_guest_day = -1
		return
	if guest.global_position.distance_to(_P4_ROOM_SPOT) < 4.0 and _player_zone() == "dorm":
		guest.friendship = mini(100, guest.friendship + 4)
		social = minf(100.0, social + 2.0)
		_p3_post(_p4_room_guest, "Hung out in your dorm room — %s. Rooms tell the truth about people." % _p4_room_guest)
		_show_toast("🏠 %s is in your room! Friendship +4, social +2." % _p4_room_guest)
		_p4_room_invite_done = true
		_p4_room_guest = ""
		_p4_room_guest_day = -1

# --- save deltas (Phase 4 block rides the Phase 2 delta system) ---

func _p4_collect_state() -> Dictionary:
	return {
		"weather": _p4_weather, "clubs_joined": _p4_clubs_joined.duplicate(),
		"club_attended": _p4_club_attended.duplicate(), "club_sessions": _p4_club_sessions,
		"sport_sessions": _p4_sport_sessions, "sports_week_sessions": _p4_sports_week_sessions,
		"sports_week_award": _p4_sports_week_award, "exams_sat": _p4_exams_sat.duplicate(),
		"midsem_total": _p4_midsem_total, "midsem_count": _p4_midsem_count,
		"final_total": _p4_final_total, "final_count": _p4_final_count,
		"midsem_result": _p4_midsem_result, "final_results": _p4_final_results,
		"week": _p4_week.duplicate(), "sem": _p4_sem.duplicate(),
		"week_summaries": _p4_week_summaries.duplicate(), "city_visits": _p4_city_visits,
		"outfit": _p4_outfit, "hairstyle": _p4_hairstyle,
		"outfits_owned": _p4_outfits_owned.duplicate(), "hairstyles_owned": _p4_hairstyles_owned.duplicate(),
		"decor_owned": _p4_decor_owned.duplicate(), "decor_placed": _p4_decor_placed.duplicate(),
		"room_guest": _p4_room_guest, "room_guest_day": _p4_room_guest_day,
		"room_invite_done": _p4_room_invite_done,
		"ext_progress": _p4_ext_progress.duplicate(), "ext_done": _p4_ext_done.duplicate()
	}

func _p4_apply_state(d: Dictionary) -> void:
	_p4_weather = str(d.get("weather", "clear"))
	_p4_clubs_joined = (d.get("clubs_joined", []) as Array).duplicate()
	_p4_club_attended = (d.get("club_attended", []) as Array).duplicate()
	_p4_club_sessions = int(d.get("club_sessions", 0))
	_p4_sport_sessions = int(d.get("sport_sessions", 0))
	_p4_sports_week_sessions = int(d.get("sports_week_sessions", 0))
	_p4_sports_week_award = bool(d.get("sports_week_award", false))
	_p4_exams_sat = (d.get("exams_sat", {}) as Dictionary).duplicate()
	_p4_midsem_total = int(d.get("midsem_total", 0))
	_p4_midsem_count = int(d.get("midsem_count", 0))
	_p4_final_total = int(d.get("final_total", 0))
	_p4_final_count = int(d.get("final_count", 0))
	_p4_midsem_result = str(d.get("midsem_result", ""))
	_p4_final_results = str(d.get("final_results", ""))
	_p4_week = (d.get("week", {}) as Dictionary).duplicate()
	_p4_sem = (d.get("sem", {}) as Dictionary).duplicate()
	_p4_week_summaries = (d.get("week_summaries", []) as Array).duplicate()
	_p4_city_visits = int(d.get("city_visits", 0))
	_p4_outfit = int(d.get("outfit", -1))
	_p4_hairstyle = int(d.get("hairstyle", -1))
	_p4_outfits_owned = (d.get("outfits_owned", []) as Array).duplicate()
	_p4_hairstyles_owned = (d.get("hairstyles_owned", []) as Array).duplicate()
	_p4_decor_owned = (d.get("decor_owned", []) as Array).duplicate()
	_p4_decor_placed = (d.get("decor_placed", []) as Array).duplicate()
	_p4_room_guest = str(d.get("room_guest", ""))
	_p4_room_guest_day = int(d.get("room_guest_day", -1))
	_p4_room_invite_done = bool(d.get("room_invite_done", false))
	_p4_ext_progress = (d.get("ext_progress", {}) as Dictionary).duplicate()
	_p4_ext_done = (d.get("ext_done", {}) as Dictionary).duplicate()

func _p4_after_load() -> void:
	if _p4_outfit >= 0 or _p4_hairstyle >= 0:
		_p4_apply_custom_appearance()
	_p4_refresh_dorm_decor()

# --- Phase 4 headless tests ---

func _run_phase4_tests() -> bool:
	var ok := true
	print("[TEST_P4] Phase 4 checks: clubs, sports, weather, tiers, city, exams, summaries, extensions, dorm, persistence")
	# 1) Clubs: 8 defined, join two, third refused, attendance counted.
	if Phase4Data.clubs().size() != 8:
		print("[TEST_P4_FAIL] expected 8 clubs, got ", Phase4Data.clubs().size())
		ok = false
	energy = 95.0
	var tech_before := int(_skill_xp.get("Tech", 0))
	_player.global_position = ZONE_CENTERS["union"]
	game_minutes = 16.3 * 60.0
	_p4_club_session("coding")
	if not _p4_clubs_joined.has("coding") or _p4_club_sessions < 1:
		print("[TEST_P4_FAIL] coding club join/attend failed")
		ok = false
	if int(_skill_xp.get("Tech", 0)) <= tech_before:
		print("[TEST_P4_FAIL] coding session gave no Tech XP")
		ok = false
	_player.global_position = ZONE_CENTERS["sports"]
	_p4_club_session("football")
	if not _p4_clubs_joined.has("football"):
		print("[TEST_P4_FAIL] football club join failed")
		ok = false
	var sessions_before := _p4_club_sessions
	_player.global_position = ZONE_CENTERS["quad"]
	_p4_club_session("dance")
	if _p4_clubs_joined.size() != 2 or _p4_club_sessions != sessions_before:
		print("[TEST_P4_FAIL] max-2-clubs rule not enforced")
		ok = false
	print("[TEST_P4] clubs OK: joined=", _p4_clubs_joined, " sessions=", _p4_club_sessions)
	# 2) Sports: all five actions, anchored, XP + health.
	energy = 95.0
	var sport_before := int(_skill_xp.get("Sport", 0))
	var health_before := health
	for kind in ["football", "basketball", "running", "gym", "swim"]:
		var s: Dictionary = Phase4Data.sports()[kind]
		_player.global_position = s["anchor"]
		_p4_sport(kind)
	if _p4_sport_sessions < 5 or int(_skill_xp.get("Sport", 0)) <= sport_before or health <= health_before:
		print("[TEST_P4_FAIL] sports sessions/XP/health did not rise (sessions=", _p4_sport_sessions, ")")
		ok = false
	print("[TEST_P4] sports OK: sessions=", _p4_sport_sessions, " Sport XP=", int(_skill_xp.get("Sport", 0)))
	# 3) Weather table + rain redirect (quad club crowd moves to union).
	if Phase4Data.weather_for_day(1) != "clear" or Phase4Data.weather_for_day(7) != "rain" or Phase4Data.weather_for_day(10) != "rain":
		print("[TEST_P4_FAIL] weather table mismatch (day1=", Phase4Data.weather_for_day(1), " day7=", Phase4Data.weather_for_day(7), ")")
		ok = false
	var bg0: NPC = _bgs[0]
	var old_club: String = str(bg0.data.get("club", "quad"))
	bg0.data["club"] = "quad"
	_p4_weather = "rain"
	game_minutes = 17.0 * 60.0
	_update_schedules()
	if bg0.target_zone != "union":
		print("[TEST_P4_FAIL] rain redirect failed: bg0 target=", bg0.target_zone)
		ok = false
	bg0.data["club"] = old_club
	_p4_weather = "clear"
	print("[TEST_P4] weather OK: day1 clear, day7 rain, rain redirect quad->union")
	# 4) Sim tiers: boundaries + live distance check.
	if _p4_tier_for(20.0) != 0 or _p4_tier_for(50.0) != 1 or _p4_tier_for(100.0) != 2:
		print("[TEST_P4_FAIL] tier boundaries wrong")
		ok = false
	_player.global_position = Vector3(0, 0.1, -5)
	bg0.global_position = Vector3(0, 0.1, -5)
	var bg1: NPC = _bgs[1]
	bg1.global_position = Vector3(58, 0.1, -58)
	_p4_apply_tiers(true)
	if bg0.sim_tier != 0 or bg1.sim_tier != 2:
		print("[TEST_P4_FAIL] live tiers wrong: near=", bg0.sim_tier, " far=", bg1.sim_tier)
		ok = false
	print("[TEST_P4] tiers OK: near 0, far 2")
	# 5) City: bus out, shop buys, bus back.
	money = 5000
	_player.global_position = Vector3(-11, 0.1, 90)
	var money_before := money
	_p4_bus_to_city()
	if money != money_before - Phase4Data.city_bus_fare() or _player.global_position != Vector3(0, 0.1, 120) or _player_zone() != "city":
		print("[TEST_P4_FAIL] bus to city failed: money=", money, " pos=", _player.global_position, " zone=", _player_zone())
		ok = false
	if _p4_city_visits < 1:
		print("[TEST_P4_FAIL] city visit not counted")
		ok = false
	_p4_buy_outfit(0)
	if _p4_outfit != 0 or money != money_before - Phase4Data.city_bus_fare() - int(Phase4Data.outfits()[0]["price"]):
		print("[TEST_P4_FAIL] outfit buy failed: outfit=", _p4_outfit, " money=", money)
		ok = false
	energy = 50.0
	_p4_buy_snack(0)
	if energy <= 50.0:
		print("[TEST_P4_FAIL] café snack gave no energy")
		ok = false
	_p4_buy_decor("plant")
	if not _p4_decor_owned.has("plant") or not _p4_decor_placed.has("plant"):
		print("[TEST_P4_FAIL] décor buy/place failed")
		ok = false
	_p4_store_decor("plant")
	if _p4_decor_placed.has("plant") or not _p4_decor_owned.has("plant"):
		print("[TEST_P4_FAIL] décor store failed")
		ok = false
	_p4_place_decor("plant")
	if not _p4_decor_placed.has("plant"):
		print("[TEST_P4_FAIL] décor re-place failed")
		ok = false
	_player.global_position = Vector3(7, 0.1, 120)
	money_before = money
	_p4_bus_to_campus()
	if money != money_before - Phase4Data.city_bus_fare() or _player.global_position != Vector3(0, 0.1, 88) or _player_zone() != "gate":
		print("[TEST_P4_FAIL] bus back failed: money=", money, " pos=", _player.global_position, " zone=", _player_zone())
		ok = false
	print("[TEST_P4] city OK: visits=", _p4_city_visits, " outfit=", _p4_outfit, " décor placed=", _p4_decor_placed)
	# 6) Exams: 3 mid-sem sittings, results Day 57, 5 finals, results Day 85.
	energy = 95.0
	_player.global_position = ZONE_CENTERS["lecture"]
	for d in [52, 53, 54]:
		day = d
		_p4_take_exam()
	if _p4_exams_sat.size() != 3:
		print("[TEST_P4_FAIL] mid-sem sittings: ", _p4_exams_sat.size())
		ok = false
	for k in _p4_exams_sat.keys():
		if int(_p4_exams_sat[k]) < 35 or int(_p4_exams_sat[k]) > 98:
			print("[TEST_P4_FAIL] marks out of range: ", _p4_exams_sat[k])
			ok = false
	day = 57
	_p4_on_day_start()
	if _p4_midsem_result == "":
		print("[TEST_P4_FAIL] mid-sem results empty")
		ok = false
	energy = 95.0
	for d in [78, 79, 80, 81, 82]:
		day = d
		_p4_take_exam()
	day = 85
	_p4_on_day_start()
	if _p4_final_results == "" or _p4_exams_sat.size() != 8:
		print("[TEST_P4_FAIL] final results/sittings: results='", _p4_final_results, "' sittings=", _p4_exams_sat.size())
		ok = false
	print("[TEST_P4] exams OK: mid='", _p4_midsem_result, "' final='", _p4_final_results, "'")
	# 7) Week summary + Sports Meet award.
	_p4_week["lectures"] = 5
	_p4_week["study"] = 4
	day = 8
	_p4_on_day_start()
	if _p4_week_summaries.is_empty():
		print("[TEST_P4_FAIL] week summary not produced")
		ok = false
	_p4_sports_week_sessions = 4
	day = 71
	_p4_on_day_start()
	if not _p4_sports_week_award:
		print("[TEST_P4_FAIL] sports meet award not given")
		ok = false
	print("[TEST_P4] summaries OK: ", _p4_week_summaries.size(), " award=", _p4_sports_week_award)
	# 8) Continued arcs: 10 x 4 steps; Anirudh end-to-end (club step
	# already done by the club test above, so progress starts at 1).
	var exts: Dictionary = Phase4Data.arc_extensions()
	if exts.size() != 10:
		print("[TEST_P4_FAIL] expected 10 continued arcs, got ", exts.size())
		ok = false
	for nm in exts.keys():
		if (exts[nm] as Dictionary)["steps"].size() != 4:
			print("[TEST_P4_FAIL] continued arc ", nm, " is not 4 steps")
			ok = false
	var ani := _p3_npc_by_name("Anirudh")
	if _p4_ext_prog("Anirudh") != 1:
		print("[TEST_P4_FAIL] Anirudh ext step 1 (club:coding) not recorded: ", _p4_ext_prog("Anirudh"))
		ok = false
	_p3_on_talk(ani)
	if _p4_ext_prog("Anirudh") != 2:
		print("[TEST_P4_FAIL] Anirudh ext step 2 (talk) failed: ", _p4_ext_prog("Anirudh"))
		ok = false
	_p3_on_action("job")
	if _p4_ext_prog("Anirudh") != 3:
		print("[TEST_P4_FAIL] Anirudh ext step 3 (job) failed: ", _p4_ext_prog("Anirudh"))
		ok = false
	_p3_check_zone("union", true)
	if not bool(_p4_ext_done.get("Anirudh", false)):
		print("[TEST_P4_FAIL] Anirudh ext step 4 (visit:union) failed")
		ok = false
	print("[TEST_P4] continued arcs OK: Anirudh complete, all 10 x 4 steps")
	# 9) Dorm invite: guest arrives (teleported, simulated) and is welcomed.
	var invite_text := _p4_invite_room(ani)
	if _p4_room_guest != "Anirudh":
		print("[TEST_P4_FAIL] room invite failed: ", invite_text)
		ok = false
	ani.global_position = _P4_ROOM_SPOT
	_player.global_position = Vector3(-66, 0.1, 18)
	_p4_check_room_guest()
	if _p4_room_guest != "" or not _p4_room_invite_done:
		print("[TEST_P4_FAIL] room guest welcome failed: guest='", _p4_room_guest, "' done=", _p4_room_invite_done)
		ok = false
	print("[TEST_P4] dorm invite OK")
	# 10) Customisation persistence via the save-delta system.
	_p4_outfit = 1
	_p4_hairstyle = 6
	_p4_decor_owned = ["plant", "rug"]
	_p4_decor_placed = ["plant"]
	_p4_clubs_joined = ["coding", "football"]
	_p4_city_visits = 3
	var keep_outfit := _p4_outfit
	var keep_hair := _p4_hairstyle
	var keep_decor: Array = _p4_decor_placed.duplicate()
	var keep_clubs: Array = _p4_clubs_joined.duplicate()
	var keep_visits := _p4_city_visits
	var keep_ext := _p4_ext_prog("Anirudh")
	SaveSystem.save(3, _collect_state())
	_p4_outfit = -1
	_p4_hairstyle = -1
	_p4_decor_owned = []
	_p4_decor_placed = []
	_p4_clubs_joined = []
	_p4_city_visits = 0
	_p4_ext_progress = {}
	var loaded := SaveSystem.load_slot(3)
	if loaded.is_empty():
		print("[TEST_P4_FAIL] save slot 3 did not load")
		ok = false
	else:
		_apply_state(loaded)
		if _p4_outfit != keep_outfit or _p4_hairstyle != keep_hair or _p4_decor_placed != keep_decor or _p4_clubs_joined != keep_clubs or _p4_city_visits != keep_visits or _p4_ext_prog("Anirudh") != keep_ext:
			print("[TEST_P4_FAIL] persistence round-trip mismatch: outfit=", _p4_outfit, " hair=", _p4_hairstyle, " decor=", _p4_decor_placed, " clubs=", _p4_clubs_joined, " visits=", _p4_city_visits, " ext=", _p4_ext_prog("Anirudh"))
			ok = false
	print("[TEST_P4] persistence OK: outfit=", _p4_outfit, " hair=", _p4_hairstyle, " decor=", _p4_decor_placed)
	print("[TEST_P4] Phase 4 result: ", "PASS" if ok else "FAIL")
	return ok

# --- 12-week semester harness (synchronous day-step, NOT real-time) ---

func _p4_reset_for_harness() -> void:
	day = 1
	game_minutes = 450.0
	money = 500
	energy = 95.0
	gpa = 7.5
	health = 80.0
	stress = 30.0
	social = 50.0
	skills = {"Study": 1, "Sport": 1, "Music/Art": 1, "Tech": 1, "Communication": 1}
	_skill_xp = {"Study": 0, "Sport": 0, "Music/Art": 0, "Tech": 0, "Communication": 0}
	player_name = "New Student"
	player_major = "Computer Science"
	_appearance_idx = 0
	_attended_keys = []
	_jobs_today = {}
	_jobs_total = {}
	_earned_total = 0
	_messages = []
	_buzz = []
	_p3_arc_progress = {}
	_p3_arc_done = {}
	_p3_teacher_progress = {}
	_p3_teacher_done = {}
	_p3_story_idx = 0
	_p3_favours = []
	_p3_favours_done = 0
	_p3_invitations = []
	_p3_social_posts = []
	_p3_gossip_log = []
	_p3_events_attended = []
	_fest_practice = 0
	_p3_holi_done = false
	_p3_fest_result = ""
	_romance_partner = ""
	_teacher_letters = []
	_city_trip_day = -1
	_p4_weather = "clear"
	_p4_clubs_joined = []
	_p4_club_attended = []
	_p4_club_sessions = 0
	_p4_sport_sessions = 0
	_p4_sports_week_sessions = 0
	_p4_sports_week_award = false
	_p4_exams_sat = {}
	_p4_midsem_total = 0
	_p4_midsem_count = 0
	_p4_final_total = 0
	_p4_final_count = 0
	_p4_midsem_result = ""
	_p4_final_results = ""
	_p4_week = {"lectures": 0, "study": 0, "clubs": 0, "sports": 0, "jobs": 0, "earned": 0, "exams": 0}
	_p4_sem = {"lectures": 0, "study": 0, "clubs": 0, "sports": 0, "jobs": 0, "earned": 0, "exams": 0}
	_p4_week_summaries = []
	_p4_city_visits = 0
	_p4_outfit = -1
	_p4_hairstyle = -1
	_p4_outfits_owned = []
	_p4_hairstyles_owned = []
	_p4_decor_owned = []
	_p4_decor_placed = []
	_p4_room_guest = ""
	_p4_room_guest_day = -1
	_p4_room_invite_done = false
	_p4_ext_progress = {}
	_p4_ext_done = {}
	_p4_prompt_club = ""
	var mi := 0
	for n in _mains:
		var npc := n as NPC
		npc.friendship = 22 + (mi * 3) % 14
		npc.chats = 0
		npc.compliments_today = 0
		npc.learned_hobby = false
		npc.learned_secret = false
		npc.memory_notes = []
		npc.dialogue_seen = {}
		npc.office_help_day = -1
		npc.talking = false
		npc.stationary = false
		npc.path = []
		npc.seated = false
		npc.sim_tier = 0
		mi += 1
	for n in _teachers:
		var npc := n as NPC
		npc.friendship = 25
		npc.chats = 0
		npc.office_help_day = -1
		npc.talking = false
		npc.path = []
		npc.sim_tier = 0
	for n in _bgs:
		var npc := n as NPC
		npc.talking = false
		npc.stationary = false
		npc.path = []
		npc.seated = false
		npc.sim_tier = 0
	_init_phase2()
	var hour := game_minutes / 60.0
	for n in _all_npcs:
		var npc := n as NPC
		if npc.is_staff or npc.talking:
			continue
		var zone := _segment_for(npc.data, hour)
		var idx := _all_npcs.find(npc)
		var spot: Vector3 = _pick_spot(npc, zone, idx)
		npc.global_position = spot
		npc.spot = spot
		npc.target_zone = zone
		npc.set_path([])
	_player.global_position = Vector3(0, 0.1, 84)
	_p4_apply_custom_appearance()
	_p4_refresh_dorm_decor()
	_refresh_hud()

func _run_semester_harness() -> bool:
	_p4_reset_for_harness()
	var fails: Array = []
	print("[TEST_P4_SEM] 12-week semester harness: synchronous day-step, Days 1-85 (no real-time clock)")
	var ani := _p3_npc_by_name("Anirudh")
	var rag := _p3_npc_by_name("Prof. Raghavan")
	var own_block: String = str(Phase2Data.major_info(player_major)["block"])
	while day <= 85:
		var d := day
		var weekday := (day - 1) % 7
		# Day 1 storyline + base-arc setup: teacher talk, Kickabout
		# check-in (group event), study, Anirudh talk + union visit.
		if d == 1:
			_p3_on_talk(rag)
			_player.global_position = ZONE_CENTERS["sports"]
			game_minutes = 17.3 * 60.0
			_p3_check_in()
			_player.global_position = ZONE_CENTERS["library"]
			_do_study(false)
			_p3_on_talk(ani)
			_p3_check_zone("union", true)
		# Lectures: all three weekday slots, correct answers.
		if weekday < 5:
			_player.global_position = ZONE_CENTERS[own_block]
			for slot in ["am1", "am2", "pm"]:
				_qa_period = slot
				_qa_answer = 1
				_qa_answer_pressed(1)
		# Daily study in the library; submit the moment an assignment
		# hits 100% (due Days 5/12/19 — always on time this way).
		_player.global_position = ZONE_CENTERS["library"]
		_do_study(false)
		var cur: Variant = _current_assignment()
		if cur != null and int(cur["progress"]) >= 100 and not bool(cur["submitted"]):
			_do_submit()
		# Weekday library shift.
		if weekday < 5:
			_player.global_position = ZONE_CENTERS["library"]
			_do_job("library")
		# Clubs: coding Mondays (union 16:00), football Fridays (sports).
		if weekday == 0:
			_player.global_position = ZONE_CENTERS["union"]
			game_minutes = 16.3 * 60.0
			_p4_club_session("coding")
		if weekday == 4:
			_player.global_position = ZONE_CENTERS["sports"]
			game_minutes = 16.3 * 60.0
			_p4_club_session("football")
		# Sports: Mon running, Wed basketball, Fri gym.
		if weekday == 0:
			_player.global_position = Vector3(-52, 0.1, 42)
			_p4_sport("running")
		if weekday == 2:
			_player.global_position = Vector3(-14, 0.1, 34)
			_p4_sport("basketball")
		if weekday == 4:
			_player.global_position = Vector3(-10, 0.1, 44)
			_p4_sport("gym")
		# Fest practice: Art Jam Tuesdays (garden 17:00), Dance Break
		# Fridays (quad 17:00), Open Mic Saturdays (union 17:00).
		if weekday == 1:
			_player.global_position = ZONE_CENTERS["garden"]
			game_minutes = 17.3 * 60.0
			_p3_check_in()
		if weekday == 4:
			_player.global_position = ZONE_CENTERS["quad"]
			game_minutes = 17.3 * 60.0
			_p3_check_in()
		if weekday == 5:
			_player.global_position = ZONE_CENTERS["union"]
			game_minutes = 17.3 * 60.0
			_p3_check_in()
		# Anirudh continued arc, end-to-end, on Day 8 (after the Monday
		# coding session already banked ext step 1).
		if d == 8:
			_p3_on_talk(ani)
			_p3_on_action("job")
			_p3_check_zone("union", true)
		# Dorm invite, Day 10 (guest teleported to the room spot — a
		# simulated arrival — then welcomed with the player in dorm).
		if d == 10:
			_p4_invite_room(ani)
			ani.global_position = _P4_ROOM_SPOT
			_player.global_position = Vector3(-66, 0.1, 18)
			_p4_check_room_guest()
		# City Sundays: bus out, buys on Days 7/14, bus back.
		if weekday == 6:
			_player.global_position = Vector3(-11, 0.1, 90)
			_p4_bus_to_city()
			if d == 7:
				_p4_buy_outfit(0)
			if d == 14:
				_p4_buy_decor("plant")
				_p4_buy_decor("rug")
			_player.global_position = Vector3(7, 0.1, 120)
			_p4_bus_to_campus()
		# Holi, Day 63.
		if d == 63:
			_player.global_position = ZONE_CENTERS["quad"]
			_p3_check_zone("quad", true)
		# Exams on every sitting day.
		if Phase4Data.midsem_days().has(d) or Phase4Data.final_days().has(d):
			_player.global_position = ZONE_CENTERS[own_block]
			_p4_take_exam()
		# End the day in the dorm; _advance_day rolls everything over.
		_player.global_position = Vector3(-66, 0.1, 18)
		_do_sleep()
		if day != d + 1:
			fails.append("day did not advance after sleep on Day %d (now %d)" % [d, day])
			break
	print("[TEST_P4_SEM] harness reached Day ", day, " (loop ended at 86)")
	if day != 86:
		fails.append("final day != 86 (got %d)" % day)
	if _p4_midsem_result == "":
		fails.append("mid-sem results empty")
	if _p4_final_results == "":
		fails.append("final results empty")
	if _p4_week_summaries.size() != 12:
		fails.append("week summaries != 12 (got %d)" % _p4_week_summaries.size())
	if _p3_story_idx != 4:
		fails.append("storyline idx != 4 (got %d)" % _p3_story_idx)
	if _p4_clubs_joined.size() != 2:
		fails.append("clubs != 2 (got %s)" % str(_p4_clubs_joined))
	if _p4_city_visits < 10:
		fails.append("city visits < 10 (got %d)" % _p4_city_visits)
	if _p4_outfit < 0:
		fails.append("no outfit bought")
	if _p4_decor_placed.size() < 2:
		fails.append("décor placed < 2 (got %s)" % str(_p4_decor_placed))
	if not _p4_room_invite_done:
		fails.append("room invite not completed")
	if not bool(_p4_ext_done.get("Anirudh", false)):
		fails.append("Anirudh continued arc not done")
	if _fest_practice < 3:
		fails.append("fest practice < 3 (got %d)" % _fest_practice)
	if not _p4_sports_week_award:
		fails.append("sports meet award not given")
	if _p4_exams_sat.size() != 8:
		fails.append("exams sat != 8 (got %d)" % _p4_exams_sat.size())
	if money < 0:
		fails.append("money negative (₹%d)" % money)
	if gpa < 0.0 or gpa > 10.0:
		fails.append("GPA out of range (%.2f)" % gpa)
	print("[TEST_P4_SEM] final: day=", day, " GPA=%.2f" % gpa, " money=₹", money, " clubs=", _p4_clubs_joined, " city_visits=", _p4_city_visits, " outfit=", _p4_outfit, " decor=", _p4_decor_placed, " exams=", _p4_exams_sat.size(), " summaries=", _p4_week_summaries.size(), " story_idx=", _p3_story_idx, " fest_practice=", _fest_practice, " sports_award=", _p4_sports_week_award)
	print("[TEST_P4_SEM] mid-sem: ", _p4_midsem_result)
	print("[TEST_P4_SEM] final: ", _p4_final_results)
	print("[TEST_P4_SEM] semester totals: ", _p4_sem)
	for f in fails:
		print("[TEST_P4_SEM_FAIL] ", f)
	print("[TEST_P4_SEM] Semester harness result: ", "PASS" if fails.is_empty() else "FAIL")
	return fails.is_empty()

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
	# Phase 2 HUD: GPA / health / stress / social / objective
	_hud_gpa = _mk_label("GPA 7.50 / 10", 18, Color(1.0, 0.9, 0.5))
	vb.add_child(_hud_gpa)
	var hrow := HBoxContainer.new()
	hrow.add_child(_mk_label("Health", 16))
	_hud_health = ProgressBar.new()
	_hud_health.min_value = 0
	_hud_health.max_value = 100
	_hud_health.value = health
	_hud_health.custom_minimum_size = Vector2(150, 14)
	hrow.add_child(_hud_health)
	vb.add_child(hrow)
	var srow := HBoxContainer.new()
	srow.add_child(_mk_label("Stress", 16))
	_hud_stress = ProgressBar.new()
	_hud_stress.min_value = 0
	_hud_stress.max_value = 100
	_hud_stress.value = stress
	_hud_stress.custom_minimum_size = Vector2(150, 14)
	srow.add_child(_hud_stress)
	vb.add_child(srow)
	_hud_social = _mk_label("Social 50", 16, Color(0.8, 0.9, 1.0))
	vb.add_child(_hud_social)
	_hud_objective = _mk_label("🎯 Orientation: talk to a teacher", 15, Color(1.0, 0.85, 0.3))
	_hud_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_objective.custom_minimum_size = Vector2(280, 0)
	vb.add_child(_hud_objective)
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
	var b_phone := Button.new()
	b_phone.text = "📱 Phone (Tab)"
	b_phone.pressed.connect(func() -> void: _phone_panel.visible = not _phone_panel.visible; if _phone_panel.visible: _set_phone_tab(_phone_tab))
	bb.add_child(b_phone)
	var b_save := Button.new()
	b_save.text = "💾 Save"
	b_save.pressed.connect(func() -> void: _save_panel.visible = not _save_panel.visible)
	bb.add_child(b_save)
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
	_class_box.add_child(_mk_label("FACULTY (Phase 2)", 17, Color(1.0, 0.85, 0.35)))
	for t in _teachers:
		var tl := _mk_label("%s — %s" % [str((t as NPC).data["name"]), (t as NPC).subject], 15, Color(1.0, 0.9, 0.6))
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(320, 0)
		_class_box.add_child(tl)
	# dialogue panel
	_dialog_panel = PanelContainer.new()
	_dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialog_panel.position = Vector2(-340, -380)
	_dialog_panel.custom_minimum_size = Vector2(680, 340)
	_dialog_panel.visible = false
	layer.add_child(_dialog_panel)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	_dialog_panel.add_child(dv)
	_dlg_title = _mk_label("", 22, Color(1.0, 0.95, 0.75))
	dv.add_child(_dlg_title)
	_dlg_text = RichTextLabel.new()
	_dlg_text.fit_content = true
	_dlg_text.custom_minimum_size = Vector2(640, 90)
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
	# Phase 2 dialogue second row: topic buttons + office hours (teachers)
	_dlg_btns2 = HBoxContainer.new()
	_dlg_btns2.add_theme_constant_override("separation", 8)
	dv.add_child(_dlg_btns2)
	for spec in [["topic_classes", "📚 Classes"], ["topic_fest", "🎉 Fest & events"], ["topic_gossip", "🗣️ Gossip"], ["topic_personal", "💛 Personal"]]:
		var tb := Button.new()
		tb.text = spec[1]
		# bind (not a lambda): loop-variable capture would give every
		# button the last topic.
		tb.pressed.connect(_dlg_choice.bind(str(spec[0])))
		_dlg_btns2.add_child(tb)
	_dlg_office_btn = Button.new()
	_dlg_office_btn.text = "🎓 Office hours help"
	_dlg_office_btn.pressed.connect(func() -> void: _dlg_choice("office"))
	_dlg_btns2.add_child(_dlg_office_btn)
	# Phase 3 dialogue third row: story / favour / invite / romance / letter
	_dlg_btns3 = HBoxContainer.new()
	_dlg_btns3.add_theme_constant_override("separation", 8)
	dv.add_child(_dlg_btns3)
	for spec in [["p3_story", "📖 Story"], ["p3_favour", "🤝 Favour"], ["p3_invite", "✉️ Invite"]]:
		var pb := Button.new()
		pb.text = spec[1]
		pb.pressed.connect(_dlg_choice.bind(str(spec[0])))
		_dlg_btns3.add_child(pb)
	_dlg_romance_btn = Button.new()
	_dlg_romance_btn.text = "💛 Something more?"
	_dlg_romance_btn.pressed.connect(func() -> void: _dlg_choice("p3_romance"))
	_dlg_btns3.add_child(_dlg_romance_btn)
	_dlg_letter_btn = Button.new()
	_dlg_letter_btn.text = "📜 Recommendation letter"
	_dlg_letter_btn.pressed.connect(func() -> void: _dlg_choice("p3_letter"))
	_dlg_btns3.add_child(_dlg_letter_btn)
	_dlg_btns3.visible = false
	# Phase 4 dialogue fourth row: invite a main to your dorm room.
	_dlg_btns4 = HBoxContainer.new()
	_dlg_btns4.add_theme_constant_override("separation", 8)
	dv.add_child(_dlg_btns4)
	_dlg_invite_btn = Button.new()
	_dlg_invite_btn.text = "🏠 Invite to my room"
	_dlg_invite_btn.pressed.connect(func() -> void: _dlg_choice("p4_invite_room"))
	_dlg_btns4.add_child(_dlg_invite_btn)
	_dlg_btns4.visible = false
	# ---- Phone panel (Tab) ----
	_phone_panel = PanelContainer.new()
	_phone_panel.set_anchors_preset(Control.PRESET_CENTER)
	_phone_panel.position = Vector2(-310, -290)
	_phone_panel.custom_minimum_size = Vector2(620, 580)
	_phone_panel.visible = false
	layer.add_child(_phone_panel)
	var pv := VBoxContainer.new()
	_phone_panel.add_child(pv)
	pv.add_child(_mk_label("📱 PHONE — Northbridge Campus", 20, Color(1.0, 0.95, 0.7)))
	var tabrow := HBoxContainer.new()
	pv.add_child(tabrow)
	for tab in ["Messages", "Buzz", "Calendar", "Map", "Wallet", "Jobs", "Stories", "Social", "City Gate"]:
		var tb2 := Button.new()
		tb2.text = tab
		tb2.pressed.connect(_set_phone_tab.bind(tab))
		tabrow.add_child(tb2)
	_phone_text = RichTextLabel.new()
	_phone_text.fit_content = false
	_phone_text.custom_minimum_size = Vector2(580, 380)
	_phone_text.add_theme_font_size_override("normal_font_size", 16)
	_phone_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(_phone_text)
	_phone_job_row = HBoxContainer.new()
	pv.add_child(_phone_job_row)
	for jid in ["library", "canteen", "tutoring", "freelance"]:
		var jb := Button.new()
		jb.text = str(Phase2Data.jobs()[jid]["title"])
		jb.pressed.connect(_do_job.bind(jid))
		_phone_job_row.add_child(jb)
	_phone_job_row.visible = false
	_phone_city_row = HBoxContainer.new()
	pv.add_child(_phone_city_row)
	for tid in Phase3Data.city_trips().keys():
		var cb := Button.new()
		cb.text = str(Phase3Data.city_trips()[tid]["title"])
		cb.pressed.connect(_do_city_trip.bind(tid))
		_phone_city_row.add_child(cb)
	_phone_city_row.visible = false
	_phone_action_row = HBoxContainer.new()
	pv.add_child(_phone_action_row)
	var ab := Button.new()
	ab.text = "📍 Check in here (group event / festival)"
	ab.pressed.connect(func() -> void: _p3_check_in())
	_phone_action_row.add_child(ab)
	_phone_action_row.visible = false
	# ---- Save / Load panel ----
	_save_panel = PanelContainer.new()
	_save_panel.set_anchors_preset(Control.PRESET_CENTER)
	_save_panel.position = Vector2(-200, -180)
	_save_panel.custom_minimum_size = Vector2(400, 360)
	_save_panel.visible = false
	layer.add_child(_save_panel)
	var sv := VBoxContainer.new()
	_save_panel.add_child(sv)
	sv.add_child(_mk_label("💾 SAVE / LOAD (autosave runs at every sleep)", 17, Color(1.0, 0.95, 0.7)))
	for slot in [1, 2, 3]:
		var srow2 := HBoxContainer.new()
		var sb := Button.new()
		sb.text = "Save slot %d" % slot
		sb.pressed.connect(_save_slot_pressed.bind(slot))
		srow2.add_child(sb)
		var lb := Button.new()
		lb.text = "Load slot %d" % slot
		lb.pressed.connect(_load_slot_pressed.bind(slot))
		srow2.add_child(lb)
		sv.add_child(srow2)
	var svclose := Button.new()
	svclose.text = "Close"
	svclose.pressed.connect(func() -> void: _save_panel.visible = false)
	sv.add_child(svclose)
	# ---- Phase 4 shop panel (city clothing store / café / campus shops) ----
	_shop_panel = PanelContainer.new()
	_shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	_shop_panel.position = Vector2(-280, -300)
	_shop_panel.custom_minimum_size = Vector2(560, 600)
	_shop_panel.visible = false
	layer.add_child(_shop_panel)
	var shv := VBoxContainer.new()
	_shop_panel.add_child(shv)
	_shop_title = _mk_label("🛍️ CITY SHOPS — MG Road", 20, Color(1.0, 0.95, 0.7))
	shv.add_child(_shop_title)
	_shop_list = VBoxContainer.new()
	_shop_list.add_theme_constant_override("separation", 4)
	shv.add_child(_shop_list)
	var shclose := Button.new()
	shclose.text = "Close"
	shclose.pressed.connect(func() -> void: _shop_panel.visible = false)
	shv.add_child(shclose)
	# ---- Character creation panel (normal play only) ----
	_create_panel = PanelContainer.new()
	_create_panel.set_anchors_preset(Control.PRESET_CENTER)
	_create_panel.position = Vector2(-280, -240)
	_create_panel.custom_minimum_size = Vector2(560, 480)
	_create_panel.visible = false
	layer.add_child(_create_panel)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	_create_panel.add_child(cv)
	cv.add_child(_mk_label("🎓 CREATE YOUR STUDENT — Northbridge University", 20, Color(1.0, 0.95, 0.7)))
	cv.add_child(_mk_label("Your name:", 16))
	_create_name = LineEdit.new()
	_create_name.placeholder_text = "e.g. Aarav Sharma"
	_create_name.custom_minimum_size = Vector2(500, 32)
	cv.add_child(_create_name)
	cv.add_child(_mk_label("Your major (decides your lecture block + professor):", 16))
	_create_major = OptionButton.new()
	for m in Phase2Data.majors():
		_create_major.add_item(m)
	cv.add_child(_create_major)
	cv.add_child(_mk_label("Appearance:", 16))
	_create_appear = OptionButton.new()
	for pr in Phase2Data.appearance_presets():
		_create_appear.add_item(str(pr["label"]))
	cv.add_child(_create_appear)
	var start_btn := Button.new()
	start_btn.text = "▶ Start Semester"
	start_btn.pressed.connect(func() -> void: _create_start_pressed())
	cv.add_child(start_btn)
	# ---- Mission popup (GTA-style quest popups) ----
	_mission_panel = PanelContainer.new()
	_mission_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mission_panel.position = Vector2(-320, 90)
	_mission_panel.custom_minimum_size = Vector2(640, 90)
	_mission_panel.visible = false
	layer.add_child(_mission_panel)
	var mv := VBoxContainer.new()
	_mission_panel.add_child(mv)
	_mission_label = _mk_label("", 18, Color(1.0, 0.9, 0.4))
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_label.custom_minimum_size = Vector2(620, 0)
	mv.add_child(_mission_label)
	# ---- Lecture Q&A panel ----
	_qa_panel = PanelContainer.new()
	_qa_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_qa_panel.position = Vector2(-340, -560)
	_qa_panel.custom_minimum_size = Vector2(680, 220)
	_qa_panel.visible = false
	layer.add_child(_qa_panel)
	var qv := VBoxContainer.new()
	_qa_panel.add_child(qv)
	_qa_question = _mk_label("", 18, Color(1.0, 0.95, 0.75))
	_qa_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_qa_question.custom_minimum_size = Vector2(640, 0)
	qv.add_child(_qa_question)
	_qa_btns = HBoxContainer.new()
	_qa_btns.add_theme_constant_override("separation", 8)
	qv.add_child(_qa_btns)
	for qi in range(3):
		var qb := Button.new()
		qb.text = "?"
		qb.pressed.connect(_qa_answer_pressed.bind(qi))
		_qa_btns.add_child(qb)
	# ---- Circular minimap (bottom-right) + quest marker (3D) ----
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap.position = Vector2(-186, -186)
	_minimap.custom_minimum_size = Vector2(172, 172)
	layer.add_child(_minimap)
	_quest_marker = MeshInstance3D.new()
	var qmesh := SphereMesh.new()
	qmesh.radius = 0.55
	qmesh.height = 1.1
	_quest_marker.mesh = qmesh
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = Color(1.0, 0.85, 0.15)
	qmat.emission_enabled = true
	qmat.emission = Color(1.0, 0.8, 0.1)
	qmat.emission_energy_multiplier = 1.6
	_quest_marker.material_override = qmat
	_quest_marker.position = Vector3(0, 3.2, 0)
	add_child(_quest_marker)
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
	if _hud_gpa != null:
		_hud_gpa.text = "GPA %.2f / 10 • %s" % [gpa, player_major]
		_hud_health.value = health
		_hud_stress.value = stress
		_hud_social.text = "Social %d • %s" % [int(social), player_name]
		if _quest_index < _quests.size():
			_hud_objective.text = "🎯 %s" % str(_quests[_quest_index]["title"])
		else:
			_hud_objective.text = "🎯 All orientation quests done — live your semester!"
	if _minimap != null and _player != null:
		var mitems: Array = []
		for n in _all_npcs:
			var npc := n as NPC
			var col := Color(0.65, 0.65, 0.7)
			if npc.is_main:
				col = Color(0.3, 0.85, 0.4)
			elif npc.is_teacher:
				col = Color(1.0, 0.85, 0.3)
			elif npc.is_staff:
				col = Color(0.9, 0.6, 0.2)
			mitems.append({"pos": npc.global_position, "color": col, "quest": false})
		var qp := _quest_target_pos()
		mitems.append({"pos": qp, "color": Color(1.0, 0.85, 0.15), "quest": true})
		_minimap.update_data(_player.global_position, _player._yaw, mitems, qp, _quest_index < _quests.size())
	if _quest_marker != null:
		_quest_marker.visible = _quest_index < _quests.size()
	if not _capture_mode and not _test_mode:
		_p3_check_zone(_player_zone())
	_refresh_classmates()

func _refresh_classmates() -> void:
	if _class_box == null:
		return
	var i := 0
	for child in _class_box.get_children():
		if i == 0:
			i += 1
			continue
		if i - 1 >= _mains.size():
			# faculty separator + faculty labels: static text, leave alone
			i += 1
			continue
		var npc := _mains[i - 1] as NPC
		(child as Label).text = "%s — %s Yr%s\n♥ %d (%s) • at %s" % [npc.data["name"], npc.data["major"], str(npc.data["year"]), npc.friendship, _tier_name(npc.friendship), ZONE_NAMES.get(npc.target_zone, npc.target_zone)]
		i += 1

# ---------------- screenshots (capture mode) ----------------

# Capture-only staging (FIX 2026-11-03, defects D1-D5). The game itself is
# unchanged: these NPCs are teleported + held still ONLY for screenshots, so
# the frames show lunch-hour street life instead of the 10:30 lecture exodus.
# _stage() also sets spot/target to the lunch zone so _update_schedules does
# not re-path a staged NPC mid-tour.
func _stage(npc: NPC, pos: Vector3, yaw: float, sit: bool = false) -> void:
	npc.stationary = true
	npc.set_path([])
	npc.global_position = pos
	npc.spot = pos
	npc.target_zone = "foodcourt" # 13:00 segment for everyone; keeps schedules quiet
	npc.seated = sit
	npc.seat_yaw = yaw
	npc.rotation.y = yaw

func _run_captures() -> void:
	# A free camera tours fixed viewpoints; saves PNGs into res://preview/
	var cam := Camera3D.new()
	cam.fov = 60.0
	add_child(cam)
	cam.current = true
	_player.visible = true
	# Park the player far outside every frame: after the dialogue shot the
	# player used to stay next to Jatin and photobomb later shots (the big
	# yellow block in the old shot7) and trigger the "[E] Talk to" prompt.
	_player.global_position = Vector3(-130, 0, 100)
	# --- stage all street life up front (before anyone walks off to lunch) ---
	# D3 close-up: Anirudh alone on open quad lawn (old spot sat on top of
	# the chai-stall staff, who filled the foreground).
	_stage(_mains[0], Vector3(-16, 0, 8), 0.0)
	# D2 food-court diners at the tables + counter queue (kept clear of the
	# menu-board sightline so no name label lands on the menu text).
	_stage(_bgs[0], Vector3(62, 0, 15.5), PI / 2.0)
	_stage(_bgs[1], Vector3(63, 0, 22), -PI / 2.0)
	_stage(_bgs[4], Vector3(68, 0, 13.5), PI / 2.0)
	_stage(_bgs[5], Vector3(71, 0, 21), 0.0)
	_stage(_bgs[6], Vector3(70, 0, 20), 0.8)
	# D1 avenue crowd: people on the avenue itself, near and far so the gate
	# vehicles read behind them, facing the gate/camera.
	_stage(_bgs[7], Vector3(-2, 0, 45), 0.0)
	_stage(_bgs[8], Vector3(2, 0, 52), 0.0)
	_stage(_bgs[9], Vector3(-1.5, 0, 70), 0.3)
	_stage(_bgs[10], Vector3(3, 0, 38), -0.3)
	_stage(_bgs[11], Vector3(-3.5, 0, 80), 0.5)
	# D1 shops crowd in the plaza, facing the shop fronts (east).
	_stage(_bgs[12], Vector3(19, 0, 76), PI / 2.0)
	_stage(_bgs[13], Vector3(20, 0, 88), PI / 2.0)
	_stage(_bgs[14], Vector3(17, 0, 84), PI / 2.0)
	_stage(_bgs[15], Vector3(22, 0, 92), PI / 2.0)
	# D1 garden life: two seated on the pond bench + three standing by the pond.
	var gseats: Array = _world["seats"]["garden"]
	_stage(_bgs[16], gseats[0]["pos"], gseats[0]["yaw"], true)
	_stage(_bgs[17], gseats[1]["pos"], gseats[1]["yaw"], true)
	# Garden standers kept OFF the pond (the old (114,34) spot was inside it)
	# and on the camera's side of the pond bench.
	_stage(_bgs[18], Vector3(112, 0, 33), -1.17)
	_stage(_bgs[19], Vector3(122, 0, 38), -2.55)
	_stage(_bgs[20], Vector3(124, 0, 28), -0.98)
	await get_tree().create_timer(1.2).timeout
	_shot(cam, Vector3(30, 24, 92), Vector3(0, 3, -30))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot1_campus_wide.png")
	# D3 character close-up: camera ~1.2 m from the face, face turned to the
	# camera (yaw = direction to camera, same convention as walk facing),
	# name label hidden for this frame so it cannot dwarf the face.
	var ani: NPC = _mains[0]
	var ap := ani.global_position
	var cam2 := ap + Vector3(0.7, 1.52, 0.95)
	ani.rotation.y = atan2(cam2.x - ap.x, cam2.z - ap.z)
	ani._label.visible = false
	_shot(cam, cam2, ap + Vector3(0, 1.52, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot2_character_closeup.png")
	ani._label.visible = true
	# dialogue: teleport player next to Jatin and open the panel
	var jatin: NPC = _mains[4]
	_player.global_position = jatin.global_position + Vector3(1.4, 0.1, 1.4)
	_open_dialogue(jatin)
	var jp := jatin.global_position
	_shot(cam, jp + Vector3(2.0, 1.7, 2.6), jp + Vector3(0, 1.2, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot3_dialogue.png")
	_close_dialogue()
	_player.global_position = Vector3(-130, 0, 100)
	# D2 food court interior: straight down the hall to counter + menu board,
	# diners staged at the tables in frame. A lunch-spot main (Chirag) stands
	# in the menu sightline, so ALL name labels are hidden for this frame
	# only — otherwise one always lands on the menu text.
	for n in _all_npcs:
		(n as NPC)._label.visible = false
	_shot(cam, Vector3(56, 1.7, 18), Vector3(79, 2.5, 18))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot4_foodcourt.png")
	for n in _all_npcs:
		(n as NPC)._label.visible = true
	# library facade + quad
	_shot(cam, Vector3(28, 7, -18), Vector3(58, 5, -56))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot5_library_quad.png")
	# D1 street level on the main avenue, looking SOUTH to the gate: bus,
	# auto-rickshaw, scooters, parking, shops row and staged avenue crowd
	# all in frame; no empty lawn in the foreground.
	_shot(cam, Vector3(0, 1.7, 28), Vector3(1, 1.5, 95))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot6_avenue.png")
	# D1 shops row: camera east of the auto-rickshaw (the old (10,88) spot
	# sat 2 m from it, so the rickshaw filled the left foreground).
	_shot(cam, Vector3(14, 1.8, 92), Vector3(26, 1.3, 80))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot7_shops.png")
	# D1 gardens + pond: low camera from the south path toward the pond
	# bench and pond (the old west camera sat inside a tree canopy);
	# sitter labels hidden so they cannot overlap each other.
	_bgs[16]._label.visible = false
	_bgs[17]._label.visible = false
	_shot(cam, Vector3(105, 1.7, 36), Vector3(117, 1.0, 30))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot8_garden.png")
	_bgs[16]._label.visible = true
	_bgs[17]._label.visible = true
	# D5 mid-walk-cycle: freeze a genuine mid-stride frame. The old code's
	# seek+pause was undone every frame by NPC._update_anim (stationary ->
	# idle); anim_frozen now holds the pose. Frame 1 of the walk clip is a
	# full leg split (-32/+28 deg).
	var walker: NPC = _bgs[2]
	_stage(walker, Vector3(2.5, 0, 34), -PI / 2.0) # side-on to camera
	walker.anim_frozen = true
	await get_tree().create_timer(0.3).timeout
	var wanim: AnimationPlayer = walker._anim
	if wanim != null and wanim.has_animation("walk"):
		# Freeze with speed_scale 0, NOT pause(): in this Godot build pause()
		# clears current_animation and the pose reverts to rest (straight
		# legs) — that was the second half of the old shot9 failure.
		wanim.play("walk")
		wanim.seek(0.0, true)
		wanim.speed_scale = 0.0
		print("[CAPTURE] walker anim=", wanim.current_animation, " pos=", wanim.current_animation_position)
	var wp := walker.global_position
	_shot(cam, wp + Vector3(0.3, 1.1, 2.8), wp + Vector3(0, 0.9, 0))
	await get_tree().create_timer(0.5).timeout
	await _shot_file("shot9_walk_cycle.png")
	# D4 seated on a quad bench: LOW front-side camera at seat height so the
	# bent legs, seat plank and backrest relationship read unambiguously
	# (the old high camera made a sitter read as standing behind the bench).
	var sitter: NPC = _bgs[3]
	var seat0: Dictionary = (_world["seats"]["quad"] as Array)[0]
	_stage(sitter, seat0["pos"], seat0["yaw"], true)
	var seat1: Dictionary = (_world["seats"]["quad"] as Array)[1]
	_stage(_bgs[22], seat1["pos"], seat1["yaw"], true)
	sitter._label.visible = false
	_bgs[22]._label.visible = false
	await get_tree().create_timer(0.6).timeout
	var sp2 := sitter.global_position
	var fwd := Vector3(sin(seat0["yaw"]), 0, cos(seat0["yaw"]))
	var side := Vector3(cos(seat0["yaw"]), 0, -sin(seat0["yaw"]))
	# 3/4 side view (more side offset than before) so the horizontal thighs
	# read instead of foreshortening into vertical bars from dead front.
	_shot(cam, sp2 + fwd * 2.2 + side * 2.0 + Vector3(0, 0.9, 0), sp2 + Vector3(0, 0.65, 0))
	await get_tree().create_timer(0.5).timeout
	await _shot_file("shot10_seated.png")
	sitter._label.visible = true
	_bgs[22]._label.visible = true
	# Phase 2 shots: (11) street-level avenue WITH the circular minimap HUD
	# and the yellow quest marker in frame; (12) phone open on Messages.
	# Park the player at the avenue edge so the minimap is centred on the
	# staged crowd instead of the far parking spot, and force a HUD refresh
	# so the minimap draws before the capture.
	_player.global_position = Vector3(6, 0, 30)
	_quest_marker.global_position = Vector3(0, 3.2, 55)
	_quest_marker.visible = true
	_refresh_hud()
	await get_tree().create_timer(0.6).timeout
	_shot(cam, Vector3(0, 1.7, 28), Vector3(1, 1.5, 95))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot11_minimap_hud.png")
	_phone_panel.visible = true
	_set_phone_tab("Messages")
	await get_tree().create_timer(0.6).timeout
	_shot(cam, Vector3(0, 1.7, 28), Vector3(1, 1.5, 95))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot12_phone.png")
	# Phase 3 shots: (13) phone Social feed tab, (14) phone Stories tab,
	# (15) group event on the quad at street level, (16) arc dialogue
	# with Anirudh (Story button visible in the panel).
	_p3_seed_capture_posts()
	_set_phone_tab("Social")
	await get_tree().create_timer(0.6).timeout
	_shot(cam, Vector3(0, 1.7, 28), Vector3(1, 1.5, 95))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot13_social_feed.png")
	_set_phone_tab("Stories")
	await get_tree().create_timer(0.6).timeout
	_shot(cam, Vector3(0, 1.7, 28), Vector3(1, 1.5, 95))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot14_stories.png")
	_phone_panel.visible = false
	_stage(_mains[4], Vector3(-2, 0, 2), 0.3)
	_stage(_mains[3], Vector3(2, 0, 3), -0.4)
	_stage(_mains[7], Vector3(0, 0, 6), 0.1)
	_stage(_mains[6], Vector3(-4, 0, 6), 0.5)
	_player.global_position = Vector3(-130, 0, 100)
	_shot(cam, Vector3(0, 1.7, 13), Vector3(0, 1.2, 3))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot15_group_event.png")
	var ani2: NPC = _mains[0]
	_player.global_position = ani2.global_position + Vector3(1.4, 0.1, 1.4)
	_open_dialogue(ani2)
	var ap2 := ani2.global_position
	_shot(cam, ap2 + Vector3(2.0, 1.7, 2.6), ap2 + Vector3(0, 1.2, 0))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot16_arc_dialogue.png")
	_close_dialogue()
	# ---- Phase 4 shots ----
	# shot17: the city district street (MG Road) with foot traffic.
	_stage(_bgs[0], Vector3(-6, 0, 136), 0.2)
	_stage(_bgs[1], Vector3(2, 0, 136), -0.3)
	_stage(_bgs[2], Vector3(6, 0, 140), 0.5)
	_stage(_bgs[3], Vector3(-2, 0, 142), -0.1)
	_stage(_bgs[4], Vector3(4, 0, 132), 0.0)
	_stage(_bgs[5], Vector3(-10, 0, 140), 0.4)
	_player.global_position = Vector3(-130, 0, 100)
	# Phase 4 completion fix: shoot from the park side looking NORTH so
	# the Style Studio / Café Street shopfronts read behind the foot
	# traffic (the first take looked south and showed only apartments).
	_shot(cam, Vector3(2, 1.7, 150), Vector3(-8, 1.5, 130))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot17_city_street.png")
	# shot18: a football club session on the pitch, street-level.
	# Diagonal camera with lateral spread — no two players share the
	# camera axis (the first take stacked Jatin/Chirag labels).
	_stage(_mains[4], Vector3(-52, 0, 60), 0.785)
	_stage(_mains[3], Vector3(-55, 0, 63), 1.14)
	_stage(_bgs[6], Vector3(-49, 0, 63), 0.785)
	_stage(_bgs[7], Vector3(-58, 0, 60), 1.05)
	_player.global_position = Vector3(-130, 0, 100)
	_shot(cam, Vector3(-42, 1.7, 70), Vector3(-56, 1.2, 60))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot18_club_sports.png")
	# shot19: the player's decorated dorm room corner.
	# Shot from the WEST side: the "MY ROOM" sign faces west, so an
	# east-side camera saw it mirrored. Anirudh faces the camera.
	_p4_decor_owned = ["plant", "lamp", "rug"]
	_p4_decor_placed = ["plant", "lamp", "rug"]
	_p4_refresh_dorm_decor()
	_stage(_mains[0], Vector3(-58, 0, 14), -0.8)
	_player.global_position = Vector3(-130, 0, 100)
	_shot(cam, Vector3(-62, 1.7, 18), Vector3(-57, 1.2, 14.5))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot19_dorm_room.png")
	# shot20: rain over the avenue (weather system visible).
	# The player stands just behind the camera so the rain volume
	# (which follows the player) covers the frame, without the player
	# appearing in it.
	_p4_weather = "rain"
	_player.global_position = Vector3(8, 0.1, 52)
	_update_sun()
	_shot(cam, Vector3(2, 1.7, 55), Vector3(0, 1.5, 25))
	await get_tree().create_timer(0.9).timeout
	await _shot_file("shot20_rain_avenue.png")
	_p4_weather = "clear"
	_update_sun()
	_player.global_position = Vector3(-130, 0, 100)
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
