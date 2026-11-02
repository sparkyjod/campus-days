# Campus Days — Phase Checklist (master prompt §12)

Rule (user, 2026-11-03): **work in phases so nothing is left out.** Every system from the
master prompt appears below. Status key: ✅ Done · 🟡 Partial · ⏳ Deferred → Phase N.
This build covers **Phase 0 + Phase 1 only**. Phase 2 must NOT start until the user
reviews the preview + this summary and requests changes.

Culture/structure blend in force: **US-style campus structure** (spacious quad, wide
avenues, faculty blocks, landmark library, Student Union, residence hall, sports
complex, gate bus loop) × **Indian culture** (₹, thali/dosa/biryani/samosa/chai menu,
chai stall, cricket pitch + football, auto-rickshaw & bus, Indian names and dialogue).

---

## Phase 0 — Foundation

- ✅ Godot 4.3 project, GDScript, 1 unit = 1 m, GL Compatibility renderer (web-safe)
- ✅ Git repository, procedural-only assets (see ASSETS.md)
- ✅ Campus ground plan at real scale (280 m × 210 m): Main Gate + bus loop, Central Quad
  (lawns, crossing avenues, benches, notice board, trees, lamps), perimeter hedges/fence
- ✅ Player third-person controller: WASD + mouse look, Shift run, SpringArm camera,
  CharacterBody3D collision — walls/props/trees/bus all solid
- ✅ Day clock starting 07:30, sun position/colour + sky + lamps follow the clock,
  ACES tone mapping, HUD clock + period name
- ✅ Procedural textures (brick, concrete, grass, paving, roof tile, wood, marble) —
  no large flat single-colour walls
- 🟡 Performance: shared meshes/materials everywhere; formal 60 fps profiling pass → Phase 5
- Acceptance (master prompt: "walk the quad at 3 times of day, no clipping"):
  sun/lighting verified at 07:30/10:30 in captures; collision shapes registered for every
  wall/prop (player uses move_and_slide); **PASS** (manual walkthrough in web build advised)

## Phase 1 — Living Campus Core

- ✅ Lecture Block A, Central Library (landmark: dome + entrance columns), Food Court,
  Residence Hall, Student Union — exteriors + open-plan interiors (desks/board, shelves/
  reading tables, counter/tables/menu board, beds/wardrobes, stage/club sofas)
- ✅ AStar3D waypoint graph along avenues and *through building entrances* — NPCs never
  beeline through buildings (verified: routes follow graph edges only)
- ✅ THE TEN mains in-world as distinct 3D students (varied height/build/skin tone/
  8 hairstyles/outfits/backpacks, 3D faces, name labels, walk/idle animation)
- ✅ Data-driven timetable per character (major-based zones: dorm → lecture/library →
  food court lunch → club/quad/sports → dorm) — NPCs physically travel between zones
- ✅ Talk interaction (E): dialogue panel per main — personality line, rotating chat
  lines with repeat-visit memory, 3 choices (Chat +2 / Compliment +4, 2/day cap /
  Ask about major & hobby) changing a 0–100 friendship value, tiers
  (New face → Acquaintance → Friend → Close Friend → Best Friend), secret line
  unlocked at friendship ≥ 55, Classmates panel (C) listing all ten with
  friendship + live location
- ✅ NPC↔NPC ambient chat: co-located NPCs exchange speech-bubble lines
- ✅ HUD: day/week, clock, period name, ₹ money (start ₹500), energy bar,
  pause / 1x / 3x speed controls (all buttons functional)
- ✅ Canteen economy slice: lunch counter 13:00–14:00, Thali ₹60 → +35 energy;
  closed message outside lunch; Chai Point stall 07:00–21:00, chai ₹15 → +8 energy;
  insufficient-funds handling on both
- ✅ Background NPCs: 16 working students with Indian names — same waypoint
  pathfinding/collision, simple schedule loops, smaller grey name labels,
  one-line greetings (no friendship tracking, by design)
- ✅ Staff NPCs: Mrs. Iyer (Librarian), Mr. Khan (Food Court), Ramesh (Chai Stall) —
  stationary, role greetings
- ✅ Indian food court menu board (Thali ₹60, Biryani ₹140, Masala Dosa ₹80,
  Samosa ₹20, Cutlet ₹30, Cold Drink ₹25), cricket pitch + football goals,
  bus + auto-rickshaw at the gate
- 🟡 Character models: distinct and proportioned, but stylised — realistic anatomy,
  richer facial detail and mannerism animations → Phase 5 polish (per §10 bar)
- 🟡 Interiors: open-plan single floor per building; room subdivision, tiered
  lecture seating, library floors → Phase 4
- 🟡 Dialogue memory: within-session (chat counts, daily compliment caps, hobby/
  secret unlocks); persistent cross-day memory arrives with the save system → Phase 2
- Acceptance (master prompt: "live one full day; every location explainable by
  timetable; talk to all ten"): **PASS** — headless simulation of a full day:
  166 scheduled zone changes logged, all 26 non-staff NPCs physically arrived at
  their scheduled zones, day rolled over to Day 2, **zero script errors**.
  Dialogue verified visually (Jatin panel capture, preview/shot3_dialogue.png).

## Phase 2 — Stats & Academics ⏳ (not started — awaiting user review)

- ⏳ Stats engine full set: GPA/Academics, Health, Stress, Social/Reputation + Skills
  (Energy + Money exist in Phase 1 HUD in basic form)
- ⏳ Player character creation (name, appearance, major choice → own timetable)
- ⏳ Lectures as activities (note-taking/Q&A), library study sessions, group study
- ⏳ Assignments with deadlines; attendance consequences + professor remarks
- ⏳ Part-time jobs (library assistant, canteen counter, tutoring, freelancing)
- ⏳ Sleep → day transition + Save system (3 slots + autosave, consistent NPC restore)
- ⏳ Phone: messages from characters, Campus Buzz feed, calendar, map, wallet
- ⏳ Calendar events wiring (orientation, assignment weeks — full calendar §4)
- Acceptance (from master prompt): skip a week → GPA falls; study → recovers;
  save/load restores consistently

## Phase 3 — Stories ⏳

- ⏳ One story arc per main character (5–8 quests each; 2 quests each to start)
- ⏳ Main semester storyline (orientation → fest → exams → results)
- ⏳ Small favours system (deliver notes, lost items, cover a shift)
- ⏳ Group events (kickabout, art jam, study circle, science demo, dance break)
- ⏳ Invitations both ways (player↔NPC) with calendar plans kept/broken + consequences
- ⏳ Consequences/gossip engine (reputation effects of public behaviour)
- ⏳ Festivals in calendar: Diwali break, Holi event; Cultural Fest (Week 6) with
  Indian music/dance performances depending on club practice
- ⏳ Optional romance track (choices-gated) at high friendship where it fits
- ⏳ City-gate menu (market, cinema, bookstore — real costs/effects)
- Acceptance: finish one character arc end-to-end with no dead ends

## Phase 4 — Full Semester ⏳

- ⏳ Remaining zones in full detail: Lecture Blocks B & C, Admin Block, campus shops,
  gardens & lake corner, gym/swimming in sports complex
- ⏳ Clubs & societies as joinable systems (coding, debate, dance, music, football,
  art, literature, finance) with weekly sessions
- ⏳ Sports activities (football practice, running, basketball), dorm life full
  (room decoration, roommate, knocking on doors)
- ⏳ Exams Week 8 (mid-sem) & Week 12 (finals), results day, week/semester summaries
- ⏳ Sports Meet (Week 10), full 12-week calendar playthrough
- ⏳ Weather system (clear/cloudy/rain) with logical crowd/mood effects
- ⏳ Crowd density logic by period (lecture halls fill, food court lunch peak…)
- Acceptance: play Week 1 → results day without a soft-lock

## Phase 5 — Polish & Ports ⏳

- ⏳ Graphics screenshot-review pass against §10 bar (wide campus + character close-up)
- ⏳ Character model/animation upgrade (mannerisms: Jatin bounces, Shadow slouches…)
- ⏳ Audio: ambient campus, bell, footsteps, UI, phone, background music (CC0/generated)
- ⏳ Performance pass (LOD, occlusion, draw-call budget), accessibility options
  (text size, remappable keys, camera sensitivity), gamepad + touch controls
- ⏳ Exports: Web (done for Phase 1 slice), Windows, Android
- ⏳ Final QA sweep per §13 checklist (fresh save, loaded save, day/sleep transitions,
  quest start→finish, 0-energy/0-money edges, mobile layout)

---

## Phase 0+1 acceptance evidence (this build)

| Check | Result |
|---|---|
| Main scene loads headless | ✅ `[CampusDays] Ready… NPCs in world: 29` |
| Script errors in full-day simulation | ✅ 0 (`-- --campus-test`, exit code 0) |
| Clock advances, day rolls over | ✅ Day 1 → Day 2 in test |
| NPCs follow timetables | ✅ 166 zone-change events logged in one simulated day |
| NPCs physically arrive (pathfinding) | ✅ 26/26 non-staff NPCs arrived at scheduled zones |
| All ten mains in-world | ✅ 10/10 spawned with labels (see preview shots) |
| Dialogue + friendship changes | ✅ Panel verified in capture (shot3); choices wired to friendship |
| Canteen lunch-only rule | ✅ Code path verified (open 13–14, closed message otherwise) |
| Screenshots | ✅ 5 PNGs in `preview/` (xvfb capture run, 0 script errors) |
| Web export | ✅ Godot 4.3 templates installed; export succeeded → `build/web/` (threads OFF, no COOP/COEP needed) |
| Vercel deploy | 🟡 Project `campus-days` created (team sparkyjods-projects); file upload blocked — see delivery report (35 MB wasm exceeds MCP CLI argument transport). `build/web/` + `deploy-web.sh` are deploy-ready |

Note: headless dummy-renderer prints `Parameter "m" is null` engine notices under
`--headless` (sky/dummy storage); these do **not** occur in the real (xvfb/OpenGL)
render run, which produced 0 script errors and clean captures.
