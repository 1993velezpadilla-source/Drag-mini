"""Original Blender move-FX authoring pilot. Run blender -b -t 2 -P this.py -- output."""
import bpy, math, os, sys
from mathutils import Vector
out=sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "/tmp/kindria_blender_fx"
os.makedirs(out,exist_ok=True)
bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine="BLENDER_EEVEE_NEXT"
scene.render.resolution_x=96;scene.render.resolution_y=96;scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG";scene.render.image_settings.color_mode="RGBA";scene.render.film_transparent=True
scene.view_settings.view_transform="Standard"
bpy.ops.object.camera_add(location=(0,-8,5));cam=bpy.context.object
cam.rotation_euler=(Vector((0,0,0.4))-cam.location).to_track_quat("-Z","Y").to_euler()
cam.data.type="ORTHO";cam.data.ortho_scale=5;scene.camera=cam
def mat(name,color):
    m=bpy.data.materials.new(name);m.use_nodes=True
    nodes=m.node_tree.nodes;nodes.clear()
    emission=nodes.new("ShaderNodeEmission");emission.inputs[0].default_value=(*color,1);emission.inputs[1].default_value=1
    output=nodes.new("ShaderNodeOutputMaterial");m.node_tree.links.new(emission.outputs[0],output.inputs[0]);return m
dark=mat("Original briar forest",(.06,.25,.09));light=mat("Leaf edge",(.55,.83,.22))
curve=bpy.data.curves.new("Animated whip spine","CURVE");curve.dimensions="3D";curve.bevel_depth=.105;curve.bevel_resolution=1
spline=curve.splines.new("POLY");spline.points.add(19)
ob=bpy.data.objects.new("Briar whip",curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(dark)
leaves=[]
for i in range(4):
    mesh=bpy.data.meshes.new("Leaf_"+str(i));mesh.from_pydata([(-.18,0,0),(0,0,.23),(.18,0,0),(0,0,-.12)],[],[(0,1,2,3)])
    leaf=bpy.data.objects.new("Leaf_"+str(i),mesh);bpy.context.collection.objects.link(leaf);leaf.data.materials.append(light);leaves.append(leaf)
for frame in range(1,13):
    t=(frame-1)/11
    extent=.25+.75*math.sin(t*math.pi*.9)
    for i,point in enumerate(spline.points):
        f=i/19;point.co=(-1.7+3.4*f*extent,0,.4+math.sin(f*math.tau*1.2-t*5)*.46*f,1)
        point.keyframe_insert(data_path="co",frame=frame)
    for j,leaf in enumerate(leaves):
        f=(j+1)/5;leaf.location=(-1.7+3.4*f*extent,-.01,.4+math.sin(f*math.tau*1.2-t*5)*.46*f)
        leaf.rotation_euler[1]=(-1)**j*.8
        leaf.keyframe_insert(data_path="location",frame=frame);leaf.keyframe_insert(data_path="rotation_euler",frame=frame)
scene.frame_start=1;scene.frame_end=12
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,"original_briar_whip.blend"))
for frame in range(1,13):
    scene.frame_set(frame);scene.render.filepath=os.path.join(out,f"briar_{frame:02d}.png");bpy.ops.render.render(write_still=True)
print("KINDRIA_BLENDER_BRIAR_PASS 12")
