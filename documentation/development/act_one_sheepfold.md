# Act 1: Shepherds' Fold investigation

This incremental gameplay pass makes the first highland sub-area interactive instead of decorative only. It follows the established six-ending outline: the messenger reports stolen horses, the dogs are silent at dawn, and Aluda follows signs toward the Arkhoti heights.

## Objects and interactions

| World X | Object | First E interaction | Repeat interaction |
| --- | --- | --- | --- |
| 160 | Messenger | Advances `ActOneState` from RAID_REPORT to TRACKING | Recalls the raid report |
| 295 | Cut halter | Notes deliberate cutting of a horse's leather tether **[New]** | Re-examines the cut |
| 430 | Silent sheepdog | Records the existing `dogs` tracking clue | Gently comforts the dog; it starts wagging its tail **[New]** |
| 570 | Broken gate | Examines shattered crossbar and hoof-marked earth **[New]** | Reviews the gate's damage |

All speech appears in the existing bottom dialogue UI. The upper-left status shows **SHEEPFOLD 0 / 3** while within the sheepfold (alongside the original trail clue count). The optional evidence includes the halter, dog and gate. There is no inventory, damage, collision, or extra required objective.

The dog is a **new, unnamed sheepfold animal**, distinct from Murana, who is Aluda's family dog in the wider story. It is a low-cost, original painted Node2D silhouette with gentle breathing. Its idle tail moves more after the second dog interaction; it does not follow the player, fight, or award advantages.

## Architecture

- `scripts/levels/aluda/shepherds_fold_investigation.gd`: runtime data for optional evidence and calm state; per-scene instance owned by `act_one_tracking.gd`. The scene decides how to show dialogue.
- `scripts/levels/aluda/silent_sheepdog.gd`: decorative dog with a `soothe()` presentation method. It has no collider or gameplay state.
- `scripts/levels/aluda/shepherds_fold_props.gd`: statically painted halter and gate splinters.
- `scenes/levels/aluda/act_one/subareas/shepherds_fold.tscn`: includes the evidence props and dog as editable children without moving the existing scene.
- `scripts/levels/aluda/act_one_tracking.gd`: dispatches the new optional interactions, selects the nearest nearby clue, and keeps the existing `ActOneState` authoritative.

Original tracking IDs (`dogs`, `hoofprints`, `grass`, `stones`, `birds`) remain unchanged; only the existing `dogs` clue is shared with the first dog interaction. Finding extra evidence does not change the morality decisions or story outcomes. The gameplay still allows entering the crags without examining the halter or gate.

## Testing

In Godot 4.7, open `scenes/levels/aluda/act_one/tracking.tscn` and run F6. Speak to the messenger, inspect the halter at x295, approach the sheepdog and press E twice, and examine the broken gate. Return to either object to see its repeated observation. Enter the pasture and verify that the original tracking clues still work.

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_sheepfold_smoke.gd
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_landmarks_smoke.gd
godot --headless --path . --script res://tests/act_one_subareas_smoke.gd
godot --headless --path . --script res://tests/act_one_dialogue_smoke.gd
```

These tests must be run in Godot before reporting them as passed.
