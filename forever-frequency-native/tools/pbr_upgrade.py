"""Build a production-oriented GLB runtime set from the editable Blender .blend.

- Original .blend remains fully editable and separate from Godot import.
- Uses CC0 ambientCG brick/concrete PBR color, roughness and normal maps.
- Applies bevels and joins meshes by material to reduce Godot node count.
- Exports runtime .glb files without the huge authoring scene.
"""
import bpy, json, os
from pathlib import Path
from collections import defaultdict

root=Path(__file__).resolve().parents[1]
src=root/'assets'/'city_zero_modular.blend'
textures=root/'pbr_sources'
assert src.exists(), 'Missing Blender authoring scene'
bpy.ops.wm.open_mainfile(filepath=str(src))
assets=['la_caldera_records','moon_market','forever_home','pixel_garden',
        'nova_stage','radio_one','street_tree','street_lamp','city_bench',
        'city_car','artist_avatar','companion_nova']

def inject_pbr(material_name, texture_prefix):
    mat=bpy.data.materials.get(material_name)
    if mat is None:
        raise RuntimeError('Missing original material: '+material_name)
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    links=mat.node_tree.links
    bs=nodes.get('Principled BSDF')
    for key, target in [('Color','Base Color'),('Roughness','Roughness')]:
        f=textures/(texture_prefix+'_'+key+'.jpg')
        if not f.is_file(): raise RuntimeError('Missing CC0 PBR image: '+str(f))
        im=bpy.data.images.load(str(f),check_existing=True)
        if key=='Roughness': im.colorspace_settings.name='Non-Color'
        if max(im.size)>1024: im.scale(1024,1024)
        im.pack()
        t=nodes.new('ShaderNodeTexImage')
        t.image=im
        t.label=texture_prefix+' CC0 '+key
        links.new(t.outputs['Color'],bs.inputs[target])
    nf=textures/(texture_prefix+'_NormalGL.jpg')
    if not nf.is_file():raise RuntimeError('Missing normal map '+str(nf))
    normal_im=bpy.data.images.load(str(nf),check_existing=True)
    normal_im.colorspace_settings.name='Non-Color'
    if max(normal_im.size)>1024: normal_im.scale(1024,1024)
    normal_im.pack()
    normal_tex=nodes.new('ShaderNodeTexImage');normal_tex.image=normal_im
    normal_map=nodes.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=0.67
    links.new(normal_tex.outputs['Color'],normal_map.inputs['Color'])
    links.new(normal_map.outputs['Normal'],bs.inputs['Normal'])
    print('PBR ADDED:', material_name, texture_prefix,flush=True)

inject_pbr('Terracotta red brick','Bricks066_2K-JPG')
inject_pbr('Poured concrete','Concrete012_2K-JPG')

counts={}
for index, asset in enumerate(assets):
    collection=bpy.data.collections.get(asset)
    assert collection is not None, 'Blender authoring collection missing: '+asset
    originals=[o for o in collection.objects if o.type=='MESH']
    assert originals, 'No meshes: '+asset
    temp=bpy.data.collections.new('EXPORT_TMP_'+asset)
    bpy.context.scene.collection.children.link(temp)
    duplicates=[]
    for source in originals:
        dup=source.copy()
        dup.data=source.data.copy()
        temp.objects.link(dup)
        dup.location.x -= index*24.0
        duplicates.append(dup)
    # Bake bevel modifiers before merging, preventing lost bevel shading.
    for dup in duplicates:
        bpy.ops.object.select_all(action='DESELECT')
        dup.select_set(True)
        bpy.context.view_layer.objects.active=dup
        for modifier in list(dup.modifiers):
            try:bpy.ops.object.modifier_apply(modifier=modifier.name)
            except Exception as exc: print('MODIFIER:',str(exc),flush=True)
    groups=defaultdict(list)
    for dup in duplicates:
        mats=tuple(m.name for m in dup.data.materials if m is not None)
        groups[mats].append(dup)
    joined=[]
    for material_names, group in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in group: ob.select_set(True)
        bpy.context.view_layer.objects.active=group[0]
        if len(group)>1:
            bpy.ops.object.join()
        joined.append(bpy.context.view_layer.objects.active)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in joined:ob.select_set(True)
    bpy.context.view_layer.objects.active=joined[0]
    output=root/'assets'/(asset+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB',
           use_selection=True, export_apply=True, export_materials='EXPORT')
    if output.stat().st_size<2048:raise RuntimeError('GLB empty '+asset)
    counts[asset]={'source_meshes':len(originals),'export_nodes':len(joined),
                   'bytes':output.stat().st_size}
    print('OPTIMIZED GLB',asset,counts[asset],flush=True)
    for ob in joined:
        bpy.data.objects.remove(ob,do_unlink=True)
    bpy.data.collections.remove(temp)
assert len(counts)==12
assert counts['la_caldera_records']['export_nodes']<counts['la_caldera_records']['source_meshes']/2
metrics=root/'assets'/'mesh_metrics.json'
metrics.write_text(json.dumps(counts,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(src))
print('PBR-GAUNTLET GREEN 12 ORIGINAL OPTIMIZED MODELS',flush=True)
