class_name CharModel
extends RefCounted

## Loads the Blender-built student rigs (assets/characters/student_*.glb,
## built by tools/build_characters.py) and dresses them per character:
## skin/shirt/pants/hair materials re-tinted, one of the 8 baked-in hair
## styles shown, backpack toggled, body scaled to the character's
## height/build. Clips on the AnimationPlayer: idle, walk, run, sit, talk.

const MALE_SCENE: PackedScene = preload("res://assets/characters/student_male.glb")
const FEMALE_SCENE: PackedScene = preload("res://assets/characters/student_female.glb")

const BASE_HEIGHT := 1.785 # metres, as modelled in Blender

static var _mat_cache: Dictionary = {}

static func _mat(c: Color, rough: float) -> Material:
	var key := "cm_%s_%f" % [str(c), rough]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mat_cache[key] = m
	return m

static func _pattern_mat(tex: Texture2D, tint: Color) -> Material:
	var key := "pat_%d_%s" % [tex.get_instance_id(), str(tint)]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.roughness = 0.92
	_mat_cache[key] = m
	return m

static func build(cfg: Dictionary) -> Dictionary:
	var scene: PackedScene = FEMALE_SCENE if cfg.get("female", false) else MALE_SCENE
	var inst: Node3D = scene.instantiate()
	var root := Node3D.new()
	root.name = "Model"
	root.add_child(inst)
	var height: float = cfg.get("height", 1.72)
	var build_w: float = cfg.get("build", 1.0)
	root.scale = Vector3(build_w, height / BASE_HEIGHT, build_w)

	var skin: Color = cfg.get("skin", Color(0.62, 0.44, 0.32))
	var shirt: Color = cfg.get("shirt", Color(0.3, 0.4, 0.8))
	var pants: Color = cfg.get("pants", Color(0.2, 0.2, 0.25))
	var hair_c: Color = cfg.get("hair_color", Color(0.08, 0.06, 0.05))
	var pattern: String = cfg.get("pattern", "")
	var skin_m := _mat(skin, 0.55)
	var shirt_m: Material = _mat(shirt, 0.9)
	if pattern == "stripe":
		shirt_m = _pattern_mat(TexGen.tex_shirt_stripe(), shirt.lightened(0.25))
	elif pattern == "check":
		shirt_m = _pattern_mat(TexGen.tex_shirt_check(), shirt.lightened(0.2))
	var pants_m := _mat(pants, 0.92)
	var hair_m := _mat(hair_c, 0.95)
	var pack_m := _mat(cfg.get("pack_color", Color(0.7, 0.25, 0.2)), 0.9)
	var hair_style: int = cfg.get("hair_style", 0)
	var want_pack: bool = cfg.get("backpack", false)

	var anim: AnimationPlayer = null
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AnimationPlayer:
			anim = n
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var nm := mi.name
			if nm.begins_with("Hair"):
				var idx := -1
				if nm.length() > 4 and nm.substr(4, 1).is_valid_int():
					idx = int(nm.substr(4, 1))
				mi.visible = (idx == hair_style)
				if idx == 4: # cap keeps its own colour
					pass
				else:
					mi.material_override = hair_m
			elif nm == "Backpack" or nm == "BackpackPocket":
				mi.visible = want_pack
				mi.material_override = pack_m
			elif nm == "TorsoLower" or nm == "TorsoUpper" or nm == "Bust" or nm == "Collar" or nm.begins_with("UpperArm"):
				mi.material_override = shirt_m
			elif nm == "Pelvis" or nm.begins_with("Thigh") or nm.begins_with("Shin"):
				mi.material_override = pants_m
			elif nm == "Brows":
				mi.material_override = hair_m
			elif nm == "Eyes" or nm == "Mouth" or nm.begins_with("Shoe"):
				pass # keep Blender materials
			else: # Head, Neck, Forearm, Hand, Ears cluster...
				mi.material_override = skin_m
		for c in n.get_children():
			stack.append(c)
	return {"root": root, "anim": anim, "inst": inst}
