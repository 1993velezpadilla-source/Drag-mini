# Kindria V25.0 — Performance audit

Audited code revision: `e8cc25c90040aeec4881c83c58351620dd92d9cf` (V24.9).
Comparison baseline: `893161774f8e5cdbb9d35b05cdd64635d37bf553` (V23.8).
GitHub comparison: 23 commits ahead, 0 behind; only dungeon_view.gd and cinematic_gauntlet.gd modified.

## Verified results
- [Godot 4.5.1 cinematic gauntlet](https://github.com/1993velezpadilla-source/Drag-mini/actions/runs/46082170016): success. Job log reports CINEMATIC_GAUNTLET checks=315687 failures=0.
- 589 visual sequences, 7068 frames, 18 elements; 173166 similarity pairs, 0 flagged visual candidates.
- 1178 audio samples, 1178 exact unique; 68 coarse audio similarity review groups, 0 review candidates under the current threshold. This does not prove subjective perceptual uniqueness.
- 2945 runtime samples recorded by the full quality test.
- [Godot 4.6 release validation](https://github.com/1993velezpadilla-source/Drag-mini/actions/runs/46082169982): import/compile and full cinematic gauntlet succeeded; remaining release stages were in progress or pending when this report was written.

## Remaining release gates
- Verify original PCM and lossless atlas bake results.
- Obtain packed combat CPU benchmark and rendered desktop probe.
- Compare optional particle batching; do not enable by default without evidence.
- Obtain real Android frame interval p50/p95/p99, CPU submission timing, draw calls and memory. Report resolution, device, quality tier and simultaneous casts.
- Target 60 FPS (16.67 ms frame budget); no Android FPS claim until measured. Desktop/headless results are not Android measurements.

No engine changes were made in this audit pass. The report describes observed CI output, not a guarantee of visual equivalence on every device.
