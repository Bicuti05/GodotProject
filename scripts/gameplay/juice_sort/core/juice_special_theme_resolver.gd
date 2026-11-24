class_name JuiceSpecialThemeResolver
extends RefCounted


static func resolve(level: int, special: bool, instance_id: String, frozen_id: String, 
		tutorial: bool, reward_pending: bool, use_theme: bool, previous: Dictionary, 
		next_sequence: int) -> Dictionary:
	if tutorial or reward_pending:
		return {"skin_id": "default"}
	if not frozen_id.is_empty():
		return {"skin_id": frozen_id}
	if not use_theme:
		return {"skin_id": "default"}
	if not previous.is_empty():
		return {"skin_id": previous["skin_id"]}
	return {"skin_id": "cat" if next_sequence % 2 == 0 else "bird", "sequence": next_sequence, 
		"round_kind": "special_challenge" if special else "level", 
		"round_key": instance_id if special else "level:%d" % level}
