# Agent instructions

- Work only on `mikheil-branch` unless the owner explicitly changes that instruction. Inspect Git status first; preserve all existing changes. Never modify or merge main, force-push, or discard work.
- This is an existing Godot 4.7 GDScript game. Preserve playable behavior, story, input, saves and scene paths. Refactor incrementally; do not rebuild or adjust balance during visual extraction.
- Gameplay owns collision, timing, damage and state; visuals present state; Resources hold configuration, not shared mutable runtime state. Favor composition, signals and small practical interfaces.
- Before moving files, inspect references, UIDs, inherited scenes, exported NodePaths, save formats and autoloads. Preserve public APIs where practical.
- Review `documentation/architecture/system_architecture.md` and `documentation/development/migration_plan.md` before architecture work. Use the player scene and its visual slot as the reference for separating gameplay from presentation.
- Validate changes with the configured Godot version and relevant tests. For each test: `godot --headless --path . --script res://tests/<test>.gd`. Run the architecture smoke test with fresh user data when changing actor presentation, shrine upgrades or progression. Avoid writing to real player saves during tests.
- Document major changes and report actual checks, limitations and risks. Do not claim unexecuted tests passed.
