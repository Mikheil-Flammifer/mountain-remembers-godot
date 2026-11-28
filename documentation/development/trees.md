# Trees

Reusable, detailed trees drawn in code by `scripts/visuals/environment/trees/tree_visual.gd` (class `TreeVisual`). The node's origin is the foot of the trunk, so drop it on the ground line.

| Scene | Kind |
| --- | --- |
| `scenes/visuals/environment/trees/oak_tree.tscn` | Oak: wide rounded crown, furrowed brown bark |
| `scenes/visuals/environment/trees/beech_tree.tscn` | Beech: smooth grey bark, tall crown |
| `scenes/visuals/environment/trees/birch_tree.tscn` | Birch: white bark with dark marks, light drooping twigs |
| `scenes/visuals/environment/trees/pine_tree.tscn` | Scots pine: tall orange upper trunk, flat needle clouds |
| `scenes/visuals/environment/trees/spruce_tree.tscn` | Spruce: cone of drooping needle tiers with cones |
| `scenes/visuals/environment/trees/dead_tree.tscn` | Dead tree: bare grey branches |
| `scenes/visuals/environment/trees/autumn_oak_tree.tscn` | Oak in autumn colours |
| `scenes/visuals/environment/trees/autumn_birch_tree.tscn` | Birch in autumn colours |

Every tree is its own scene and its own node type with its own icon (`assets/icons/trees/<name>.svg`, script `scripts/visuals/environment/trees/kinds/<name>_tree.gd`). Drag any scene into a level, or add it from Add Node (search "Tree"), and move, copy or delete each tree on its own.

`scenes/visuals/environment/trees/tree_gallery.tscn` shows them all side by side.

Settings on every tree (Inspector, live in the editor):
- `kind`: OAK, BEECH, BIRCH, PINE, SPRUCE, DEAD
- `tree_seed`: each number grows a different tree of the same kind, so a forest never repeats
- `height`: size in pixels
- `autumn`: autumn leaves for oak, beech and birch

Add a new kind by adding it to `Kind`, giving it a bark colour and leaf palette, and a match branch in `_draw()`. Test: `godot --headless --path . --script res://tests/tree_visuals_smoke.gd`.
