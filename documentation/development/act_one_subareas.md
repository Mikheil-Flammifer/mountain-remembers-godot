# Act 1 sub-areas: the road toward Arkhoti

The continuous Khevsureti tracking location now contains four individually editable **visual sub-area scenes**. They are not separate loading screens. The player walks between them using the original movement and collision systems.

## Route

| World X | Sub-area | Authored environment | Existing gameplay |
| --- | --- | --- | --- |
| Before 650 | **Shepherds' Fold** | Slate shepherd's hut, collapsed masonry, scattered grass and weathered approach | Messenger at 160, silent sheepdogs at 430 |
| 650–1239 | **Wind-cut Pasture** | Terrace slopes, wind-responsive alpine grass, scree and a standing waystone | Hoofprints at 750, trampled grass at 1060 |
| 1240–1919 | **Sanata's Ford** | Riverside stone shelter, herbs, steep gorge and distant waterfall | Sanata at 1400, wet stones at 1720 |
| 1920 onward | **Arkhoti Crags** | Fractured slate fins, cliff fissures, talus, streaks of mountain wind | Birdcalls at 2050, crags at 2400, rifle cover at 2500–2580 |

The art is a fictional interpretation of high Khevsureti landscape and traditional stone construction. The specific shelter, waystone, and waterfall are **[New]** visual additions; they are not claimed to be named sites or events in the poem.

## Scene structure

- `scenes/levels/aluda/act_one/tracking.tscn`: retains the single scene root, decorative world background, ground, landmarks, and adds a `Subareas` collection.
- `scenes/levels/aluda/act_one/subareas/*.tscn`: four separate scene resources with adjustable region IDs and local widths, placed at world X -150, 650, 1240, and 1920.
- `scripts/levels/aluda/act_one_subarea_art.gd`: shared, `@tool` procedural drawing code. Rendering and wind animation only.
- `scripts/levels/aluda/act_one_subareas.gd`: authoritative display names and world-X boundaries.
- `scripts/ui/act_one_area_banner.gd`: temporary zone-entry title (top center), distinct from the bottom dialogue panel.
- `scripts/ui/aluda_dialogue_panel.gd`: can now receive a changing location header using `set_location(name)`.
- `scripts/levels/aluda/act_one_tracking.gd`: reads player X once each frame; sends title changes to UI. Story, existing clues and rifle encounter continue unchanged.

## Important guarantees

No new `CollisionShape2D`, `StaticBody2D`, `Area2D`, path transition, enemy spawn, or save format is introduced. Do not add collisions to the decorative area scenes. The cover rock still belongs to `act_one_landmarks.gd` and must remain aligned with the rifle encounter logic. Crossing boundaries in either direction is supported.

The scene can be previewed directly with Godot **F6**. The project-wide default main scene remains Aluda's character preview.

## Verification

Requires Godot 4.7 and the project imported:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_subareas_smoke.gd
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_landmarks_smoke.gd
godot --headless --path . --script res://tests/act_one_dialogue_smoke.gd
```

Check the zone titles after moving right and left through all four areas; verify the new vegetation and rocks remain behind Aluda, that the original clues can still be inspected, and that the bottom dialogue panel doesn't obscure the title.
