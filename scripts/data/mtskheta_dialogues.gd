extends RefCounted
## Data-only dialogue definitions; no UI, physics, or save calls.

const PEOPLE: Array[Dictionary] = [
	{"id": "elder", "name": "Mtskheta Elder", "x": 680.0, "color": Color("655044")},
	{"id": "pilgrim", "name": "Pilgrim", "x": 1570.0, "color": Color("526b63")},
	{"id": "traveler", "name": "Highland Traveler", "x": 3050.0, "color": Color("514859")},
]


static func conversation(person_id: String, stage: int) -> Dictionary:
	match person_id:
		"elder":
			if stage == 0:
				return {
					"speaker": "Mtskheta Elder", "complete_stage": 1,
					"journal": "The elder says a pilgrim may know the northern roads.",
					"lines": [
						"Xizane, you have been quiet since the news from Sakhare.",
						"Your sister Samdzivari vanished after the quarrel between the two villages.",
						"A pilgrim passing through Mtskheta spoke of the northern roads. Find them near the eastward path."
					]
				}
			return {"speaker": "Mtskheta Elder", "lines": ["You cannot untangle every rumor here. Seek the truth, Xizane."]}
		"pilgrim":
			if stage < 1:
				return {"speaker": "Pilgrim", "lines": ["The elder might help you understand where to begin."]}
			if stage == 1:
				return {
					"speaker": "Pilgrim", "complete_stage": 2,
					"journal": "A highland traveler may have news from Khevsureti.",
					"lines": [
						"The road north divides beyond the settled valleys.",
						"I met a traveler who had come down from Khevsureti. You will find them farther east.",
						"Listen carefully. In the mountains, a name can be remembered long after a person is gone."
					]
				}
			return {"speaker": "Pilgrim", "lines": ["You will find the traveler farther along the road."]}
		"traveler":
			if stage < 2:
				return {"speaker": "Highland Traveler", "lines": ["I have come a long way. Speak with those of Mtskheta first."]}
			if stage == 2:
				return {
					"speaker": "Highland Traveler", "complete_stage": 3,
					"journal": "A woman may have been seen heading into the highlands.",
					"lines": [
						"In the high villages I heard talk of a woman walking alone toward the mountains.",
						"No one could tell me her name. But some said she refused to return to the valley.",
						"If you seek her, the road through the Aragvi valley is your beginning."
					]
				}
			return {"speaker": "Highland Traveler", "lines": ["Follow the Aragvi valley. Travel carefully."]}
	return {}
