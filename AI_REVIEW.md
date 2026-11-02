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
