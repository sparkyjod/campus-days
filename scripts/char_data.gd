class_name CharData
extends RefCounted

## Data-driven definitions for the TEN main characters (master prompt §6),
## background student pool and staff. Zones: dorm, lecture, library,
## foodcourt, quad, union, sports, gate.
## Timetable fields per main character:
##   morning (07:30-09), am1 (09-11), am2 (11-13), lunch is always foodcourt
##   for students, pm (14-16), club (16-18), evening (18-20), night (20-22).

static func mains() -> Array:
	return [
		{
			"name": "Anirudh", "major": "Computer Science", "year": 2,
			"height": 1.78, "build": 1.0, "skin": Color(0.60, 0.42, 0.29),
			"hair_style": 0, "hair_color": Color(0.07, 0.05, 0.04),
			"shirt": Color(0.16, 0.30, 0.62), "pants": Color(0.16, 0.17, 0.20),
			"backpack": true, "pack_color": Color(0.85, 0.45, 0.10),
			"personality": "Curious, witty, builder mindset — talks in ideas and plans.",
			"hobby": "building apps and late-night coding jams",
			"friends": "Jatin, Diya", "rival": "Chirag (friendly tech-vs-business rivalry)",
			"morning": "dorm", "am1": "lecture", "am2": "lecture", "pm": "library", "club": "union", "evening": "quad", "night": "library",
			"chat": [
				"Arre, I just got my code to compile on the first try. Today is a good day, I'm telling you.",
				"I'm prototyping a campus app — timetables, canteen menu, everything. Want to beta-test it?",
				"If the library Wi-Fi cooperates, I'll finish the assignment tonight itself. If not... chai first.",
				"You know what this campus needs? A proper hackathon. I'm already planning the poster in my head."
			],
			"compliment": "Haha, thanks yaar! Okay, you officially get early access to my app when it launches.",
			"hobby_line": "Mostly I build things — small apps, weird automations. Last week I made a script that reminds Jatin to attend class. It has a 40% success rate.",
			"secret_line": "Between us? I'm applying for a big tech internship next month. Haven't told anyone yet — fingers crossed."
		},
		{
			"name": "Zannat", "major": "Law", "year": 2,
			"height": 1.68, "build": 0.92, "skin": Color(0.66, 0.47, 0.33),
			"hair_style": 1, "hair_color": Color(0.05, 0.04, 0.03),
			"shirt": Color(0.45, 0.10, 0.16), "pants": Color(0.10, 0.10, 0.12),
			"backpack": false,
			"personality": "Sharp, principled, debate-ready — precise and confident.",
			"hobby": "debating and moot court prep",
			"friends": "Shreya, Aarya", "rival": "Chirag (debate finals opponent)",
			"morning": "dorm", "am1": "lecture", "am2": "library", "pm": "library", "club": "union", "evening": "quad", "night": "library",
			"chat": [
				"The debate society selections are next week. I've prepared three arguments and two rebuttals for each.",
				"People say law is all memorising. It isn't — it's learning to think in structures.",
				"I read a judgment this morning that completely changed how I see free speech. Fascinating stuff.",
				"If anyone tells you the canteen queue is 'first come, first served', note that it is, legally and morally, a lie."
			],
			"compliment": "Well argued. I mean — thank you. Compliments with confidence, I respect that.",
			"hobby_line": "Debating, mostly. There's a thrill in defending a position you personally disagree with — it stretches your mind like nothing else.",
			"secret_line": "Confidentially? I sometimes practise my closing arguments to the library plants. They are a very supportive audience."
		},
		{
			"name": "Shreya", "major": "Medicine", "year": 3,
			"height": 1.65, "build": 0.90, "skin": Color(0.70, 0.52, 0.38),
			"hair_style": 2, "hair_color": Color(0.09, 0.06, 0.04),
			"shirt": Color(0.88, 0.86, 0.80), "pants": Color(0.35, 0.42, 0.50),
			"backpack": true, "pack_color": Color(0.30, 0.55, 0.45),
			"personality": "Calm topper, kind under pressure — soft, exact, helpful.",
			"hobby": "anatomy sketching and classical music",
			"friends": "Zannat, Yumi", "rival": "Nobody really — the syllabus is her rival",
			"morning": "library", "am1": "library", "am2": "lecture", "pm": "library", "club": "library", "evening": "quad", "night": "library",
			"chat": [
				"I was revising the cardiac cycle at 7 AM. My brain is 90% diagrams at this point.",
				"If you're ever stressed about exams, come sit in the library with me. Quiet helps, I promise.",
				"People think toppers don't struggle. We do — we just make timetables about it.",
				"Remember to drink water between lectures, okay? Half this campus runs on chai and no sleep."
			],
			"compliment": "That's sweet of you. Thank you — honestly, final-year pressure makes kind words land harder.",
			"hobby_line": "I sketch anatomy plates by hand — it helps me memorise, and it's oddly peaceful. Also, old Hindi film songs while I study. Don't tell the others.",
			"secret_line": "Just between us — I topped the last anatomy test but I cried in the hostel corridor first. Toppers are allowed that, I think."
		},
		{
			"name": "Chirag", "major": "Business", "year": 2,
			"height": 1.75, "build": 1.08, "skin": Color(0.58, 0.40, 0.27),
			"hair_style": 4, "hair_color": Color(0.06, 0.05, 0.04),
			"shirt": Color(0.90, 0.55, 0.08), "pants": Color(0.22, 0.24, 0.30),
			"backpack": false,
			"personality": "Loud, charming hustler — jokes, deals, big plans.",
			"hobby": "startup ideas and cricket betting on who wins debates (no money, only pride)",
			"friends": "Jatin, Anirudh", "rival": "Zannat (debate) and Anirudh (startup pitches)",
			"morning": "foodcourt", "am1": "lecture", "am2": "foodcourt", "pm": "lecture", "club": "union", "evening": "sports", "night": "dorm",
			"chat": [
				"Bhai, listen — a chai subscription service for hostel students. Monthly plan. This is a goldmine, I swear.",
				"I sold my old notes for printing money and pure goodwill. Mostly goodwill. Okay, only goodwill.",
				"The entrepreneurship cell meet is today. Last time I pitched for 10 minutes. They gave me 2. Growth!",
				"If motivation had a share price, mine would be at an all-time high. Invest now, thank me later."
			],
			"compliment": "See! This is why you'll be in my company's 'early believers' list. Front row at the IPO, pakka.",
			"hobby_line": "Business ideas, bro. I have a notes app with 47 startup concepts. Three are good. One is genius. The chai subscription is the genius one.",
			"secret_line": "Low-key? My dad thinks I'm 'networking' when I bunk. If the fest stall makes profit, I'll finally have proof of concept. And proof for dad."
		},
		{
			"name": "Jatin", "major": "Engineering", "year": 1,
			"height": 1.70, "build": 0.95, "skin": Color(0.52, 0.35, 0.23),
			"hair_style": 3, "hair_color": Color(0.08, 0.06, 0.05),
			"shirt": Color(0.20, 0.65, 0.30), "pants": Color(0.25, 0.28, 0.35),
			"backpack": true, "pack_color": Color(0.20, 0.35, 0.80),
			"personality": "Hyper, funny, restless — fast, slangy, meme-brain.",
			"hobby": "football, jugaad engineering and meme pages",
			"friends": "Chirag, Anirudh", "rival": "The 8 AM lecture slot itself",
			"morning": "foodcourt", "am1": "lecture", "am2": "lecture", "pm": "lecture", "club": "sports", "evening": "sports", "night": "dorm",
			"chat": [
				"Bro I fixed the hostel fan with a hairpin and pure confidence. Engineering is 10% knowledge, 90% jugaad.",
				"Football at 5 PM, full ground, no excuses. Last time I scored and celebrated before realising it was offside.",
				"My attendance is in danger zone. The professor knows my face AND my excuses now.",
				"Workshop sir said my bridge model was 'creative'. It collapsed in 4 seconds. Creative collapse."
			],
			"compliment": "Arre stop it, you'll make me blush in public. Okay fine, one more compliment, go on.",
			"hobby_line": "Football, obviously, and building dumb machines. I once made a mini catapult for hostel snacks. It delivered one samosa perfectly. One.",
			"secret_line": "Secret, okay? I act all chill but I actually revise every night after dinner. The 'last bench legend' image is marketing."
		},
		{
			"name": "Shadow", "major": "Fine Arts", "year": 3,
			"height": 1.80, "build": 0.94, "skin": Color(0.48, 0.33, 0.22),
			"hair_style": 6, "hair_color": Color(0.04, 0.04, 0.05),
			"shirt": Color(0.15, 0.15, 0.17), "pants": Color(0.12, 0.12, 0.14),
			"backpack": false,
			"personality": "Quiet, observant, mysterious — few words, deep when he opens up.",
			"hobby": "painting the campus at dusk and old vinyl records",
			"friends": "Gulshan, Diya", "rival": "No one — he competes with his last painting",
			"morning": "dorm", "am1": "lecture", "am2": "quad", "pm": "quad", "club": "union", "evening": "quad", "night": "dorm",
			"chat": [
				"...The light on the library steps right now. Look at it. That's a painting waiting.",
				"People rush everywhere here. Nobody watches the campus actually breathe.",
				"I finished a canvas last night. Three weeks of evenings. Worth it.",
				"Words are loud. Colours behave better."
			],
			"compliment": "...Thank you. I'll remember that. I don't forget kind things; I paint them later.",
			"hobby_line": "Painting, mostly at dusk — the lake corner behind the gardens. And vinyl. Music sounds honest on vinyl, even through scratches.",
			"secret_line": "You earned this one: 'Shadow' is not my real name. It's what my first art teacher called me — always in a corner, drawing. The name stayed."
		},
		{
			"name": "Gulshan", "major": "Literature", "year": 2,
			"height": 1.73, "build": 1.02, "skin": Color(0.64, 0.46, 0.31),
			"hair_style": 6, "hair_color": Color(0.10, 0.07, 0.05),
			"shirt": Color(0.60, 0.42, 0.20), "pants": Color(0.30, 0.26, 0.22),
			"backpack": false,
			"personality": "Warm storyteller, poetic — long, thoughtful replies.",
			"hobby": "poetry, old ghazals and collecting strangers' stories",
			"friends": "Shadow, Zannat", "rival": "Deadlines — his poems never meet them",
			"morning": "quad", "am1": "library", "am2": "lecture", "pm": "library", "club": "union", "evening": "quad", "night": "library",
			"chat": [
				"I heard the most beautiful line in the library today — someone returning a book said, 'It kept me company.' Books do that, don't they?",
				"Every person on this campus is a story walking around in shoes. I just try to read a few pages of each.",
				"The poetry circle meets under the big tree this week. We read under the sky — the way poems prefer it.",
				"My grandmother says a day without a story is a day half-lived. She has never had a half-day in eighty years."
			],
			"compliment": "Ah, you speak like a friend of long standing. Thank you — may your words always find good listeners.",
			"hobby_line": "Poetry and stories. I write a few lines every night, mostly about this campus — the chai stall uncle features in at least nine poems. He's a celebrity and doesn't know it.",
			"secret_line": "Shall I tell you a secret? I'm writing a novel about a university very much like this one. Some of the characters... you might recognise them."
		},
		{
			"name": "Yumi", "major": "Psychology", "year": 2,
			"height": 1.63, "build": 0.88, "skin": Color(0.78, 0.60, 0.45),
			"hair_style": 5, "hair_color": Color(0.15, 0.10, 0.07),
			"shirt": Color(0.85, 0.45, 0.55), "pants": Color(0.40, 0.35, 0.55),
			"backpack": true, "pack_color": Color(0.95, 0.75, 0.25),
			"personality": "Bright, curious about people — asks questions, notices feelings.",
			"hobby": "dance club and people-watching with a notebook",
			"friends": "Shreya, Diya", "rival": "Her own overthinking before performances",
			"morning": "dorm", "am1": "lecture", "am2": "library", "pm": "lecture", "club": "union", "evening": "quad", "night": "dorm",
			"chat": [
				"Quick question — how are you actually doing today? Not the 'fine' answer. The real one.",
				"I love how this campus changes moods by the hour. Mornings are ambition, evenings are pure nostalgia.",
				"Dance practice was so good today! Movement is just feelings with choreography, I truly believe that.",
				"In psychology we learned about the 'mere exposure effect'. It's why the canteen song gets better every time. Science!"
			],
			"compliment": "Aww, thank you! Psychologically speaking, compliments release happy chemicals — so basically you just improved my whole day. Science again!",
			"hobby_line": "Dance, and observing people ( kindly! ). My notebook has little sketches of campus moments — the chai queue debates are my favourite case studies.",
			"secret_line": "Can I share something small? I get stage fright before every performance. Every single one. Then the music starts and it melts. Brains are funny."
		},
		{
			"name": "Diya", "major": "Architecture", "year": 1,
			"height": 1.66, "build": 0.90, "skin": Color(0.56, 0.38, 0.25),
			"hair_style": 2, "hair_color": Color(0.06, 0.05, 0.04),
			"shirt": Color(0.92, 0.90, 0.86), "pants": Color(0.55, 0.30, 0.18),
			"backpack": true, "pack_color": Color(0.45, 0.30, 0.65),
			"personality": "Organised, design-obsessed — precise, visual thinker.",
			"hobby": "sketching buildings and collecting stationery",
			"friends": "Yumi, Shadow", "rival": "Crooked lines and last-minute model making",
			"morning": "quad", "am1": "lecture", "am2": "library", "pm": "quad", "club": "quad", "evening": "quad", "night": "dorm",
			"chat": [
				"Look at the library facade — those columns carry the whole elevation. I sketched it six times before I got the proportions right.",
				"I have strong opinions about this campus's pathways. The quad diagonal? Genius. The hostel bottleneck? A crime.",
				"My desk is 60% models, 40% stationery, 0% space to actually work. The maths of architecture students.",
				"If buildings could talk, the old lecture block would complain about its windows. Rightly so."
			],
			"compliment": "Oh — thank you! Precise and kind, my two favourite qualities in feedback. Noted in my sketchbook of nice moments.",
			"hobby_line": "Sketching structures, mostly. I carry a ruler like other people carry phones. Also — I have 34 pens. Thirty-four. Each has a purpose. Probably.",
			"secret_line": "Secret sketchbook confession: I've redesigned this entire campus in my notebook — bigger library windows, a better canteen roof. Someday, maybe."
		},
		{
			"name": "Aarya", "major": "Commerce", "year": 3,
			"height": 1.69, "build": 0.94, "skin": Color(0.62, 0.43, 0.30),
			"hair_style": 0, "hair_color": Color(0.07, 0.06, 0.05),
			"shirt": Color(0.20, 0.45, 0.40), "pants": Color(0.18, 0.20, 0.24),
			"backpack": false,
			"personality": "Ambitious, disciplined, finance-brain — direct, numbers-aware.",
			"hobby": "stock-market paper trading and 6 AM runs",
			"friends": "Zannat, Shreya", "rival": "Anyone who calls budgeting 'boring'",
			"morning": "sports", "am1": "lecture", "am2": "library", "pm": "lecture", "club": "union", "evening": "foodcourt", "night": "dorm",
			"chat": [
				"Ran 5K before breakfast, reviewed my portfolio over chai, attended two lectures. Discipline is a schedule, not a mood.",
				"I made a budgeting sheet for our whole friend group. Three people cried. Then they thanked me.",
				"People waste money on small things daily, then wonder where it went. Compound interest works on habits too — both directions.",
				"My internship applications are tracked in a spreadsheet with colour codes. Yes, I am fun at parties."
			],
			"compliment": "Thank you. Direct, specific feedback — that's the highest-value kind. I'll log it under 'assets'.",
			"hobby_line": "Paper trading and running. Both teach the same lesson: consistency beats intensity. Also, I genuinely enjoy a well-made spreadsheet. No apologies.",
			"secret_line": "Between us — everyone thinks I have it all figured out. I have a spreadsheet for that too. It's called 'Things I Am Figuring Out'. It's long."
		}
	]

static func background_names() -> Array:
	return ["Priya", "Rohan", "Sneha", "Arjun", "Kavya", "Vikram", "Meera", "Aditya", "Ishita", "Karan", "Pooja", "Rahul", "Ananya", "Dev", "Nisha", "Sameer", "Tanya", "Varun", "Riya", "Nikhil"]

static func background_greetings() -> Array:
	return [
		"Hey! Heading to class, but hi! This campus is huge, no?",
		"Hi hi. If you're lost, the library is the big building — everyone finds their way from there.",
		"Hello! Try the masala chai at the stall near the quad. Life-changing, seriously.",
		"Hey there. Fest practice is eating everyone's evenings. Worth it though.",
		"Hi! Watch out, the 11 AM lecture rush is like a local train at peak hour.",
		"Hello hello. I'm just running to the library before all the good seats go.",
		"Hey! New around here? The food court's thali is the best budget lunch, trust me."
	]

static func npc_chat_pairs() -> Array:
	# ambient lines NPCs say to each other (speaker, line template with {other})
	return [
		"Did you finish the assignment, {other}? I did mine at 2 AM.",
		"{other}, chai? The stall uncle is giving extra elaichi today.",
		"I heard fest auditions start next week, {other}.",
		"{other}, library after lunch? Full study mode today.",
		"That lecture could have been an email, {other}. Honestly.",
		"{other}, cricket this evening? Losers buy samosas.",
		"I swear the semester is running faster than Jatin, {other}."
	]
