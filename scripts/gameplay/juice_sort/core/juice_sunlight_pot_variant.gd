class_name JuiceSunlightPotVariant
extends RefCounted

const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")
const LEVELS: = [41, 42, 43, 45, 47, 49, 53, 60, 62, 69, 75, 80, 84, 87, 94, 98, 
	101, 109, 113, 117, 121, 126, 135, 137, 142, 146, 155, 159, 161, 167, 174, 178, 
	183, 186, 195, 200]


static func scheduled(level: int) -> bool:
	return LEVELS.has(level)


static func content_hash(raw: Dictionary) -> String:
	var content: Dictionary = raw.duplicate(true)
	for key: String in ["id", "note", "seed", "sunlightPotSource"]:
		content.erase(key)
	return JSON.stringify(content, "", true).md5_text()


static func apply_recipe(raw: Dictionary, recipe: Dictionary) -> Dictionary:
	if recipe.get("status", "") != "ready" or content_hash(raw) != recipe.get("source_hash", ""):
		return {}
	var converted: Dictionary = _convert(raw, recipe)
	if converted.is_empty():
		return {}
	var level: JuiceLevel = JuiceLevel.from_dict(converted)
	if not level.validate().is_empty() or content_hash(converted) != recipe.get("converted_hash", ""):
		return {}
	converted["sunlightPotSource"] = {
		"source_uid": recipe["source_uid"], "source_hash": recipe["source_hash"], 
		"converted_hash": recipe["converted_hash"], "source_level": recipe["level"], 
		"target": recipe["target"], "sun_type": recipe["sun_type"], "group": "10_5", 
	}
	return converted


static func prepare_recipe(raw: Dictionary, node_budget: int = 200000) -> Dictionary:
	var level: JuiceLevel = JuiceLevel.from_dict(raw)
	if not level.validate().is_empty() or level.has_sunlight():
		return {"status": "skipped", "reason": "invalid_or_existing_sunlight"}
	var order: Array[int] = _initial_order(raw)
	var candidates: Array[int] = []
	for column in level.columns:
		if level.board_jars[column] >= 0 and (level.board_locks[column] as Dictionary).is_empty():
			candidates.append(column)
	var per_search: int = maxi(1, node_budget / maxi(1, candidates.size() * 2))
	for column: int in candidates:
		var state: Dictionary = R.make_state(level)
		var flags: Array[bool] = []
		for index in level.columns:
			flags.append(level.board_jars[index] >= 0 and index != column)
		state["frozen_pots"] = flags
		var route: Variant = _route(state, level, column, per_search)
		if not (route is Array):
			continue
		var origins: Array = []
		for index in level.columns:
			var cells: Array = []
			for position in (level.board_cols[index] as Array).size():
				cells.append([order[index], position])
			origins.append(cells)
		var probe: Dictionary = R.clone_state(state)
		for move: Dictionary in route:
			var source: int = int(move["src"])
			var start: int = int(move["j"])
			var target: int = int(move["dst"])
			var carried: Array = (origins[source] as Array).slice(start)
			(origins[source] as Array).resize(start)
			(origins[target] as Array).append_array(carried)
			R.apply_move(probe, level, source, start, target, true)
		var color: int = level.board_jars[column]
		var sun_type: int = _sun_type(level, color, level.column_caps[column])
		if sun_type < 0:
			continue
		var recipe: Dictionary = {"status": "ready", "source_hash": content_hash(raw), 
			"target": order[column], "original_type": color, "sun_type": sun_type, 
			"cells": origins[column], "node_cap": node_budget, "max_depth": 60}
		var converted: Dictionary = _convert(raw, recipe)
		if converted.is_empty():
			continue
		var transformed: JuiceLevel = JuiceLevel.from_dict(converted)
		if not transformed.validate().is_empty():
			continue
		var start_state: Dictionary = R.make_state(transformed)
		var proof: Variant = _route(start_state, transformed, column, per_search)
		if not (proof is Array):
			continue
		var verified: Dictionary = R.clone_state(start_state)
		var first: Dictionary = {}
		var moves: Array = []
		for move: Dictionary in proof:
			var record: Dictionary = R.apply_move(verified, transformed, int(move["src"]), int(move["j"]), int(move["dst"]))
			if record.is_empty():
				break
			moves.append(move)
			if not (record["deposits"] as Array).is_empty():
				first = record["deposits"][0]
				break
		if not first.is_empty() and bool(first["sun"]) and int(first["col"]) == column:
			recipe["proof"] = moves
			recipe["converted_hash"] = content_hash(converted)
			return recipe
	return {"status": "skipped", "reason": "no_verified_first_sun_or_type_slot", "node_cap": node_budget}


static func _route(state: Dictionary, level: JuiceLevel, column: int, node_cap: int) -> Variant:
	var route: Variant = S.solve_group(state, level, column, {"node_cap": node_cap, "max_depth": 60})
	if route is Array and not route.is_empty():
		return route
	if R.deposit_ready(state, column) > 0:
		for move: Dictionary in R.useful_moves(state):
			var probe: Dictionary = R.clone_state(state)
			var record: Dictionary = R.apply_move(probe, level, int(move["src"]), int(move["j"]), int(move["dst"]))
			if not record.is_empty() and not (record["deposits"] as Array).is_empty()\
			and int(record["deposits"][0]["col"]) == column:
				return [move]
	return null


static func _sun_type(level: JuiceLevel, color: int, capacity: int) -> int:
	var counts: Array[int] = level.future_tally(0).duplicate()
	for column: Array in level.board_cols:
		for fruit: int in column:
			counts[JuiceLevel.true_type(fruit)] += 1
	if counts[color] == capacity:
		return color
	for type_id in JuiceLevel.MAX_TYPES:
		if type_id >= counts.size() or counts[type_id] == 0:
			return type_id
	return -1


static func _initial_order(raw: Dictionary) -> Array[int]:
	var parks: Array[int] = []
	var jars: Array[int] = []
	for index in (raw["initial"] as Array).size():
		var entry: Variant = raw["initial"][index]
		var column: String = String(entry["column"] if entry is Dictionary else entry)
		if column.begins_with("-|"):
			parks.append(index)
		else:
			jars.append(index)
	parks.append_array(jars)
	return parks


static func _convert(raw: Dictionary, recipe: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	var initial: Array = result.get("initial", [])
	var target: int = int(recipe.get("target", -1))
	var sun_type: int = int(recipe.get("sun_type", -1))
	if target < 0 or target >= initial.size() or sun_type < 0 or sun_type >= JuiceLevel.MAX_TYPES:
		return {}
	var decoded: Array = []
	for entry: Variant in initial:
		var parsed: Dictionary = JuiceLevel._decode_col(entry, "sunlight pot")
		if parsed["err"] != "":
			return {}
		decoded.append(parsed)
	var seen: Dictionary = {}
	for cell: Array in recipe.get("cells", []):
		if cell.size() != 2:
			return {}
		var column: int = int(cell[0])
		var position: int = int(cell[1])
		if column < 0 or column >= decoded.size() or position < 0\
		or position >= (decoded[column]["beads"] as Array).size() or seen.has(str(cell)):
			return {}
		var before: int = decoded[column]["beads"][position]
		if JuiceLevel.true_type(before) != int(recipe["original_type"]) or JuiceLevel.is_frozen(before):
			return {}
		seen[str(cell)] = true
		decoded[column]["beads"][position] = JuiceLevel.hide_type(sun_type) if JuiceLevel.is_hidden(before) else sun_type
	decoded[target]["jar"] = sun_type
	var frozen: Array = []
	for index in decoded.size():
		var column: String = JuiceLevel.encode_col(int(decoded[index]["jar"]), decoded[index]["beads"] as Array[int])
		if initial[index] is Dictionary:
			initial[index]["column"] = column
		else:
			initial[index] = column
		if index != target and int(decoded[index]["jar"]) >= 0:
			frozen.append(index)
	result["sunlight"] = {"typeId": sun_type}
	result["frozenPots"] = frozen
	return result
