# Act 1: Khevsureti high-pasture environment

This environment is a **new game interpretation** of the raid-and-duel route in the six-ending design plan. The raid, stolen horses, hoofprint tracking, river detour with Sanata, and confrontation at the crags remain in their existing story positions.

## Visual layers

- `khevsureti_background.gd`: three camera-relative ridges, sun, thin clouds, sparse alpine scrub. Shared with the Aluda character preview.
- `khevsureti_ground.gd`: continuous level-floor palette with stones and meadow grass.
- `act_one_landmarks.gd`: dry-laid slate sheepfold (x 244–634), broken fence (x 596–661), hoofprints (x 691–845), trampled grass (x 965–1145), shallow wet river ford (x 1260–1823), distant small tower (x ~1970), bird silhouettes (x ~2011–2150), crags (x 2330–3170), and a marked rifle-cover boulder centered at x 2540.

The landscape is an artistic interpretation of the exposed highland valleys and dry-stone construction of Khevsureti, not a map of a documented historic structure.

## Game boundaries

All three environment nodes draw only. No new collisions or hazards are introduced; the original `StaticBody2D` owns floor physics. The boulder at x 2540 visually corresponds to the existing `RifleEncounter.tick` cover interval x 2500–2580. Removing or repositioning it requires updating the gameplay cover check.

`act_one_tracking.gd` continues to own story state and interactions. Five optional trail clues glow until inspected, then fade; the HUD shows a 0–5 counter. The story still allows reaching the crags without collecting all signs. No story outcomes or player input bindings are changed.

## Verification

Open `scenes/levels/aluda/act_one/tracking.tscn` and run the scene (F6) to view the full trail; the project launch still starts with the Aluda character preview.

From the repository root, with Godot 4.7 available, run:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_landmarks_smoke.gd
godot --headless --path . --script res://tests/rifle_encounter_smoke.gd
```

Confirm visually that the sheepfold does not block travel, the water reads as a shallow ford rather than a hole, rocks sit behind Aluda, clue glow disappears on inspection, and the low boulder covers the intended safe interval.
