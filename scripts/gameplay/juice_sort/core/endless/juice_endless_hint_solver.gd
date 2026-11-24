class_name JuiceEndlessHintSolver
extends RefCounted

const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")


static func _now(opts: Dictionary) -> int:
	if opts.has("yield_at") and Time.get_ticks_usec() >= int(opts["yield_at"]):
		OS.delay_usec(1000)
		opts["yield_at"] = Time.get_ticks_usec() + 6000
	var cancel: Semaphore = opts.get("cancel")
	if cancel != null and cancel.try_wait():
		opts["cancelled"] = true
	return int(opts["deadline"]) if bool(opts.get("cancelled", false)) else int((opts["clock"] as Callable).call())


static func solve(data: Dictionary, opts: Dictionary) -> Dictionary:
	var session: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(data)
	if session.incoming.is_empty():
		return {}
	opts["clock"] = opts.get("now", Time.get_ticks_msec)
	var start: int = int((opts["clock"] as Callable).call())
	opts["deadline"] = mini(start + int(opts.get("ms_cap", 800)), int(opts.get("deadline", start + 800)))
	if bool(session.state.get("allow_root_swapping", false)):
		if bool(opts.get("require_complete", false)):

			opts["deadline"] = 1 << 60
		return _solve_root(data, session, opts)
	var counts: Dictionary = JuiceEndlessSession.inventory(session.state)
	var targets: Array[int] = []
	for ci in range(1, JuiceEndlessSettings.COLUMNS):
		var color: int = int(session.state["jars"][ci])
		if color >= 0 and int(counts["flowers"][color]) >= JuiceEndlessSettings.CAPACITY:
			targets.append(ci)
	targets.sort_custom( func(a: int, b: int) -> bool:
		return S.hint_lower_bound(session.state, a, session.level) < S.hint_lower_bound(session.state, b, session.level))

	var remaining_ms: int = int(opts["deadline"]) - _now(opts)
	if not targets.is_empty() and remaining_ms > 0:
		var route: Dictionary = S._astar_group(session.state, session.level, targets, {
			"node_cap": 6000, "max_depth": 40, 
			"deadline": mini(int(opts["deadline"]), _now(opts) + int(remaining_ms * 0.6)), 
			"now": _now.bind(opts), "forbid": opts.get("forbid", {})})
		if not route.is_empty():
			var checked: Dictionary = _checked_hint_path(data, route["path"], int(route["col"]), opts)
			if not checked.is_empty():
				return checked
	for ci in targets:
		if _now(opts) >= int(opts["deadline"]):
			break
		var path: Variant = S.solve_group(session.state, session.level, ci, {
			"node_cap": 6000, "max_depth": 40, "deadline": opts["deadline"], "clock_every": 16, 
			"now": _now.bind(opts), "forbid": opts.get("forbid", {})})
		if path == null:
			continue
		var checked: Dictionary = _checked_hint_path(data, path, ci, opts)
		if not checked.is_empty():
			return checked
	return {}



static func _checked_hint_path(data: Dictionary, path: Array, ci: int, opts: Dictionary) -> Dictionary:
	var replay: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(data)
	var verified: Array[Dictionary] = []
	for move: Dictionary in path:
		if _now(opts) >= int(opts["deadline"]):
			return {}
		var rec: Dictionary = replay.apply_move(int(move.src), int(move.j), int(move.dst))
		if rec.is_empty():
			return {}
		verified.append(move.duplicate())
		if not (rec["deposits"] as Array).is_empty():
			return {"move": verified[0], "col": ci, "len": verified.size(), "path": verified, 
				"optimal": false, "win_path": false, "queue_prefix": data["incoming"].duplicate(true)}
	return {}




static func _solve_root(data: Dictionary, session: JuiceEndlessSession, opts: Dictionary) -> Dictionary:
	if _now(opts) >= int(opts["deadline"]):
		return {}
	var checks: Dictionary = opts.duplicate()
	checks.merge({"now": _now.bind(opts), "check_path": _checked_root_path.bind(data)}, true)
	var hint: Dictionary = _root_route(session, checks)

	var search: Dictionary = checks.get("search_result", {})
	opts["search_result"] = {"status": search.get("status", "UNKNOWN"), 
		"continuable": search.get("continuable", false), "states": search.get("states", 0)}

	_now(opts)
	return {} if bool(opts.get("cancelled", false)) else hint


static func _root_route(session: JuiceEndlessSession, checks: Dictionary) -> Dictionary:
	var search: Dictionary = S._find_root_local_hint(session.state, session.level, checks)
	checks["search_result"] = search
	return search["hint"]


static func _checked_root_path(path: Array, checks: Dictionary, data: Dictionary) -> Dictionary:
	var replay: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(data)
	var verified: Array[Dictionary] = []
	for move: Dictionary in path:
		if S._hint_time_expired(checks):
			return {}
		var rec: Dictionary = replay.apply_move(int(move["src"]), int(move["j"]), int(move["dst"]))
		if rec.is_empty():
			return {}
		verified.append({"src": rec["src"], "j": rec["j"], "dst": rec["dst"], 
			"k": rec["k"], "head": rec["head"], "root_swapped": rec["root_swapped"]})
		var deposits: Array = rec["deposits"]
		if not deposits.is_empty():
			var hint: Dictionary = {"move": verified[0], "col": int(deposits[0]["col"]), "len": verified.size(), 
				"path": verified, "optimal": false, "win_path": false, "root_necessary": false, 
				"queue_prefix": data["incoming"].duplicate(true)}

			checks["check_safe"] = func(ranking: Dictionary) -> bool:
				return _root_safe_after(replay, ranking)
			return hint
	return {}




static func _root_safe_after(session: JuiceEndlessSession, checks: Dictionary) -> bool:
	if S._hint_time_expired(checks) or session.incoming.is_empty():
		return false
	var clock: Callable = checks["now"]
	var started: int = int(clock.call())
	var window: int = mini(4, maxi(0, int(checks["deadline"]) - started))
	if window <= 0:
		return false
	var probe: Dictionary = {"now": clock, "deadline": started + window, "verify_safe": false, 
		"node_cap": 128, "state_cap": 256, 
		"check_path": _checked_root_path.bind(session.player_snapshot())}
	return not _root_route(session, probe).is_empty()





static func run_task(data: Dictionary, opts: Dictionary, result: Dictionary) -> void :
	opts["yield_at"] = Time.get_ticks_usec() + 6000
	opts["clock"] = opts.get("now", Time.get_ticks_msec)
	var started: int = int((opts["clock"] as Callable).call())
	var budget_ms: int = maxi(1, int(opts.get("ms_cap", 800)))
	var deadline: int = mini(started + budget_ms, int(opts.get("deadline", started + budget_ms)))
	opts["deadline"] = deadline
	var session: JuiceEndlessSession = JuiceEndlessSession.from_player_snapshot(data)
	var hint: Dictionary = {}
	var reachability: int = S.Reachability.UNKNOWN
	var root_enabled: bool = bool(session.state.get("allow_root_swapping", false))
	if root_enabled:
		hint = solve(data, opts)
		if String((opts.get("search_result", {}) as Dictionary).get("status", "UNKNOWN")) == "CLOSED":
			reachability = S.Reachability.UNWINNABLE
	elif not session.incoming.is_empty() and _now(opts) < deadline:
		var first_deadline: int = mini(deadline, started + maxi(0, int(opts.get("death_first_ms", 50))))
		if _dead_proven(session, opts, first_deadline):
			reachability = S.Reachability.UNWINNABLE
		else:
			var reserve_ms: int = mini(maxi(0, int(opts.get("death_last_ms", 70))), maxi(0, deadline - _now(opts)))
			opts["deadline"] = deadline - reserve_ms
			hint = solve(data, opts)
			opts["deadline"] = deadline
			if hint.is_empty() and _dead_proven(session, opts, deadline):
				reachability = S.Reachability.UNWINNABLE
	_now(opts)
	if bool(opts.get("cancelled", false)):
		hint = {}
		reachability = S.Reachability.UNKNOWN
	if not hint.is_empty():
		var progress: JuiceSolver.HintProgress = opts.get("progress")
		if progress != null:
			progress.publish(hint, "endless_first_pot", int((opts["clock"] as Callable).call()) - started, 0)
	result.merge({"completed": true, "hint": hint, "reachability": reachability, 
		"hint_source": "endless_first_pot" if not hint.is_empty() else "", 
		"budget_ms": budget_ms, "elapsed_ms": int((opts["clock"] as Callable).call()) - started, 
		"stop_reason": "cancelled" if bool(opts.get("cancelled", false)) else (
			"dead" if reachability == S.Reachability.UNWINNABLE else "completed")}, true)

	if root_enabled:
		var search: Dictionary = opts.get("search_result", {})
		result["continuable"] = not bool(opts.get("cancelled", false)) and bool(search.get("continuable", false))
		result["search_status"] = String(search.get("status", "UNKNOWN"))


static func _dead_proven(session: JuiceEndlessSession, opts: Dictionary, deadline: int) -> bool:
	if _now(opts) >= deadline or R.any_ready(session.state):
		return false
	if not R.has_any_move(session.state):
		return true


	var seen: Dictionary = {R.state_key(session.state): true}
	var pending: Array[Dictionary] = [R.clone_state(session.state)]
	while not pending.is_empty():
		var cur: Dictionary = pending.pop_back()
		var cols: Array = cur["cols"]
		for src in cols.size():
			for j in (cols[src] as Array).size():
				for dst in cols.size():
					if _now(opts) >= deadline:
						return false
					if R.move_info(cur, src, j, dst) <= 0:
						continue
					var next: Dictionary = R.clone_state(cur)
					if R.apply_move(next, session.level, src, j, dst, true).is_empty():
						continue
					if R.any_ready(next):
						return false
					var key: String = R.state_key(next)
					if seen.has(key):
						continue
					if seen.size() >= S.CLOSED_STATE_CAP:
						return false
					seen[key] = true
					pending.append(next)
	return not bool(opts.get("cancelled", false)) and _now(opts) < deadline
