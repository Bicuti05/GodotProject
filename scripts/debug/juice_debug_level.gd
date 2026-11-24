class_name JuiceDebugLevel
extends RefCounted

const CHALLENGE_CASES = preload("res://scripts/debug/juice_challenge_cases.gd")


const MYSTERY_AUTO_UNLOCK_TEST_ROW: Dictionary = {
	"capacity": 4, 
	"targetCups": 2, 
	"initial": ["0|0,0,0", "1|?1,1", "-|?1,1,0"], 
	"incoming": ["x"], 
	"note": "问号自动解开一步触达测试盘面", 
}




const MIN_ROWS: = 3
const DEFAULT_ROWS: = 5
const MAX_ROWS: = 8
const EIGHT_COLUMNS_ROWS: = {
	3: {
		"id": 2, 
		"capacity": 3, 
		"targetCups": 8, 
		"initial": [
			"0|0,0", "1|0", "2|1,2,0", "1|1,3,1", 
			"0|2,0,1", "1|0,1,0", "0|0,1,0", 
		], 
		"incoming": ["3|3,1,1", "-|2,3,1"], 
		"note": "8 columns x 3 rows layout test", 
	}, 
	4: {
		"id": 2, 
		"capacity": 4, 
		"targetCups": 8, 
		"initial": [
			"1|1,0,1", "2|1,0,1,0", "1|3,1,3,0", "3|2,3,1,0", 
			"0|0,1", "1|1,2,1", "0|0,1,0,1", 
		], 
		"incoming": ["0|1,0,0,2", "-|2,0,3,0"], 
		"note": "8 columns x 4 rows layout test", 
	}, 
	5: {
		"id": 2, 
		"capacity": 5, 
		"targetCups": 8, 
		"initial": [
			"0|0,3,0,1,0", "3|2,0,3,0", "2|2,1,0,1,0", "1|0,1,2,0", 
			"0|0,1,3,1,0", "1|0,2,1,0,1", "0|0,1", 
		], 
		"incoming": ["1|1,3,1,1,2", "-|0,3,1,1,1"], 
		"note": "8 columns x 5 rows layout test", 
	}, 
	6: {
		"id": 2, 
		"capacity": 6, 
		"targetCups": 8, 
		"initial": [
			"0|0,3,0,1,0", "3|2,0,3,0,2,0", "2|2,1,0,1,0", 
			"1|0,1,2,0,1,3", "0|0,3,1,0,1", "1|0,2,1,0,1", 
			"0|0,1,0,1,0,1", 
		], 
		"incoming": ["1|1,3,1,1,2", "-|0,3,1,1,1"], 
		"note": "8 columns x 6 rows layout test", 
	}, 
	7: {
		"id": 2, 
		"capacity": 7, 
		"targetCups": 8, 
		"initial": [
			"0|0,0,0,0,0,0", "0|0,0,0,0,0,0", "0|0,0,0,0,0,0", 
			"0|0,0,0,0,0,0", "0|0,0,0,0,0,0", "-|0,0", "-|0,0,0", 
		], 
		"incoming": [
			"0|0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0", 
			"-|", "-|", "-|", "-|", 
		], 
		"note": "8 columns x 7 rows layout test", 
	}, 
	8: {
		"id": 2, 
		"capacity": 8, 
		"targetCups": 8, 
		"initial": [
			"0|0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0", 
			"0|0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0", "-|0,0", "-|0,0,0", 
		], 
		"incoming": [
			"0|0,0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0,0", "0|0,0,0,0,0,0,0,0", 
			"-|", "-|", "-|", "-|", 
		], 
		"note": "8 columns x 8 rows layout test", 
	}, 
}




const LONG_ROPE_CASES: Array[Dictionary] = [
	{"capacity": 8, "targetCups": 4, "initial": ["-|2,1,2,0,2,3", "0|1,2,3", "1|0,0,0,1,3,0,3,0", "2|2,2,3,1,3,1,3", "3|1,1,2,0,2,0,1,3"], "incoming": [], "note": "long_rope #1 · 4色 · 容量8 · 1白盆 · 难度 68.5"}, 
	{"capacity": 8, "targetCups": 4, "initial": ["-|", "0|3,0,1,2,3,1,2,1", "1|2,0,1,3,0,3,0,1", "2|1,3,2,1,0,3,2,1", "3|0,2,0,3,2,0,3,2"], "incoming": [], "note": "long_rope #2 · 4色 · 容量8 · 1白盆 · 难度 40.5"}, 
	{"capacity": 8, "targetCups": 5, "initial": ["-|1,2,1,0,1,0,4,3", "0|4,3,2,0,1,3,4,2", "1|0,1,4,3,0,3,4,0", "2|", "3|2,4,2,1,2,1,2,4", "4|3,0,1,4,3,0,2,3"], "incoming": [], "note": "long_rope #3 · 5色 · 容量8 · 1白盆 · 难度 60"}, 
	{"capacity": 8, "targetCups": 5, "initial": ["-|2,3,4,3,0,2,1", "0|0,3,1,0,4,0,2,1", "1|1,2", "2|2,1,4,0,4,0,4", "3|3,3,2,1,3,2,1,4", "4|4,3,1,3,0,2,0,4"], "incoming": [], "note": "long_rope #4 · 5色 · 容量8 · 1白盆 · 难度 79"}, 
	{"capacity": 9, "targetCups": 4, "initial": ["-|3,0,2,0,1", "0|1,3,1,3,1,3", "1|2,3,1,0,2,0,2,1,2", "2|3,2,0,2,3,0,1", "3|2,0,2,0,1,3,1,3,0"], "incoming": [], "note": "long_rope #5 · 4色 · 容量9 · 1白盆 · 难度 72"}, 
	{"capacity": 10, "targetCups": 4, "initial": ["-|1,2,1,2,3,2,3,0,3,1", "0|0,2,0,2,1,0,3,1,2,0", "1|3,1,2,0,2,0,1,0,1,3", "2|", "3|3,1,3,2,1,3,0,3,0,2"], "incoming": [], "note": "long_rope #6 · 4色 · 容量10 · 1白盆 · 难度 46.5"}, 
]




























static func load_from_text(text: String, pick_level: int = 0, as_level: int = 0) -> Dictionary:
	if text.strip_edges().is_empty():
		return _fail("没收到 JSON")
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return _fail("JSON 解析失败(注意 cheat 面板按空格切参数,整段 JSON 里不要有换行)")

	var rows: Array = []
	if parsed is Array:
		rows = parsed
	elif parsed is Dictionary:
		var doc: Dictionary = parsed
		if doc.has("levels") and doc["levels"] is Array:
			rows = doc["levels"]
		else:
			rows = [doc]
	else:
		return _fail("JSON 顶层既不是对象也不是数组")
	if rows.is_empty():
		return _fail("JSON 里没有关卡")

	var row: Dictionary = {}
	if pick_level > 0:
		for r: Variant in rows:
			if r is Dictionary and int((r as Dictionary).get("id", 0)) == pick_level:
				row = r
				break
		if row.is_empty():
			return _fail("这份 JSON 里没有第 %d 关(共 %d 关)" % [pick_level, rows.size()])
	elif rows[0] is Dictionary:
		row = rows[0]
	else:
		return _fail("关卡不是 JSON 对象")

	var juice: = JuiceLevel.from_dict(row)
	var errs: Array[String] = juice.validate()
	if not errs.is_empty():
		return {
			"ok": false, 
			"message": "题面校验不通过(%d 项),没有进关" % errs.size(), 
			"level": 0, 
			"errors": errs, 
		}

	var lv: int = as_level
	if lv <= 0:
		lv = int(row.get("id", 0))
	if lv <= 0:
		lv = UserState.get_current_level()
	lv = maxi(1, lv)

	JuiceLevelParser.set_debug_row(lv, row)
	return {
		"ok": true, 
		"message": "已装载调试题面:第 %d 关 · %d 列 × 容量 %d · 要榨 %d 杯%s" % [
			lv, juice.columns, juice.capacity, juice.groups_total, 
			(" · %s" % juice.note) if juice.note != "" else ""], 
		"level": lv, 
		"errors": [] as Array[String], 
	}




static func enter(level: int, params: Dictionary = {}) -> void :
	LevelManager.clear_game_state(level)
	UserState.cheat_jump_to_level(level)

	SceneManager.show_page("game", params)


static func load_mystery_auto_unlock_test() -> Dictionary:
	if OS.has_feature("rel"):
		return _fail("正式包不支持问号自动解开测试")
	var row: Dictionary = MYSTERY_AUTO_UNLOCK_TEST_ROW.duplicate(true)
	row["id"] = maxi(2, UserState.get_current_level())
	return load_from_text(JSON.stringify(row))


static func load_sunlight_level(difficulty: int, sequence: int) -> Dictionary:
	return _load_sunlight_record(LevelManager.read_sunlight_level_by_difficulty(difficulty, sequence))


static func load_sunlight_case(source_id: int) -> Dictionary:
	return _load_sunlight_record(LevelManager.read_sunlight_level(source_id))


static func _load_sunlight_record(record: Dictionary) -> Dictionary:
	if record.is_empty():
		return _fail("阳光题库没有该题：难度1..5，档内序号从1开始；不会循环或回落普通题")
	var raw: Dictionary = (record["raw"] as Dictionary).duplicate(true)
	var play_level: int = maxi(2, UserState.get_current_level())
	raw["id"] = play_level
	var result: Dictionary = load_from_text(JSON.stringify(raw), 0, play_level)
	if bool(result["ok"]):
		result["source_level_id"] = int(record["source_level_id"])
		result["difficulty"] = int(record["difficulty"])
		result["tier_sequence"] = int(record["tier_sequence"])
		result["level_unique_id"] = record["level_unique_id"]
		result["message"] = "阳光题库 · 难度%d第%d题 · 原题号%d；%s" % [
			result["difficulty"], result["tier_sequence"], result["source_level_id"], result["message"]]
	return result



static func load_long_rope_case(n: int) -> Dictionary:
	if n < 1 or n > LONG_ROPE_CASES.size():
		return _fail("long_rope 没有第 %d 个样例(共 %d 个)" % [n, LONG_ROPE_CASES.size()])
	return load_from_text(JSON.stringify(LONG_ROPE_CASES[n - 1]), 0, maxi(2, UserState.get_current_level()))




static func load_eight_columns(target_rows: int) -> Dictionary:
	var rows: int = clampi(target_rows, MIN_ROWS, MAX_ROWS)
	return load_from_text(JSON.stringify(EIGHT_COLUMNS_ROWS[rows]))




static func load_challenge_case(n: int) -> Dictionary:
	var c: Dictionary = CHALLENGE_CASES.get_case(n)
	if c.is_empty():
		return _fail("challenge_time 没有第 %d 个用例(共 %d 个)" % [n, CHALLENGE_CASES.CASES.size()])
	var row: Dictionary = (c["level"] as Dictionary).duplicate(true)
	row["note"] = "challenge_time #%d %s · %s" % [n, c["kind"], c["note"]]
	var res: Dictionary = load_from_text(JSON.stringify(row), 0, maxi(2, UserState.get_current_level()))
	if bool(res["ok"]):
		res["kind"] = c["kind"]
		res["tip"] = "challenge #%d %s:%s" % [n, c["kind"], CHALLENGE_CASES.describe_move(c)]
	return res



static func clear() -> int:
	var lv: int = JuiceLevelParser.debug_row_level()
	JuiceLevelParser.clear_debug_row()
	if lv > 0:


		LevelManager.clear_game_state(lv)
	return lv



static func active_level() -> int:
	return JuiceLevelParser.debug_row_level()


static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "message": msg, "level": 0, "errors": [] as Array[String]}
