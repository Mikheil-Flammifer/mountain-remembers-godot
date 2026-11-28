# Act menu

The game now opens on an act menu (`scenes/ui/act_select_menu.tscn`, set as the main scene).

- Act I is always open. Every later act opens only after the act before it is finished.
- Acts without a scene yet (III–V) are listed as "not built yet" and cannot be opened.
- Progress is kept in `user://act_progress.cfg` by `ActProgress` (`scripts/systems/story/act_progress.gd`). It stores only whether each act is finished, plus the choice a later act needs: Act I's hand choice and Act II's dream choice.
- Act I is recorded as finished when the player arrives in Act II from it. Act II is recorded when the player breaks camp. Act I code is unchanged.
- Starting an act from the menu passes it only the earlier choices it needs, through `SceneTree` metadata, so acts stay separate.
- When Act II is complete, or opened while still locked, E returns to the menu.
- Tests set `ActProgress.save_path` to a throwaway file, so real saves are never touched.

Test: `godot --headless --path . --script res://tests/act_select_menu_smoke.gd`
