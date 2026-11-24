class_name FinishAdRewardTable
extends RefCounted


const ENTRIES: Array[Dictionary] = [
	{"kind": "coins", "count": 1200, "weight": 10, "tier": "normal"}, 
	{"kind": "coins", "count": 1500, "weight": 10, "tier": "nice"}, 
	{"kind": "coins", "count": 2000, "weight": 10, "tier": "lucky"}, 
	{"kind": "undo", "count": 3, "weight": 5, "tier": "normal"}, 
	{"kind": "undo", "count": 4, "weight": 10, "tier": "nice"}, 
	{"kind": "undo", "count": 5, "weight": 10, "tier": "lucky"}, 
	{"kind": "hint", "count": 2, "weight": 5, "tier": "normal"}, 
	{"kind": "hint", "count": 3, "weight": 10, "tier": "nice"}, 
	{"kind": "hint", "count": 4, "weight": 10, "tier": "lucky"}, 
	{"kind": "rope", "count": 1, "weight": 5, "tier": "nice"}, 
	{"kind": "rope", "count": 2, "weight": 15, "tier": "lucky"}, 
]

static func draw() -> Dictionary:
	var entries: Array[Dictionary] = available_entries()
	var total_weight: int = 0
	for entry: Dictionary in entries:
		total_weight += int(entry["weight"])
	return pick(randi_range(0, total_weight - 1), entries)


static func available_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in ENTRIES:
		if entry["kind"] == "coins" or UserState.is_prop_unlock_shown(String(entry["kind"])):
			entries.append(entry)
	return entries

static func pick(ticket: int, entries: Array[Dictionary] = []) -> Dictionary:
	if entries.is_empty():
		entries = available_entries()
	var boundary: int = 0
	for entry: Dictionary in entries:
		boundary += int(entry["weight"])
		if ticket < boundary:
			return entry.duplicate()
	return entries.back().duplicate()
