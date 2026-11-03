class_name Minimap
extends Control

## GTA-style circular minimap (Phase 2): player-centred, north-up,
## NPC blips coloured by type, quest waypoint as a yellow diamond.
## Fed by Main every HUD refresh; drawing is pure CanvasItem, so it
## also renders in xvfb screenshot captures.

var player_pos := Vector3.ZERO
var player_yaw := 0.0
var items: Array = [] # each: {"pos": Vector3, "color": Color, "quest": bool}
var quest_pos := Vector3.ZERO
var has_quest := false
var landmarks: Dictionary = {} # zone name -> world centre, set by Main (extended-world coverage)

const RADIUS := 78.0
const SCALE := 1.15 # px per metre; 78px radius covers ~68 m

func update_data(p_pos: Vector3, p_yaw: float, p_items: Array, q_pos: Vector3, q: bool) -> void:
	player_pos = p_pos
	player_yaw = p_yaw
	items = p_items
	quest_pos = q_pos
	has_quest = q
	queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	# outer ring + dark disc
	draw_circle(c, RADIUS + 4.0, Color(0.05, 0.06, 0.08, 0.95))
	draw_circle(c, RADIUS, Color(0.10, 0.16, 0.12, 0.92))
	draw_arc(c, RADIUS, 0.0, TAU, 64, Color(1.0, 0.85, 0.3, 0.9), 2.0)
	# north tick
	draw_line(c + Vector2(0, -RADIUS + 4.0), c + Vector2(0, -RADIUS + 12.0), Color(1, 1, 1, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, c + Vector2(-4, -RADIUS + 22.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.85))
	# Zone landmark dots: every district of the extended world (campus
	# + MG Road + Northgate) shows as a soft dot when in range, so the
	# larger map still reads at a glance.
	for z in landmarks:
		var lp: Vector3 = landmarks[z]
		var loff := Vector2(lp.x - player_pos.x, lp.z - player_pos.z) * SCALE
		if loff.length() < RADIUS - 6.0:
			draw_circle(c + loff, 3.0, Color(0.75, 0.85, 1.0, 0.45))
	for it in items:
		var d: Dictionary = it
		var rel: Vector3 = (d["pos"] as Vector3) - player_pos
		var p := Vector2(rel.x, rel.z) * SCALE
		if p.length() > RADIUS - 6.0:
			p = p.normalized() * (RADIUS - 6.0)
		var col: Color = d["color"]
		if bool(d.get("quest", false)):
			# yellow diamond waypoint
			var q := c + p
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -8), q + Vector2(6, 0), q + Vector2(0, 8), q + Vector2(-6, 0)]), Color(1.0, 0.85, 0.15))
		else:
			draw_circle(c + p, 3.2, col)
	# player wedge at centre, rotated by yaw (yaw 0 faces -Z? Godot: forward
	# is -Z for look_at; our movement yaw uses atan2(x, z), so map it so
	# the wedge points along the facing direction on the map plane).
	var fwd := Vector2(sin(player_yaw), cos(player_yaw))
	var side := Vector2(fwd.y, -fwd.x)
	draw_colored_polygon(PackedVector2Array([
		c + fwd * 9.0, c - fwd * 6.0 + side * 6.0, c - fwd * 6.0 - side * 6.0
	]), Color(1, 1, 1))
	draw_circle(c, 2.5, Color(0.2, 0.6, 1.0))
