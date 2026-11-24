"""Synthetic fixtures for the original CarTypeInfo upgrade metadata reader."""
import math
import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from nfsu2_physics_catalog import CAR_CHUNK, CAR_SIZE, catalog, record


def physics_record(name="SUPRA", bad=False):
    data = bytearray(CAR_SIZE)
    data[:len(name)] = name.encode("ascii")
    struct.pack_into("<3f", data, 0x300, 750.0, 6500.0, 7000.0)
    struct.pack_into("<f", data, 0x220, 1.43)
    struct.pack_into("<I", data, 0x2D8, 5)
    struct.pack_into("<9f", data, 0x310, *[0.3] * 9)
    struct.pack_into("<9f", data, 0x530, *[0.1] * 9)
    struct.pack_into("<3f", data, 0x5E0, 0.0, 1500.0, 1500.0)
    struct.pack_into("<f", data, 0x690, 6.0)
    if bad:
        struct.pack_into("<f", data, 0x310, float("nan"))
    return bytes(data)


class PhysicsReadTests(unittest.TestCase):
    def test_real_offsets_baseline_and_upgrades(self):
        d = record(physics_record())
        self.assertEqual(d["xname"], "SUPRA")
        self.assertEqual(d["factory_physics"]["engine_idle_redline_max_rpm"],
                         [750.0, 6500.0, 7000.0])
        self.assertAlmostEqual(d["factory_physics"]["mass_tonnes"], 1.43, places=5)
        self.assertAlmostEqual(d["factory_physics"]["torque_curve_kNm"][0], 0.3)
        self.assertEqual(d["upgrade_source_targets"]["ecu"]["rpm_level_3_add"],
                         [0.0, 1500.0, 1500.0])
        self.assertAlmostEqual(d["upgrade_source_targets"]["nitrous"]["capacity_target"], 6.0)
        self.assertEqual(d["upgrade_status"], "original_targets_extracted_packages_not_applied")

    def test_recurses_into_nested_globalb(self):
        original = physics_record()
        leaf = struct.pack("<II", CAR_CHUNK, len(original)) + original
        parent = struct.pack("<II", 0x80034600, len(leaf)) + leaf
        data = catalog(parent)
        self.assertEqual(data["parsed"], 1)
        self.assertIn("SUPRA", data["cars"])
        self.assertEqual(len(data["rejected"]), 0)

    def test_does_not_invent_invalid_cars(self):
        original = physics_record() + bytes(CAR_SIZE)
        leaf = struct.pack("<II", CAR_CHUNK, len(original)) + original
        data = catalog(leaf)
        self.assertEqual(data["parsed"], 1)
        self.assertEqual(len(data["rejected"]), 1)

    def test_rejects_malformed_or_nan_original_physics(self):
        with self.assertRaises(ValueError):
            record(physics_record(bad=True))
        with self.assertRaises(ValueError):
            record(b"fake")
        with self.assertRaises(ValueError):
            catalog(b"wrong")

    def test_refuses_out_of_bounds_chunk(self):
        fake = struct.pack("<II", 0x80034600, 999999999) + b"\x00" * 10
        with self.assertRaises(ValueError):
            catalog(fake)


if __name__ == "__main__":
    unittest.main()
