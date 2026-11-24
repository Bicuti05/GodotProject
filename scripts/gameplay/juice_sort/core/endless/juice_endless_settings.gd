class_name JuiceEndlessSettings
extends RefCounted

const CAPACITY: int = 5
const COLUMNS: int = 6
const FLOWERS: int = 18
const INITIAL_TIME_MS: int = 120000
const CUP_TIME_MS: int = 3000
const MAX_COLORS: int = 10
const HISTORY_LIMIT: int = 32
const CANDIDATES: int = 32
const FIRST_BUDGET_MS: int = 1000
const RETRY_BUDGET_MS: int = 2000
const RECOVERY_WINDOW: int = 6
const LOOKAHEAD: int = 3
const QUEUE_TARGET: int = 5
const SAFE_SEARCH_MS: int = 180
const DIFFICULTY_CONFIG: JuiceEndlessDifficultyConfig = preload("res://scripts/gameplay/juice_sort/core/endless/juice_endless_difficulty_config.tres")
const INITIAL_LAYOUTS: Array[Array] = [
	["-|", "0|0,2,0,1", "1|0,4,2", "2|2,2,3,1", "3|3,4,1,1", "4|0,3,1"], 
	["-|1", "0|0,1,2", "1|3,2,3,0", "2|2,0,0,1", "3|1,2", "4|4,4,0,3"], 
	["-|2,1", "0|3,0", "1|2,3,3,1", "2|0,0,4,2", "3|1,4,0", "4|1,2,0"], 
	["-|1,2,4", "0|0,0,1,2,0", "1|2", "2|4,2,3", "3|3,1,0,3", "4|1,0"], 
	["-|0,2", "0|1,0,3,1", "1|1,2", "2|2,4,3", "3|4,0,3", "4|1,1,0,2"], 
	["-|0", "0|1,3,4,1", "1|0,1,4", "2|0,2,3,2,2", "3|1,3,2", "4|0,2"], 
	["-|4,0,2", "0|3,1,2", "1|0,2", "2|1,4", "3|3,2,3,1", "4|1,0,0,2"], 
	["-|", "0|2,1,0", "1|2,0,3,2,2", "2|4,0,1", "3|1,3,2", "4|1,3,0,4"], 
	["-|1", "0|4,1,3", "1|3,0,4", "2|2,0", "3|2,0,3,2,2", "4|2,1,1,0"], 
]

const OPENING_MOVES: Array[Array] = [
	[[2, 0, 0], [3, 3, 2], [5, 2, 2], [1, 3, 2], [4, 2, 2]], 
	[[1, 1, 0], [2, 3, 1], [4, 1, 0], [3, 3, 4], [3, 1, 1], [5, 3, 2], [5, 2, 1]], 
	[[4, 2, 1], [5, 2, 1], [5, 0, 0], [1, 0, 5], [5, 1, 1], [3, 2, 4], [3, 0, 1]], 
	[[1, 3, 2], [1, 0, 5], [2, 2, 1], [4, 3, 3], [4, 2, 1], [5, 4, 4], [5, 1, 1]], 
	[[2, 1, 0], [1, 3, 2], [5, 3, 0], [1, 1, 5], [1, 0, 2], [5, 2, 1], [5, 0, 2]], 
	[[5, 0, 0], [3, 0, 5], [5, 3, 3], [4, 2, 3], [0, 2, 3], [5, 2, 4], [5, 1, 3]], 
	[[1, 2, 0], [3, 0, 1], [0, 2, 3], [2, 1, 5], [4, 1, 3], [3, 3, 4], [5, 3, 3]], 
	[[3, 0, 0], [2, 3, 3], [4, 2, 3], [2, 1, 1], [2, 0, 3], [1, 1, 2], [1, 0, 3]], 
	[[3, 1, 5], [4, 3, 3], [1, 2, 4], [5, 1, 0], [4, 0, 5], [5, 2, 4], [5, 0, 3]], 
]

static func color_limit(done: int) -> int:
	return mini(MAX_COLORS, DIFFICULTY_CONFIG.color_limit(done))


static func preferred_flower_colors(done: int) -> int:
	return DIFFICULTY_CONFIG.preferred_flower_colors(done)


static func search_ms(done: int) -> int:
	return 600 if done >= 20 else (350 if done >= 8 else SAFE_SEARCH_MS)


static func target_score(done: int) -> float:
	return DIFFICULTY_CONFIG.target_score(done)


static func initial_layout(seed_value: int) -> Array[String]:
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_value
	var colors: Array[int] = [0, 1, 2, 3, 4]
	for i in range(colors.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var value: int = colors[i]
		colors[i] = colors[j]
		colors[j] = value
	var rows: Array[String] = []
	var template: Array = INITIAL_LAYOUTS[posmod(seed_value, INITIAL_LAYOUTS.size())]
	for ci: int in _column_order(seed_value):
		var parts: PackedStringArray = String(template[ci]).split("|")
		var beads: Array[int] = []
		if not parts[1].is_empty():
			for color: String in parts[1].split(","):
				beads.append(colors[int(color)])
		var jar: int = -1 if parts[0] == "-" else colors[int(parts[0])]
		rows.append(JuiceLevel.encode_col(jar, beads))
	return rows


static func _column_order(seed_value: int) -> Array[int]:
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_value ^ 1831565813
	var order: Array[int] = [0, 1, 2, 3, 4, 5]

	for i in range(COLUMNS - 1, 1, -1):
		var j: int = rng.randi_range(1, i)
		var value: int = order[i]
		order[i] = order[j]
		order[j] = value
	return order


static func opening_moves(seed_value: int) -> Array[Dictionary]:
	var path: Array[Dictionary] = []
	var order: Array[int] = _column_order(seed_value)
	for move: Array in OPENING_MOVES[posmod(seed_value, OPENING_MOVES.size())]:
		path.append({"src": order.find(int(move[0])), "j": int(move[1]), "dst": order.find(int(move[2]))})
	return path


static func normal_column(beads: Array) -> bool:
	var colors: Dictionary = {}
	var repeats: int = 0
	for i in beads.size():
		colors[beads[i]] = true
		if i > 0 and beads[i] == beads[i - 1]:
			repeats += 1
	return colors.size() >= 3 and repeats <= 1


static func mixed_neighbors(st: Dictionary) -> int:
	var mixed: int = 0
	for col: Array[int] in st["cols"] as Array:
		for j in range(1, col.size()):
			if col[j] != col[j - 1]:
				mixed += 1
	return mixed
