# Adversarial review: visual overhaul, pass 1
User reference: approved Pet Dash model and rejected 0.24 room/menu screenshots.
Reject old alternate green head, floating feet, clock stacked vertically, duplicate
overlapping room action labels, tiny list-only arcade menus and recycled room UI.
Current change:
- Exact mosskit.glb and foot.glb shared with the approved runner, not recreated.
- Measure actual mesh bottom, ground the model even during breathing and growth.
- Check all 24 live mesh instances and sole contact in CI.
- Dedicated illustrated room/arcade menus and compact Blender icon navigation.
- Project hotspots from real world coordinates, resolve label overlaps.
- Hidden viewport stops rendering; real day/night light changes.
- Capture all 24 creature models in the real home viewport in addition to room and
  game captures. A generated image or a passing parser is not art approval.
Remaining risks: species silhouettes are still derived from one body template;
wardrobe fit is approximate; room decorations, UI typography and secondary arcade
art still need visual review. No claim of AAA parity or physical device validation.
