import unittest
from PIL import Image
from dungeon_composition_audit import measure

class CompositionAuditTests(unittest.TestCase):
    def test_identical(self):
        im=Image.new("RGB",(40,60))
        self.assertEqual(measure(im,im)["whole"],0)
    def test_foreground_only(self):
        a=Image.new("RGB",(40,60))
        b=a.copy(); b.paste((255,255,255),(0,40,10,60))
        p=measure(a,b)
        self.assertEqual(p["near"],25)
        self.assertEqual(p["far"],0)
        self.assertEqual(p["right_edge"],0)
        self.assertAlmostEqual(p["whole"],8.333,places=3)
    def test_threshold(self):
        a=Image.new("RGB",(40,60),(100,100,100))
        b=Image.new("RGB",(40,60),(112,100,100))
        self.assertEqual(measure(a,b)["whole"],0)
    def test_mismatched(self):
        with self.assertRaises(ValueError):
            measure(Image.new("RGB",(40,60)),Image.new("RGB",(41,60)))

if __name__ == "__main__": unittest.main()
