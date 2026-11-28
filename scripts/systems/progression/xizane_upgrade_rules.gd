class_name XizaneUpgradeRules
extends RefCounted
## Shared balance rules for gameplay stats and upgrade previews.

const MAX_UPGRADE_LEVEL: int = 5
const UPGRADE_COSTS: Dictionary = {
	"blade": [0, 90, 210, 380, 620],
	"shield": [0, 75, 180, 330, 540],
	"stone": [0, 85, 200, 360, 580],
	"hp": [0, 100, 230, 420, 680],
	"energy": [0, 95, 220, 400, 650],
}

static func default_levels() -> Dictionary:
	var levels := {}
	for kind: String in UPGRADE_COSTS:
		levels[kind] = 1
	return levels


static func clamp_level(level: int) -> int:
	return clampi(level, 1, MAX_UPGRADE_LEVEL)


static func cost_for_level(kind: String, level: int) -> int:
	if level >= MAX_UPGRADE_LEVEL or not UPGRADE_COSTS.has(kind):
		return -1
	return int(UPGRADE_COSTS[kind][clamp_level(level)])


static func blade_damage_for_level(level: int) -> int:
	return 8 + (clamp_level(level) - 1) * 2


static func stone_heal_for_level(level: int) -> int:
	return 30 + (clamp_level(level) - 1) * 10


static func max_hp_for_level(level: int) -> int:
	return 100 + (clamp_level(level) - 1) * 12


static func max_energy_for_level(level: int) -> float:
	return 100.0 + float(clamp_level(level) - 1) * 12.0


static func shield_cost_multiplier(level: int) -> float:
	return 1.0 - float(clamp_level(level) - 1) * 0.08


static func guard_break_damage_multiplier(level: int) -> float:
	return clampf(0.70 - float(clamp_level(level) - 1) * 0.08, 0.38, 0.70)


static func value_text(kind: String, level: int) -> String:
	match kind:
		"blade":
			return "%d damage" % blade_damage_for_level(level)
		"shield":
			return "%d%% guard efficiency" % roundi(100.0 / shield_cost_multiplier(level))
		"stone":
			return "%d HP healed" % stone_heal_for_level(level)
		"hp":
			return "%d max HP" % max_hp_for_level(level)
		"energy":
			return "%d max energy" % roundi(max_energy_for_level(level))
	return ""
