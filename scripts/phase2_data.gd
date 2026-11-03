class_name Phase2Data
extends RefCounted

## Phase 2 data: teachers, majors/timetables, jobs, assignments,
## semester calendar, lecture Q&A, dialogue banks, Campus Buzz.
## Dialogue banks are AUTHORIAL per character (see dialogue.gd for the
## no-repeat picker): mains get 5 lines per topic x 4 topics, teachers
## 4 lines per topic x 3 topics. Lines are written in each character's
## own voice and reference their own major, friends and habits, so no
## two characters' lines are interchangeable.

# ---------------- teachers (Section 19.1) ----------------
static func teachers() -> Array:
	return [
		{"name": "Prof. Raghavan", "subject": "Computer Science", "major_key": "Computer Science",
			"personality": "Strict, punctual, secretly proud of good students.",
			"female": false, "height": 1.74, "build": 1.0, "skin": Color(0.58, 0.41, 0.28),
			"hair_style": 7, "hair_color": Color(0.55, 0.52, 0.50),
			"shirt": Color(0.90, 0.88, 0.82), "pants": Color(0.28, 0.27, 0.30),
			"lecture_zone": "lecture", "office": "library",
			"morning": "gate", "am1": "lecture", "am2": "lecture", "pm": "library", "club": "library", "evening": "foodcourt", "night": "gate",
			"greeting": "Mr. Raghavan here. My lecture starts on the minute, not on Indian Standard Time. Sit, notebook open, phone away."},
		{"name": "Dr. Mehta", "subject": "Medicine", "major_key": "Medicine",
			"personality": "Calm, precise, impossible to fool.",
			"female": true, "height": 1.66, "build": 0.94, "skin": Color(0.66, 0.48, 0.34),
			"hair_style": 1, "hair_color": Color(0.10, 0.08, 0.06),
			"shirt": Color(0.85, 0.87, 0.90), "pants": Color(0.30, 0.32, 0.38),
			"lecture_zone": "lecture", "office": "library",
			"morning": "gate", "am1": "lecture", "am2": "library", "pm": "library", "club": "library", "evening": "foodcourt", "night": "gate",
			"greeting": "Good morning. I notice everything, including who read the chapter and who only read the chapter title. Which are you today?"},
		{"name": "Prof. Qureshi", "subject": "Law", "major_key": "Law",
			"personality": "Debates everything; respects a sharp argument.",
			"female": false, "height": 1.76, "build": 1.04, "skin": Color(0.60, 0.43, 0.30),
			"hair_style": 6, "hair_color": Color(0.08, 0.06, 0.05),
			"shirt": Color(0.20, 0.22, 0.30), "pants": Color(0.15, 0.15, 0.17),
			"lecture_zone": "lecturec", "office": "admin",
			"morning": "gate", "am1": "lecturec", "am2": "lecturec", "pm": "admin", "club": "admin", "evening": "foodcourt", "night": "gate",
			"greeting": "Ah, a student. State your position in one sentence, then defend it. If you cannot, that is the lesson for today."},
		{"name": "Prof. Banerjee", "subject": "Literature", "major_key": "Literature",
			"personality": "Warm, poetic, quotes authors mid-sentence.",
			"female": true, "height": 1.64, "build": 0.96, "skin": Color(0.68, 0.50, 0.36),
			"hair_style": 2, "hair_color": Color(0.30, 0.26, 0.24),
			"shirt": Color(0.55, 0.30, 0.45), "pants": Color(0.35, 0.30, 0.35),
			"lecture_zone": "lectureb", "office": "library",
			"morning": "gate", "am1": "lectureb", "am2": "library", "pm": "library", "club": "library", "evening": "quad", "night": "gate",
			"greeting": "Come, sit. As Tagore wrote, the highest education is that which does not merely give us information but makes our life in harmony with all existence. Now — what did you read this week?"},
		{"name": "Dr. Kapoor", "subject": "Business", "major_key": "Business",
			"personality": "Corporate energy, talks in frameworks, runs fest sponsorship.",
			"female": false, "height": 1.78, "build": 1.06, "skin": Color(0.56, 0.39, 0.27),
			"hair_style": 4, "hair_color": Color(0.06, 0.05, 0.04),
			"shirt": Color(0.15, 0.30, 0.55), "pants": Color(0.20, 0.20, 0.24),
			"lecture_zone": "lecturec", "office": "admin",
			"morning": "gate", "am1": "lecturec", "am2": "lecturec", "pm": "admin", "club": "admin", "evening": "foodcourt", "night": "gate",
			"greeting": "Welcome. In business, as in class, there are only three questions: what is the value, who pays for it, and what happens if you miss the deadline? Let us begin with the third."},
		{"name": "Prof. D'Souza", "subject": "Fine Arts", "major_key": "Fine Arts",
			"personality": "Eccentric, encouraging, allergic to rules.",
			"female": true, "height": 1.68, "build": 0.92, "skin": Color(0.62, 0.44, 0.31),
			"hair_style": 5, "hair_color": Color(0.45, 0.30, 0.18),
			"shirt": Color(0.85, 0.40, 0.30), "pants": Color(0.25, 0.22, 0.28),
			"lecture_zone": "lectureb", "office": "union",
			"morning": "gate", "am1": "lectureb", "am2": "lectureb", "pm": "union", "club": "union", "evening": "garden", "night": "gate",
			"greeting": "Oh good, a living student! Rules are for exam halls, not studios. Show me something you made because you felt it, not because it was assigned."},
		{"name": "Prof. Nair", "subject": "Engineering", "major_key": "Engineering",
			"personality": "Practical, dry humour, loves a working prototype over a perfect theory.",
			"female": false, "height": 1.72, "build": 1.0, "skin": Color(0.54, 0.37, 0.25),
			"hair_style": 3, "hair_color": Color(0.07, 0.05, 0.04),
			"shirt": Color(0.35, 0.45, 0.40), "pants": Color(0.22, 0.22, 0.26),
			"lecture_zone": "lectureb", "office": "library",
			"morning": "gate", "am1": "lectureb", "am2": "lectureb", "pm": "library", "club": "library", "evening": "sports", "night": "gate",
			"greeting": "Engineering is the art of making things that do not fall down. Your attendance record, I notice, is currently load-bearing. Fix it."},
		{"name": "Dr. Rao", "subject": "Psychology", "major_key": "Psychology",
			"personality": "Gentle, observant, asks one question that rearranges your whole week.",
			"female": true, "height": 1.65, "build": 0.94, "skin": Color(0.64, 0.46, 0.32),
			"hair_style": 2, "hair_color": Color(0.12, 0.09, 0.07),
			"shirt": Color(0.45, 0.35, 0.60), "pants": Color(0.30, 0.28, 0.34),
			"lecture_zone": "lecturec", "office": "library",
			"morning": "gate", "am1": "lecturec", "am2": "library", "pm": "library", "club": "library", "evening": "quad", "night": "gate",
			"greeting": "Hello. Before we talk about the syllabus — how are you sleeping? The answer tells me more about your grades than your notes do."},
		{"name": "Prof. Fernandes", "subject": "Architecture", "major_key": "Architecture",
			"personality": "Precise, visual, judges a building by its staircase and a student by their sketchbook.",
			"female": false, "height": 1.75, "build": 0.98, "skin": Color(0.58, 0.41, 0.29),
			"hair_style": 0, "hair_color": Color(0.09, 0.07, 0.05),
			"shirt": Color(0.70, 0.68, 0.60), "pants": Color(0.25, 0.24, 0.28),
			"lecture_zone": "lectureb", "office": "admin",
			"morning": "gate", "am1": "lectureb", "am2": "lectureb", "pm": "admin", "club": "admin", "evening": "garden", "night": "gate",
			"greeting": "Look up before you sit down. A room teaches you before the teacher opens their mouth. Now, show me your last drawing — the honest one, not the neat one."}
	]

# ---------------- majors / timetables ----------------
static func majors() -> Array:
	return ["Computer Science", "Medicine", "Law", "Literature", "Business", "Fine Arts", "Engineering", "Psychology", "Architecture"]

static func major_info(major: String) -> Dictionary:
	var table := {
		"Computer Science": {"block": "lecture", "block_name": "Lecture Block A", "teacher": "Prof. Raghavan", "subjects": ["Data Structures", "Discrete Maths", "Programming Lab"]},
		"Medicine": {"block": "lecture", "block_name": "Lecture Block A", "teacher": "Dr. Mehta", "subjects": ["Anatomy", "Physiology", "Biochemistry"]},
		"Law": {"block": "lecturec", "block_name": "Lecture Block C", "teacher": "Prof. Qureshi", "subjects": ["Constitutional Law", "Contracts", "Legal Writing"]},
		"Literature": {"block": "lectureb", "block_name": "Lecture Block B", "teacher": "Prof. Banerjee", "subjects": ["Poetry", "Drama", "Literary Theory"]},
		"Business": {"block": "lecturec", "block_name": "Lecture Block C", "teacher": "Dr. Kapoor", "subjects": ["Marketing", "Accounting", "Organisational Behaviour"]},
		"Fine Arts": {"block": "lectureb", "block_name": "Lecture Block B", "teacher": "Prof. D'Souza", "subjects": ["Drawing", "Art History", "Studio Practice"]},
		"Engineering": {"block": "lectureb", "block_name": "Lecture Block B", "teacher": "Prof. Nair", "subjects": ["Mechanics", "Circuits", "Workshop"]},
		"Psychology": {"block": "lecturec", "block_name": "Lecture Block C", "teacher": "Dr. Rao", "subjects": ["Cognitive Psychology", "Statistics", "Development"]},
		"Architecture": {"block": "lectureb", "block_name": "Lecture Block B", "teacher": "Prof. Fernandes", "subjects": ["Design Studio", "Structures", "History of Architecture"]}
	}
	return table.get(major, table["Computer Science"])

static func appearance_presets() -> Array:
	return [
		{"label": "Short black hair • Blue tee", "female": false, "hair_style": 0, "shirt": Color(0.16, 0.30, 0.62), "skin": Color(0.60, 0.42, 0.29)},
		{"label": "Long hair • Maroon kurti", "female": true, "hair_style": 1, "shirt": Color(0.55, 0.15, 0.25), "skin": Color(0.66, 0.47, 0.33)},
		{"label": "Spiky hair • Green tee", "female": false, "hair_style": 3, "shirt": Color(0.20, 0.65, 0.30), "skin": Color(0.52, 0.35, 0.23)},
		{"label": "Bob cut • Pink top", "female": true, "hair_style": 5, "shirt": Color(0.85, 0.45, 0.55), "skin": Color(0.70, 0.52, 0.38)},
		{"label": "Curly hair • Yellow tee", "female": false, "hair_style": 6, "shirt": Color(0.85, 0.75, 0.15), "skin": Color(0.58, 0.40, 0.27)},
		{"label": "Braided hair • Teal top", "female": true, "hair_style": 2, "shirt": Color(0.20, 0.45, 0.40), "skin": Color(0.62, 0.43, 0.30)}
	]

# ---------------- jobs ----------------
static func jobs() -> Dictionary:
	return {
		"library": {"title": "Library Assistant", "pay": 150, "energy": 14, "where": "Central Library", "desc": "Shelving, issuing books, shushing with authority. Shift: library, daytime."},
		"canteen": {"title": "Canteen Counter Help", "pay": 120, "energy": 16, "where": "Food Court", "desc": "Serving thalis at lunch rush. Mr. Khan pays cash and feeds you too."},
		"tutoring": {"title": "Tutoring Juniors", "pay": 200, "energy": 18, "where": "Library / phone", "desc": "Explaining first-year topics to juniors. Pays best, needs GPA 7.0+."},
		"freelance": {"title": "Freelance Gig", "pay": 250, "energy": 22, "where": "Anywhere (phone)", "desc": "Design / code / writing gig from the campus notice board. Irregular, good money."}
	}

# ---------------- assignments + calendar ----------------
static func assignment_templates() -> Array:
	return [
		{"title": "Assignment 1: Foundations Essay", "subject": "Core subject", "due_day": 5, "desc": "1500 words. Work on it in the library; lectures and study raise progress."},
		{"title": "Assignment 2: Mid-Sem Project", "subject": "Core subject", "due_day": 12, "desc": "Group-friendly project. Group study with a friend gives bonus progress."},
		{"title": "Assignment 3: Presentation Prep", "subject": "Core subject", "due_day": 19, "desc": "Slides + rehearsal. Office hours with your professor add a big boost."}
	]

static func calendar_events() -> Array:
	return [
		{"day": 1, "title": "Orientation Day", "desc": "Welcome to Northbridge! Meet your professor and find your lecture block."},
		{"day": 2, "title": "Club Registrations Open", "desc": "Coding, debate, dance, music, finance, art — sign up at the Student Union."},
		{"day": 5, "title": "Assignment 1 Due", "desc": "Foundations Essay due today. Submit from the library before midnight."},
		{"day": 8, "title": "First Unit Tests", "desc": "Short tests in every subject. Attendance + study decide the marks."},
		{"day": 12, "title": "Assignment 2 Due", "desc": "Mid-Sem Project due. Group study helps — bring a friend."},
		{"day": 15, "title": "Fest Auditions", "desc": "Cultural Fest auditions at the amphitheatre. Perform, volunteer, or watch."},
		{"day": 19, "title": "Assignment 3 Due", "desc": "Presentation Prep due. Rehearse once in the library for full marks."},
		{"day": 22, "title": "Sports Trials", "desc": "Football, cricket and basketball trials at the Sports Complex."},
		{"day": 28, "title": "Unit Tests (Week 4)", "desc": "Unit tests in class. Your GPA so far is your preparation — revise, sleep, breathe."},
		{"day": 36, "title": "Cultural Fest Week", "desc": "The big one: performances, stalls, competitions across the whole campus."},
		{"day": 50, "title": "Diwali Break", "desc": "Campus glows, families visit, the fest committee rests. Enjoy it."},
		{"day": 52, "title": "Mid-Semester Exams Begin", "desc": "Mid-semester papers Days 52-54 in your lecture block (09:00-16:00). Results Day 57."},
		{"day": 57, "title": "Mid-Semester Results", "desc": "Mid-semester results published. Your average nudges your GPA."},
		{"day": 64, "title": "Sports Meet Week", "desc": "Sports Meet Week Days 64-70: sports sessions count double XP, 3+ sessions earns the meet prize."},
		{"day": 70, "title": "Results Day (Semester Story)", "desc": "Grades published at the Admin Block. Whatever they say, you lived it."},
		{"day": 78, "title": "Final Exams Begin", "desc": "Final papers Days 78-82 in your lecture block (09:00-16:00). Final results Day 85."},
		{"day": 85, "title": "Final Results Day", "desc": "Final results published — and the semester story closes."}
	]

# ---------------- lecture Q&A ----------------
static func qa_questions() -> Dictionary:
	return {
		"Computer Science": {"q": "In a stack, which element is removed first?", "options": ["The first one pushed", "The last one pushed", "A random one"], "answer": 1},
		"Medicine": {"q": "Which chamber of the heart pumps blood to the whole body?", "options": ["Right atrium", "Left ventricle", "Right ventricle"], "answer": 1},
		"Law": {"q": "A contract without consideration is generally…?", "options": ["Always valid", "Void, with exceptions", "A criminal offence"], "answer": 1},
		"Literature": {"q": "Who wrote: 'The road not taken'?", "options": ["Tagore", "Robert Frost", "Shakespeare"], "answer": 1},
		"Business": {"q": "In a SWOT analysis, what does 'O' stand for?", "options": ["Outcomes", "Opportunities", "Overheads"], "answer": 1},
		"Fine Arts": {"q": "Which colour results from mixing blue and yellow pigment?", "options": ["Purple", "Green", "Orange"], "answer": 1},
		"Engineering": {"q": "A simply supported beam with a central load bends most at…?", "options": ["The supports", "The centre", "Both ends equally"], "answer": 1},
		"Psychology": {"q": "The 'mere exposure effect' says familiarity tends to…?", "options": ["Breed contempt", "Increase liking", "Cause forgetting"], "answer": 1},
		"Architecture": {"q": "In a building, the primary job of a column is to carry…?", "options": ["Wind only", "Vertical load to the foundation", "Decoration"], "answer": 1}
	}

static func buzz_templates() -> Array:
	return [
		"{name} just posted: Library seats at 9 AM are a competitive sport. I lost. Again.",
		"{name} just posted: The chai stall has achieved enlightenment. Kadak level: dangerous.",
		"{name} just posted: Fest auditions next week and my stomach is already performing.",
		"{name} just posted: Whoever left notes in the library photocopier — you are a campus legend.",
		"{name} just posted: Attendance 75% is not a suggestion, it is a lifestyle choice I regret.",
		"{name} just posted: Cricket at 5, football at 5:30, assignment at midnight. This is fine.",
		"{name} just posted: The quad at sunset is the only lecture I never bunk.",
		"{name} just posted: Group study actually worked today. We studied. Mostly. Okay, 60%."
	]

static func context_snippets() -> Dictionary:
	return {
		"library_night": ["It is late for the library, but the quiet here is doing its work. ", "Night-study crowd energy — respect. "],
		"library_day": ["Between these shelves, even gossip whispers. ", "Library mode: voices low, ambitions high. "],
		"foodcourt_lunch": ["Lunch rush, steel plates everywhere, and somehow still the best conversations. ", "Thali steam and gossip in equal measure. "],
		"quad_evening": ["Evening on the quad — the whole campus exhales at once. ", "Golden hour, and suddenly everyone is philosophical. "],
		"sports_evening": ["Post-game energy, grass on shoes, stories getting taller by the minute. ", "Sports ground at dusk — where legends and excuses are born. "],
		"garden_evening": ["The lake corner at this hour makes everyone a poet for ten minutes. ", "Quiet corner, loud thoughts. "],
		"morning": ["Morning campus, chai in hand, plans still innocent. ", "Early lecture energy — half awake, fully determined. "]
	}

# ---------------- mains dialogue banks ----------------
# Topics: classes / fest / gossip / personal. 5 authored lines each.
static func mains_dialogue() -> Dictionary:
	return {
		"Anirudh": {
			"classes": [
				"Raghavan sir's data structures lecture today was actually good — he debugged a binary tree live and the whole hall gasped when it worked first try.",
				"My assignment code finally passed all tests at 2 AM. I celebrated by refactoring it, which is either discipline or a cry for help.",
				"If the library Wi-Fi holds tonight I will finish the discrete maths sheet. If not, I am blaming the router in my project report.",
				"Jatin asked me to explain pointers using cricket. I did. He now thinks a pointer is a fielder. Progress, sort of.",
				"Serious plan: a campus app that predicts which lecture will actually take attendance. The dataset is my own fear."
			],
			"fest": [
				"The coding club wants a hackathon stall at fest. I pitched 'build an app in 24 hours' and three people volunteered before I finished the sentence.",
				"Fest tech team needs volunteers who can carry both cables and conversations. I volunteered for cables. Diya volunteered me for conversations.",
				"If the fest website crashes during ticket sales, that is on me, so I am testing it like it owes me money. It does, emotionally.",
				"Chirag wants the fest stall to sell 'startup idea' coupons. I told him the coupon is just a QR code to my notes app. He loved it.",
				"My fest goal is simple: one demo that works live, on stage, in front of actual humans, without me saying 'it worked on my laptop'."
			],
			"gossip": [
				"Have you noticed Zannat and Chirag only argue when there is an audience? Debate society finals are going to be a full stadium event.",
				"Word is Shreya topped anatomy again and then apologised to the second ranker. Classic Shreya — humble even while winning.",
				"Shadow was seen at the lake corner sketching the sunset for the fourth evening straight. Gulshan says the painting is about all of us.",
				"Jatin's attendance is a campus weather report: sunny if he shows up, storm warning if Raghavan sir takes the register first.",
				"Aarya's budgeting sheet now covers half the hostel. People joke about it, then quietly ask her to make them one too."
			],
			"personal": [
				"Between us, I am applying for a tech internship next month and I have rehearsed the interview answers in the shower fourteen times.",
				"Building things is how I think. If I am quiet, I am not upset — I am debugging something in my head, usually my own schedule.",
				"My dream is stupidly simple: ship one thing that strangers actually use. Even a timetable app. Especially a timetable app.",
				"People think coders do not feel things. I feel everything, I just commit it to a private repo first.",
				"If you ever need help with an app idea, come find me. I will over-engineer it lovingly and then simplify it twice."
			]
		},
		"Zannat": {
			"classes": [
				"Qureshi sir made us argue both sides of a contract case today. I won against myself, which is the most Law-school sentence ever written.",
				"My moot court brief is 22 pages and I have cut it three times. Brevity is a legal virtue and a personal struggle.",
				"People think law is memorising sections. It is learning to spot the one weak premise in a confident argument — like Chirag's.",
				"Library silent zone, third row, same seat every day. Rituals matter: the law rewards the prepared, and so does my timetable.",
				"I read a dissenting judgment last night that changed my mind completely. Changing your mind on evidence is not weakness, it is the job."
			],
			"fest": [
				"Debate society is running a fest event called 'Argue Anything'. Chirag signed up to argue that attendance should be optional. I have prepared five rebuttals.",
				"Fest needs a proper rules sheet, or the sponsorship desk will be chaos. Kapoor sir asked me to draft it. I drafted it twice.",
				"I am judging the fest debate, which means I must be impartial while Chirag performs. My face will be neutral. My notes will not be.",
				"Fest week is the one week the whole campus argues productively. I consider it a public good, like the library, but louder.",
				"If you want to win an argument at fest, do not raise your voice. Raise one fact nobody expected. Works every time."
			],
			"gossip": [
				"Chirag's chai-subscription pitch reached the entrepreneurship cell. Verdict pending. My verdict: charming, unviable, unforgettable.",
				"Anirudh's campus app beta has a waiting list now. He pretends not to care. His commit history says otherwise.",
				"Shreya and Yumi have a study pact: no phones for two hours. Yumi lasted ninety minutes and called it 'personal growth'.",
				"Gulshan wrote a poem about the chai stall uncle. The uncle framed it. The uncle is now, technically, published.",
				"Shadow has not spoken in group chat for a week, then posted one photograph of the lake at dusk. Forty likes in an hour. Economy of words."
			],
			"personal": [
				"I practise closing arguments to the library plants. They are supportive, silent, and never interrupt — the ideal jury.",
				"People assume I am always certain. I am not. I am just disciplined about doubt: I schedule it, examine it, then decide.",
				"My goal is simple to say and hard to do: be the lawyer people trust when the stakes are real, not just when the debate is fun.",
				"My father wanted me to be 'practical'. I chose law because principles are practical — they decide who gets heard.",
				"If you ever need someone to read your argument before you send it, bring it to me. I will be honest, and then kind, in that order."
			]
		},
		"Shreya": {
			"classes": [
				"I revised the cardiac cycle at 7 AM with colour-coded diagrams. My notes look like art now. The heart, it turns out, is very drawable.",
				"Mehta ma'am asked a question nobody could answer, then waited in silence for a full minute. Silence is a teaching method, apparently.",
				"Anatomy practicals are humbling. You think you know a diagram until you have to label it with shaking hands and a time limit.",
				"My study rule: two hours of focus, then a real walk, then chai. The walk is not a break from studying. It is part of it.",
				"If you are stressed about exams, sit in the library with me for an hour. Quiet company helps more than advice, I promise."
			],
			"fest": [
				"Fest week and exams both need my calendar, so I made a spreadsheet with colour codes. Aarya approved. That is high praise.",
				"The medical society is running a first-aid stall at fest. Practical, useful, and the only stall where being calm is the product.",
				"I volunteered for fest health desk duty. Someone always faints at dance events. I will be ready, with water and zero drama.",
				"Classical music society wants me to sing at fest. I said maybe. My maybe means yes, after three practice sessions.",
				"Fest is the one week I allow myself to stay out late. The library will forgive me. I have negotiated with it in advance."
			],
			"gossip": [
				"Yumi's dance rehearsal ran over by an hour and she still made it to the library by 9. I respect that kind of stubborn joy.",
				"Chirag tried to sell the fest committee a 'premium chai experience'. Zannat cross-examined the pricing. It did not survive.",
				"Anirudh stayed up debugging and then attended the 8 AM lecture anyway. I gave him my notes and my concern, in that order.",
				"Gulshan's poetry circle now meets under the big tree because the classroom 'had no sky'. I cannot argue with that logic.",
				"Shadow left a sketch of the library steps on the notice board, unsigned. Everyone knows. Nobody says. It is better that way."
			],
			"personal": [
				"Just between us, I topped the last anatomy test and then cried in the hostel corridor. Toppers are allowed that, I think.",
				"People think calm means unstressed. Calm is a practice: sleep, water, a plan, and one person you can be honest with.",
				"I want to be the kind of doctor who explains things slowly. My grandmother deserved that, and so does every patient.",
				"Old Hindi film songs while I study — that is my secret fuel. Do not tell the others, they already know and hum along.",
				"If you ever feel overwhelmed, tell me before it becomes a crisis. Early help is not weakness, it is good medicine."
			]
		},
		"Chirag": {
			"classes": [
				"Kapoor sir's marketing lecture was basically my life story with frameworks. I took notes in business jargon and felt seen.",
				"Attendance is my startup's biggest competitor. It keeps disrupting my schedule with its 75% market share.",
				"I pitched the professor a case study on the canteen queue. He said 'interesting'. In professor language, that is a term sheet.",
				"My assignment strategy: start early, panic efficiently, finish with a presentation slide titled 'Key Learnings'. Works 70% of the time.",
				"Business school taught me one truth: every problem is a pricing problem, including my sleep schedule, which is currently overpriced."
			],
			"fest": [
				"Fest stall plan: chai subscription, live demo, and a whiteboard where people write startup ideas. The whiteboard is the real product.",
				"Sponsorship desk is my natural habitat. Kapoor sir runs it, I haunt it, and together we have secured two banners and a dream.",
				"My fest pitch is ten minutes, but I have a two-minute version for busy people and a thirty-second version for Zannat's patience.",
				"Fest is a market, bhai. Supply: talent. Demand: attention. My stall will corner both, legally and loudly.",
				"If my fest stall makes profit, my dad finally accepts 'networking' as a subject. That is the real ROI I am chasing."
			],
			"gossip": [
				"Anirudh's app has actual users now — twelve, but twelve is a Series A in hostel terms. I am an early believer, obviously.",
				"Zannat beat me in debate practice again. I am framing it as 'market research into losing gracefully'.",
				"Jatin scored in football and celebrated before realising it was offside. The celebration, however, was technically flawless.",
				"Aarya made a budgeting sheet for our friend group. Three people cried, then thanked her. I cried first, proudly.",
				"Shadow's lake painting is apparently about the whole campus. I offered to sell prints. He looked at me for five seconds and walked away. Negotiation continues."
			],
			"personal": [
				"Low-key? My dad thinks I bunk to 'network'. If the fest stall profits, I will finally have proof of concept. And proof for dad.",
				"People think hustle means no feelings. I feel everything loudly, then turn it into a pitch deck before it can hurt me.",
				"My real goal is not money, it is proof: that a kid with ideas and no connections can build something people actually want.",
				"I joke about everything except my friends. Those, I protect like a cap table: carefully, and with full disclosure.",
				"If you have an idea, tell me. I will hype it, stress-test it, and then help you build the boring parts nobody posts about."
			]
		},
		"Jatin": {
			"classes": [
				"Workshop sir called my bridge model 'creative'. It collapsed in four seconds. Creative collapse is still collapse, apparently.",
				"My attendance is in the danger zone. The professor knows my face AND my excuses now. I need new excuses, or, you know, attendance.",
				"Nair sir's mechanics lecture moves fast, so I take notes like a court stenographer having a panic attack. Legible-ish.",
				"Engineering is 10% knowledge, 90% jugaad, and 100% explaining to your parents why the project is 'almost done'.",
				"I revised last night after dinner and nobody believed me. The 'last bench legend' image is marketing, and marketing works."
			],
			"fest": [
				"Fest football match, bro — full ground, no excuses. I am playing, Chirag is commentating, and the trophy is already in my head.",
				"I volunteered for fest stage setup because it involves ladders, cables and zero sitting still. Perfect job for me.",
				"Fest dance break: I will dance badly and with full confidence. That combination has never lost an audience.",
				"The fest meme page is my contribution to culture. Engagement is high, academic value is zero, legacy is secure.",
				"If fest needs energy, I am the energy. If fest needs planning, please ask literally anyone else, preferably Diya."
			],
			"gossip": [
				"Anirudh made a script that reminds me to attend class. It has a 40% success rate, which is 40% more than my willpower.",
				"Zannat destroyed Chirag in debate club and then helped him rewrite his argument. Ruthless and kind — terrifying combo.",
				"Shadow and Gulshan have a whole friendship conducted in, like, twelve words a day. I use twelve words before breakfast.",
				"Aarya runs at 6 AM. I have seen it once, by accident, while returning from a night study session. We nodded like strangers in a documentary.",
				"Diya redesigned the fest stage layout in her notebook. The stage crew adopted it. She pretended not to be pleased. She was pleased."
			],
			"personal": [
				"Secret, okay? I act all chill but I actually revise every night after dinner. The chill is a brand. The revision is the product.",
				"Football is where my brain goes quiet. No memes, no deadlines — just a ball, a ground, and people who pass to you.",
				"I want to build something stupid and wonderful, like a snack-delivery catapult that actually works twice in a row.",
				"My family thinks I am the funny one. I am. But I am also the one who fixes the fan with a hairpin and pure confidence.",
				"If you are ever stressed, come to the ground at 5. We will play, we will laugh, and the problem will shrink to normal size."
			]
		},
		"Shadow": {
			"classes": [
				"D'Souza ma'am said my studio work has 'patience'. That is the highest grade she gives. I kept the comment, not the mark.",
				"Art history lectures are quiet in a good way. I listen, I sketch the lecturer's hands, I learn twice.",
				"Fine arts assignments have no right answer, which is freeing and terrifying in equal measure. Mostly freeing, after midnight.",
				"The studio at dusk is my real classroom. Light does the teaching; I just show up with a brush and pay attention.",
				"People rush through lectures to reach the next thing. I stay a minute longer and look. Looking is also studying."
			],
			"fest": [
				"Fest art exhibition: I am submitting one canvas. Not my best, my most honest. There is a difference, and the difference matters.",
				"The fest stage lights at dusk are a painting already. I might just sit in the audience and memorise the colours.",
				"Gulshan wants a poetry-painting collaboration for fest. Words and colours, same wall. I said yes in three words. He wrote a poem about it.",
				"Fest crowds are loud, so I will be at the edge, watching. The edge is where the real compositions happen.",
				"If you see my painting at fest, do not ask what it means. Stand with it for a minute. It will tell you, slowly."
			],
			"gossip": [
				"People talk a lot here. I listen. The campus tells better stories when nobody is performing for it.",
				"Gulshan's poems about the chai uncle are now campus folklore. The uncle has not read them. He lives them.",
				"Yumi notices feelings the way I notice light — quietly, accurately, before anyone else names them.",
				"Chirag offered to sell prints of my lake painting. I did not answer. Silence is also a negotiation tactic, apparently.",
				"Anirudh builds apps; I build canvases. Both of us stay up too late making something that was not there before."
			],
			"personal": [
				"You earned this one: 'Shadow' is not my real name. It is what my first art teacher called me — always in a corner, drawing. The name stayed.",
				"Words are loud. Colours behave better. That is why I paint first and explain later, if at all.",
				"I finished a canvas last night after three weeks of evenings. Worth it. Everything worth it takes three weeks of evenings.",
				"People think quiet means empty. Quiet is full — of light, of faces, of the exact shade of the sky at 6:40 PM.",
				"If you ever want to talk without talking, come to the lake corner at dusk. We can sit. Sitting counts as a conversation."
			]
		},
		"Gulshan": {
			"classes": [
				"Banerjee ma'am quoted Tagore mid-lecture today and the whole hall went still. Poetry does that — it pauses the timetable.",
				"Literature assignments are conversations with dead authors. I write my essays as letters to them. They reply, in footnotes.",
				"My poems never meet deadlines, but my essays do. I have made peace with this contradiction and written a poem about it.",
				"Library, third floor feeling, second row — that is where the good lines come. Place matters for words, like soil for seeds.",
				"Zannat says my arguments are beautiful but unstructured. She is right. I am learning structure the way a river learns banks."
			],
			"fest": [
				"Poetry circle under the big tree at fest — we read under the sky, the way poems prefer it. You should come, even to listen.",
				"Fest needs a quiet corner too, not just stages. I proposed a reading nook with chai. The committee approved it unanimously, then loudly.",
				"I am writing a fest poem about this campus: the rickshaw, the queue, the 8 AM light. It is long. It will get longer.",
				"Shadow and I are collaborating: his colours, my words, one wall. Neither of us will explain it. Both of us will be proud.",
				"Fest week is a story the campus tells itself once a year. I collect the footnotes: the volunteers, the near-misses, the rain."
			],
			"gossip": [
				"Every person on this campus is a story walking around in shoes. I just try to read a few pages of each, with permission.",
				"The chai stall uncle features in at least nine of my poems. He is a celebrity and does not know it. I will tell him, gently.",
				"Shreya hums old film songs while studying. The library pretends not to hear. The library hums along, in its way.",
				"Chirag's startup ideas are poems in disguise: hopeful, exaggerated, and occasionally true. I admire the hope most.",
				"Yumi keeps a notebook of campus moments. Mine is a notebook of campus sentences. Between us, we have the whole place documented."
			],
			"personal": [
				"Shall I tell you a secret? I am writing a novel about a university very much like this one. Some characters you might recognise.",
				"My grandmother says a day without a story is a day half-lived. She has never had a half-day in eighty years. I am trying to match her.",
				"Poetry is how I remember people: not their faces, but the exact sentence they said that changed the room.",
				"I want to be a writer people quote to each other in canteens. Not famous — quoted. There is a difference, and it matters.",
				"If you ever need a story to make sense of a bad week, come find me. I will not fix it, but I will give it a shape."
			]
		},
		"Yumi": {
			"classes": [
				"Rao ma'am asked us what we notice before we judge, and the whole class went quiet in a good way. Psychology does that.",
				"Dance practice and psychology lectures agree on one thing: the body knows before the mind admits it. I test this daily.",
				"Statistics for psychology is hard, but I treat it like choreography: steps, rhythm, repetition, then it flows.",
				"My notebook has case studies of campus moments — the chai queue debates are my favourite. People are wonderfully predictable and surprising.",
				"Quick question — how are you actually doing today? Not the 'fine' answer. The real one. I ask because it changes how I study with you."
			],
			"fest": [
				"Dance club fest performance is my whole heart right now. Rehearsals run over, feet hurt, and I have never been happier.",
				"Fest is a psychology experiment with lights: strangers become a crowd, a crowd becomes a memory, and everyone dances.",
				"I am choreographing a piece about first-year nerves. It starts stiff and ends free. Spoiler: that is also my semester.",
				"Stage fright before every performance, every single one. Then the music starts and it melts. Brains are funny like that.",
				"If you come to the fest dance show, sit where I can see you. Friendly faces in the crowd are my favourite choreography."
			],
			"gossip": [
				"Shreya and I have a study pact: two hours, no phones. I lasted ninety minutes and called it growth. She called it a good start.",
				"Jatin's energy is a case study: where does it come from, and can it be bottled for exam week? Research ongoing.",
				"Shadow communicates in photographs and silence, and honestly, his communication style is healthier than most group chats.",
				"Chirag pitched me a 'feelings as a service' startup. I explained why feelings are not a subscription model. He took notes.",
				"Gulshan collects stories, I collect feelings. Between us, the campus has a full medical record, emotionally speaking."
			],
			"personal": [
				"Can I share something small? I get stage fright before every performance. Then the music starts and it melts. Every time, a small miracle.",
				"As an exchange student, I notice things locals miss: how the sunset hits the library, how chai tastes like belonging.",
				"I ask people how they really are because someone once asked me, far from home, and it changed my whole semester.",
				"My dream is to understand people well enough to help them be kinder to themselves. Dance is one way. Listening is another.",
				"If you ever feel homesick or just tired, come find me. We will get chai, we will talk, and we will not rush the feeling."
			]
		},
		"Diya": {
			"classes": [
				"Fernandes sir made us redraw a staircase three times until the proportions were honest. Stairs do not forgive laziness, apparently.",
				"Look at the library facade — those columns carry the whole elevation. I sketched it six times before I got it right.",
				"Architecture studio runs long, but time disappears when the model starts looking like the idea in your head.",
				"My desk is 60% models, 40% stationery, 0% space to work. The maths of architecture students, and I accept it.",
				"Fernandes sir says a room teaches you before the teacher speaks. I now enter every classroom like it is a textbook."
			],
			"fest": [
				"I redesigned the fest stage layout in my notebook — better sightlines, safer cables. The crew adopted it. I pretended not to be pleased.",
				"Fest needs a design desk: signage, stalls, flow of people. I volunteered before they finished asking. Flow is my love language.",
				"The fest exhibition pavilion is my project: light, shade, and one long wall for Shadow's paintings. Form follows feeling.",
				"Fest week is a temporary city, and temporary cities deserve real design. I made a map. People actually used it.",
				"If you visit my fest stall, notice the corners. Corners are where design either cares or does not. Mine cares."
			],
			"gossip": [
				"Anirudh's app interface has, in my professional opinion, 'potential and three crimes against spacing'. He fixed two. Progress.",
				"Jatin's football celebrations are structurally unsound but emotionally load-bearing. I have sketched them. Twice.",
				"Shadow's lake painting uses the exact dusk palette I measured last month. Great minds, same sunset, different mediums.",
				"Gulshan's poetry corner under the tree has better acoustics than the lecture hall. I measured. He wrote a poem about the measurement.",
				"Aarya's spreadsheet for fest budgeting is a work of art. I said so out loud. She colour-coded my compliment."
			],
			"personal": [
				"Secret sketchbook confession: I have redesigned this entire campus in my notebook — bigger library windows, a better canteen roof. Someday, maybe.",
				"I carry a ruler like other people carry phones, and I have 34 pens. Each has a purpose. Probably. Definitely the blue one.",
				"Buildings talk, if you listen: the old lecture block complains about its windows, rightly, and the library hums when it rains.",
				"My goal is to design places where strangers become friends — a courtyard, a staircase wide enough for conversations.",
				"If you ever need a space redesigned — your room, your day, your fest stall — bring me a sketch, even a bad one. Bad sketches are honest."
			]
		},
		"Aarya": {
			"classes": [
				"Kapoor sir's accounting lecture was a masterclass in clarity: every rupee tracked, every assumption stated. I took notes in two colours.",
				"Ran 5K before breakfast, reviewed my portfolio over chai, attended two lectures. Discipline is a schedule, not a mood.",
				"My internship applications live in a colour-coded spreadsheet. Yes, I am fun at parties. No, the spreadsheet does not attend parties.",
				"Commerce teaches you that time is also capital. I budget my week like money: some saved, some invested, some joyfully spent.",
				"Group projects are portfolio management: diversify effort, hedge against free-riders, and document everything. It works."
			],
			"fest": [
				"Fest budgeting is my event: every stall costed, every sponsor tracked, contingency fund intact. The fest runs on my spreadsheet.",
				"Finance club is running a fest investment game with fake money and real bragging rights. I am winning, obviously, and modestly.",
				"Sponsorship negotiations with Kapoor sir are my training ground. He drives a hard bargain. I take notes and enjoy it.",
				"Fest is proof that culture has a balance sheet: joy on one side, logistics on the other, and both must reconcile.",
				"If the fest makes a surplus, I have already allocated it: 40% next year, 40% charity stall, 20% celebratory samosas."
			],
			"gossip": [
				"Chirag's fest stall budget had no contingency line. I added one. He called it pessimism. I called it adulthood.",
				"Zannat and I have a pact: no debating each other's life choices before 9 AM. After 9 AM, all bets and arguments are open.",
				"Shreya's study schedule is the only one stricter than mine. We compare calendars like athletes compare training logs.",
				"Jatin's attendance spreadsheet — yes, I made him one — is red for three weeks. He calls it 'modern art'. I call it a warning.",
				"Anirudh's app could actually monetise, with the right pricing. I told him so with a full model. He said 'cool' and kept coding."
			],
			"personal": [
				"Between us — everyone thinks I have it all figured out. I have a spreadsheet for that too. It is called 'Things I Am Figuring Out'. It is long.",
				"People waste money on small things daily, then wonder where it went. Compound interest works on habits too — both directions.",
				"My goal is not wealth, it is freedom: enough discipline now that future me gets to choose, not scramble.",
				"I run at 6 AM because the day belongs to whoever claims it first. Also because the gym is empty and the air is honest.",
				"If you ever want help with money — a budget, a plan, a panic — come to me. No judgment, just numbers and a way forward."
			]
		}
	}

# ---------------- teachers dialogue banks ----------------
# Topics: classes / career / personal. 4 authored lines each.
static func teachers_dialogue() -> Dictionary:
	return {
		"Prof. Raghavan": {
			"classes": [
				"My lecture starts on the minute. Punctuality is not politeness, it is the first data structure: order matters.",
				"A program that works by accident is not correct, it is lucky. I grade correctness, not luck, and luck knows it.",
				"Attend, take notes by hand first, then type them. The hand remembers what the keyboard forgets.",
				"Your last assignment had a clean solution buried under clever code. Simplicity is a senior skill. Practise it now."
			],
			"career": [
				"Internships reward students who ship small things reliably. Build one project properly instead of ten half-finished.",
				"Do not chase every new framework. Master fundamentals, and the frameworks will introduce themselves politely.",
				"Your portfolio should show judgment, not just output. One honest README beats five copied tutorials.",
				"Ask for feedback early and often. The best engineers I know are the ones who stopped fearing red ink."
			],
			"personal": [
				"Strict, they call me. Good. I am also, quietly, proud when a struggling student finally debugs their own thinking.",
				"I still keep my first student's thank-you note in my desk drawer. It reminds me why the register matters.",
				"Off the record: I once failed a programming test myself. Failure taught me to teach. Remember that when you stumble.",
				"My Sundays are for filter coffee and unread research papers. Both are acquired tastes, like good code."
			]
		},
		"Dr. Mehta": {
			"classes": [
				"Medicine rewards precision. A decimal point is not a detail, it is a patient. Learn that here, not later.",
				"Read the chapter before the lecture, not after. The lecture then becomes revision, and revision becomes confidence.",
				"I notice who prepares. Preparation is visible in the questions you ask, not the answers you recite.",
				"Your notes are neat but your diagrams are rushed. In anatomy, the diagram is the understanding. Redraw it."
			],
			"career": [
				"A good doctor is made of two things: knowledge and the courage to say 'I do not know, yet'. Cultivate both.",
				"Choose the specialisation that keeps you curious at 2 AM, not the one that impresses at dinner parties.",
				"Empathy is a clinical skill, not a personality trait. Practise it deliberately, like any procedure.",
				"Keep a reflective diary. The cases that trouble you are the curriculum your textbooks forgot."
			],
			"personal": [
				"Calm is not the absence of pressure. It is pressure, organised. I learned that in my first year on the wards.",
				"People think I cannot be fooled. I can — I simply check. Checking is respect, for the truth and for you.",
				"My hobby is classical music, played badly and joyfully. Perfection is for surgery, not for Sundays.",
				"Sleep is not a reward for finishing work. It is part of the work. I prescribe it to students and myself alike."
			]
		},
		"Prof. Qureshi": {
			"classes": [
				"State your position in one sentence, then defend it. If you cannot state it, you do not hold it yet — you are holding a mood.",
				"A good argument concedes the strongest counterpoint first. Weak debaters hide it; strong ones dismantle it.",
				"Law is not about winning arguments, it is about designing outcomes people can live with. Remember that in the moot hall.",
				"Your last essay argued passionately and cited thinly. Passion without precedent is a speech, not a submission."
			],
			"career": [
				"Advocacy, academia, judiciary, policy — each rewards a different temperament. Know yours before you choose the robe.",
				"Read judgments, not just summaries. The reasoning is the education; the verdict is merely the headline.",
				"Integrity compounds like interest. One shortcut now costs ten cases of credibility later. I have seen the ledger.",
				"Find a mentor who disagrees with you respectfully. Comfort is a poor teacher; principled disagreement is a great one."
			],
			"personal": [
				"I debate everything, including my own breakfast choices. My family has learned to file objections in writing.",
				"Off the bench: I collect fountain pens and lose arguments to my daughter, who is nine and already formidable.",
				"Respect is my only non-negotiable. Argue fiercely, listen fully, and never mistake volume for validity.",
				"My favourite verdicts are the dissents. History often promotes the dissent to majority, given enough time."
			]
		},
		"Prof. Banerjee": {
			"classes": [
				"As Tagore wrote, the highest education makes our life in harmony with all existence. Let us start there, then read the poem twice.",
				"Do not summarise a poem, inhabit it. A summary is a photograph of a river; reading is swimming.",
				"Your essay had a beautiful opening and a hurried ending. Endings deserve the same devotion as beginnings — ask any novel.",
				"Literature teaches attention: to a comma, to a silence, to the character nobody noticed. Attention is a moral act."
			],
			"career": [
				"Writing, teaching, publishing, theatre — literature opens many doors, but you must knock with actual work, not just love.",
				"Keep a commonplace book: lines that struck you, copied by hand. In ten years it will be your real degree.",
				"Do not fear the impractical degree. Fear the practical life lived without ever reading deeply. One impoverishes, the other merely worries.",
				"Edit ruthlessly, then restore one brave sentence. That sentence is usually the essay's soul, hiding from the red pen."
			],
			"personal": [
				"I quote authors mid-sentence because they are old friends, and old friends interrupt lovingly. Forgive me, and them.",
				"My garden is my second classroom. Plants, like students, grow toward light when you stop shouting at them.",
				"I still write letters by hand, to friends who reply by text. The mismatch is itself a poem, I think.",
				"Warmth is a pedagogy. A student who feels safe will risk a real thought; a frightened one will only repeat the textbook."
			]
		},
		"Dr. Kapoor": {
			"classes": [
				"In business, there are three questions: what is the value, who pays, and what happens if you miss the deadline? Answer in that order.",
				"Your case analysis was strong on numbers and silent on people. Markets are people, not spreadsheets with legs.",
				"Frameworks are maps, not territories. Use them to navigate, not to replace looking out of the window.",
				"Deadlines are market signals. Miss one and the market — in this case, me — reprices your reliability."
			],
			"career": [
				"Network before you need the network. Help juniors now; the returns compound, and the interest is gratitude.",
				"Your first job teaches you what you do not want. That is valuable data, not a wasted year. Price it accordingly.",
				"Learn to present numbers as a story: problem, tension, decision. Executives fund stories, not tables.",
				"Fest sponsorship taught you more than my lectures, I suspect. Good. The market is the best visiting faculty."
			],
			"personal": [
				"Corporate energy, they say, as if energy were a suit. It is a habit: prepare, decide, follow through, repeat.",
				"I run the fest sponsorship desk because students negotiating with real sponsors learn faster than any simulation.",
				"My guilty pleasure is street food, priced and reviewed like a stock. The samosa index is currently bullish.",
				"Off the record: my first business lost money gracefully. I keep its ledger to remind myself that failure is tuition, paid once."
			]
		},
		"Prof. D'Souza": {
			"classes": [
				"Rules are for exam halls, not studios. In here, the only rule is: make something honest, then make it braver.",
				"Your sketch has courage and no composition. Courage first is correct; composition is courage, organised. We will get there.",
				"Do not copy the masters, argue with them. Your disagreement is the beginning of your style.",
				"Art history is not dates, it is gossip about people who dared. Learn their daring, not just their birthdays."
			],
			"career": [
				"Portfolio careers are real careers: teach a little, exhibit a little, design a little. The mix is the stability.",
				"Show your process, not just finished work. Clients and galleries trust the sketchbook more than the frame.",
				"Apply for the residency, the grant, the wall. Rejection is the studio's rent; pay it and keep painting.",
				"Collaborate across departments. The best art I have seen came from an engineer, a poet, and a deadline."
			],
			"personal": [
				"I am allergic to rules and devoted to rituals: morning tea, evening light, one hour of looking before touching a brush.",
				"My studio is organised chaos, which is to say: I know where everything is, and nobody else is allowed to know.",
				"Encouragement is my medium. A student who believes they can make something usually goes ahead and does.",
				"My favourite colour changes yearly. This year it is the green of the campus after rain. Last year, monsoon grey."
			]
		},
		"Prof. Nair": {
			"classes": [
				"Engineering is the art of making things that do not fall down. Your design fell down beautifully. Now make it stand.",
				"Theory without a prototype is a rumour. Build the small version first, break it, learn, then build the real one.",
				"Your lab report had excellent data and no conclusion. Data without a decision is just expensive weather.",
				"Attendance, I notice, is load-bearing in your semester. Fix the structure before the exam applies the load."
			],
			"career": [
				"Industry wants engineers who document. Write the manual as if future you is tired, because future you will be.",
				"Learn one tool deeply and three shallowly. Depth gets you hired; breadth gets you promoted.",
				"Field visits beat textbooks for one reason: real machines do not care about your assumptions. Visit them often.",
				"Prototype in public. Feedback on a rough model is worth more than praise for a perfect drawing."
			],
			"personal": [
				"Dry humour is my teaching aid. If you laughed, you remembered. If you remembered, you will pass. Simple engineering.",
				"I restore old radios on Sundays. They teach patience: every circuit has a reason, even the buzzing ones.",
				"My workshop rule: clean tools, honest measurements, and no blaming the material for the maker's haste.",
				"Off the record: my first bridge model also collapsed. In four seconds, like yours. Welcome to the profession."
			]
		},
		"Dr. Rao": {
			"classes": [
				"Before we talk about the syllabus — how are you sleeping? The answer tells me more about your grades than your notes.",
				"Psychology begins with observation, not opinion. Watch one person fully for ten minutes before theorising about them.",
				"Your essay described the theory well but never applied it to a real person. Theories are tools; use one on yourself first.",
				"Statistics is not maths anxiety in disguise. It is a way of listening to large groups without interrupting them."
			],
			"career": [
				"Counselling, research, HR, UX — psychology travels well, but only if you practise listening as a skill, not a trait.",
				"Supervision matters more than the first job title. Choose the supervisor who asks the uncomfortable kind question.",
				"Keep an ethics journal. The dilemmas you notice now are the ones you will navigate later, under pressure.",
				"Research patience: one good study beats ten rushed surveys. Slow science is still science, and often the truer kind."
			],
			"personal": [
				"I ask one question that rearranges your week because rearrangement is often the treatment, not the advice.",
				"My garden and my dog are my supervision team. Both listen without interrupting, which is rarer than it sounds.",
				"Gentleness is not softness. It is strength, practised quietly, until it becomes the room's default temperature.",
				"Off the record: I still get nervous before the first lecture of term. Nerves mean I care. Caring is the curriculum."
			]
		},
		"Prof. Fernandes": {
			"classes": [
				"Look up before you sit down. A room teaches you before the teacher opens their mouth — ceiling, light, proportion.",
				"A staircase is a building's handshake: if it is awkward, the whole conversation suffers. Redraw yours, kindly but firmly.",
				"Your model is beautiful and unbuildable. Beauty must negotiate with gravity, budget, and the monsoon. Negotiate well.",
				"Sketch daily, even badly. The hand learns what the eye only suspects, and the suspect becomes a plan."
			],
			"career": [
				"Intern at a firm that lets you visit sites, not just draw them. Concrete teaches what renderings politely hide.",
				"Your portfolio needs one project explained end to end: brief, constraint, compromise, result. Clients hire explanations.",
				"Learn to present to non-architects. If a client cannot feel your building, your sections are just elegant wallpaper.",
				"Competitions are worth entering even when you lose. The jury's comments are a free studio critique from strangers."
			],
			"personal": [
				"I judge a building by its staircase and a student by their sketchbook. Both reveal whether the maker cared about the journey.",
				"My own house has a crooked window I refuse to fix. It reminds me that perfection is a visitor, not a resident.",
				"Precise, they call me. I prefer 'attentive'. Precision is attention, given a ruler and a reason.",
				"On Sundays I walk the old city and sketch doorways. Every doorway is a decision someone made about welcome."
			]
		}
	}
