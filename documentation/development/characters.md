# Characters

Each character uses the same polygon-rig technique as Aluda and lives in one folder per root, named by its id:

| Part | Path |
| --- | --- |
| Look (polygons, colours, weapon) | `scenes/visuals/actors/characters/<id>/<id>_visual.tscn` |
| Script (class `<Name>Visual`) | `scripts/visuals/actors/characters/<id>/<id>_visual.gd` |
| Appearance data | `resources/visuals/actors/<id>/default_appearance.tres` |

Shared motion (walk, attack, block, jump) is in `scripts/visuals/actors/characters/shared/humanoid_rig_visual.gd`. A rig needs `Body`, `Body/FrontArm`, `FrontLeg`, `BackLeg`; `Body/BackArm` is optional.

## Roster

| id | Name | Notes |
| --- | --- | --- |
| aluda | Aluda Ketelauri | Player. Older layout: `scenes/visuals/actors/player/aluda/`, `scripts/visuals/actors/implementations/aluda_visual.gd`. |
| xizane | Xizane | Older layout under `player/xizane/`. |
| mindia | Mindia | Young Khevsur, sword, light coat with blue embroidery. |
| mutsal | Mutsal | Chechen warrior in traditional dress: grey astrakhan papakha, black cherkeska with silver-capped gazyri, white beshmet, silver belt with sheathed kinzhal, soft high boots, dagger (`scenes/visuals/equipment/kist_dagger.tscn`). |

## Adding a character

1. Copy the `mindia` folders in all three places and rename files to the new id.
2. Rename the class to `<Name>Visual`, fix paths in the `.tscn` and `.tres`, and set `appearance_id` / `display_name`.
3. Add a row to the roster and run `godot --headless --path . --script res://tests/character_visuals_smoke.gd`.
