extends RefCounted

const BANK_PATH: = "res://assets/game/juice_sunlight_levels.json"
const INDEX_PATH: = "res://assets/game/juice_sunlight_levels_index.json"
const INDEX_FORMAT: = "juice-sunlight-bank-index/1"
const MAX_INDEX_BYTES: = 131072
const MAX_CASE_BYTES: = 32768

var _cases: Dictionary = {}
var _tiers: Dictionary = {}
var _bank_bytes: int = 0


func read_case(source_id: int) -> Dictionary:
	if source_id <= 0 or not _ensure_index():
		return {}
	var address: Variant = _cases.get(str(source_id))
	if not (address is Array) or (address as Array).size() != 5:
		push_warning("Sunlight bank: 原题号 %d 不存在或索引无效" % source_id)
		return {}
	var descriptor: Array = address
	var offset: int = _index_integer(descriptor[0], 0)
	var length: int = _index_integer(descriptor[1], 1)
	var difficulty: int = _index_integer(descriptor[2], 1)
	var sequence: int = _index_integer(descriptor[3], 1)
	var unique_id: Variant = descriptor[4]
	if offset < 0 or length <= 0 or length > MAX_CASE_BYTES or offset + length > _bank_bytes\
	or difficulty < 1 or difficulty > 5 or sequence < 1\
	or not (unique_id is String) or (unique_id as String).length() != 32\
	or not (unique_id as String).is_valid_hex_number():
		push_warning("Sunlight bank: 第 %d 题索引内容无效" % source_id)
		return {}
	var file: FileAccess = FileAccess.open(BANK_PATH, FileAccess.READ)
	if file == null or file.get_length() != _bank_bytes:
		push_warning("Sunlight bank: 题库缺失或与索引不匹配")
		return {}
	file.seek(offset)
	var parsed: Variant = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
	if not (parsed is Dictionary):
		push_warning("Sunlight bank: 第 %d 题不是JSON对象" % source_id)
		return {}
	var record: Dictionary = parsed
	var raw: Variant = record.get("raw")
	if _index_integer(record.get("source_level_id"), 1) != source_id\
	or _index_integer(record.get("difficulty"), 1) != difficulty\
	or _index_integer(record.get("tier_sequence"), 1) != sequence\
	or record.get("level_unique_id") != unique_id or not (raw is Dictionary)\
	or _index_integer((raw as Dictionary).get("id"), 1) != source_id:
		push_warning("Sunlight bank: 第 %d 题元数据与索引不符" % source_id)
		return {}
	return record


func read_by_difficulty(difficulty: int, sequence: int) -> Dictionary:
	if difficulty < 1 or difficulty > 5 or sequence < 1:
		push_warning("Sunlight bank: 难度须为1..5，档内序号从1开始")
		return {}
	if not _ensure_index():
		return {}
	var ids: Array = _tiers[str(difficulty)]
	if sequence > ids.size():
		push_warning("Sunlight bank: 难度%d没有第%d题（共%d题）" % [difficulty, sequence, ids.size()])
		return {}
	var record: Dictionary = read_case(_index_integer(ids[sequence - 1], 1))
	if not record.is_empty() and (int(record["difficulty"]) != difficulty\
	or int(record["tier_sequence"]) != sequence):
		push_warning("Sunlight bank: 档位顺序索引与题面不符")
		return {}
	return record


func _ensure_index() -> bool:
	if not _cases.is_empty():
		return true
	var file: FileAccess = FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null or file.get_length() <= 0 or file.get_length() > MAX_INDEX_BYTES:
		push_warning("Sunlight bank: 索引缺失或大小无效")
		return false
	var parsed: Variant = JSON.parse_string(file.get_buffer(file.get_length()).get_string_from_utf8())
	if not (parsed is Dictionary) or parsed.get("format", "") != INDEX_FORMAT:
		push_warning("Sunlight bank: 索引格式无效")
		return false
	var index: Dictionary = parsed
	var cases: Variant = index.get("cases")
	var tiers: Variant = index.get("tiers")
	var counts: Variant = index.get("counts")
	var total: int = _index_integer(index.get("count"), 1)
	var bank_bytes: int = _index_integer(index.get("bank_bytes"), 1)
	if not (cases is Dictionary) or not (tiers is Dictionary) or not (counts is Dictionary)\
	or total <= 0 or (cases as Dictionary).size() != total or bank_bytes <= 0:
		push_warning("Sunlight bank: 索引元数据无效")
		return false
	var tier_total: int = 0
	for difficulty in range(1, 6):
		var ids: Variant = (tiers as Dictionary).get(str(difficulty))
		if not (ids is Array) or (ids as Array).is_empty()\
		or _index_integer((counts as Dictionary).get(str(difficulty)), 1) != (ids as Array).size():
			push_warning("Sunlight bank: 五档索引不完整")
			return false
		tier_total += (ids as Array).size()
	if tier_total != total:
		push_warning("Sunlight bank: 五档数量与总数不符")
		return false
	_cases = cases
	_tiers = tiers
	_bank_bytes = bank_bytes
	return true


static func _index_integer(value: Variant, minimum: int) -> int:
	if not (value is int or value is float):
		return -1
	var number: float = float(value)
	return int(number) if is_finite(number) and floor(number) == number and number >= minimum else -1
