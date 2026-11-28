class_name ActOneSubareas
extends RefCounted
## Authored Act 1 tracking regions. Decorative changes never alter quest state.
## All x coordinates are in the existing continuous ActOneTracking world.

const SHEEPFOLD_END: float = 650.0
const PASTURE_END: float = 1240.0
const FORD_END: float = 1920.0

const REGIONS := [
	{
		"id": &"shepherds_fold",
		"title": "THE SHEPHERDS' FOLD",
		"subtitle": "The stolen horses · Dawn in the high valleys",
		"short_name": "Shepherds' Fold",
		"start": -150.0,
		"end": SHEEPFOLD_END
	},
	{
		"id": &"wind_pasture",
		"title": "WIND-CUT PASTURE",
		"subtitle": "Grass bent by hooves · The trail toward Arkhoti",
		"short_name": "Wind-cut Pasture",
		"start": SHEEPFOLD_END,
		"end": PASTURE_END
	},
	{
		"id": &"sanata_ford",
		"title": "SANATA'S FORD",
		"subtitle": "Cold water · An uncertain detour",
		"short_name": "Sanata's Ford",
		"start": PASTURE_END,
		"end": FORD_END
	},
	{
		"id": &"arkhoti_crags",
		"title": "ARKHOTI CRAGS",
		"subtitle": "Broken rock · Raiders ahead",
		"short_name": "Arkhoti Crags",
		"start": FORD_END,
		"end": 3300.0
	},
]


static func index_at(world_x: float) -> int:
	if world_x < SHEEPFOLD_END:
		return 0
	if world_x < PASTURE_END:
		return 1
	if world_x < FORD_END:
		return 2
	return 3


static func region(index: int) -> Dictionary:
	if index < 0 or index >= REGIONS.size():
		return {}
	return REGIONS[index]
