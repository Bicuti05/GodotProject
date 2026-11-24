class_name JuiceEndlessSession
extends RefCounted


const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const SETTINGS = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_settings.gd")
var level: JuiceLevel
var state: Dictionary
var pending: Array[Dictionary] = []
var obligations: Dictionary = {}
var seed: int
var steps: int = 0
var queue_mode: bool = false
var incoming: Array[Dictionary] = []
var last_incoming: Dictionary = {}


func _init(run_seed: int = 1, queued_round: bool = false) -> void :
	seed = run_seed
	queue_mode = queued_round

	level = JuiceLevel.from_dict({"id": 101, "capacity": SETTINGS.CAPACITY, 
		"targetCups": 5, "initial": SETTINGS.initial_layout(run_seed), "incoming": []})

	level.types = SETTINGS.MAX_COLORS
	level.groups_total = 0
	level.jar_seq.clear()
	state = R.make_state(level)


static func from_snapshot(data: Dictionary) -> JuiceEndlessSession:
	var session: = JuiceEndlessSession.new(int(data["seed"]))
	session.state = R.clone_state(data["state"])
	for deposit: Dictionary in data["pending"] as Array:
		session.pending.append(deposit.duplicate(true))
	session.obligations = (data["obligations"] as Dictionary).duplicate()
	session.steps = int(data.get("steps", 0))
	return session


func snapshot() -> Dictionary:
	return {"state": R.clone_state(state), "pending": pending.duplicate(true), 
		"obligations": obligations.duplicate(), "seed": seed, "steps": steps}


func player_snapshot() -> Dictionary:
	var data: Dictionary = snapshot()
	data["incoming"] = incoming.duplicate(true)
	data["last_incoming"] = last_incoming.duplicate(true)
	return data


static func from_player_snapshot(data: Dictionary) -> JuiceEndlessSession:
	var session: JuiceEndlessSession = from_snapshot(data)
	session.queue_mode = true
	for entry: Dictionary in data.get("incoming", []):
		session.incoming.append(entry.duplicate(true))
	session.last_incoming = data.get("last_incoming", {}).duplicate(true)
	return session


func undo_move(rec: Dictionary) -> bool:
	var before: Dictionary = rec.get("endless_before", {})
	if not queue_mode or before.is_empty():
		return false
	state.merge(R.clone_state(before["state"]), true)
	incoming.clear()
	for entry: Dictionary in before["incoming"]:
		incoming.append(entry.duplicate(true))
	last_incoming = before["last_incoming"].duplicate(true)
	steps = int(before["steps"])
	return true


static func snapshot_key(data: Dictionary) -> String:

	return JSON.stringify({"state": data["state"], "pending": data["pending"], 
		"obligations": data["obligations"], "seed": data["seed"]})


func apply_move(src: int, j: int, dst: int) -> Dictionary:
	if is_pending(src) or is_pending(dst):
		return {}
	if queue_mode:

		var predicted: Dictionary = R.clone_state(state)
		if R.apply_move(predicted, level, src, j, dst, true).is_empty():
			return {}
		var needed: int = 0
		for ci in SETTINGS.COLUMNS:
			if R.deposit_ready(predicted, ci) > 0:
				needed += 1
		if needed > incoming.size():
			return {}
	var before: Dictionary = player_snapshot() if queue_mode else {}
	var rec: Dictionary = R.apply_move(state, level, src, j, dst, true)
	if rec.is_empty():
		return rec
	if queue_mode:
		rec["endless_before"] = before
	steps += 1
	rec["deposits"] = _collect_ready_columns()
	return rec



func _collect_ready_columns() -> Array[Dictionary]:
	var deposits: Array[Dictionary] = []
	for ci in SETTINGS.COLUMNS:
		var q: int = R.deposit_ready(state, ci)
		if q == 0:
			continue
		var color: int = int(state["jars"][ci])
		var nth: int = int(state["done"])
		(state["cols"][ci] as Array[int]).clear()
		(state["jars"] as Array[int])[ci] = R.NO_JAR
		(state["caps"] as Array[int])[ci] = 0
		state["done"] = nth + 1
		var cups: Array[int] = state["cups"]
		cups.append(color)
		if cups.size() > SETTINGS.HISTORY_LIMIT:
			cups.pop_front()
		var deposit: Dictionary = {"col": ci, "fruit": color, "q": q, "nth": nth, 
			"spawns": [], "new_rope": {}}
		if queue_mode:
			last_incoming = incoming.pop_front()
			(state["jars"] as Array[int])[ci] = int(last_incoming["jar"])
			(state["caps"] as Array[int])[ci] = SETTINGS.CAPACITY
			(state["cols"] as Array)[ci] = (last_incoming["beads"] as Array[int]).duplicate()
			deposit["incoming"] = {"slot": JuiceLevel.SLOT_JAR, "jar": int(last_incoming["jar"])}
			deposit["spawns"] = [{"col": ci, "types": (last_incoming["beads"] as Array[int]).duplicate()}]
		else:
			pending.append(deposit)
		deposits.append(deposit.duplicate(true))
	return deposits




func complete_column(order: Array) -> Dictionary:
	if not queue_mode or incoming.is_empty():
		return {}
	var before: Dictionary = player_snapshot()
	var seed_base: int = R.state_key(state).hash() & 2147483647
	var selected: Dictionary = {}
	for ci_value: Variant in order:
		var ci: int = int(ci_value)
		for attempt: int in 4:
			var built: Dictionary = R.build_complete_column_state(state, level, ci, false, 
				(seed_base + attempt * 7919) & 2147483647)
			if built.is_empty():
				break
			var trial: JuiceEndlessSession = from_player_snapshot(before)
			trial.state = built["state"]
			var needed: int = 0
			for target: int in SETTINGS.COLUMNS:
				if R.deposit_ready(trial.state, target) > 0:
					needed += 1
			if needed == 0 or needed > trial.incoming.size():
				continue
			var deposits: Array[Dictionary] = trial._collect_ready_columns()
			var candidate: Dictionary = {"state": trial.state, "mapping": built["mapping"], 
				"rec": {"deposits": deposits, "revealed": [], "unlocked": [], "revealed_target": []}, 
				"target": ci, "incoming": trial.incoming, "last_incoming": trial.last_incoming}
			if selected.is_empty():
				selected = candidate
			if R.has_any_move(trial.state):
				selected = candidate
				break
		if not selected.is_empty() and R.has_any_move(selected["state"]):
			break
	if selected.is_empty():
		return {}
	state.merge(selected["state"], true)
	incoming.assign(selected["incoming"])
	last_incoming = selected["last_incoming"]
	steps += 1
	selected["state"] = state
	selected.erase("incoming")
	selected.erase("last_incoming")
	return selected


func enqueue(entries: Array) -> bool:
	if not queue_mode or incoming.size() + entries.size() > SETTINGS.QUEUE_TARGET:
		return false
	var expected: int = int(state["done"]) + incoming.size()
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if not valid_incoming(entry, expected + i):
			return false
	for entry: Dictionary in entries:
		incoming.append(entry.duplicate(true))
	return true


static func valid_incoming(entry: Dictionary, sequence: int) -> bool:
	var jar: int = int(entry.get("jar", -1))
	var beads: Array = entry.get("beads", [])
	if int(entry.get("sequence", -1)) != sequence or jar < 0 or jar >= SETTINGS.MAX_COLORS\
	or beads.size() != SETTINGS.CAPACITY or not SETTINGS.normal_column(beads):
		return false
	for color: Variant in beads:
		if not color is int or int(color) < 0 or int(color) >= SETTINGS.MAX_COLORS:
			return false
	return true


func is_pending(ci: int) -> bool:
	for deposit: Dictionary in pending:
		if int(deposit["col"]) == ci:
			return true
	return false


static func inventory(st: Dictionary) -> Dictionary:
	var flowers: Array[int] = []
	var pots: Array[int] = []
	flowers.resize(SETTINGS.MAX_COLORS)
	flowers.fill(0)
	pots.resize(SETTINGS.MAX_COLORS)
	pots.fill(0)
	for ci in (st["cols"] as Array).size():
		var jar: int = int(st["jars"][ci])
		if jar >= 0:
			pots[jar] += 1
		for color: int in st["cols"][ci] as Array[int]:
			flowers[color] += 1
	return {"flowers": flowers, "pots": pots}



static func check_refill(data: Dictionary, entries: Array) -> Dictionary:
	var deposits: Array = data["pending"]
	if deposits.is_empty() or entries.size() != deposits.size():
		return {}
	var st: Dictionary = R.clone_state(data["state"])
	var limit: int = SETTINGS.color_limit(int(st["done"]))
	var used: Dictionary = {}
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var ci: int = int(entry.get("col", -1))
		var jar: int = int(entry.get("jar", -1))
		var beads: Array = entry.get("beads", [])
		if ci != int(deposits[i]["col"]) or ci < 1 or ci >= SETTINGS.COLUMNS\
		or used.has(ci) or jar < 0 or jar >= limit or beads.size() != SETTINGS.CAPACITY:
			return {}
		if not (st["cols"][ci] as Array).is_empty():
			return {}
		used[ci] = true
		var col: Array[int] = []
		var own: int = 0
		for value: Variant in beads:
			if not value is int or int(value) < 0 or int(value) >= limit:
				return {}
			col.append(int(value))
			if int(value) == jar:
				own += 1
		if own == SETTINGS.CAPACITY:
			return {}
		(st["jars"] as Array[int])[ci] = jar
		(st["caps"] as Array[int])[ci] = SETTINGS.CAPACITY
		(st["cols"] as Array)[ci] = col
	var counts: Dictionary = inventory(st)
	var next_obligations: Dictionary = (data["obligations"] as Dictionary).duplicate()
	var total: int = 0
	for color in SETTINGS.MAX_COLORS:
		var count: int = int(counts["flowers"][color])
		var pot_count: int = int(counts["pots"][color])
		total += count
		if absi(pot_count * SETTINGS.CAPACITY - count) > SETTINGS.CAPACITY:
			return {}
		if pot_count > 0 or count == 0:
			next_obligations.erase(color)
		else:
			if next_obligations.has(color) and int(next_obligations[color]) <= int(st["done"]):
				return {}
			if not next_obligations.has(color):
				next_obligations[color] = int(st["done"]) + SETTINGS.RECOVERY_WINDOW
	if total != SETTINGS.FLOWERS:
		return {}
	return {"state": st, "obligations": next_obligations}


func apply_refill(entries: Array) -> Dictionary:
	var checked: Dictionary = check_refill(snapshot(), entries)
	if checked.is_empty():
		return {}

	state.merge(checked["state"], true)
	obligations = checked["obligations"]
	var spawns: Array[Dictionary] = []
	for entry: Dictionary in entries:
		spawns.append({"col": int(entry["col"]), "types": (entry["beads"] as Array).duplicate()})
	pending.clear()
	return {"spawns": spawns}
