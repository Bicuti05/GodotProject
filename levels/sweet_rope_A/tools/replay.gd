extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	var failures := 0
	for raw: Dictionary in rows:
		var level := JuiceLevel.from_dict(raw)
		var state := JuiceRules.make_state(level)
		var moves := _shortest_sample(level)
		if moves.is_empty():
			var search := JuiceSolver.begin_full_search(state, level, false, true)
			JuiceSolver.advance_full_search(search, level, {"node_cap": 18000, "state_cap": 70000})
			moves = search.path
		var events := {"revealed": 0, "unlocked": 0, "melted": 0}
		for move: Dictionary in moves:
			var record := JuiceRules.apply_move(state, level, move.src, move.j, move.dst)
			if record.is_empty():
				break
			events.revealed += (record.revealed as Array).size()
			events.unlocked += (record.unlocked as Array).size()
			for deposit: Dictionary in record.deposits:
				events.melted += (deposit.melted as Array).size()
		var won := JuiceRules.is_win(state, level)
		output.store_line(JSON.stringify({"id": raw.id, "won": won, "moves": moves.size(), "events": events}))
		if not won:
			failures += 1
	output.flush()
	quit(0 if failures == 0 else 1)


func _shortest_sample(level: JuiceLevel) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var shortest: Array = []
	for attempt in 30:
		var state := JuiceRules.make_state(level)
		var path: Array = []
		for step in 400:
			if JuiceRules.is_win(state, level):
				if shortest.is_empty() or path.size() < shortest.size():
					shortest = path
				break
			var moves := JuiceRules.useful_moves(state)
			if moves.is_empty():
				break
			var move: Dictionary = moves[rng.randi_range(0, moves.size() - 1)]
			if JuiceRules.apply_move(state, level, move.src, move.j, move.dst).is_empty():
				break
			path.append(move)
	return shortest
