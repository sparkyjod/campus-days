# Campus Days — Blender character pipeline (headless, bpy).
#
# Builds two rigged student base characters (male + female) from smooth,
# bevelled forms — no boxes/capsules as final geometry — skinned rigidly
# to a humanoid armature, with baked animation actions:
#   idle, walk, run, sit, talk
# Each GLB contains ALL 8 hair styles as separate named meshes (Godot
# shows one, hides the rest) plus a backpack mesh (toggled per character).
#
# Run:
#   blender -b --python tools/build_characters.py -- <output_dir>
# Output: student_male.glb, student_female.glb (+ pose-check renders in /tmp)

import bpy
import math
import os
import sys
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT_DIR = argv[0] if argv else os.path.expanduser("~/workspace/campus-days-godot/assets/characters")
os.makedirs(OUT_DIR, exist_ok=True)
CHECK_DIR = "/tmp/pose_check"
os.makedirs(CHECK_DIR, exist_ok=True)

FPS = 24

# ---------------------------------------------------------------- materials

def make_materials():
    mats = {}
    def mat(name, color, rough=0.85):
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        mats[name] = m
        return m
    mat("Skin", (0.62, 0.44, 0.32), 0.55)
    mat("Shirt", (0.30, 0.40, 0.80), 0.9)
    mat("Pants", (0.20, 0.20, 0.25), 0.9)
    mat("Hair", (0.08, 0.06, 0.05), 0.95)
    mat("Shoes", (0.12, 0.12, 0.13), 0.6)
    mat("Pack", (0.70, 0.25, 0.20), 0.9)
    mat("Eye", (0.05, 0.04, 0.04), 0.35)
    mat("Lip", (0.50, 0.26, 0.24), 0.7)
    return mats

# ---------------------------------------------------------------- helpers

def clean_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures,
                 bpy.data.materials, bpy.data.actions, bpy.data.cameras, bpy.data.lights):
        pass  # keep datablocks; objects are what matters for export

def activate(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

def finish_part(obj, name, bone, mat, arm_obj):
    """Assign material, rigid skin weight to one bone, armature modifier."""
    obj.name = name
    if mat is not None:
        obj.data.materials.append(mat)
    if bone is not None:
        vg = obj.vertex_groups.new(name=bone)
        vg.add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
        mod = obj.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm_obj
    obj.parent = arm_obj
    return obj

def ellipsoid(name, loc, scale, mat, bone, arm_obj, segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=loc)
    obj = bpy.context.active_object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    return finish_part(obj, name, bone, mat, arm_obj)

def rbox(name, loc, dims, bevel, mat, bone, arm_obj, rot=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.scale = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("bev", 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        activate(obj)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish_part(obj, name, bone, mat, arm_obj)

def limb(name, p1, p2, radius, mat, bone, arm_obj, cap_scale=1.0):
    """Cylinder between two points + sphere caps, joined into one mesh."""
    p1 = Vector(p1); p2 = Vector(p2)
    mid = (p1 + p2) * 0.5
    direction = p2 - p1
    length = direction.length
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=radius, depth=length, location=mid)
    cyl = bpy.context.active_object
    cyl.rotation_mode = 'QUATERNION'
    cyl.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    bpy.ops.object.shade_smooth()
    parts = [cyl]
    for p in (p1, p2):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=radius * cap_scale, location=p)
        parts.append(bpy.context.active_object)
        bpy.ops.object.shade_smooth()
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = cyl
    bpy.ops.object.join()
    return finish_part(cyl, name, bone, mat, arm_obj)

# ---------------------------------------------------------------- armature

BONES = [
    # name, head, tail, parent
    ("Hips",      (0, 0, 0.98),      (0, 0, 1.10),      None),
    ("Spine",     (0, 0, 1.10),      (0, 0, 1.26),      "Hips"),
    ("Chest",     (0, 0, 1.26),      (0, 0, 1.46),      "Spine"),
    ("Neck",      (0, 0, 1.46),      (0, 0, 1.55),      "Chest"),
    ("Head",      (0, 0, 1.55),      (0, 0, 1.76),      "Neck"),
    ("Shoulder.L", (0.05, 0, 1.44),  (0.20, 0, 1.45),   "Chest"),
    ("UpperArm.L", (0.21, 0, 1.45),  (0.24, 0, 1.18),   "Shoulder.L"),
    ("Forearm.L",  (0.24, 0, 1.18),  (0.25, 0, 0.94),   "UpperArm.L"),
    ("Hand.L",     (0.25, 0, 0.94),  (0.25, 0, 0.82),   "Forearm.L"),
    ("Shoulder.R", (-0.05, 0, 1.44), (-0.20, 0, 1.45),  "Chest"),
    ("UpperArm.R", (-0.21, 0, 1.45), (-0.24, 0, 1.18),  "Shoulder.R"),
    ("Forearm.R",  (-0.24, 0, 1.18), (-0.25, 0, 0.94),  "UpperArm.R"),
    ("Hand.R",     (-0.25, 0, 0.94), (-0.25, 0, 0.82),  "Forearm.R"),
    ("UpperLeg.L", (0.10, 0, 0.96),  (0.11, 0, 0.52),   "Hips"),
    ("Shin.L",     (0.11, 0, 0.52),  (0.11, 0, 0.09),   "UpperLeg.L"),
    ("Foot.L",     (0.11, 0, 0.09),  (0.11, -0.13, 0.05), "Shin.L"),
    ("UpperLeg.R", (-0.10, 0, 0.96), (-0.11, 0, 0.52),  "Hips"),
    ("Shin.R",     (-0.11, 0, 0.52), (-0.11, 0, 0.09),  "UpperLeg.R"),
    ("Foot.R",     (-0.11, 0, 0.09), (-0.11, -0.13, 0.05), "Shin.R"),
]

def build_armature():
    data = bpy.data.armatures.new("StudentRig")
    arm = bpy.data.objects.new("StudentRig", data)
    bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for name, head, tail, parent in BONES:
        b = data.edit_bones.new(name)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm

# ---------------------------------------------------------------- body

def build_body(arm, mats, female):
    S = mats["Skin"]; T = mats["Shirt"]; P = mats["Pants"]
    H = mats["Hair"]; SH = mats["Shoes"]; PK = mats["Pack"]
    chest_w = 0.32 if female else 0.36
    pelvis_x = 0.168 if female else 0.155
    arm_r = 0.046 if female else 0.052
    # pelvis + torso
    ellipsoid("Pelvis", (0, 0, 1.00), (pelvis_x, 0.115, 0.10), P, "Hips", arm)
    rbox("TorsoLower", (0, 0, 1.17), ((0.26 if female else 0.30), 0.19, 0.24), 0.045, T, "Spine", arm)
    rbox("TorsoUpper", (0, 0, 1.35), (chest_w, 0.21, 0.26), 0.05, T, "Chest", arm)
    if female:
        ellipsoid("Bust", (0, -0.085, 1.36), (0.135, 0.055, 0.085), T, "Chest", arm)
    # collar + neck
    rbox("Collar", (0, 0, 1.485), (0.17, 0.13, 0.05), 0.02, T, "Chest", arm)
    limb("Neck", (0, 0, 1.44), (0, 0, 1.56), 0.042, S, "Neck", arm)
    # head cluster (joined): skull + jaw
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=1.0, location=(0, 0, 1.66))
    skull = bpy.context.active_object
    skull.scale = (0.104, 0.114, 0.124)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=1.0, location=(0, -0.012, 1.585))
    jaw = bpy.context.active_object
    jaw.scale = (0.082, 0.088, 0.068)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0, location=(0, -0.112, 1.645))
    nose = bpy.context.active_object
    nose.scale = (0.017, 0.026, 0.020)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    ears = []
    for sx in (1, -1):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0, location=(0.104 * sx, 0, 1.65))
        e = bpy.context.active_object
        e.scale = (0.018, 0.012, 0.028)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.ops.object.shade_smooth()
        ears.append(e)
    for o in [skull, jaw, nose] + ears:
        o.select_set(True)
    bpy.context.view_layer.objects.active = skull
    bpy.ops.object.join()
    finish_part(skull, "Head", "Head", S, arm)
    # eyes (joined), brows (joined), mouth
    # FIX 2026-11-03 (D3): eyes enlarged ~55% so they read at street-level
    # camera distance instead of tiny dots; brows/mouth strengthened to match.
    eyes = []
    for sx in (1, -1):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0, location=(0.040 * sx, -0.106, 1.683))
        e = bpy.context.active_object
        e.scale = (0.021, 0.010, 0.025)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.ops.object.shade_smooth()
        eyes.append(e)
    for o in eyes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = eyes[0]
    bpy.ops.object.join()
    finish_part(eyes[0], "Eyes", "Head", mats["Eye"], arm)
    brows = []
    for sx in (1, -1):
        b = rbox("tmp", (0.042 * sx, -0.099, 1.713), (0.056, 0.010, 0.015), 0.004, None, None, arm)
        brows.append(b)
    for o in brows:
        o.select_set(True)
    bpy.context.view_layer.objects.active = brows[0]
    bpy.ops.object.join()
    finish_part(brows[0], "Brows", "Head", H, arm)
    rbox("Mouth", (0, -0.104, 1.602), (0.046, 0.006, 0.011), 0.003, mats["Lip"], "Head", arm)
    # arms
    for side, sx in (("L", 1), ("R", -1)):
        limb("UpperArm." + side, (0.215 * sx, 0, 1.44), (0.24 * sx, 0, 1.19), arm_r, T, "UpperArm." + side, arm)
        limb("Forearm." + side, (0.24 * sx, 0, 1.17), (0.25 * sx, 0, 0.95), 0.040, S, "Forearm." + side, arm)
        ellipsoid("Hand." + side, (0.25 * sx, 0, 0.885), (0.034, 0.020, 0.058), S, "Hand." + side, arm)
    # legs + shoes
    for side, sx in (("L", 1), ("R", -1)):
        limb("Thigh." + side, (0.105 * sx, 0, 0.95), (0.11 * sx, 0, 0.53), 0.070, P, "UpperLeg." + side, arm)
        limb("Shin." + side, (0.11 * sx, 0, 0.51), (0.11 * sx, 0, 0.10), 0.049, P, "Shin." + side, arm)
        rbox("Shoe." + side, (0.11 * sx, -0.038, 0.032), (0.088, 0.235, 0.062), 0.025, SH, "Foot." + side, arm)
    # backpack (toggled per character in Godot)
    rbox("Backpack", (0, 0.175, 1.30), (0.34, 0.15, 0.42), 0.05, PK, "Chest", arm)
    rbox("BackpackPocket", (0, 0.265, 1.26), (0.24, 0.05, 0.24), 0.02, PK, "Chest", arm)
    build_hair(arm, mats)

def build_hair(arm, mats):
    """8 styles as separate meshes, rigid to Head bone. Style ids match
    CharData hair_style: 0 short, 1 long, 2 bun, 3 curly, 4 cap,
    5 ponytail, 6 wavy medium, 7 buzz."""
    H = mats["Hair"]; T = mats["Shirt"]
    # Cap sits BACK and UP: front hairline must stay above the brow line
    # (eyes at z=1.683, face front at y=-0.104). A centred ellipsoid bowl
    # covers the eyes — QA render caught that; do not re-centre it.
    top = (0, 0.030, 1.700)
    cap_scale = (0.113, 0.124, 0.106)
    # 0 short crop
    ellipsoid("Hair0", top, cap_scale, H, "Head", arm)
    # 1 long: cap + back sheet + side falls
    ellipsoid("tmp", top, cap_scale, H, "Head", arm).name = "Hair1a"
    rbox("Hair1b", (0, 0.085, 1.42), (0.20, 0.045, 0.52), 0.02, H, "Head", arm)
    for sx in (1, -1):
        rbox("tmp", (0.105 * sx, 0.01, 1.50), (0.035, 0.10, 0.34), 0.015, H, "Head", arm).name = "Hair1c"
    # merge Hair1 parts
    parts = [o for o in bpy.context.scene.objects if o.name.startswith("Hair1")]
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = "Hair1"
    # 2 bun
    ellipsoid("tmp", top, cap_scale, H, "Head", arm).name = "Hair2a"
    ellipsoid("Hair2b", (0, 0.045, 1.80), (0.052, 0.052, 0.052), H, "Head", arm)
    parts = [o for o in bpy.context.scene.objects if o.name.startswith("Hair2")]
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = "Hair2"
    # 3 curly: cluster of spheres
    curls = []
    rng_pts = [(0, 0, 1.775), (0.06, -0.03, 1.745), (-0.06, -0.03, 1.745), (0.075, 0.03, 1.72),
               (-0.075, 0.03, 1.72), (0.03, -0.075, 1.73), (-0.03, -0.075, 1.73), (0, 0.06, 1.75),
               (0.095, -0.01, 1.68), (-0.095, -0.01, 1.68), (0.045, 0.075, 1.70), (-0.045, 0.075, 1.70)]
    for i, p in enumerate(curls_pts(rng_pts)):
        e = ellipsoid("tmp", p, (0.048, 0.048, 0.048), H, "Head", arm)
        e.name = "Hair3_%d" % i
        curls.append(e)
    for o in curls:
        o.select_set(True)
    bpy.context.view_layer.objects.active = curls[0]
    bpy.ops.object.join()
    curls[0].name = "Hair3"
    # 4 cap: dome + brim (shirt-coloured; Godot re-tints with Hair slot rule -> uses own mat name CapMat)
    capmat = bpy.data.materials.new("Cap")
    capmat.use_nodes = True
    capmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.25, 0.25, 0.28, 1.0)
    capmat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    ellipsoid("tmp", (0, 0.028, 1.705), (0.115, 0.125, 0.100), capmat, "Head", arm).name = "Hair4a"
    rbox("Hair4b", (0, -0.128, 1.700), (0.15, 0.13, 0.016), 0.006, capmat, "Head", arm)
    parts = [o for o in bpy.context.scene.objects if o.name.startswith("Hair4")]
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = "Hair4"
    # 5 ponytail: cap + tail
    ellipsoid("tmp", top, cap_scale, H, "Head", arm).name = "Hair5a"
    limb("Hair5b", (0, 0.10, 1.72), (0, 0.135, 1.38), 0.034, H, "Head", arm)
    parts = [o for o in bpy.context.scene.objects if o.name.startswith("Hair5")]
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = "Hair5"
    # 6 wavy medium: bigger cap + side panels
    ellipsoid("tmp", (0, 0.028, 1.694), (0.119, 0.130, 0.116), H, "Head", arm).name = "Hair6a"
    for sx in (1, -1):
        rbox("tmp", (0.112 * sx, 0.005, 1.565), (0.032, 0.115, 0.21), 0.014, H, "Head", arm).name = "Hair6b"
    parts = [o for o in bpy.context.scene.objects if o.name.startswith("Hair6")]
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = "Hair6"
    # 7 buzz: tight cap
    ellipsoid("Hair7", (0, 0.028, 1.688), (0.109, 0.120, 0.100), H, "Head", arm)

def curls_pts(pts):
    return pts

# ---------------------------------------------------------------- animation

def key_pose(arm, frame, rot=None, hips_loc=None):
    rot = rot or {}
    bpy.context.scene.frame_set(frame)
    for pb in arm.pose.bones:
        # FIX 2026-11-03 (D4/D5 root cause): Blender pose bones default to
        # QUATERNION rotation mode, so setting rotation_euler was silently
        # ignored and every clip exported as identity (straight legs, no sit
        # drop, no arm swing — only the Hips location bob survived). Force
        # XYZ Euler mode so the euler keyframes actually drive the pose.
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler = (0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)
    for name, r in rot.items():
        arm.pose.bones[name].rotation_euler = tuple(math.radians(a) for a in r)
    if hips_loc is not None:
        arm.pose.bones["Hips"].location = hips_loc
    for pb in arm.pose.bones:
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    arm.pose.bones["Hips"].keyframe_insert(data_path="location", frame=frame)

def make_action(arm, name, keys):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = act
    for frame, rot, hips in keys:
        key_pose(arm, frame, rot, hips)
    return act

def build_actions(arm):
    D = math.degrees  # not needed; poses already in degrees below
    # ---- idle: 48f loop, breathing + slight sway
    idle_keys = []
    for f, chest, head_ry, arm_rz in ((1, 1.2, -3.0, 3.0), (25, 2.6, 3.0, 4.2), (49, 1.2, -3.0, 3.0)):
        idle_keys.append((f, {
            "Chest": (chest, 0, 0), "Spine": (0.6, 0, 0), "Head": (-1.0, head_ry, 0),
            "UpperArm.L": (0, 0, arm_rz), "UpperArm.R": (0, 0, -arm_rz),
            "Forearm.L": (-6, 0, 0), "Forearm.R": (-6, 0, 0),
        }, (0, 0, 0.002 if f == 25 else 0.0)))
    make_action(arm, "idle", idle_keys)
    # ---- walk: 20f loop. Forward swing = negative rotation.x (faces -Y).
    def walk_pose(leg_l, shin_l, leg_r, shin_r, bob):
        return {
            "UpperLeg.L": (leg_l, 0, 0), "UpperLeg.R": (leg_r, 0, 0),
            "Shin.L": (shin_l, 0, 0), "Shin.R": (shin_r, 0, 0),
            "Foot.L": (-(leg_l + shin_l) * 0.65, 0, 0), "Foot.R": (-(leg_r + shin_r) * 0.65, 0, 0),
            "UpperArm.L": (-leg_l * 0.7, 0, 3), "UpperArm.R": (-leg_r * 0.7, 0, -3),
            "Forearm.L": (-10, 0, 0), "Forearm.R": (-10, 0, 0),
            "Chest": (1.5, leg_l * 0.10, 0), "Head": (-1.5, 0, 0),
        }, (0, 0, bob)
    wk = []
    for f, args in ((1, (-32, 8, 28, 40, 0.0)), (6, (-4, 28, 2, 6, -0.016)),
                    (11, (28, 40, -32, 8, 0.0)), (16, (2, 6, -4, 28, -0.016)),
                    (21, (-32, 8, 28, 40, 0.0))):
        rot, hips = walk_pose(*args)
        wk.append((f, rot, hips))
    make_action(arm, "walk", wk)
    # ---- run: 16f loop, bigger swing, bent arms, forward lean
    def run_pose(leg_l, shin_l, leg_r, shin_r, bob):
        return {
            "UpperLeg.L": (leg_l, 0, 0), "UpperLeg.R": (leg_r, 0, 0),
            "Shin.L": (shin_l, 0, 0), "Shin.R": (shin_r, 0, 0),
            "Foot.L": (-(leg_l + shin_l) * 0.5, 0, 0), "Foot.R": (-(leg_r + shin_r) * 0.5, 0, 0),
            "UpperArm.L": (-leg_l * 0.6, 0, 4), "UpperArm.R": (-leg_r * 0.6, 0, -4),
            "Forearm.L": (-68, 0, 0), "Forearm.R": (-68, 0, 0),
            "Spine": (7, 0, 0), "Chest": (9, leg_l * 0.08, 0), "Head": (-8, 0, 0),
        }, (0, 0, bob)
    rk = []
    for f, args in ((1, (-48, 14, 40, 78, 0.01)), (5, (-6, 55, 4, 12, -0.03)),
                    (9, (40, 78, -48, 14, 0.01)), (13, (4, 12, -6, 55, -0.03)),
                    (17, (-48, 14, 40, 78, 0.01))):
        rot, hips = run_pose(*args)
        rk.append((f, rot, hips))
    make_action(arm, "run", rk)
    # ---- sit: 48f loop, seated on ~0.46 m bench (hips drop 0.47)
    sit_base = {
        "UpperLeg.L": (-86, 0, 0), "UpperLeg.R": (-86, 0, 0),
        "Shin.L": (84, 0, 0), "Shin.R": (84, 0, 0),
        "Foot.L": (2, 0, 0), "Foot.R": (2, 0, 0),
        "UpperArm.L": (-16, 0, 4), "UpperArm.R": (-16, 0, -4),
        "Forearm.L": (-10, 0, 0), "Forearm.R": (-10, 0, 0),
        "Spine": (5, 0, 0), "Head": (-3, 0, 0),
    }
    sk = []
    for f, chest in ((1, 3.0), (25, 4.4), (49, 3.0)):
        p = dict(sit_base)
        p["Chest"] = (chest, 0, 0)
        sk.append((f, p, (0, 0, -0.47)))
    make_action(arm, "sit", sk)
    # ---- talk: 40f loop, right-hand gestures + head nods
    tk = []
    for f, ua_r, fa_r, nod in ((1, -22, -34, 0.0), (11, -34, -52, -5.0),
                               (21, -26, -40, 0.0), (31, -36, -58, -4.0),
                               (41, -22, -34, 0.0)):
        tk.append((f, {
            "UpperArm.R": (ua_r, 0, -8), "Forearm.R": (fa_r, 0, 0),
            "Hand.R": (0, 0, math.sin(f) * 6.0),
            "UpperArm.L": (-6, 0, 5), "Forearm.L": (-14, 0, 0),
            "Head": (nod, 2.0, 0), "Chest": (2.0, 2.5, 0), "Spine": (1.0, 0, 0),
        }, (0, 0, 0.0)))
    make_action(arm, "talk", tk)
    # reset pose
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)

# ---------------------------------------------------------------- render check

def pose_renders(arm, tag):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.render.resolution_x = 420
    scene.render.resolution_y = 560
    scene.render.film_transparent = False
    cam_data = bpy.data.cameras.new("CheckCam")
    cam = bpy.data.objects.new("CheckCam", cam_data)
    bpy.context.collection.objects.link(cam)
    cam.location = (1.9, -3.1, 1.55)
    direction = Vector((0, 0, 0.92)) - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam
    checks = [("idle", 2), ("walk", 6), ("run", 5), ("sit", 3), ("talk", 11)]
    for name, frame in checks:
        act = bpy.data.actions.get(name)
        if act is None:
            continue
        arm.animation_data.action = act
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        scene.render.filepath = os.path.join(CHECK_DIR, "%s_%s.png" % (tag, name))
        bpy.ops.render.render(write_still=True)
    arm.animation_data.action = None
    bpy.data.objects.remove(cam, do_unlink=True)

# ---------------------------------------------------------------- export

def export_glb(path):
    kwargs = dict(filepath=path, export_format='GLB', export_animations=True,
                  export_skins=True, export_yup=True, export_apply=False)
    try:
        bpy.ops.export_scene.gltf(export_animation_mode='ACTIONS', **kwargs)
    except TypeError:
        bpy.ops.export_scene.gltf(**kwargs)
    print("[BUILD] exported", path, os.path.getsize(path), "bytes")

def build_variant(female, filename):
    print('[STAGE] clean', flush=True)
    clean_scene()
    mats = make_materials()
    print('[STAGE] armature', flush=True)
    arm = build_armature()
    print('[STAGE] body', flush=True)
    build_body(arm, mats, female)
    print('[STAGE] actions', flush=True)
    build_actions(arm)
    # NOTE: no in-Blender pose renders — Workbench needs libEGL (absent on
    # this VM) and aborts the process. Poses are verified instead through
    # the Godot xvfb capture set (close-up / walk / seated / dialogue).
    print('[STAGE] export', flush=True)
    export_glb(os.path.join(OUT_DIR, filename))

build_variant(False, "student_male.glb")
build_variant(True, "student_female.glb")
print("[BUILD] DONE")
