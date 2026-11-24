class_name JuiceSolver
extends RefCounted




























const HINT_PLANNER = preload("res://scripts/gameplay/juice_sort/core/juice_hint_planner.gd")
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")


enum Reachability{UNKNOWN, WINNABLE, UNWINNABLE}

enum DeathAttribution{UNKNOWN, LAST_MOVE, EARLIER}



const LB_IMPOSSIBLE: = 99



const BEAM_FROM_DEPTH: = 3
const BEAM_WIDTH: = 7


const CLOCK_EVERY: = 256


const ASTAR_CLOCK_EVERY: = 16







const FORBID_PENALTY: = 1000.0




const SHUFFLE_PENALTY: = 3

const SHUFFLE_COST_ROOM: = 2



static func _hint_type(fruit_type: int) -> int:
	return JuiceLevel.true_type(fruit_type)


static func _has_sunlight_state(st: Dictionary, level: JuiceLevel = null) -> bool:
	if level != null and level.has_sunlight():
		return true
	for col: Array in (st["cols"] as Array):
		for fruit_type: int in col:
			if JuiceLevel.is_frozen(fruit_type):
				return true
	return false


static func _has_mechanics(st: Dictionary, level: JuiceLevel = null) -> bool:
	if level != null and level.has_sunlight():
		return true
	for col: Array in (st["cols"] as Array):
		for fruit_type: int in col:
			if JuiceLevel.is_hidden(fruit_type) or JuiceLevel.is_frozen(fruit_type):
				return true
	for lock: Dictionary in st.get("locks", []) as Array:
		if not lock.is_empty():
			return true
	return false












static func is_shuffle_step(before: Dictionary, mv: Dictionary, after: Dictionary) -> bool:
	if int(mv["j"]) != 0:
		return false
	var dst: int = int(mv["dst"])
	if not ((before["cols"] as Array)[dst] as Array).is_empty():
		return false
	return R.deposit_ready(after, dst) == 0










static func _prune_shuffles(st: Dictionary, level: JuiceLevel, path: Array, goal: String, 
		verify: Callable = Callable()) -> Dictionary:
	var real: bool = goal == "win"
	var cur: Array = path
	var k: int = 0
	while k < cur.size():
		var before: Dictionary = R.clone_state(st)
		for i in k:
			var pm: Dictionary = cur[i]
			R.apply_move(before, level, int(pm["src"]), int(pm["j"]), int(pm["dst"]), not real)
		var mv: Dictionary = cur[k]
		var after: Dictionary = R.clone_state(before)
		R.apply_move(after, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		if not is_shuffle_step(before, mv, after):
			k += 1
			continue
		var a: int = int(mv["src"])
		var b: int = int(mv["dst"])
		var cand: Array = cur.slice(0, k)
		for i in range(k + 1, cur.size()):
			var om: Dictionary = (cur[i] as Dictionary).duplicate()
			for f: String in ["src", "dst"]:
				var c: int = int(om[f])
				om[f] = b if c == a else (a if c == b else c)
			cand.append(om)
		var end: Dictionary = {} if cand.is_empty() else _replay(st, level, cand, real)
		if not end.is_empty() and _goal_met(end, level, goal)\
		and ( not verify.is_valid() or bool(verify.call(end))):
			cur = cand
		else:
			k += 1
	var end_st: Dictionary = _replay(st, level, cur, real)
	return {"path": cur, "col": -1 if real else _ready_col(end_st)}



static func _replay(st: Dictionary, level: JuiceLevel, path: Array, real: bool, 
		opts: Dictionary = {}) -> Dictionary:
	var x: Dictionary = R.clone_state(st)
	for mv: Dictionary in path:
		if _hint_time_expired(opts):
			return {}
		if R.apply_move(x, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), not real).is_empty():
			return {}
	return x


static func _goal_met(end: Dictionary, level: JuiceLevel, goal: String) -> bool:
	return R.is_win(end, level) if goal == "win" else _ready_col(end) >= 0


static func _ready_col(st: Dictionary) -> int:
	if st.is_empty():
		return -1
	for ci in (st["cols"] as Array).size():
		if R.deposit_ready(st, ci) > 0:
			return ci
	return -1





static func _is_mono(st: Dictionary, ci: int) -> bool:
	if int((st["jars"] as Array[int])[ci]) < 0:
		return false
	var col: Array[int] = (st["cols"] as Array)[ci]
	if col.is_empty():
		return true
	var t: int = _hint_type(col[0])
	for i in range(1, col.size()):
		if _hint_type(col[i]) != t:
			return false
	return true




static func move_score(st: Dictionary, mv: Dictionary) -> float:
	if R.is_root_swap(st, int(mv["src"]), int(mv["j"]), int(mv["dst"])):
		var after: Dictionary = _root_swap_preview(st, mv)
		var score: float = 0.0
		for ci: int in [int(mv["src"]), int(mv["dst"])]:
			score += _pot_prefix_score(after, ci) - _pot_prefix_score(st, ci)
			score += 40.0 * float(int(R.deposit_ready(after, ci) > 0) - int(R.deposit_ready(st, ci) > 0))
		return score
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var src: int = int(mv["src"])
	var dst: int = int(mv["dst"])
	var j: int = int(mv["j"])
	var sc: Array[int] = cols[src]
	var dc: Array[int] = cols[dst]

	var blk_len: int = sc.size() - j
	var head: int = _hint_type(sc[j])
	var mono: bool = true
	var frozen_block: bool = false
	for fruit_type: int in dc:
		if JuiceLevel.is_frozen(fruit_type):
			frozen_block = true
	for index in range(j, sc.size()):
		if JuiceLevel.is_frozen(sc[index]):
			frozen_block = true
	for i in range(j + 1, sc.size()):
		if _hint_type(sc[i]) != head:
			mono = false
			break

	var s: float = 0.0
	var dt: int = int((st["jars"] as Array[int])[dst])
	if dt >= 0:
		if mono and head == dt:

			if dc.is_empty() or _is_mono(st, dst):
				var after: int = dc.size() + blk_len
				s += 14.0
				if after == caps[dst] and not frozen_block:
					s += 40.0
				else:
					s += minf(10.0, blk_len * 2.0)
			else:
				s += 2.0
		else:
			s -= 4.0
	var stt: int = int((st["jars"] as Array[int])[src])
	if stt >= 0:


		var pre: int = 0
		while pre < sc.size() and _hint_type(sc[pre]) == stt:
			pre += 1
		s += 6.0 if j >= pre else -8.0
		var junk: bool = true
		for i in range(j, sc.size()):
			if _hint_type(sc[i]) == stt:
				junk = false
				break
		if junk:
			s += 5.0

			if j == 0:
				s += 12.0
	if dc.is_empty():
		s -= 2.0
	return s + minf(3.0, blk_len * 0.5)



static func _root_swap_preview(st: Dictionary, mv: Dictionary) -> Dictionary:
	var after: Dictionary = st.duplicate()
	var cols: Array = (st["cols"] as Array).duplicate()
	var src: int = int(mv["src"])
	var dst: int = int(mv["dst"])
	var sc: Array[int] = cols[src]
	cols[src] = cols[dst]
	cols[dst] = sc
	after["cols"] = cols
	return after


static func _pot_prefix_score(st: Dictionary, ci: int) -> float:
	var target: int = int(st["jars"][ci])
	if target < 0:
		return 0.0
	var col: Array[int] = st["cols"][ci]
	var pre: int = 0
	while pre < col.size() and _hint_type(col[pre]) == target:
		pre += 1
	return float(pre * 4 - (col.size() - pre) * 2)



static func group_score(st: Dictionary, mv: Dictionary, ci: int) -> float:
	var target: int = int((st["jars"] as Array[int])[ci])
	var s: float = move_score(st, mv) * 0.35
	if R.is_root_swap(st, int(mv["src"]), int(mv["j"]), int(mv["dst"])):
		if ci == int(mv["src"]) or ci == int(mv["dst"]):
			var after: Dictionary = _root_swap_preview(st, mv)
			s += (_pot_prefix_score(after, ci) - _pot_prefix_score(st, ci)) * 3.0
			if R.deposit_ready(after, ci) > 0:
				s += 30.0
		return s
	var cols: Array = st["cols"]
	var j: int = int(mv["j"])
	if int(mv["dst"]) == ci:

		var sc: Array[int] = cols[int(mv["src"])]
		var ok: bool = true
		for i in range(j, sc.size()):
			if _hint_type(sc[i]) != target:
				ok = false
				break
		s += (30.0 + (sc.size() - j) * 4.0) if ok else -30.0
	elif int(mv["src"]) == ci:

		var c: Array[int] = cols[ci]
		var junk: int = 0
		for i in range(j, c.size()):
			if _hint_type(c[i]) != target:
				junk += 1
		s += (16.0 + junk * 3.0) if junk > 0 else -14.0
		if j == 0 and junk > 0:
			s += 10.0
	return s







static func is_forbidden(st: Dictionary, mv: Dictionary, forbid: Dictionary) -> bool:
	var root_swap: bool = R.is_root_swap(st, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
	if root_swap != bool(forbid.get("root_swapped", false)):
		return false
	if root_swap:
		var src: int = int(mv["src"])
		var dst: int = int(mv["dst"])
		var a: int = int(forbid.get("src", -1))
		var b: int = int(forbid.get("dst", -1))
		return (src == a and dst == b) or (src == b and dst == a)
	if int(mv["src"]) != int(forbid.get("src", -1))\
	or int(mv["dst"]) != int(forbid.get("dst", -1)):
		return false
	var sc: Array[int] = (st["cols"] as Array)[int(mv["src"])]
	return sc.size() - int(mv["j"]) == int(forbid.get("k", -1))
























static func hint_lower_bound(st: Dictionary, ci: int, level: JuiceLevel = null) -> int:

	if bool(st.get("allow_root_swapping", false)):
		return 0
	if _has_sunlight_state(st, level):
		return 0
	var target: int = int((st["jars"] as Array[int])[ci])
	if target < 0:
		return LB_IMPOSSIBLE
	var cols: Array = st["cols"]
	var col: Array[int] = cols[ci]
	var cap: int = int((st["caps"] as Array[int])[ci])
	var pre: int = 0
	while pre < col.size() and col[pre] == target:
		pre += 1
	var junk: int = 1 if pre < col.size() else 0
	var deficit: int = cap - pre
	if deficit <= 0:
		return junk

	var runs: Array[int] = []
	var gone: Array[bool] = st["gone"]
	for k in cols.size():
		if gone[k]:
			continue
		var c: Array[int] = cols[k]
		var i: int = pre if k == ci else 0
		while i < c.size():
			if _hint_type(c[i]) != target:
				i += 1
				continue
			var e: int = i
			while e < c.size() and _hint_type(c[e]) == target:
				e += 1
			runs.append(e - i)
			i = e
	runs.sort()
	runs.reverse()

	var need: int = deficit
	var moves: int = 0
	for r in runs:
		if need <= 0:
			break
		need -= r
		moves += 1
	return LB_IMPOSSIBLE if need > 0 else junk + moves




static func group_candidates(st: Dictionary, level: JuiceLevel) -> Array:
	var supply: Array[int] = []
	supply.resize(level.types)
	supply.fill(0)
	var frozen_count: int = 0
	for col_index in (st["cols"] as Array).size():
		for fruit_type: int in ((st["cols"] as Array)[col_index] as Array[int]):
			if JuiceLevel.is_frozen(fruit_type):
				frozen_count += 1
	for source_ci in (st["cols"] as Array).size():
		if R.is_locked(st, source_ci):
			continue
		for fruit_type: int in ((st["cols"] as Array)[source_ci] as Array[int]):
			if JuiceLevel.is_frozen(fruit_type):
				continue
			var actual: int = JuiceLevel.true_type(fruit_type)
			if actual >= 0 and actual < level.types:
				supply[actual] += 1
	var out: Array = []
	var jars: Array[int] = st["jars"]
	var caps: Array[int] = st["caps"]
	var cols: Array = st["cols"]
	for ci in cols.size():
		if R.is_locked(st, ci) or R.is_frozen_pot(st, ci):
			continue
		var t: int = jars[ci]
		if t < 0 or supply[t] < caps[ci]:
			continue
		var col: Array[int] = cols[ci]
		var pre: int = 0
		while pre < col.size() and col[pre] == t:
			pre += 1
		var score: int = pre * 3 + (supply[t] - caps[ci])
		if level.has_sunlight() and frozen_count > 0 and t == level.sunlight_type:
			score += 100
		out.append({"col": ci, "score": score})
	out.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["score"]) > int(b["score"]))
	return out

















static func _sort_by_group_score(st: Dictionary, moves: Array, ci: int, 
		forbid: Dictionary = {}) -> void :
	var m: int = moves.size()
	if m < 2:
		return
	var keyed: Array = []
	keyed.resize(m)
	for i in m:
		var sc: float = group_score(st, moves[i], ci)
		if not forbid.is_empty() and is_forbidden(st, moves[i], forbid):
			sc -= FORBID_PENALTY
		keyed[i] = [ - sc, i]
	keyed.sort()
	var sorted_moves: Array = []
	sorted_moves.resize(m)
	for i in m:
		sorted_moves[i] = moves[int((keyed[i] as Array)[1])]
	for i in m:
		moves[i] = sorted_moves[i]






static func solve_group(st: Dictionary, level: JuiceLevel, ci: int, opts: Dictionary = {}) -> Variant:
	if int((st["jars"] as Array[int])[ci]) < 0 or R.is_locked(st, ci):
		return null
	var cap0: int = int((st["caps"] as Array[int])[ci])
	var n: int = (st["cols"] as Array).size()


	var auto_depth: int = clampi(cap0 * 5 + 14, 30, 110)
	@warning_ignore("integer_division")
	var auto_nodes: int = maxi(3000, 30000 / maxi(1, (n * cap0) / 50))
	var ctx: Dictionary = {
		"level": level, 
		"col": ci, 
		"node_cap": int(opts.get("node_cap", auto_nodes)), 
		"max_depth": int(opts.get("max_depth", auto_depth)), 
		"deadline": int(opts.get("deadline", 0)), 
		"now": opts.get("now", Callable()), 
		"clock_every": maxi(1, int(opts.get("clock_every", CLOCK_EVERY))), 
		"nodes": 0, 
		"seen": {}, 
		"forbid": opts.get("forbid", {}), 
	}
	return _dfs(R.clone_state(st), 0, [], ctx)






static func _dfs(st: Dictionary, depth: int, path: Array, ctx: Dictionary) -> Variant:
	var ci: int = ctx["col"]
	if R.deposit_ready(st, ci) > 0:
		return path
	if depth >= int(ctx["max_depth"]):
		return null
	ctx["nodes"] = int(ctx["nodes"]) + 1
	var nodes: int = ctx["nodes"]
	if nodes > int(ctx["node_cap"]):
		return null
	var deadline: int = int(ctx["deadline"])
	if deadline > 0 and nodes % int(ctx["clock_every"]) == 0:
		var now: Callable = ctx["now"]
		if now.is_valid() and int(now.call()) >= deadline:

			ctx["nodes"] = int(ctx["node_cap"]) + 1
			return null

	var key: String = R.state_key(st)
	var seen: Dictionary = ctx["seen"]

	if seen.has(key) and int(seen[key]) <= depth:
		return null
	seen[key] = depth

	var moves: Array = R.useful_moves(st)
	var forbid: Dictionary = ctx["forbid"] if depth == 0 else {}
	_sort_by_group_score(st, moves, ci, forbid)
	var width: int = moves.size() if depth < BEAM_FROM_DEPTH else mini(moves.size(), BEAM_WIDTH)

	var level: JuiceLevel = ctx["level"]
	for i in width:
		var mv: Dictionary = moves[i]
		var nx: Dictionary = R.clone_state(st)

		if R.apply_move(nx, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true).is_empty():
			continue
		var r: Variant = _dfs(nx, depth + 1, path + [mv], ctx)
		if r != null:
			return r
		if int(ctx["nodes"]) > int(ctx["node_cap"]):
			return null
	return null




























static func _astar_group(st: Dictionary, level: JuiceLevel, targets: Array[int], 
		opts: Dictionary) -> Dictionary:
	var node_cap: int = int(opts.get("node_cap", 6000))
	var max_depth: int = int(opts.get("max_depth", 20))
	var deadline: int = int(opts.get("deadline", 0))
	var now: Callable = opts.get("now", Callable())
	var clock_every: int = maxi(1, int(opts.get("clock_every", ASTAR_CLOCK_EVERY)))
	var verify: Callable = opts.get("verify", Callable())
	var forbid: Dictionary = opts.get("forbid", {})
	var stats: Dictionary = opts.get("stats", {})
	stats.merge({"expanded": 0, "states": 1, "candidates": 0, "stop": "exhausted"}, true)

	var h0: int = _min_lower_bound(st, targets, level)
	if h0 > max_depth:
		stats["stop"] = "depth_limit"
		return {}
	var key0: String = R.state_key(st)
	var states: Array[Dictionary] = [R.clone_state(st)]
	var keys: PackedStringArray = PackedStringArray([key0])
	var parents: PackedInt32Array = PackedInt32Array([-1])
	var gs: PackedInt32Array = PackedInt32Array([0])

	var steps: PackedInt32Array = PackedInt32Array([0])
	var moves_in: Array[Dictionary] = [{}]
	var best_g: Dictionary = {key0: 0}
	var cost_cap: int = max_depth + SHUFFLE_PENALTY * SHUFFLE_COST_ROOM


	var buckets: Array[Array] = []
	buckets.resize(cost_cap + 1)
	for b in buckets.size():
		buckets[b] = []
	buckets[h0].append(0)

	var f: int = h0
	var expanded: int = 0
	while f <= cost_cap:
		var bucket: Array = buckets[f]
		if bucket.is_empty():
			f += 1
			continue
		var idx: int = bucket.pop_back()
		var g: int = gs[idx]
		if int(best_g[keys[idx]]) < g:
			continue
		var cur: Dictionary = states[idx]
		for ci: int in targets:
			if R.deposit_ready(cur, ci) > 0:
				var path: Array = _trace_path(idx, parents, moves_in)
				stats["candidates"] = int(stats["candidates"]) + 1
				if not verify.is_valid() or bool(verify.call(path)):
					stats.merge({"expanded": expanded, "states": best_g.size(), "stop": "resolved"}, true)
					return {"col": ci, "path": path}
		if expanded >= node_cap:
			stats.merge({"expanded": expanded, "states": best_g.size(), "stop": "node_cap"}, true)
			return {}
		if deadline > 0 and expanded % clock_every == 0\
		and now.is_valid() and int(now.call()) >= deadline:
			stats.merge({"expanded": expanded, "states": best_g.size(), "stop": "deadline"}, true)
			return {}
		expanded += 1
		var moves: Array = R.useful_moves(cur)
		if idx == 0:
			_sort_first_layer(cur, moves, forbid)
		var ns: int = steps[idx] + 1
		for mi in range(moves.size() - 1, -1, -1):
			if clock_every == 1 and deadline > 0 and now.is_valid() and int(now.call()) >= deadline:
				stats.merge({"expanded": expanded, "states": best_g.size(), "stop": "deadline"}, true)
				return {}
			var mv: Dictionary = moves[mi]
			var nx: Dictionary = R.clone_state(cur)
			if R.apply_move(nx, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true).is_empty():
				continue
			var ng: int = g + 1 + (SHUFFLE_PENALTY if is_shuffle_step(cur, mv, nx) else 0)
			var key: String = R.state_key(nx)
			if best_g.has(key) and int(best_g[key]) <= ng:
				continue
			var lb: int = _min_lower_bound(nx, targets, level)
			var nf: int = ng + lb
			if nf > cost_cap or ns + lb > max_depth:
				continue
			best_g[key] = ng
			states.append(nx)
			keys.append(key)
			parents.append(idx)
			gs.append(ng)
			steps.append(ns)
			moves_in.append(mv)
			buckets[nf].append(states.size() - 1)
			if nf < f:
				f = nf
		states[idx] = {}
	stats.merge({"expanded": expanded, "states": best_g.size()}, true)
	return {}



static func _min_lower_bound(st: Dictionary, targets: Array[int], level: JuiceLevel = null) -> int:
	var best: int = LB_IMPOSSIBLE
	for ci: int in targets:
		best = mini(best, hint_lower_bound(st, ci, level))
	return best


static func _trace_path(idx: int, parents: PackedInt32Array, moves_in: Array[Dictionary]) -> Array:
	var path: Array = []
	while parents[idx] >= 0:
		path.append(moves_in[idx])
		idx = parents[idx]
	path.reverse()
	return path



static func _sort_first_layer(st: Dictionary, moves: Array, forbid: Dictionary) -> void :
	var m: int = moves.size()
	if m < 2:
		return
	var keyed: Array = []
	keyed.resize(m)
	for i in m:
		var sc: float = move_score(st, moves[i])
		if not forbid.is_empty() and is_forbidden(st, moves[i], forbid):
			sc -= FORBID_PENALTY
		keyed[i] = [ - sc, i]
	keyed.sort()
	var sorted_moves: Array = []
	sorted_moves.resize(m)
	for i in m:
		sorted_moves[i] = moves[int((keyed[i] as Array)[1])]
	for i in m:
		moves[i] = sorted_moves[i]

































static func hint_move(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> Dictionary:


	if level.capacity >= LONG_ROPE_CAPACITY:
		var long: Dictionary = _long_rope_hint(st, level, opts)
		if not long.is_empty():
			return long
		return _guess_move(st, level, opts.get("forbid", {}))

	var cand: Array = group_candidates(st, level)
	var depth_cap: int = int(opts.get("shallow_depth", 12))
	var shallow_nodes: int = int(opts.get("shallow_nodes", 6000))
	var ms_cap: int = int(opts.get("ms_cap", 60))
	var forbid: Dictionary = opts.get("forbid", {})
	var now: Callable = opts.get("now", Callable())
	var t0: int = int(now.call()) if now.is_valid() else 0




	var deadline_a: int = (t0 + ms_cap * 6 / 10) if now.is_valid() else 0
	var deadline: int = (t0 + ms_cap) if now.is_valid() else 0


	var scored: Array = []
	for c in cand:
		var lb: int = hint_lower_bound(st, int(c["col"]), level)
		if lb < LB_IMPOSSIBLE:
			scored.append({"col": int(c["col"]), "lb": lb, 
				"priority": int(c["score"]) if level.has_sunlight() else 0})
	scored.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["lb"]) < int(b["lb"]) if int(a["lb"]) != int(b["lb"])\
		else int(a["priority"]) > int(b["priority"]))


	var targets: Array[int] = []
	for s in scored:
		targets.append(int(s["col"]))
	if not targets.is_empty():
		var found: Dictionary = _astar_group(st, level, targets, {
			"node_cap": shallow_nodes, "max_depth": depth_cap, 
			"deadline": deadline_a, "now": now, "forbid": forbid, 
		})
		if not found.is_empty():
			var pr: Dictionary = _prune_shuffles(st, level, found["path"], "ready")
			var path: Array = pr["path"]
			return {"move": path[0], "col": int(pr["col"]), 
				"len": path.size(), "optimal": true, "path": path}







	for i in mini(5, scored.size()):
		var ci: int = int(scored[i]["col"])
		var path2: Variant = solve_group(st, level, ci, {
			"node_cap": int(opts.get("deep_nodes", 7000)), 
			"max_depth": int(opts.get("deep_depth", 16)), 
			"deadline": deadline, "now": now, "forbid": forbid, 
		})
		if path2 is Array and not (path2 as Array).is_empty():
			var pr2: Dictionary = _prune_shuffles(st, level, path2, "ready")
			var p2: Array = pr2["path"]
			return {"move": p2[0], "col": int(pr2["col"]), 
				"len": p2.size(), "optimal": false, "path": p2}

	return _guess_move(st, level, forbid)




static func _guess_move(st: Dictionary, level: JuiceLevel, forbid: Dictionary) -> Dictionary:
	var moves: Array = R.useful_moves(st)
	var best: Dictionary = {}
	var best_s: float = -1000000000.0
	for mv in moves:
		var sc: float = move_score(st, mv)
		if not forbid.is_empty() and is_forbidden(st, mv, forbid):
			sc -= FORBID_PENALTY
		var nx: Dictionary = R.clone_state(st)
		R.apply_move(nx, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		if is_shuffle_step(st, mv, nx):
			sc -= FORBID_PENALTY * 2.0
		if sc > best_s:
			best_s = sc
			best = mv
	if best.is_empty():
		return {}
	return {"move": best, "guess": true}










const LONG_ROPE_CAPACITY: = 8

const LONG_ROPE_WEIGHT: = 3

const LONG_ROPE_MAX_DEPTH: = 90

const LONG_ROPE_VERIFY_OPT: = {"node_cap": 1500, "state_cap": 4000}
const LONG_ROPE_VERIFY_TRIES: = 4

const LONG_ROPE_WIN_OPT: = {"node_cap": 6000, "weight": 2, "max_depth": 200}

const LONG_ROPE_WIN_BUDGET_MUL: = 2




static func sort_lower_bound(st: Dictionary) -> int:
	if bool(st.get("allow_root_swapping", false)):
		return 0
	var cols: Array = st["cols"]
	var jars: Array[int] = st["jars"]
	var gone: Array[bool] = st["gone"]
	var runs: int = 0
	var pots: int = 0
	var bottom_ok: int = 0
	for ci in cols.size():
		if gone[ci]:
			continue
		var col: Array[int] = cols[ci]
		var prev: int = -1
		for v in col:
			var t: int = _hint_type(v)
			if t != prev:
				runs += 1
				prev = t
		if jars[ci] < 0:
			continue
		pots += 1
		if not col.is_empty() and _hint_type(col[0]) == jars[ci]:
			bottom_ok += 1
	return maxi(0, runs - pots) + maxi(0, pots - bottom_ok)










static func _long_rope_hint(st: Dictionary, level: JuiceLevel, opts: Dictionary) -> Dictionary:
	var now: Callable = opts.get("now", Callable())
	var ms_cap: int = int(opts.get("ms_cap", 60))
	var t0: int = int(now.call()) if now.is_valid() else 0
	var deadline: int = (t0 + ms_cap) if now.is_valid() else 0
	var banned: Dictionary = {}
	var found: Dictionary = {}
	for attempt in LONG_ROPE_VERIFY_TRIES:
		found = {}
		for w: int in [LONG_ROPE_WEIGHT, 1]:
			found = _astar_sorted(st, level, {
				"node_cap": int(opts.get("deep_nodes", 7000)), 
				"max_depth": LONG_ROPE_MAX_DEPTH, "weight": w, "banned": banned, 
				"deadline": deadline, "now": now, "forbid": opts.get("forbid", {}), 
			})
			if not found.is_empty():
				break
		if found.is_empty():
			break
		var end_state: Dictionary = R.clone_state(st)
		for mv: Dictionary in (found["path"] as Array):
			R.apply_move(end_state, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		var after: Dictionary = R.clone_state(end_state)
		R.run_deposit(after, level, [])
		var verify_opt: Dictionary = LONG_ROPE_VERIFY_OPT.duplicate()
		if now.is_valid():
			verify_opt["now"] = now
			verify_opt["ms_cap"] = maxi(1, deadline - int(now.call()))
		if full_reachability(after, level, verify_opt) != Reachability.UNWINNABLE:
			break
		banned[R.state_key(end_state)] = true
		found = {}
		if deadline > 0 and int(now.call()) > deadline:
			return {}
	if found.is_empty():




		var whole_deadline: int = (int(now.call()) + ms_cap * LONG_ROPE_WIN_BUDGET_MUL) if now.is_valid() else 0

		if opts.has("diagnostic"):
			var diagnostic: Dictionary = opts["diagnostic"]
			diagnostic["phase"] = "long_rope_win_path"
			diagnostic["budget_ms"] = ms_cap * LONG_ROPE_WIN_BUDGET_MUL
			diagnostic["window_text"] = String(diagnostic.get("window_text", ""))\
			+ "；长绳整关续查另开%dms" % int(diagnostic["budget_ms"])
		var whole: Array = _win_path(st, level, LONG_ROPE_WIN_OPT, whole_deadline, now)
		if whole.is_empty():
			return {}
		whole = _prune_shuffles(st, level, whole, "win")["path"]
		return {"move": whole[0], "col": int((whole[0] as Dictionary)["dst"]), "len": whole.size(), 
			"optimal": false, "path": whole}

	var verify: = func(end: Dictionary) -> bool:
		var after2: Dictionary = R.clone_state(end)
		R.run_deposit(after2, level, [])
		return full_reachability(after2, level, LONG_ROPE_VERIFY_OPT) != Reachability.UNWINNABLE
	var pr: Dictionary = _prune_shuffles(st, level, found["path"], "ready", verify)
	var path: Array = pr["path"]
	return {"move": path[0], "col": int(pr["col"]), "len": path.size(), 
		"optimal": false, "path": path}




static func _win_path(st: Dictionary, level: JuiceLevel, opts: Dictionary, deadline: int, 
		now: Callable) -> Array:
	var node_cap: int = int(opts.get("node_cap", 6000))
	var w: int = int(opts.get("weight", 2))
	var max_g: int = int(opts.get("max_depth", 200))
	var h_of: = func(x: Dictionary) -> int:
		return sort_lower_bound(x) + level.groups_total - int(x["done"])
	var key0: String = _full_state_key(st)
	var states: Array[Dictionary] = [R.clone_state(st)]
	var parents: PackedInt32Array = PackedInt32Array([-1])
	var gs: PackedInt32Array = PackedInt32Array([0])
	var moves_in: Array[Dictionary] = [{}]
	var best_g: Dictionary = {key0: 0}
	var keys: PackedStringArray = PackedStringArray([key0])
	var buckets: Dictionary = {}
	var f0: int = w * int(h_of.call(st))
	buckets[f0] = [0]
	var f: int = f0
	var f_max: int = f0
	var expanded: int = 0
	while f <= f_max:
		if not buckets.has(f) or (buckets[f] as Array).is_empty():
			f += 1
			continue
		var idx: int = (buckets[f] as Array).pop_back()
		var g: int = gs[idx]
		if int(best_g[keys[idx]]) < g or g >= max_g:
			continue
		if expanded >= node_cap:
			return []
		if deadline > 0 and (expanded & (ASTAR_CLOCK_EVERY - 1)) == 0 and int(now.call()) > deadline:
			return []
		expanded += 1
		var cur: Dictionary = states[idx]
		for mv: Dictionary in R.useful_moves(cur):
			var nx: Dictionary = R.clone_state(cur)
			if R.apply_move(nx, level, int(mv["src"]), int(mv["j"]), int(mv["dst"])).is_empty():
				continue
			states.append(nx)
			parents.append(idx)
			gs.append(g + 1)
			moves_in.append(mv)
			var ni: int = states.size() - 1
			var key: String = _full_state_key(nx)
			keys.append(key)
			if R.is_win(nx, level):
				return _trace_path(ni, parents, moves_in)
			if R.is_doomed(nx, level) or (best_g.has(key) and int(best_g[key]) <= g + 1):
				states[ni] = {}
				continue
			best_g[key] = g + 1
			var nf: int = g + 1 + w * int(h_of.call(nx))
			if not buckets.has(nf):
				buckets[nf] = []
			(buckets[nf] as Array).append(ni)
			f_max = maxi(f_max, nf)
			if nf < f:
				f = nf
		states[idx] = {}
	return []



static func _astar_sorted(st: Dictionary, level: JuiceLevel, opts: Dictionary) -> Dictionary:
	var node_cap: int = int(opts.get("node_cap", 7000))
	var max_depth: int = int(opts.get("max_depth", LONG_ROPE_MAX_DEPTH))
	var deadline: int = int(opts.get("deadline", 0))
	var now: Callable = opts.get("now", Callable())
	var forbid: Dictionary = opts.get("forbid", {})
	var banned: Dictionary = opts.get("banned", {})
	if R.any_ready(st):
		return {}
	var w: int = int(opts.get("weight", LONG_ROPE_WEIGHT))
	var f_cap: int = max_depth * (w + 1)
	var h0: int = sort_lower_bound(st)
	if w * h0 > f_cap:
		return {}
	var key0: String = R.state_key(st)
	var states: Array[Dictionary] = [R.clone_state(st)]
	var keys: PackedStringArray = PackedStringArray([key0])
	var parents: PackedInt32Array = PackedInt32Array([-1])
	var gs: PackedInt32Array = PackedInt32Array([0])

	var steps: PackedInt32Array = PackedInt32Array([0])
	var moves_in: Array[Dictionary] = [{}]
	var best_g: Dictionary = {key0: 0}
	f_cap += SHUFFLE_PENALTY * SHUFFLE_COST_ROOM
	var buckets: Array[Array] = []
	buckets.resize(f_cap + 1)
	for b in buckets.size():
		buckets[b] = []
	buckets[w * h0].append(0)
	var f: int = w * h0
	var expanded: int = 0
	while f <= f_cap:
		var bucket: Array = buckets[f]
		if bucket.is_empty():
			f += 1
			continue
		var idx: int = bucket.pop_back()
		var g: int = gs[idx]
		if int(best_g[keys[idx]]) < g:
			continue
		if expanded >= node_cap:
			return {}
		if deadline > 0 and (expanded & (ASTAR_CLOCK_EVERY - 1)) == 0\
		and now.is_valid() and int(now.call()) > deadline:
			return {}
		expanded += 1
		var cur: Dictionary = states[idx]
		var moves: Array = R.useful_moves(cur)
		if idx == 0:
			_sort_first_layer(cur, moves, forbid)
		var ns: int = steps[idx] + 1
		if ns > max_depth:
			states[idx] = {}
			continue
		for mi in range(moves.size() - 1, -1, -1):
			var mv: Dictionary = moves[mi]
			var nx: Dictionary = R.clone_state(cur)
			if R.apply_move(nx, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true).is_empty():
				continue
			var ng: int = g + 1 + (SHUFFLE_PENALTY if is_shuffle_step(cur, mv, nx) else 0)
			states.append(nx)
			parents.append(idx)
			gs.append(ng)
			steps.append(ns)
			moves_in.append(mv)
			var ni: int = states.size() - 1
			var key: String = R.state_key(nx)
			keys.append(key)
			if banned.has(key):
				states[ni] = {}
				continue
			for ci in (nx["cols"] as Array).size():
				if R.deposit_ready(nx, ci) > 0:
					return {"col": ci, "path": _trace_path(ni, parents, moves_in)}
			if best_g.has(key) and int(best_g[key]) <= ng:
				states[ni] = {}
				continue
			var nf: int = ng + w * sort_lower_bound(nx)
			if nf > f_cap:
				states[ni] = {}
				continue
			best_g[key] = ng
			buckets[nf].append(ni)
			if nf < f:
				f = nf
		states[idx] = {}
	return {}










static func has_route_to_group(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> bool:
	var r: Dictionary = hint_move(st, level, opts)
	return not r.is_empty() and not bool(r.get("guess", false))





static func full_reachability(st: Dictionary, level: JuiceLevel, 
		opts: Dictionary = {}) -> int:
	var search: Dictionary = begin_full_search(st, level)

	var diagnostic: Dictionary = opts.get("diagnostic", {})
	var now: Callable = opts.get("now", Callable())
	var started: int = int(now.call()) if opts.has("diagnostic") and now.is_valid() else 0
	var value: int = advance_full_search(search, level, opts)
	if opts.has("diagnostic") and value == Reachability.UNKNOWN\
	and String(search.get("stop_reason", "")) == "deadline":
		diagnostic.merge(full_search_summary(search))
		diagnostic["budget_ms"] = int(opts.get("ms_cap", 120))
		diagnostic["elapsed_ms"] = maxi(0, int(now.call()) - started) if now.is_valid() else 0
	return value



static func full_search_summary(search: Dictionary) -> Dictionary:
	return {"phase": "full_search", "reason": String(search.get("stop_reason", "")), 
		"expanded": int(search.get("expanded", 0)), 
		"states": (search.get("seen", {}) as Dictionary).size(), 
		"candidates": int(search.get("candidates", 0))}





static func begin_full_search(st: Dictionary, level: JuiceLevel, one_pot: bool = false, 
		keep_path: bool = false) -> Dictionary:
	var result: int = Reachability.UNKNOWN
	var done: bool = st.is_empty() or level == null
	if not done:
		if R.is_win(st, level):
			result = Reachability.WINNABLE
			done = true
		elif ( not one_pot and R.is_doomed(st, level)) or not R.has_any_move(st):
			result = Reachability.UNWINNABLE
			done = true
	return {"result": result, "done": done, "expanded": 0, "candidates": 0, 
		"one_pot": one_pot, "start_done": int(st.get("done", 0)), 
		"stop_reason": "resolved" if result != Reachability.UNKNOWN else ("invalid_state" if done else ""), 
		"frontier": [] if done else [R.clone_state(st)], 
		"seen": {} if done else {_full_search_key(st, keep_path): true}, 
		"current": {}, "src": 0, "j": 0, "dst": 0, 
		"keep_path": keep_path, "parents": {}, "path": []}




static func advance_full_search(search: Dictionary, level: JuiceLevel, 
		opts: Dictionary = {}) -> int:
	if bool(search["done"]):
		return int(search["result"])
	var node_cap: int = maxi(0, int(opts.get("node_cap", 3000)))
	var state_cap: int = maxi(1, int(opts.get("state_cap", 8000)))
	var now: Callable = opts.get("now", Callable())
	var deadline: int = int(opts.get("deadline", int(now.call()) + int(opts.get("ms_cap", 120)))) if now.is_valid() else 0
	var clock_every: int = maxi(1, int(opts.get("clock_every", 64)))
	while true:
		if deadline > 0 and int(now.call()) >= deadline:
			search["stop_reason"] = "deadline"
			return Reachability.UNKNOWN
		if (search["current"] as Dictionary).is_empty():
			if (search["frontier"] as Array).is_empty():
				search["done"] = true
				search["result"] = Reachability.UNWINNABLE
				search["stop_reason"] = "resolved"
				return Reachability.UNWINNABLE
			if int(search["expanded"]) >= node_cap:
				search["stop_reason"] = "node_cap"
				return Reachability.UNKNOWN
			search["current"] = (search["frontier"] as Array).pop_back()
			search["expanded"] = int(search["expanded"]) + 1
			search["src"] = 0
			search["j"] = 0
			search["dst"] = 0
		var cur: Dictionary = search["current"]
		var cols: Array = cur["cols"]
		while int(search["src"]) < cols.size():
			var src: int = int(search["src"])
			while int(search["j"]) < (cols[src] as Array[int]).size():
				var j: int = int(search["j"])
				while int(search["dst"]) < cols.size():
					var dst: int = int(search["dst"])
					search["candidates"] = int(search["candidates"]) + 1
					if deadline > 0 and int(search["candidates"]) % clock_every == 0\
					and int(now.call()) >= deadline:
						search["stop_reason"] = "deadline"
						return Reachability.UNKNOWN
					if R.move_info(cur, src, j, dst) > 0:
						var next: Dictionary = R.clone_state(cur)
						var rec: Dictionary = R.apply_move(next, level, src, j, dst)
						if not rec.is_empty():
							var one_pot: bool = bool(search["one_pot"])
							if R.is_win(next, level) or (one_pot and int(next["done"]) > int(search["start_done"])):
								var check_opts: Dictionary = {"now": now, "deadline": deadline}
								if not one_pot or _hint_safe_after(next, level, check_opts):
									search["done"] = true
									search["result"] = Reachability.WINNABLE
									search["stop_reason"] = "resolved"
									if bool(search["keep_path"]):
										search["path"] = _full_search_path(search, _full_search_key(cur, true), 
											{"src": src, "j": j, "dst": dst})
									return Reachability.WINNABLE
								if _hint_time_expired(check_opts):

									search["stop_reason"] = "deadline"
									return Reachability.UNKNOWN
							elif one_pot or not R.is_doomed(next, level):
								var key: String = _full_search_key(next, bool(search["keep_path"]))
								if not (search["seen"] as Dictionary).has(key):
									if (search["seen"] as Dictionary).size() >= state_cap:

										search["stop_reason"] = "state_cap"
										return Reachability.UNKNOWN
									search["seen"][key] = true
									if bool(search["keep_path"]):
										search["parents"][key] = {"key": _full_search_key(cur, true), 
											"move": {"src": src, "j": j, "dst": dst}}
									(search["frontier"] as Array).append(next)
					search["dst"] = dst + 1
				search["j"] = j + 1
				search["dst"] = 0
			search["src"] = src + 1
			search["j"] = 0
		search["current"] = {}
	return Reachability.UNKNOWN


static func _full_search_key(st: Dictionary, keep_path: bool) -> String:
	var key: String = _full_state_key(st)

	if keep_path and not bool(st.get("allow_root_swapping", false)):
		key += JSON.stringify([st.get("frozen_pots", []), st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION)])
	return key


static func _full_search_path(search: Dictionary, key: String, last: Dictionary) -> Array:
	var path: Array = [last]
	var parents: Dictionary = search["parents"]
	while parents.has(key):
		var parent: Dictionary = parents[key]
		path.append(parent["move"])
		key = String(parent["key"])
	path.reverse()
	return path



static func _full_state_key(st: Dictionary) -> String:
	var key: String = JSON.stringify([st["cols"], st["jars"], st["caps"], st["gone"], 
		st["locks"], st["done"], st["cups"], st["late_left"], st["extra_rope_used"]])

	if bool(st.get("allow_root_swapping", false)):
		return key + "~root_swap" + JSON.stringify([st.get("frozen_pots", []), 
			st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION)])
	return key




static func classify_dead_previous(previous: Dictionary, level: JuiceLevel, 
		opts: Dictionary = {}) -> int:
	if previous.is_empty() or level == null or (previous["cols"] as Array).is_empty():
		return DeathAttribution.UNKNOWN
	if R.is_win(previous, level):
		return DeathAttribution.LAST_MOVE
	if not R.has_any_move(previous):
		return DeathAttribution.EARLIER
	var now: Callable = opts.get("now", Time.get_ticks_msec)
	if not now.is_valid():
		now = Time.get_ticks_msec
	var started: int = int(now.call())
	var ms_cap: int = maxi(0, int(opts.get("ms_cap", 120)))
	var deadline: int = int(opts.get("deadline", started + ms_cap))
	var search_opts: Dictionary = opts.duplicate()
	search_opts["now"] = now
	search_opts["deadline"] = deadline
	search_opts["clock_every"] = 1
	var search: Dictionary = begin_full_search(previous, level, true)
	var value: int = advance_full_search(search, level, search_opts)
	if value == Reachability.WINNABLE:
		return DeathAttribution.LAST_MOVE
	if value == Reachability.UNWINNABLE:
		return DeathAttribution.EARLIER
	if opts.has("diagnostic") and int(now.call()) >= deadline:
		var diagnostic: Dictionary = opts["diagnostic"]
		diagnostic.merge({"phase": "one_pot_dfs", "reason": "deadline", "budget_ms": ms_cap, 
			"elapsed_ms": maxi(0, int(now.call()) - started), "expanded": search["expanded"]})
	return DeathAttribution.UNKNOWN



static func run_death_attribution_task(previous: Dictionary, level: JuiceLevel, 
		opts: Dictionary, result: Dictionary) -> void :

	var diagnostic: Dictionary = {}
	var opt: Dictionary = opts.duplicate()
	opt["diagnostic"] = diagnostic
	result["attribution"] = classify_dead_previous(previous, level, opt)
	if not diagnostic.is_empty():
		diagnostic["source"] = "death_attribution"
		result["diagnostic"] = diagnostic
	result["completed"] = true



const HINT_WIN_WIDTH: = 3

const HINT_WIN_ROUTE_NODES: = 1500
const HINT_WIN_ROUTE_DEPTH: = 16

const HINT_WIN_MAX_ROUTES: = 300


















static func hint_win_path(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> Array:
	if st.is_empty() or level == null or R.is_win(st, level):
		return []
	var ctx: Dictionary = {
		"level": level, 
		"goal_done": int(opts.get("goal_done", level.groups_total)), 
		"root_state": st, 
		"safe_hint": bool(opts.get("safe_hint", false)), 
		"clock_every": int(opts.get("clock_every", 0)), 
		"seen": {}, 
		"routes": 0, 
		"aborted": false, 
		"max_routes": int(opts.get("max_routes", HINT_WIN_MAX_ROUTES)), 
		"width": int(opts.get("width", HINT_WIN_WIDTH)), 
		"route_nodes": int(opts.get("route_nodes", HINT_WIN_ROUTE_NODES)), 
		"route_depth": int(opts.get("route_depth", HINT_WIN_ROUTE_DEPTH)), 
		"stats": opts.get("stats", {}), 
		"deadline": int(opts.get("deadline", 0)), 
		"now": opts.get("now", Callable()), 
	}
	var path: Array = []
	var found: bool = _hint_win_dfs(R.clone_state(st), path, ctx, 0)
	var stats: Dictionary = ctx["stats"]
	stats["aborted"] = ctx["aborted"]
	stats["routes"] = ctx["routes"]
	stats["stop"] = "resolved" if found else stats.get("stop", "no_path")
	return path if found else []




static func _hint_win_dfs(st: Dictionary, path: Array, ctx: Dictionary, depth: int) -> bool:
	var level: JuiceLevel = ctx["level"]
	if R.is_win(st, level) or int(st["done"]) >= int(ctx["goal_done"]):
		(ctx["stats"] as Dictionary)["done"] = st["done"]
		return true
	if R.is_doomed(st, level) or not R.has_any_move(st):
		return false

	if depth > level.groups_total * 4:
		return false
	var seen: Dictionary = ctx["seen"]
	var key: String = _full_state_key(st)
	if seen.has(key):
		return false
	seen[key] = true


	var scored: Array = []
	for c: Dictionary in group_candidates(st, level):
		var lb: int = hint_lower_bound(st, int(c["col"]), level)
		if lb < LB_IMPOSSIBLE:
			scored.append({"col": int(c["col"]), "lb": lb, 
				"priority": int(c["score"]) if level.has_sunlight() else 0})
	scored.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["lb"]) != int(b["lb"]):
			return int(a["lb"]) < int(b["lb"])
		if int(a.get("priority", 0)) != int(b.get("priority", 0)):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
		return int(a["col"]) < int(b["col"]))

	var tried: int = 0
	for s: Dictionary in scored:
		if tried >= int(ctx["width"]):
			break
		if _hint_win_out_of_budget(ctx):
			return false
		var route: Variant = _hint_route(st, ctx, int(s["col"]))
		if route == null:
			continue
		tried += 1

		var next: Dictionary = R.clone_state(st)
		var applied: Array = []
		var safe: bool = true
		for mv: Dictionary in (route as Array):
			if _hint_time_expired(ctx):
				ctx["aborted"] = true
				(ctx["stats"] as Dictionary)["stop"] = "deadline"
				return false
			var rec: Dictionary = R.apply_move(next, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			if rec.is_empty():
				break
			applied.append(mv)

			if bool(ctx["safe_hint"]) and not (rec["deposits"] as Array).is_empty()\
			and not _hint_safe_after(next, level, ctx):
				safe = false
				break
			if R.is_win(next, level) or int(next["done"]) >= int(ctx["goal_done"]):
				break
		if applied.is_empty() or not safe:
			continue
		var root_hint: Dictionary = {}
		var stats: Dictionary = ctx["stats"]
		if depth == 0 or (stats.get("local", {}) as Dictionary).is_empty():
			root_hint = _checked_path_hint(ctx["root_state"], level, path + applied, 
				ctx if bool(ctx["safe_hint"]) else {})
			var best: Dictionary = stats.get("local", {})
			if not root_hint.is_empty() and (best.is_empty() or int(root_hint["len"]) < int(best["len"])):
				stats["local"] = root_hint
		var base: int = path.size()
		path.append_array(applied)
		if _hint_win_dfs(next, path, ctx, depth + 1):
			if depth == 0:
				if root_hint.is_empty():
					root_hint = _checked_path_hint(st, level, path, ctx if bool(ctx["safe_hint"]) else {})
				(ctx["stats"] as Dictionary)["hint"] = root_hint
			return true
		path.resize(base)
	return false






static func _hint_route(st: Dictionary, ctx: Dictionary, ci: int) -> Variant:
	ctx["routes"] = int(ctx["routes"]) + 1
	var level: JuiceLevel = ctx["level"]
	var route_opts: Dictionary = {
		"node_cap": ctx["route_nodes"], "max_depth": ctx["route_depth"], 
		"deadline": ctx["deadline"], "now": ctx["now"], "forbid": {}, 
	}
	if int(ctx["clock_every"]) > 0:
		route_opts["clock_every"] = ctx["clock_every"]
	var deep: Variant = solve_group(st, level, ci, route_opts)
	if deep is Array:
		return deep
	var targets: Array[int] = [ci]
	var found: Dictionary = _astar_group(st, level, targets, route_opts)
	if not found.is_empty():
		return found["path"]
	return null



static func _hint_win_out_of_budget(ctx: Dictionary) -> bool:
	if bool(ctx["aborted"]):
		return true
	if int(ctx["routes"]) >= int(ctx["max_routes"]):
		ctx["aborted"] = true
		(ctx["stats"] as Dictionary)["stop"] = "route_cap"
		return true
	if _hint_time_expired(ctx):
		ctx["aborted"] = true
		(ctx["stats"] as Dictionary)["stop"] = "deadline"
		return true
	return false


static func _hint_time_expired(opts: Dictionary) -> bool:
	var now: Callable = opts.get("now", Callable())
	var deadline: int = int(opts.get("deadline", 0))
	return deadline > 0 and now.is_valid() and int(now.call()) >= deadline







static func run_safe_return_task(st: Dictionary, recs: Array, level: JuiceLevel, 
		keep_revealed: bool, opts: Dictionary, result: Dictionary) -> void :
	var probe: Dictionary = R.clone_state(st)
	var steps: int = 0
	var now: Callable = opts.get("now", Callable())
	var started: int = int(now.call()) if now.is_valid() else 0
	var checked: int = 0
	var timed_out: int = 0
	var last_timeout: Dictionary = {}
	for i: int in recs.size():
		R.undo_move(probe, recs[recs.size() - 1 - i] as Dictionary, keep_revealed)
		checked += 1

		var candidate: Dictionary = {}
		if _safe_candidate_has_exit(probe, level, opts, candidate):
			steps = i + 1
			break
		if String(candidate.get("reason", "")) == "deadline":
			timed_out += 1
			last_timeout = candidate
			last_timeout["candidate_step"] = i + 1
	result["steps"] = steps
	if steps == 0 and timed_out > 0:
		last_timeout["source"] = "safe_return"
		last_timeout["checked"] = checked
		last_timeout["timed_out"] = timed_out
		last_timeout["elapsed_ms"] = maxi(0, int(now.call()) - started) if now.is_valid() else 0
		last_timeout["window_text"] = "每候选%dms，共检查%d个候选（%d个超时）" % [
			int(opts.get("ms_cap", 120)), checked, timed_out]
		result["diagnostic"] = last_timeout
	result["completed"] = true




static func _safe_candidate_has_exit(st: Dictionary, level: JuiceLevel, opts: Dictionary, 
		diagnostic: Dictionary = {}) -> bool:

	var search: Dictionary = begin_full_search(st, level)
	if bool(search["done"]):
		return int(search["result"]) == Reachability.WINNABLE
	var now: Callable = opts.get("now", Callable())
	var ms_cap: int = int(opts.get("ms_cap", 120))
	var started: int = int(now.call()) if now.is_valid() else 0
	var hint_opts: Dictionary = {
		"now": now, "goal_done": mini(level.groups_total, int(st["done"]) + 3), 
		"safe_hint": true, "clock_every": 1, "width": 6, "route_nodes": 6000, 
		"route_depth": maxi(32, level.capacity * 8), "max_routes": 2000, 
	}
	if now.is_valid():
		hint_opts["deadline"] = started + int(ms_cap * 0.6)
	if not hint_win_path(st, level, hint_opts).is_empty():
		return true
	var fallback_opts: Dictionary = opts.duplicate()
	if now.is_valid():
		var remaining_ms: int = started + ms_cap - int(now.call())
		if remaining_ms <= 0:

			diagnostic.merge({"phase": "safe_hint", "reason": "deadline", "budget_ms": ms_cap})
			return false
		fallback_opts["ms_cap"] = remaining_ms
		fallback_opts["clock_every"] = 1
	var value: int = advance_full_search(search, level, fallback_opts)
	if value == Reachability.UNKNOWN and String(search.get("stop_reason", "")) == "deadline":
		diagnostic.merge(full_search_summary(search))
		diagnostic["budget_ms"] = ms_cap
	return value == Reachability.WINNABLE







const CLOSED_STATE_CAP: = 80

const ROOT_PERMUTATION_STATE_CAP: = 2000
























static func is_closed_cycle(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> bool:
	if _hint_time_expired(opts):
		opts["aborted"] = true
		return false
	if st.is_empty() or level == null or R.any_ready(st):
		return false
	if bool(st.get("allow_root_swapping", false)):
		var search: Dictionary = begin_root_closed_search(st, level, int(opts.get("state_cap", 8000)))
		var result: Dictionary = advance_root_closed_search(search, 8, opts)
		if String(result["status"]) == "UNKNOWN":
			opts["aborted"] = true
		return bool(result["closed"])


	if not _has_mechanics(st, level) and _has_irreversible_move(st):
		return false



	var idx: Dictionary = {R.state_key(st): 0}
	var states: Array[Dictionary] = [R.clone_state(st)]
	var adj: Array = [[] as Array[int]]
	var pending: Array[int] = [0]
	while not pending.is_empty():
		if _hint_time_expired(opts):
			opts["aborted"] = true
			return false
		var i: int = pending.pop_back()
		var cur: Dictionary = states[i]
		var cols: Array = cur["cols"]
		for src in cols.size():
			var src_col: Array[int] = cols[src]
			for j in src_col.size():
				for dst in cols.size():
					if _hint_time_expired(opts):
						opts["aborted"] = true
						return false
					if R.move_info(cur, src, j, dst) <= 0:
						continue
					var nx: Dictionary = R.clone_state(cur)
					if R.apply_move(nx, level, src, j, dst, true).is_empty():
						continue

					if R.any_ready(nx):
						return false
					var key: String = R.state_key(nx)
					if not idx.has(key):
						if idx.size() >= CLOSED_STATE_CAP:
							return false
						idx[key] = states.size()
						states.append(nx)
						adj.append([] as Array[int])
						pending.append(int(idx[key]))
					(adj[i] as Array[int]).append(int(idx[key]))



	var n: int = states.size()
	var radj: Array = []
	radj.resize(n)
	for i in n:
		radj[i] = [] as Array[int]
	for i in n:
		for t in (adj[i] as Array[int]):
			if _hint_time_expired(opts):
				opts["aborted"] = true
				return false
			(radj[t] as Array[int]).append(i)
	var seen: Array[bool] = []
	seen.resize(n)
	seen.fill(false)
	seen[0] = true
	var reached: int = 1
	var queue: Array[int] = [0]
	while not queue.is_empty():
		if _hint_time_expired(opts):
			opts["aborted"] = true
			return false
		var c: int = queue.pop_back()
		for p in (radj[c] as Array[int]):
			if not seen[p]:
				seen[p] = true
				reached += 1
				queue.append(p)
	return reached == n







static func _root_permutation_closed_without_deposit(st: Dictionary, level: JuiceLevel, 
		opts: Dictionary) -> bool:
	if not bool(st.get("allow_root_swapping", false)) or _has_mechanics(st, level):
		return false
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	if cols.is_empty() or caps[0] <= 0:
		return false
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		if caps[ci] != caps[0] or col.size() > caps[ci]\
		or bool(st["gone"][ci]) or R.is_frozen_pot(st, ci):
			return false

	var start: Dictionary = R.clone_state(st)
	start["allow_root_swapping"] = false
	var seen: Dictionary = {_root_permutation_key(start): true}
	var pending: Array[Dictionary] = [start]
	var cap: int = mini(ROOT_PERMUTATION_STATE_CAP, maxi(1, int(opts.get("state_cap", ROOT_PERMUTATION_STATE_CAP))))
	while not pending.is_empty():
		if _hint_time_expired(opts):
			opts["aborted"] = true
			return false
		var cur: Dictionary = pending.pop_back()
		if _root_permutation_has_deposit(cur):
			return false
		var cur_cols: Array = cur["cols"]
		for src in cur_cols.size():
			for j in (cur_cols[src] as Array).size():
				for dst in cur_cols.size():
					if _hint_time_expired(opts):
						opts["aborted"] = true
						return false
					if R.move_info(cur, src, j, dst) <= 0:
						continue
					var next: Dictionary = R.clone_state(cur)
					if R.apply_move(next, level, src, j, dst, true).is_empty():
						continue
					if _root_permutation_has_deposit(next):
						return false
					var key: String = _root_permutation_key(next)
					if seen.has(key):
						continue
					if seen.size() >= cap:

						return false
					seen[key] = true
					pending.append(next)
	if _hint_time_expired(opts):
		opts["aborted"] = true
		return false
	return true


static func _root_permutation_key(st: Dictionary) -> String:
	var moving: Array[String] = []
	var fixed: Array = []
	for ci in (st["cols"] as Array).size():
		var col: Array[int] = st["cols"][ci]
		if bool(st["gone"][ci]) or not (st["locks"][ci] as Dictionary).is_empty():
			fixed.append([ci, col])
		else:
			moving.append(JSON.stringify(col))
	moving.sort()
	return JSON.stringify([moving, fixed])



static func _root_permutation_has_deposit(st: Dictionary) -> bool:
	var legal: Dictionary = st.duplicate()
	legal["allow_root_swapping"] = true
	return R.any_ready(st) or not _root_deposit_move(legal).is_empty()



static func _root_deposit_move(st: Dictionary) -> Dictionary:
	for src in (st["cols"] as Array).size():
		var col: Array[int] = st["cols"][src]
		if col.is_empty() or bool(st["gone"][src]) or not (st["locks"][src] as Dictionary).is_empty()\
		or JuiceLevel.is_hidden(col[0]) or JuiceLevel.is_frozen(col[0]):
			continue
		var mono: bool = true
		for fruit_type: int in col:
			if fruit_type != col[0]:
				mono = false
				break
		if not mono:
			continue
		for dst in (st["cols"] as Array).size():
			if int(st["jars"][dst]) == col[0] and int(st["caps"][dst]) == col.size()\
			and not bool(st["gone"][dst]) and (st["locks"][dst] as Dictionary).is_empty()\
			and not R.is_frozen_pot(st, dst) and R.move_info(st, src, 0, dst) > 0:
				return {"src": src, "j": 0, "dst": dst}
	return {}



static func _root_insufficient_stock(st: Dictionary, level: JuiceLevel) -> bool:
	for ci in (st["cols"] as Array).size():
		if bool(st["gone"][ci]) and (int(st["caps"][ci]) != 0 or not (st["cols"][ci] as Array).is_empty()):
			return false
	var stock: Dictionary = {}
	for col: Array[int] in st["cols"]:
		for fruit_type: int in col:
			var color: int = JuiceLevel.true_type(fruit_type)
			stock[color] = int(stock.get(color, 0)) + 1
	for ci in (st["jars"] as Array).size():
		var color: int = int(st["jars"][ci])
		if not bool(st["gone"][ci]) and color >= 0 and int(st["caps"][ci]) > 0\
		and int(stock.get(color, 0)) >= int(st["caps"][ci]):
			return false
	return true






static func _is_root_swap_only_cycle(st: Dictionary, level: JuiceLevel) -> bool:
	if not bool(st.get("allow_root_swapping", false)) or _has_mechanics(st, level):
		return false
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var jars: Array[int] = st["jars"]
	var max_cap: int = 0
	for ci in cols.size():
		if R.is_frozen_pot(st, ci):
			return false
		if (cols[ci] as Array).is_empty() or caps[ci] <= 0 or bool(st["gone"][ci]):
			return false
		max_cap = maxi(max_cap, caps[ci])
	for src in cols.size():
		var sc: Array[int] = cols[src]

		var mono: bool = true
		for fruit_type: int in sc:
			if fruit_type != sc[0]:
				mono = false
				break
		if mono:
			for ci in jars.size():
				if jars[ci] == sc[0] and caps[ci] == sc.size():
					return false
		for dst in cols.size():
			if src == dst:
				continue
			var dc: Array[int] = cols[dst]
			for j in sc.size():
				if sc[j] == dc[-1] and sc.size() - j + dc.size() <= max_cap:
					return false
	return true




static func _has_irreversible_move(st: Dictionary) -> bool:
	var cols: Array = st["cols"]
	for src in cols.size():
		var sc: Array[int] = cols[src]
		for j in sc.size():
			if j == 0 or sc[j - 1] == sc[j]:
				continue
			for dst in cols.size():
				if R.move_info(st, src, j, dst) > 0:
					return true
	return false



static func root_closed_state_key(st: Dictionary) -> String:
	return "" if st.is_empty() else _full_state_key(st)




static func begin_root_closed_search(st: Dictionary, level: JuiceLevel, 
		max_states: int = 8000, require_complete: bool = false) -> Dictionary:
	var valid: bool = not st.is_empty() and level != null\
	and bool(st.get("allow_root_swapping", false))
	var snapshot: Dictionary = R.clone_state(st.duplicate()) if valid else {}
	var key: String = root_closed_state_key(snapshot)
	return {"level": level, "start": snapshot, "root_key": key, "phase": "initial", 
		"done": not valid, "status": "UNKNOWN", "reason": "" if valid else "invalid_state", 
		"max_states": mini(64000, maxi(1, max_states)), "states": 1 if valid else 0, 
		"require_complete": require_complete, "method": "astar", 
		"expanded": 0, "candidates": 0, "seen": {}, "nodes": [], "frontier": [], 
		"current": {}, "current_id": -1, "path": [], "src": 0, "j": 0, "dst": 0, 
		"delivery_checked": false, "initial_has_move": false}





static func advance_root_closed_search(search: Dictionary, budget_ms: int = 8, 
		opts: Dictionary = {}) -> Dictionary:
	if bool(search.get("done", true)):
		return _root_closed_search_result(search)
	var level: JuiceLevel = search["level"] as JuiceLevel
	var now: Callable = opts.get("now", Callable())
	var clock_opts: Dictionary = {}
	if now.is_valid():
		clock_opts = {"now": now, 
			"deadline": int(opts.get("deadline", int(now.call()) + maxi(0, budget_ms)))}
	if _hint_time_expired(clock_opts):
		return _root_closed_search_pause(search)
	if String(search["phase"]) == "initial":
		var start: Dictionary = search["start"]
		var initially_ready: bool = R.any_ready(start)
		if initially_ready:

			var cols: Array = start["cols"]
			while int(search["src"]) < cols.size():
				var src: int = int(search["src"])
				while int(search["j"]) < (cols[src] as Array[int]).size():
					var j: int = int(search["j"])
					while int(search["dst"]) < cols.size():
						if _hint_time_expired(clock_opts):
							return _root_closed_search_pause(search)
						var dst: int = int(search["dst"])
						search["dst"] = dst + 1
						search["candidates"] = int(search["candidates"]) + 1
						var k: int = R.move_info(start, src, j, dst)
						if k <= 0:
							continue
						search["initial_has_move"] = true
						var next: Dictionary = HINT_PLANNER.clone_search(start)
						if not R.apply_move(next, level, src, j, dst, true).is_empty() and R.any_ready(next):
							search["path"] = [{"src": src, "j": j, "dst": dst, "k": k, "head": cols[src][j]}]
							return _root_closed_search_finish(search, "EXIT", "ready")
					search["j"] = j + 1
					search["dst"] = 0
				search["src"] = src + 1
				search["j"] = 0
			if not bool(search["initial_has_move"]):
				return _root_closed_search_finish(search, "UNKNOWN", "ready_pending_collect")
		if not initially_ready and not bool(opts.get("skip_fast_proof", false)):
			if _root_insufficient_stock(start, level):
				return _root_closed_search_finish(search, "CLOSED", "insufficient_stock")
			if _root_inert_swap_only_cycle(start, level):
				return _root_closed_search_finish(search, "CLOSED", "swap_only")
		search["phase"] = "permutation" if not initially_ready and not bool(opts.get("skip_fast_proof", false))\
		and _root_can_merge_permutations(start, level) else "actual"
		var key: String = _root_permutation_key(start) if String(search["phase"]) == "permutation" else _full_state_key(start)
		search["seen"] = {key: 0}
		search["nodes"] = [{"st": start, "parent": -1, "mv": {}, "g": 0, 
			"f": _root_group_lower_bound(start, level) * 2, "tie": - _root_group_value(start), "key": key}]
		search["frontier"] = [0]
	if String(search["method"]) == "dfs":
		return _advance_root_closed_dfs(search, clock_opts, opts)
	while true:
		if _hint_time_expired(clock_opts):
			return _root_closed_search_pause(search)
		var permutation: bool = String(search["phase"]) == "permutation"
		var nodes: Array = search["nodes"]
		if (search["current"] as Dictionary).is_empty():
			if int(search["expanded"]) >= int(opts.get("node_cap", 1 << 60)):
				return _root_closed_search_pause(search)
			if (search["frontier"] as Array).is_empty():
				return _root_closed_search_finish(search, "CLOSED", "permutation" if permutation else "exhausted")
			var id: int = HINT_PLANNER._pop(search["frontier"], nodes)
			var node: Dictionary = nodes[id]
			var node_key: String = String(node["key"])
			if int(search["seen"][node_key]) != int(node["g"]):
				continue
			search["current"] = node["st"]
			search["current_id"] = id
			search["expanded"] = int(search["expanded"]) + 1
			search["src"] = 0
			search["j"] = 0
			search["dst"] = 0
			search["delivery_checked"] = false
		var cur: Dictionary = search["current"]
		var current_id: int = int(search["current_id"])
		if not bool(search["delivery_checked"]):
			search["delivery_checked"] = true
			if current_id > 0 and R.any_ready(cur):
				var node: Dictionary = nodes[current_id]
				search["path"] = HINT_PLANNER._path(int(node["parent"]), nodes, node["mv"])
				search["current"] = {}
				return _root_closed_search_finish(search, "EXIT", "ready")
			var delivery: Dictionary = _root_deposit_move(cur)
			if not delivery.is_empty():
				search["path"] = HINT_PLANNER._path(current_id, nodes, delivery)
				return _root_closed_search_finish(search, "EXIT", "ready")
		var cols: Array = cur["cols"]
		var legal: Dictionary = cur
		if permutation or bool(opts.get("ordinary_only", false)):
			legal = cur.duplicate()
			legal["allow_root_swapping"] = false
		while int(search["src"]) < cols.size():
			var src: int = int(search["src"])
			while int(search["j"]) < (cols[src] as Array[int]).size():
				var j: int = int(search["j"])
				while int(search["dst"]) < cols.size():
					if _hint_time_expired(clock_opts):
						return _root_closed_search_pause(search)
					var dst: int = int(search["dst"])
					search["dst"] = dst + 1
					search["candidates"] = int(search["candidates"]) + 1
					if R.move_info(legal, src, j, dst) <= 0:
						continue

					var next: Dictionary = HINT_PLANNER.clone_search(cur)
					var rec: Dictionary = R.apply_move(next, level, src, j, dst, true)
					if rec.is_empty():
						continue
					var mv: Dictionary = {"src": src, "j": j, "dst": dst}


					if ( not permutation or (next["cols"][dst] as Array[int]).size() == int(next["caps"][dst])) and R.any_ready(next):
						search["path"] = HINT_PLANNER._path(current_id, nodes, mv)
						return _root_closed_search_finish(search, "EXIT", "ready")
					var key: String = _root_permutation_key(next) if permutation else _full_state_key(next)
					var depth: int = int(nodes[current_id]["g"]) + 1
					if (search["seen"] as Dictionary).has(key) and int(search["seen"][key]) <= depth:
						continue
					if int(search["states"]) >= int(search["max_states"]):
						if bool(search["require_complete"]):
							_begin_root_closed_dfs(search)
							return _advance_root_closed_dfs(search, clock_opts, opts)
						search["dst"] = dst
						return _root_closed_search_finish(search, "UNKNOWN", "state_cap")
					var penalty: float = 4.0 if bool(rec.get("root_swapped", false)) else 0.0
					var forbid: Dictionary = opts.get("forbid", {})
					if current_id == 0 and not forbid.is_empty() and is_forbidden(cur, mv, forbid):
						penalty += FORBID_PENALTY
					nodes.append({"st": next, "parent": current_id, "mv": mv, "g": depth, 
						"f": depth + _root_group_lower_bound(next, level) * 2, 
						"tie": - _root_group_value(next) + penalty, "key": key})
					search["seen"][key] = depth
					search["states"] = int(search["states"]) + 1
					HINT_PLANNER._push(search["frontier"], nodes.size() - 1, nodes)
				search["j"] = j + 1
				search["dst"] = 0
			search["src"] = src + 1
			search["j"] = 0
		search["current"] = {}
	return _root_closed_search_result(search)




static func _begin_root_closed_dfs(search: Dictionary) -> void :
	var start: Dictionary = search["start"]
	var key: String = _root_permutation_key(start) if String(search["phase"]) == "permutation" else _full_state_key(start)
	search["method"] = "dfs"
	search["dfs_stack"] = [_root_closed_dfs_frame(start, key, {})]
	search["dfs_active"] = {key: true}
	search["dfs_completed"] = {}
	search["dfs_cache_keys"] = [] as Array[String]
	search["dfs_cache_head"] = 0
	search["dfs_evictions"] = 0
	search["dfs_peak_depth"] = 1
	(search["nodes"] as Array).clear()
	(search["frontier"] as Array).clear()
	(search["seen"] as Dictionary).clear()
	search["current"] = {}
	search["current_id"] = -1


static func _root_closed_dfs_frame(st: Dictionary, key: String, mv: Dictionary) -> Dictionary:
	return {"st": st, "key": key, "mv": mv, "src": 0, "j": 0, "dst": 0, 
		"delivery_checked": false}


static func _root_closed_dfs_path(stack: Array, last: Dictionary) -> Array:
	var path: Array = []
	for i in range(1, stack.size()):
		path.append(stack[i]["mv"])
	if not last.is_empty():
		path.append(last)
	return path




static func _root_closed_dfs_cache(search: Dictionary, key: String) -> void :
	var completed: Dictionary = search["dfs_completed"]
	if completed.has(key):
		return
	var keys: Array[String] = search["dfs_cache_keys"]
	if keys.size() < int(search["max_states"]):
		keys.append(key)
	else:
		var head: int = int(search["dfs_cache_head"])
		completed.erase(keys[head])
		keys[head] = key
		search["dfs_cache_head"] = (head + 1) % keys.size()
		search["dfs_evictions"] = int(search["dfs_evictions"]) + 1
	completed[key] = true


static func _advance_root_closed_dfs(search: Dictionary, clock_opts: Dictionary, 
		opts: Dictionary) -> Dictionary:
	var stack: Array = search["dfs_stack"]
	var active: Dictionary = search["dfs_active"]
	var completed: Dictionary = search["dfs_completed"]
	var level: JuiceLevel = search["level"] as JuiceLevel
	var permutation: bool = String(search["phase"]) == "permutation"
	while not stack.is_empty():
		if _hint_time_expired(clock_opts):
			return _root_closed_search_pause(search)
		var frame: Dictionary = stack[-1]
		var cur: Dictionary = frame["st"]
		if not bool(frame["delivery_checked"]):
			if int(search["expanded"]) >= int(opts.get("node_cap", 1 << 60)):
				return _root_closed_search_pause(search)
			frame["delivery_checked"] = true
			search["expanded"] = int(search["expanded"]) + 1
			if stack.size() > 1 and R.any_ready(cur):
				search["path"] = _root_closed_dfs_path(stack, {})
				return _root_closed_search_finish(search, "EXIT", "ready")
			var delivery: Dictionary = _root_deposit_move(cur)
			if not delivery.is_empty():
				search["path"] = _root_closed_dfs_path(stack, delivery)
				return _root_closed_search_finish(search, "EXIT", "ready")
		var cols: Array = cur["cols"]
		var legal: Dictionary = cur
		if permutation or bool(opts.get("ordinary_only", false)):
			legal = cur.duplicate()
			legal["allow_root_swapping"] = false
		var pushed: bool = false
		while int(frame["src"]) < cols.size() and not pushed:
			var src: int = int(frame["src"])
			while int(frame["j"]) < (cols[src] as Array[int]).size() and not pushed:
				var j: int = int(frame["j"])
				while int(frame["dst"]) < cols.size():
					if _hint_time_expired(clock_opts):
						return _root_closed_search_pause(search)
					var dst: int = int(frame["dst"])
					frame["dst"] = dst + 1
					search["candidates"] = int(search["candidates"]) + 1
					if R.move_info(legal, src, j, dst) <= 0:
						continue
					var next: Dictionary = HINT_PLANNER.clone_search(cur)
					if R.apply_move(next, level, src, j, dst, true).is_empty():
						continue
					var mv: Dictionary = {"src": src, "j": j, "dst": dst}
					if ( not permutation or (next["cols"][dst] as Array[int]).size() == int(next["caps"][dst])) and R.any_ready(next):
						search["path"] = _root_closed_dfs_path(stack, mv)
						return _root_closed_search_finish(search, "EXIT", "ready")
					var key: String = _root_permutation_key(next) if permutation else _full_state_key(next)
					if active.has(key) or completed.has(key):
						continue
					stack.append(_root_closed_dfs_frame(next, key, mv))
					active[key] = true
					search["states"] = int(search["states"]) + 1
					search["dfs_peak_depth"] = maxi(int(search["dfs_peak_depth"]), stack.size())
					pushed = true
					break
				if not pushed:
					frame["j"] = j + 1
					frame["dst"] = 0
			if not pushed:
				frame["src"] = src + 1
				frame["j"] = 0
		if pushed:
			continue
		var key: String = String(frame["key"])
		_root_closed_dfs_cache(search, key)
		active.erase(key)
		stack.pop_back()
	return _root_closed_search_finish(search, "CLOSED", "permutation" if permutation else "exhausted")



static func resume_root_closed_search(search: Dictionary, max_states: int) -> bool:
	if String(search.get("status", "")) != "UNKNOWN" or String(search.get("reason", "")) != "state_cap"\
	or max_states <= int(search.get("max_states", 0)):
		return false
	search["max_states"] = mini(64000, max_states)
	if int(search["max_states"]) <= int(search["states"]):
		return false
	search["done"] = false
	search["reason"] = ""
	return true


static func _root_closed_search_pause(search: Dictionary) -> Dictionary:
	search["status"] = "UNKNOWN"
	search["reason"] = "deadline"
	return _root_closed_search_result(search)


static func _root_closed_search_finish(search: Dictionary, status: String, 
		reason: String) -> Dictionary:
	search["done"] = true
	search["status"] = status
	search["reason"] = reason
	return _root_closed_search_result(search)


static func _root_closed_search_result(search: Dictionary) -> Dictionary:
	var status: String = String(search.get("status", "UNKNOWN"))
	return {"closed": status == "CLOSED", "completed": true, "status": status, 
		"continuable": not bool(search.get("done", true)), 
		"recoverable": status == "UNKNOWN" and String(search.get("reason", "")) == "state_cap"
			and int(search.get("max_states", 0)) < 64000, "reason": String(search.get("reason", "")), 
		"states": int(search.get("states", 0)), "expanded": int(search.get("expanded", 0)), 
		"candidates": int(search.get("candidates", 0)), "path": (search.get("path", []) as Array).duplicate(true)}





static func _root_inert_swap_only_cycle(st: Dictionary, level: JuiceLevel) -> bool:
	if level == null or not bool(st.get("allow_root_swapping", false)) or level.has_sunlight():
		return false
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var jars: Array[int] = st["jars"]
	var gone: Array[bool] = st["gone"]
	var locks: Array = st["locks"]
	if cols.size() != caps.size() or cols.size() != jars.size()\
	or cols.size() != gone.size() or cols.size() != locks.size():
		return false
	var movable: Array[int] = []
	var max_cap: int = 0
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		if R.is_frozen_pot(st, ci):
			return false
		for fruit_type: int in col:
			if JuiceLevel.is_frozen(fruit_type):
				return false
		if gone[ci]:
			if caps[ci] != 0 or not col.is_empty():
				return false
			continue
		if caps[ci] <= 0:
			return false
		if col.size() > caps[ci]:
			return false
		var lock: Dictionary = locks[ci]
		if not lock.is_empty():
			if String(lock.get("condition", "")) not in [JuiceLevel.LOCK_COLLECT_COUNT, JuiceLevel.LOCK_COLLECT_TYPE]:
				return false
			continue
		if col.is_empty() or JuiceLevel.is_hidden(col[-1]):
			return false
		movable.append(ci)
		max_cap = maxi(max_cap, caps[ci])
	var pure: Dictionary = {}
	for src: int in movable:
		var sc: Array[int] = cols[src]
		var mono: bool = true
		for fruit_type: int in sc:
			if fruit_type != sc[0]:
				mono = false
				break
		if mono:
			var key: String = "%d/%d" % [sc[0], sc.size()]
			pure[key] = int(pure.get(key, 0)) + 1
		for dst: int in movable:
			if src == dst:
				continue
			var dc: Array[int] = cols[dst]
			for j in sc.size():
				if not R.is_connection_blocked(st, sc[j]) and not R.is_connection_blocked(st, dc[-1])\
				and R.connection_type(st, sc[j]) == R.connection_type(st, dc[-1])\
				and sc.size() - j + dc.size() <= max_cap:
					return false
	for ci: int in movable:
		if jars[ci] < 0:
			continue
		var key: String = "%d/%d" % [jars[ci], caps[ci]]
		if int(pure.get(key, 0)) == 0:
			continue
		return false
	return true





static func _root_can_merge_permutations(st: Dictionary, level: JuiceLevel) -> bool:
	if level == null or not bool(st.get("allow_root_swapping", false)):
		return false
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var locks: Array = st["locks"]
	var gone: Array[bool] = st["gone"]
	if cols.is_empty() or cols.size() != caps.size() or cols.size() != locks.size() or cols.size() != gone.size():
		return false
	var cap: int = 0
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		if gone[ci]:
			if caps[ci] != 0 or not col.is_empty():
				return false
			continue
		if caps[ci] <= 0 or col.size() > caps[ci]:
			return false
		var lock: Dictionary = locks[ci]
		if not lock.is_empty():
			if String(lock.get("condition", "")) not in [JuiceLevel.LOCK_COLLECT_COUNT, JuiceLevel.LOCK_COLLECT_TYPE]:
				return false
			continue
		if not col.is_empty() and JuiceLevel.is_hidden(col[-1]):
			return false
		if cap == 0:
			cap = caps[ci]
		if caps[ci] != cap:
			return false
	return cap > 0



static func run_closed_cycle_task(st: Dictionary, level: JuiceLevel, 
		result: Dictionary) -> void :
	var opts: Dictionary = {}
	if bool(st.get("allow_root_swapping", false)):
		opts = {"now": Time.get_ticks_msec, "deadline": Time.get_ticks_msec() + 120}
	result["closed"] = is_closed_cycle(st, level, opts)
	result["completed"] = true















const FILL_POT_MAX_PLACEMENTS: int = 64
const FILL_POT_CLOSED_MS: int = 10
const FILL_POT_TOTAL_MS: int = 60




static func complete_column_checked(st: Dictionary, level: JuiceLevel, order: Array, 
		opts: Dictionary = {}) -> Dictionary:
	if st.is_empty() or level == null or order.is_empty():
		return {}
	var now_ms: Callable = opts.get("now", Callable())
	var now_us: Callable = opts.get("now_us", Callable())
	var max_placements: int = maxi(1, int(opts.get("max_placements", FILL_POT_MAX_PLACEMENTS)))
	var closed_ms: int = maxi(0, int(opts.get("closed_ms", FILL_POT_CLOSED_MS)))
	var total_ms: int = maxi(0, int(opts.get("total_ms", FILL_POT_TOTAL_MS)))
	var started_us: int = _fill_pot_clock_us(now_us)
	var started_ms: int = int(now_ms.call()) if now_ms.is_valid() else -1
	var timing: Dictionary = {"build_us": 0, "finalize_us": 0, "check_us": 0, 
		"tried_cols": 0, "placements": 0, "closed_checks": 0, "budget_hit": false}
	var fallback: Dictionary = {}
	var seed_base: int = R.state_key(st).hash() & 2147483647

	for reveal_target: bool in [false, true]:
		for ci_value: Variant in order:
			var ci: int = int(ci_value)

			if reveal_target and not _fill_pot_can_reveal(st, ci):
				continue
			timing["tried_cols"] = int(timing["tried_cols"]) + 1
			for attempt: int in max_placements:

				if bool(timing["budget_hit"]) and not fallback.is_empty():
					timing["total_us"] = _fill_pot_clock_us(now_us) - started_us
					return fallback
				var t_build: int = _fill_pot_clock_us(now_us)
				var built: Dictionary = R.build_complete_column_state(st, level, ci, 
					reveal_target, (seed_base + attempt * 7919) & 2147483647)
				timing["build_us"] = int(timing["build_us"])\
				+ _fill_pot_clock_us(now_us) - t_build
				if built.is_empty():

					break
				timing["placements"] = int(timing["placements"]) + 1
				var t_finalize: int = _fill_pot_clock_us(now_us)
				var rec: Dictionary = R.finalize_complete_column(built["state"] as Dictionary, 
					level, built["revealed_target"] as Array)
				timing["finalize_us"] = int(timing["finalize_us"])\
				+ _fill_pot_clock_us(now_us) - t_finalize
				var t_check: int = _fill_pot_clock_us(now_us)
				var verdict: String = _fill_pot_verdict(built["state"] as Dictionary, level, 
					now_ms, closed_ms, total_ms, started_ms, timing)
				timing["check_us"] = int(timing["check_us"])\
				+ _fill_pot_clock_us(now_us) - t_check
				var candidate: Dictionary = {"state": built["state"], "mapping": built["mapping"], 
					"rec": rec, "target": ci, "fallback": false, "timing": timing}
				if verdict.is_empty():
					timing["total_us"] = _fill_pot_clock_us(now_us) - started_us
					return candidate
				if fallback.is_empty():

					candidate["fallback"] = true
					candidate["dead_reason"] = verdict
					fallback = candidate
	if fallback.is_empty():
		return {}
	timing["total_us"] = _fill_pot_clock_us(now_us) - started_us
	return fallback




static func _fill_pot_can_reveal(st: Dictionary, ci: int) -> bool:
	var cols: Array = st.get("cols", [])
	var jars: Array = st.get("jars", [])
	var caps: Array = st.get("caps", [])
	var gone: Array = st.get("gone", [])
	var locks: Array = st.get("locks", [])
	if ci < 0 or ci >= cols.size() or ci >= jars.size():
		return false
	var jar: int = int(jars[ci])
	if jar < 0:
		return false
	for source_ci: int in cols.size():
		if source_ci >= caps.size() or source_ci >= gone.size():
			continue
		if bool(gone[source_ci]) or int(caps[source_ci]) <= 0:
			continue

		if source_ci != ci and source_ci < locks.size()\
		and not (locks[source_ci] as Dictionary).is_empty():
			continue
		for value: Variant in (cols[source_ci] as Array):
			var type_id: int = int(value)
			if JuiceLevel.is_hidden(type_id) and JuiceLevel.true_type(type_id) == jar:
				return true
	return false




static func _fill_pot_verdict(state: Dictionary, level: JuiceLevel, now_ms: Callable, 
		closed_ms: int, total_ms: int, started_ms: int, timing: Dictionary) -> String:
	if R.is_win(state, level):
		return ""
	if not R.has_any_move(state):
		return "stuck"
	if R.is_doomed(state, level):
		return "doomed"
	if bool(timing.get("budget_hit", false)):
		return ""
	if now_ms.is_valid() and total_ms > 0 and started_ms >= 0\
	and int(now_ms.call()) - started_ms >= total_ms:
		timing["budget_hit"] = true
		return ""
	var closed_opts: Dictionary = {"now": now_ms}
	if now_ms.is_valid() and closed_ms > 0:
		closed_opts["deadline"] = int(now_ms.call()) + closed_ms
	var closed: bool = is_closed_cycle(state, level, closed_opts)
	timing["closed_checks"] = int(timing["closed_checks"]) + 1
	if bool(closed_opts.get("aborted", false)):
		timing["budget_hit"] = true
		return ""
	return "loop" if closed else ""



static func _fill_pot_clock_us(now: Callable) -> int:
	return int(now.call()) if now.is_valid() else 0




class HintProgress extends RefCounted:
	var _mutex: Mutex = Mutex.new()
	var _version: int = 0
	var _latest: Dictionary = {}

	func publish(hint: Dictionary, phase: String, elapsed_ms: int, expanded: int) -> void :
		var snapshot: Dictionary = {"hint": hint.duplicate(true), "phase": phase, 
			"elapsed_ms": elapsed_ms, "expanded": expanded}
		_mutex.lock()
		_version += 1
		snapshot["version"] = _version
		_latest = snapshot
		_mutex.unlock()

	func read(after_version: int = -1) -> Dictionary:
		if not _mutex.try_lock():
			return {}


		var snapshot: Dictionary = _latest if _version > after_version else {}
		_mutex.unlock()
		return snapshot.duplicate(true)






static func run_checked_hint_task(st: Dictionary, level: JuiceLevel, hint_opts: Dictionary, 
		result: Dictionary) -> void :
	if bool(st.get("allow_root_swapping", false)) and level != null:
		_run_root_hint_task(st, level, hint_opts, result)
		return
	result.merge({"hint": {}, "reachability": Reachability.UNKNOWN, "hint_source": "", 
		"stop_reason": "invalid_state", "elapsed_ms": 0, "routes": 0, 
		"search_trace": [], "completed": false}, true)
	if st.is_empty() or level == null:
		result["completed"] = true
		return
	var clock: Callable = hint_opts.get("now", Time.get_ticks_msec)
	var started: int = int(clock.call())
	var budget_ms: int = maxi(1, int(hint_opts.get("ms_cap", 800)))
	var deadline: int = mini(started + budget_ms, int(hint_opts.get("deadline", started + budget_ms)))
	var death_first_ms: int = maxi(0, int(hint_opts.get("death_first_ms", 50)))
	var death_last_ms: int = maxi(0, int(hint_opts.get("death_last_ms", 70)))
	result["budget_ms"] = budget_ms
	var cancel: Semaphore = hint_opts.get("cancel", null)
	var cancelled: Array[bool] = [false]
	var now: Callable = func() -> int:
		if cancel != null and cancel.try_wait():
			cancelled[0] = true
		return (1 << 60) if cancelled[0] else int(clock.call())
	now.call()
	if cancelled[0]:
		result["stop_reason"] = "cancelled"
		result["completed"] = true
		return
	if R.is_win(st, level):
		result["reachability"] = Reachability.WINNABLE
		result["stop_reason"] = "resolved"
		result["completed"] = true
		return
	var progress: HintProgress = hint_opts.get("progress", null)
	var trace: Array = result["search_trace"]

	var death_search: Dictionary = begin_full_search(st, level)
	var reachability: int = int(death_search["result"])
	var death_nodes: int = maxi(0, int(hint_opts.get("death_node_cap", 3000)))
	var death_states: int = maxi(1, int(hint_opts.get("death_state_cap", 8000)))
	if death_first_ms > 0 and int(now.call()) < deadline:
		reachability = advance_full_search(death_search, level, {"now": now, 
			"deadline": mini(deadline, started + death_first_ms), "clock_every": 1, 
			"node_cap": death_nodes, "state_cap": death_states})
	var first_death: Dictionary = full_search_summary(death_search)
	first_death.merge({"phase": "death_first", "elapsed_ms": int(clock.call()) - started, 
		"reachability": reachability}, true)
	trace.append(first_death)
	if reachability == Reachability.UNWINNABLE and not cancelled[0]:
		result["reachability"] = reachability
		result["stop_reason"] = "dead"
		result["elapsed_ms"] = int(clock.call()) - started
		result["completed"] = true
		return

	var hint_deadline: int = deadline - mini(death_last_ms, maxi(0, deadline - int(clock.call())))\
	if reachability == Reachability.UNKNOWN else deadline
	var checks: Dictionary = {"candidates": 0, "rejected": 0, "safety_ms": 0, "reasons": {}}
	var verify: Callable = func(path: Array, ms: int) -> Dictionary:
		var t: int = int(clock.call())
		var opt: Dictionary = {"now": now, "deadline": mini(hint_deadline, t + maxi(1, ms))}
		var checked: Dictionary = _checked_path_hint(st, level, path, opt)
		checks["candidates"] = int(checks["candidates"]) + 1
		checks["safety_ms"] = int(checks["safety_ms"]) + int(clock.call()) - t
		if checked.is_empty():
			checks["rejected"] = int(checks["rejected"]) + 1
			var reason: String = String(opt.get("check_stop", "unknown"))
			var reasons: Dictionary = checks["reasons"]
			reasons[reason] = int(reasons.get(reason, 0)) + 1
		return {"hint": checked, "stop": opt.get("check_stop", "")}
	var opts: Dictionary = {"now": now, "verify": verify, 
		"state_cap": int(hint_opts.get("state_cap", 24000)), 
		"shorten_nodes": int(hint_opts.get("shorten_nodes", 100000))}
	var forbid: Dictionary = hint_opts.get("forbid", {})
	opts["rank"] = func(cur: Dictionary, moves: Array, first: bool) -> void :
		_sort_first_layer(cur, moves, forbid if first else {})
	var local: Dictionary = {}
	var fast_deadline: int = mini(hint_deadline, int(clock.call()) + maxi(0, int(hint_opts.get("fast_ms", 80))))
	if int(now.call()) < fast_deadline:
		var direct: Dictionary = HINT_PLANNER.clone_search(st)
		for mv: Dictionary in HINT_PLANNER.all_moves(direct):
			if int(now.call()) >= fast_deadline:
				break
			var rec: Dictionary = R.apply_move(direct, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
			var ready: bool = R.any_ready(direct)
			HINT_PLANNER.undo_search(direct, rec)
			if ready:
				local = verify.call([mv], maxi(1, fast_deadline - int(now.call())))["hint"]
				if not local.is_empty():
					break
	var fast_stats: Dictionary = {}
	if local.is_empty() and int(now.call()) < fast_deadline:
		hint_win_path(st, level, {"now": now, "deadline": fast_deadline, 
			"goal_done": mini(level.groups_total, int(st["done"]) + 1), "safe_hint": true, 
			"clock_every": 1, "width": int(hint_opts.get("width", 6)), 
			"route_nodes": int(hint_opts.get("route_nodes", 6000)), 
			"route_depth": maxi(32, level.capacity * 8), 
			"max_routes": int(hint_opts.get("max_routes", 2000)), "stats": fast_stats})
		local = fast_stats.get("local", {})
	trace.append({"phase": "one_pot_fast", "elapsed_ms": int(clock.call()) - started, 
		"steps": int(local.get("len", 0)), "routes": fast_stats.get("routes", 0)})
	var expanded: int = 0
	if local.is_empty() and not cancelled[0] and int(now.call()) < hint_deadline:
		var find: Dictionary = HINT_PLANNER.begin_find(st, level, opts)
		while not bool(find["done"]) and not cancelled[0] and int(now.call()) < hint_deadline:
			HINT_PLANNER.advance_find(find, 8, hint_deadline)
		local = find["hint"]
		expanded = int(find["expanded"])
		trace.append({"phase": "one_pot_find", "expanded": expanded, 
			"rounds": find["rounds"], "stop": find["stop"] if bool(find["done"]) else "deadline", 
			"steps": int(local.get("len", 0))})
	var first_ms: int = int(clock.call()) - started
	result["first_ms"] = first_ms
	var shortened: Dictionary = {}
	var hint_source: String = "local"
	if not local.is_empty() and not cancelled[0]:
		if progress != null:
			progress.publish(local, "shorten", first_ms, expanded)
		var optimize_deadline: int = mini(hint_deadline, 
			started + maxi(0, int(hint_opts.get("shorten_ms", budget_ms))))
		var previous_len: int = int(local["len"])
		if int(now.call()) < optimize_deadline:
			shortened = HINT_PLANNER.begin_shortening(st, level, local, opts)
		else:
			shortened = {"done": true, "stop": "deadline", "hint": local, 
				"expanded": 0, "generated": 0, "improvements": 0}
		while not bool(shortened["done"]) and not cancelled[0]:
			HINT_PLANNER.advance_shortening(shortened, 8, optimize_deadline)
			local = shortened["hint"]
			if int(local["len"]) < previous_len:
				previous_len = int(local["len"])
				if progress != null:
					progress.publish(local, "shorten", int(clock.call()) - started, expanded + int(shortened["expanded"]))

			now.call()
		trace.append({"phase": "one_pot_shorten", "expanded": shortened["expanded"], 
			"states": shortened["generated"], "improvements": shortened["improvements"], 
			"stop": shortened["stop"], "steps": local["len"]})


		var goal_done: int = mini(level.groups_total, int(st["done"]) + 3)
		var prefix: Array = local["path"]
		var after: Dictionary = {}
		if int(now.call()) < optimize_deadline:
			after = _replay(st, level, prefix, true, {"now": now, "deadline": optimize_deadline})
		if not after.is_empty() and int(now.call()) < optimize_deadline:
			if progress != null:
				progress.publish(local, "three_pot_extend", int(clock.call()) - started, expanded + int(shortened["expanded"]))
			var three_stats: Dictionary = {}
			var three_opts: Dictionary = {"now": now, "deadline": optimize_deadline, 
				"goal_done": goal_done, "safe_hint": true, "clock_every": 1, 
				"width": int(hint_opts.get("width", 6)), 
				"route_nodes": int(hint_opts.get("route_nodes", 6000)), 
				"route_depth": maxi(32, level.capacity * 8), 
				"max_routes": int(hint_opts.get("max_routes", 2000)), "stats": three_stats}
			var tail: Array = []
			if int(after["done"]) < goal_done:
				tail = hint_win_path(after, level, three_opts)
			var extended: Dictionary = _checked_three_pot_hint(st, level, prefix + tail, goal_done, three_opts)
			trace.append({"phase": "three_pot_extend", "routes": three_stats.get("routes", 0), 
				"stop": "resolved" if not extended.is_empty() else three_stats.get("stop", "no_path")})
			result["routes"] = int(three_stats.get("routes", 0))
			if extended.is_empty() and int(now.call()) < optimize_deadline:
				three_stats = {}
				three_opts["stats"] = three_stats
				var whole: Array = hint_win_path(st, level, three_opts)
				var candidate: Dictionary = _checked_three_pot_hint(st, level, whole, goal_done, three_opts)
				if not candidate.is_empty() and int(candidate["first_len"]) <= int(local["len"]):
					extended = candidate
				trace.append({"phase": "three_pot_root", "routes": three_stats.get("routes", 0), 
					"stop": "resolved" if not extended.is_empty() else three_stats.get("stop", "no_path")})
				result["routes"] = int(result["routes"]) + int(three_stats.get("routes", 0))
			if not extended.is_empty():
				local = extended
				hint_source = "three_pot"
				if progress != null:
					progress.publish(local, "three_pot", int(clock.call()) - started, expanded + int(shortened["expanded"]))
			now.call()
	if not cancelled[0] and reachability == Reachability.UNKNOWN\
	and death_last_ms > 0 and int(now.call()) < deadline:
		var final_started: int = int(clock.call())
		var resumed_from: Dictionary = full_search_summary(death_search)
		reachability = advance_full_search(death_search, level, {"now": now, 
			"deadline": mini(deadline, final_started + death_last_ms), "clock_every": 1, 
			"node_cap": int(death_search["expanded"]) + death_nodes, 
			"state_cap": (death_search["seen"] as Dictionary).size() + death_states})
		var final_death: Dictionary = full_search_summary(death_search)
		final_death.merge({"phase": "death_last", "elapsed_ms": int(clock.call()) - final_started, 
			"reachability": reachability, "resumed_from": resumed_from}, true)
		trace.append(final_death)
	now.call()
	result["routes"] = int(result["routes"]) + int(fast_stats.get("routes", 0)) + int(checks["candidates"])
	result["elapsed_ms"] = int(clock.call()) - started
	result["safety_stats"] = checks
	trace.append({"phase": "verification", "candidates": checks["candidates"], 
		"rejected": checks["rejected"], "safety_ms": checks["safety_ms"], "reasons": checks["reasons"]})
	result["completed"] = true
	if cancelled[0]:
		result["reachability"] = Reachability.UNKNOWN
		result["stop_reason"] = "cancelled"
		return
	result["reachability"] = reachability
	if reachability == Reachability.UNWINNABLE:
		result["stop_reason"] = "dead"
		return
	result["hint"] = local
	result["hint_source"] = hint_source if not local.is_empty() else ""
	result["stop_reason"] = "resolved" if not local.is_empty() else ("deadline" if int(clock.call()) >= hint_deadline else "no_safe_route")
	if not local.is_empty() and bool(local.get("win_path", false)):
		result["reachability"] = Reachability.WINNABLE




static func _run_root_hint_task(st: Dictionary, level: JuiceLevel, opts: Dictionary, 
		result: Dictionary) -> void :
	var clock: Callable = opts.get("now", Time.get_ticks_msec)
	var started: int = int(clock.call())
	var budget: int = maxi(1, int(opts.get("ms_cap", 800)))
	var deadline: int = mini(started + budget, int(opts.get("deadline", started + budget)))
	var cancelled: Array[bool] = [false]
	var cancel: Semaphore = opts.get("cancel", null)
	var now: Callable = func() -> int:
		if cancel != null and cancel.try_wait():
			cancelled[0] = true
		return (1 << 60) if cancelled[0] else int(clock.call())
	result.merge({"hint": {}, "reachability": Reachability.UNKNOWN, "hint_source": "", 
		"stop_reason": "deadline", "elapsed_ms": 0, "routes": 0, 
		"search_trace": [], "completed": false, "budget_ms": budget}, true)
	var checks: Dictionary = opts.duplicate()
	checks.merge({"now": now, "deadline": deadline, "started": started}, true)
	if bool(opts.get("require_complete", false)):
		checks["deadline"] = 1 << 60
	if R.is_win(st, level) and not _hint_time_expired(checks):
		result["reachability"] = Reachability.WINNABLE
		result["stop_reason"] = "resolved"
	else:
		var search: Dictionary = _find_root_local_hint(st, level, checks)
		var hint: Dictionary = search["hint"]
		result["hint"] = hint
		result["routes"] = search["expanded"]
		result["first_ms"] = search.get("first_ms", int(clock.call()) - started)
		result["first_pot_status"] = search.get("status", "UNKNOWN")
		(result["search_trace"] as Array).append({"phase": "root_first_pot", 
			"expanded": search["expanded"], "states": search["states"], "stop": search["stop"], 
			"status": search.get("status", "UNKNOWN")})
		if not hint.is_empty():
			result["hint_source"] = "root_delivery" if int(hint.get("len", 0)) == 1 else "root_grouping"
			result["stop_reason"] = "resolved"
			if bool(hint.get("win_path", false)):
				result["reachability"] = Reachability.WINNABLE
		elif String(search.get("status", "UNKNOWN")) == "CLOSED":
			result["reachability"] = Reachability.UNWINNABLE
			result["stop_reason"] = "dead"
		else:
			result["stop_reason"] = search["stop"]
	now.call()
	if cancelled[0]:
		result["hint"] = {}
		result["reachability"] = Reachability.UNKNOWN
		result["stop_reason"] = "cancelled"
	result["elapsed_ms"] = int(clock.call()) - started
	result["completed"] = true




static func _root_try_direct_hint(root: Dictionary, cur: Dictionary, level: JuiceLevel, 
		prefix: Array, opts: Dictionary) -> Dictionary:
	for src in (cur["cols"] as Array).size():
		var col: Array[int] = cur["cols"][src]
		if col.is_empty() or JuiceLevel.is_hidden(col[0]) or JuiceLevel.is_frozen(col[0]):
			continue
		var mono: bool = true
		for fruit_type: int in col:
			if fruit_type != col[0]:
				mono = false
				break
		if not mono:
			continue
		for dst in (cur["cols"] as Array).size():
			if _hint_time_expired(opts):
				return {}
			if int(cur["jars"][dst]) != col[0] or int(cur["caps"][dst]) != col.size()\
			or R.move_info(cur, src, 0, dst) <= 0:
				continue
			var mv: Dictionary = {"src": src, "j": 0, "dst": dst}
			var hint: Dictionary = _checked_root_local_hint(root, level, prefix + [mv], opts)
			if not hint.is_empty():
				return hint
	return {}






static func _root_group_lower_bound(st: Dictionary, _level: JuiceLevel) -> int:
	if (st["caps"] as Array).is_empty():
		return 0

	var locks: Array = st.get("locks", [])
	var usable: Array[bool] = []
	var cap: int = 0
	for ci in (st["caps"] as Array).size():
		usable.append( not bool(st["gone"][ci])
			and (ci >= locks.size() or (locks[ci] as Dictionary).is_empty()))

		if bool(st["gone"][ci]):
			continue
		var current_cap: int = int(st["caps"][ci])
		if cap == 0:
			cap = current_cap
		if current_cap != cap or cap <= 0:
			return 0
	if cap <= 0:
		return 0
	var stock: Dictionary = {}
	for ci in (st["jars"] as Array).size():
		var target: int = int(st["jars"][ci])
		if usable[ci] and target >= 0:
			stock[target] = {"count": 0, "runs": [] as Array[int]}
	var prefix_colors: Array[int] = []
	var prefixes: Array[int] = []

	for ci in (st["cols"] as Array).size():
		var col: Array[int] = st["cols"][ci]
		if not usable[ci]:

			prefix_colors.append(-1)
			prefixes.append(0)
			continue
		prefix_colors.append(-1 if col.is_empty() else _hint_type(col[0]))
		prefixes.append(0)
		var i: int = 0
		while i < col.size():
			var color: int = _hint_type(col[i])
			var end: int = i + 1
			while end < col.size() and _hint_type(col[end]) == color:
				end += 1
			var size: int = end - i
			if i == 0:
				prefixes[prefixes.size() - 1] = size
			if stock.has(color):
				stock[color]["count"] = int(stock[color]["count"]) + size
				(stock[color]["runs"] as Array[int]).append(size)
			i = end
	var best: int = LB_IMPOSSIBLE
	for target: int in stock:
		if int(stock[target]["count"]) < cap:
			continue
		var runs: Array[int] = stock[target]["runs"]
		runs.sort()
		runs.reverse()
		for ci in (st["cols"] as Array).size():
			if not usable[ci]:
				continue
			var pre: int = prefixes[ci] if prefix_colors[ci] == target else 0
			var need: int = cap - pre
			var moves: int = int(pre < (st["cols"][ci] as Array).size())
			var skipped_prefix: bool = pre == 0
			for run: int in runs:
				if not skipped_prefix and run == pre:
					skipped_prefix = true
					continue
				if need <= 0:
					break
				need -= run
				moves += 1
			if need <= 0:
				best = mini(best, moves)
	return best



static func _root_group_value(st: Dictionary) -> float:
	var score: float = 0.0
	for ci in (st["cols"] as Array).size():
		var col: Array[int] = st["cols"][ci]
		if col.is_empty():
			score += 3.0
			continue
		var pre: int = 1
		while pre < col.size() and _hint_type(col[pre]) == _hint_type(col[0]):
			pre += 1
		score += float(pre * pre)
		if pre == col.size():
			score += float(pre * pre * 2)
			if pre == int(st["caps"][ci]):
				score += 20.0
	return score





static func _find_root_local_hint(st: Dictionary, level: JuiceLevel, opts: Dictionary) -> Dictionary:
	var result: Dictionary = {"hint": {}, "expanded": 0, "states": 1, "stop": "deadline", 
		"status": "UNKNOWN", "continuable": true}
	var require_complete: bool = bool(opts.get("require_complete", false))
	var output: Dictionary = opts
	if require_complete:
		opts = opts.duplicate()
		opts["deadline"] = 1 << 60
		opts["node_cap"] = 1 << 60
	var preferred: Array = opts.get("preferred_path", [])
	if require_complete and not bool(opts.get("verify_safe", true)) and not preferred.is_empty():

		var local: Dictionary = _checked_root_local_hint(st, level, preferred, opts)
		result["stop"] = opts.get("check_stop", "invalid_path")
		if not local.is_empty():
			result.merge({"hint": local, "status": "EXIT", "stop": "resolved", 
				"continuable": false, "first_ms": _root_hint_clock(opts) - int(opts.get("started", 0))}, true)
			var progress: HintProgress = opts.get("progress", null)
			if progress != null:
				progress.publish(local, "root_first_pot", int(result["first_ms"]), 0)
			return result
		if _hint_time_expired(opts):
			return result

		preferred = []
	if _hint_time_expired(opts):
		return result
	var key: String = root_closed_state_key(st)
	var search: Dictionary = opts.get("root_search", {})
	if search.is_empty() or String(search.get("root_key", "")) != key:
		search = begin_root_closed_search(st, level, int(opts.get("state_cap", 8000 if require_complete else 16000)), require_complete)
		opts["root_search"] = search
		output["root_search"] = search
	result["search"] = search
	var local: Dictionary = {}
	var direct_paths: Array = []
	if not preferred.is_empty():
		direct_paths.append(preferred)
	for mv: Dictionary in HINT_PLANNER.all_moves(st):
		if int(mv["j"]) != 0:
			continue
		var col: Array[int] = st["cols"][int(mv["src"])]
		if col.is_empty() or col.size() != int(st["caps"][int(mv["dst"])])\
		or int(st["jars"][int(mv["dst"])]) != col[0]:
			continue
		var mono: bool = true
		for fruit_type: int in col:
			if fruit_type != col[0] or JuiceLevel.is_hidden(fruit_type) or JuiceLevel.is_frozen(fruit_type):
				mono = false
				break
		if mono:
			direct_paths.append([mv])
	if not direct_paths.is_empty():
		local = _checked_root_local_hint(st, level, direct_paths.pop_front(), opts)
	var started: int = int(opts.get("started", _root_hint_clock(opts)))
	var progress: HintProgress = opts.get("progress", null)
	var node_cap: int = maxi(1, int(opts.get("node_cap", 6000)))
	var initial_expanded: int = int(search["expanded"])
	var optimize_deadline: int = 0
	var first_found: bool = false
	var ranked: int = 0
	while true:
		if not local.is_empty():
			if not first_found:
				result["hint"] = local
				result["first_ms"] = _root_hint_clock(opts) - started
				result["status"] = "EXIT"
				result["stop"] = "resolved"
				first_found = true
				if progress != null:
					progress.publish(local, "root_first_pot", int(result["first_ms"]), int(search["expanded"]))

				var deadline: int = int(opts.get("check_deadline", opts.get("deadline", 0)))
				optimize_deadline = mini(deadline, _root_hint_clock(opts) + maxi(0, int(opts.get("prefer_ms", 12)))) if deadline > 0 else 0
			if not bool(opts.get("verify_safe", true)):
				break
			var ranking: Dictionary = opts.duplicate()
			if optimize_deadline > 0:
				ranking["deadline"] = optimize_deadline
			if not local.has("safe_after") and not _hint_time_expired(ranking):
				var check_safe: Callable = opts.get("check_safe", Callable())
				local["safe_after"] = bool(check_safe.call(ranking)) if check_safe.is_valid()\
				else _root_hint_safe_preference(opts.get("checked_after", {}), level, ranking)
			ranked += 1
			if bool(local.get("safe_after", false)):
				result["hint"] = local
				if progress != null:
					progress.publish(local, "root_preferred", _root_hint_clock(opts) - started, int(search["expanded"]))
				break
			local = {}
			if ranked >= int(opts.get("prefer_candidates", 4)):
				break
			if bool(search.get("done", false)) and String(search["status"]) == "EXIT":
				search["done"] = false
				search["status"] = "UNKNOWN"
				search["path"] = []
		if _hint_time_expired(opts) or (first_found and optimize_deadline > 0 and _root_hint_clock(opts) >= optimize_deadline):
			break
		if not direct_paths.is_empty():
			local = _checked_root_local_hint(st, level, direct_paths.pop_front(), opts)
			continue

		if first_found and int((result["hint"] as Dictionary).get("len", 0)) == 1:
			break
		if int(search["expanded"]) - initial_expanded >= node_cap:
			result["stop"] = "node_cap" if not first_found else "resolved"
			break
		var slice: Dictionary = opts.duplicate()
		slice["node_cap"] = initial_expanded + node_cap
		if first_found and optimize_deadline > 0:
			slice["deadline"] = optimize_deadline
		var found: Dictionary = advance_root_closed_search(search, 8, slice)
		result["expanded"] = found["expanded"]
		result["states"] = found["states"]
		result["continuable"] = found["continuable"]
		if String(found["status"]) == "EXIT":
			local = _checked_root_local_hint(st, level, found["path"], opts)
			if local.is_empty():

				search["done"] = false
				search["status"] = "UNKNOWN"
				search["path"] = []
				if (found["path"] as Array).is_empty():
					break
			continue
		if not bool(found["continuable"]):
			if not first_found:
				result["status"] = found["status"]
				result["stop"] = "exhausted" if String(found["status"]) == "CLOSED" else found["reason"]
			break
		if _hint_time_expired(slice):
			break
	return result


static func _root_hint_clock(opts: Dictionary) -> int:
	var now: Callable = opts.get("now", Callable())
	return int(now.call()) if now.is_valid() else 0



static func _root_hint_safe_preference(after: Dictionary, level: JuiceLevel, opts: Dictionary) -> bool:
	if after.is_empty() or _hint_time_expired(opts):
		return false
	if R.is_win(after, level):
		return true
	var search: Dictionary = begin_root_closed_search(after, level, 256)
	var check: Dictionary = opts.duplicate()
	check["node_cap"] = 128
	var now: Callable = opts.get("now", Callable())
	if now.is_valid():
		var deadline: int = int(opts.get("deadline", 0))
		check["deadline"] = mini(deadline, int(now.call()) + 4) if deadline > 0 else int(now.call()) + 4
	var found: Dictionary = advance_root_closed_search(search, 8, check)
	return String(found["status"]) == "EXIT"




static func _checked_root_local_hint(st: Dictionary, level: JuiceLevel, whole_path: Array, 
		opts: Dictionary) -> Dictionary:
	var output: Dictionary = opts

	if bool(opts.get("require_complete", false)):
		opts = opts.duplicate()

		opts["deadline"] = 1 << 60
	elif int(opts.get("check_deadline", 0)) > int(opts.get("deadline", 0)):
		opts = opts.duplicate()
		opts["deadline"] = int(opts["check_deadline"])

	var check_path: Callable = opts.get("check_path", Callable())
	if check_path.is_valid():
		return check_path.call(whole_path, opts)
	var after: Dictionary = R.clone_state(st)
	var path: Array = []
	var keys: Array[String] = [_full_state_key(after)]
	var positions: Dictionary = {keys[0]: 0}
	for mv: Dictionary in whole_path:
		if _hint_time_expired(opts):
			opts["check_stop"] = "deadline"
			output["check_stop"] = "deadline"
			return {}
		var rec: Dictionary = R.apply_move(after, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if rec.is_empty():
			opts["check_stop"] = "invalid_move"
			output["check_stop"] = "invalid_move"
			return {}
		var key: String = _full_state_key(after)
		if positions.has(key):
			var keep: int = int(positions[key])
			while keys.size() > keep + 1:
				positions.erase(keys.pop_back())
			path.resize(keep)
		else:
			path.append({"src": rec["src"], "j": rec["j"], "dst": rec["dst"], 
				"k": rec["k"], "head": rec["head"], "root_swapped": rec["root_swapped"]})
			positions[key] = path.size()
			keys.append(key)
		var deposits: Array = rec["deposits"]
		if not deposits.is_empty():
			opts["checked_after"] = after
			output["checked_after"] = after
			opts["check_stop"] = "resolved"
			output["check_stop"] = "resolved"
			return {"move": path[0], "col": int(deposits[0]["col"]), "len": path.size(), 
				"optimal": false, "path": path, "win_path": R.is_win(after, level), "root_necessary": false}
	opts["check_stop"] = "no_deposit"
	output["check_stop"] = "no_deposit"
	return {}




static func _checked_three_pot_hint(st: Dictionary, level: JuiceLevel, path: Array, 
		goal_done: int, opts: Dictionary) -> Dictionary:
	var after: Dictionary = R.clone_state(st)
	var applied: Array = []
	var first_col: int = -1
	var first_len: int = 0
	for mv: Dictionary in path:
		if _hint_time_expired(opts):
			return {}
		var rec: Dictionary = R.apply_move(after, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if rec.is_empty():
			return {}
		applied.append(mv)
		if not (rec["deposits"] as Array).is_empty():
			if not _hint_safe_after(after, level, opts):
				return {}
			if first_col < 0:
				first_col = int(rec["deposits"][0]["col"])
				first_len = applied.size()
		if int(after["done"]) >= goal_done:
			return {"move": applied[0], "col": first_col, "len": applied.size(), 
				"first_len": first_len, "optimal": false, "path": applied, 
				"win_path": R.is_win(after, level)}
	return {}





static func _merge_hint_moves(st: Dictionary, level: JuiceLevel, path: Array, 
		deadline: int = 0, now: Callable = Callable()) -> Array:
	var merged: Array = path.duplicate()
	var before: Dictionary = R.clone_state(st)
	var i: int = 0
	while i + 1 < merged.size():
		if deadline > 0 and now.is_valid() and int(now.call()) >= deadline:
			break
		var a: Dictionary = merged[i]
		var b: Dictionary = merged[i + 1]
		var two: Dictionary = R.clone_state(before)
		var first: Dictionary = R.apply_move(two, level, int(a["src"]), int(a["j"]), int(a["dst"]))
		if first.is_empty():
			return path
		if not bool(first.get("root_swapped", false)) and int(b["src"]) == int(a["dst"])\
		and int(b["j"]) == (before["cols"][int(a["dst"])] as Array).size():
			var second: Dictionary = R.apply_move(two, level, int(b["src"]), int(b["j"]), int(b["dst"]))
			if not second.is_empty() and not bool(second.get("root_swapped", false))\
			and int(first["k"]) == int(second["k"]):
				var direct: Dictionary = R.clone_state(before)
				var rec: Dictionary = R.apply_move(direct, level, int(a["src"]), int(a["j"]), int(b["dst"]))
				if not rec.is_empty() and not bool(rec.get("root_swapped", false))\
				and _full_state_key(direct) == _full_state_key(two):
					merged[i] = {"src": rec["src"], "j": rec["j"], "dst": rec["dst"], 
						"k": rec["k"], "head": rec["head"]}
					merged.remove_at(i + 1)
					continue

		R.apply_move(before, level, int(a["src"]), int(a["j"]), int(a["dst"]))
		i += 1
	return merged



static func _checked_path_hint(st: Dictionary, level: JuiceLevel, whole_path: Array, 
		opts: Dictionary = {}) -> Dictionary:
	if bool(st.get("allow_root_swapping", false)):
		return _checked_root_local_hint(st, level, whole_path, opts)
	var after: Dictionary = R.clone_state(st)
	var path: Array = []
	for mv: Dictionary in whole_path:
		if _hint_time_expired(opts):
			opts["check_stop"] = "deadline"
			return {}
		var rec: Dictionary = R.apply_move(after, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
		if rec.is_empty():
			opts["check_stop"] = "invalid_move"
			return {}
		path.append(mv)
		var deposits: Array = rec["deposits"]
		if not deposits.is_empty():
			if not _hint_safe_after(after, level, opts):
				opts["check_stop"] = "deadline" if _hint_time_expired(opts) else "unsafe_after_deposit"
				return {}
			opts["check_stop"] = "resolved"
			return {"move": path[0], "col": int(deposits[0]["col"]), "len": path.size(), 
				"optimal": false, "path": path, "win_path": R.is_win(after, level)}
	opts["check_stop"] = "no_deposit"
	return {}




static func _hint_safe_after(after: Dictionary, level: JuiceLevel, opts: Dictionary) -> bool:
	if _hint_time_expired(opts):
		return false
	if R.is_win(after, level):
		return true
	if not R.has_any_move(after):
		return false


	if bool(after.get("allow_root_swapping", false)) and _root_has_deposit_exit(after, level, opts):
		return true
	var check_opts: Dictionary = {"now": opts.get("now", Callable()), "deadline": opts.get("deadline", 0)}
	var closed: bool = is_closed_cycle(after, level, check_opts)
	return not closed and not bool(check_opts.get("aborted", false)) and not _hint_time_expired(opts)




static func _root_has_deposit_exit(st: Dictionary, level: JuiceLevel, opts: Dictionary) -> bool:
	if _hint_time_expired(opts):
		return false
	var now: Callable = opts.get("now", Callable())
	var deadline: int = int(opts.get("deadline", 0))
	var exit_deadline: int = 0
	if now.is_valid():
		var started: int = int(now.call())
		var window: int = mini(80, maxi(0, (deadline - started) / 2)) if deadline > 0 else 80
		if window <= 0:
			return false
		exit_deadline = started + window
	var checks: Dictionary = {"now": now, "deadline": exit_deadline, "verify_safe": false, 
		"node_cap": 1000, "state_cap": 4000, "depth_cap": maxi(32, level.capacity * 8)}
	if not _root_try_direct_hint(st, st, level, [], checks).is_empty():
		return not _hint_time_expired(opts)


	var ordinary_exit_opts: Dictionary = checks.duplicate()
	if now.is_valid():
		ordinary_exit_opts["deadline"] = mini(exit_deadline, int(now.call()) + 20)
	if _root_ordinary_deposit_exit(st, level, ordinary_exit_opts):
		return not _hint_time_expired(opts)
	if _hint_time_expired(checks):
		return false
	checks["ordinary_only"] = true
	if now.is_valid():
		checks["deadline"] = int(now.call()) + maxi(1, (exit_deadline - int(now.call())) * 3 / 4)
	var search: Dictionary = _find_root_local_hint(st, level, checks)
	if not (search["hint"] as Dictionary).is_empty():
		return not _hint_time_expired(opts)
	checks["deadline"] = exit_deadline
	if not _hint_time_expired(checks):
		checks["ordinary_only"] = false
		search = _find_root_local_hint(st, level, checks)
		if not (search["hint"] as Dictionary).is_empty():
			return not _hint_time_expired(opts)
	return false




static func _root_ordinary_deposit_exit(st: Dictionary, level: JuiceLevel, opts: Dictionary) -> bool:
	if _hint_time_expired(opts):
		return false

	var ordinary: Dictionary = R.clone_state(st.duplicate())
	ordinary["allow_root_swapping"] = false
	var scored: Array = []
	for c: Dictionary in group_candidates(ordinary, level):
		var lb: int = hint_lower_bound(ordinary, int(c["col"]), level)
		if lb < LB_IMPOSSIBLE:
			scored.append({"col": int(c["col"]), "lb": lb, 
				"priority": int(c["score"]) if level.has_sunlight() else 0})
	scored.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["lb"]) != int(b["lb"]):
			return int(a["lb"]) < int(b["lb"])
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) > int(b["priority"])
		return int(a["col"]) < int(b["col"]))
	var ctx: Dictionary = {"level": level, "routes": 0, "route_nodes": 1000, "route_depth": 32, 
		"deadline": opts.get("deadline", 0), "now": opts.get("now", Callable()), "clock_every": 1}
	for candidate: Dictionary in scored:
		if _hint_time_expired(opts):
			return false
		var route: Variant = _hint_route(ordinary, ctx, int(candidate["col"]))
		if not route is Array:
			continue
		var after: Dictionary = R.clone_state(st.duplicate())
		for mv: Dictionary in (route as Array):
			if _hint_time_expired(opts):
				return false
			var rec: Dictionary = R.apply_move(after, level, int(mv["src"]), int(mv["j"]), int(mv["dst"]))
			if rec.is_empty():
				break
			if not (rec["deposits"] as Array).is_empty():
				return not _hint_time_expired(opts)
	return false
