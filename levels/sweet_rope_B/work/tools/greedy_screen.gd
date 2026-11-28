extends SceneTree
# Usage: -- in.json out.json shard nshards
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

# policy 0: eps-greedy on S.move_score; policy 1: softmax(move_score / T) with T=eps
func play(lv: JuiceLevel, rng: RandomNumberGenerator, policy: int, eps: float, max_steps: int) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	var steps := 0
	var res := "cap"
	while steps < max_steps:
		if R.is_win(st, lv):
			res = "win"; break
		var ms: Array = R.useful_moves(st)
		if ms.is_empty():
			res = "stuck"; break
		var mv: Dictionary
		if policy == 0:
			if rng.randf() >= eps:
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
		else:
			var ws: Array = []
			var mx := -1e9
			for m: Dictionary in ms:
				var sc2: float = S.move_score(st, m)
				ws.append(sc2); mx = maxf(mx, sc2)
			var tot := 0.0
			for i in ws.size():
				ws[i] = exp((ws[i] - mx) / eps); tot += ws[i]
			var r := rng.randf() * tot
			var k := 0
			while k < ws.size() - 1 and r > ws[k]:
				r -= ws[k]; k += 1
			mv = ms[k]
		if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
			res = "invalid"; break
		steps += 1
	return {"res": res, "steps": steps, "done": int(st["done"])}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var shard := int(args[2])
	var nsh := int(args[3])
	var out: Array = []
	var configs := [[0, 0.45], [1, 4.0]]
	for idx in arr.size():
		if idx % nsh != shard:
			continue
		var item: Dictionary = arr[idx]
		var lv := JuiceLevel.from_dict(item["raw"])
		if not lv.validate().is_empty():
			continue
		var t0 := Time.get_ticks_msec()
		var total: int = lv.groups_total
		var o: Dictionary = {"uid": item["uid"], "cfg": []}
		for c in configs:
			var per: Array = []
			for sd in [11]:
				var rng := RandomNumberGenerator.new()
				rng.seed = sd
				var w := 0
				var dn := 0.0
				var wsteps := 0.0
				for p in 30:
					var r: Dictionary = play(lv, rng, c[0], c[1], 300)
					if r.res == "win":
						w += 1; wsteps += r.steps
					dn += float(r.done) / total
				per.append({"win": w / 30.0, "done": dn / 30.0, "wsteps": (wsteps / w) if w > 0 else -1.0})
			o["cfg"].append({"policy": c[0], "param": c[1], "seeds": per})
		o["t"] = Time.get_ticks_msec() - t0
		out.append(o)
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out)); f.close()
	quit()
