class_name JuiceRules
extends RefCounted













































const NO_JAR: = JuiceLevel.NO_JAR



const CASCADE_GUARD: = 40


enum Reject{
	NONE = 0, 
	FULL, 
	COLOR, 
	INVALID, 
	LOCKED, 
	MYSTERY, 
	FROZEN, 
}




static func make_state(level: JuiceLevel) -> Dictionary:
	var cols: Array = []
	var jars: Array[int] = []
	var caps: Array[int] = []
	var gone: Array[bool] = []
	var locks: Array = []
	for i in level.columns:
		var col: Array[int] = (level.board_cols[i] as Array[int]).duplicate()
		cols.append(col)
		jars.append(level.board_jars[i])
		caps.append(level.column_caps[i] if i < level.column_caps.size() else level.capacity)
		gone.append(false)
		locks.append((level.board_locks[i] as Dictionary).duplicate(true))
	var st: Dictionary = {
		"cols": cols, "jars": jars, "caps": caps, "gone": gone, "locks": locks, 
		"done": 0, "cups": [] as Array[int], "late_left": level.late_park, 
		"extra_rope_used": false, "varcap": level.has_variable_caps(), 
		"allow_root_swapping": false, 
		"ice_mode": level.ice_mode, 
	}
	if level.has_frozen_pots():
		st["frozen_pots"] = level.board_frozen_pots.duplicate()
	return st


static func reveal_type(st: Dictionary, type_id: int) -> int:
	var changed: int = 0
	if type_id < 0:
		return changed
	for column: Array in st.get("cols", []) as Array:
		changed += _reveal_column_type(column, type_id)
	return changed

static func _reveal_column_type(column: Array, type_id: int) -> int:
	var changed: int = 0
	for i: int in column.size():
		var value: int = int(column[i])
		if JuiceLevel.is_hidden(value) and JuiceLevel.true_type(value) == type_id:
			column[i] = type_id
			changed += 1
	return changed


static func level_with_revealed_type(level: JuiceLevel, type_id: int) -> JuiceLevel:
	if level == null or type_id < 0:
		return level
	var needs_copy: bool = false
	for column: Array in level.board_cols:
		for value: int in column:
			if JuiceLevel.is_hidden(value) and JuiceLevel.true_type(value) == type_id:
				needs_copy = true
	for entry: Dictionary in level.incoming:
		for value: int in entry["beads"]:
			if JuiceLevel.is_hidden(value) and JuiceLevel.true_type(value) == type_id:
				needs_copy = true
	if not needs_copy:
		return level
	var shown: JuiceLevel = JuiceLevel.from_dict(level.to_dict())
	for column: Array in shown.board_cols:
		_reveal_column_type(column, type_id)
	for entry: Dictionary in shown.incoming:
		_reveal_column_type(entry["beads"], type_id)
	return shown





static func clone_state(st: Dictionary) -> Dictionary:
	var src: Array = st["cols"]
	var cols: Array = []
	cols.resize(src.size())
	for i in src.size():
		cols[i] = (src[i] as Array[int]).duplicate()
	var out: Dictionary = {
		"cols": cols, 
		"jars": (st["jars"] as Array[int]).duplicate(), 
		"caps": (st["caps"] as Array[int]).duplicate(), 
		"gone": (st["gone"] as Array[bool]).duplicate(), 
		"locks": _clone_locks(_locks_for(st)), 
		"done": int(st["done"]), 
		"cups": (st["cups"] as Array[int]).duplicate(), 
		"late_left": int(st["late_left"]), 
		"extra_rope_used": bool(st.get("extra_rope_used", false)), 
		"varcap": bool(st.get("varcap", false)), 
		"allow_root_swapping": bool(st.get("allow_root_swapping", false)), 
		"ice_mode": st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION), 
	}
	if st.has("frozen_pots"):
		out["frozen_pots"] = (st["frozen_pots"] as Array[bool]).duplicate()
	return out




static func is_frozen_pot(st: Dictionary, ci: int) -> bool:
	var flags: Array = st.get("frozen_pots", [])
	return ci >= 0 and ci < flags.size() and bool(flags[ci])




static func _clone_locks(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for lock: Variant in raw as Array:
			out.append((lock as Dictionary).duplicate(true) if lock is Dictionary else {})
	return out


static func _locks_for(st: Dictionary) -> Array:
	var locks: Variant = st.get("locks")
	if locks is Array and (locks as Array).size() == (st["cols"] as Array).size():
		return locks as Array
	var created: Array = []
	for _i in (st["cols"] as Array).size():
		created.append({})
	st["locks"] = created
	return created


static func is_locked(st: Dictionary, ci: int) -> bool:
	var locks: Array = _locks_for(st)
	return ci >= 0 and ci < locks.size() and not (locks[ci] as Dictionary).is_empty()




static func add_rope(st: Dictionary, capacity: int) -> int:
	if bool(st.get("extra_rope_used", false)) or capacity <= 0:
		return -1
	var cols: Array = st.get("cols", [])
	var limit: int = JuiceLevel.MAX_TWO_ROW_COLUMNS if cols.size() > JuiceLevel.MAX_TOTAL_COLUMNS else JuiceLevel.MAX_TOTAL_COLUMNS
	if cols.size() >= limit:
		return -1
	var jars: Array[int] = st.get("jars", [] as Array[int])
	var caps: Array[int] = st.get("caps", [] as Array[int])
	var gone: Array[bool] = st.get("gone", [] as Array[bool])
	var locks: Array = _locks_for(st)
	var ci: int = cols.size()
	if jars.size() != ci or caps.size() != ci or gone.size() != ci or locks.size() != ci:
		return -1
	cols.append([] as Array[int])
	jars.append(NO_JAR)
	caps.append(capacity)
	gone.append(false)
	locks.append({})
	if st.has("frozen_pots"):
		(st["frozen_pots"] as Array[bool]).append(false)
	st["extra_rope_used"] = true
	return ci





static func state_key(st: Dictionary) -> String:
	var out: = ""
	var cols: Array = st["cols"]
	var jars: Array[int] = st["jars"]
	for i in cols.size():
		if i > 0:
			out += "|"
		var col: Array[int] = cols[i]
		for j in col.size():
			if j > 0:
				out += ","
			out += str(col[j])
		out += "#" + str(jars[i])
	out += "@" + str(int(st["done"])) + "/" + str(int(st["late_left"]))

	if bool(st.get("varcap", false)):
		out += "~"
		var caps: Array[int] = st["caps"] as Array[int]
		for i in caps.size():
			if i > 0:
				out += ","
			out += str(caps[i])
	var locks: Array = _locks_for(st)
	var has_lock: bool = false
	var lock_parts: PackedStringArray = []
	for lock: Dictionary in locks:
		if lock.is_empty():
			lock_parts.append("-")
			continue
		has_lock = true
		if String(lock.get("condition", "")) == JuiceLevel.LOCK_COLLECT_TYPE:
			lock_parts.append("t%d:%d" % [int(lock.get("typeId", -1)), int(lock.get("count", 0))])
		else:
			lock_parts.append("c:%d" % int(lock.get("count", 0)))
	out += ("!" + ",".join(lock_parts) if has_lock else "")
	if st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION) == JuiceLevel.ICE_BLOCK_CONNECTION:
		out += "~" + JuiceLevel.ICE_BLOCK_CONNECTION
	if st.has("frozen_pots"):
		out += "^"
		for flag: bool in st["frozen_pots"]:
			out += "1" if flag else "0"
	if bool(st.get("allow_root_swapping", false)):
		out += "~root_swap"
	return out





static func bottom_of(col: Array) -> int:
	return -1 if col.is_empty() else int(col[col.size() - 1])



static func is_park(st: Dictionary, ci: int) -> bool:
	return int((st["jars"] as Array[int])[ci]) < 0









static func is_connection_blocked(st: Dictionary, fruit_type: int) -> bool:
	return JuiceLevel.is_hidden(fruit_type) or (JuiceLevel.is_frozen(fruit_type)
		and st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION) == JuiceLevel.ICE_BLOCK_CONNECTION)


static func connection_type(st: Dictionary, fruit_type: int) -> int:
	return fruit_type if is_connection_blocked(st, fruit_type) else JuiceLevel.connection_type(fruit_type)




static func is_root_swap(st: Dictionary, src: int, j: int, dst: int) -> bool:
	var cols: Array = st["cols"]
	var candidate: bool = bool(st.get("allow_root_swapping", false)) and j == 0 and src != dst\
	and src >= 0 and dst >= 0 and src < cols.size() and dst < cols.size()\
	and not (cols[src] as Array).is_empty() and not (cols[dst] as Array).is_empty()
	if not candidate:
		return false
	var sc: Array[int] = cols[src]
	var dc: Array[int] = cols[dst]
	var can_connect: bool = sc.size() + dc.size() <= int((st["caps"] as Array[int])[dst])\
	and not is_connection_blocked(st, sc[0]) and not is_connection_blocked(st, dc[-1])\
	and connection_type(st, sc[0]) == connection_type(st, dc[-1])
	return not can_connect


static func move_info(st: Dictionary, src: int, j: int, dst: int) -> int:
	if src == dst:
		return 0
	var cols: Array = st["cols"]
	if src < 0 or dst < 0 or src >= cols.size() or dst >= cols.size():
		return 0
	if is_locked(st, src) or is_locked(st, dst):
		return 0
	var sc: Array[int] = cols[src]
	var dc: Array[int] = cols[dst]
	var k: int = sc.size() - j
	if j < 0 or k <= 0:
		return 0
	if is_root_swap(st, src, j, dst):
		var caps: Array[int] = st["caps"]
		var gone: Array[bool] = st["gone"]
		if gone[src] or gone[dst] or caps[src] <= 0 or caps[dst] <= 0:
			return 0
		return k if sc.size() <= caps[dst] and dc.size() <= caps[src] else 0
	if dc.size() + k > int((st["caps"] as Array[int])[dst]):
		return 0
	if dc.is_empty():
		return k
	if is_connection_blocked(st, sc[j]) or is_connection_blocked(st, dc[dc.size() - 1]):
		return 0
	return k if connection_type(st, dc[dc.size() - 1]) == connection_type(st, sc[j]) else 0









static func reject_reason(st: Dictionary, src: int, j: int, dst: int) -> Reject:
	if move_info(st, src, j, dst) > 0:
		return Reject.NONE
	var cols: Array = st["cols"]

	if src == dst or src < 0 or dst < 0 or src >= cols.size() or dst >= cols.size():
		return Reject.INVALID
	var sc: Array[int] = cols[src]
	var k: int = sc.size() - j
	if j < 0 or k <= 0:
		return Reject.INVALID



	var dc: Array[int] = cols[dst]
	if is_locked(st, src) or is_locked(st, dst):
		return Reject.LOCKED
	if is_root_swap(st, src, j, dst):
		return Reject.FULL
	if dc.size() + k > int((st["caps"] as Array[int])[dst]):
		return Reject.FULL


	if JuiceLevel.is_hidden(sc[j]):
		return Reject.MYSTERY
	if st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION) == JuiceLevel.ICE_BLOCK_CONNECTION\
	and (JuiceLevel.is_frozen(sc[j]) or JuiceLevel.is_frozen(dc[dc.size() - 1])):
		return Reject.FROZEN
	return Reject.COLOR





















static func useful_moves(st: Dictionary) -> Array:

	if bool(st.get("allow_root_swapping", false)):
		var moves: Array = []
		var swap_cols: Array = st["cols"]
		for src in swap_cols.size():
			for j in (swap_cols[src] as Array).size():
				for dst in swap_cols.size():
					var k: int = move_info(st, src, j, dst)
					if k > 0:
						moves.append({"src": src, "j": j, "dst": dst, "k": k, 
							"head": swap_cols[src][j]})
		return moves
	var out: Array = []
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var n: int = cols.size()
	var locks: Array = _locks_for(st)


	var room: PackedInt32Array = PackedInt32Array()
	var need: PackedInt32Array = PackedInt32Array()
	room.resize(n)
	need.resize(n)
	for d in n:
		var dc: Array[int] = cols[d]
		room[d] = 0 if not (locks[d] as Dictionary).is_empty() else caps[d] - dc.size()
		need[d] = -1 if dc.is_empty() else connection_type(st, dc[dc.size() - 1])

	for i in n:
		if not (locks[i] as Dictionary).is_empty():
			continue
		var b: Array[int] = cols[i]
		var sz: int = b.size()


		var has_special: bool = false
		for fruit_type: int in b:
			if JuiceLevel.is_hidden(fruit_type) or JuiceLevel.is_frozen(fruit_type):
				has_special = true
				break
		if has_special:
			for j in sz:
				for d in n:
					var k: int = move_info(st, i, j, d)
					if k > 0:
						out.append({"src": i, "j": j, "dst": d, "k": k, "head": b[j]})
			continue

		var s: int = 0
		while s < sz:
			var head: int = b[s]
			var e: int = s
			while e + 1 < sz and b[e + 1] == head:
				e += 1
			var k_min: int = sz - e
			for d in n:
				if d == i or k_min > room[d]:
					continue
				var nd: int = need[d]
				if nd != -1 and (JuiceLevel.is_hidden(head) or nd != head):
					continue

				var j_big: int = maxi(s, sz - room[d])
				out.append({"src": i, "j": j_big, "dst": d, "k": sz - j_big, "head": head})
				if e != j_big:
					out.append({"src": i, "j": e, "dst": d, "k": k_min, "head": head})
			s = e + 1
	return out







static func has_any_move(st: Dictionary) -> bool:
	if bool(st.get("allow_root_swapping", false)):
		var swap_cols: Array = st["cols"]
		for src in swap_cols.size():
			for j in (swap_cols[src] as Array).size():
				for dst in swap_cols.size():
					if move_info(st, src, j, dst) > 0:
						return true
		return false
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var n: int = cols.size()
	var locks: Array = _locks_for(st)
	for i in n:
		if not (locks[i] as Dictionary).is_empty():
			continue
		var b: Array[int] = cols[i]
		if b.is_empty():
			continue
		for d in n:
			if d == i or not (locks[d] as Dictionary).is_empty():
				continue
			var dc: Array[int] = cols[d]
			var room: int = caps[d] - dc.size()
			if room <= 0:
				continue
			if dc.is_empty():
				return true
			var need: int = connection_type(st, dc[dc.size() - 1])
			if is_connection_blocked(st, dc[dc.size() - 1]):
				continue
			var scan_index: int = b.size() - 1
			while scan_index >= 0 and b.size() - scan_index <= room:
				if not is_connection_blocked(st, b[scan_index])\
				and connection_type(st, b[scan_index]) == need:
					return true
				scan_index -= 1
	return false






static func progress_at(st: Dictionary, ci: int) -> int:
	if is_locked(st, ci):
		return 0
	var jar: int = int((st["jars"] as Array[int])[ci])
	var col: Array[int] = (st["cols"] as Array)[ci]
	if jar < 0 or col.is_empty():
		return 0
	var k: int = 0
	while k < col.size() and JuiceLevel.connection_type(col[k]) == jar:
		k += 1
	return mini(k, int((st["caps"] as Array[int])[ci]))




static func deposit_ready(st: Dictionary, ci: int) -> int:
	if is_locked(st, ci) or is_frozen_pot(st, ci):
		return 0
	var jar: int = int((st["jars"] as Array[int])[ci])
	if jar < 0:
		return 0
	var col: Array[int] = (st["cols"] as Array)[ci]
	var cap: int = int((st["caps"] as Array[int])[ci])
	if col.size() != cap or cap <= 0:
		return 0
	for v in col:
		if JuiceLevel.is_frozen(v):
			return 0
		if v != jar:
			return 0
	return cap


static func any_ready(st: Dictionary) -> bool:
	for ci in (st["cols"] as Array).size():
		if deposit_ready(st, ci) > 0:
			return true
	return false



static func type_counts(st: Dictionary, types: int) -> Array[int]:
	var m: Array[int] = []
	m.resize(types)
	m.fill(0)
	for col in (st["cols"] as Array):
		for t in (col as Array[int]):
			var actual: int = JuiceLevel.true_type(t)
			if actual >= 0 and actual < types:
				m[actual] += 1
	return m















static func place_batch(st: Dictionary, types_in: Array[int], cleared_ci: int) -> Array:
	var cols: Array = st["cols"]
	var caps: Array[int] = st["caps"]
	var n: int = cols.size()
	var locks: Array = _locks_for(st)
	var order: Array[int] = []
	if cleared_ci >= 0 and cleared_ci < n:
		order.append(cleared_ci)
	for i in n:
		if i != cleared_ci:
			order.append(i)

	var per: Dictionary = {}
	var from_by_col: Dictionary = {}
	var order_by_col: Dictionary = {}
	for bi in types_in.size():
		var t: int = types_in[bi]
		var placed: = false
		for ci in order:
			if not (locks[ci] as Dictionary).is_empty():
				continue
			var col: Array[int] = cols[ci]

			if col.size() >= caps[ci]:
				continue
			if not per.has(ci):
				per[ci] = [] as Array[int]
				from_by_col[ci] = col.size()
				order_by_col[ci] = [] as Array[int]
			col.append(t)
			(per[ci] as Array[int]).append(t)
			(order_by_col[ci] as Array[int]).append(bi)
			placed = true
			break
		if not placed:

			break

	var spawns: Array = []
	for ci in per:
		spawns.append({"col": ci, "types": per[ci], "from": from_by_col[ci], "order": order_by_col[ci]})
	return spawns









static func run_deposit(st: Dictionary, level: JuiceLevel, log: Array) -> int:
	var fired: int = 0
	var again: bool = true
	var guard: int = 0
	var cols: Array = st["cols"]
	var jars: Array[int] = st["jars"]
	var caps: Array[int] = st["caps"]
	var gone: Array[bool] = st["gone"]
	var cups: Array[int] = st["cups"]
	var locks: Array = _locks_for(st)

	while again and guard < CASCADE_GUARD:
		guard += 1
		again = false
		for ci in cols.size():
			var q: int = deposit_ready(st, ci)
			if q == 0:
				continue
			var fruit: int = jars[ci]
			var k: int = int(st["done"])
			var sun: bool = level.has_sunlight() and fruit == level.sunlight_type
			var melted: Array = []
			var thawed_pots: Array = []

			(cols[ci] as Array[int]).clear()
			if sun:
				if st.has("frozen_pots"):
					var flags: Array[bool] = st["frozen_pots"]
					for pot_index in flags.size():
						if flags[pot_index]:
							thawed_pots.append({"col": pot_index, "type": jars[pot_index]})
							flags[pot_index] = false
				for melt_col in cols.size():
					var melt_cells: Array[int] = cols[melt_col]
					for melt_index in melt_cells.size():
						var before: int = melt_cells[melt_index]
						if not JuiceLevel.is_frozen(before):
							continue
						var actual: int = JuiceLevel.true_type(before)
						melt_cells[melt_index] = actual
						melted.append({"col": melt_col, "index": melt_index, 
							"before": before, "type": actual})
			st["done"] = k + 1
			cups.append(fruit)


			var inc: Dictionary = level.incoming_at(k)
			var slot: String = String(inc.get("slot", JuiceLevel.SLOT_RETIRE))
			match slot:
				JuiceLevel.SLOT_JAR:
					jars[ci] = int(inc["jar"])
					caps[ci] = int(inc.get("cap", level.capacity))
				JuiceLevel.SLOT_PARK:
					jars[ci] = NO_JAR
					caps[ci] = int(inc.get("cap", level.capacity))
					if int(st["late_left"]) <= 0:
						push_error("juice_sort: incoming[%d] 是 park 但 late_left 已耗尽(关卡数据与运行期不一致)" % k)
					st["late_left"] = maxi(0, int(st["late_left"]) - 1)
				_:

					jars[ci] = NO_JAR
					caps[ci] = 0
					gone[ci] = true

			var spawns: Array = []
			var beads: Array = inc.get("beads", [])
			if not beads.is_empty():
				spawns = place_batch(st, _recall_revealed(st, k, beads as Array[int]), ci)
			var incoming_lock: Dictionary = inc.get("lock", {}) as Dictionary
			locks[ci] = incoming_lock.duplicate(true) if not gone[ci] else {}

			var new_rope: Dictionary = {}
			if not gone[ci]:
				var has_question: bool = false
				for type_id: int in (cols[ci] as Array[int]):
					if JuiceLevel.is_hidden(type_id):
						has_question = true
						break
				new_rope = {
					"is_empty": (cols[ci] as Array[int]).is_empty(), 
					"has_question": has_question, 
					"has_lock": not (locks[ci] as Dictionary).is_empty(), 
				}
			log.append({"col": ci, "fruit": fruit, "q": q, "nth": k, "sun": sun, "melted": melted, 
				"thawed_pots": thawed_pots, 
				"spawns": spawns, "new_rope": new_rope})
			fired += 1
			again = true

	if guard >= CASCADE_GUARD:
		push_error("juice_sort: 收集级联超过 %d 轮,疑似死循环" % CASCADE_GUARD)
	return fired




static func _unlock_pass(st: Dictionary) -> Array:
	var unlocked: Array = []
	var locks: Array = _locks_for(st)
	for ci in locks.size():
		var lock: Dictionary = locks[ci] as Dictionary
		if lock.is_empty() or not _lock_satisfied(st, lock):
			continue
		unlocked.append({"col": ci, "lock": lock.duplicate(true)})
		locks[ci] = {}
	return unlocked


static func _lock_satisfied(st: Dictionary, lock: Dictionary) -> bool:
	var count: int = int(lock.get("count", 0))
	if String(lock.get("condition", "")) == JuiceLevel.LOCK_COLLECT_COUNT:
		return int(st["done"]) >= count
	var type_id: int = int(lock.get("typeId", -1))
	var collected: int = 0
	for cup: int in (st["cups"] as Array[int]):
		if cup == type_id:
			collected += 1
	return collected >= count



static func _reveal_tails(st: Dictionary) -> Array:
	var revealed: Array = []
	var cols: Array = st["cols"]
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		if col.is_empty():
			continue
		var idx: int = col.size() - 1
		var before: int = col[idx]
		if not JuiceLevel.is_hidden(before):
			continue
		var actual: int = JuiceLevel.true_type(before)
		col[idx] = actual
		revealed.append({"col": ci, "index": idx, "before": before, "type": actual})
	return revealed





static func mystery_auto_unlock_eligible(st: Dictionary, level: JuiceLevel) -> bool:
	if st.is_empty() or level == null or int(st["done"]) != level.groups_total - 1:
		return false
	for col: Array[int] in st["cols"]:
		for flower: int in col:
			if JuiceLevel.is_hidden(flower):
				return true
	return false




static func mystery_auto_unlock_candidate(st: Dictionary, level: JuiceLevel) -> Dictionary:
	if not mystery_auto_unlock_eligible(st, level):
		return {}
	var revealed: Array = []
	var cols: Array = st["cols"]
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		for index in col.size():
			var before: int = col[index]
			if JuiceLevel.is_hidden(before):
				revealed.append({"col": ci, "index": index, "before": before, "type": JuiceLevel.true_type(before)})
	return {"revealed": revealed} if not revealed.is_empty() else {}




static func apply_mystery_auto_unlock(st: Dictionary, level: JuiceLevel) -> Dictionary:
	var candidate: Dictionary = mystery_auto_unlock_candidate(st, level)
	if candidate.is_empty():
		return {}
	var before: Dictionary = _snapshot(st)
	var revealed: Array = candidate["revealed"]
	for reveal: Dictionary in revealed:
		(st["cols"][int(reveal["col"])] as Array[int])[int(reveal["index"])] = int(reveal["type"])
	var deposits: Array = []
	run_deposit(st, level, deposits)
	var unlocked: Array = _unlock_pass(st) if not deposits.is_empty() else []
	return {"before": before, "revealed": revealed, "deposits": deposits, "unlocked": unlocked}













static func _recall_revealed(st: Dictionary, nth: int, beads: Array[int]) -> Array[int]:
	var memory: Dictionary = st.get("reveal_memory", {})
	if memory.is_empty():
		return beads
	var out: Array[int] = beads.duplicate()
	for i in out.size():
		if JuiceLevel.is_hidden(out[i]) and memory.has(_spawn_key(nth, i)):
			out[i] = JuiceLevel.true_type(out[i])
	return out


static func _spawn_key(nth: int, order: int) -> String:
	return "%d:%d" % [nth, order]



static func _hidden_spawns(deposits: Array) -> Array:
	var out: Array = []
	for dep: Dictionary in deposits:
		var nth: int = int(dep.get("nth", -1))
		for spawn: Dictionary in dep.get("spawns", []) as Array:
			var types: Array = spawn.get("types", [])
			var order: Array = spawn.get("order", [])
			var from: int = int(spawn.get("from", 0))
			for m in types.size():
				if JuiceLevel.is_hidden(int(types[m])):
					out.append({"col": int(spawn["col"]), "index": from + m, 
						"key": _spawn_key(nth, int(order[m]))})
	return out


static func _value_at(cols: Array, ci: int, idx: int) -> int:
	if ci < 0 or ci >= cols.size() or idx < 0 or idx >= (cols[ci] as Array).size():
		return -1
	return int((cols[ci] as Array)[idx])











static func apply_move(st: Dictionary, level: JuiceLevel, src: int, j: int, dst: int, 
		no_deposit: bool = false) -> Dictionary:
	var k: int = move_info(st, src, j, dst)
	if k == 0:
		return {}
	var cols: Array = st["cols"]
	var sc: Array[int] = cols[src]
	var dc: Array[int] = cols[dst]
	var head: int = sc[j]
	var root_swapped: bool = is_root_swap(st, src, j, dst)
	if root_swapped:
		cols[src] = dc
		cols[dst] = sc
	else:
		for i in k:
			dc.append(sc[j + i])
		sc.resize(j)

	var deposits: Array = []
	var unlocked: Array = []
	var snap: Dictionary = {}
	if not no_deposit:



		snap = _snapshot(st)
		run_deposit(st, level, deposits)
		if deposits.is_empty():
			snap = {}
		else:
			unlocked = _unlock_pass(st)
	var revealed: Array = _reveal_tails(st)
	var rec: Dictionary = {
		"src": src, "j": j, "dst": dst, "k": k, "head": head, 
		"root_swapped": root_swapped, 
		"deposits": deposits, "revealed": revealed, "unlocked": unlocked, "snap": snap, 
		"hidden_spawns": _hidden_spawns(deposits), 
	}
	return rec




static func undo_move(st: Dictionary, rec: Dictionary, keep_revealed: bool = false, 
		always_visible_type: int = -1) -> int:
	if rec.is_empty():
		return 0
	var before: Array = []
	for col in (st["cols"] as Array):
		before.append((col as Array[int]).duplicate())
	var auto_unlock_before: Dictionary = rec.get("auto_unlock_before", {})
	if not auto_unlock_before.is_empty():
		_restore(st, auto_unlock_before)
	var snap: Dictionary = rec.get("snap", {})
	if not snap.is_empty():
		_restore(st, snap)
	else:
		for reveal: Dictionary in rec.get("revealed", []) as Array:
			var ci: int = int(reveal.get("col", -1))
			var idx: int = int(reveal.get("index", -1))
			var cols_now: Array = st["cols"]
			if ci >= 0 and ci < cols_now.size() and idx >= 0 and idx < (cols_now[ci] as Array).size():
				(cols_now[ci] as Array[int])[idx] = int(reveal.get("before", -1))
	var cols: Array = st["cols"]
	if bool(rec.get("root_swapped", false)):
		var src: int = int(rec["src"])
		var dst: int = int(rec["dst"])
		var swapped: Array[int] = cols[src]
		cols[src] = cols[dst]
		cols[dst] = swapped
		reveal_type(st, always_visible_type)
		return _keep_seen_questions(st, rec, before, 0, keep_revealed)
	var k: int = int(rec["k"])
	var dc: Array[int] = cols[int(rec["dst"])]
	var sc: Array[int] = cols[int(rec["src"])]
	var at: int = dc.size() - k
	for i in k:
		sc.append(dc[at + i])
	dc.resize(at)
	reveal_type(st, always_visible_type)
	return _keep_seen_questions(st, rec, before, at, keep_revealed)


static func _keep_seen_questions(st: Dictionary, rec: Dictionary, before: Array, dst_at: int, 
		keep_revealed: bool) -> int:
	var touched: int = 0
	var src: int = int(rec["src"])
	var j: int = int(rec["j"])
	var dst: int = int(rec["dst"])
	var cols: Array = st["cols"]
	for ci in cols.size():
		var col: Array[int] = cols[ci]
		for idx in col.size():
			var h: int = col[idx]
			if not JuiceLevel.is_hidden(h):
				continue

			var was: int = _value_at(before, dst, dst_at + idx - j) if ci == src and idx >= j\
			else _value_at(before, ci, idx)
			if bool(rec.get("root_swapped", false)):
				was = _value_at(before, dst if ci == src else (src if ci == dst else ci), idx)
			if was == JuiceLevel.true_type(h):
				touched += 1
				if keep_revealed:
					col[idx] = was
	var memory: Dictionary = st.get("reveal_memory", {})
	for spawn: Dictionary in rec.get("hidden_spawns", []) as Array:
		var key: String = String(spawn.get("key", ""))
		var was: int = _value_at(before, int(spawn.get("col", -1)), int(spawn.get("index", -1)))
		if was < 0 or JuiceLevel.is_hidden(was) or memory.has(key):
			continue
		touched += 1
		if keep_revealed:
			memory[key] = true
	if keep_revealed and not memory.is_empty():
		st["reveal_memory"] = memory
	return touched



static func _snapshot(st: Dictionary) -> Dictionary:
	return clone_state(st)


static func _restore(st: Dictionary, snap: Dictionary) -> void :
	var dst_cols: Array = st["cols"]
	var src_cols: Array = snap["cols"]
	for i in dst_cols.size():
		var col: Array[int] = dst_cols[i]
		col.clear()
		col.append_array(src_cols[i] as Array[int])
	var jars: Array[int] = st["jars"]
	var caps: Array[int] = st["caps"]
	var gone: Array[bool] = st["gone"]
	var locks: Array = _locks_for(st)
	for i in jars.size():
		jars[i] = int((snap["jars"] as Array[int])[i])
		caps[i] = int((snap["caps"] as Array[int])[i])
		gone[i] = bool((snap["gone"] as Array[bool])[i])
		locks[i] = ((snap.get("locks", []) as Array)[i] as Dictionary).duplicate(true)
	var cups: Array[int] = st["cups"]
	cups.clear()
	cups.append_array(snap["cups"] as Array[int])
	st["done"] = int(snap["done"])
	st["late_left"] = int(snap["late_left"])
	st["extra_rope_used"] = bool(snap.get("extra_rope_used", false))
	st["ice_mode"] = snap.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION)
	if snap.has("frozen_pots"):
		st["frozen_pots"] = (snap["frozen_pots"] as Array[bool]).duplicate()


static func is_win(st: Dictionary, level: JuiceLevel) -> bool:
	return int(st["done"]) >= level.groups_total











static func build_complete_column_state(st: Dictionary, level: JuiceLevel, ci: int, 
		reveal_target: bool = false, rng_seed: int = -1) -> Dictionary:
	if st.is_empty() or level == null or level.capacity <= 0:
		return {}

	var result: Dictionary = clone_state(st.duplicate())
	if st.has("reveal_memory"):

		result["reveal_memory"] = (st["reveal_memory"] as Dictionary).duplicate(true)
	var cols: Array = result["cols"]
	var caps: Array[int] = result["caps"]
	var gone: Array[bool] = result["gone"]
	var jars: Array[int] = result["jars"]
	if ci < 0 or ci >= cols.size() or gone[ci] or caps[ci] <= 0\
	or not level.valid_cap(caps[ci])\
	or jars[ci] < 0 or jars[ci] >= level.types or is_locked(result, ci)\
	or is_frozen_pot(result, ci):
		return {}
	var target_col: Array[int] = cols[ci]
	if target_col.size() > caps[ci]:
		return {}
	var target_type: int = jars[ci]
	var target_flowers: Array[int] = []
	var target_mapping: Array[Dictionary] = []
	var displaced: Array[Dictionary] = []
	var revealed_target: Array = []


	for index: int in target_col.size():
		var type_id: int = target_col[index]
		var origin: Dictionary = {"col": ci, "index": index}
		if reveal_target and JuiceLevel.is_hidden(type_id)\
		and JuiceLevel.true_type(type_id) == target_type:
			target_col[index] = target_type
			target_flowers.append(target_type)
			target_mapping.append(origin)


			revealed_target.append({"col": ci, "index": target_mapping.size() - 1, 
				"before": type_id, "type": target_type})
		elif not JuiceLevel.is_hidden(type_id) and type_id == target_type:
			target_flowers.append(type_id)
			target_mapping.append(origin)
		else:
			displaced.append(origin)
	var needed: int = caps[ci] - target_flowers.size()
	var mapping: Dictionary = {}

	for source_ci: int in cols.size():
		if gone[source_ci] or caps[source_ci] <= 0:
			continue
		if not level.valid_cap(caps[source_ci])\
		or (cols[source_ci] as Array).size() > caps[source_ci]:
			return {}
		if source_ci == ci:
			continue
		var source_col: Array[int] = cols[source_ci]
		var remaining: Array[int] = []
		var source_mapping: Array[Dictionary] = []
		var locked: bool = is_locked(result, source_ci)
		for index: int in source_col.size():
			var origin: Dictionary = {"col": source_ci, "index": index}
			if not locked and needed > 0 and source_col[index] == target_type:
				target_flowers.append(source_col[index])
				target_mapping.append(origin)
				needed -= 1
			else:

				remaining.append(source_col[index])
				source_mapping.append(origin)
		cols[source_ci] = remaining
		mapping[source_ci] = source_mapping


	if reveal_target and needed > 0:
		for source_ci: int in cols.size():
			if needed <= 0:
				break
			if gone[source_ci] or caps[source_ci] <= 0 or source_ci == ci\
			or is_locked(result, source_ci):
				continue
			var source_col: Array[int] = cols[source_ci]
			var source_origins: Array = mapping[source_ci]
			var kept: Array[int] = []
			var kept_origins: Array[Dictionary] = []
			for index: int in source_col.size():
				var type_id: int = source_col[index]
				if needed > 0 and JuiceLevel.is_hidden(type_id)\
				and JuiceLevel.true_type(type_id) == target_type:
					target_flowers.append(target_type)
					target_mapping.append(source_origins[index])
					revealed_target.append({"col": ci, "index": target_mapping.size() - 1, 
						"before": type_id, "type": target_type})
					needed -= 1
				else:
					kept.append(type_id)
					kept_origins.append(source_origins[index])
			cols[source_ci] = kept
			mapping[source_ci] = kept_origins
	if needed > 0:
		return {}
	cols[ci] = target_flowers
	mapping[ci] = target_mapping

	var free_slots: Array[int] = []
	for dst_ci: int in cols.size():
		if dst_ci == ci or gone[dst_ci] or caps[dst_ci] <= 0 or is_locked(result, dst_ci):
			continue
		if not level.valid_cap(caps[dst_ci]):
			return {}
		for _slot: int in caps[dst_ci] - (cols[dst_ci] as Array).size():
			free_slots.append(dst_ci)
	if free_slots.size() < displaced.size():
		return {}
	if rng_seed >= 0:
		_shuffle_with_seed(free_slots, rng_seed)
	else:
		free_slots.shuffle()
	for origin: Dictionary in displaced:
		var dst_ci: int = free_slots.pop_back()
		(cols[dst_ci] as Array[int]).append(target_col[int(origin["index"])])
		(mapping[dst_ci] as Array[Dictionary]).append(origin)
	return {"state": result, "mapping": mapping, "revealed_target": revealed_target}






static func finalize_complete_column(state: Dictionary, level: JuiceLevel, 
		revealed_target: Array = []) -> Dictionary:
	var deposits: Array = []
	run_deposit(state, level, deposits)
	var unlocked: Array = _unlock_pass(state) if not deposits.is_empty() else []
	var revealed: Array = []


	revealed.append_array(revealed_target)
	revealed.append_array(_reveal_tails(state))
	return {
		"deposits": deposits, "revealed": revealed, "unlocked": unlocked, 
		"hidden_spawns": _hidden_spawns(deposits), "revealed_target": revealed_target, 
	}



static func _shuffle_with_seed(values: Array, seed_value: int) -> void :
	var state: int = seed_value & 2147483647
	for i: int in range(values.size() - 1, 0, -1):
		state = (state * 1664525 + 1013904223) & 2147483647
		var j: int = state % (i + 1)
		var tmp: Variant = values[i]
		values[i] = values[j]
		values[j] = tmp





static func cheat_last_cup_state(st: Dictionary, level: JuiceLevel) -> Dictionary:
	if st.is_empty() or level == null or level.capacity <= 0:
		return {}
	var result: Dictionary = clone_state(st)
	var cups: Array[int] = result["cups"] as Array[int]
	if cups.size() >= level.groups_total or cups.size() != int(result["done"]):
		return {}
	var remaining: Array[int] = level.jar_seq.duplicate()
	for fruit_type: int in cups:
		if not remaining.has(fruit_type):
			return {}
		remaining.erase(fruit_type)
	if remaining.is_empty():
		return {}
	var final_type: int = remaining.pop_back()
	cups.append_array(remaining)
	result["done"] = level.groups_total - 1

	var cols: Array = result["cols"]
	var jars: Array[int] = result["jars"] as Array[int]
	var caps: Array[int] = result["caps"] as Array[int]
	var gone: Array[bool] = result["gone"] as Array[bool]
	var locks: Array = _locks_for(result)
	var dst: int = -1
	var src: int = -1
	for ci in cols.size():
		if gone[ci] or caps[ci] <= 0:
			continue
		if dst < 0 and jars[ci] == final_type:
			dst = ci
	if dst < 0:
		for ci in cols.size():
			if not gone[ci] and caps[ci] > 0:
				dst = ci
				break
	for ci in cols.size():
		if ci != dst and not gone[ci] and caps[ci] > 0:
			src = ci
			break
	if src < 0:
		return {}
	for ci in cols.size():
		(cols[ci] as Array[int]).clear()
		locks[ci] = {}
	jars[dst] = final_type
	jars[src] = NO_JAR
	for _i in caps[dst] - 1:
		(cols[dst] as Array[int]).append(final_type)
	(cols[src] as Array[int]).append(final_type)
	if move_info(result, src, 0, dst) != 1 or any_ready(result):
		return {}
	return result









static func max_groups_left(st: Dictionary, level: JuiceLevel) -> int:
	var cnt: Array[int] = type_counts(st, level.types)
	var done: int = int(st["done"])
	var fut: Array[int] = level.future_tally(done)

	if not level.has_variable_caps():
		var even: int = 0
		for t in level.types:
			@warning_ignore("integer_division")
			even += (cnt[t] + fut[t]) / level.capacity
		return even
	var cups: Array[int] = []
	var min_cap: Array[int] = []
	cups.resize(level.types)
	cups.fill(0)
	min_cap.resize(level.types)
	min_cap.fill(0)


	var jars: Array[int] = st["jars"]
	var caps: Array[int] = st["caps"]
	var gone: Array[bool] = st["gone"]
	for ci in jars.size():
		var t: int = jars[ci]
		if gone[ci] or t < 0:
			continue
		var cap: int = caps[ci]
		cups[t] += 1
		min_cap[t] = cap if min_cap[t] == 0 else mini(min_cap[t], cap)
	for k in range(done, level.incoming.size()):
		var inc: Dictionary = level.incoming[k]
		if String(inc["slot"]) != JuiceLevel.SLOT_JAR:
			continue
		var t: int = int(inc["jar"])
		var cap: int = int(inc.get("cap", level.capacity))
		cups[t] += 1
		min_cap[t] = cap if min_cap[t] == 0 else mini(min_cap[t], cap)
	var g: int = 0
	for t in level.types:
		if cups[t] <= 0 or min_cap[t] <= 0:
			continue
		@warning_ignore("integer_division")
		g += mini(cups[t], (cnt[t] + fut[t]) / min_cap[t])
	return g






static func is_doomed(st: Dictionary, level: JuiceLevel) -> bool:
	if is_win(st, level):
		return false
	return max_groups_left(st, level) < level.groups_total - int(st["done"])












static func is_dead(st: Dictionary, level: JuiceLevel) -> bool:
	if is_win(st, level):
		return false
	return ( not has_any_move(st)) or is_doomed(st, level)


static func cups_left(st: Dictionary, level: JuiceLevel) -> int:
	return maxi(0, level.groups_total - int(st["done"]))













static func state_to_dict(st: Dictionary) -> Dictionary:
	var cols: Array = []
	for col in (st["cols"] as Array):
		cols.append((col as Array[int]).duplicate())
	var out: Dictionary = {
		"v": 1, 
		"iceMode": st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION), 
		"cols": cols, 
		"jars": (st["jars"] as Array[int]).duplicate(), 
		"caps": (st["caps"] as Array[int]).duplicate(), 
		"gone": (st["gone"] as Array[bool]).duplicate(), 
		"locks": _clone_locks(_locks_for(st)), 
		"done": int(st["done"]), 
		"cups": (st["cups"] as Array[int]).duplicate(), 
		"late_left": int(st["late_left"]), 
		"extra_rope_used": bool(st.get("extra_rope_used", false)), 
		"allow_root_swapping": bool(st.get("allow_root_swapping", false)), 
	}
	var memory: Dictionary = st.get("reveal_memory", {})
	if st.has("frozen_pots"):
		out["frozen_pots"] = (st["frozen_pots"] as Array[bool]).duplicate()
	if not memory.is_empty():
		out["reveal_memory"] = memory.keys()
	return out











static func state_from_dict(d: Dictionary, level: JuiceLevel) -> Dictionary:
	var mode: Variant = d.get("iceMode", JuiceLevel.ICE_BLOCK_COLLECTION)
	if not (mode is String) or mode != level.ice_mode:
		push_warning("juice_sort: 存档 iceMode 与题面不符,丢弃续局")
		return {}
	var extra_rope_used: bool = bool(d.get("extra_rope_used", false))
	var expected_columns: int = level.columns + (1 if extra_rope_used else 0)
	var raw_cols: Variant = d.get("cols", [])
	if not (raw_cols is Array) or (raw_cols as Array).size() != expected_columns:
		push_warning("juice_sort: 存档 cols 长度与关卡不符,丢弃续局")
		return {}
	var cols: Array = []
	for c: Variant in (raw_cols as Array):
		var col: Array[int] = []
		if c is Array:
			for v: Variant in (c as Array):
				col.append(int(v))
		cols.append(col)

	var jars: Array[int] = []
	var caps: Array[int] = []
	var gone: Array[bool] = []
	var locks: Array = []
	for v: Variant in d.get("jars", []):
		jars.append(int(v))
	for v: Variant in d.get("caps", []):
		caps.append(int(v))
	for v: Variant in d.get("gone", []):
		gone.append(bool(v))
	if jars.size() != expected_columns or caps.size() != expected_columns or gone.size() != expected_columns:
		push_warning("juice_sort: 存档 jars/caps/gone 长度与关卡不符,丢弃续局")
		return {}
	var raw_locks: Variant = d.get("locks")
	if raw_locks == null:
		var level_has_locks: bool = false
		for level_lock: Dictionary in level.board_locks:
			if not level_lock.is_empty():
				level_has_locks = true
		for incoming_entry: Dictionary in level.incoming:
			if not (incoming_entry.get("lock", {}) as Dictionary).is_empty():
				level_has_locks = true
		if level_has_locks:
			push_warning("juice_sort: 机制关存档缺少 locks,丢弃续局")
			return {}
		for _i in expected_columns:
			locks.append({})
	elif raw_locks is Array and (raw_locks as Array).size() == expected_columns:
		for raw_lock: Variant in raw_locks as Array:
			if not (raw_lock is Dictionary) or not _valid_saved_lock(raw_lock as Dictionary, level):
				push_warning("juice_sort: 存档 locks 内容不合法,丢弃续局")
				return {}
			locks.append((raw_lock as Dictionary).duplicate(true))
	else:
		push_warning("juice_sort: 存档 locks 长度与关卡不符,丢弃续局")
		return {}

	var cups: Array[int] = []
	for v: Variant in d.get("cups", []):
		cups.append(int(v))
	var done: int = int(d.get("done", 0))
	var late_left: int = int(d.get("late_left", level.late_park))


	for i in expected_columns:
		var cap: int = caps[i]
		if cap != 0 and not level.valid_cap(cap):
			push_warning("juice_sort: 存档第 %d 列容量 %d 不属于题面列容量,丢弃续局" % [i, cap])
			return {}
		if (cols[i] as Array).size() > cap:
			push_warning("juice_sort: 存档第 %d 列有 %d 颗 > 容量 %d,丢弃续局"
				%[i, (cols[i] as Array).size(), cap])
			return {}
		if gone[i] != (cap == 0):
			push_warning("juice_sort: 存档第 %d 列的 gone/caps 自相矛盾,丢弃续局" % i)
			return {}
		if gone[i] and not (locks[i] as Dictionary).is_empty():
			push_warning("juice_sort: 存档第 %d 列已退出却仍带冰封,丢弃续局" % i)
			return {}
		if jars[i] != NO_JAR and (jars[i] < 0 or jars[i] >= level.types):
			push_warning("juice_sort: 存档第 %d 列的机器 %d 超出种类数 %d,丢弃续局" % [i, jars[i], level.types])
			return {}
		for t: int in (cols[i] as Array):
			var actual: int = JuiceLevel.true_type(t)
			if t < 0 or actual < 0 or actual >= level.types\
			or (t >= level.types and not JuiceLevel.is_hidden(t) and not JuiceLevel.is_frozen(t)):
				push_warning("juice_sort: 存档第 %d 列出现水果类型 %d,超出种类数 %d,丢弃续局"
					%[i, t, level.types])
				return {}
			if JuiceLevel.is_frozen(t) and not level.has_sunlight():
				push_warning("juice_sort: 存档第 %d 列含冰封花朵,但题面没有 sunlight,丢弃续局" % i)
				return {}
	if extra_rope_used:
		var extra_ci: int = expected_columns - 1
		if jars[extra_ci] != NO_JAR or caps[extra_ci] != level.capacity or gone[extra_ci]\
		or not (locks[extra_ci] as Dictionary).is_empty():
			push_warning("juice_sort: 存档中的额外绳状态不合法,丢弃续局")
			return {}
	if done < 0 or done >= level.groups_total:

		push_warning("juice_sort: 存档已榨 %d 杯,不在 0..%d 内,丢弃续局" % [done, level.groups_total - 1])
		return {}
	if cups.size() != done:
		push_warning("juice_sort: 存档已榨杯列表 %d 项 != done %d,丢弃续局" % [cups.size(), done])
		return {}
	if late_left < 0 or late_left > level.late_park:
		push_warning("juice_sort: 存档后备白位 %d 不在 0..%d 内,丢弃续局" % [late_left, level.late_park])
		return {}

	var restored: Dictionary = {
		"ice_mode": level.ice_mode, 
		"cols": cols, "jars": jars, "caps": caps, "gone": gone, "locks": locks, 
		"done": done, 
		"cups": cups, 
		"late_left": late_left, 
		"extra_rope_used": extra_rope_used, 
		"allow_root_swapping": bool(d.get("allow_root_swapping", false)), 
		"varcap": level.has_variable_caps(), 
	}
	if level.has_frozen_pots() or d.has("frozen_pots"):
		var raw_flags: Variant = d.get("frozen_pots")
		if not (raw_flags is Array) or raw_flags.size() != expected_columns:
			return {}
		var flags: Array[bool] = []
		for index in expected_columns:
			if not (raw_flags[index] is bool):
				return {}
			var frozen: bool = raw_flags[index]
			var original: bool = index < level.board_frozen_pots.size() and level.board_frozen_pots[index]
			if frozen and ( not original or cups.has(level.sunlight_type) or jars[index] < 0):
				return {}
			if original and not cups.has(level.sunlight_type) and not frozen:
				return {}
			flags.append(frozen)
		restored["frozen_pots"] = flags
	var raw_memory: Variant = d.get("reveal_memory", [])
	if raw_memory is Array and not (raw_memory as Array).is_empty():
		var memory: Dictionary = {}
		for key: Variant in raw_memory as Array:
			memory[String(key)] = true
		restored["reveal_memory"] = memory
	return restored




static func _valid_saved_lock(lock: Dictionary, level: JuiceLevel) -> bool:
	if lock.is_empty():
		return true
	var condition: String = String(lock.get("condition", ""))
	var allowed: Array[String] = ["condition", "count"]
	if condition == JuiceLevel.LOCK_COLLECT_TYPE:
		allowed.append("typeId")
	elif condition != JuiceLevel.LOCK_COLLECT_COUNT:
		return false
	for key: Variant in lock:
		if not allowed.has(String(key)):
			return false
	var raw_count: Variant = lock.get("count")
	if not (raw_count is int or raw_count is float) or raw_count is bool\
	or float(raw_count) != float(int(raw_count)) or int(raw_count) < 1:
		return false
	if condition == JuiceLevel.LOCK_COLLECT_TYPE:
		var raw_type_id: Variant = lock.get("typeId")
		if not (raw_type_id is int or raw_type_id is float) or raw_type_id is bool\
		or float(raw_type_id) != float(int(raw_type_id)):
			return false
		var type_id: int = int(raw_type_id)
		return type_id >= 0 and type_id < level.types
	return true



static func board_stats(st: Dictionary) -> Dictionary:
	var slots: int = 0
	var beads: int = 0
	var caps: Array[int] = st["caps"]
	var cols: Array = st["cols"]
	for i in cols.size():
		if bool((st["gone"] as Array[bool])[i]) or is_locked(st, i):
			continue
		slots += caps[i]
		beads += (cols[i] as Array).size()
	return {"slots": slots, "beads": beads, "free": slots - beads}
