# AI Review — Campus Days (overnight autochain, replaces user review tonight)

## Review 1 — Overhaul build (graphics + world density + Blender characters)
Date: 2026-11-03 ~02:45 IST. Reviewer: autochain Stage 2 (independent of builder).
Build reviewed: local commit 955e174; build/web/ 2026-11-03 02:30 IST (41 MB);
preview/ shots 2026-11-03 02:29–02:30 IST. All 10 screenshots read.

## Verdict: FAIL — on the morning-reveal visual bar only

Systems and tests PASS. The failure is strictly visual, judged the way the user
judges screenshots: from street level, as a player standing in the world.

### What passes
- Headless test re-run by the reviewer: exit 0, zero script/parse errors,
  `[TEST_PASS] Day rolled over to Day 2. Mains=10 BG=24`, 34/34 non-staff NPCs
  physically arrived at scheduled zones, 38 NPCs in world. (Repeated
  `Parameter "m" is null` lines are the known dummy-renderer engine notices.)
- Overhaul content is really in the build: Lecture Blocks B/C, Admin Block,
  shops row (Juice Junction, Stationery & Prints, Xerox Point, Campus Books),
  gardens + pond, amphitheatre, parking, basketball court, running track,
  41 trees, cars/scooters/bicycles, benches 7 → 14.
- Blender character files exist: assets/characters/student_male.glb and
  student_female.glb (~1.1 MB each). Hair no longer covers the face.
- No Phase 2 systems started early (no minimap/save/GPA/quest/phone code).

### Defects (fix attempt 1 of max 3)
- D1 — Street-level shots read empty. shot6 (avenue): no people, no vehicles,
  large empty lawns. shot8 (garden): empty benches, nobody in the foreground.
  shot7 (shops): only Bhola in an empty, overexposed plaza.
- D2 — Food-court interior (shot4) reads flat and empty: one person, empty
  tables, flat lighting, menu board text partly clipped/overlapping.
- D3 — Character close-up (shot2) faces barely readable: eyes are tiny dots,
  bodies read blocky. The rig exists, but the close-up does not prove it.
- D4 — "Seated" shot (shot10) reads as standing behind the bench, not sitting.
- D5 — Walk-cycle frame (shot9) shows straight legs and arms at the sides;
  no clear mid-stride articulation in the still.

All captures are at 10:30 during lectures, which partly explains outdoor
emptiness — but the bar stands: re-capture at a busy period (lunch
13:00–14:00 or a break) with people and vehicles in frame, and add visible
street life if the timetable alone cannot fill the frame.

### Explicitly not defects in this review
- build/windows/ does not exist yet: that is Stage 3's export job, not a
  review defect. Stage 3 must verify CampusDays.exe + .pck after export.
- Circular-minimap HUD shot: required from Phase 2 onward, not for the overhaul.
- Stylised (not photoreal GTA V) look under the GL Compatibility renderer:
  honestly recorded in PHASES.md as Partial; Phase 5 (Forward+) is the
  designated graphics milestone. This FAIL is about emptiness/readability in
  the current shots, not about photorealism.

## Review 2 — Re-review after fix attempt 1 (commit 16c2ff2)
Date: 2026-11-03 ~03:25 IST. All 10 re-captured screenshots (13:00 lunch) read.

## Verdict: PASS

- D1 FIXED: shot6 avenue now shows pedestrians + gate sign + parking cars;
  shot7 shops has a 4+ person plaza crowd with Bhola; shot8 garden has seated
  + standing students at the pond. (Minor, non-blocking: a bench sits
  mid-avenue in shot6 — pre-existing layout; one label cut at shot7's edge;
  lake sign partly overlapped by seated figures in shot8 but readable.)
- D2 FIXED: shot4 menu board fully readable on both lines, 6+ diners, warm
  interior lights, no more blow-out.
- D3 FIXED within stylised limits: shot2 Anirudh close-up, face to camera,
  enlarged eyes/brows/mouth clearly readable, hair off the face. Still
  stylised low-poly — honestly recorded, Phase 5 is the milestone for more.
- D4 FIXED: shot10 shows two sitters with thighs on the seat plank, knees
  bent, feet on the ground — unambiguously sitting.
- D5 FIXED: shot9 is a genuine mid-stride frame, legs split, arms swinging.
  Root cause also fixed in code: Blender pose bones forced to XYZ Euler mode
  (quaternion default had silently discarded all euler keyframes); walk now
  15 tracks, and the freeze uses speed_scale = 0.
- Tests re-run by the reviewer: exit 0, zero script/parse errors, 34/34
  non-staff NPCs arrived, Day 1 → Day 2, 38 NPCs in world.
- Scope check: diff 955e174 → 16c2ff2 touches only scripts/main.gd,
  scripts/npc.gd, scripts/world.gd, tools/build_characters.py, the two GLBs,
  preview PNGs, PHASES.md and this file. No Phase 2 systems. Capture
  staging is gated behind the `--capture` argument only (_capture_mode);
  normal gameplay is unaffected.
- Still open, owned by Stage 3 (not defects): build/windows/ does not exist
  yet; no git remote configured. Stage 3 must export Windows, force-add
  build/web/ + build/windows/ past the build/ gitignore, run --import before
  exporting (GLBs changed), and verify the pushed files by reading the repo back.

---

## Review 3 — Phase 2 AI REVIEW — PASS (2026-11-03 ~06:35 IST)

Reviewer: independent AI review per the autochain Stage 2 protocol (replacement
Phase 2 builder, local commit 1ea3271). Builder's report was verified, not taken
on trust: headless test re-run by the reviewer, screenshots read directly,
dialogue data sampled from scripts/phase2_data.gd, scope grepped.

- (a) Promised Phase 2 content present: PASS. Stats/GPA/skills + 9 majors +
  creation, lectures/Q&A, study, 3 assignments, 4 jobs, sleep + delta saves,
  6-tab phone, 13 calendar events, 5-quest orientation chain, circular
  minimap + quest marker, 9 teachers, dialogue overhaul — all in code and
  evidenced by the test block and/or screenshots (shot11 HUD: GPA 7.50 /
  Computer Science, Health/Stress/Social bars, "Orientation: talk to a
  teacher"; shot12 phone: all 6 tabs, Messages content readable).
- (b) Characters: PASS (unchanged from overhaul Review 2 — same Blender GLB
  rigs). Close-up shot2 re-captured from final code: eyes/brows/mouth
  clearly readable, hair off the face.
- (c) Headless tests: PASS, re-run by the reviewer this run.
  `timeout 240 Godot --headless --path ~/workspace/campus-days-godot --
  --campus-test` → exit 0, ZERO script/parse errors, `[TEST_PASS] Day
  rolled over to Day 2. Mains=10 BG=24 … arrived: 43` (10 mains + 24
  background + 9 teachers), `[TEST_P2] Teachers in world: 9`,
  `[TEST_P2_SAVE] delta round-trip: OK` (gpa=7.32 money=650 day=2).
  The `Parameter "m" is null` lines are the known dummy-renderer notices.
- (d) No next-phase systems started early: PASS. Grep of scripts/ for
  romance / story-arc / gossip-engine / festival-system / social-feed /
  city-gate systems returned nothing. The quest chain is the in-scope
  Phase 2 orientation chain (5 quests); "fest"/"gossip" appear only as
  Phase 2 dialogue topics, not systems.
- (e) Exports: PASS (fresh, with one Stage 3 note). build/windows/
  CampusDays.exe 84,214,784 bytes + CampusDays.pck 7,793,904 bytes and
  build/web/ index.wasm 35,376,909 bytes + index.pck 7,793,888 bytes, all
  timestamped 2026-11-03 00:51 UTC (= 06:21 IST, today — the builder's
  "~00:51 IST" was UTC, not IST; the files are fresh regardless).
  NOTE FOR STAGE 3: these refreshed builds are UNSTAGED after commit
  1ea3271 (`M build/web/index.html`, `M build/web/index.pck`,
  `M build/windows/CampusDays.pck`); Stage 3 must force-add and verify
  them in the push, as the builder flagged.
- (f) Morning-reveal visual bar: PASS. Street-level shot6/shot11: avenue
  with people, banners, buildings, sports court and vehicles in frame —
  no large empty ground areas; shot11 adds the circular minimap with
  blips bottom-right; shot2 close-up face readable. Lighting/shadows
  match the Review-2-passed overhaul standard; Phase 2 adds HUD density,
  not a regression.
- Phase 2 DIALOGUE HARD CHECK: PASS. Reviewer sampled actual built data,
  not just the test's verdict: Anirudh (CS — "debugged a binary tree
  live"), Zannat (Law — "argue both sides of a contract case… most
  Law-school sentence"), Shadow (Fine Arts — terse, "I kept the comment,
  not the mark") on "classes" are non-interchangeable; gossip lines
  cross-reference characters with distinct voices (Chirag's "premium chai
  experience", Shadow's lake painting, Anirudh's app beta); test also
  confirms 5 Anirudh fest lines with no repeats and distinct-across-3
  OK. Indian-English flavour present throughout ("Indian Standard Time",
  "hostel terms", "Series A in hostel terms").

VERDICT: PASS, no fix attempts needed. Honest partials carried (already in
PHASES.md, not defects): other-skill levelling (Sport/Music-Art/Tech/
Communication await Phase 4 activities), event-reactive NPC-initiated lines
(Phase 3 gossip layer), multi-day week-skip sim (Phase 4 12-week
playthrough). NEXT: Stage 3 export + push for Phase 2 (retry the deferred
cumulative push; remote still empty as of the overhaul Stage 3 check).

---

## Review 4 — Phase 3 "Stories" — PASS (2026-11-03 ~07:15 IST, reviewer re-ran tests)

Builder commit f8727cb (local only, no push — Stage 3's job). Reviewer-verified, not taken on trust.
- (a) Promised content visibly present: PASS. shot13 phone Social tab readable (Campus Events, Gossip, Yumi, Anirudh posts; tabs Messages/Buzz/Calendar/Map/Wallet/Jobs/Stories/Social/City Gate all visible); shot14 Stories tab readable (main storyline Orientation→Fest week→Exams prep→Results Day, all Ten arcs listed 0/2 with named titles, "Check in here" button); shot16 dialogue shows the new third button row (Story / Favour / Invite / Something more?) fully visible; shot15 street-level quad group event (Gulshan, Jatin, Yumi, Chirag) with buildings, trees, benches in frame.
- (b) Rigged Blender-style models with walk/sit poses: PASS. shot9 genuine mid-stride walk frame (legs split, arms swinging); shot10 seated NPCs with bent knees/feet forward; shot2 close-up face readable, eyes/brows visible, hair off the face.
- (c) Headless tests: PASS, re-run by the reviewer this run. `timeout 240 Godot --headless --path ~/workspace/campus-days-godot -- --campus-test` → exit 0, zero script/parse errors (565 `Parameter "m" is null` lines are the known dummy-renderer engine notices), `[TEST_PASS] Day rolled over to Day 2. Mains=10 BG=24 … 43` NPCs arrived, `[TEST_P2] RESULT: PASS`, `[TEST_P3] RESULT: PASS` (arcs defined: 10, teacher arcs: 3; Anirudh 'Ship It' completed end-to-end; storyline 3/4 with Results locked until Day 70; romance refused before arc completion then accepted after; 18 social posts, 2 gossip entries).
- (d) No next-phase systems started early: PASS. Diff is 26 files: new scripts/phase3_data.gd + Phase 3 engine in main.gd + PHASES.md + preview + exports only. Scope grep for weather/clubs-as-systems/sports gameplay/dorm decoration/simulation tiers/customisation/city district/bus route returns only phase3_data.gd's own comment stating none of those were built; city-gate content is the phone menu tab only (Market/Cinema/Bookstore costs), as scoped. No Forward+/audio/LOD work.
- (e) Exports: PASS, fresh for this phase. build/windows/ CampusDays.exe 84,214,784 B + CampusDays.pck 10,098,368 B; build/web/ index.wasm 35,376,909 B + index.pck 10,098,400 B + index.html — all timestamped 2026-11-03 01:41 UTC (= 07:11 IST), after commit f8727cb's code, and all under the 100 MB single-file limit. NOTE FOR STAGE 3: unlike Phase 2, these exports ARE in commit f8727cb (working tree clean at review time); Stage 3 should still verify them in the pushed tree after its own re-export check.
- (f) Morning-reveal visual bar: PASS. Street-level shot6 avenue (people, banners, shops, sports court, vehicles in frame), shot15 group event populated at eye height, shot11 circular minimap with blips bottom-right; lighting/shadows match the overhaul standard; no large empty ground areas in the street-level set. Still stylised low-poly, not photoreal — honestly carried, Forward+ is Phase 5.

VERDICT: PASS, no fix attempts needed. Honest partials carried (already in PHASES.md, not defects): arcs are 2 steps each, not the master prompt's eventual 5–8 (remaining steps are Phase 4's "remaining arcs" item, per the Phase 3 brief); festival performances are text verdicts + rewards, not staged in-world dance/music with audio (Phase 5). NEXT: Stage 3 export + push for Phase 3 (retry the deferred cumulative push; push blocker from Phase 2 Stage 3 still stands until a git-capable route is available).
