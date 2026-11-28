# Playable Act I → Act II chapter flow

This patch closes an existing progression gap. **Act I now begins when the game launches**, traverses four contiguous Khevsureti sub-areas, continues past Mutsal's brother into Mutsal's duel and a deliberate hand decision, and only then unlocks the transition to the playable **Act II night camp**.

## Launch and locations

`project.godot` points to `scenes/levels/aluda/act_one/tracking.tscn`. The previous character preview remains at `scenes/levels/aluda/character_preview.tscn`, available by opening it directly.

The original sub-area scenes remain children of the single Act I scene:
Shepherds' Fold (x below 650), Wind-cut Pasture (650–1239), Sanata's Ford (1240–1919) and Arkhoti Crags (1920 onward). Walking between them interpolates **camera zoom** and **CanvasModulate tint**. Area title cards still appear, and no level reload occurs. The furthest new area reached becomes an **in-memory recovery checkpoint** (x=690, 1270, 1960), used if Aluda falls below the stage; backtracking never erases story state.

The painted Arkhoti section and floor now extend beyond x=3750 to support the full finale and road to the camp. Visual objects do not own collision.

## Act I completion (Poem, expanded; prototype combat)

1. Talk to the Messenger at x=160; investigate the fold and follow signs, optionally meeting Sanata.
2. At x=2400, press **E** to start the existing rifle encounter against Mutsal's brother. The earlier **F** fire and **R** four-stage reload rules remain.
3. When the brother is defeated, Mutsal appears at the far end of the crags (x=3260). This **new prototype duel** uses F to fire, R to reload, and a separate cover rock at x~2930. Stand at x=3000–3170 facing right to land a shot. The first successful shot moves the canonical `ActOneState` into `MUTSAL_COVER` and breaks the powder horn; the second, after reloading, mortally wounds Mutsal.
4. Mutsal's last shot and thrown rifle are scripted at the `MUTSAL_FINAL` phase, following the story design. The timer **only** ends the duel. It never makes the hand choice.
5. **Hand decision:** At x≈3260, hold **H** for 1.4 seconds to follow the old custom and cut; alternatively, walk to x≈3460 and press **E** to cover Mutsal and spare his hand. Neither is triggered by losing, missing, or simply waiting. Both decisions go through `ActOneState.decide_hand` and `finish_aftermath`.
6. Only after `ActOneState.Phase.COMPLETE` does the stone road near x≈3750 accept **E**. A short fade hands off to `scenes/levels/aluda/act_two/night_camp.tscn`.

The duel and choice are a playable first pass, not a final, fully animated boss encounter. Additional sound, cues, battle stages and accessibility will need in-editor refinement.

## Act II opening (Changed/New)

Act II now has a playable night camp, consistent with the six-ending design plan's deliberate relocation of the dream to a night shelter on the way home. Aluda can approach the fire (x≈540), press E to tend it, then press E again after watch to enter the dream. At the dream's fork, walking to x≈850 and pressing **E** lowers the dagger, while x≈1220 and E strikes. This is a deliberate, untimed action. Aluda wakes by the fire and can reflect; **the remainder of Act II is not implemented yet**.

The Act I hand choice passes to Act II through `SceneTree` metadata `aluda_act_one_hand_choice` immediately before the fade. The dream action is recorded in `aluda_act_two_dream_choice`. These are **session-only fields**, not durable saves; restarting the application begins a new Act I run. They are intentionally limited to the two connected chapters rather than a new global save architecture.

## Validation

Run Godot 4.7 from the repository root:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/act_one_finale_smoke.gd
godot --headless --path . --script res://tests/act_two_night_camp_smoke.gd
godot --headless --path . --script res://tests/act_one_state_smoke.gd
godot --headless --path . --script res://tests/act_one_tracking_smoke.gd
godot --headless --path . --script res://tests/act_one_subareas_smoke.gd
godot --headless --path . --script res://tests/act_one_pasture_smoke.gd
```

**Manual play test:** Start with F5. Check continuous area crossings, camera easing, fall checkpoint, both rifle duels, each hand choice, fading to the night camp, and both untimed dream actions. Check the 1.4-second hold does not complete unintentionally. Neither headless tests nor rendering can be claimed passing without running Godot.
