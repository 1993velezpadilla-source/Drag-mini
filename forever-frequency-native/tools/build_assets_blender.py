"""Generate original low-poly-to-midpoly modular 3D assets with Blender.

Run: blender -b -t 2 --python tools/build_assets_blender.py
No proprietary game assets or downloaded character models required.
"""
from __future__ import annotations
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets"
OUT.mkdir(parents=True, exist_ok=True)


def mat(name, color, metallic=0.0, roughness=0.5, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Emission Color'].default_value = (*color, 1)
    bsdf.inputs['Emission Strength'].default_value = emission
    return m

NAVY = mat('Midnight powdercoat', (.045,.07,.17),0.45,0.35)
STEEL = mat('Brushed chrome', (.39,.52,.67),0.75,0.28)
CYAN = mat('Cyan neon tubes',(.07,.83,.93),0.1,0.18,3.0)
MAGENTA = mat('Magenta neon tubes',(.98,.12,.62),0.1,0.16,3.1)
GLASS = mat('Architectural glass',(.08,.29,.44),0.65,0.12)
STONE = mat('Stone tiles',(.48,.50,.56),0.0,0.82)
WARM = mat('Warm paper',(.92,.71,.48),0.0,0.9,0.7)


def box(name, loc, size, material, bevel=.035):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    if bevel:
        mod = o.modifiers.new('Real bevels', 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        if hasattr(mod, 'affect'):
            mod.affect = 'EDGES'
        mod2 = o.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    return o


def text_obj(label, name, loc, size, material):
    bpy.ops.object.text_add(location=loc)
    o = bpy.context.object
    o.name = name
    o.data.body = label
    o.data.align_x = 'CENTER'
    o.data.size = size
    o.data.extrude = .025
    o.data.bevel_depth = .005
    o.data.materials.append(material)
    o.rotation_euler = (math.pi / 2, 0, 0)
    return o


def torus(name, loc, major, minor, material, rotate=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=64, minor_segments=8,
            location=loc, major_radius=major, minor_radius=minor,
            rotation=rotate)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    return o


def clear_selection():
    bpy.ops.object.select_all(action='DESELECT')


def export_selected(name, objects):
    clear_selection()
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT / name),
                              export_format='GLB',
                              use_selection=True,
                              export_apply=True,
                              export_materials='EXPORT')
    clear_selection()

# Architectural studio front — 3D sign, light rails, canopy, glass, a door.
studio = []
studio.append(box('Facade metal portal', (0,2.1,0), (5.9,4.25,.22),NAVY,.1))
studio.append(box('Glass entrance', (0,1.25,-.14),(2.25,2.45,.10),GLASS,.03))
studio.append(box('Sliding door L',(-.57,1.22,-.22),(.035,2.3,.08),CYAN,.01))
studio.append(box('Sliding door R',(.57,1.22,-.22),(.035,2.3,.08),CYAN,.01))
studio.append(box('Sliding track',(0,2.46,-.25),(2.36,.12,.15),STEEL,.01))
studio.append(box('Canopy',(0,3.28,-.95),(5.9,.24,1.95),STEEL,.12))
studio.append(box('Neon vertical left',(-2.84,2.08,-.22),(.085,3.85,.085),MAGENTA,.02))
studio.append(box('Neon vertical right',(2.84,2.08,-.22),(.085,3.85,.085),MAGENTA,.02))
studio.append(box('Neon arch top',(0,4.03,-.18),(5.7,.09,.09),CYAN,.02))
studio.append(box('Threshold',(0,.09,-.75),(4.4,.18,1.7),STONE,.05))
studio.append(text_obj('ECHO', 'Architectural front lettering', (0,3.52,-1.07), .7, MAGENTA))
studio.append(text_obj('STUDIO','Below lettering',(0,2.9,-1.09),.36,WARM))
export_selected('studio_entrance.glb', studio)

# The same source Blender file also includes kit parts for editable future mods.
kiosk = []
kiosk.append(box('Market base',(0,.15,0),(3.2,.3,2.6),STONE,.06))
kiosk.append(box('Kiosk main',(0,1.65,0),(2.9,2.65,2.3),NAVY,.1))
kiosk.append(box('Market glass',(0,1.85,-1.2),(2.55,1.6,.08),GLASS,.02))
kiosk.append(box('Shop canopy',(0,3.05,-1.55),(3.35,.3,1.3),MAGENTA,.05))
kiosk.append(text_obj('LIVE', 'Kiosk marquee', (0,3.13,-1.67),.25,CYAN))
export_selected('street_kiosk.glb', kiosk)

clear_selection()
for o in studio+kiosk:
    o.select_set(True)
bpy.context.view_layer.objects.active = studio[0]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'city_zero_modular.blend'))
print('Blender generated:', [p.name for p in OUT.glob('*.glb')])
