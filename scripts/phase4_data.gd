class_name Phase4Data
extends RefCounted

## Phase 4 data: clubs & societies, sports, exams, weather, the city
## district (shops, café street, apartments, park, bus route),
## character customisation (outfits/hairstyles), dorm décor, café snacks,
## and the continued story arcs (steps 3-6) for the Ten.
## Nothing here is Phase 5: no Forward+ conversion, no audio system,
## no LOD/performance pass, no accessibility/gamepad/touch work,
## no Android export.

# ---------------- clubs & societies (Section 8) ----------------
# venue = zone key; weekday 0=Mon .. 6=Sun; hour window is the session.
# skill = the Phase 2 skill the session levels. practice = counts toward
# Cultural Fest practice (dance/music/art performance clubs).
static func clubs() -> Dictionary:
	return {
		"coding": {"title": "Coding Club", "venue": "union", "weekday": 0, "hour_start": 16.0, "hour_end": 17.0, "skill": "Tech", "practice": false,
			"desc": "Monday coding jam at the Student Union. Ship something every week."},
		"debate": {"title": "Debate Society", "venue": "lecturec", "weekday": 1, "hour_start": 16.0, "hour_end": 17.0, "skill": "Communication", "practice": false,
			"desc": "Tuesday debate sparring in Lecture Block C. Zannat usually wins."},
		"dance": {"title": "Dance Club", "venue": "quad", "weekday": 2, "hour_start": 16.0, "hour_end": 17.0, "skill": "Music/Art", "practice": true,
			"desc": "Wednesday dance rehearsal on the Central Quad. Fest performance practice."},
		"music": {"title": "Music Society", "venue": "union", "weekday": 3, "hour_start": 16.0, "hour_end": 17.0, "skill": "Music/Art", "practice": true,
			"desc": "Thursday music jam at the Student Union. Fest performance practice."},
		"football": {"title": "Football Club", "venue": "sports", "weekday": 4, "hour_start": 16.0, "hour_end": 17.0, "skill": "Sport", "practice": false,
			"desc": "Friday football club session at the Sports Complex. Jatin runs the drills."},
		"art": {"title": "Art Club", "venue": "garden", "weekday": 5, "hour_start": 16.0, "hour_end": 17.0, "skill": "Music/Art", "practice": true,
			"desc": "Saturday art jam in the Gardens. Fest exhibition practice."},
		"literature": {"title": "Literature Circle", "venue": "library", "weekday": 6, "hour_start": 11.0, "hour_end": 12.0, "skill": "Communication", "practice": false,
			"desc": "Sunday morning literature circle in the Central Library. Gulshan brings poems."},
		"finance": {"title": "Finance Club", "venue": "admin", "weekday": 6, "hour_start": 16.0, "hour_end": 17.0, "skill": "Tech", "practice": false,
			"desc": "Sunday finance club at the Admin Block. Aarya's spreadsheets, live."}
	}

# ---------------- sports (Section 8: football practice, running, basketball, gym, swim) ----------------
# anchor = world position the action happens at; radius = prompt range.
static func sports() -> Dictionary:
	return {
		"football": {"title": "Football practice", "anchor": Vector3(-52, 0, 62), "radius": 26.0, "desc": "Drills and a kickabout on the football pitch."},
		"running": {"title": "Run laps", "anchor": Vector3(-52, 0, 42), "radius": 40.0, "desc": "Laps on the running track around the pitch."},
		"basketball": {"title": "Basketball shots", "anchor": Vector3(-14, 0, 34), "radius": 12.0, "desc": "Shoot hoops on the basketball court."},
		"gym": {"title": "Gym workout", "anchor": Vector3(-10, 0, 44), "radius": 9.0, "desc": "Weights and machines in the campus gym."},
		"swim": {"title": "Swim laps", "anchor": Vector3(12, 0, 41), "radius": 8.0, "desc": "Laps in the open-air campus pool."}
	}

# ---------------- exams (master prompt Section 4/8: Week 8 mid-sem, Week 12 finals) ----------------
# Week 8 = Days 50-56; sittings Wed-Fri (Days 52-54) so they do not clash
# with the Diwali Break (Days 49-51). Week 12 = Days 78-84; finals
# sittings Mon-Fri (Days 78-82). Results: mid-sem Day 57, finals Day 85.
static func midsem_days() -> Array:
	return [52, 53, 54]

static func final_days() -> Array:
	return [78, 79, 80, 81, 82]

static func midsem_results_day() -> int:
	return 57

static func final_results_day() -> int:
	return 85

static func sports_week_days() -> Array:
	return [64, 65, 66, 67, 68, 69, 70]

# ---------------- weather (Section 4: clear/cloudy/rain by day, deterministic) ----------------
# Rain on days where (day*37+11)%10 < 2 (days 7, 10, 17, 20, ...);
# cloudy on a further slice; Day 1 is clear by construction so the
# one-day test and the lunch captures are unaffected.
static func weather_for_day(d: int) -> String:
	var h := (d * 37 + 11) % 10
	if h < 2:
		return "rain"
	var h2 := (d * 13 + 5) % 10
	if h2 < 3:
		return "cloudy"
	return "clear"

# Outdoor zones whose crowds move indoors on rain days.
static func rain_redirect() -> Dictionary:
	return {"quad": "union", "garden": "library", "sports": "union"}

# --- World extension + weather/seasons build: seasons engine --------
# The semester opens in December, so the CURRENT season is WINTER
# (user: "currently will be a snow season"). Seasons follow the
# in-game calendar; seasonal_weather() maps the deterministic base
# table through the season: winter turns rain into snowfall, monsoon
# turns most cloudy days wet. weather_for_day() itself is unchanged,
# so the Phase 4 table test (day 1 clear, days 7/10 rain) still holds.
static func season_for_day(d: int) -> String:
	if d <= 28:
		return "winter"
	if d <= 56:
		return "spring"
	if d <= 70:
		return "summer"
	return "monsoon"

static func seasonal_weather(d: int) -> String:
	var base := weather_for_day(d)
	match season_for_day(d):
		"winter":
			return "snow" if base == "rain" else base
		"monsoon":
			if base == "cloudy" and (d * 17 + 3) % 10 < 6:
				return "rain"
			return base
	return base

static func snow_redirect() -> Dictionary:
	# Heavy snow sends outdoor crowds indoors, like rain — extended to
	# the Northgate zones: the bazaar crowds step into the campus shops,
	# the lakefront empties to the library, the colony heads home.
	return {"quad": "union", "garden": "library", "sports": "union",
		"bazaar": "shops", "lakefront": "library", "colony": "dorm"}

# ---------------- city district (Section 15.3) ----------------
# MG Road beyond the Main Gate: clothing store, café street, apartments,
# park, bus stop with the Route 12 bus back to campus.
static func city_bus_fare() -> int:
	return 20

static func outfits() -> Array:
	return [
		{"id": "casual", "label": "Everyday Denim — blue tee", "shirt": Color(0.20, 0.40, 0.70), "pants": Color(0.25, 0.30, 0.45), "price": 180},
		{"id": "sporty", "label": "Sports Kit — bright training tee", "shirt": Color(0.85, 0.30, 0.15), "pants": Color(0.15, 0.15, 0.18), "price": 200},
		{"id": "street", "label": "Streetwear — black + red", "shirt": Color(0.15, 0.15, 0.17), "pants": Color(0.20, 0.25, 0.35), "price": 250},
		{"id": "kurta", "label": "Fest Kurta — teal & gold", "shirt": Color(0.10, 0.50, 0.45), "pants": Color(0.95, 0.92, 0.85), "price": 300},
		{"id": "ethnic", "label": "Ethnic Day — maroon kurta", "shirt": Color(0.50, 0.12, 0.20), "pants": Color(0.90, 0.88, 0.80), "price": 350},
		{"id": "formal", "label": "Seminar Formals — navy blazer look", "shirt": Color(0.15, 0.25, 0.50), "pants": Color(0.25, 0.25, 0.28), "price": 400}
	]

static func hairstyles() -> Array:
	return [
		{"style": 0, "label": "Short crop", "price": 80},
		{"style": 3, "label": "Spiky", "price": 100},
		{"style": 1, "label": "Long", "price": 100},
		{"style": 5, "label": "Bob", "price": 100},
		{"style": 6, "label": "Curly", "price": 120}
	]

static func decor_items() -> Array:
	return [
		{"id": "plant", "label": "Potted Plant", "price": 120},
		{"id": "rug", "label": "Handloom Rug", "price": 150},
		{"id": "lamp", "label": "Floor Lamp", "price": 200},
		{"id": "shelf", "label": "Bookshelf", "price": 300}
	]

static func cafe_snacks() -> Array:
	return [
		{"id": "samosa", "label": "Samosa Plate", "price": 40, "energy": 10, "health": 0, "stress": 0, "social": 0},
		{"id": "coffee", "label": "Cold Coffee", "price": 60, "energy": 12, "health": 0, "stress": -3, "social": 0},
		{"id": "pastry", "label": "Pastry", "price": 80, "energy": 15, "health": 0, "stress": -2, "social": 1}
	]

# ---------------- continued arcs: steps 3-6 for each of the Ten ----------------
# These run AFTER the Phase 3 base arc (2 steps) is complete. Same action
# vocabulary as Phase 3, plus Phase 4 actions: "club:<id>", "sport:<kind>",
# "visit:city", "customise". Gated on base-arc completion in Main.
static func arc_extensions() -> Dictionary:
	return {
		"Anirudh": {"title": "Ship It — Launch Week", "steps": [
			{"title": "Demo at the coding club", "desc": "Attend a Coding Club session — Anirudh demos the app to the club.", "action": "club:coding", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "Feedback round", "desc": "Talk to Anirudh about the demo feedback.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Freelance gig for launch funds", "desc": "Work a freelance gig — the launch needs a domain and snacks.", "action": "job", "target": "",
				"money": 100, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Launch party at the Union", "desc": "Visit the Student Union for the app launch party.", "action": "visit:union", "target": "union",
				"money": 50, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Zannat": {"title": "Moot Point — Finals", "steps": [
			{"title": "Debate society sparring", "desc": "Attend a Debate Society session — Zannat sharpens her arguments.", "action": "club:debate", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "Face Chirag in a practice moot", "desc": "Talk to Chirag — Zannat wants you to watch her beat him, politely.", "action": "talk_to:Chirag", "target": "Chirag",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "Argue under pressure in class", "desc": "Attend a lecture — Zannat wants to hear how you argue under pressure.", "action": "lecture", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.03},
			{"title": "Moot final at Block C", "desc": "Visit Lecture Block C for the moot final.", "action": "visit:lecturec", "target": "lecturec",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Shreya": {"title": "First-Aid Friends — Duty Roster", "steps": [
			{"title": "Revise the first-aid manual", "desc": "Study in the library — Shreya's manual, second edition.", "action": "study", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.02},
			{"title": "Roster talk", "desc": "Talk to Shreya about the duty roster.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Morning run", "desc": "Run laps — Shreya runs before her shift, and she invited you.", "action": "sport:running", "target": "",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "First-aid desk shift", "desc": "Visit the Central Library for the first-aid desk shift.", "action": "visit:library", "target": "library",
				"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
		]},
		"Chirag": {"title": "Stall Hustle — City Supplier", "steps": [
			{"title": "Meet the supplier in the city", "desc": "Visit the city district — Chirag's supplier has a shop on MG Road.", "action": "visit:city", "target": "city",
				"money": 0, "friend": 4, "social": 3, "gpa": 0.0},
			{"title": "Earn the seed money", "desc": "Work any part-time job — Chirag counts real earnings, not hype.", "action": "job", "target": "",
				"money": 100, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Pitch review", "desc": "Talk to Chirag about the revised pitch.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Finance club pricing session", "desc": "Attend a Finance Club session — Aarya checks Chirag's margins.", "action": "club:finance", "target": "",
				"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
		]},
		"Jatin": {"title": "Match Day — League", "steps": [
			{"title": "Football practice", "desc": "Football practice at the Sports Complex — Jatin runs the drills.", "action": "sport:football", "target": "",
				"money": 0, "friend": 4, "social": 3, "gpa": 0.0},
			{"title": "Sprint training", "desc": "Run laps — Jatin's sprint plan is loud and somehow works.", "action": "sport:running", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Football club session", "desc": "Attend a Football Club session — tactics, then a practice match.", "action": "club:football", "target": "",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "League final at the ground", "desc": "Visit the Sports Complex for the league final.", "action": "visit:sports", "target": "sports",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Shadow": {"title": "Lake Canvas — Exhibition", "steps": [
			{"title": "Art club critique", "desc": "Attend an Art Club session — Shadow's canvas goes up for critique.", "action": "club:art", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "Quiet talk", "desc": "Talk to Shadow — he says little, and means all of it.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Hang the painting at the lake", "desc": "Visit the Gardens & Amphitheatre for the exhibition hang.", "action": "visit:garden", "target": "garden",
				"money": 0, "friend": 6, "social": 4, "gpa": 0.0},
			{"title": "Exhibition outfit", "desc": "Buy and wear an outfit from the city clothing store for the opening.", "action": "customise", "target": "",
				"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
		]},
		"Gulshan": {"title": "Poetry Night — Main Stage", "steps": [
			{"title": "Literature circle reading", "desc": "Attend a Literature Circle session — Gulshan reads the new poem.", "action": "club:literature", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "New poem", "desc": "Talk to Gulshan about the poem he wrote for the main stage.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Chai and a reading", "desc": "Buy a chai at the Chai Point — Gulshan reads over kadak chai.", "action": "chai", "target": "",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "Poetry night at the Union", "desc": "Visit the Student Union for poetry night.", "action": "visit:union", "target": "union",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Yumi": {"title": "Dance Piece — Fest Stage", "steps": [
			{"title": "Dance club rehearsal", "desc": "Attend a Dance Club session — Yumi's piece, full run-through.", "action": "club:dance", "target": "",
				"money": 0, "friend": 4, "social": 3, "gpa": 0.0},
			{"title": "Choreography talk", "desc": "Talk to Yumi about the choreography.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Music collaboration", "desc": "Attend a Music Society session — the piece needs its soundtrack.", "action": "club:music", "target": "",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "Fest performance at the Union", "desc": "Visit the Student Union for the fest performance.", "action": "visit:union", "target": "union",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Diya": {"title": "Stage Design — Build", "steps": [
			{"title": "Art club materials session", "desc": "Attend an Art Club session — Diya sources pavilion materials.", "action": "club:art", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "Buy materials in the city", "desc": "Visit the city district for pavilion materials.", "action": "visit:city", "target": "city",
				"money": 0, "friend": 5, "social": 3, "gpa": 0.0},
			{"title": "Design review", "desc": "Talk to Diya about the revised pavilion design.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Pavilion opening", "desc": "Visit the Gardens & Amphitheatre for the pavilion opening.", "action": "visit:garden", "target": "garden",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]},
		"Aarya": {"title": "Budget Fest — Sign-off", "steps": [
			{"title": "Finance club audit", "desc": "Attend a Finance Club session — Aarya audits the fest budget, live.", "action": "club:finance", "target": "",
				"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
			{"title": "Earn the contingency", "desc": "Work any part-time job — Aarya counts real earnings, not projections.", "action": "job", "target": "",
				"money": 100, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Budget review", "desc": "Talk to Aarya about the final budget.", "action": "talk", "target": "",
				"money": 0, "friend": 5, "social": 2, "gpa": 0.0},
			{"title": "Sign-off at the Admin Block", "desc": "Visit the Admin Block for the budget sign-off.", "action": "visit:admin", "target": "admin",
				"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
		]}
	}
