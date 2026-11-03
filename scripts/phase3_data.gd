class_name Phase3Data
extends RefCounted

## Phase 3 data: character arcs, main storyline, favours, group events,
## festivals, teacher arcs, city-gate day trips, social-feed templates.
## Actions (shared vocabulary with Main's Phase 3 engine):
##   "talk" = talk to the arc giver; "talk_to:Name" = talk to that person;
##   "visit:zone" = be in that zone; "lecture" / "study" / "job" / "chai" /
##   "office" = the matching Phase 2 action; "group_event" = attend a group
##   event via the Stories check-in; "talk_teacher" = talk to any teacher.
## Nothing here is Phase 4: no city district, no clubs-as-systems, no
## sports gameplay, no dorm decoration, no weather, no simulation tiers.

# ---------------- character arcs: 2 steps each, all Ten ----------------
static func arcs() -> Dictionary:
	return {
		"Anirudh": {"title": "Ship It", "premise": "Anirudh's campus app needs a live demo audience before he dares show Raghavan sir.",
			"steps": [
				{"title": "Hear the pitch", "desc": "Talk to Anirudh about his campus app idea.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Demo day at the Union", "desc": "Visit the Student Union while Anirudh demos the app to the coding club.", "action": "visit:union", "target": "union",
					"money": 50, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Zannat": {"title": "Moot Point", "premise": "Zannat is preparing a moot case and needs someone to poke holes in her argument.",
			"steps": [
				{"title": "Take a side", "desc": "Talk to Zannat about her moot court case.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Argue it in class", "desc": "Attend a lecture — Zannat wants to hear how you argue under pressure.", "action": "lecture", "target": "",
					"money": 0, "friend": 6, "social": 3, "gpa": 0.03}
			]},
		"Shreya": {"title": "First-Aid Friends", "premise": "Shreya runs the fest first-aid desk and needs a calm second pair of hands.",
			"steps": [
				{"title": "Volunteer, carefully", "desc": "Talk to Shreya about volunteering at the first-aid desk.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Study the manual", "desc": "Study in the library — Shreya's first-aid manual is dense, and she quizzes you on it.", "action": "study", "target": "",
					"money": 0, "friend": 6, "social": 3, "gpa": 0.02}
			]},
		"Chirag": {"title": "Stall Hustle", "premise": "Chirag's fest chai stall needs a location, a supplier and one sceptical friend.",
			"steps": [
				{"title": "Hear the pitch (again)", "desc": "Talk to Chirag about his chai-subscription stall idea.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Scout the shops lane", "desc": "Visit the Campus Shops — Chirag wants a stall pitch with real footfall.", "action": "visit:shops", "target": "shops",
					"money": 100, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Jatin": {"title": "Match Day", "premise": "Jatin's football side is one player short for the inter-hostel friendly.",
			"steps": [
				{"title": "Get recruited", "desc": "Talk to Jatin — he has been looking for you, loudly, all week.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Turn up at the ground", "desc": "Visit the Sports Complex for the friendly — even spectating counts as showing up.", "action": "visit:sports", "target": "sports",
					"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
			]},
		"Shadow": {"title": "Lake Canvas", "premise": "Shadow is painting the campus for the fest exhibition and needs a collaborator's words.",
			"steps": [
				{"title": "Sit, don't talk", "desc": "Talk to Shadow at the lake corner — or just sit with him. Sitting counts.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Bring Gulshan's words", "desc": "Talk to Gulshan — Shadow wants a poem to hang beside the painting.", "action": "talk_to:Gulshan", "target": "Gulshan",
					"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Gulshan": {"title": "Poetry Night", "premise": "Gulshan's poetry circle needs a venue, an audience and one honest listener.",
			"steps": [
				{"title": "Hear the new poem", "desc": "Talk to Gulshan about the poem he wrote for the chai stall uncle.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Chai and a reading", "desc": "Buy a chai at the Chai Point — Gulshan reads the poem over kadak chai.", "action": "chai", "target": "",
					"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Yumi": {"title": "Dance Piece", "premise": "Yumi is choreographing a fest piece about first-year nerves and needs a rehearsal audience.",
			"steps": [
				{"title": "Watch a rehearsal", "desc": "Talk to Yumi about the dance piece she is building.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Show up at the Union", "desc": "Visit the Student Union during a dance rehearsal — friendly faces in the crowd matter.", "action": "visit:union", "target": "union",
					"money": 0, "friend": 6, "social": 5, "gpa": 0.0}
			]},
		"Diya": {"title": "Stage Design", "premise": "Diya's fest pavilion design needs a site visit and one person who notices corners.",
			"steps": [
				{"title": "See the sketch", "desc": "Talk to Diya about her fest pavilion sketch.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Walk the amphitheatre", "desc": "Visit the Gardens & Amphitheatre — Diya wants your eyes on the sightlines.", "action": "visit:garden", "target": "garden",
					"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Aarya": {"title": "Budget Fest", "premise": "Aarya's fest budget has a hole in it and she needs someone who will actually work a shift.",
			"steps": [
				{"title": "Read the spreadsheet", "desc": "Talk to Aarya about the fest budget — she colour-coded your scepticism already.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Earn the contingency", "desc": "Work any part-time job — Aarya counts real earnings, not good intentions.", "action": "job", "target": "",
					"money": 50, "friend": 6, "social": 3, "gpa": 0.0}
			]}
	}

# ---------------- teacher arcs (Section 19.1, depth in Phase 3) ----------------
static func teacher_arcs() -> Dictionary:
	return {
		"Prof. Raghavan": {"title": "Strict, Softening", "premise": "Raghavan sir is strict, punctual, secretly proud of good students. Prove you are one.",
			"steps": [
				{"title": "Introduce yourself, properly", "desc": "Talk to Prof. Raghavan — on the minute, notebook open.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Attend, and answer", "desc": "Attend a lecture and answer the question — Raghavan sir notices.", "action": "lecture", "target": "",
					"money": 0, "friend": 5, "social": 2, "gpa": 0.02},
				{"title": "Office hours, attempted answers first", "desc": "Take office-hours help from Prof. Raghavan (dialogue: Office hours help).", "action": "office", "target": "Prof. Raghavan",
					"money": 0, "friend": 6, "social": 3, "gpa": 0.02}
			]},
		"Dr. Kapoor": {"title": "Sponsorship Desk", "premise": "Kapoor sir runs the fest sponsorship desk. Students who negotiate with real sponsors learn fast.",
			"steps": [
				{"title": "Pitch a sponsor", "desc": "Talk to Dr. Kapoor about fest sponsorship.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "Work the desk", "desc": "Work any part-time job — Kapoor sir counts a shift as a sponsorship credential.", "action": "job", "target": "",
					"money": 100, "friend": 6, "social": 4, "gpa": 0.0}
			]},
		"Prof. D'Souza": {"title": "Fest Judge", "premise": "D'Souza ma'am judges the fest exhibition. She wants honesty, not polish.",
			"steps": [
				{"title": "Show her something felt", "desc": "Talk to Prof. D'Souza about the fest exhibition.", "action": "talk", "target": "",
					"money": 0, "friend": 4, "social": 2, "gpa": 0.0},
				{"title": "See the exhibition site", "desc": "Visit the Gardens & Amphitheatre — the exhibition wall lives there.", "action": "visit:garden", "target": "garden",
					"money": 0, "friend": 6, "social": 4, "gpa": 0.0}
			]}
	}

# ---------------- main semester storyline ----------------
static func storyline() -> Array:
	return [
		{"title": "Orientation: meet the faculty", "desc": "Talk to any teacher and introduce yourself.", "action": "talk_teacher"},
		{"title": "Fest week: join campus life", "desc": "Attend any group event (Stories tab: Check in here).", "action": "group_event"},
		{"title": "Exams approach: prepare", "desc": "Study in the library — preparation, not panic.", "action": "study"},
		{"title": "Results Day", "desc": "Reach Day 85. Final results are published after the Week 12 finals.", "action": "results_day"}
	]

# ---------------- favours (templates; giver fills {name}) ----------------
static func favour_templates() -> Array:
	return [
		{"title": "Deliver a note", "desc": "Deliver {name}'s note to {target} — just talk to them.", "action": "talk_to", "target": "",
			"money": 30, "friend": 5, "social": 2},
		{"title": "Find a lost item", "desc": "{name} left something in the {target_name}. Visit there and look for it.", "action": "visit", "target": "",
			"money": 40, "friend": 5, "social": 2},
		{"title": "Cover a shift", "desc": "{name} needs someone to cover a shift. Work any part-time job.", "action": "job", "target": "",
			"money": 60, "friend": 6, "social": 3}
	]

# Favour target rotation, per giver index: (target person, target zone).
static func favour_targets() -> Array:
	return [
		{"person": "Shreya", "zone": "library", "zone_name": "Central Library"},
		{"person": "Jatin", "zone": "sports", "zone_name": "Sports Complex"},
		{"person": "Yumi", "zone": "union", "zone_name": "Student Union"},
		{"person": "Gulshan", "zone": "garden", "zone_name": "Gardens"},
		{"person": "Diya", "zone": "shops", "zone_name": "Campus Shops"}
	]

# ---------------- group events (weekly; weekday 0=Mon .. 6=Sun) ----------------
static func group_events() -> Array:
	return [
		{"title": "Kickabout", "zone": "sports", "weekday": 0, "hour_start": 17.0, "hour_end": 18.0, "practice": false, "desc": "Monday football kickabout at the Sports Complex."},
		{"title": "Art Jam", "zone": "garden", "weekday": 1, "hour_start": 17.0, "hour_end": 18.0, "practice": true, "desc": "Tuesday art jam in the Gardens — fest exhibition practice."},
		{"title": "Study Circle", "zone": "library", "weekday": 2, "hour_start": 17.0, "hour_end": 18.0, "practice": false, "desc": "Wednesday study circle in the Central Library."},
		{"title": "Science Demo", "zone": "lecture", "weekday": 3, "hour_start": 16.0, "hour_end": 17.0, "practice": false, "desc": "Thursday science demo in Lecture Block A."},
		{"title": "Dance Break", "zone": "quad", "weekday": 4, "hour_start": 17.0, "hour_end": 18.0, "practice": true, "desc": "Friday dance break on the Central Quad — fest dance practice."},
		{"title": "Open Mic", "zone": "union", "weekday": 5, "hour_start": 17.0, "hour_end": 18.0, "practice": true, "desc": "Saturday open mic at the Student Union — fest performance practice."}
	]

# ---------------- festivals ----------------
static func festivals() -> Array:
	return [
		{"title": "Cultural Fest", "day_start": 36, "day_end": 40, "desc": "Five days of performances, stalls and competitions. Performances shine if you practised at Art Jam, Dance Break or Open Mic."},
		{"title": "Diwali Break", "day_start": 49, "day_end": 51, "desc": "Campus glows, families visit. No lecture-attendance penalty during the break."},
		{"title": "Holi", "day_start": 63, "day_end": 63, "desc": "Colours on the Quad and in the Gardens. Be there (check in) to celebrate."}
	]

# ---------------- city-gate day trips (FLAVOUR ONLY — city is Phase 4) ----------------
static func city_trips() -> Dictionary:
	return {
		"market": {"title": "City Market", "cost": 150, "desc": "Bus to the city market: supplies, snacks and a long walk. Energy +15, Health +5."},
		"cinema": {"title": "Cinema", "cost": 200, "desc": "Bus to the cinema: a film with friends, popcorn, perspective. Stress −15, Social +3."},
		"bookstore": {"title": "Bookstore", "cost": 180, "desc": "Bus to the big bookstore: one reference book you actually wanted. GPA +0.02, assignment +10."}
	}

# ---------------- social feed: ambient NPC posts ----------------
static func social_templates() -> Array:
	return [
		"{name} posted: Fest prep is real now. Rehearsals, stalls, and a spreadsheet that has achieved sentience.",
		"{name} posted: Library at 9 AM is a competitive sport and I am, regrettably, an athlete now.",
		"{name} posted: Chai stall debate today: is attendance a lifestyle or a punishment? Verdict pending.",
		"{name} posted: The quad at sunset remains undefeated. Bring a friend, leave with a plan.",
		"{name} posted: Group study worked today. We studied. Mostly. Okay, 60%. The other 40% was gossip.",
		"{name} posted: Someone left notes in the library photocopier and honestly, that person is a campus legend."
	]
