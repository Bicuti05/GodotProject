class_name HapticTuneConfig
extends RefCounted


const FORMAT: String = "pocketsort_haptic_config_v1"
const SAVE_PATH: String = "user://haptic_tune_config.json"
const MAX_BYTES: int = 524288
signal loaded
signal saved(error: String)

var _overrides: Dictionary = {}
var _loaded: bool = false
var _revision: int = 0
var _load_revision: int = 0
var _task: int = -1
var _job: Dictionary = {}
var _job_kind: String = ""
var _save_due: int = -1
var _path: String = SAVE_PATH


func get_profile(event: int) -> Dictionary:
	var baseline: Dictionary = HapticProfiles.PROFILES.get(event, {})
	if OS.has_feature("rel") or baseline.is_empty():
		return baseline
	var key: String = HapticProfiles.Event.keys()[event]
	return baseline.merged(_overrides.get(key, {}), true)


func is_overridden(event: int) -> bool:
	return not OS.has_feature("rel") and _overrides.has(HapticProfiles.Event.keys()[event])


func set_platform(event: int, platform: String, cfg: Dictionary) -> String:
	if OS.has_feature("rel"):
		return "正式包不支持调试覆盖"
	if not HapticProfiles.PROFILES.has(event) or platform not in ["android", "ios"]:
		return "未知场景或平台"
	var error: String = _validate_effect(cfg, platform)
	if not error.is_empty():
		return error
	var key: String = HapticProfiles.Event.keys()[event]
	var profile: Dictionary = (_overrides.get(key, {}) as Dictionary).duplicate(true)
	profile[platform] = cfg.duplicate(true)
	_overrides[key] = profile
	_changed()
	return ""


func reset_event(event: int) -> void :
	if OS.has_feature("rel"):
		return
	_overrides.erase(HapticProfiles.Event.keys()[event])
	_changed()


func reset_all() -> void :
	if OS.has_feature("rel"):
		return
	_overrides.clear()
	_changed()


func export_json() -> String:
	var events: Dictionary = {}
	for event: int in HapticProfiles.PROFILES:
		var profile: Dictionary = get_profile(event)
		var configured: Dictionary = {}
		for platform: String in ["android", "ios"]:
			if not (profile.get(platform, {}) as Dictionary).is_empty():
				configured[platform] = profile[platform]
		if not configured.is_empty():
			events[HapticProfiles.Event.keys()[event]] = configured
	return JSON.stringify({"format": FORMAT, "events": events}, "  ")



func export_upload_snapshot() -> Dictionary:
	var current: Dictionary = {}
	var baseline: Dictionary = {}
	for event: int in HapticProfiles.PROFILES:
		var key: String = HapticProfiles.Event.keys()[event]
		var effective: Dictionary = get_profile(event)
		var defaults: Dictionary = HapticProfiles.PROFILES[event]
		var configured: Dictionary = {}
		var packaged: Dictionary = {}
		for platform: String in ["android", "ios"]:
			packaged[platform] = (defaults.get(platform, {}) as Dictionary).duplicate(true)
			if not (effective.get(platform, {}) as Dictionary).is_empty():
				configured[platform] = (effective[platform] as Dictionary).duplicate(true)
		baseline[key] = packaged
		if not configured.is_empty():
			current[key] = configured
	return {"config": {"format": FORMAT, "events": current}, "baseline": {"format": FORMAT, "events": baseline}}



func import_json(source: String) -> String:
	if OS.has_feature("rel"):
		return "正式包不支持导入调试配置"
	var result: Dictionary = _parse(source)
	if not result.error.is_empty():
		return result.error
	_overrides = result.events.duplicate(true)
	_changed()
	return ""


func _changed() -> void :
	_revision += 1

	_save_due = Time.get_ticks_msec() + 350


func load_saved() -> void :
	if _loaded or _task >= 0:
		return
	if OS.has_feature("rel"):
		_loaded = true
		loaded.emit()
		return
	_load_revision = _revision
	_job = {}
	_job_kind = "load"
	_task = WorkerThreadPool.add_task(_read_file.bind(_path, _job))


func tick() -> void :
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_complete_job()
	if not OS.has_feature("rel") and _save_due >= 0 and Time.get_ticks_msec() >= _save_due:
		_start_save()


func _complete_job() -> void :
	if _job_kind == "load":
		_loaded = true
		if _revision == _load_revision:
			if _job.get("error", "").is_empty():
				_overrides = _job.get("events", {})
			else:
				SortLogger.warn("HapticTuneConfig: 本机配置无效，使用正式参数：" + String(_job.error))
		loaded.emit()
	else:
		saved.emit(String(_job.get("error", "")))
	_job = {}


func _start_save() -> void :
	var source: String = "" if _overrides.is_empty() else JSON.stringify({"format": FORMAT, "events": _overrides})
	_save_due = -1
	_job = {}
	_job_kind = "save"
	_task = WorkerThreadPool.add_task(_write_file.bind(_path, source, _job))



func finish_save() -> void :
	if OS.has_feature("rel"):
		return
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_complete_job()
	if _save_due >= 0:
		_start_save()
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_complete_job()


static func _read_file(path: String, result: Dictionary) -> void :
	if not FileAccess.file_exists(path):
		result.merge({"events": {}, "error": ""})
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		result["error"] = "读取失败或配置超过512KiB"
		return
	result.merge(_parse(file.get_as_text()))


static func _write_file(path: String, source: String, result: Dictionary) -> void :
	if source.is_empty():
		var error: Error = DirAccess.remove_absolute(path) if FileAccess.file_exists(path) else OK
		result["error"] = "" if error == OK else error_string(error)
		return
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		result["error"] = error_string(FileAccess.get_open_error())
		return
	file.store_string(source)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, path)
	result["error"] = "" if error == OK else error_string(error)


static func _parse(source: String) -> Dictionary:
	var bad: Dictionary = {"events": {}, "error": "配置格式无效"}
	if source.to_utf8_buffer().size() > MAX_BYTES:
		bad.error = "配置超过512KiB"
		return bad
	var json: JSON = JSON.new()
	if json.parse(source) != OK or not json.data is Dictionary:
		return bad
	var data: Dictionary = json.data
	if data.get("format") != FORMAT or not data.get("events") is Dictionary:
		return bad
	for key: Variant in data.events:
		if key not in HapticProfiles.Event.keys() or not data.events[key] is Dictionary:
			return bad
		var profile: Dictionary = data.events[key]
		if profile.is_empty():
			return bad
		for platform: Variant in profile:
			if platform not in ["android", "ios"] or not profile[platform] is Dictionary:
				return bad
			var error: String = _validate_effect(profile[platform], platform)
			if not error.is_empty():
				bad.error = String(key) + " / " + String(platform) + "：" + error
				return bad
	return {"events": data.events, "error": ""}


static func _number(value: Variant, lo: float, hi: float, integer: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= lo\
	and float(value) <= hi and ( not integer or float(value) == floorf(float(value)))


static func _validate_effect(cfg: Dictionary, platform: String, depth: int = 0) -> String:
	var kind: Variant = cfg.get("type")
	var kinds: Array = ["oneshot", "waveform", "composition"] if platform == "android" else\
	["waveform", "impact", "notification", "selection", "transient", "continuous", "ahap", "ahap_json"]
	if kind not in kinds or depth > 2:
		return "未知效果类型或降级层数过多"
	var valid: bool = true
	match kind:
		"oneshot":
			valid = _number(cfg.get("duration_msec"), 1, 10000, true) and _number(cfg.get("amplitude"), -1, 255, true)
		"waveform", "composition":
			var fields: Array = ["timings_msec", "amplitudes"] if kind == "waveform" else ["primitives", "scales_percent", "delays_msec"]
			var count: int = -1
			for field: String in fields:
				var values: Variant = cfg.get(field)
				if not values is Array or values.is_empty() or values.size() > 64:
					return "数组必须包含1~64段"
				if count >= 0 and count != values.size():
					return "数组长度必须一致"
				count = values.size()
				for value: Variant in values:
					var lo: float = 1 if field == "primitives" else 0
					var hi: float = 8 if field == "primitives" else (255 if field == "amplitudes" else (100 if field == "scales_percent" else 10000))
					valid = valid and _number(value, lo, hi, true)
			if kind == "waveform":
				var total: int = 0
				for value: Variant in cfg.timings_msec:
					total += int(value)
				valid = valid and total > 0 and total <= 60000
		"impact":
			valid = _number(cfg.get("style"), 0, 4, true)
		"notification":
			valid = _number(cfg.get("kind"), 0, 2, true)
		"transient", "continuous":
			valid = _number(cfg.get("intensity"), 0, 1) and _number(cfg.get("sharpness"), 0, 1)
			if kind == "continuous":
				valid = valid and _number(cfg.get("duration"), 0.01, 10)
		"ahap":
			valid = cfg.get("file") is String and String(cfg.file).begins_with("res://assets/haptic/") and not ".." in cfg.file
			for field: String in ["intensity_scale", "sharpness_scale"]:
				valid = valid and _number(cfg.get(field, 1.0), 0, 2)
		"ahap_json":
			if not cfg.get("json") is String:
				return "AHAP文本无效"
			var ahap: Variant = JSON.parse_string(cfg.json)
			valid = ahap is Dictionary and _number(ahap.get("Version"), 1, 1) and ahap.get("Pattern") is Array
			if valid:
				valid = not ahap.Pattern.is_empty() and ahap.Pattern.size() <= 128
				for entry: Variant in ahap.Pattern:
					if not entry is Dictionary or ( not entry.has("Event") and not entry.has("ParameterCurve")):
						return "AHAP事件或曲线无效"
					if entry.has("Event"):
						var event: Variant = entry.Event
						if not event is Dictionary or event.get("EventType") not in ["HapticTransient", "HapticContinuous"] or not _number(event.get("Time"), 0, 60) or not event.get("EventParameters") is Array:
							return "AHAP事件参数无效"
						if event.EventType == "HapticContinuous" and not _number(event.get("EventDuration"), 0.001, 60):
							return "AHAP时长无效"
						for parameter: Variant in event.EventParameters:
							if not parameter is Dictionary or not parameter.get("ParameterID") is String or not _number(parameter.get("ParameterValue"), 0, 1):
								return "AHAP强度或包络无效"
					else:
						var curve: Variant = entry.ParameterCurve
						if not curve is Dictionary or not curve.get("ParameterID") is String or not _number(curve.get("Time"), 0, 60) or not curve.get("ParameterCurveControlPoints") is Array:
							return "AHAP曲线参数无效"
						if curve.ParameterCurveControlPoints.size() < 2 or curve.ParameterCurveControlPoints.size() > 64:
							return "AHAP曲线需要2~64个控制点"
						for point: Variant in curve.ParameterCurveControlPoints:
							if not point is Dictionary or not _number(point.get("Time"), 0, 60) or not _number(point.get("ParameterValue"), -1, 1):
								return "AHAP控制点无效"
	if not valid:
		return "参数超出范围或类型不正确"
	if cfg.has("fallback"):
		if not cfg.fallback is Dictionary:
			return "降级配置无效"
		return _validate_effect(cfg.fallback, platform, depth + 1)
	return ""
