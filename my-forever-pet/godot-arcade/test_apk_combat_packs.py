"""Packaging verifier regression fixtures. No APK or Godot install required."""
import hashlib
import pathlib
import struct
import tempfile
import unittest
import zipfile

from verify_apk_combat_packs import FILES, verify, read_pck


def build_pck(payloads):
    directory = bytearray()
    payload = bytearray()
    for name, data in payloads.items():
        encoded = ("res://" + name).encode()
        encoded += b"\0" * ((-len(encoded)) % 4)
        directory.extend(struct.pack("<I", len(encoded)))
        directory.extend(encoded)
        directory.extend(struct.pack("<QQ", len(payload), len(data)))
        directory.extend(hashlib.md5(data).digest())
        directory.extend(struct.pack("<I", 0))
        payload.extend(data)
    base = 100 + len(directory)
    header = b"GDPC" + struct.pack("<5IQ", 2, 4, 4, 1, 2, base)
    header += bytes(64) + struct.pack("<I", len(payloads))
    return header + directory + payload


class PackVerification(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        self.payloads = {}
        for i, name in enumerate(FILES):
            data = bytes([i + 1]) * (i + 30)
            self.payloads[name] = data
            file = self.root / name
            file.parent.mkdir(exist_ok=True)
            file.write_bytes(data)
        self.apk = self.root / "fixture.apk"

    def write_loose(self, payloads):
        with zipfile.ZipFile(self.apk, "w") as archive:
            for name, data in payloads.items():
                archive.writestr("assets/" + name, data)

    def test_loose_exact(self):
        self.write_loose(self.payloads)
        report = verify(self.apk, self.root)
        self.assertEqual(set(report), set(FILES))
        for name, data in self.payloads.items():
            self.assertEqual(report[name]["sha256"], hashlib.sha256(data).hexdigest())

    def test_missing_and_changed(self):
        bad = dict(self.payloads)
        del bad[FILES[0]]
        self.write_loose(bad)
        with self.assertRaises(SystemExit):
            verify(self.apk, self.root)
        bad = dict(self.payloads)
        bad[FILES[-1]] = b"x" * len(bad[FILES[-1]])
        self.write_loose(bad)
        with self.assertRaises(SystemExit):
            verify(self.apk, self.root)

    def test_pck_exact(self):
        packed = build_pck(self.payloads)
        self.assertEqual(read_pck(packed), self.payloads)
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("assets/game.pck", packed)
        self.assertEqual(set(verify(self.apk, self.root)), set(FILES))

    def test_pck_corrupt(self):
        packed = bytearray(build_pck(self.payloads))
        packed[-1] ^= 255
        with self.assertRaises(ValueError):
            read_pck(packed)


    def test_conflicting_loose_and_pck(self):
        bad = dict(self.payloads)
        bad[FILES[0]] = b"stale index"
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("assets/game.pck", build_pck(bad))
            for name, payload in self.payloads.items():
                archive.writestr("assets/" + name, payload)
        with self.assertRaisesRegex(ValueError, "conflicting APK"):
            verify(self.apk, self.root)

    def test_identical_loose_and_pck(self):
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("assets/game.pck", build_pck(self.payloads))
            for name, payload in self.payloads.items():
                archive.writestr("assets/" + name, payload)
        self.assertEqual(set(verify(self.apk, self.root)), set(FILES))

    def test_duplicate_zip_resource(self):
        import warnings
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(self.apk, "w") as archive:
                archive.writestr("assets/" + FILES[0], b"stale")
                for name, payload in self.payloads.items():
                    archive.writestr("assets/" + name, payload)
        with self.assertRaisesRegex(ValueError, "conflicting APK"):
            verify(self.apk, self.root)

    def test_malformed_directory(self):
        original = build_pck(self.payloads)
        variants = [original[:40]]
        bad = bytearray(original)
        struct.pack_into("<Q", bad, 24, 99)
        variants.append(bad)
        bad = bytearray(original)
        struct.pack_into("<I", bad, 96, 2**31)
        variants.append(bad)
        bad = bytearray(original)
        struct.pack_into("<I", bad, 100, 2**31)
        variants.append(bad)
        for variant in variants:
            with self.subTest(size=len(variant)):
                with self.assertRaises(ValueError):
                    read_pck(variant)


if __name__ == "__main__":
    unittest.main()
