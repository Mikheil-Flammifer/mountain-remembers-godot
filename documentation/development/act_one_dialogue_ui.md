# Act 1: dialogue presentation

Act 1 has a dedicated bottom-of-screen dialogue panel, implemented in `scripts/ui/aluda_dialogue_panel.gd`. It is **presentation only**. `scripts/levels/aluda/act_one_tracking.gd` still owns story phases, interactions, clue state, and combat events.

## Visual language

The panel is pinned to the lower 26% of the viewport through a `CanvasLayer` and fractional anchors. The translucent dark-slate surface, warm gold border, inset accent, and light text match the Khevsureti mountain palette without obstructing the horizon. The header displays the speaker and a subtle Act I chapter identifier; the body wraps long dialogue; the footer shows dialogue controls.

Only the compact quest status remains at the upper left. An interaction hint is shown near the bottom while exploration is active, but hidden during a dialogue so it does not overlap the panel.

## Behaviour

- Approaching the messenger and pressing **E** opens speech from **Messenger**, just as before.
- Interacting with clues opens narration from **The trail**.
- At the river detour, Sanata's existing speech appears under the speaker name **Sanata**. The old internal `[New]` tag is not shown to players.
- Rifle encounter status is presented through the same panel under **The crags**.
- Text reveals gradually; **Enter** reveals the complete line and then closes it. **Escape** closes immediately.
- **E** remains world interaction: the panel does not pause movement or prevent the tracking smoke test from visiting the next clue. Story triggers and floor collision remain unchanged.

## API

The `AludaDialoguePanel` class provides `show_line(speaker, text, instant=false)`, `reveal_all()`, `advance()`, `close()`, `is_open`, `current_speaker`, `current_text`, and a `dismissed` signal. It can be instantiated in future Aluda scenes without duplicating the visual styling.

## Verification

Open `scenes/levels/aluda/act_one/tracking.tscn` and run with F6. Test the messenger, hoofprints, Sanata, and the rifle encounter. Try narrow windows to verify text wrapping.

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_dialogue_smoke.gd
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_landmarks_smoke.gd
godot --headless --path . --script res://tests/rifle_encounter_smoke.gd
```

The Godot engine must be available for actual runtime and visual verification.
