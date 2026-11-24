"""Synthetic-only tests for City Zero's private Godot/NFSU2 handoff."""
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import nfsu2_prepare_godot_library as source


def write_glb(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    body = b'{"asset":{"version":"2.0"}}'
    body += b' ' * (-len(body) % 4)
    path.write_bytes(struct.pack("<4sIII4s", b"glTF", 2, len(body) + 20,
                                 len(body), b"JSON") + body)


class PrivateGodotLibraryTests(unittest.TestCase):
    def test_exact_stock_parts_and_sound_stage_banks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "local_assets/models/SUPRA"
            write_glb(model / "stock.glb")
            write_glb(model / "parts/KIT01/front.glb")
            (model / "models.json").write_text(json.dumps({
                "stock": "stock.glb", "parts": [{
                    "name": "SUPRA_KIT01_FRONT_BUMPER_A",
                    "hash": "000000A1", "family": "FRONT_BUMPER",
                    "kit": "KIT01", "lod": "A",
                    "triangles": 700, "glb": "parts/KIT01/front.glb"
                }]
            }))
            snd = root / "local_assets/audio/test_engine_1.wav"
            snd.parent.mkdir(parents=True, exist_ok=True)
            snd.write_bytes(b"RIFF" + b"x" * 80)
            source_data = {
                "cars": {"SUPRA": {
                    "geometry": {"model_name": "SUPRA", "part_count": 201,
                                 "slots": {"body": 4}},
                    "unlimiter": {"Performance": {"engine": "1", "ecu": "1"}},
                    "sound": {"status": "mapped_from_car_sound_tuner", "stages": {
                        "stock": {"engine": {"EngineData": {
                            "mainrambankname": "TEST_ENGINE.ABK"}}},
                        "extreme": {"engine": {"EngineData": {
                            "mainrambankname": "UNKNOWN.ABK"}}},
                    }}
                }},
                "audio_files": [{"path": "SOUND/ENGINE/TEST_ENGINE.ABK",
                                 "private_wavs": [str(snd)]}],
            }
            result = source.build_library(source_data, root)
            a = result["vehicles"]["SUPRA"]
            self.assertEqual(result["summary"]["cars_with_all_model_files_valid"], 1)
            self.assertEqual(a["model_assets"]["parts"][0]["kit"], "KIT01")
            self.assertEqual(a["performance_categories"]["engine"], "1")
            self.assertEqual(a["sound_stages"]["stock"]["referenced_audio"]["TEST_ENGINE.ABK"]["status"],
                             "decoded_audio_available")
            self.assertEqual(a["sound_stages"]["extreme"]["referenced_audio"]["UNKNOWN.ABK"]["status"],
                             "source_not_found")
            self.assertEqual(a["sound_stages"]["street"]["status"], "unmapped")
            self.assertTrue(a["model_assets"]["stock"]["glb"].endswith("/stock.glb"))

    def test_rejects_absolute_and_traversal_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for bad in ("../../etc/passwd", "/etc/passwd", "parts/../../../escape"):
                with self.assertRaises(ValueError, msg=bad):
                    source.private_path(root, bad)

    def test_corrupted_glb_is_not_marked_usable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "local_assets/models/CIVIC"
            model.mkdir(parents=True)
            (model / "stock.glb").write_bytes(b"not a glb")
            (model / "models.json").write_text('{"stock":"stock.glb","parts":[]}')
            result = source.build_library({"cars": {"CIVIC": {}}, "audio_files": []}, root)
            car = result["vehicles"]["CIVIC"]["model_assets"]
            self.assertEqual(car["status"], "incomplete")
            self.assertIsNone(car["stock"])
            self.assertGreater(len(car["errors"]), 0)

    def test_duplicate_audio_basename_does_not_guess(self):
        stage = {"engine": {"mainrambankname": "BANK.ABK"}}
        i = source._sound_index([
            {"path": "SOUND/ENGINE/BANK.ABK"},
            {"path": "SOUND/ALT/BANK.ABK"},
        ])
        data = source._audio_refs(stage, i, Path("/tmp"))
        self.assertEqual(data["BANK.ABK"]["status"], "ambiguous")

    def test_no_unlicensed_models_get_auto_generated(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = source.build_library({"cars": {"GTO": {}}}, root)
            self.assertEqual(report["summary"]["cars_with_valid_stock_glb"], 0)
            self.assertEqual(report["vehicles"]["GTO"]["model_assets"]["status"],
                             "no_model_exports")

    def test_non_object_manifest_rejected(self):
        with self.assertRaises(ValueError):
            source.build_library({"cars": []}, Path("/tmp"))


if __name__ == "__main__":
    unittest.main()
