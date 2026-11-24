extends RefCounted

















const CASES: Array[Dictionary] = [
	{
		"kind": "TRAP", "move": [0, 1, 1], "answer": [4, 2, 3], 
		"note": "4 色 5 列,3 种推进走法只 1 条活", 
		"level": {"capacity": 3, "targetCups": 4, "incoming": ["x", "x", "x"], 
			"initial": ["-|1,2,3", "0|2", "1|0,0,1", "3|0,3", "2|1,2,3"]}, 
	}, 
	{
		"kind": "TRAP", "move": [1, 2, 0], "answer": [3, 2, 2], 
		"note": "5 色 6 列,3 种推进走法只 1 条活", 
		"level": {"capacity": 4, "targetCups": 5, "incoming": ["x", "x", "x", "x"], 
			"initial": ["-|0,0,2", "2|1,1,2", "0|1,4,4", "4|1,3,4", "3|0,2,3,4", "1|0,2,3,3"]}, 
	}, 
	{
		"kind": "TRAP", "move": [5, 3, 3], "answer": [6, 3, 0], 
		"note": "6 色 7 列,3 种推进走法只 1 条活", 
		"level": {"capacity": 4, "targetCups": 6, "incoming": ["x", "x", "x", "x", "x"], 
			"initial": ["-|1,3,5", "3|2,3,3,5", "5|0,0,4,4", "4|2", "0|0,3,4,5", "2|0,1,1,2", "1|1,2,4,5"]}, 
	}, 
	{
		"kind": "MASTER", "move": [1, 1, 4], "answer": [], 
		"note": "4 色 5 列,唯一推进走法会死,要先倒腾 1 步", 
		"level": {"capacity": 3, "targetCups": 4, "incoming": ["x", "x", "x"], 
			"initial": ["-|0,0,1", "2|1,3", "3|0,3", "1|2,2,2", "0|1,3"]}, 
	}, 
	{
		"kind": "MASTER", "move": [1, 1, 3], "answer": [], 
		"note": "6 色 7 列,2 种推进走法全死,要先倒腾 1 步", 
		"level": {"capacity": 4, "targetCups": 6, "incoming": ["x", "x", "x", "x", "x"], 
			"initial": ["-|1,4,4,5", "2|3,3,5", "3|0,1,2,5", "5|0,3", "0|0,2,4,5", "4|0,1,2,3", "1|1,2,4"]}, 
	}, 
	{
		"kind": "MASTER", "move": [4, 1, 0], "answer": [], 
		"note": "5 色 7 列(2 白盆),没有推进走法,要先倒腾 2 步", 
		"level": {"capacity": 4, "targetCups": 5, "incoming": ["x", "x", "x", "x"], 
			"initial": ["-|", "-|3,4,4", "4|1", "2|0,0,2,2", "3|0,3,4,4", "1|0,2,3,3", "0|1,1,1,2"]}, 
	}, 
	{
		"kind": "MASTER", "move": [0, 2, 6], "answer": [], 
		"note": "6 色 7 列,没有推进走法,要先倒腾 2 步", 
		"level": {"capacity": 4, "targetCups": 6, "incoming": ["x", "x", "x", "x", "x"], 
			"initial": ["-|3,4,5", "5|0,1,3", "1|0,0,1,2", "0|4,4,5,5", "2|0,1,2,2", "3|1,2,3,3", "4|4,5"]}, 
	}, 
]



static func get_case(n: int) -> Dictionary:
	if n < 1 or n > CASES.size():
		return {}
	return CASES[n - 1]



static func describe_move(c: Dictionary, key: String = "move") -> String:
	var mv: Array = c[key]
	var col: String = String((c["level"]["initial"] as Array)[int(mv[0])])
	var flowers: String = col.split("|")[1]
	var count: int = flowers.split(",").size() - int(mv[1])
	return "拖第 %d 列下端 %d 朵 → 第 %d 列" % [int(mv[0]) + 1, count, int(mv[2]) + 1]
