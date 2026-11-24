"""Synthetic-only validation of the public NFSU2 source importer."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
import nfsu2_import_all as src
import nfsu2_blender_export_all as blender

class NFSU2ImportTests(unittest.TestCase):
    def test_comprehensive_slots(self):
        kinds = [
            ("SUPRA_TRUNK_AUDIO", "trunk_audio"), ("SUPRA_HOOD_UNDER", "hood_under"),
            ("SUPRA_TRUNK_UNDER", "trunk_under"), ("SUPRA_FRONT_BUMPER", "front_bumper"),
            ("SUPRA_REAR_BUMPER", "rear_bumper"), ("SUPRA_WHEEL", "wheel"),
            ("SUPRA_SPOILER", "spoiler"), ("SUPRA_ENGINE", "engine"),
            ("SUPRA_EXHAUST", "exhaust"), ("SUPRA_HEADLIGHT", "headlight"),
            ("SUPRA_BRAKELIGHT", "taillight"), ("SUPRA_HOOD", "hood"),
            ("SUPRA_KIT00_BODY", "body"),
        ]
        for name, expected in kinds:
            self.assertEqual(src.part_category(name), expected, name)
        self.assertEqual(src.part_category("SUPRA_KITW01_BODY", "KITW01"), "widebody")

    def test_sound_mapping_for_four_upgrade_levels(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            files = {
                "CarTypeMapping/MUSTANGGT.ini": "[CarTypeMapping]\nCarDataMapping=20\n",
                "CarDataMapping/20.ini": "[Stock]\nEngineData=14\n"
                    "[Street]\nEngineData=12\nShiftPattern=9\nTurboDataSet=13\n"
                    "[Pro]\nEngineData=12\n[Extreme]\nEngineData=35\n",
                "EngineData/12.ini": "[EngineData]\nMainRAMBankName=CAR_12_ENG_MB_EE.abk\n"
                    "GinsuAccel=GIN_Mustang_Drag.gin\nCarID=12\n",
                "ShiftPatterns/09.ini": "[ShiftPattern]\nBankName=GEAR_LRG_Lev1.abk\n",
                "TurboDataSet/13.ini": "[Turbo]\nTurboBank=TURBO_TRUCK_0_MB.abk\n",
            }
            for relative, data in files.items():
                p = root / relative
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(data)
            mapping = src.sound_mapping(root, "MUSTANGGT")
            self.assertEqual(mapping["status"], "mapped_from_car_sound_tuner")
            self.assertEqual(len(mapping["stages"]), 4)
            street = mapping["stages"]["street"]
            self.assertEqual(street["engine"]["EngineData"]["ginsuaccel"], "GIN_Mustang_Drag.gin")
            self.assertEqual(street["shifting"]["ShiftPattern"]["bankname"], "GEAR_LRG_Lev1.abk")
            self.assertEqual(street["turbo"]["Turbo"]["turbobank"], "TURBO_TRUCK_0_MB.abk")

    def test_missing_mapping_stays_unmapped(self):
        self.assertEqual(src.sound_mapping(None, "CIVIC")["status"], "not_mapped")

    def test_unlimiter_inheritance(self):
        with tempfile.TemporaryDirectory() as directory:
            d = Path(directory) / "Scripts" / "UnlimiterData"
            d.mkdir(parents=True)
            (d / "_General.ini").write_text("[BodyShop]\nRims=1\nTrunk=0 // comment\n")
            (d / "SUPRA.ini").write_text("[BodyShop]\nTrunk=1\n")
            section = src.unlimiter_config(Path(directory), "SUPRA")["BodyShop"]
            self.assertEqual(section["rims"], "1")
            self.assertEqual(section["trunk"], "1")

    def test_file_categories(self):
        with tempfile.TemporaryDirectory() as directory:
            sound = Path(directory) / "SOUND" / "ENGINE"
            sound.mkdir(parents=True)
            (sound / "car.GIN").write_bytes(b"test")
            (sound / "car.ABK").write_bytes(b"test")
            files = src.sound_files(Path(directory))
            self.assertEqual(len(files), 2)
            self.assertTrue(all(x["category"] == "engine" for x in files))

    def test_all_kit_lods_in_catalog(self):
        def part(name, kit, family, lod, number):
            return SimpleNamespace(name=name, kit=kit, family=family, lod=lod, hash=number,
                                   nverts=100, nfaces=40, classes=[1])
        parts = [
            part("SUPRA_KIT00_BODY_A", "KIT00", "SUPRA_BODY", "A", 1),
            part("SUPRA_KIT00_BODY_B", "KIT00", "SUPRA_BODY", "B", 2),
            part("SUPRA_KIT02_TRUNK_AUDIO_A", "KIT02", "SUPRA_TRUNK_AUDIO", "A", 3),
        ]
        class Car:
            name = "SUPRA"
            def stock_parts(self, kit, lod):
                return [self.parts[0]]
        Car.parts = parts
        class Parser:
            CLASS_NAMES = {1: "CARSKIN"}
            class CarGeometry:
                @staticmethod
                def open(path):
                    return Car()
        result = src.collect_geometry(Parser, Path("synthetic.bin"), None)
        self.assertEqual(result["part_count"], 3)
        self.assertEqual(result["slots"]["body"], 2)
        self.assertEqual(result["slots"]["trunk_audio"], 1)
        self.assertTrue(result["parts"][0]["stock"])

    def test_highest_lod_and_every_lod(self):
        def part(name, lod, kit="KIT00", family="BODY", verts=100):
            return SimpleNamespace(name=name, lod=lod, kit=kit, family=family, nverts=verts)
        entries = [part("low", "B"), part("high", "A"),
                   part("other", "A", "KIT02"), part("hood", None, "STYLE06", "HOOD")]
        self.assertEqual(len(blender.best_variants(entries)), 3)
        self.assertEqual(len(blender.best_variants(entries, True)), 4)
        self.assertEqual(blender.best_variants(entries)[0].name, "high")


    def test_all_vgmstream_subsongs_are_kept(self):
        from unittest.mock import patch
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "wavs"
            rows = [{"path": "SOUND/ENGINE/BANK.ABK", "extension": ".abk"}]
            def produce(cmd, **kw):
                self.assertEqual(cmd[cmd.index("-S") + 1], "0")
                target = cmd[cmd.index("-o") + 1]
                for i in (1, 2, 3):
                    Path(target.replace("?04s", f"{i:04d}")).write_bytes(
                        b"RIFF" + b"\0" * 4 + b"WAVE" + b"\0" * 64)
                return SimpleNamespace(returncode=0, stderr="", stdout="")
            with patch.object(src.shutil, "which", return_value="/usr/bin/vgmstream-cli"), patch.object(
                    src.subprocess, "run", side_effect=produce):
                result = src.decode_sound_banks(Path(directory), rows, output, "vgmstream-cli")
            self.assertEqual(result["decoded_streams"], 3)
            self.assertEqual(len(rows[0]["private_wavs"]), 3)
            self.assertTrue(all(Path(p).is_file() for p in rows[0]["private_wavs"]))

    def test_stale_or_invalid_audio_never_counts_as_decoded(self):
        from unittest.mock import patch
        from types import SimpleNamespace
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "wavs"
            output.mkdir()
            (output / "stale.wav").write_bytes(
                b"RIFF" + b"\0" * 4 + b"WAVE" + b"\0" * 60)
            rows = [{"path": "SOUND/ENGINE/BANK.ABK", "extension": ".abk"}]
            with patch.object(src.shutil, "which", return_value="/usr/bin/vgmstream-cli"), patch.object(
                    src.subprocess, "run", return_value=SimpleNamespace(
                        returncode=1, stderr="decoder failure", stdout="")):
                result = src.decode_sound_banks(Path(directory), rows, output, "vgmstream-cli")
            self.assertEqual(result["decoded_streams"], 0)
            self.assertNotIn("private_wavs", rows[0])
            self.assertEqual(rows[0]["decode_status"], "failed")

if __name__ == "__main__":
    unittest.main()
