# Aluda Ketelauri

The current game starts in a character preview for Aluda, a Khevsur warrior inspired by Vazha-Pshavela's poem. Move with A and D, jump with Space, swing the sword with H, and raise the shield with G. This is an early character prototype; attacks and blocking currently drive visual poses and do not yet apply damage or protection.

The six-ending design is recorded in `documentation/game_design/six_ending_development_plan.md`.

Aluda's reusable actor is `scenes/actors/player/aluda.tscn`. Gameplay state is sent to `ActorVisualSlot`, which loads `resources/visuals/actors/aluda/default_appearance.tres`. Replace its visual scene to change appearance without rewriting movement. The default visual uses separate hat, garment, sword and shield scenes under `scenes/visuals/equipment/`. Their painted textures are in `assets/2d/characters/aluda/equipment/`. Runtime animation state remains on each actor instance.

Older Mountain Remembers files are retained for reference and are not instantiated by the new starting scene. The story acts, other characters, ending choices and combat systems are planned work.
