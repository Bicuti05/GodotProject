class_name LevelProvider
extends RefCounted








static func pick(candidates: Array[Dictionary], user_tags: Dictionary) -> Dictionary:
	var default_candidate: Dictionary = {}
	for c: Dictionary in candidates:
		var raw_tags: String = String(c.get("levelUserTags", "default"))
		if raw_tags.is_empty() or raw_tags == "default":
			if default_candidate.is_empty():
				default_candidate = c
			continue
		var hit: Dictionary = _match(raw_tags, user_tags)
		if not hit.is_empty():
			return c
	return default_candidate








static func pick_downgrade(candidates: Array[Dictionary], patch_candidates: Array[Dictionary], 
		tag_chain: Array[Dictionary]) -> Dictionary:
	if tag_chain.is_empty():
		return {}
	var base: Dictionary = resolve_with_patch(candidates, patch_candidates, tag_chain[0])
	if base.is_empty():
		return {}
	for i: int in range(1, tag_chain.size()):
		var lower: Dictionary = resolve_with_patch(candidates, patch_candidates, tag_chain[i])
		if lower.is_empty() or is_same_level(base, lower):
			continue
		return {"base": base, "merged": lower, "tags": tag_chain[i]}
	return {}




static func resolve_with_patch(candidates: Array[Dictionary], patch_candidates: Array[Dictionary], 
		tags: Dictionary) -> Dictionary:
	var base: Dictionary = pick(candidates, tags)
	if base.is_empty():
		return {}
	var patch: Dictionary = pick(patch_candidates, tags) if not patch_candidates.is_empty() else {}
	return base if patch.is_empty() else ContentLevelExperimentResolver.merge_entry(base, patch)




static func is_same_level(a: Dictionary, b: Dictionary) -> bool:
	if a.has("initialLayout") or b.has("initialLayout"):
		return str(a.get("initialLayout", "")) == str(b.get("initialLayout", ""))
	return String(a.get("levelUniqueId", "")) == String(b.get("levelUniqueId", ""))



static func _match(raw_tags: String, user_tags: Dictionary) -> Dictionary:
	var parts: PackedStringArray = raw_tags.split(":", true, 1)
	if parts.size() != 2:
		return {}
	var key: String = parts[0]
	if not user_tags.has(key):
		return {}
	var allowed: PackedStringArray = parts[1].split(",", false)
	var value: String = String(user_tags[key])
	return {"key": key, "value": value} if allowed.has(value) else {}
