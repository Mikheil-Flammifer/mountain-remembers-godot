# Aluda Ketelauri

A 2D game prototype inspired by Vazha-Pshavela's poem *Aluda Ketelauri*. The current build opens a small character preview featuring Aluda in Khevsur-inspired clothing with a felt hat, sword and round shield.

## Run

Open `project.godot` in Godot 4.7 and run the project. Use A / D to move, Space to jump, H to swing the sword and G to raise the shield. Sword and shield actions currently show poses; combat effects and protection are not implemented yet.

## Project layout

- `scenes/actors/player/aluda.tscn` contains the reusable character and gameplay collision.
- `scripts/actors/player/aluda_player.gd` handles movement and input.
- `scenes/visuals/actors/player/aluda/` contains the replaceable character rig.
- `scenes/visuals/equipment/` contains reusable sword and shield visuals.
- `resources/visuals/actors/aluda/` configures the default appearance.
- `scenes/levels/aluda/character_preview.tscn` is the starting preview.
- `documentation/game_design/six_ending_development_plan.md` contains the supplied story and ending plan.

Aluda communicates movement and action state through `ActorVisualSlot`. A compatible visual scene can replace the default appearance without changing his controller. Existing Mountain Remembers content remains in the repository for reference and is not loaded by the new starting scene.

## Verification

Run `godot --headless --path . --script res://tests/aluda_character_smoke.gd` to exercise movement, attack presentation and visual replacement. The six endings and other characters are future work.
