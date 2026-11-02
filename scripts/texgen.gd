class_name TexGen
extends RefCounted

## Procedural canvas textures + shared materials. No external assets.
## Every texture is generated once and cached; materials are shared across
## all meshes that use them (performance rule from the master prompt).
## Overhaul pass: 512px facade/ground textures with per-element colour
## jitter, grime/stains, roughness variation maps and mipmaps.

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func _make_image(w: int, h: int, fill: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(fill)
	return img

static func _finish(img: Image, key: String) -> Texture2D:
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex_cache[key] = t
	return t

static func _noise_overlay(img: Image, base_vary: float, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var v := rng.randf_range(-base_vary, base_vary)
			img.set_pixel(x, y, Color(clampf(c.r + v, 0.0, 1.0), clampf(c.g + v, 0.0, 1.0), clampf(c.b + v, 0.0, 1.0)))

static func _blotches(img: Image, count: int, r_min: float, r_max: float, col_a: Color, col_b: Color, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var w := img.get_width()
	var h := img.get_height()
	for i in range(count):
		var cx := rng.randi_range(0, w - 1)
		var cy := rng.randi_range(0, h - 1)
		var r := rng.randf_range(r_min, r_max)
		var col := col_a.lerp(col_b, rng.randf())
		var x0 := maxi(0, int(cx - r))
		var x1 := mini(w - 1, int(cx + r))
		var y0 := maxi(0, int(cy - r))
		var y1 := mini(h - 1, int(cy + r))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var d := Vector2(x - cx, y - cy).length() / r
				if d < 1.0:
					var old := img.get_pixel(x, y)
					img.set_pixel(x, y, old.lerp(col, (1.0 - d) * 0.5))

static func tex_rough() -> Texture2D:
	# grayscale roughness variation (0.72..1.0), shared by textured materials
	if _tex_cache.has("rough"):
		return _tex_cache["rough"]
	var img := _make_image(256, 256, Color(0.9, 0.9, 0.9))
	_noise_overlay(img, 0.13, 77)
	_blotches(img, 26, 14.0, 46.0, Color(0.74, 0.74, 0.74), Color(1.0, 1.0, 1.0), 78)
	return _finish(img, "rough")

static func tex_grass() -> Texture2D:
	if _tex_cache.has("grass"):
		return _tex_cache["grass"]
	var img := _make_image(512, 512, Color(0.25, 0.44, 0.18))
	_blotches(img, 60, 22.0, 70.0, Color(0.19, 0.37, 0.14), Color(0.32, 0.51, 0.21), 10)
	_blotches(img, 14, 8.0, 26.0, Color(0.45, 0.48, 0.24), Color(0.48, 0.44, 0.22), 13) # dry patches
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(14000):
		var x := rng.randi_range(0, 511)
		var y := rng.randi_range(0, 511)
		var g := rng.randf_range(0.35, 0.62)
		img.set_pixel(x, y, Color(0.22 + rng.randf() * 0.1, g, 0.16))
	_noise_overlay(img, 0.02, 12)
	return _finish(img, "grass")

static func tex_paving() -> Texture2D:
	if _tex_cache.has("paving"):
		return _tex_cache["paving"]
	var img := _make_image(512, 512, Color(0.52, 0.50, 0.47))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# per-slab tint (4x4 slabs of 128px)
	for sy in range(4):
		for sx in range(4):
			var v := rng.randf_range(-0.045, 0.045)
			var c := img.get_pixel(sx * 128 + 4, sy * 128 + 4)
			img.fill_rect(Rect2i(sx * 128, sy * 128, 128, 128), Color(clampf(c.r + v, 0, 1), clampf(c.g + v, 0, 1), clampf(c.b + v, 0, 1)))
	var grout := Color(0.33, 0.31, 0.29)
	for i in range(0, 512, 128):
		img.fill_rect(Rect2i(i, 0, 2, 512), grout)
		img.fill_rect(Rect2i(0, i, 512, 2), grout)
	_blotches(img, 20, 10.0, 40.0, Color(0.5, 0.48, 0.46), Color(0.66, 0.64, 0.61), 22)
	_noise_overlay(img, 0.03, 23)
	return _finish(img, "paving")

static func tex_asphalt() -> Texture2D:
	if _tex_cache.has("asphalt"):
		return _tex_cache["asphalt"]
	var img := _make_image(512, 512, Color(0.23, 0.23, 0.24))
	_blotches(img, 34, 16.0, 60.0, Color(0.18, 0.18, 0.19), Color(0.30, 0.30, 0.31), 71) # worn patches
	_blotches(img, 8, 20.0, 44.0, Color(0.28, 0.27, 0.25), Color(0.32, 0.30, 0.27), 72) # repairs
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	for i in range(9000):
		var x := rng.randi_range(0, 511)
		var y := rng.randi_range(0, 511)
		var v := rng.randf_range(0.16, 0.38)
		img.set_pixel(x, y, Color(v, v, v * 1.04))
	_noise_overlay(img, 0.02, 74)
	return _finish(img, "asphalt")

static func tex_brick() -> Texture2D:
	if _tex_cache.has("brick"):
		return _tex_cache["brick"]
	var img := _make_image(512, 512, Color(0.70, 0.66, 0.60)) # mortar
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var bh := 21
	var bw := 62
	var rows := 512 / bh
	for row in range(rows + 1):
		var off := bw / 2 if row % 2 == 1 else 0
		for bx in range(-1, 512 / bw + 1):
			var x0 := bx * bw + off
			var hue_j := rng.randf_range(-0.03, 0.03)
			var val_j := rng.randf_range(-0.055, 0.055)
			var base := Color(0.55 + hue_j, 0.30 + hue_j * 0.5, 0.22)
			if rng.randf() < 0.08: # occasional dark burnt brick
				base = Color(0.38, 0.20, 0.15)
			var c := Color(clampf(base.r + val_j, 0, 1), clampf(base.g + val_j, 0, 1), clampf(base.b + val_j, 0, 1))
			img.fill_rect(Rect2i(x0 + 2, row * bh + 2, bw - 3, bh - 3), c)
	# grime near the bottom rows
	for y in range(440, 512):
		for x in range(512):
			var c := img.get_pixel(x, y)
			var f := float(y - 440) / 72.0 * 0.25
			img.set_pixel(x, y, c.lerp(Color(0.30, 0.26, 0.22), f))
	_noise_overlay(img, 0.03, 32)
	return _finish(img, "brick")

static func tex_concrete() -> Texture2D:
	if _tex_cache.has("concrete"):
		return _tex_cache["concrete"]
	var img := _make_image(512, 512, Color(0.78, 0.76, 0.72))
	# formwork panel seams
	var seam := Color(0.66, 0.64, 0.60)
	for i in range(0, 513, 170):
		img.fill_rect(Rect2i(i, 0, 2, 512), seam)
		img.fill_rect(Rect2i(0, i, 512, 2), seam)
	_blotches(img, 22, 12.0, 52.0, Color(0.68, 0.66, 0.62), Color(0.84, 0.83, 0.79), 41) # stains
	_blotches(img, 6, 30.0, 60.0, Color(0.62, 0.60, 0.55), Color(0.70, 0.68, 0.63), 42) # weather streaks
	_noise_overlay(img, 0.035, 43)
	return _finish(img, "concrete")

static func tex_roof() -> Texture2D:
	if _tex_cache.has("roof"):
		return _tex_cache["roof"]
	var img := _make_image(256, 256, Color(0.45, 0.22, 0.16))
	for y in range(256):
		for x in range(256):
			if y % 32 == 0:
				img.set_pixel(x, y, Color(0.30, 0.13, 0.09))
			elif (x + (y / 32) * 16) % 32 == 0:
				img.set_pixel(x, y, Color(0.36, 0.17, 0.12))
	_noise_overlay(img, 0.03, 51)
	return _finish(img, "roof")

static func tex_wood() -> Texture2D:
	if _tex_cache.has("wood"):
		return _tex_cache["wood"]
	var img := _make_image(256, 256, Color(0.45, 0.32, 0.20))
	for x in range(256):
		for y in range(256):
			var s := sin(float(x) * 0.22) * 0.03 + sin(float(x) * 0.05) * 0.02
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + s, c.g + s * 0.7, c.b + s * 0.4))
	return _finish(img, "wood")

static func tex_marble() -> Texture2D:
	if _tex_cache.has("marble"):
		return _tex_cache["marble"]
	var img := _make_image(256, 256, Color(0.85, 0.84, 0.80))
	for x in range(256):
		for y in range(256):
			if x % 128 == 0 or y % 128 == 0:
				img.set_pixel(x, y, Color(0.60, 0.59, 0.56))
			var vein := sin(float(x) * 0.08 + float(y) * 0.05)
			if vein > 0.965:
				img.set_pixel(x, y, Color(0.68, 0.67, 0.64))
	_noise_overlay(img, 0.015, 61)
	return _finish(img, "marble")

static func tex_track() -> Texture2D:
	if _tex_cache.has("track"):
		return _tex_cache["track"]
	var img := _make_image(256, 256, Color(0.62, 0.32, 0.20))
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	for i in range(5000):
		var x := rng.randi_range(0, 255)
		var y := rng.randi_range(0, 255)
		var v := rng.randf_range(-0.06, 0.06)
		var c := img.get_pixel(x, y)
		img.set_pixel(x, y, Color(clampf(c.r + v, 0, 1), clampf(c.g + v * 0.6, 0, 1), clampf(c.b + v * 0.4, 0, 1)))
	_noise_overlay(img, 0.025, 82)
	return _finish(img, "track")

static func tex_flowers() -> Texture2D:
	if _tex_cache.has("flowers"):
		return _tex_cache["flowers"]
	var img := _make_image(256, 256, Color(0.25, 0.44, 0.18))
	_noise_overlay(img, 0.04, 91)
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	var cols := [Color(0.95, 0.45, 0.55), Color(0.98, 0.80, 0.25), Color(0.95, 0.93, 0.90), Color(0.95, 0.55, 0.20), Color(0.75, 0.40, 0.80)]
	for i in range(700):
		var x := rng.randi_range(1, 254)
		var y := rng.randi_range(1, 254)
		var c: Color = cols[rng.randi_range(0, cols.size() - 1)]
		img.set_pixel(x, y, c)
		img.set_pixel(x + 1, y, c)
		img.set_pixel(x, y + 1, c)
	return _finish(img, "flowers")

static func tex_water() -> Texture2D:
	if _tex_cache.has("water"):
		return _tex_cache["water"]
	var img := _make_image(256, 256, Color(0.13, 0.33, 0.46))
	for x in range(256):
		for y in range(256):
			var w := sin(float(x) * 0.11 + float(y) * 0.045) * 0.5 + sin(float(y) * 0.16) * 0.5
			if w > 0.82:
				img.set_pixel(x, y, Color(0.33, 0.54, 0.67))
	_noise_overlay(img, 0.02, 95)
	return _finish(img, "water")

static func tex_shirt_stripe() -> Texture2D:
	if _tex_cache.has("stripe"):
		return _tex_cache["stripe"]
	var img := _make_image(128, 128, Color(1, 1, 1))
	for y in range(128):
		if (y / 16) % 2 == 0:
			for x in range(128):
				img.set_pixel(x, y, Color(0.78, 0.78, 0.80))
	_noise_overlay(img, 0.02, 96)
	return _finish(img, "stripe")

static func tex_shirt_check() -> Texture2D:
	if _tex_cache.has("check"):
		return _tex_cache["check"]
	var img := _make_image(128, 128, Color(1, 1, 1))
	for x in range(128):
		for y in range(128):
			if x % 32 < 3 or y % 32 < 3:
				img.set_pixel(x, y, Color(0.72, 0.72, 0.75))
	_noise_overlay(img, 0.02, 97)
	return _finish(img, "check")

static func mat_tex(tex: Texture2D, tint: Color, uv_scale: Vector2, rough: float = 0.9) -> Material:
	var key := "tex_%d_%s_%s" % [tex.get_instance_id(), str(tint), str(uv_scale)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	m.roughness = rough
	m.roughness_texture = tex_rough()
	_mat_cache[key] = m
	return m

static func mat_color(c: Color, rough: float = 0.85) -> Material:
	var key := "col_%s_%f" % [str(c), rough]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mat_cache[key] = m
	return m

static func mat_glass() -> Material:
	if _mat_cache.has("glass"):
		return _mat_cache["glass"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.30, 0.50, 0.66, 0.88)
	m.metallic = 0.85
	m.roughness = 0.12
	_mat_cache["glass"] = m
	return m

static func mat_emissive(c: Color, energy: float = 1.5) -> Material:
	var key := "emi_%s_%f" % [str(c), energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	_mat_cache[key] = m
	return m
