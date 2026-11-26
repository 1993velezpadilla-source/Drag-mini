# Composition regression, baseline 6ba17a3
Measured actual downloaded on/off pairs (artifact 15095890113, 540x742 viewport), all pixels, maximum RGB channel difference >12/255. Values below are percentages of each band, not whole-image percentages.
| Biome | Floor | Whole | Far third | Middle third | Near third | Left quarter | Right quarter |
|---|---|---|---|---|---|---|---|
| Whisperwood | 1 | 2.06 | 0 | 0 | 6.18 | 7.20 | 0 |
| Whisperwood | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| Coral Depths | 1 | 3.95 | 4.36 | 4.86 | 2.63 | 2.64 | 2.01 |
| Coral Depths | 2 | 4.41 | 2.74 | 3.99 | 6.48 | 2.02 | 1.86 |
| Starfall Isles | 1 | 2.99 | 8.99 | 0 | 0 | 4.28 | 1.05 |
| Starfall Isles | 2 | 2.53 | 7.59 | 0 | 0 | 3.68 | 0.34 |

Concept comparison remains rejected: forest has no new background contribution in the upper third on both floors, and starfall has no new foreground contribution. Coral values may include animated caustics because the shader clock was not frozen during capture. This is not evidence that all scenery is absent, only that the switched exterior assets contributed little. Keep visual judgment separate. New model and shader revisions require fresh renders. Latest 69a13e8 smoke and isolated interaction pass; complete Blender and Android builds pending, so this diagnostic commit deliberately leaves production and existing CI trigger paths untouched. Next capture should isolate shader timing and include multiple rooms with live combat. Do not stop the production build to rerun this offline test.
