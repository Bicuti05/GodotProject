@tool
class_name HapticUploadDefaults
extends RefCounted


const FORMAT: String = "pocketsort_haptic_connection_defaults_v1"
const PACKAGE_PATH: String = "res://haptic_upload_defaults.json"
const MAX_BYTES: int = 4096


static func private_path() -> String:
	return OS.get_environment("HOME").path_join(".config/pocket-sort/haptic-upload-defaults.json")


static func load_defaults() -> Dictionary:
	return load_for_features(OS.has_feature("editor"), OS.has_feature("macos"), OS.has_feature("debug"), OS.has_feature("rel"))


static func load_for_features(is_editor: bool, is_macos: bool, is_debug: bool, is_rel: bool) -> Dictionary:
	if is_rel:
		return {}
	if is_editor and is_macos:
		return read_private_defaults()
	if is_debug and not is_editor:
		return read_file(PACKAGE_PATH)
	return {}


static func read_private_defaults() -> Dictionary:
	var path: String = private_path()
	if not OS.has_feature("macos") or not FileAccess.file_exists(path):
		return {}
	if FileAccess.get_unix_permissions(path) != (FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_WRITE_OWNER):
		return {}
	return read_file(path)


static func read_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {}
	return parse_defaults(file.get_as_text())


static func parse_defaults(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return {}
	var parsed: JSON = JSON.new()
	if parsed.parse(text) != OK:
		return {}
	var value: Variant = parsed.data
	if not value is Dictionary or value.size() != 3 or value.get("format") != FORMAT:
		return {}
	var address: Variant = value.get("address")
	var token: Variant = value.get("upload_token")
	if not address is String or not token is String:
		return {}
	var address_pattern: RegEx = RegEx.new()
	address_pattern.compile("^https?://([A-Za-z0-9][A-Za-z0-9.-]*|\\[[0-9A-Fa-f:]+\\])(:[0-9]{1,5})?/?$")
	var matched: RegExMatch = address_pattern.search(address)
	if address.length() > 512 or matched == null:
		return {}
	var port: String = matched.get_string(2)
	if not port.is_empty() and (port.substr(1).to_int() < 1 or port.substr(1).to_int() > 65535):
		return {}
	if token.length() < 32 or token.length() > 256:
		return {}
	for character: int in token.to_utf8_buffer():
		if character < 33 or character > 126:
			return {}
	return {"format": FORMAT, "address": address.trim_suffix("/"), "upload_token": token}


static func resolve_connection(saved: ConfigFile, defaults: Dictionary) -> Dictionary:

	if OS.has_feature("rel"):
		return {"address": "", "token": "", "pending_id": ""}
	return {
		"address": String(saved.get_value("upload", "address", defaults.get("address", ""))), 
		"token": String(saved.get_value("upload", "token", defaults.get("upload_token", ""))), 
		"pending_id": String(saved.get_value("upload", "pending_id", "")), 
	}
