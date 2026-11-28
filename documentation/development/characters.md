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
| gela | Gela | Young Khevsur, red coat with cross, black cap, flat-blade sword. Prologue, Act 3. |
| zezva | Zezva | Boy (drawn at 0.68 size), plain coat, stick. Prologue. |
| ushisha | Ushisha | Old man, white beard, sheepskin hat, staff. Prologue, Act 3. |
| lela | Lela | Aluda's wife, red embroidered dress, white headscarf, braid. Prologue. |
| aluda_mother | Aluda's Mother | Black dress and scarf, carries bread. Prologue. |
| aluda_brother | Aluda's Brother | Blue-grey coat, pale cap, staff. Prologue. |
| aluda_nephew | Aluda's Nephew | Smaller (0.8), staff. One rig for the three nephews; recolour copies if needed. |
| messenger | Messenger | Shepherd in sheepskin vest. Act 1 opening. |
| sanata | Sanata | Herb woman with basket. Act 1 river detour. |
| mutsal_brother | Mutsal's Brother | Chechen raider, brown cherkeska, black papakha, rifle. Act 1 combat 1. |
| murana | Murana | Dog. Four-legged rig: Body/FrontArm is the tail. Prologue. |
| berdia | Berdia | Khevisberi (priest-elder): white robe with red cross and sash, tall white felt hat, grey beard, staff with red shrine banner. Act 3, Act 5. |
| aiza | Aiza | Mutsal's sister, Chechen woman: dark dress, silver bib and belt, black mourning shawl. Act 4. |
| elmurza | Elmurza | Mutsal's kinsman, Chechen: blue-grey cherkeska with silver gazyri and belt, black papakha, dark beard, drawn kinzhal. Act 4. |
| gigia | Gigia | Keeper at Anatori: grey coat, brown hooded cloak, grey beard, lantern and pick. Preparation side quest. |
| young_khevsur_1 | Bero | Young Khevsur who mocks Aluda (with Gela): loud one: pale coat with blue cross, black cap, sword. Name is a placeholder. |
| young_khevsur_2 | Torgva | Young Khevsur who mocks Aluda (with Gela): red coat with cream cross, brown cap, stick; laughs the loudest. Name is a placeholder. |
| young_khevsur_3 | Khvtisia | Young Khevsur who mocks Aluda (with Gela): dark blue coat with red cross, pale cap, short sword and small shield. Name is a placeholder. |
| young_khevsur_4 | Gugua | Young Khevsur who mocks Aluda (with Gela): youngest: plain brown coat, black cap, sling; follows the others. Name is a placeholder. |

## Adding a character

1. Copy the `mindia` folders in all three places and rename files to the new id.
2. Rename the class to `<Name>Visual`, fix paths in the `.tscn` and `.tres`, and set `appearance_id` / `display_name`.
3. Add a row to the roster and run `godot --headless --path . --script res://tests/character_visuals_smoke.gd`.
