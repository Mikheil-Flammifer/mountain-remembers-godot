# Act I room transitions and route hazards

The pursuit is divided into five areas: Shepherds' Fold, Wind-cut Pasture, Sanata's Ford, Arkhoti Crags and Mutsal's Crags. Crossing an area edge fades out, moves Aluda just inside the next area and fades in. Crossing back works as well. The level and story state remain alive during transitions, so clues, route deductions and choices persist. The boundary to Mutsal's Crags is closed until the brother is defeated; Mutsal's combat timer waits until the player enters that area.

Four visible unstable-ground patches are new gameplay inventions. Touching one returns Aluda to a safe point in the current area without undoing clues or making a moral choice. Jump over them. The existing clue objects, Sanata, rifle encounters and hand decision remain in place. The five areas use the existing route's coordinates and art; the fifth has its own editable visual scene. This is a room-transition pass, not an expansion of the physical length of the route.

Run `godot --headless --path . --script res://tests/act_one_rooms_smoke.gd` for hazard collision, jumping, transitions, backtracking, gate and state preservation. Also run the tracking, pasture and finale smoke tests. Play through visually to assess pacing, artwork and encounter timing.
