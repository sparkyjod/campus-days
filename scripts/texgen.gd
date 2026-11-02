class_name TexGen
extends RefCounted

## Procedural canvas textures + shared materials. No external assets.
## Every texture is generated once and cached; materials are shared across
## all meshes that use them (performance rule from the master prompt).

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func _make_image(w: int, h: int, fill: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(fill)
	return img

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

static func tex_grass() -> Texture2D:
	if _tex_cache.has("grass"):
		return _tex_cache["grass"]
	var img := _make_image(256, 256, Color(0.30, 0.50, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(6000):
		var x := rng.randi_range(0, 255)
		var y := rng.randi_range(0, 255)
		var g := rng.randf_range(0.35, 0.62)
		img.set_pixel(x, y, Color(0.22 + rng.randf() * 0.1, g, 0.16))
	_noise_overlay(img, 0.02, 12)
	var t := ImageTexture.create_from_image(img)
	_tex_cache["grass"] = t
	return t

static func tex_paving() -> Texture2D:
	if _tex_cache.has("paving"):
		return _tex_cache["paving"]
	var img := _make_image(256, 256, Color(0.62, 0.60, 0.57))
	var grout := Color(0.42, 0.40, 0.38)
	for x in range(256):
		for y in range(256):
			if x % 64 == 0 or y % 64 == 0:
				img.set_pixel(x, y, grout)
	_noise_overlay(img, 0.03, 21)
	var t := ImageTexture.create_from_image(img)
	_tex_cache["paving"] = t
	return t

static func tex_brick() -> Texture2D:
	if _tex_cache.has("brick"):
		return _tex_cache["brick"]
	var img := _make_image(256, 256, Color(0.55, 0.30, 0.22))
	var mortar := Color(0.72, 0.68, 0.62)
	var bh := 16
	var bw := 42
	for y in range(256):
		for x in range(256):
			var row := y / bh
			var off := bw / 2 if row % 2 == 1 else 0
			if y % bh == 0 or (x + off) % bw == 0:
				img.set_pixel(x, y, mortar)
	_noise_overlay(img, 0.045, 31)
	var t := ImageTexture.create_from_image(img)
	_tex_cache["brick"] = t
	return t

static func tex_concrete() -> Texture2D:
	if _tex_cache.has("concrete"):
		return _tex_cache["concrete"]
	var img := _make_image(256, 256, Color(0.78, 0.76, 0.72))
	_noise_overlay(img, 0.035, 41)
	var t := ImageTexture.create_from_image(img)
	_tex_cache["concrete"] = t
	return t

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
	var t := ImageTexture.create_from_image(img)
	_tex_cache["roof"] = t
	return t

static func tex_wood() -> Texture2D:
	if _tex_cache.has("wood"):
		return _tex_cache["wood"]
	var img := _make_image(256, 256, Color(0.45, 0.32, 0.20))
	for x in range(256):
		for y in range(256):
			var s := sin(float(x) * 0.22) * 0.03 + sin(float(x) * 0.05) * 0.02
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + s, c.g + s * 0.7, c.b + s * 0.4))
	var t := ImageTexture.create_from_image(img)
	_tex_cache["wood"] = t
	return t

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
	var t := ImageTexture.create_from_image(img)
	_tex_cache["marble"] = t
	return t

static func mat_tex(tex: Texture2D, tint: Color, uv_scale: Vector2, rough: float = 0.9) -> Material:
	var key := "tex_%d_%s_%s" % [tex.get_instance_id(), str(tint), str(uv_scale)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	m.roughness = rough
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
	m.albedo_color = Color(0.35, 0.55, 0.70, 0.85)
	m.metallic = 0.6
	m.roughness = 0.15
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
