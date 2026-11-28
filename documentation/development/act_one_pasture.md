# Act 1 — Wind-cut Pasture tracking

This pass changes the second sub-area from a simple walk into a readable, **optional investigation**. It keeps the continuous level, the original five `ActOneState` trail clues, the river meeting with Sanata and the first rifle encounter intact.

## What the player sees

The pasture (world X 650–1239) now has three places to examine and a small route judgment. Each sign is visible as procedural slate scratches or trampled vegetation, with the same E-key interaction and bottom dialogue panel already used by Shepherds' Fold.

| X | Sign | Reading |
| --- | --- | --- |
| 750 | Hoofprints | A damaged horseshoe has left repeated, deep impressions going uphill |
| 900 | Scraped slate **[New]** | An iron shoe scraped an uphill-facing rock |
| 1060 | Bent grass | Flattened stalks and torn tips point to the upper ridge |
| 1160 | Upper ledge **[New]** | Confirm that the raiders travelled by the windward ridge |
| 1220 | Sheltered gully **[New]** | Identify a misleading set of small goat tracks |

The authored details (a damaged shoe, slate scrape, and goat tracks) are **[New]** deductions invented for this game's raid sequence, not attributed to Vazha-Pshavela's poem. The raiders' pursuit toward the Arkhoti heights and the optional river detour follow the existing game design.

## Gameplay and fairness

- The player starts tracking only after hearing the Messenger's raid report.
- Hoofprints and bent grass remain recorded in the existing `ActOneState.trail_clues` dictionary. Slate is an extra local sign in `WindPastureTracking`.
- Examine **hoofprints and bent grass** before confirming the upper ledge. Scraped slate is an optional third supporting clue.
- Guessing early gives a hint to investigate rather than inflicting damage, losing a resource or selecting a moral option.
- The sheltered gully can be inspected, but is not a separate teleported level; looking at it counts a false lead at most once.
- A correctly found ridge gives the player **1.5 additional seconds** before Mutsal's brother fires his first shot. The advantage also applies when restarting the rifle encounter.
- The player can ignore all these signs and walk to Sanata or the crags. Neither tracking mistakes nor skipping clues changes the story's moral choices.

## Code ownership

- `scripts/levels/aluda/wind_pasture_tracking.gd` owns optional per-run clue state and route confirmation. The script is not saved and has no knowledge of presentation.
- `scripts/levels/aluda/wind_pasture_signs.gd` paints the slate scrape, upper ledge, and gully signs in local sub-area coordinates. These have **no collision**.
- `scenes/levels/aluda/act_one/subareas/wind_pasture.tscn` adds a `TrailSigns` child.
- `scripts/levels/aluda/act_one_tracking.gd` dispatches E interactions, updates on-screen progress, and applies the approach bonus to the existing `RifleEncounter.enemy_timer`.

The existing fall-through route, controls, camera, Sanata encounter, and original combat checks are preserved.

## Verification

With Godot 4.7 and the project imported:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_pasture_smoke.gd
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_landmarks_smoke.gd
godot --headless --path . --script res://tests/act_one_sheepfold_smoke.gd
godot --headless --path . --script res://tests/act_one_subareas_smoke.gd
```

Open `scenes/levels/aluda/act_one/tracking.tscn` and use **F6** to run it visually. Check that the new clue markers identify the correct props, the gully and ridge interact separately, and the first rifle encounter retains its original rules while offering the small head start.
