class_name ShepherdsFoldInvestigation
extends RefCounted
## Optional evidence in the Shepherds' Fold. No story branches or save mutations.
## The ActOneTracking scene owns the instance and sends text to the dialogue UI.

signal evidence_found(clue_id: StringName)
signal dog_comforted

const EVIDENCE_IDS := [&"halter", &"dogs", &"gate"]

var inspected: Dictionary = {}
var dog_calm: bool = false


func examine(clue_id: StringName) -> Dictionary:
	if clue_id not in EVIDENCE_IDS:
		return {}

	match clue_id:
		&"halter":
			if not inspected.has(clue_id):
				_record(clue_id)
				return {
					"speaker": "Aluda",
					"text": "The halter was cut clean through. The horses did not break loose; someone led them away."
				}
			return {
				"speaker": "The trail",
				"text": "The severed halter still hangs from the rail. The cut points toward a deliberate theft."
			}
		&"dogs":
			if not inspected.has(clue_id):
				_record(clue_id)
				return {
					"speaker": "Aluda",
					"text": "The shepherd's dog has not barked since dawn. It watches the broken gate, too frightened to rise."
				}
			if not dog_calm:
				dog_calm = true
				dog_comforted.emit()
				return {
					"speaker": "Aluda",
					"text": "Easy, old friend. The dog takes a cautious step toward Aluda, then turns its gaze to the mountain path.",
					"soothed": true
				}
			return {
				"speaker": "The trail",
				"text": "The dog is calmer now. Its ears still turn toward the path leading out of the fold."
			}
		&"gate":
			if not inspected.has(clue_id):
				_record(clue_id)
				return {
					"speaker": "Aluda",
					"text": "The wooden crossbar was forced outward. Several horses were driven through here in haste."
				}
			return {
				"speaker": "The trail",
				"text": "Fresh splinters and churned earth mark the way out toward the high pasture."
			}
	return {}


func evidence_count() -> int:
	return inspected.size()


func _record(clue_id: StringName) -> void:
	inspected[clue_id] = true
	evidence_found.emit(clue_id)
