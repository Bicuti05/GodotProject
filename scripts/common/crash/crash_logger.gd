


class_name CrashLogger
extends Logger


const _DEDUP_WINDOW_MS: int = 5000

var _mutex: = Mutex.new()

var _recent: Dictionary = {}

func _log_error(
	function: String, 
	file: String, 
	line: int, 
	code: String, 
	rationale: String, 
	editor_notify: bool, 
	error_type: int, 
	script_backtraces: Array[ScriptBacktrace]
) -> void :



	if script_backtraces.is_empty():
		return

	if error_type != Logger.ERROR_TYPE_ERROR and error_type != Logger.ERROR_TYPE_SCRIPT:
		return




	var msg: String
	if not rationale.is_empty() and not code.is_empty():
		msg = "%s | %s" % [code, rationale]
	elif not rationale.is_empty():
		msg = rationale
	else:
		msg = code

	_mutex.lock()
	var now_ms: int = Time.get_ticks_msec()

	var key: int = hash(msg + script_backtraces[0].format())
	var last: int = _recent.get(key, - _DEDUP_WINDOW_MS - 1)
	if now_ms - last < _DEDUP_WINDOW_MS:
		_mutex.unlock()
		return
	_recent[key] = now_ms

	if _recent.size() > 200:
		_recent.clear()
	_mutex.unlock()


	var stack_lines: PackedStringArray = []
	for bt in script_backtraces:
		stack_lines.append(bt.format())
	var stack: String = "\n".join(stack_lines)




	if not is_instance_valid(NativeUtilManager):
		return

	NativeUtilManager.log_exception(msg, stack)
