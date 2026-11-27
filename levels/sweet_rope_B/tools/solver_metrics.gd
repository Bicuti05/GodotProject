extends SceneTree
# Usage: -- in.json out.json shard nshards [mode]
# in.json: [{uid, raw}]  -> out.json: [{uid, ...metrics}]
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

func hidden_count(st: Dictionary) -> int:
	var c := 0
	for col: Array in st["cols"]:
		for v: int in col:
			if JuiceLevel.is_hidden(v):
				c += 1
	return c

func hidden_pos(st: Dictionary) -> Dictionary:
	# depth = number of flowers between hidden flower and tail (0 = tail)
	var n := 0
	var dsum := 0.0
	var runs := 0
	var cols_h := 0
	var under := 0   # hidden flowers lying under a non-hidden flower of a different type than pot
	for col: Array in st["cols"]:
		var prev_h := false
		var any := false
		for i in col.size():
			var v: int = col[i]
			var h: bool = JuiceLevel.is_hidden(v)
			if h:
				n += 1; any = true
				dsum += float(col.size() - 1 - i)
				if not prev_h:
					runs += 1
			prev_h = h
		if any:
			cols_h += 1
	return {"n": n, "mean_depth": (dsum / n) if n > 0 else 0.0, "runs": runs, "cols": cols_h}

func hidden_burden(st: Dictionary) -> int:
	var b := 0
	for col: Array in st["cols"]:
		for i in col.size():
			if JuiceLevel.is_hidden(int(col[i])):
				b += col.size() - i
	return b

func locks_active(st: Dictionary) -> int:
	var c := 0
	for l: Dictionary in R._locks_for(st):
		if not l.is_empty():
			c += 1
	return c

func is_dead_state(st: Dictionary, lv: JuiceLevel) -> bool:
	return R.is_doomed(st, lv) or not R.has_any_move(st)

# random / greedy playout. policy: 0 random, 1 eps-greedy(move_score)
func play(lv: JuiceLevel, rng: RandomNumberGenerator, policy: int, eps: float, max_steps: int) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	var steps := 0
	var bsum := 0.0
	var bn := 0
	var doomed_at := -1
	var res := "cap"
	while steps < max_steps:
		if R.is_win(st, lv):
			res = "win"; break
		if doomed_at < 0 and R.is_doomed(st, lv):
			doomed_at = steps
		var ms: Array = R.useful_moves(st)
		if ms.is_empty():
			res = "stuck"; break
		bsum += ms.size(); bn += 1
		var mv: Dictionary
		if policy == 1 and rng.randf() >= eps:
			var best := -1e9
			var cands: Array = []
			for m: Dictionary in ms:
				var sc: float = S.move_score(st, m)
				if sc > best + 1e-6:
					best = sc; cands = [m]
				elif absf(sc - best) <= 1e-6:
					cands.append(m)
			mv = cands[rng.randi_range(0, cands.size() - 1)]
		else:
			mv = ms[rng.randi_range(0, ms.size() - 1)]
		if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
			res = "invalid"; break
		steps += 1
	return {"res": res, "steps": steps, "done": int(st["done"]), "b": bsum / maxi(1, bn), "doomed_at": doomed_at}

func summarize(plays: Array, total: int) -> Dictionary:
	var w := 0
	var stuck := 0
	var done_sum := 0.0
	var b := 0.0
	var wsteps := 0.0
	var doomed := 0
	var doomed_at := 0.0
	for p: Dictionary in plays:
		if p.res == "win":
			w += 1; wsteps += p.steps
		if p.res == "stuck":
			stuck += 1
		done_sum += float(p.done) / total
		b += p.b
		if p.doomed_at >= 0:
			doomed += 1; doomed_at += p.doomed_at
	var n := float(plays.size())
	return {"win": w / n, "stuck": stuck / n, "done_frac": done_sum / n, "branch": b / n,
		"win_steps": (wsteps / w) if w > 0 else -1.0, "doomed_frac": doomed / n,
		"doomed_at": (doomed_at / doomed) if doomed > 0 else -1.0}

# Beam search. returns {win, depth, path, stats}
func beam(lv: JuiceLevel, width: int, max_depth: int) -> Dictionary:
	var root: Dictionary = R.make_state(lv)
	var total: int = lv.groups_total
	var nodes: Array = [{"st": root, "p": -1, "mv": {}}]   # all nodes (for path)
	var layer: Array = [0]
	var seen: Dictionary = {R.state_key(root): true}
	var expanded := 0
	var bsum := 0.0
	var children_total := 0
	var children_dead := 0
	var layer_sizes: Array = []
	for depth in range(1, max_depth + 1):
		var cand: Array = []
		for ni: int in layer:
			var st: Dictionary = nodes[ni]["st"]
			var ms: Array = R.useful_moves(st)
			expanded += 1
			bsum += ms.size()
			for mv: Dictionary in ms:
				var nx: Dictionary = R.clone_state(st)
				if R.apply_move(nx, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
					continue
				children_total += 1
				if R.is_win(nx, lv):
					nodes.append({"st": nx, "p": ni, "mv": mv})
					return _beam_result(true, depth, nodes, nodes.size() - 1, expanded, bsum, children_total, children_dead, layer_sizes)
				if is_dead_state(nx, lv):
					children_dead += 1
					continue
				var key: String = R.state_key(nx)
				if seen.has(key):
					continue
				seen[key] = true
				var h: float = float(int(nx["done"])) * 12.0 - float(S.sort_lower_bound(nx))
				cand.append({"h": h, "st": nx, "p": ni, "mv": mv})
		if cand.is_empty():
			return _beam_result(false, depth, nodes, -1, expanded, bsum, children_total, children_dead, layer_sizes)
		cand.sort_custom(func(a, b): return a.h > b.h)
		if cand.size() > width:
			cand.resize(width)
		layer = []
		for c: Dictionary in cand:
			nodes.append({"st": c.st, "p": c.p, "mv": c.mv})
			layer.append(nodes.size() - 1)
		layer_sizes.append(layer.size())
	return _beam_result(false, max_depth, nodes, -1, expanded, bsum, children_total, children_dead, layer_sizes)

func _beam_result(win: bool, depth: int, nodes: Array, last: int, expanded: int, bsum: float, ct: int, cd: int, ls: Array) -> Dictionary:
	var path: Array = []
	var i := last
	while win and i > 0:
		path.append({"mv": nodes[i]["mv"], "pi": nodes[i]["p"]})
		i = nodes[i]["p"]
	path.reverse()
	var states: Array = []
	if win:
		for e: Dictionary in path:
			states.append(nodes[e.pi]["st"])
	return {"win": win, "depth": depth, "path": path, "states": states, "expanded": expanded,
		"branch": bsum / maxi(1, expanded), "dead_child": float(cd) / maxi(1, ct)}

func path_stats(lv: JuiceLevel, b: Dictionary) -> Dictionary:
	var path: Array = b["path"]
	var states: Array = b["states"]
	var nonmono := 0
	var low := 0
	var rank_sum := 0.0
	var reveal := 0
	var lock_steps := 0
	var wide := 0
	var brs := 0.0
	var forced := 0
	var hburden := 0.0
	for i in path.size():
		var st: Dictionary = states[i]
		var mv: Dictionary = path[i]["mv"]
		var ms: Array = R.useful_moves(st)
		brs += ms.size()
		if ms.size() <= 2:
			forced += 1
		var sc: float = S.move_score(st, mv)
		var better := 0
		for m: Dictionary in ms:
			if S.move_score(st, m) > sc + 1e-6:
				better += 1
		rank_sum += float(better) / maxi(1, ms.size() - 1)
		if sc <= 0.0:
			low += 1
		var col: Array = st["cols"][int(mv.src)]
		var mono := true
		for q in range(int(mv.j) + 1, col.size()):
			if col[q] != col[int(mv.j)]:
				mono = false
		if not mono:
			nonmono += 1
		if int(mv.k) > 1:
			wide += 1
		if locks_active(st) > 0:
			lock_steps += 1
		var hb: int = hidden_count(st)
		hburden += float(hidden_burden(st))
		if i + 1 < states.size() and hidden_count(states[i + 1]) < hb:
			reveal += 1
	var n: float = maxf(1.0, path.size())
	return {"nonmono": nonmono / n, "lowscore": low / n, "rank": rank_sum / n, "reveal": reveal / n,
		"lock_steps": lock_steps / n, "wide": wide / n, "path_branch": brs / n, "forced": forced / n, "hburden": hburden / n, "reveal_n": reveal}

func label(st: Dictionary, lv: JuiceLevel, cap: int) -> int:
	# 1 winnable, 2 unwinnable, 0 unknown
	var s: Dictionary = S.begin_full_search(st, lv)
	return S.advance_full_search(s, lv, {"node_cap": cap, "state_cap": 6 * cap})

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var shard := int(args[2])
	var nsh := int(args[3])
	var out: Array = []
	var seeds := [12345, 777, 4242]
	for idx in arr.size():
		if idx % nsh != shard:
			continue
		var item: Dictionary = arr[idx]
		var lv := JuiceLevel.from_dict(item["raw"])
		if not lv.validate().is_empty():
			continue
		var o: Dictionary = {"uid": item["uid"]}
		var t0 := Time.get_ticks_msec()
		var total: int = lv.groups_total
		o["total"] = total
		var st0: Dictionary = R.make_state(lv)
		o["hidden0"] = hidden_count(st0)
		o["locks0"] = locks_active(st0)
		o["hpos"] = hidden_pos(st0)
		# 1. random play: 3 seeds x 40
		var rng := RandomNumberGenerator.new()
		var rs: Array = []
		for sd in seeds:
			rng.seed = sd
			var pl: Array = []
			for p in 40:
				pl.append(play(lv, rng, 0, 0.0, 300))
			rs.append(summarize(pl, total))
		o["rand_seeds"] = rs
		var tr := Time.get_ticks_msec()
		o["t_rand"] = tr - t0
		# 2. greedy eps 0.15 / eps 0.35 (2 seeds x 20)
		var gs: Array = []
		for eps in [0.0, 0.15, 0.35]:
			rng.seed = 999
			var pl: Array = []
			for p in (1 if eps == 0.0 else 30):
				pl.append(play(lv, rng, 1, eps, 300))
			gs.append(summarize(pl, total))
		o["greedy"] = gs
		var tg := Time.get_ticks_msec()
		o["t_greedy"] = tg - tr
		# 3. DFS solver (as in first pass) keep_path
		var srch: Dictionary = S.begin_full_search(R.make_state(lv), lv, false, true)
		var res: int = S.advance_full_search(srch, lv, {"node_cap": 4000, "state_cap": 20000})
		o["dfs_res"] = res
		o["dfs_expanded"] = int(srch["expanded"])
		o["dfs_states"] = (srch["seen"] as Dictionary).size()
		o["dfs_path"] = (srch["path"] as Array).size()
		var td := Time.get_ticks_msec()
		o["t_dfs"] = td - tg
		# 4. beam widths
		var bw: Array = []
		var best: Dictionary = {}
		var wins_seen := 0
		for w in [1, 3, 8, 20, 50, 120]:
			var b: Dictionary = beam(lv, w, 160)
			bw.append({"w": w, "win": b.win, "depth": b.depth, "dead_child": b.dead_child, "branch": b.branch, "exp": b.expanded})
			if b.win:
				wins_seen += 1
				if best.is_empty() or b.depth < best.depth:
					best = b
				if wins_seen >= 2:
					break
		o["beam"] = bw
		var tb := Time.get_ticks_msec()
		o["t_beam"] = tb - td
		if not best.is_empty():
			o["path"] = path_stats(lv, best)
			o["opt_len"] = best.depth
		if not (args.size() > 4 and args[4] == "full"):
			o["t_total"] = Time.get_ticks_msec() - t0
			out.append(o)
			continue
		# 5. root moves labelled
		var root_ms: Array = R.useful_moves(st0)
		var lw := 0
		var lu := 0
		var lk := 0
		for m: Dictionary in root_ms:
			var nx: Dictionary = R.clone_state(st0)
			if R.apply_move(nx, lv, int(m.src), int(m.j), int(m.dst)).is_empty():
				continue
			var l: int = 2 if is_dead_state(nx, lv) else label(nx, lv, 300)
			if l == 1: lw += 1
			elif l == 2: lu += 1
			else: lk += 1
		o["root"] = {"n": root_ms.size(), "win": lw, "lost": lu, "unk": lk}
		var tl := Time.get_ticks_msec()
		o["t_root"] = tl - tb
		# 6. random trajectories labelled at checkpoints
		rng.seed = 2024
		var tw := 0
		var tu := 0
		var tk := 0
		var trap_steps: Array = []
		var trap_plays := 0
		for p in 6:
			var st: Dictionary = R.make_state(lv)
			var step := 0
			var trapped := false
			while step < 120 and not R.is_win(st, lv):
				if step % 8 == 0:
					var l: int = 2 if is_dead_state(st, lv) else label(st, lv, 150)
					if l == 1: tw += 1
					elif l == 2:
						tu += 1; trapped = true; trap_steps.append(step); break
					else: tk += 1
				var ms: Array = R.useful_moves(st)
				if ms.is_empty():
					break
				var mv: Dictionary = ms[rng.randi_range(0, ms.size() - 1)]
				if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
					break
				step += 1
			if trapped:
				trap_plays += 1
		o["traj"] = {"w": tw, "u": tu, "k": tk, "trap_plays": trap_plays, "trap_steps": trap_steps}
		o["t_traj"] = Time.get_ticks_msec() - tl
		o["t_total"] = Time.get_ticks_msec() - t0
		out.append(o)
		print("L %d %s t=%d" % [idx, item["uid"].substr(0, 6), o["t_total"]])
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out)); f.close()
	quit()
