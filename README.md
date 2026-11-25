# The Mountain Remembers

**The Mountain Remembers** is a 2D action-adventure RPG set in a fictionalized medieval Georgian world inspired by Georgian landscapes, architecture, folklore, and mountain culture.

The player controls **Xizane**, who leaves Mtskheta and travels north in search of his missing sister, **Samdzivari**.

The game is being developed in **Godot 4 with GDScript**.

---

## Current Playable Route

```text
Mtskheta → Jvari → Zhinvali
```

Implemented regions include:

- Mtskheta
- Jvari
- Zhinvali
- Ananuri Approach
- Dusheti Approach

Zhinvali introduces branching mountain routes, vertical traversal, ladders, forests, rivers, ruins, and optional areas.

---

## Gameplay

Current systems include:

- running and jumping
- double jump
- dashing
- coyote time and jump buffering
- Mountain Blade sword combat
- directional attacks
- two-hit combos
- shield blocking
- stamina
- poise and stagger
- healing stones
- checkpoints
- upgrades
- score rewards
- death and score recovery
- branching exploration

---

## Combat

Enemies use different combat styles instead of only changing health and damage.

### Mtskheta

- Mountain Wolf
- Shield Guard
- Swordsman

### Jvari

- Sentry
- Raider
- Wraith
- Warden
- Wild Boar

Jvari enemies can use mechanics such as:

- blocking
- guard breaking
- backstepping
- counterattacks
- dodging
- poise
- heavy attacks

### Zhinvali

Enemies include:

- raiders
- archers
- mountain hawks

Enemy attacks use actual attack windows instead of simple contact damage.

---

## Progression

Defeated enemies award score.

Score can be spent at rest points to improve:

- maximum HP
- maximum energy
- Mountain Blade
- Shield
- Healing Stones

When Xizane dies, carried score is left behind as a recoverable memory.

---

## Current Controls

| Action | Key |
| --- | --- |
| Move | A / D |
| Jump | Space |
| Dash | Shift |
| Mountain Blade | H |
| Shield | G / Right Mouse |
| Healing Stone | R |
| Interact / Rest | E |
| Item Interaction | Q |

---

## World Design

The game is moving toward connected, layered environments rather than simple horizontal levels.

Current areas can contain:

- upper and lower routes
- slopes
- ladders
- cliffs
- platforms
- forests
- rivers
- ruins
- hidden areas
- environmental storytelling

The goal is to make travelling through the world feel like moving through a connected Georgian mountain landscape.

---

## Technology

- Godot 4.x
- GDScript
- 2D physics
- procedural environment drawing
- reusable enemy scenes
- reusable level components
- persistent progression

---

## Main Goal

The main story is about **Xizane searching for Samdzivari and discovering what happened to her**.

Combat and platforming support the journey, while exploration, atmosphere, and story discovery remain central to the game.