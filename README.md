# Campus Days — Northbridge University Life Simulator

Godot 4.3 · Phase 0 (foundation) + Phase 1 (living campus core) · See `PHASES.md`
for the full phase checklist and what comes next.

## Play (desktop / web build)
- **Click** the game to capture the mouse · **WASD** move · **Mouse** look
- **Shift** run · **E** talk / buy · **C** classmates panel · **Esc** release mouse / close
- HUD buttons: 👥 Classmates, ⏸ pause, 1x / 3x game speed

## What's in this slice
US-style spacious campus (quad, avenues, faculty block, landmark library, student
union, residence hall, sports complex with cricket + football, gate bus loop) ×
Indian campus life (₹, thali/dosa/biryani menu, Chai Point stall, auto-rickshaw).
The ten main characters live on real timetables and walk the waypoint network
between dorm, lectures, library, lunch, clubs and evening spots. Talk to them to
build friendship (0–100). 16 background students + 3 staff keep the campus alive.
Buy a ₹60 thali at the Food Court counter during lunch (13:00–14:00) or a ₹15
chai at the stall (07:00–21:00).

## Develop
```bash
GODOT=~/workspace/tools/godot/Godot_v4.3-stable_linux.x86_64
$GODOT --headless --path . --import          # first run: register classes
$GODOT --headless --path . -- --campus-test  # full-day simulation self-test
$GODOT --path .                              # play in editor binary
$GODOT --headless --path . --export-release "Web" build/web/index.html
```
Self-test prints `[TEST_ZONE]` / `[TEST_ARRIVE]` lines and `[TEST_PASS]` with
exit code 0 on success. Screenshot tour: run under X (or xvfb) with `-- --capture`
to regenerate `preview/*.png`.
