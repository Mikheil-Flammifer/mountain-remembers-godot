# Khevsur castle interior props

Reusable pieces for indoor scenes (first use: the Prologue feast in Shatili where the
messenger tells Aluda the horses were stolen).

- Scripts: `scripts/visuals/environment/castle/props/<prop>.gd` (shared base: `castle_prop.gd`, class `CastleProp`)
- Scenes (one per prop, drag into any level): `scenes/visuals/environment/castle/<prop>.tscn`
- Editor icons: `assets/icons/castle/<prop>.svg`
- Feast scene: `scenes/levels/aluda/prologue/shatili_castle_feast.tscn`

Every prop's origin is its bottom-centre. Change `prop_seed` for a differently textured copy.

| Prop | Notes |
| --- | --- |
| stone_wall | `size` export; stone courses with soot near the ceiling |
| stone_floor | flagstones in perspective |
| arrow_window | narrow loophole with night sky |
| wall_torch | flickering flame |
| hearth | fire, logs, cauldron |
| shield_and_swords | round Khevsur shield over crossed swords |
| castle_door | plank door, `open` export |
| feast_table | `length`, `height`; front hides the legs of people seated behind it |
| chief_chair | the head's high carved chair with sheepskin |
| bench | `length`; guests' bench |
| bread, meat_platter, wine_jug, drinking_horn | table food, place at the table top |

Seating characters: put the chair/bench behind, the character next, then the table and food
in front (scene order = draw order). Use the visual's `visual_scale` and `default_facing`,
not `scale`, because the actor visual overwrites `scale` when turning.

Test: `godot --headless --path . -s tests/castle_props_smoke.gd`
