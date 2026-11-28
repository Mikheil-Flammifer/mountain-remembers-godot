# Act II: Night camp and dream [Changed]

Act II is a separate round. It starts only after Act I is finished and has its own state, scene and tests.

## Separation from Act I

- `scripts/systems/story/act_two_state.gd` (`ActTwoState`) owns the Act II sequence. It does not reference `ActOneState`.
- Act I passes one session value, `aluda_act_one_hand_choice`, through `SceneTree` metadata. Act I sets it only after its `COMPLETE` phase, so Act II treats it as proof that Act I is finished. Act I code is unchanged.
- `ActTwoState.begin()` refuses to start without a completed Act I and a deliberate hand choice. If `night_camp.tscn` is opened directly, it stays locked and E returns to Act I.
- Act II never writes Act I values. It writes `aluda_act_two_dream_choice` (only from the dagger action) and `aluda_act_two_complete`.

## Sequence

1. Tend the fire (x 540, E).
2. Check the rifle: powder, bullet, ramming, priming (x 380, E).
3. Keep watch at the lookout stone (x 960, E).
4. Sleep by the fire (E). The dream begins.
5. Dream gathering [Poem, moved]: warriors sit around the dead at a meal. The food is implied, never shown (x 700, E).
6. Mirror duel [New]: face Mutsal's shade (x 1080, E). He swings every 1.8 s while Aluda is near. Holding the shield (G) when he swings counts as a parry. Three parries end the duel. Each sword swing (H) adds a round, up to six. A missed guard costs nothing and makes no choice.
7. Dagger: walk to x 850 and press E to turn it aside, or to x 1220 and press E to strike. This is the only place the dream choice is recorded. It is untimed.
8. Wake, reflect by the fire (E), then break camp at the road marker (x 1800, E). Act II is complete. Act III is not built yet.

## Validation

```bash
godot --headless --path . --script res://tests/act_two_state_smoke.gd
godot --headless --path . --script res://tests/act_two_night_camp_smoke.gd
```

Both passed headless on Godot 4.6.3 (4.7 was not available). Not checked: in-editor play, visuals, feel of the duel timing.

## Dialogue source

The dream lines follow Vazha-Pshavela's poem *Aluda Ketelauri* (1888, public
domain), Canto III, in a close English translation made for this game:
the nightfall narration, the wake for the dead, Mutsal putting a dagger in
Aluda's hand and begging "I want to die, and I do not die. Kill me!", the
bowl of human flesh, and "Bad dreams tormented me". In the poem the feast
comes after Mutsal speaks, and Aluda tells the dream at home to his mother and
sister, who beg him to eat bread. The game moves the dream to the night camp
and plays the feast first. The camp chores (fire, rifle, watch), the
dream duel and Aluda's arrival and reflection lines are new and not in the poem.
