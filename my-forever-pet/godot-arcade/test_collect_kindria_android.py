import json
import unittest
from collect_kindria_android import TAG, parse_windows, summarize

def window(over=0, tier=0, os="Android", samples=300):
    return {"os": os, "peak_quality_tier": tier, "frame_interval": {
        "samples": samples, "p50_usec": 10000, "p95_usec": 13000,
        "p99_usec": 15000, "max_usec": 16000, "over_60hz_budget": over}}

class AndroidEvidenceTests(unittest.TestCase):
    def test_android_only(self):
        rows, rejected = parse_windows(TAG + json.dumps(window()) + "\n" +
                                       TAG + json.dumps(window(os="Linux")))
        self.assertEqual((len(rows), rejected), (1, 1))
    def test_invalid_and_partial(self):
        rows, rejected = parse_windows(TAG + "bad\n" + TAG + json.dumps(window(samples=299)))
        self.assertEqual((len(rows), rejected), (0, 2))
    def test_missing_budget_count(self):
        row = window()
        del row["frame_interval"]["over_60hz_budget"]
        self.assertEqual(parse_windows(TAG + json.dumps(row)), ([], 1))
    def test_budget_quality_and_sample_gates(self):
        self.assertTrue(summarize([window()]*60, 0, True, 600)["certification_ready"])
        for rows, rejected, physical, duration in [
            ([window()]*60, 1, True, 600),
            ([window(over=1)]*60, 0, True, 600),
            ([window(tier=1)]*60, 0, True, 600),
            ([window()]*60, 0, False, 600),
            ([window()]*60, 0, True, 599),
            ([window()], 0, True, 600),
            ([], 0, True, 600),
        ]:
            self.assertFalse(summarize(rows, rejected, physical, duration)["certification_ready"])

if __name__ == "__main__":
    unittest.main()
