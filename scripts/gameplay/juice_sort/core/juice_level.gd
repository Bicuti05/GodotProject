class_name JuiceLevel
extends RefCounted


























const SLOT_JAR: = "jar"
const SLOT_PARK: = "park"

const MAX_LATE_PARK: = 4

const MAX_BASE_COLUMNS: = 7
const MAX_TOTAL_COLUMNS: = MAX_BASE_COLUMNS + 1
const MAX_TWO_ROW_COLUMNS: = 13

const MAX_TYPES: = 10
const SLOT_RETIRE: = "retire"


const NO_JAR: = -1


const COL_SEP: = "|"
const PARK_CHAR: = "-"
const RETIRE_CHAR: = "x"
const HIDDEN_BASE: = 1000
const HIDDEN_CHAR: = "?"
const FROZEN_BASE: = 2000
const FROZEN_LIMIT: = 3000
const FROZEN_CHAR: = "i"
const NO_SUNLIGHT: = -1
const SUNLIGHT_KEY: = "sunlight"
const SUNLIGHT_TYPE_ID: = "typeId"
const ICE_MODE_KEY: = "iceMode"
const ICE_BLOCK_CONNECTION: = "blockConnection"
const ICE_BLOCK_COLLECTION: = "blockCollection"
const LOCK_TYPE: = "unlock"
const LOCK_COLLECT_TYPE: = "collect_type"
const LOCK_COLLECT_COUNT: = "collect_count"
var id: int = 0
var note: String = ""
var seed: int = 0
var _has_seed: bool = false

var layout_rows: int = 1
var layout_columns: int = 5

var columns: int = 0


var capacity: int = 0

var column_caps: Array[int] = []

var incoming_caps: Array[int] = []

var cup_caps: Array[int] = []

var total_flowers: int = 0
var _variable_caps: bool = false
var groups_total: int = 0
var types: int = 0
var init_jars: int = 0
var initial_parks: int = 0
var late_park: int = 0
var batch_size: int = 0

var jar_seq: Array[int] = []
var board_cols: Array = []
var board_jars: Array[int] = []
var board_locks: Array = []
var board_frozen_pots: Array[bool] = []
var incoming: Array = []




var _fut: Array = []

var _errors: Array[String] = []



var _white_jar: bool = false
var sunlight_type: int = NO_SUNLIGHT
var ice_mode: String = ICE_BLOCK_COLLECTION
var _has_ice_mode: bool = false
var sun_cups: int = 0











static func from_dict(d: Dictionary) -> JuiceLevel:
	var lv: = JuiceLevel.new()


	lv.id = _read_integer(d.get("id"), "id(题目 ID)", 1, lv._errors) if d.has("id") else 0
	if d.has("note") and not (d["note"] is String):
		lv._errors.append("note 必须是字符串")
	else:
		lv.note = String(d.get("note", ""))
	lv._has_seed = d.has("seed")
	if lv._has_seed:
		lv.seed = _read_integer(d.get("seed"), "seed", 0, lv._errors)
	lv.capacity = _read_integer(d.get("capacity"), "capacity(每杯容量)", 2, lv._errors)
	lv.groups_total = _read_integer(d.get("targetCups"), "targetCups(目标杯数)", 2, lv._errors)
	lv.layout_rows = _read_integer(d.get("layoutRows", 1), "layoutRows", 1, lv._errors)
	lv.layout_columns = _read_integer(d.get("layoutColumns", 5), "layoutColumns", 1, lv._errors)
	lv.batch_size = lv.capacity
	if d.has("whiteJar") and not (d["whiteJar"] is bool):
		lv._errors.append("whiteJar 必须是布尔值")
	else:
		lv._white_jar = bool(d.get("whiteJar", false))
	if d.has(SUNLIGHT_KEY):
		lv._read_sunlight(d[SUNLIGHT_KEY])
	lv._has_ice_mode = d.has(ICE_MODE_KEY)
	if lv._has_ice_mode:
		var mode: Variant = d[ICE_MODE_KEY]
		if not (mode is String) or mode not in [ICE_BLOCK_CONNECTION, ICE_BLOCK_COLLECTION]:
			lv._errors.append("iceMode 只支持 blockConnection / blockCollection")
		else:
			lv.ice_mode = mode

	if not (d.get("initial") is Array):
		lv._errors.append("initial 必须是数组")
	if not (d.get("incoming") is Array):
		lv._errors.append("incoming 必须是数组")
	var initial: Array = d.get("initial", []) if d.get("initial") is Array else []
	if initial.size() < 3:
		lv._errors.append("initial(开局每列一条)缺失或少于 3 列")
	lv.columns = initial.size()
	lv.board_cols.resize(lv.columns)
	lv.board_jars.resize(lv.columns)
	lv.board_locks.resize(lv.columns)
	lv.board_frozen_pots.resize(lv.columns)
	lv.column_caps.resize(lv.columns)
	for i in lv.columns:
		lv.board_cols[i] = [] as Array[int]
		lv.board_jars[i] = NO_JAR
		lv.board_locks[i] = {}
		lv.board_frozen_pots[i] = false
		lv.column_caps[i] = lv.capacity
	for i in lv.columns:
		var got: Dictionary = _decode_col(initial[i], "initial 第 %d 条" % (i + 1))
		if String(got["err"]) != "":
			lv._errors.append(String(got["err"]))
			continue
		if bool(got["retire"]):
			lv._errors.append("initial 第 %d 条写了 \"%s\" —— 退出盘面只能出现在 incoming 里"
				%[i + 1, RETIRE_CHAR])
			continue
		lv.board_jars[i] = int(got["jar"])
		lv.board_cols[i] = got["beads"]
		lv.board_locks[i] = got["lock"]
	lv._read_frozen_pots(d.get("frozenPots"))

	var inc_raw: Array = d.get("incoming", []) if d.get("incoming") is Array else []
	lv._read_column_caps(d.get("columnCaps"), initial.size(), inc_raw.size())
	if lv.groups_total >= 2 and inc_raw.size() > lv.groups_total - 1:
		lv._errors.append("incoming 有 %d 条,不能超过 targetCups-1=%d 条"
			%[inc_raw.size(), lv.groups_total - 1])
	for k in inc_raw.size():
		var got2: Dictionary = _decode_col(inc_raw[k], "incoming 第 %d 条" % (k + 1))
		if String(got2["err"]) != "":
			lv._errors.append(String(got2["err"]))
			continue
		var jar: int = int(got2["jar"])
		var slot: String = SLOT_RETIRE if bool(got2["retire"]) else (SLOT_PARK if jar == NO_JAR else SLOT_JAR)
		var cap: int = 0 if slot == SLOT_RETIRE else (
			int(lv.incoming_caps[k]) if lv._variable_caps and k < lv.incoming_caps.size() else lv.capacity)
		lv.incoming.append({"slot": slot, "jar": jar, "beads": got2["beads"], "lock": got2["lock"], 
			"cap": cap})
		if k < lv.incoming_caps.size():
			lv.incoming_caps[k] = cap
	while lv.incoming.size() < lv.groups_total - 1:
		lv.incoming.append({"slot": SLOT_RETIRE, "jar": NO_JAR, "beads": [] as Array[int], 
			"lock": {}, "cap": 0})
		lv.incoming_caps.append(0)


	lv._derive()
	lv._build_cup_caps()
	lv._build_future_tally()
	return lv






static func _unwrap_column(raw: Variant, where: String) -> Dictionary:
	if not (raw is Dictionary):
		return {"raw": raw, "lock": {}, "err": ""}
	var d: Dictionary = raw
	var extra: Array[String] = []
	for key: Variant in d:
		var name: String = String(key)
		if name != "column" and name != "columnType" and name != "columnInfo":
			extra.append(name)
	if not extra.is_empty():
		return {"raw": null, "lock": {}, "err": "%s 的扩写形态有不认识的字段「%s」" % [where, "/".join(extra)]}
	var kind: Variant = d.get("columnType")
	var info: Variant = d.get("columnInfo")
	if String(kind) == LOCK_TYPE:
		var parsed: Dictionary = _parse_lock_info(info, where)
		if String(parsed["err"]) != "":
			return {"raw": null, "lock": {}, "err": parsed["err"]}
		return {"raw": d.get("column"), "lock": parsed["lock"], "err": ""}
	if kind != null and String(kind) != "" and String(kind) != "default":
		return {"raw": null, "lock": {}, "err": "%s 的 columnType 是「%s」,只支持 \"default\" / \"%s\""
			%[where, str(kind), LOCK_TYPE]}
	if info != null:
		if not (info is Dictionary):
			return {"raw": null, "lock": {}, "err": "%s 的 columnInfo 必须是对象" % where}
		var info_keys: Array[String] = []
		for key2: Variant in (info as Dictionary):
			info_keys.append(String(key2))
		if not info_keys.is_empty():
			return {"raw": null, "lock": {}, "err": "%s 的 columnInfo 带了内容「%s」,普通列只支持空对象 {}"
				%[where, "/".join(info_keys)]}
	return {"raw": d.get("column"), "lock": {}, "err": ""}


func _read_sunlight(raw: Variant) -> void :
	if not (raw is Dictionary):
		_errors.append("sunlight 必须是对象")
		return
	var info: Dictionary = raw
	for key: Variant in info:
		if String(key) != SUNLIGHT_TYPE_ID:
			_errors.append("sunlight 只含 typeId 字段")
			return
	var errors: Array[String] = []
	var type_id: int = _read_integer(info.get(SUNLIGHT_TYPE_ID), "sunlight.typeId", 0, errors)
	if not errors.is_empty():
		_errors.append(errors[0])
		return
	if type_id >= MAX_TYPES:
		_errors.append("sunlight.typeId=%d 超出客户端上限 %d" % [type_id, MAX_TYPES - 1])
		return
	sunlight_type = type_id


static func _parse_lock_info(raw: Variant, where: String) -> Dictionary:
	var bad: = func(msg: String) -> Dictionary:
		return {"lock": {}, "err": msg}
	if not (raw is Dictionary):
		return bad.call("%s 的 columnType 是 \"%s\",columnInfo 必须给出解锁条件对象" % [where, LOCK_TYPE])
	var info: Dictionary = raw
	var condition: String = String(info.get("condition", ""))
	if condition != LOCK_COLLECT_COUNT and condition != LOCK_COLLECT_TYPE:
		return bad.call("%s 的解锁条件 condition 是「%s」,只支持 \"%s\" / \"%s\""
			%[where, condition, LOCK_COLLECT_TYPE, LOCK_COLLECT_COUNT])
	var allowed: Array[String] = ["condition", "count"]
	if condition == LOCK_COLLECT_TYPE:
		allowed.insert(1, "typeId")
	var extra: Array[String] = []
	for key: Variant in info:
		if not allowed.has(String(key)):
			extra.append(String(key))
	if not extra.is_empty():
		return bad.call("%s 的 columnInfo 有解锁条件用不到的字段「%s」" % [where, "/".join(extra)])
	var errors: Array[String] = []
	var count: int = _read_integer(info.get("count"), "%s 的解锁条件 count" % where, 1, errors)
	if not errors.is_empty():
		return bad.call(errors[0])
	if condition == LOCK_COLLECT_COUNT:
		return {"lock": {"condition": condition, "count": count}, "err": ""}
	var type_id: int = _read_integer(info.get("typeId"), "%s 的解锁条件 typeId" % where, 0, errors)
	if not errors.is_empty():
		return bad.call(errors[0])
	if type_id >= HIDDEN_BASE:
		return bad.call("%s 的解锁条件 typeId=%d 太大,必须小于 %d" % [where, type_id, HIDDEN_BASE])
	return {"lock": {"condition": condition, "typeId": type_id, "count": count}, "err": ""}





static func _decode_col(raw: Variant, where: String) -> Dictionary:
	var bad: = func(msg: String) -> Dictionary:
		return {"jar": NO_JAR, "beads": [] as Array[int], "retire": false, "lock": {}, "err": msg}
	var unwrapped: Dictionary = _unwrap_column(raw, where)
	if String(unwrapped["err"]) != "":
		return bad.call(String(unwrapped["err"]))
	if not (unwrapped["raw"] is String):
		return bad.call("%s 必须是字符串,或排关表的 {column:\"…\"} 扩写形态" % where)
	var col_str: String = unwrapped["raw"]

	if col_str == RETIRE_CHAR or col_str == RETIRE_CHAR + COL_SEP:
		if not (unwrapped["lock"] as Dictionary).is_empty():
			return bad.call("%s 是退出盘面的那一条(\"%s\"),不能带锁" % [where, RETIRE_CHAR])
		return {"jar": NO_JAR, "beads": [] as Array[int], "retire": true, "lock": {}, "err": ""}
	var parts: PackedStringArray = col_str.split(COL_SEP, true)
	if parts.size() != 2:
		return bad.call("%s 写的是「%s」,必须包含且只包含一个竖线 —— 如 \"0%s2,3,1\";白色空机写 \"%s%s\",退出盘面写 \"%s\""
			%[where, col_str, COL_SEP, PARK_CHAR, COL_SEP, RETIRE_CHAR])
	var jar_part: String = parts[0]
	var bead_part: String = parts[1]
	var jar: int = NO_JAR
	if jar_part != PARK_CHAR:
		if jar_part.begins_with(HIDDEN_CHAR):
			return bad.call("%s 的机器写成「%s」—— \"%s\" 只能标花朵,机器不能隐藏"
				%[where, jar_part, HIDDEN_CHAR])
		jar = _parse_uint(jar_part)
		if jar < 0:
			return bad.call("%s 的机器写的是「%s」,只能是非负整数或 \"%s\"(白色空机)"
				%[where, jar_part, PARK_CHAR])
		if jar >= HIDDEN_BASE:
			return bad.call("%s 的机器类型 %d 太大,必须小于 %d" % [where, jar, HIDDEN_BASE])
	var beads: Array[int] = []
	if not bead_part.is_empty():
		for token: String in bead_part.split(",", true):
			var hidden: bool = token.begins_with(HIDDEN_CHAR)
			var frozen: bool = token.begins_with(FROZEN_CHAR)
			var encoded: String = token.substr(1) if hidden or frozen else token
			if encoded.begins_with(HIDDEN_CHAR) or encoded.begins_with(FROZEN_CHAR):
				return bad.call("%s 的水果序列「%s」格式错误,同一颗不能同时是问号和冰封"
					%[where, bead_part])
			var fruit_type: int = _parse_uint(encoded)
			if fruit_type < 0:
				return bad.call("%s 的水果序列「%s」格式错误,必须用英文逗号分隔非负整数;隐藏花朵写 \"?2\",不能有空项"
					%[where, bead_part])
			if fruit_type >= HIDDEN_BASE:
				return bad.call("%s 的花朵类型 %d 太大,必须小于 %d" % [where, fruit_type, HIDDEN_BASE])
			beads.append(freeze_type(fruit_type) if frozen else hide_type(fruit_type) if hidden else fruit_type)
	return {"jar": jar, "beads": beads, "retire": false, "lock": unwrapped["lock"], "err": ""}


static func is_hidden(fruit_type: int) -> bool:
	return fruit_type >= HIDDEN_BASE and fruit_type < FROZEN_BASE


static func is_frozen(fruit_type: int) -> bool:
	return fruit_type >= FROZEN_BASE and fruit_type < FROZEN_LIMIT


static func true_type(fruit_type: int) -> int:
	if is_frozen(fruit_type):
		return fruit_type - FROZEN_BASE
	return fruit_type - HIDDEN_BASE if is_hidden(fruit_type) else fruit_type


static func connection_type(fruit_type: int) -> int:
	return fruit_type - FROZEN_BASE if is_frozen(fruit_type) else fruit_type


static func hide_type(fruit_type: int) -> int:
	return fruit_type + HIDDEN_BASE


static func freeze_type(fruit_type: int) -> int:
	return fruit_type + FROZEN_BASE


func has_sunlight() -> bool:
	return sunlight_type != NO_SUNLIGHT


func is_sunlight_type(fruit_type: int) -> bool:
	return has_sunlight() and true_type(fruit_type) == sunlight_type


func flower_cups() -> int:
	return groups_total - sun_cups


static func _parse_uint(text: String) -> int:
	if text.is_empty():
		return -1
	for i in text.length():
		var code: int = text.unicode_at(i)
		if code < 48 or code > 57:
			return -1
	return int(text)


static func _read_integer(raw: Variant, field_name: String, minimum: int, errors: Array[String]) -> int:
	if not (raw is int or raw is float) or raw is bool:
		errors.append("%s=%s,必须是 >= %d 的整数" % [field_name, str(raw), minimum])
		return 0
	var value: int = int(raw)
	if float(raw) != float(value) or value < minimum:
		errors.append("%s=%s,必须是 >= %d 的整数" % [field_name, str(raw), minimum])
		return 0
	return value






func _read_column_caps(raw: Variant, column_count: int, incoming_count: int) -> void :
	incoming_caps.resize(incoming_count)
	incoming_caps.fill(0)
	if raw == null:
		return
	if not (raw is Dictionary):
		_errors.append("columnCaps 必须是对象")
		return
	var caps: Dictionary = raw
	var extra: Array[String] = []
	for key: Variant in caps:
		if String(key) != "initial" and String(key) != "incoming":
			extra.append(String(key))
	if not extra.is_empty():
		_errors.append("columnCaps 有不认识的字段「%s」" % "/".join(extra))
		return
	var initial_caps: Variant = caps.get("initial")
	var incoming_caps_raw: Variant = caps.get("incoming")
	if not (initial_caps is Array) or (initial_caps as Array).size() != column_count:
		_errors.append("columnCaps.initial 长度必须等于列数 %d" % column_count)
		return
	if not (incoming_caps_raw is Array) or (incoming_caps_raw as Array).size() != incoming_count:
		_errors.append("columnCaps.incoming 长度必须等于 incoming 条数 %d" % incoming_count)
		return
	_variable_caps = true
	for i in column_count:
		var cap: int = _read_integer((initial_caps as Array)[i], 
			"columnCaps.initial[%d]" % i, 1, _errors)
		column_caps[i] = cap
		if cap > capacity:
			_errors.append("columnCaps.initial[%d]=%d 大于 capacity=%d —— 生成数据应把 capacity 写成最大列容量"
				%[i, cap, capacity])
	for k in incoming_count:
		var cap2: int = _read_integer((incoming_caps_raw as Array)[k], 
			"columnCaps.incoming[%d]" % k, 0, _errors)
		incoming_caps[k] = cap2
		if cap2 > capacity:
			_errors.append("columnCaps.incoming[%d]=%d 大于 capacity=%d —— 生成数据应把 capacity 写成最大列容量"
				%[k, cap2, capacity])




func _build_cup_caps() -> void :
	cup_caps.clear()
	for i in columns:
		if board_jars[i] != NO_JAR:
			cup_caps.append(column_caps[i])
	for entry: Dictionary in incoming:
		if String(entry.get("slot", "")) == SLOT_JAR:
			cup_caps.append(int(entry.get("cap", capacity)))
	total_flowers = 0
	for cap: int in cup_caps:
		total_flowers += cap



func initial_total_capacity() -> int:
	var total: int = 0
	for cap: int in column_caps:
		total += cap
	return total


func has_variable_caps() -> bool:
	return _variable_caps



func valid_cap(cap: int) -> bool:
	if cap == capacity or column_caps.has(cap) or incoming_caps.has(cap):
		return true
	return false


func has_frozen_pots() -> bool:
	return board_frozen_pots.has(true)


func _read_frozen_pots(raw: Variant) -> void :
	if raw == null:
		return
	if not (raw is Array):
		_errors.append("frozenPots 必须是初始列下标数组")
		return
	for value: Variant in raw:
		var index: int = _read_integer(value, "frozenPots 下标", 0, _errors)
		if index >= columns:
			_errors.append("frozenPots 下标越界")
			continue
		board_frozen_pots[index] = true





func _derive() -> void :
	initial_parks = 0
	for jar: int in board_jars:
		if jar == NO_JAR:
			initial_parks += 1
	init_jars = columns - initial_parks

	jar_seq.clear()
	sun_cups = 0
	for jar in board_jars:
		if jar != NO_JAR:
			jar_seq.append(jar)
			if has_sunlight() and jar == sunlight_type:
				sun_cups += 1
	late_park = 0
	for e in incoming:
		if String(e["slot"]) == SLOT_JAR:
			jar_seq.append(int(e["jar"]))
			if has_sunlight() and int(e["jar"]) == sunlight_type:
				sun_cups += 1
		elif String(e["slot"]) == SLOT_PARK:
			late_park += 1

	var max_type: int = -1
	for t in jar_seq:
		max_type = maxi(max_type, t)
	for col in board_cols:
		for t in (col as Array):
			max_type = maxi(max_type, true_type(int(t)))
	for e in incoming:
		for t in (e["beads"] as Array):
			max_type = maxi(max_type, true_type(int(t)))
	types = max_type + 1


func _build_future_tally() -> void :
	var n: int = incoming.size()
	_fut.resize(n + 1)
	var tail: Array[int] = []
	tail.resize(types)
	tail.fill(0)
	_fut[n] = tail
	for k in range(n - 1, -1, -1):
		var row: Array[int] = (_fut[k + 1] as Array[int]).duplicate()
		for t in (incoming[k]["beads"] as Array[int]):
			var actual: int = true_type(t)
			if actual >= 0 and actual < types:
				row[actual] += 1
		_fut[k] = row



func future_tally(done: int) -> Array[int]:
	if _fut.is_empty():
		var empty: Array[int] = []
		empty.resize(types)
		empty.fill(0)
		return empty
	return _fut[clampi(done, 0, _fut.size() - 1)] as Array[int]



func incoming_at(k: int) -> Dictionary:
	if k < 0 or k >= incoming.size():
		return {}
	return incoming[k]








func validate() -> Array[String]:
	var errs: Array[String] = _errors.duplicate()
	if columns <= 0 or capacity <= 0 or groups_total <= 0 or types <= 0:
		errs.append("基本参数有 0:列数=%d 容量(capacity)=%d 杯数(targetCups)=%d 种类=%d"
			%[columns, capacity, groups_total, types])
		return errs
	if types > MAX_TYPES:
		errs.append("花色类型范围 %d > 客户端上限 %d(类型号必须为 0..%d)"
			%[types, MAX_TYPES, MAX_TYPES - 1])
	if has_sunlight() and sunlight_type >= types:
		errs.append("sunlight.typeId=%d 不在本关类型范围 0..%d 内" % [sunlight_type, types - 1])
	if has_sunlight() and sun_cups <= 0:
		errs.append("阳光融冰玩法的机器序里必须有阳光收集器")
	if has_frozen_pots() and not has_sunlight():
		errs.append("冻盆必须指定阳光收集器")
	for index in board_frozen_pots.size():
		if board_frozen_pots[index] and (board_jars[index] < 0 or is_sunlight_type(board_jars[index])):
			errs.append("白盆或阳光盆不能被冻结")
	var has_ice: bool = false
	var frozen_sun: bool = false
	for col: Array in board_cols:
		for fruit_type: int in col:
			if not is_frozen(fruit_type):
				continue
			has_ice = true
			if has_sunlight() and true_type(fruit_type) == sunlight_type:
				frozen_sun = true
	for k in incoming.size():
		for fruit_type: int in ((incoming[k] as Dictionary)["beads"] as Array[int]):
			if not is_frozen(fruit_type):
				continue
			errs.append("冰只允许出现在 initial，incoming 第 %d 条发现冰封花朵" % (k + 1))
			if has_sunlight() and true_type(fruit_type) == sunlight_type:
				frozen_sun = true
	if has_ice and not has_sunlight():
		errs.append("含冰封花朵的题必须指定 sunlight.typeId")
	if frozen_sun:
		errs.append("阳光不能标成冰封花朵")
	if layout_rows not in [1, 2]:
		errs.append("layoutRows 只支持 1 或 2")
	if layout_rows == 2 and (layout_columns not in [4, 5] or capacity != 4
			or (columns - initial_parks != layout_columns * 2
				and not (layout_columns == 5 and columns - initial_parks == 9)) or initial_parks > 2):
		errs.append("双排关卡支持4+4、5+4或5+5盆、容量4，可另带最多2根独立空绳")
	if layout_rows == 1 and columns > MAX_BASE_COLUMNS:
		errs.append("开局列数 %d > 上限 %d(需为增加绳子道具预留 1 列)"
			%[columns, MAX_BASE_COLUMNS])
	if _white_jar:
		errs.append("whiteJar=true(白机模式)未移植,本玩法必须凑成机器要的那一种才算榨出一杯")
	var has_hidden: bool = false
	for col: Array in board_cols:
		for fruit_type: int in col:
			if is_hidden(fruit_type):
				has_hidden = true
	for entry: Dictionary in incoming:
		for fruit_type: int in (entry["beads"] as Array[int]):
			if is_hidden(fruit_type):
				has_hidden = true
	var initial_lock_count: int = 0
	for lock: Dictionary in board_locks:
		if not lock.is_empty():
			initial_lock_count += 1
	var has_locks: bool = initial_lock_count > 0
	for entry: Dictionary in incoming:
		if not (entry.get("lock", {}) as Dictionary).is_empty():
			has_locks = true
	if _white_jar and has_hidden:
		errs.append("白机模式(whiteJar)不能和问号(隐藏花朵)同时使用")
	if _white_jar and has_locks:
		errs.append("白机模式(whiteJar)不能和冰封列同时使用")
	if incoming.size() != groups_total - 1:
		errs.append("incoming 内部长度 %d,必须等于 targetCups-1=%d"
			%[incoming.size(), groups_total - 1])
	if jar_seq.size() != groups_total:
		errs.append("机器总数 %d(initial 里 %d 台 + incoming 里 %d 台)必须等于 targetCups=%d —— 每台机器榨一杯"
			%[jar_seq.size(), init_jars, jar_seq.size() - init_jars, groups_total])



	var max_initial_parks: int = maxi(0, columns - 2)
	if initial_parks > max_initial_parks:
		errs.append("开局白列 %d 个 > %d(列数-2,至少留 2 台机器)" % [initial_parks, max_initial_parks])
	if initial_lock_count > max_initial_parks:
		errs.append("开局冰封了 %d 列 > %d(列数-2,至少留 2 列周转)" % [initial_lock_count, max_initial_parks])
	if late_park < 0 or late_park > MAX_LATE_PARK:
		errs.append("后备白列 %d 个不在 0..%d 内" % [late_park, MAX_LATE_PARK])

	if cup_caps.size() != jar_seq.size():
		errs.append("每杯容量表 %d 项 != 机器序 %d 台" % [cup_caps.size(), jar_seq.size()])
	if total_flowers <= 0:
		errs.append("花朵总数必须 > 0")
	var init_capacity: int = initial_total_capacity()
	var init_beads: int = 0
	for i in board_cols.size():
		var initial_col: Array = board_cols[i] as Array
		var n: int = initial_col.size()
		var cap: int = column_caps[i] if i < column_caps.size() else capacity
		init_beads += n
		if cap <= 0:
			errs.append("initial 第 %d 条列容量必须 > 0" % (i + 1))
		if n > cap:
			errs.append("initial 第 %d 条有 %d 颗水果 > 该列容量 %d" % [i + 1, n, cap])
		if n > 0 and is_hidden(int(initial_col[n - 1])):
			errs.append("initial 第 %d 条的串尾是问号 —— 串尾必须是明牌" % (i + 1))
	var supply: int = 0
	for k in incoming.size():
		var e: Dictionary = incoming[k]
		var n2: int = (e["beads"] as Array).size()
		var cap2: int = int(e.get("cap", capacity))
		supply += n2
		if String(e["slot"]) == SLOT_RETIRE:
			if cap2 != 0:
				errs.append("incoming 第 %d 条是 \"%s\",列容量必须为 0" % [k + 1, RETIRE_CHAR])
		elif cap2 <= 0:
			errs.append("incoming 第 %d 条列容量必须 > 0" % (k + 1))
		if n2 > cap2:
			errs.append("incoming 第 %d 条有 %d 颗水果 > 该列容量 %d" % [k + 1, n2, cap2])
		if String(e["slot"]) == SLOT_RETIRE and n2 > 0:
			errs.append("incoming 第 %d 条是 \"%s\"(退出盘面)却还带 %d 颗补货" % [k + 1, RETIRE_CHAR, n2])
		if n2 > 0 and is_hidden(int((e["beads"] as Array)[n2 - 1])):
			errs.append("incoming 第 %d 条的最后一颗是问号 —— 它会落在串尾,必须是明牌" % (k + 1))

	if init_beads + supply != total_flowers:
		errs.append("水果账不配平:开局 %d 颗 + 后续补 %d 颗 = %d,必须等于各杯容量之和 %d"
			%[init_beads, supply, init_beads + supply, total_flowers])
	if init_beads > init_capacity:
		errs.append("开局 %d 颗放不进初始各列容量之和 %d 格" % [init_beads, init_capacity])


	var cnt: Array[int] = []
	cnt.resize(types)
	cnt.fill(0)
	for col in board_cols:
		for t in (col as Array):
			cnt[true_type(int(t))] += 1
	for e2 in incoming:
		for t in (e2["beads"] as Array):
			cnt[true_type(int(t))] += 1
	var want: Array[int] = []
	want.resize(types)
	want.fill(0)
	for k in jar_seq.size():
		var t: int = jar_seq[k]
		want[t] += cup_caps[k] if k < cup_caps.size() else capacity
	for t in types:
		if cnt[t] != want[t]:
			if want[t] == 0:
				errs.append("盘面里有水果 %s(%d 颗),但机器序里没有任何机器要它 ⇒ 永远收不掉"
					%[type_label(t), cnt[t]])
			else:
				errs.append("水果 %s 一共 %d 颗,但它占的杯总容量是 %d 颗"
					%[type_label(t), cnt[t], want[t]])

	if has_locks:
		for i in board_locks.size():
			_validate_lock(board_locks[i] as Dictionary, "initial 第 %d 条" % (i + 1), errs)
		for k in incoming.size():
			_validate_lock((incoming[k] as Dictionary).get("lock", {}) as Dictionary, 
				"incoming 第 %d 条" % (k + 1), errs)

	return errs


func _validate_lock(lock: Dictionary, where: String, errs: Array[String]) -> void :
	if lock.is_empty():
		return
	var condition: String = String(lock.get("condition", ""))
	var count: int = int(lock.get("count", 0))
	if condition == LOCK_COLLECT_COUNT:
		if count >= groups_total:
			errs.append("%s 的解锁条件是累计收满 %d 盆,而本关一共 %d 盆 —— 这把锁永远解不开"
				%[where, count, groups_total])
		return


	if count != 1:
		errs.append("%s 的解锁条件是收满 %d 盆同色花,但客户端只支持 1 盆(没有「颜色 × N」的 UI)"
			%[where, count])
		return
	var type_id: int = int(lock.get("typeId", -1))
	if type_id < 0 or type_id >= types:
		errs.append("%s 的解锁条件盯着 %d 号花,但本关只有 %d 种花(0..%d)"
			%[where, type_id, types, types - 1])
		return
	var available_cups: int = 0
	for jar: int in jar_seq:
		if jar == type_id:
			available_cups += 1
	if available_cups < count:
		errs.append("%s 的解锁条件要收满 %d 盆 %d 号花,但机器序里该类型只占 %d 盆 —— 这把锁永远解不开"
			%[where, count, type_id, available_cups])


static func type_label(t: int) -> String:
	return str(t)




func to_dict() -> Dictionary:
	var initial: Array = []
	for i in board_cols.size():
		initial.append(_encode_column_entry(encode_col(board_jars[i], board_cols[i] as Array[int]), 
			board_locks[i] as Dictionary))
	var inc: Array = []
	for e in incoming:
		if String(e["slot"]) == SLOT_RETIRE:
			inc.append(RETIRE_CHAR)
		else:
			inc.append(_encode_column_entry(encode_col(int(e["jar"]), e["beads"] as Array[int]), 
				e.get("lock", {}) as Dictionary))
	while not inc.is_empty() and String(inc.back()) == RETIRE_CHAR:
		inc.pop_back()
	var out: Dictionary = {
		"id": id, 
		"capacity": capacity, 
		"targetCups": groups_total, 
		"initial": initial, 
		"incoming": inc, 
	}
	if layout_rows == 2:
		out["layoutRows"] = layout_rows
		out["layoutColumns"] = layout_columns
	if not note.is_empty():
		out["note"] = note
	if has_sunlight():
		out["sunlight"] = {SUNLIGHT_TYPE_ID: sunlight_type}
	if _has_ice_mode or ice_mode != ICE_BLOCK_COLLECTION:
		out[ICE_MODE_KEY] = ice_mode
	if _has_seed:
		out["seed"] = seed
	if _white_jar:
		out["whiteJar"] = true
	if _variable_caps:

		out["schema"] = "juice-level/4"
		var init_caps: Array = []
		for cap: int in column_caps:
			init_caps.append(cap)
		var inc_caps: Array = []
		for k in inc.size():
			inc_caps.append(int(incoming_caps[k]) if k < incoming_caps.size() else 0)
		out["columnCaps"] = {"initial": init_caps, "incoming": inc_caps}
	if has_frozen_pots():
		var frozen: Array = []
		for index in board_frozen_pots.size():
			if board_frozen_pots[index]:
				frozen.append(index)
		out["frozenPots"] = frozen
	return out



static func encode_col(jar: int, beads: Array[int]) -> String:
	var encoded: PackedStringArray = []
	for fruit_type in beads:
		if is_frozen(fruit_type):
			encoded.append(FROZEN_CHAR + type_label(true_type(fruit_type)))
		elif is_hidden(fruit_type):
			encoded.append(HIDDEN_CHAR + type_label(true_type(fruit_type)))
		else:
			encoded.append(type_label(fruit_type))
	return (PARK_CHAR if jar < 0 else type_label(jar)) + COL_SEP + ",".join(encoded)


static func _encode_column_entry(column: String, lock: Dictionary) -> Variant:
	if lock.is_empty():
		return column
	return {
		"column": column, 
		"columnType": LOCK_TYPE, 
		"columnInfo": lock.duplicate(true), 
	}
