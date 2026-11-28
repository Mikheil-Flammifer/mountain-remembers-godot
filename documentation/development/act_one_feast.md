# Act I opening: the interrupted feast

Act I now opens in the existing Shatili castle feast scene. Aluda sits with four guests. Press E to bring the messenger in; after closing each dialogue with Enter, press E to answer and then leave. Outside, E mounts a horse and starts a short ride toward the existing tracking area. The feast, courtyard and ride staging are new game inventions; the attack, stolen horses and pursuit follow the Act I design. The messenger does not identify the raiders by name before Aluda encounters Mutsal's brother and Mutsal in the crags.

The castle and horse sequence is a staged first pass, with simple procedural horse artwork rather than a controllable mounted traversal system. A one-shot SceneTree flag records that the report was heard and starts the existing tracking state without repeating the messenger encounter. Opening the tracking scene directly still permits the original report for testing. Starting an act from the menu clears the temporary flag.

Run `godot --headless --path . --script res://tests/act_one_feast_smoke.gd` for the scene setup and handoff. Visually play through Act I from the act menu to review the timing, art, and transitions.
