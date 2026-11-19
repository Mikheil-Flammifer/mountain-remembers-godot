class_name MtskhetaInvestigationData
extends RefCounted

## Data only: clues and conversations for the two-district investigation.
## These are rumors, not confirmation of Samdzivari's whereabouts.

const MARKET_CLUE: String = (
    "An Aragvi merchant heard of a lone woman who refused shelter "
    + "and continued toward the mountain villages. Her name was unknown."
)
const STREETS_CLUE: String = (
    "A pilgrim heard that a stranger asked about the higher paths "
    + "beyond the Aragvi valley before leaving at dawn."
)


static func conversation(npc_id: String, market_known: bool, streets_known: bool) -> Dictionary:
    match npc_id:
        "aragvi_merchant":
            if not market_known:
                return {
                    "clue": MARKET_CLUE,
                    "lines": [
                        {"speaker": "Aragvi Merchant", "text": "You are looking toward the mountains, young man. Is someone waiting for you there?"},
                        {"speaker": "Xizane", "text": "My sister, Samdzivari. She vanished after the fighting between Sakhare and Khevari."},
                        {"speaker": "Aragvi Merchant", "text": "A mule driver spoke of a woman traveling alone. She refused shelter and went toward the high villages."},
                        {"speaker": "Xizane", "text": "Did he know her name?"},
                        {"speaker": "Aragvi Merchant", "text": "No. Ask the pilgrim in the old streets. He has come from farther north."},
                    ]
                }
            return {
                "lines": [
                    {"speaker": "Aragvi Merchant", "text": "I told you all I heard. The pilgrim in the streets may know more."},
                    {"speaker": "Xizane", "text": "Then I will speak with him."},
                ]
            }
        "street_pilgrim":
            if not market_known:
                return {
                    "lines": [
                        {"speaker": "Pilgrim", "text": "You seek news from the north? A merchant in the market has just returned from the Aragvi road."},
                        {"speaker": "Xizane", "text": "I will ask him what he heard."},
                    ]
                }
            if not streets_known:
                return {
                    "clue": STREETS_CLUE,
                    "lines": [
                        {"speaker": "Xizane", "text": "The merchant spoke of a woman traveling alone. Have you heard anything?"},
                        {"speaker": "Pilgrim", "text": "A household beyond the valley sheltered a stranger for one night."},
                        {"speaker": "Pilgrim", "text": "At dawn she asked which paths climbed above the river. Then she was gone."},
                        {"speaker": "Xizane", "text": "It might be Samdzivari. But a rumor is not proof."},
                        {"speaker": "Pilgrim", "text": "Go to Svetitskhoveli. Speak with the monk before you take the northern road."},
                    ]
                }
            return {
                "lines": [
                    {"speaker": "Pilgrim", "text": "The monk at Svetitskhoveli may help you decide what to do next."},
                ]
            }
    return {"lines": []}


# Only an inference: neither witness identified the traveler.
const DEDUCTION_CLUE: String = (
    "The merchant and pilgrim independently suggest the northern Aragvi "
    + "route, but neither identified the traveler as Samdzivari. "
    + "I should seek further evidence at Svetitskhoveli."
)


static func deduction_available(entries: Array[String]) -> bool:
    return entries.has(MARKET_CLUE) and entries.has(STREETS_CLUE)


static func deduction_feedback(choice: int) -> String:
    match choice:
        1:
            return "Not proven: no witness knew the woman's name."
        2:
            return "A cautious conclusion. The northern route is a lead, not proof."
        3:
            return "Not proven: two accounts may describe different travelers."
        _:
            return "Choose 1, 2, or 3."
