extends Node









const SESSION_REFRESH_INTERVAL_SEC: int = 30 * 60

signal session_changed(new_session_id: String)

var session_id: String = ""
var session_count: int = 1

var _last_away_time: int = 0


var _autoloads_ready: bool = false

func _ready() -> void :
	_reset_session()
	set_deferred("_autoloads_ready", true)

func _notification(what: int) -> void :
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_last_away_time = int(Time.get_unix_time_from_system())



			if _autoloads_ready:
				AuthManager.track_user_permissions()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_on_resume()

			if _autoloads_ready:
				AuthManager.track_user_permissions()

func _on_resume() -> void :

	if _last_away_time == 0:
		return
	var span_sec: int = int(Time.get_unix_time_from_system()) - _last_away_time
	if span_sec > SESSION_REFRESH_INTERVAL_SEC:
		_reset_session()
		session_changed.emit(session_id)
	else:
		session_count += 1

func _reset_session() -> void :
	session_id = _gen_session_id()
	session_count = 1
	_last_away_time = int(Time.get_unix_time_from_system())

	UserState.inc_session_num()


func get_session_num() -> int:
	return UserState.get_session_num()


func _gen_session_id() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), 
		hex.substr(8, 4), 
		hex.substr(12, 4), 
		hex.substr(16, 4), 
		hex.substr(20, 12), 
	]
