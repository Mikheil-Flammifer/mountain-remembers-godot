# System architecture

The project uses Godot 4.7 and GDScript with GL Compatibility. The project starts in Mtskheta Streets. WorldState handles location discovery and the MtskhetaTransitionManager autoload owns travel and checkpoints.

| Responsibility | Entry point |
| --- | --- |
| Player input, guard, poise and coordination | `scripts/characters/player.gd` |
| Movement, sword hit windows, health and stamina | `scripts/components/` |
| Replaceable Xizane appearances | `ActorVisualSlot`, `ActorVisualState`, `ActorVisualData` |
| Enemy decisions, attacks and rewards | `scripts/enemies/` |
| Actor rigs, poses and feedback | `scenes/visuals/actors/` and `scripts/visuals/actors/` |
| Upgrade costs, levels and effects | `scripts/systems/progression/xizane_upgrade_rules.gd` |
| Progression JSON and session metadata | `scripts/systems/progression/xizane_progression_store.gd` |
| Shrine interaction, checkpoint and enemy respawn | `scripts/objects/rest_shrine.gd` |
| Shrine cards, previews and menu input | `scripts/ui/shrine_upgrade_menu.gd` |
| District layout, spawns and transitions | `scenes/levels/` and `scripts/levels/` |

## Actors and visuals

Compose an actor from its gameplay nodes and a visual scene. Xizane publishes one reusable state object per actor. Visuals read it during the update call. The active visual can be swapped through the slot with a PackedScene or an ActorVisualData resource. The resource stores the initial scene, offset, scale, tint and facing. Keep runtime state on individual instances.

To add a player appearance, create a scene whose root extends ActorVisual, implement the states the appearance supports and point an appearance resource at the scene. The default polygon appearance is under `scenes/visuals/actors/player/xizane/`. The climb pose receives state from the player just like the other poses. The ladder controls traversal through the player API.

The wolf scene composes its AI and collider with a separate visual scene. The visual receives poses, facing and health ratio. The wolf script owns damage, rewards and despawn timing. Keep authoritative mechanics on the gameplay side when applying the same separation to another actor.

## Progression and interaction

The shrine asks for current upgrade values through XizanePlayer. The shared rules supply both the applied stats and the menu preview for any level. A purchase runs through XizanePlayer so game rules, signals and saves follow one path. The store keeps the existing `user://xizane_progression.json` fields and session metadata keys. Existing WorldState and checkpoint data remain separate.

## Scene and resource changes

Preserve stable scene paths, UIDs and node names used by other scenes. Check autoloads, inherited scenes, exported NodePaths, string-based references and save data before moving a resource. Keep district collision, spawns and routes independent of scenery. Use Godot's semicolon comment syntax in text scenes.
