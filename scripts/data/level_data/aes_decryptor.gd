class_name AESDecryptor extends RefCounted













const KEY_B64: = "bHmJQ0X7EixyOe+LuW8ShBaXz1S4cNxL+Ebe3rQKHlA="






static var _cache: Dictionary = {}


static func decrypt(b64_input: String) -> String:
	if b64_input.is_empty():
		return ""
	if _cache.has(b64_input):
		return str(_cache[b64_input])

	var key: = Marshalls.base64_to_raw(KEY_B64)
	if key.size() != 32:
		push_error("AESDecryptor: key 长度异常 %d(期望 32)" % key.size())
		return ""
	var all: = Marshalls.base64_to_raw(b64_input)

	if all.size() < 32 or (all.size() - 16) % 16 != 0:
		push_warning("AESDecryptor: 输入长度异常 %d" % all.size())
		return ""

	var iv: = all.slice(0, 16)
	var cipher: = all.slice(16)

	var aes: = AESContext.new()
	var err: = aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	if err != OK:
		push_error("AESDecryptor: AESContext.start 失败 %d" % err)
		return ""
	var plain: PackedByteArray = aes.update(cipher)
	aes.finish()
	if plain.is_empty():
		return ""



	var pad: int = plain[plain.size() - 1]
	if pad < 1 or pad > 16 or pad > plain.size():
		push_warning("AESDecryptor: PKCS7 padding 字节异常 %d" % pad)
		return ""
	plain = plain.slice(0, plain.size() - pad)

	var result: = plain.get_string_from_utf8()
	_cache[b64_input] = result
	return result



static func clear_cache() -> void :
	_cache.clear()
