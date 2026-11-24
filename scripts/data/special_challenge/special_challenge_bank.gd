class_name SpecialChallengeBank
extends RefCounted








const PATH_V1: String = "res://assets/game/special_challenge_levels.jsonl"
const INDEX_PATH_V1: String = "res://assets/game/special_challenge_levels_index.json"
const PATH_V2: String = "res://assets/game/special_challenge_levels_v2.json"
const INDEX_PATH_V2: String = "res://assets/game/special_challenge_levels_v2_index.json"
const FORMAT_V1: String = "special-challenge-bank/1"
const FORMAT_V2: String = "special-challenge-bank/2"

var _bank: int = -1
var _offsets: Array = []
var _lengths: Array = []



func read_case(number: int, bank: int = 0) -> Dictionary:
	if not _ensure_index(bank):
		return {}
	if number < 1 or number > _offsets.size():
		SortLogger.error("Special Challenge 题号越界: bank=%d number=%d" % [bank, number])
		return {}
	var file: FileAccess = FileAccess.open(_path_for(bank), FileAccess.READ)
	if file == null:
		SortLogger.error("Special Challenge 题库无法打开: bank=%d" % bank)
		return {}
	file.seek(int(_offsets[number - 1]))
	var content: Variant
	if bank == 0:
		content = JSON.parse_string(file.get_line())
	else:
		var length: int = int(_lengths[number - 1])
		if length <= 0:
			SortLogger.error("Special Challenge v2 第 %d 题长度无效" % number)
			return {}
		content = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
	if not content is Dictionary:
		SortLogger.error("Special Challenge 第 %d 题格式无效: bank=%d" % [number, bank])
		return {}
	return content as Dictionary


func size(bank: int = 0) -> int:
	return _offsets.size() if _bank == bank else 0


func _path_for(bank: int) -> String:
	return PATH_V1 if bank == 0 else PATH_V2


func _ensure_index(bank: int) -> bool:
	if bank != 0 and bank != 1:
		SortLogger.error("Special Challenge 题库号无效: %d" % bank)
		return false
	if _bank == bank and not _offsets.is_empty():
		return true
	var index_path: String = INDEX_PATH_V1 if bank == 0 else INDEX_PATH_V2
	var expected_format: String = FORMAT_V1 if bank == 0 else FORMAT_V2
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
	if not index is Dictionary or index.get("format", "") != expected_format:
		SortLogger.error("Special Challenge 题库索引无效: bank=%d" % bank)
		return false
	var offsets: Variant = index.get("offsets", [])
	if not offsets is Array or (offsets as Array).is_empty():
		SortLogger.error("Special Challenge 题库索引没有偏移: bank=%d" % bank)
		return false
	var lengths: Variant = index.get("lengths", []) if bank == 1 else []
	if bank == 1 and ( not lengths is Array or (lengths as Array).size() != (offsets as Array).size()):
		SortLogger.error("Special Challenge v2 题库索引缺少 lengths")
		return false
	_offsets = offsets
	_lengths = lengths if lengths is Array else []
	_bank = bank
	return true
