import copy
import unittest
from compare_kindria_performance import compare, TIMINGS


def report(mode="headless_cpu_submission"):
    timing = {"samples": 900, "p50_usec": 1000, "p95_usec": 2000,
              "p99_usec": 3000, "max_usec": 5000}
    data = {"mode": mode, "catalog_moves": 589, "simulation_hz": 60,
            "frame_budget_usec": 16667, "audio_playback": False,
            "failures": [], "peaks": {"static_bytes": 100_000_000,
                                      "renderer_video_bytes": 0},
            "crowd_batches": 12, "concurrent_casts": 10,
            "experimental_particle_batching": False,
            "sustained_stress": {"casts": 192, "expected_waves": 576,
                "simulation_frames": 900, "slow_simulation_frames": 12,
                "counters": {"dispatched_waves": 576,
                             "dispatched_damage_waves": 384,
                             "dispatched_miss_waves": 192, "retired_dropped": 0}}}
    for group in TIMINGS[mode]:
        node = data
        keys = group.split(".")
        for key in keys[:-1]:
            node = node.setdefault(key, {})
        node[keys[-1]] = dict(timing)
    return data


class RegressionTests(unittest.TestCase):
    def setUp(self):
        self.base = report()
        self.candidate = copy.deepcopy(self.base)

    def test_identical(self):
        self.assertEqual(compare(self.base, self.candidate)["status"], "pass")

    def test_improvement(self):
        self.candidate["warm_update"]["p99_usec"] = 2500
        self.assertEqual(compare(self.base, self.candidate)["status"], "pass")

    def test_small_noise(self):
        self.candidate["warm_update"]["p50_usec"] = 1200
        self.assertEqual(compare(self.base, self.candidate)["status"], "pass")

    def test_tail_regression(self):
        self.candidate["sustained_stress"]["update"]["p99_usec"] = 4000
        self.assertEqual(compare(self.base, self.candidate)["status"], "regression")

    def test_max_only_warns(self):
        self.candidate["crowd_update"]["max_usec"] = 9000
        result = compare(self.base, self.candidate)
        self.assertEqual(result["status"], "pass")
        self.assertIn("crowd_update.max_usec", result["warnings"])

    def test_workload_mismatch(self):
        self.candidate["sustained_stress"]["casts"] -= 1
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")

    def test_missing_stress(self):
        del self.candidate["sustained_stress"]
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")

    def test_lost_wave(self):
        self.candidate["sustained_stress"]["counters"]["dispatched_waves"] -= 1
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")

    def test_sample_mismatch(self):
        self.candidate["warm_update"]["samples"] -= 1
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")

    def test_failed_benchmark(self):
        self.candidate["failures"] = ["pool cap exceeded"]
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")

    def test_mode_mismatch(self):
        self.assertEqual(compare(self.base, report("desktop_rendered"))["status"], "incompatible")

    def test_rendered_batching_mismatch(self):
        baseline = report("desktop_rendered")
        candidate = copy.deepcopy(baseline)
        candidate["experimental_particle_batching"] = True
        self.assertEqual(compare(baseline, candidate)["status"], "incompatible")

    def test_missing_memory_monitor(self):
        self.assertIn("renderer_video_bytes: unavailable monitor",
                      compare(self.base, self.candidate)["warnings"])

    def test_nonfinite_timing(self):
        self.candidate["warm_update"]["p95_usec"] = float("nan")
        self.assertEqual(compare(self.base, self.candidate)["status"], "incompatible")


if __name__ == "__main__":
    unittest.main()
