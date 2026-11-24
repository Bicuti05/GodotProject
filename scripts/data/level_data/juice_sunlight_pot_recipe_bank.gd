extends RefCounted

const INDEX: = "res://assets/game/juice_sunlight_pot_recipes_index.json"
const BANK: = "res://assets/game/juice_sunlight_pot_recipes.json"
var _addresses: Dictionary = {}
var _bank_bytes: int = 0


func read_recipe(level: int, source_uid: String, tags: String) -> Dictionary:
	if _addresses.is_empty():
		var index_file: FileAccess = FileAccess.open(INDEX, FileAccess.READ)
		if index_file == null or index_file.get_length() > 131072:
			return {}
		var parsed: Variant = JSON.parse_string(index_file.get_as_text())
		if not (parsed is Dictionary) or parsed.get("format") != "sunlight-pot-recipes/1":
			return {}
		if not (parsed.get("addresses") is Dictionary) or _integer(parsed.get("bank_bytes")) <= 0:
			return {}
		_addresses = parsed["addresses"]
		_bank_bytes = _integer(parsed["bank_bytes"])
	var key: String = "%d|%s|%s" % [level, source_uid, tags]
	var address: Variant = _addresses.get(key)
	if not (address is Array) or address.size() != 2:
		return {}
	var offset: int = _integer(address[0])
	var length: int = _integer(address[1])
	if offset < 0 or length <= 0 or length > 65536 or offset + length > _bank_bytes:
		return {}
	var file: FileAccess = FileAccess.open(BANK, FileAccess.READ)
	if file == null or file.get_length() != _bank_bytes:
		return {}
	file.seek(offset)
	var value: Variant = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
	if not (value is Dictionary) or _integer(value.get("level")) != level\
	or value.get("source_uid") != source_uid or value.get("tags") != tags:
		return {}
	return value


static func _integer(value: Variant) -> int:
	if not (value is int or value is float):
		return -1
	var number: float = float(value)
	return int(number) if is_finite(number) and floor(number) == number and number >= 0.0 and number < 1000000000.0 else -1
