class_name JuiceEndlessGenerator
extends RefCounted

const SETTINGS = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_settings.gd")
const SESSION = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_session.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")



static func next_stream(data: Dictionary, opts: Dictionary) -> Dictionary:
	var cancel: Semaphore = opts.get("cancel")
	if cancel != null and cancel.try_wait():
		return {"ok": false, "reason": "cancelled"}
	var reference: JuiceEndlessSession
	if (data.get("reference", {}) as Dictionary).is_empty():
		reference = SESSION.new(int(data["seed"]))
		for mv: Dictionary in SETTINGS.opening_moves(reference.seed):
			if reference.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
				return {"ok": false, "reason": "invalid_opening"}
			if not reference.pending.is_empty():
				break
	else:
		reference = SESSION.from_snapshot(data["reference"])
	if reference.pending.size() != 1:
		return {"ok": false, "reason": "invalid_reference"}
	var proofs: Array = data.get("forecasts", [])
	var result: Dictionary = {}
	if not proofs.is_empty() and String(proofs[0]["snapshot_key"]) == SESSION.snapshot_key(reference.snapshot()):
		result = {"ok": true, "entries": proofs[0]["refill"], "proofs": proofs, 
			"elapsed_ms": 0, "cached": true, "score": float((proofs[0]["path"] as Array).size())}
	else:
		result = generate(reference.snapshot(), opts)
	if not bool(result.get("ok", false)):
		return result
	var entry: Dictionary = (result["entries"] as Array)[0]
	var path: Array = result["proofs"][0]["path"]
	if reference.apply_refill(result["entries"]).is_empty():
		return {"ok": false, "reason": "invalid_reference_refill"}
	if bool(result.get("cached", false)):
		result["score"] = float(path.size()) + 0.5 * SETTINGS.mixed_neighbors(reference.state)
	for mv: Dictionary in path:
		if reference.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
			return {"ok": false, "reason": "invalid_reference_path"}
	if reference.pending.size() != 1:
		return {"ok": false, "reason": "invalid_reference_progress"}
	if cancel != null and cancel.try_wait():
		return {"ok": false, "reason": "cancelled"}
	var sequence: int = int(data.get("sequence", 0))
	return {"ok": true, "entry": {"sequence": sequence, "jar": int(entry["jar"]), 
		"beads": (entry["beads"] as Array[int]).duplicate(), "reference_path": path.duplicate(true)}, 
		"stream": {"seed": int(data["seed"]), "sequence": sequence + 1, 
			"reference": reference.snapshot(), "forecasts": (result["proofs"] as Array).slice(1)}, 
		"elapsed_ms": int(result.get("elapsed_ms", 0)), "cached": bool(result.get("cached", false)), 
		"score": float(result["score"])}


static func _expired(clock: Dictionary) -> bool:
	var cancel: Semaphore = clock["cancel"]
	if cancel != null and cancel.try_wait():
		clock["cancelled"] = true
	var tick: int = int((clock["now"] as Callable).call())
	return bool(clock["cancelled"]) or tick >= int(clock["deadline"])\
	or (bool(clock.get("safe", false)) and tick >= int(clock["soft_deadline"]))


static func _search_now(clock: Dictionary) -> int:
	return int(clock["deadline"]) if _expired(clock) else int((clock["now"] as Callable).call())



static func generate(data: Dictionary, opts: Dictionary) -> Dictionary:
	var now: Callable = opts["now"]
	var started: int = int(now.call())
	var clock: Dictionary = {"now": now, "deadline": started + int(opts.get("budget_ms", SETTINGS.FIRST_BUDGET_MS)), 
		"cancel": opts.get("cancel"), "cancelled": false, "candidates": 0, 
		"safe": false, "soft_deadline": started + SETTINGS.search_ms(int(data["state"]["done"]))}
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(data["seed"]) ^ (int(data["state"]["done"]) * 1664525) ^ (int(opts.get("attempt", 0)) * 1013904223)

	var best: Dictionary = _select_candidate(data, rng, clock, SETTINGS.CANDIDATES - 12)
	if best.is_empty():

		best = _select_candidate(data, rng, clock, 12, SETTINGS.CANDIDATES - 12)
	if not best.is_empty():
		var proofs: Array[Dictionary] = [{"refill": best["entries"].duplicate(true), "path": best["proof"]["path"], 
			"snapshot_key": SESSION.snapshot_key(data)}]
		var future: Dictionary = best["proof"]["after"]
		for depth in range(1, SETTINGS.LOOKAHEAD):
			var next: Dictionary = _select_candidate(future, rng, clock, 6)
			if next.is_empty():
				break
			proofs.append({"refill": next["entries"].duplicate(true), "path": next["proof"]["path"], 
				"snapshot_key": SESSION.snapshot_key(future)})
			future = next["proof"]["after"]
		best.erase("proof")
		best["proofs"] = proofs
		best["depth"] = proofs.size()
	if bool(clock["cancelled"]):
		best = {}
	best["ok"] = not best.is_empty()
	best["reason"] = "cancelled" if bool(clock["cancelled"]) else ("verified" if bool(best["ok"]) else "no_verified_refill")
	best["elapsed_ms"] = maxi(0, int(now.call()) - started)
	best["candidates"] = int(clock["candidates"])
	best["snapshot_key"] = SESSION.snapshot_key(data)
	return best


static func _select_candidate(data: Dictionary, rng: RandomNumberGenerator, clock: Dictionary, count: int, first_index: int = 0) -> Dictionary:
	var best: Dictionary = {}
	for index in range(first_index, first_index + count):
		if _expired(clock) or int(clock["candidates"]) >= SETTINGS.CANDIDATES:
			break
		var entries: Array[Dictionary] = candidate(data, rng, index)
		clock["candidates"] = int(clock["candidates"]) + 1
		if entries.is_empty():
			continue
		var proof: Dictionary = prove(data, entries, clock)
		if proof.is_empty():
			continue
		var st: Dictionary = SESSION.check_refill(data, entries)["state"]
		var score: float = float((proof["path"] as Array).size()) + 0.5 * SETTINGS.mixed_neighbors(st)
		var done: int = int(st["done"])
		var colors: int = 0
		for flowers: int in SESSION.inventory(st)["flowers"] as Array[int]:
			if flowers > 0:
				colors += 1
		var distance: float = absf(score - SETTINGS.target_score(done))\
		+ float(maxi(0, SETTINGS.preferred_flower_colors(done) - colors)) * 3.0
		if best.is_empty() or distance < float(best["distance"]):
			best = {"entries": entries, "proof": proof, "score": score, "distance": distance}
		clock["safe"] = true
		if distance <= 1.0:
			break
	return best


static func candidate(data: Dictionary, rng: RandomNumberGenerator, index: int) -> Array[Dictionary]:
	var st: Dictionary = data["state"]
	var limit: int = SETTINGS.color_limit(int(st["done"]))
	var counts: Dictionary = SESSION.inventory(st)
	var pots: Array[int] = (counts["pots"] as Array[int]).duplicate()
	var flowers: Array[int] = counts["flowers"]
	var pending: Array = data["pending"]
	if pending.is_empty():
		return []
	var size: int = pending.size() * SETTINGS.CAPACITY
	var urgent: Array[int] = []
	for color: Variant in data["obligations"] as Dictionary:
		if int(data["obligations"][color]) <= int(st["done"]) + pending.size():
			urgent.append(int(color))
	urgent.sort_custom( func(a: int, b: int) -> bool:
		return int(data["obligations"][a]) < int(data["obligations"][b]) if data["obligations"][a] != data["obligations"][b] else a < b)

	var targets: Array[int] = []
	for color in limit:
		if pots[color] > 0 and maxi(0, SETTINGS.CAPACITY - flowers[color]) <= size - pending.size() * 2:
			targets.append(color)
	if urgent.size() < pending.size():
		for color in limit:
			if pots[color] == 0 and maxi(0, SETTINGS.CAPACITY - flowers[color]) <= size - pending.size() * 2:
				targets.append(color)
	if targets.is_empty():
		return []
	var target: int = targets[index % targets.size()]
	var cycle: int = int(index / targets.size())
	var assign_target: bool = pots[target] == 0 or cycle % 2 == 0
	var entries: Array[Dictionary] = []
	for dep: Dictionary in pending:
		var jar: int
		if not urgent.is_empty():
			jar = urgent.pop_front()
		elif assign_target:
			jar = target
			assign_target = false
		else:
			jar = rng.randi_range(0, limit - 1)
			if index % 3 == 0:
				var unused: Array[int] = []
				for color in limit:
					if pots[color] == 0 and flowers[color] == 0:
						unused.append(color)
				if not unused.is_empty():
					jar = unused[rng.randi_range(0, unused.size() - 1)]
		pots[jar] += 1
		entries.append({"col": int(dep["col"]), "jar": jar, "beads": [] as Array[int]})
	if pots[target] == 0:
		return []
	var pot_colors: int = 0
	for count: int in pots:
		if count > 0:
			pot_colors += 1
	if pot_colors < 4:
		return []
	var deficit: Array[int] = []
	var batch: Array[int] = []
	for color in limit:
		deficit.append(pots[color] * SETTINGS.CAPACITY - flowers[color])
		for n in maxi(0, deficit[color] - SETTINGS.CAPACITY):
			batch.append(color)
			deficit[color] -= 1
	var missing: int = maxi(0, SETTINGS.CAPACITY - flowers[target] - batch.count(target))
	for n in missing:
		batch.append(target)
		deficit[target] -= 1
	if batch.size() > size or batch.count(target) > pending.size() * 3:
		return []

	var bridges: Dictionary = {}
	for ci in SETTINGS.COLUMNS:
		var col: Array = st["cols"][ci]
		var room: int = int(st["caps"][ci]) - col.size()
		if not col.is_empty() and room > 0 and int(col[-1]) != target:
			var color: int = int(col[-1])
			bridges[color] = maxi(room, int(bridges.get(color, 0)))
	var bridge_colors: Array = bridges.keys()
	bridge_colors.sort_custom( func(a: int, b: int) -> bool:
		return int(bridges[a]) > int(bridges[b]) if bridges[a] != bridges[b] else a < b)
	while batch.size() < size:
		var distinct: Dictionary = {}
		for color: int in batch:
			distinct[color] = true
		var chosen: int = -1
		if cycle % 2 == 0 and distinct.size() < 3:
			for color: int in bridge_colors:
				if not distinct.has(color) and deficit[color] > - SETTINGS.CAPACITY:
					chosen = color
					break
		if chosen < 0:
			var weights: Array[int] = []
			var weight_sum: int = 0
			for color in limit:
				var weight: int = maxi(0, deficit[color] + SETTINGS.CAPACITY)
				if batch.count(color) >= pending.size() * 3 or (distinct.size() < 3 and distinct.has(color)):
					weight = 0
				weights.append(weight)
				weight_sum += weight
			if weight_sum == 0:
				return []
			var pick: int = rng.randi_range(1, weight_sum)
			for color in limit:
				pick -= weights[color]
				if pick <= 0:
					chosen = color
					break
		batch.append(chosen)
		deficit[chosen] -= 1
	var rows: Array[Array] = _split_batch(batch, target, entries.size())
	for i in entries.size():
		entries[i]["beads"] = _arrange(rows[i], target, cycle, rng)
		if not SETTINGS.normal_column(entries[i]["beads"]):
			return []
	var checked: Dictionary = SESSION.check_refill(data, entries)
	if checked.is_empty():
		return []
	var flower_colors: int = 0
	for count: int in SESSION.inventory(checked["state"])["flowers"] as Array[int]:
		if count > 0:
			flower_colors += 1
	if flower_colors < 5:
		return []
	return entries


static func _split_batch(batch: Array[int], target: int, count: int) -> Array[Array]:
	var rows: Array[Array] = []
	for i in count:
		rows.append([] as Array[int])
	for i in batch.count(target):
		rows[i % count].append(target)
	for color: int in batch:
		if color == target:
			continue
		var dst: int = -1
		var score: int = 1000
		for i in count:
			if rows[i].size() >= SETTINGS.CAPACITY or rows[i].count(color) >= 3:
				continue
			var value: int = rows[i].size() * 10 + (3 if rows[i].has(color) else 0)
			if value < score:
				dst = i
				score = value
		if dst < 0:
			return rows
		rows[dst].append(color)
	return rows


static func _arrange(beads: Array, target: int, cycle: int, rng: RandomNumberGenerator) -> Array[int]:
	if beads.size() != SETTINGS.CAPACITY:
		return []
	var counts: Dictionary = {}
	for color: int in beads:
		counts[color] = int(counts.get(color, 0)) + 1
	if counts.size() < 3:
		return []
	if beads.count(target) == 3 and cycle == 0:
		var others: Array[int] = []
		for color: int in beads:
			if color != target:
				others.append(color)
		return [target, target, others[0], target, others[1]]
	var ordered: Array[int] = []
	while ordered.size() < beads.size():
		var chosen: int = -1
		var largest: int = 0
		for color in SETTINGS.MAX_COLORS:
			var left: int = int(counts.get(color, 0))
			if not ordered.is_empty() and color == ordered[-1]:
				continue
			if left > largest or (left == largest and left > 0 and rng.randi_range(0, 1) == 0):
				chosen = color
				largest = left
		if chosen < 0:
			return []
		ordered.append(chosen)
		counts[chosen] = largest - 1
	return ordered



static func prove(data: Dictionary, entries: Array, clock: Dictionary) -> Dictionary:
	var session: JuiceEndlessSession = SESSION.from_snapshot(data)
	if session.apply_refill(entries).is_empty():
		return {}
	var counts: Dictionary = SESSION.inventory(session.state)
	var targets: Array[int] = []
	for ci in range(1, SETTINGS.COLUMNS):
		var color: int = int(session.state["jars"][ci])
		if color >= 0 and int(counts["flowers"][color]) >= SETTINGS.CAPACITY:
			targets.append(ci)
	targets.sort_custom( func(a: int, b: int) -> bool:
		return S.hint_lower_bound(session.state, a, session.level) < S.hint_lower_bound(session.state, b, session.level))
	for ci in targets:
		if _expired(clock):
			break
		var path: Variant = S.solve_group(session.state, session.level, ci, 
			{"node_cap": 1500, "max_depth": 40, "deadline": clock["deadline"], 
			"clock_every": 16, "now": _search_now.bind(clock)})
		if path == null or (path as Array).is_empty():
			continue
		var replay: JuiceEndlessSession = SESSION.from_snapshot(session.snapshot())
		var actual: Array[Dictionary] = []
		for mv: Dictionary in path as Array:
			if _expired(clock) or replay.apply_move(int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
				break
			actual.append(mv.duplicate())
			if not replay.pending.is_empty():
				return {"path": actual, "after": replay.snapshot()}
	return {}
