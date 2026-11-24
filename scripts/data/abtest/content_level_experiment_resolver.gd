class_name ContentLevelExperimentResolver
extends RefCounted
































const KEY_PREFIX: String = "content_sg||level||"


const VALUE_CONTROL: String = "default"


var _ab_gateway: Object


func _init(ab_gateway: Object) -> void :
	_ab_gateway = ab_gateway

	for method: String in ["is_ab_init_done", "get_all_ab_experiments", "get_ab_string", "dye_ab"]:
		assert (ab_gateway != null and ab_gateway.has_method(method), 
			"ContentLevelExperimentResolver: AB gateway 缺少 %s()" % method)






func all_keys() -> Array:
	if _ab_gateway == null or not bool(_ab_gateway.call("is_ab_init_done")):
		return []
	var experiments: Dictionary = _ab_gateway.call("get_all_ab_experiments") as Dictionary
	return experiments.keys()


func value_of(key: String) -> String:
	if _ab_gateway == null:
		return ""
	return String(_ab_gateway.call("get_ab_string", key, "")).strip_edges()





func dye_for_chapter(chapter: int) -> void :
	if chapter <= 0:
		return
	for key: String in match_keys_for_chapter(all_keys(), chapter):
		_ab_gateway.call("dye_ab", key)







static func needs_fetch(value: String) -> bool:
	var v: String = value.strip_edges().to_lower()
	return not v.is_empty() and v != VALUE_CONTROL






static func parse_key(key: String) -> Dictionary:
	var fail: Dictionary = {"ok": false, "start": 0, "end": 0}
	if not key.begins_with(KEY_PREFIX):
		return fail
	var suffix: String = key.substr(KEY_PREFIX.length())

	var parts: PackedStringArray = suffix.split("_")
	if parts.size() != 2:
		return fail
	if not (parts[0].is_valid_int() and parts[1].is_valid_int()):
		return fail
	var start: int = int(parts[0])
	var end: int = int(parts[1])
	if start <= 0 or end <= 0 or start > end:
		return fail
	return {"ok": true, "start": start, "end": end}







static func collect_keys(all_ab_keys: Array) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for k: Variant in all_ab_keys:
		var key: String = str(k)
		var r: Dictionary = parse_key(key)
		if not bool(r.ok):
			continue
		hits.append({"key": key, "start": int(r.start), "end": int(r.end)})
	hits.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.start) != int(b.start):
			return int(a.start) < int(b.start)
		return str(a.key) < str(b.key))
	return hits











static func match_keys_overlapping(all_ab_keys: Array, start: int, end: int) -> Array[String]:
	var out: Array[String] = []
	for h: Dictionary in collect_keys(all_ab_keys):

		if int(h.start) <= end and start <= int(h.end):
			out.append(str(h.key))
	return out



static func match_keys_for_chapter(all_ab_keys: Array, chapter: int) -> Array[String]:
	return match_keys_overlapping(all_ab_keys, chapter, chapter)
















static func index_patches(raw_levels: Array, start: int, end: int) -> Dictionary:
	var out: Dictionary = {}
	var dropped_bad: int = 0
	for e: Variant in raw_levels:
		if not (e is Dictionary):
			dropped_bad += 1
			continue
		var raw: Dictionary = e
		var chapter_index: int = int(raw.get("chapterIndex", 0))
		var level_index: int = int(raw.get("levelIndex", 0))
		if chapter_index <= 0 or level_index <= 0 or level_index > LevelIndex.CHAPTER_SIZE:
			dropped_bad += 1
			continue
		if chapter_index < start or chapter_index > end:
			continue
		var level_id: int = LevelIndex.level_id_of(chapter_index, level_index)
		var bucket: Array[Dictionary] = out.get(level_id, [] as Array[Dictionary])
		bucket.append(raw)
		out[level_id] = bucket
	if dropped_bad > 0:

		SortLogger.warn("[ContentLevelExperiment] 策略池丢弃 %d 条非法条目（结构错误或 levelIndex 越界）"
			%dropped_bad)
	return out







static func merge_entry(base: Dictionary, patch: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate()
	for k: Variant in patch.keys():
		out[k] = patch[k]
	return out
