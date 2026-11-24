extends RefCounted















































































const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

enum Kind{NONE, TRAP, MASTER}


const NEAR_DEAD_STATE_CAP: = 40

const MAX_PROGRESS_MOVES: = 10

const TRAP_MAX_ALIVE: = 1

const TRAP_MIN_MOVES: = 2

const TRAP_OBVIOUS_MARGIN: = 1.0

const APPEAL_RUN: = 3.0
const APPEAL_JUNK: = 1.5
const APPEAL_DIST: = 0.5
const APPEAL_SRC_CLEAN: = 2.0
const APPEAL_OWN_POT: = 2.0
const LOOKAHEAD_DISCOUNT: = 0.5

const MOVE_MARK: = "_challenge_move"
const MASTER_MAX_DEPTH: = 6
const MASTER_STATE_CAP: = 300






const VERIFY_OPT: = {"shallow_depth": 20, "shallow_nodes": 6000, "deep_nodes": 20000, "deep_depth": 34}


const DEFAULT_VERIFY_MS_CAP: = 300
const DEFAULT_MS_CAP: = 200

const ENDGAME_CUPS: = 2

const MIN_STEPS: = 3

const REVEALED_MARK: = "_challenge_revealed"

const LUCKY_STATE_CAP: = 300






static func gate_reason(st: Dictionary, level: JuiceLevel, steps: int, 
		resumed: bool = false) -> String:
	if st.is_empty() or level == null:
		return "empty"
	if not resumed and steps < MIN_STEPS:
		return "opening"
	if R.cups_left(st, level) <= ENDGAME_CUPS:
		return "endgame"
	return ""













static func classify(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> Dictionary:
	var ctx: Dictionary = _make_ctx(opts)
	var out: Dictionary = {"kind": Kind.NONE, "reason": "", "n": 0, "alive": 0, "fatal": 0, "depth": -1}
	_record_phase(ctx, "progress_outcomes")
	var progress: Array[Dictionary] = _progress_outcomes(st, level)
	out["n"] = progress.size()
	if progress.size() > MAX_PROGRESS_MOVES:
		return _done(out, "too_many_moves")

	var alive_states: Array[Dictionary] = []
	var fatal_states: Array[Dictionary] = []
	var fatal: int = 0
	for nx: Dictionary in progress:
		var verdict: int = _near_dead(nx, level, ctx)
		if _timed_out(ctx):
			return _done(out, "timeout")
		if verdict == 1:
			fatal += 1
			fatal_states.append(nx)
		else:
			alive_states.append(nx)
			if alive_states.size() > TRAP_MAX_ALIVE:
				break
	out["alive"] = alive_states.size()
	out["fatal"] = fatal
	if alive_states.size() > TRAP_MAX_ALIVE:
		return _done(out, "many_alive")

	if not alive_states.is_empty():
		if progress.size() < TRAP_MIN_MOVES:
			return _done(out, "few_moves")
		if fatal == 0:
			return _done(out, "no_fatal")

		_record_phase(ctx, "temptation_scoring")
		var slot_of: Dictionary = opts.get("slot_of", {})
		var alive_t: float = _temptation(st, alive_states[0], slot_of)
		var fatal_t: float = - INF
		for nx: Dictionary in fatal_states:
			fatal_t = maxf(fatal_t, _temptation(st, nx, slot_of))
		out["appeal_alive"] = alive_t
		out["appeal_fatal"] = fatal_t
		if alive_t - fatal_t > TRAP_OBVIOUS_MARGIN:
			return _done(out, "obvious")
		_start_verify_phase(ctx)
		for nx: Dictionary in alive_states:
			if not _verify_alive(nx, level, ctx):
				return _done(out, "timeout" if _timed_out(ctx) else "alive_unproven")
		out["kind"] = Kind.TRAP
		out["answer"] = alive_states[0][MOVE_MARK]
		out["answer_key"] = R.state_key(alive_states[0])
		return _done(out, "")


	var exit: Dictionary = _find_shuffle_exit(st, level, ctx)
	if _timed_out(ctx):
		return _done(out, "timeout")
	if exit.is_empty():
		return _done(out, "no_exit")
	out["depth"] = int(exit["depth"])
	_start_verify_phase(ctx)
	if not _verify_alive(exit["state"] as Dictionary, level, ctx):
		return _done(out, "timeout" if _timed_out(ctx) else "exit_unproven")
	out["kind"] = Kind.MASTER
	return _done(out, "")






static func is_progress_move(st_after: Dictionary, rec: Dictionary) -> bool:
	if not (rec["deposits"] as Array).is_empty() or not (rec["revealed"] as Array).is_empty():
		return true
	var sc: Array[int] = (st_after["cols"] as Array)[int(rec["src"])]
	var j: int = int(rec["j"])
	return not (j > 0 and sc.size() == j and _is_shuffle_pair(st_after, sc[j - 1], int(rec["head"])))





static func exit_alive(st: Dictionary, level: JuiceLevel, opts: Dictionary = {}) -> Dictionary:
	var ctx: Dictionary = _make_ctx(opts)
	var out: Dictionary = {"alive": false, "reason": ""}
	if R.is_win(st, level):
		out["alive"] = true
		return out
	if _near_dead(st, level, ctx) == 1:
		out["reason"] = "near_dead"
		return out
	if _timed_out(ctx):
		out["reason"] = "timeout"
		return out
	_start_verify_phase(ctx)
	if not _verify_alive(st, level, ctx):
		out["reason"] = "timeout" if _timed_out(ctx) else "unproven"
		return out
	out["alive"] = true
	return out





static func run_task(st: Dictionary, level: JuiceLevel, opts: Dictionary, result: Dictionary) -> void :
	var now: Callable = opts.get("now", Callable())
	var started: int = int(now.call()) if now.is_valid() else 0
	var diagnostic: Dictionary = {"source": "challenge"}
	var task_opts: Dictionary = opts.duplicate()
	task_opts["diagnostic"] = diagnostic
	result.erase("diagnostic")
	var info: Dictionary = classify(st, level, task_opts)
	result["info"] = info
	_finish_task_diagnostic(result, info, diagnostic, now, started, int(info["kind"]) != Kind.NONE)
	result["completed"] = true













static func lucky_reveal(pre: Dictionary, post: Dictionary, revealed: Array, level: JuiceLevel, 
		opts: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {"lucky": false, "cells": [], "reason": "", "states": 0}
	var cells: Array = []
	for r: Dictionary in revealed:
		if _revealed_connects(post, int(r["col"]), int(r["index"]), int(r["type"])):
			cells.append(r)
	if cells.is_empty():
		out["reason"] = "no_connect"
		return out
	var ctx: Dictionary = _make_ctx(opts)
	_record_phase(ctx, "stuck_without_reveal")
	var stuck: int = _stuck_without_reveal(pre, level, ctx, out)

	if ctx.has("diagnostic"):
		(ctx["diagnostic"] as Dictionary)["states"] = int(out["states"])
	if stuck != 1:
		out["reason"] = "other_progress" if stuck == 0 else ("timeout" if _timed_out(ctx) else "state_cap")
		return out
	_start_verify_phase(ctx)
	if not _verify_alive(post, level, ctx):
		out["reason"] = "timeout" if _timed_out(ctx) else "unproven"
		return out
	out["lucky"] = true
	out["cells"] = cells
	return out




static func run_lucky_task(pre: Dictionary, post: Dictionary, revealed: Array, level: JuiceLevel, 
		opts: Dictionary, result: Dictionary) -> void :
	var now: Callable = opts.get("now", Callable())
	var started: int = int(now.call()) if now.is_valid() else 0
	var diagnostic: Dictionary = {"source": "lucky_reveal"}
	var task_opts: Dictionary = opts.duplicate()
	task_opts["diagnostic"] = diagnostic
	result.erase("diagnostic")
	var info: Dictionary = lucky_reveal(pre, post, revealed, level, task_opts)
	result["info"] = info
	_finish_task_diagnostic(result, info, diagnostic, now, started, bool(info["lucky"]))
	result["completed"] = true






static func answer_follows(info: Dictionary, last: Dictionary) -> bool:
	if int(info.get("kind", Kind.NONE)) != Kind.TRAP:
		return false
	var answer: Dictionary = info.get("answer", {})
	if answer.is_empty() or last.is_empty():
		return false
	var touched: Array[int] = [int(last["src"]), int(last["dst"])]
	return int(answer["src"]) in touched or int(answer["dst"]) in touched



static func reason_text(reason: String) -> String:
	match reason:
		"opening":
			return "新开局前 %d 步不判" % MIN_STEPS
		"endgame":
			return "只剩 ≤%d 盆,视为终局" % ENDGAME_CUPS
		"too_many_moves":
			return "推进走法超过 %d 种,选择太多" % MAX_PROGRESS_MOVES
		"many_alive":
			return "不止一条推进走法能活"
		"few_moves":
			return "推进走法不到 %d 种,谈不上选择" % TRAP_MIN_MOVES
		"no_fatal":
			return "没有会很快卡死的推进走法"
		"obvious":
			return "正解比最诱人的死路明显更诱人(诱惑分高出 %.1f 以上)" % TRAP_OBVIOUS_MARGIN
		"alive_unproven", "exit_unproven", "unproven":
			return "证明不了能种满下一盆"
		"no_exit":
			return "推进走法全死,倒腾 %d 步内也找不到出口" % MASTER_MAX_DEPTH
		"near_dead":
			return "走完很快会卡死"
		"timeout":
			return "判定超时"
		"no_connect":
			return "翻开的花接不上别的列"
		"other_progress":
			return "不翻问号也有别的路能种盆"
		"state_cap":
			return "不翻问号的可达局面超过 %d 个,没证明" % LUCKY_STATE_CAP
	return reason


static func kind_name(kind: int) -> String:
	match kind:
		Kind.TRAP:
			return "TRAP"
		Kind.MASTER:
			return "MASTER"
	return "NONE"




static func _make_ctx(opts: Dictionary) -> Dictionary:
	var now: Callable = opts.get("now", Callable())
	var ms_cap: int = int(opts.get("ms_cap", DEFAULT_MS_CAP))
	var deadline: int = 0
	if now.is_valid():
		deadline = int(now.call()) + ms_cap

	var ctx: Dictionary = {"now": now, "deadline": deadline, "near_cache": {}, 
		"budget_ms": ms_cap, "verify_ms_cap": int(opts.get("verify_ms_cap", DEFAULT_VERIFY_MS_CAP))}

	if opts.has("diagnostic"):
		var diagnostic: Dictionary = opts["diagnostic"]
		diagnostic["window_text"] = "判定窗口%dms；活路验证另开%dms窗口（非严格总时限）" % [
			ms_cap, int(ctx["verify_ms_cap"])]
		ctx["diagnostic"] = diagnostic
	return ctx



static func _start_verify_phase(ctx: Dictionary) -> void :
	var now: Callable = ctx["now"]
	if int(ctx["deadline"]) > 0:
		ctx["deadline"] = int(now.call()) + int(ctx["verify_ms_cap"])

	ctx["budget_ms"] = int(ctx["verify_ms_cap"])
	_record_phase(ctx, "alive_verification")


static func _timed_out(ctx: Dictionary) -> bool:
	var now: Callable = ctx["now"]
	var expired: bool = int(ctx["deadline"]) > 0 and int(now.call()) >= int(ctx["deadline"])

	if expired and ctx.has("diagnostic"):
		(ctx["diagnostic"] as Dictionary)["reason"] = "deadline"
	return expired



static func _record_phase(ctx: Dictionary, phase: String) -> void :
	if not ctx.has("diagnostic"):
		return
	var diagnostic: Dictionary = ctx["diagnostic"]
	for key: String in ["reason", "expanded", "states", "candidates", "depth"]:
		diagnostic.erase(key)
	diagnostic["phase"] = phase
	diagnostic["budget_ms"] = int(ctx["budget_ms"])



static func _finish_task_diagnostic(result: Dictionary, info: Dictionary, diagnostic: Dictionary, 
		now: Callable, started: int, has_usable_result: bool) -> void :
	if has_usable_result or String(info.get("reason", "")) != "timeout"\
	or not now.is_valid() or String(diagnostic.get("reason", "")) != "deadline":
		return
	diagnostic["elapsed_ms"] = maxi(0, int(now.call()) - started)
	result["diagnostic"] = diagnostic



static func _remaining_ms(ctx: Dictionary) -> int:
	if int(ctx["deadline"]) <= 0:
		return 0
	var now: Callable = ctx["now"]
	return maxi(1, int(ctx["deadline"]) - int(now.call()))


static func _done(out: Dictionary, reason: String) -> Dictionary:
	out["reason"] = reason
	out["kind_name"] = kind_name(int(out["kind"]))
	return out




static func _revealed_connects(st: Dictionary, col: int, index: int, type: int) -> bool:
	var cols: Array = st["cols"]
	if col >= cols.size():
		return false
	var cc: Array[int] = cols[col]
	if cc.size() - 1 != index or cc[index] != type:
		return false
	var run_start: int = index
	while run_start > 0 and R.connection_type(st, cc[run_start - 1]) == type:
		run_start -= 1
	for other in cols.size():
		if other == col:
			continue
		var oc: Array[int] = cols[other]
		if oc.is_empty():
			continue

		if R.connection_type(st, oc[oc.size() - 1]) == type:
			for j in range(run_start, index + 1):
				if R.move_info(st, col, j, other) > 0 and not R.is_root_swap(st, col, j, other):
					return true

		for j in oc.size():
			if R.connection_type(st, oc[j]) == type and R.move_info(st, other, j, col) > 0\
			and not R.is_root_swap(st, other, j, col):
				return true
	return false




static func _stuck_without_reveal(st: Dictionary, level: JuiceLevel, ctx: Dictionary, 
		out: Dictionary) -> int:
	if R.any_ready(st):
		return 0
	var seen: Dictionary = {R.state_key(st): true}
	var pending: Array[Dictionary] = [R.clone_state(st)]
	while not pending.is_empty():
		if _timed_out(ctx):
			out["states"] = seen.size()
			return -1
		var cur: Dictionary = pending.pop_back()
		var cols: Array = cur["cols"]
		for src in cols.size():
			for j in (cols[src] as Array).size():
				for dst in cols.size():
					if R.move_info(cur, src, j, dst) <= 0:
						continue
					var nx: Dictionary = R.clone_state(cur)
					var rec: Dictionary = R.apply_move(nx, level, src, j, dst, true)
					if rec.is_empty() or not (rec["revealed"] as Array).is_empty():
						continue
					if R.any_ready(nx):
						out["states"] = seen.size()
						return 0
					var key: String = R.state_key(nx)
					if seen.has(key):
						continue
					if seen.size() >= LUCKY_STATE_CAP:
						out["states"] = seen.size()
						return -1
					seen[key] = true
					pending.append(nx)
	out["states"] = seen.size()
	return 1



static func _is_shuffle_cut(col: Array[int], j: int, st: Dictionary = {}) -> bool:
	return j > 0 and _is_shuffle_pair(st, col[j - 1], col[j])


static func _is_shuffle_pair(st: Dictionary, upper: int, lower: int) -> bool:
	if (JuiceLevel.is_frozen(upper) or JuiceLevel.is_frozen(lower))\
	and st.get("ice_mode", JuiceLevel.ICE_BLOCK_COLLECTION) == JuiceLevel.ICE_BLOCK_CONNECTION:
		return false
	return R.connection_type(st, upper) == R.connection_type(st, lower)




static func _progress_outcomes(st: Dictionary, level: JuiceLevel) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen: Dictionary = {}
	var cols: Array = st["cols"]
	for src in cols.size():
		var sc: Array[int] = cols[src]
		for j in sc.size():
			for dst in cols.size():
				if R.move_info(st, src, j, dst) <= 0:
					continue
				var nx: Dictionary = R.clone_state(st)
				var rec: Dictionary = R.apply_move(nx, level, src, j, dst)
				if rec.is_empty():
					continue
				var revealed: bool = not (rec["revealed"] as Array).is_empty()
				if not revealed and _is_shuffle_cut(sc, j, st) and (rec["deposits"] as Array).is_empty():
					continue
				var key: String = R.state_key(nx)
				if seen.has(key):
					continue
				seen[key] = true
				nx[MOVE_MARK] = {"src": src, "j": j, "dst": dst}
				if revealed:
					nx[REVEALED_MARK] = true
				out.append(nx)
	return out



static func _temptation(st: Dictionary, outcome: Dictionary, slot_of: Dictionary) -> float:
	var mv: Dictionary = outcome[MOVE_MARK]
	return _appeal(st, mv, slot_of) + _lookahead(outcome, int(mv["src"]), slot_of)



static func _appeal(st: Dictionary, mv: Dictionary, slot_of: Dictionary) -> float:
	var cols: Array = st["cols"]
	var src: int = int(mv["src"])
	var j: int = int(mv["j"])
	var dst: int = int(mv["dst"])
	var sc: Array[int] = cols[src]
	var head: int = R.connection_type(st, sc[j])
	var run: int = 0
	for i in range(j, sc.size()):
		if R.connection_type(st, sc[i]) != head or R.is_connection_blocked(st, sc[i]):
			break
		run += 1
	var junk: int = sc.size() - j - run
	var dist: int = absi(int(slot_of.get(src, src)) - int(slot_of.get(dst, dst)))
	var src_jar: int = int((st["jars"] as Array[int])[src])
	var clean: bool = j == 0 or src_jar >= 0
	for i in j:
		if R.connection_type(st, sc[i]) != src_jar:
			clean = false
			break
	var dst_jar: int = int((st["jars"] as Array[int])[dst])
	var own: bool = dst_jar >= 0 and head == dst_jar
	return APPEAL_RUN * run - APPEAL_JUNK * junk - APPEAL_DIST * dist\
	+ (APPEAL_SRC_CLEAN if clean else 0.0) + (APPEAL_OWN_POT if own else 0.0)




static func _lookahead(nx: Dictionary, src: int, slot_of: Dictionary) -> float:
	var cols: Array = nx["cols"]
	if src >= cols.size() or (cols[src] as Array).is_empty():
		return 0.0
	var sc: Array[int] = cols[src]
	var run_start: int = sc.size() - 1
	while run_start > 0 and R.connection_type(nx, sc[run_start - 1]) == R.connection_type(nx, sc[run_start]):
		run_start -= 1
	var best: float = 0.0
	for s in cols.size():
		for jj in (cols[s] as Array).size():
			if s == src and jj < run_start:
				continue
			for d in cols.size():
				if s != src and d != src:
					continue
				if R.move_info(nx, s, jj, d) <= 0:
					continue
				best = maxf(best, _appeal(nx, {"src": s, "j": jj, "dst": d}, slot_of))
	return LOOKAHEAD_DISCOUNT * best



static func _near_dead(nx: Dictionary, level: JuiceLevel, ctx: Dictionary) -> int:

	_record_phase(ctx, "near_dead_check")
	var key: String = R.state_key(nx)
	var cache: Dictionary = ctx["near_cache"]
	if cache.has(key):
		return int(cache[key])
	var v: int = 0
	if nx.has(REVEALED_MARK):
		v = 0
	elif R.is_doomed(nx, level):
		v = 1
	else:
		_record_phase(ctx, "near_dead_search")
		var opt: Dictionary = {"node_cap": NEAR_DEAD_STATE_CAP, "state_cap": NEAR_DEAD_STATE_CAP}
		if int(ctx["deadline"]) > 0:
			opt["now"] = ctx["now"]
			opt["ms_cap"] = _remaining_ms(ctx)
		var search_diagnostic: Dictionary = {}
		if ctx.has("diagnostic"):

			if opt.has("ms_cap"):
				(ctx["diagnostic"] as Dictionary)["budget_ms"] = int(opt["ms_cap"])
			opt["diagnostic"] = search_diagnostic
		v = 1 if S.full_reachability(nx, level, opt) == S.Reachability.UNWINNABLE else 0
		if not search_diagnostic.is_empty():

			var diagnostic: Dictionary = ctx["diagnostic"]
			for field: String in ["expanded", "states", "candidates"]:
				if search_diagnostic.has(field):
					diagnostic[field] = int(search_diagnostic[field])
	cache[key] = v
	return v



static func _verify_alive(nx: Dictionary, level: JuiceLevel, ctx: Dictionary) -> bool:
	if _timed_out(ctx):
		return false
	if R.is_win(nx, level):
		return true
	if R.is_doomed(nx, level):
		return false
	var opt: Dictionary = VERIFY_OPT.duplicate()
	if int(ctx["deadline"]) > 0:
		opt["now"] = ctx["now"]
		opt["ms_cap"] = _remaining_ms(ctx)

	if ctx.has("diagnostic"):
		var diagnostic: Dictionary = ctx["diagnostic"]
		diagnostic["budget_ms"] = int(opt.get("ms_cap", DEFAULT_VERIFY_MS_CAP))
		diagnostic["window_text"] += "；本次活路求解窗口%dms" % int(diagnostic["budget_ms"])
		opt["diagnostic"] = diagnostic
	var h: Dictionary = S.hint_move(nx, level, opt)
	return not h.is_empty() and not bool(h.get("guess", false))






static func _find_shuffle_exit(st: Dictionary, level: JuiceLevel, ctx: Dictionary) -> Dictionary:
	var seen: Dictionary = {R.state_key(st): true}
	var layer: Array[Dictionary] = [st]
	for depth in range(1, MASTER_MAX_DEPTH + 1):

		_record_phase(ctx, "shuffle_exit_search")
		if ctx.has("diagnostic"):
			(ctx["diagnostic"] as Dictionary)["depth"] = depth
		var next_layer: Array[Dictionary] = []
		for cur: Dictionary in layer:
			var cols: Array = cur["cols"]
			for src in cols.size():
				var sc: Array[int] = cols[src]
				for j in sc.size():
					if not _is_shuffle_cut(sc, j, cur):
						continue
					for dst in cols.size():
						if R.move_info(cur, src, j, dst) <= 0:
							continue
						var nx: Dictionary = R.clone_state(cur)
						var rec: Dictionary = R.apply_move(nx, level, src, j, dst, true)
						if rec.is_empty():
							continue

						if not (rec["revealed"] as Array).is_empty():
							continue

						if R.any_ready(nx):
							continue
						var key: String = R.state_key(nx)
						if seen.has(key):
							continue
						if seen.size() >= MASTER_STATE_CAP:
							if ctx.has("diagnostic"):
								(ctx["diagnostic"] as Dictionary)["states"] = seen.size()
							return {}
						seen[key] = true
						next_layer.append(nx)
		for cur: Dictionary in next_layer:

			_record_phase(ctx, "progress_outcomes")
			if ctx.has("diagnostic"):
				(ctx["diagnostic"] as Dictionary)["depth"] = depth
				(ctx["diagnostic"] as Dictionary)["states"] = seen.size()
			for outcome: Dictionary in _progress_outcomes(cur, level):
				var verdict: int = _near_dead(outcome, level, ctx)

				if ctx.has("diagnostic"):
					(ctx["diagnostic"] as Dictionary)["depth"] = depth
				if verdict == 0:
					if _timed_out(ctx):
						return {}
					return {"depth": depth, "state": outcome}
				if _timed_out(ctx):
					return {}
		if next_layer.is_empty():
			return {}
		layer = next_layer
	return {}
