"""Small synthetic GLB regression tests. No Blender dependency."""
import json, struct, unittest
from dungeon_art_adversarial import inspect_glb, evaluate
def glb(points,material=0):
    payload=struct.pack('<'+'f'*len(points)*3,*(x for p in points for x in p))
    doc={'asset':{'version':'2.0'},'nodes':[{'mesh':0}],'meshes':[{'primitives':[{'attributes':{'POSITION':0},'material':material}]}],
         'accessors':[{'bufferView':0,'componentType':5126,'type':'VEC3','count':len(points)}],
         'bufferViews':[{'buffer':0,'byteLength':len(payload)}],'buffers':[{'byteLength':len(payload)}]}
    js=json.dumps(doc).encode();js+=b' '*(-len(js)%4)
    return struct.pack('<4sII',b'glTF',2,28+len(js)+len(payload))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(payload),b'BIN\0')+payload
PTS=[(-.5,0,-.4),(.5,0,.4),(.25,1,-.2)]
class TestAudit(unittest.TestCase):
    def test_material_only(self):
        self.assertEqual(inspect_glb(glb(PTS,0))['geometry_sha256'],inspect_glb(glb(PTS,1))['geometry_sha256'])
    def test_resize_translate(self):
        a=inspect_glb(glb(PTS));b=inspect_glb(glb([(2*x+1,3*y-2,.5*z+1) for x,y,z in PTS]))
        self.assertNotEqual(a['geometry_sha256'],b['geometry_sha256'])
        self.assertEqual(a['normalized_shape_sha256'],b['normalized_shape_sha256'])
    def test_real_shape_change(self):
        a=inspect_glb(glb(PTS));b=inspect_glb(glb([PTS[0],PTS[1],(.13,1,-.06)]))
        self.assertNotEqual(a['normalized_shape_sha256'],b['normalized_shape_sha256'])
    def test_oversized(self):
        result=evaluate({'dungeon_forest_wall':glb([(-.9,0,-.4),(.5,0,.4),(.25,1,-.2)])})
        self.assertTrue(any('exceeds' in x for x in result['failures']))
    def test_collapsed(self):
        with self.assertRaises(ValueError):inspect_glb(glb([(0,0,0),(0,1,1),(0,0,1)]))
if __name__=='__main__':unittest.main()
