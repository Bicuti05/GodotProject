extends RefCounted


const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const LB_IMPOSSIBLE: int = 1000000

static func _now(opts: Dictionary) -> int:
	return int((opts.now as Callable).call())

static func _expired(opts: Dictionary, deadline: int) -> bool:
	return deadline > 0 and _now(opts) >= deadline


static func clone_search(st: Dictionary) -> Dictionary:
	var nx: Dictionary = st.duplicate()
	var cols: Array = []
	for col: Array[int] in st["cols"]:
		cols.append(col.duplicate())
	nx["cols"] = cols
	return nx
static func search_key(st: Dictionary) -> String:
	var out: String = ""
	for col: Array[int] in st["cols"]:
		for fruit: int in col:
			out += String.chr(fruit + 2)
		out += String.chr(1)
	return out
static func undo_search(st: Dictionary, rec: Dictionary) -> void :
	assert ((rec["deposits"] as Array).is_empty() and (rec["snap"] as Dictionary).is_empty())
	for reveal: Dictionary in rec["revealed"]:
		(st["cols"][int(reveal["col"])] as Array[int])[int(reveal["index"])] = int(reveal["before"])
	var sc: Array[int] = st["cols"][int(rec["src"])]
	var dc: Array[int] = st["cols"][int(rec["dst"])]
	if bool(rec.get("root_swapped", false)):
		st["cols"][int(rec["src"])] = dc
		st["cols"][int(rec["dst"])] = sc
		return
	var k: int = int(rec["k"])
	var begin: int = dc.size() - k
	for i in k:
		sc.append(dc[begin + i])
	dc.resize(begin)
static func all_moves(st: Dictionary) -> Array:
	var out: Array = []
	var cols: Array = st["cols"]
	for src in cols.size():
		for j in (cols[src] as Array).size():
			for dst in cols.size():
				var k: int = R.move_info(st, src, j, dst)
				if k > 0:
					out.append({"src": src, "j": j, "dst": dst, "k": k, "head": cols[src][j]})
	return out


static func lower_bound(st: Dictionary, lv: JuiceLevel = null) -> int:
	if bool(st.get("allow_root_swapping", false)):
		return 0
	if lv != null and lv.has_sunlight():
		return 0
	for col: Array in (st["cols"] as Array):
		for fruit_type: int in col:
			if JuiceLevel.is_frozen(fruit_type):
				return 0
	var cols: Array = st["cols"]
	var goals: Array[int] = []
	var stock: Dictionary = {}
	for ci in cols.size():
		if R.is_locked(st, ci) or R.is_frozen_pot(st, ci) or bool(st["gone"][ci]) or int(st["jars"][ci]) < 0:
			continue
		goals.append(ci)
		stock[int(st["jars"][ci])] = []
	for src in cols.size():
		if bool(st["gone"][src]):
			continue
		var col: Array[int] = cols[src]
		var i: int = 0
		while i < col.size():
			var color: int = JuiceLevel.true_type(col[i])
			var e: int = i + 1
			while e < col.size() and JuiceLevel.true_type(col[e]) == color:
				e += 1
			if stock.has(color):
				(stock[color] as Array).append([src, i, e])
			i = e
	var best: int = LB_IMPOSSIBLE
	for ci: int in goals:
		var col: Array[int] = cols[ci]
		var color: int = int(st["jars"][ci])
		var pre: int = 0
		while pre < col.size() and col[pre] == color:
			pre += 1
		var need: int = int(st["caps"][ci]) - pre
		var runs: Array[int] = []
		for r: Array in stock[color]:
			var length: int = int(r[2]) - (maxi(pre, int(r[1])) if int(r[0]) == ci else int(r[1]))
			if length > 0:
				runs.append(length)
		runs.sort()
		var moves: int = 0
		for i in range(runs.size() - 1, -1, -1):
			if need <= 0:
				break
			need -= runs[i]
			moves += 1
		if need <= 0:
			best = mini(best, moves + (1 if pre < col.size() else 0))
	return best



static func begin_find(st: Dictionary, lv: JuiceLevel, opts: Dictionary) -> Dictionary:
	var cur: Dictionary = clone_search(st)
	var key: String = search_key(cur)
	return {"root": st, "level": lv, "opts": opts, "cur": cur, 
		"stack": [{"rec": {}, "moves": [], "next": 0, "key": key, "prepared": false}], 
		"path": [], "on_path": {key: true}, "depth_limit": maxi(12, lv.capacity * 4), 
		"cutoff": false, "expanded": 0, "rounds": 0, "hint": {}, "done": false, 
		"stop": "searching", "verify_ms": 120}

static func advance_find(job: Dictionary, slice_nodes: int, deadline: int) -> void :
	var cur: Dictionary = job["cur"]
	var stack: Array = job["stack"]
	var path: Array = job["path"]
	var on_path: Dictionary = job["on_path"]
	var until: int = int(job["expanded"]) + maxi(1, slice_nodes)
	while not bool(job["done"]) and int(job["expanded"]) < until and not _expired(job["opts"], deadline):
		if stack.is_empty():
			if not bool(job["cutoff"]):
				job["done"] = true
				job["stop"] = "no_safe_route"
				return
			job["rounds"] = int(job["rounds"]) + 1
			job["depth_limit"] = int(job["depth_limit"]) + 8
			job["cutoff"] = false
			var key: String = search_key(cur)
			stack.append({"rec": {}, "moves": [], "next": 0, "key": key, "prepared": false})
			on_path[key] = true
		var frame: Dictionary = stack.back()
		if not bool(frame["prepared"]):
			frame["moves"] = all_moves(cur)
			(job["opts"]["rank"] as Callable).call(cur, frame["moves"], path.is_empty())
			frame["prepared"] = true
			job["expanded"] = int(job["expanded"]) + 1
		if int(frame["next"]) >= (frame["moves"] as Array).size():
			stack.pop_back()
			on_path.erase(frame["key"])
			if not (frame["rec"] as Dictionary).is_empty():
				undo_search(cur, frame["rec"])
				path.pop_back()
			continue
		var mv: Dictionary = frame["moves"][int(frame["next"])]
		frame["next"] = int(frame["next"]) + 1
		var rec: Dictionary = R.apply_move(cur, job["level"], int(mv["src"]), int(mv["j"]), int(mv["dst"]), true)
		if rec.is_empty():
			continue
		var terminal: bool = false
		if R.any_ready(cur):
			var checked: Dictionary = (job["opts"]["verify"] as Callable).call(path + [mv], int(job["verify_ms"]))
			var hint: Dictionary = checked.get("hint", {})
			if not hint.is_empty():
				undo_search(cur, rec)
				job["hint"] = hint
				job["done"] = true
				job["stop"] = "resolved"
				return
			var stop: String = String(checked.get("stop", ""))
			if stop == "deadline":

				frame["next"] = int(frame["next"]) - 1
				job["verify_ms"] = mini(int(job["verify_ms"]) * 2, 1 << 50)
				undo_search(cur, rec)
				return
			terminal = stop != "no_deposit"
		var key: String = search_key(cur)
		if terminal or on_path.has(key):
			undo_search(cur, rec)
			continue
		if path.size() + 1 >= int(job["depth_limit"]):
			job["cutoff"] = true
			undo_search(cur, rec)
			continue
		path.append(mv)
		on_path[key] = true
		stack.append({"rec": rec, "moves": [], "next": 0, "key": key, "prepared": false})

static func _less(a: int, b: int, nodes: Array) -> bool:
	var na: Dictionary = nodes[a]
	var nb: Dictionary = nodes[b]
	if int(na.f) != int(nb.f):
		return int(na.f) < int(nb.f)
	if float(na.tie) != float(nb.tie):
		return float(na.tie) < float(nb.tie)
	return int(na.g) > int(nb.g) if int(na.g) != int(nb.g) else a > b
static func _push(heap: Array, id: int, nodes: Array) -> void :
	var i: int = heap.size()
	heap.append(id)
	while i > 0:
		var p: int = (i - 1) >> 1
		if not _less(id, int(heap[p]), nodes):
			break
		heap[i] = heap[p]
		i = p
	heap[i] = id
static func _pop(heap: Array, nodes: Array) -> int:
	var top: int = int(heap[0])
	var last: int = int(heap.pop_back())
	if heap.is_empty():
		return top
	var i: int = 0
	while i * 2 + 1 < heap.size():
		var j: int = i * 2 + 1
		if j + 1 < heap.size() and _less(int(heap[j + 1]), int(heap[j]), nodes):
			j += 1
		if not _less(int(heap[j]), last, nodes):
			break
		heap[i] = heap[j]
		i = j
	heap[i] = last
	return top
static func _path(id: int, nodes: Array, move: Dictionary) -> Array:
	var path: Array = [move]
	while int(nodes[id].parent) >= 0:
		path.append(nodes[id].mv)
		id = int(nodes[id].parent)
	path.reverse()
	return path
static func begin_shortening(st: Dictionary, lv: JuiceLevel, seed: Dictionary, opts: Dictionary) -> Dictionary:
	var key: String = search_key(st)
	var lb: int = lower_bound(st, lv)
	var nodes: Array = [{"st": clone_search(st), "key": key, "parent": -1, "mv": {}, "g": 0, "f": lb, 
		"tie": 0.0}]
	return {"root": st, "level": lv, "hint": seed.duplicate(true), "initial_len": int(seed.get("len", 0)), 
		"opts": opts, "nodes": nodes, "heap": [0], 
		"seen": {key: 0}, "expanded": 0, "generated": 0, "rejected": 0, 
		"improvements": 0, "done": false, "stop": "searching", "limited": false, 
		"node_cap": int(opts.get("shorten_nodes", 100000)), "state_cap": int(opts.get("state_cap", 24000)), "verification_ms": 0}

static func advance_shortening(job: Dictionary, slice_nodes: int, deadline: int) -> void :
	if bool(job.done):
		return
	var nodes: Array = job.nodes
	var heap: Array = job.heap
	var seen: Dictionary = job.seen
	var bound: int = int(job.hint["len"])
	var until: int = mini(int(job.node_cap), int(job.expanded) + slice_nodes)
	while not heap.is_empty() and int(job.expanded) < until:
		if _expired(job.opts, deadline):
			job.done = true
			job.stop = "deadline"
			return
		var id: int = _pop(heap, nodes)
		var node: Dictionary = nodes[id]
		if int(node.f) >= bound:
			job.done = true
			job.stop = "bounded_frontier_exhausted" if not bool(job.limited) else "state_cap"
			return
		if int(seen[node.key]) < int(node.g):
			node.st = {}
			continue
		var cur: Dictionary = node.st
		job.expanded = int(job.expanded) + 1
		for mv: Dictionary in all_moves(cur):
			if _expired(job.opts, deadline):
				job.done = true
				job.stop = "deadline"
				return
			var depth: int = int(node.g) + 1
			if depth >= bound:
				continue
			var rec: Dictionary = R.apply_move(cur, job.level, mv.src, mv.j, mv.dst, true)
			if rec.is_empty():
				continue
			var terminal: bool = false
			if R.any_ready(cur):
				var checked: Dictionary = (job.opts.verify as Callable).call(_path(id, nodes, mv), maxi(1, deadline - _now(job.opts)))
				var hint: Dictionary = checked.get("hint", {})
				terminal = String(checked.get("stop", "")) != "no_deposit"
				if not hint.is_empty() and int(hint.len) < bound:
					job.hint = hint
					bound = int(hint.len)
					job.improvements = int(job.improvements) + 1
				elif hint.is_empty():
					job.rejected = int(job.rejected) + 1
			if not terminal:
				var key: String = search_key(cur)
				if not seen.has(key) or int(seen[key]) > depth:
					var lb: int = lower_bound(cur, job.level)
					if depth + lb < bound:
						if int(job.generated) < int(job.state_cap):
							seen[key] = depth
							var child: Dictionary = {"st": clone_search(cur), "parent": id, "mv": mv, 
								"g": depth, "f": depth + lb, "key": key, 
								"tie": 0.0}
							nodes.append(child)
							_push(heap, nodes.size() - 1, nodes)
							job.generated = int(job.generated) + 1
						else:
							job.limited = true
			undo_search(cur, rec)
		node.st = {}
	if heap.is_empty() or int(job.expanded) >= int(job.node_cap):
		job.done = true
		job.stop = "node_cap" if int(job.expanded) >= int(job.node_cap) else ("state_cap" if bool(job.limited) else "bounded_frontier_exhausted")
