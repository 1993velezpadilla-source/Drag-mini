"""Synthetic data only; tests never need or publish actual NFSU2 content."""
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cityzero_vehicle_inventory import classify, inspect_glb, inspect_game_root, read_glb

def create_test_glb(path, document):
    payload = json.dumps(document).encode("utf-8")
    payload += b" " * ((-len(payload)) % 4)
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, 20 + len(payload)) +
                     struct.pack("<I4s", len(payload), b"JSON") + payload)

class VehicleAuditTests(unittest.TestCase):
    def test_classifies_specialty_parts_before_generic_parts(self):
        self.assertEqual(classify("SUPRA_KIT02_TRUNK_AUDIO_A"), "trunk_audio")
        self.assertEqual(classify("RX7_KIT00_HOOD_UNDER_A"), "hood_under")
        self.assertEqual(classify("CELICA_KIT01_FRONT_BUMPER_A"), "front_bumper")
        self.assertIsNone(classify("MARKER_AUDIO_COMP_0"))

    def test_glb_parts_pivots_and_mounts(self):
        with tempfile.TemporaryDirectory() as working:
            path = Path(working) / "vehicle.glb"
            document = {
                "asset": {"version": "2.0"},
                "nodes": [
                    {"name": "SUPRA_KIT00_HOOD_A", "mesh": 0},
                    {"name": "SUPRA_KIT02_TRUNK_AUDIO_A", "mesh": 0},
                    {"name": "_ZAM_HOOD_REG"},
                    {"name": "_ZAM_TRUNK_REG"},
                    {"name": "MARKER_AUDIO_COMP_0"},
                    {"name": "MARKER_AUDIO_COMP_11"},
                    {"name": "MARKER_TRUNK_NEON_START_0"},
                    {"name": "SUPRA_KIT00_TRUNK_A", "mesh": 0},
                ],
                "meshes": [{"primitives": [{"attributes": {"POSITION": 0}}]}],
                "accessors": [{"count": 30}],
                "materials": [{"name": "Paint"}],
            }
            create_test_glb(path, document)
            result = inspect_glb(path)
            self.assertEqual(result["estimated_triangles"], 30)
            self.assertEqual(len(result["speaker_mounts"]), 2)
            self.assertIn("trunk_audio", result["part_groups"])
            self.assertEqual(result["warnings"], [])

    def test_glb_corruption_rejected(self):
        with tempfile.TemporaryDirectory() as working:
            path = Path(working) / "broken.glb"
            path.write_bytes(b"glTF" + b"\0" * 8)
            with self.assertRaises(ValueError):
                read_glb(path)

    def test_game_folders(self):
        with tempfile.TemporaryDirectory() as working:
            folder = Path(working) / "CARS" / "CIVIC"
            folder.mkdir(parents=True)
            (folder / "GEOMETRY.BIN").write_bytes(b"synthetic")
            (folder / "TEXTURES.BIN").write_bytes(b"synthetic")
            result = inspect_game_root(Path(working))
            self.assertEqual(result["car_count"], 1)
            self.assertFalse(result["cars"][0]["animated_parts_file_available"])

if __name__ == "__main__":
    unittest.main()
