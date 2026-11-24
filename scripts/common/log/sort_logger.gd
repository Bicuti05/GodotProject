class_name SortLogger






const TAG: = "SortParade"


static func mark(msg: String = "") -> void :
	var caller: = _caller_signature()
	if msg.is_empty():
		print("[%s] %s" % [TAG, caller])
	else:
		print("[%s] %s :: %s" % [TAG, caller, msg])

static func info(msg: String) -> void :
	print("[%s][INFO] %s" % [TAG, msg])

static func warn(msg: String) -> void :
	push_warning("[%s][WARN] %s" % [TAG, msg])

static func error(msg: String) -> void :
	push_error("[%s][ERR] %s" % [TAG, msg])

static func _caller_signature() -> String:
	if not OS.is_debug_build():
		return ""
	var frames: = get_stack()

	if frames.size() >= 3:
		var f: Dictionary = frames[2]
		return "%s:%d %s()" % [f.get("source", "?"), f.get("line", 0), f.get("function", "?")]
	return ""
