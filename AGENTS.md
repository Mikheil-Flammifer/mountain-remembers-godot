# Agent instructions

- Work on `main` as explicitly requested by the owner. Inspect Git status first, preserve existing changes, and never force-push or discard work.
- This is a Godot 4.7 GDScript game based on Aluda Ketelauri. Follow `documentation/game_design/six_ending_development_plan.md`, distinguish poem events from inventions, and develop incrementally.
- Gameplay owns collision, timing, damage and state; visuals present state; Resources hold configuration, not shared mutable runtime state. Favor composition, signals and small practical interfaces.
- Before moving files, inspect references, UIDs, inherited scenes, exported NodePaths, save formats and autoloads. Preserve public APIs where practical.
- Review `documentation/architecture/system_architecture.md` and `documentation/development/migration_plan.md` before architecture work. Use the Aluda actor and its visual slot as the reference for separating gameplay from presentation.
- Validate changes with the configured Godot version and relevant tests. For each test: `godot --headless --path . --script res://tests/<test>.gd`. Run the architecture smoke test with fresh user data when changing actor presentation, shrine upgrades or progression. Avoid writing to real player saves during tests.
- Document major changes and report actual checks, limitations and risks. Do not claim unexecuted tests passed.
