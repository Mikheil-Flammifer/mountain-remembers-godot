# Architecture migration and verification

The first implementation completes the player visual slot, separates the mountain wolf's rig and feedback, and moves progression persistence and shrine UI into focused modules. Existing scenes remain at their established paths so the levels continue to instantiate them.

## Validation

Use Godot 4.7 from the project root. Import the project with `godot --headless --path . --import`, then run each script with `godot --headless --path . --script res://tests/<name>.gd`. For `architecture_smoke.gd`, use a fresh Godot user-data directory. On Windows, set APPDATA to a disposable absolute directory for the test process. The test creates a legacy save fixture and checks an alternate visual, movement, sword hits, shield, healing, score recovery, shrine upgrades and saved state.

The original baseline had a travel test parse error and two unsafe terrace return spawns. The route test now includes the monastery interior and wardens arena and checks the Jvari connection to Zhinvali's river gate. Valid scene comments restore the terrace node hierarchy and the north road wolf's authored scene overrides. The terrace return markers now satisfy the existing clearance check.

The local Godot 4.7.2 Mono build reports a missing .NET SDK during editor import and a Windows certificate-store error. The headless GDScript runtime checks can still run in that environment. Visual parity and full playthroughs require in-editor play testing.

## Later migrations

Use the current boundaries as examples. Separate the presentation of another actor or a single district when it needs work, then add shared behavior or data only where two scenes have a concrete need. Keep story, collision, progression values and established routing stable during asset or folder changes.
