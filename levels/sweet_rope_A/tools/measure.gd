extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var items: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var out := FileAccess.open(args[1], FileAccess.WRITE)
	var rng := RandomNumberGenerator.new()
	for raw: Dictionary in items:
		var level := JuiceLevel.from_dict(raw)
		var errors := level.validate()
		var result := {"key": raw.seed, "id": raw.id, "errors": errors}
		if not errors.is_empty():
			out.store_line(JSON.stringify(result))
			continue
		var search := JuiceSolver.begin_full_search(JuiceRules.make_state(level), level)
		var status := JuiceSolver.advance_full_search(search, level, {"node_cap": 4000, "state_cap": 20000})
		result["status"] = ["UNKNOWN", "WINNABLE", "UNWINNABLE"][status]
		result["expanded"] = search.expanded
		if status == JuiceSolver.Reachability.WINNABLE:
			rng.seed = 12345
			var wins := 0
			var branch_sum := 0
			var branch_count := 0
			for attempt in 30:
				var state := JuiceRules.make_state(level)
				for step in 400:
					if JuiceRules.is_win(state, level):
						wins += 1
						break
					var moves := JuiceRules.useful_moves(state)
					if moves.is_empty():
						break
					branch_sum += moves.size()
					branch_count += 1
					var move: Dictionary = moves[rng.randi_range(0, moves.size() - 1)]
					if JuiceRules.apply_move(state, level, move.src, move.j, move.dst).is_empty():
						break
			var rate := wins / 30.0
			var branch := float(branch_sum) / maxi(1, branch_count)
			result.merge({"win_rate": rate, "branch": branch,
				"score": maxf(0, 9.9 + 8.33 * log(search.expanded + 1.0) - 6.01 * branch - 35.65 * rate)})
		out.store_line(JSON.stringify(result))
	out.flush()
	quit()
