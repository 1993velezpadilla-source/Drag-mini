import sys
import unittest
import struct
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from nfsu2_parts_animation import parse, PIVOTS, SLOT

class AnimationTests(unittest.TestCase):
    def fixture(self,q=(0,0,0,1)):
        start=b'\0'*11+b'\1'+b'\0'*7
        end=b'\x0f\0\x02\x14\0\0\0\0\x01'
        pivot=struct.pack('<16f',1,0,0,0,0,1,0,0,0,0,1,0,2,3,4,1)
        return SLOT+b'hood_q\0hood_t\0'+start+struct.pack('<4f',*q)+end+b'\x0c\0\0\0ABCD'+b'\0'*8+pivot*21
    def test_tracks(self):
        result=parse(self.fixture())
        self.assertEqual(len(result['pivots']),21)
        self.assertEqual(result['pivots'][PIVOTS[0]]['position_xyzw'],[2,3,4,1])
        self.assertEqual(result['tracks'][0]['quaternion_xyzw'],[(0,0,0,1)])
        self.assertIsNone(result['frame_rate'])
    def test_truncated(self):
        with self.assertRaises(ValueError): parse(self.fixture()[:-1])
    def test_invalid_quaternion(self):
        self.assertEqual(parse(self.fixture((0,0,0,0)))['tracks'][0]['status'],'invalid_quaternion')
