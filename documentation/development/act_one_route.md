# Act 1 route and preview boundaries

The character preview and Act 1 now have collision boundaries inside their floor edges, preventing Aluda from walking or jumping off the authored terrain. Act 1 has two low collision stones between investigation areas; their visible shapes match their collision, and Aluda can jump over them. These obstacles are new gameplay additions, not events from the poem. The messenger, clues, optional route judgment, Sanata and rifle encounter retain their existing positions and rules.

The interaction hint includes the examine key. The route continues through the Mutsal encounter and the hand decision to the night camp.

Run `godot --headless --path . --script res://tests/act_one_route_physics.gd` to check the preview edge, the first stone and the Act 1 edge with real player physics. Open the tracking scene with F6 for a visual playthrough.
