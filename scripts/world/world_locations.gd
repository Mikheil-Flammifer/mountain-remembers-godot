extends RefCounted

const MAP_SIZE := Vector2(1400, 1000)

const LOCATIONS := [
	{
		"id": "mtskheta",
		"name": "Mtskheta",
		"position": Vector2(533, 729),
		"description": "Ancient royal and sacred center of Kartli.",
		"known": true
	},
	{
		"id": "tbilisi",
		"name": "Tbilisi",
		"position": Vector2(806, 889),
		"description": "A growing city of bridges, walls, and courts.",
		"known": true
	},
	{
		"id": "stepantsminda",
		"name": "Stepantsminda",
		"position": Vector2(465, 306),
		"description": "A highland settlement beneath the great mountain.",
		"known": true
	},
	{
		"id": "shatili",
		"name": "Shatili",
		"position": Vector2(1015, 235),
		"description": "A famed fortified settlement of Khevsureti.",
		"known": false
	},
	{
		"id": "mutso",
		"name": "Mutso",
		"position": Vector2(781, 188),
		"description": "A dramatic fortress settlement high in the mountains.",
		"known": false
	},
	{
		"id": "omalo",
		"name": "Omalo",
		"position": Vector2(1232, 388),
		"description": "Tusheti's mountain stronghold and remote heart.",
		"known": false
	},
	{
		"id": "zhinvali",
		"name": "Zhinvali",
		"position": Vector2(605, 512),
		"description": "Old river town and crossroads in the Aragvi gorge.",
		"known": false
	},
	{
		"id": "dusheti",
		"name": "Dusheti",
		"position": Vector2(477, 551),
		"description": "A lower-road settlement toward Kartli.",
		"known": false
	},
	{
		"id": "ananuri",
		"name": "Ananuri",
		"position": Vector2(561, 447),
		"description": "Fortress overlooking the Aragvi route.",
		"known": false
	},
	{
		"id": "tianeti",
		"name": "Tianeti",
		"position": Vector2(746, 535),
		"description": "A road settlement between valleys and uplands.",
		"known": false
	},
	{
		"id": "jvari",
		"name": "Jvari",
		"position": Vector2(470, 616),
		"description": "Monastery above Mtskheta.",
		"known": true
	},
	{
		"id": "svetitskhoveli",
		"name": "Svetitskhoveli",
		"position": Vector2(553, 672),
		"description": "Cathedral and spiritual center of Mtskheta.",
		"known": true
	},
]

const ROUTES := [
	["mtskheta", "tbilisi"],
	["mtskheta", "ananuri"],
	["jvari", "zhinvali"],
	["zhinvali", "ananuri"],
	["zhinvali", "dusheti"],
	["ananuri", "stepantsminda"],
	["ananuri", "tianeti"],
	["tianeti", "shatili"],
	["shatili", "omalo"],
	["shatili", "mutso"]
]
