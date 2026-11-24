class_name JuiceLevelModel extends LevelModel












var juice: JuiceLevel = null


var color_slots: PackedInt32Array = PackedInt32Array()


var special_theme_skin_id: String = ""

var coin_bonus_rule: Dictionary = {}

var rank_collectible_rule: Dictionary = {}







var raw: Dictionary = {}


var used_fallback: bool = false


func rank_collectible_candidates(excluded_type: int = -1) -> Array[int]:
	var result: Array[int] = []
	if juice == null:
		return result
	var totals: Dictionary = {}
	for column: Array in juice.board_cols:
		for token: int in column:
			var actual: int = JuiceLevel.true_type(token)
			totals[actual] = int(totals.get(actual, 0)) + 1
	for entry: Dictionary in juice.incoming:
		for token: int in entry["beads"]:
			var actual: int = JuiceLevel.true_type(token)
			totals[actual] = int(totals.get(actual, 0)) + 1
	for i: int in juice.jar_seq.size():
		var type_id: int = juice.jar_seq[i]
		if type_id == excluded_type or juice.is_sunlight_type(type_id) or juice.jar_seq.count(type_id) != 1:
			continue
		if int(totals.get(type_id, 0)) == juice.cup_caps[i]:
			result.append(type_id)
	return result






func is_fallback_content() -> bool:
	return raw.has("level_unique_id")


func duplicate_model() -> LevelModel:
	var d: = JuiceLevelModel.new()
	_copy_meta_into(d)
	d.raw = raw.duplicate(true)
	d.used_fallback = used_fallback
	d.color_slots = color_slots.duplicate()
	d.special_theme_skin_id = special_theme_skin_id
	d.coin_bonus_rule = coin_bonus_rule.duplicate(true)
	d.rank_collectible_rule = rank_collectible_rule.duplicate(true)


	d.juice = JuiceLevel.from_dict(d.raw) if not d.raw.is_empty() else null
	return d


func to_dict() -> Dictionary:
	var d: = super ()
	d["raw"] = raw
	d["color_slots"] = Array(color_slots)
	d["special_theme_skin_id"] = special_theme_skin_id
	d["coin_bonus_rule"] = coin_bonus_rule.duplicate(true)
	d["rank_collectible_rule"] = rank_collectible_rule.duplicate(true)
	return d


func from_dict(d: Dictionary) -> void :
	super (d)
	var r: Variant = d.get("raw", {})
	raw = (r as Dictionary) if r is Dictionary else {}
	if is_special_challenge():
		raw["id"] = level_id
	juice = JuiceLevel.from_dict(raw) if not raw.is_empty() else null
	color_slots.clear()
	for slot: Variant in d.get("color_slots", []):
		color_slots.append(int(slot))
	special_theme_skin_id = String(d.get("special_theme_skin_id", ""))
	coin_bonus_rule = (d.get("coin_bonus_rule", {}) as Dictionary).duplicate(true)
	rank_collectible_rule = (d.get("rank_collectible_rule", {}) as Dictionary).duplicate(true)




func level_info() -> String:
	if juice == null:
		return ""
	var parts: PackedStringArray = []
	for i in juice.board_cols.size():
		var col: Array[int] = juice.board_cols[i]
		var jar: int = juice.board_jars[i]
		parts.append("%s:%s" % ["W" if jar < 0 else str(jar), ".".join(col.map( func(v: int) -> String: return str(v)))])
	return "%s|%s" % [";".join(parts), ".".join(juice.jar_seq.map( func(v: int) -> String: return str(v)))]
