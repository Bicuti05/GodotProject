class_name HapticConfigConverter
extends RefCounted



const _IMPACT_DURATIONS: Array[int] = [40, 40, 60, 30, 60]
const _IMPACT_AMPLITUDES: Array[int] = [80, 120, 200, 60, 220]
const _NOTIFICATION_TIMINGS: Array = [[30, 50, 80], [80, 60, 80], [60, 50, 70, 60, 110]]
const _NOTIFICATION_AMPLITUDES: Array = [[100, 0, 160], [160, 0, 160], [160, 0, 200, 0, 230]]


static func prepare(cfg: Dictionary, source: String, target: String, job: Dictionary) -> void :
	job.result = convert_effect(cfg, source, target)


static func convert_effect(cfg: Dictionary, source: String, target: String, depth: int = 0) -> Dictionary:
	if source not in ["android", "ios"] or target not in ["android", "ios"] or source == target:
		return _failure("转换平台无效")
	if cfg.get("type") == "ahap_json" and cfg.get("json") is String:
		var json_error: String = _json_error(cfg.json)
		if not json_error.is_empty():
			return _failure(json_error)
	var error: String = HapticTuneConfig._validate_effect(cfg, source, depth)
	if not error.is_empty():
		return _failure("来源配置无效：" + error)
	var result: Dictionary = _android_to_ios(cfg) if source == "android" else _ios_to_android(cfg)
	if not result.ok:
		return result
	if cfg.has("fallback"):
		var fallback: Dictionary = convert_effect(cfg.fallback, source, target, depth + 1)
		if not fallback.ok:
			return _failure("降级配置无法转换：" + String(fallback.error))
		result.cfg.fallback = fallback.cfg
	error = HapticTuneConfig._validate_effect(result.cfg, target, depth)
	return result if error.is_empty() else _failure("换算结果超出目标平台限制：" + error)


static func _android_to_ios(cfg: Dictionary) -> Dictionary:
	if cfg.type == "composition":
		var peak: float = 0
		for scale: Variant in cfg.scales_percent:
			peak = maxf(peak, float(scale) * 255.0 / 100.0)
		return _success({"type": "impact", "style": 0 if peak <= 85 else (1 if peak <= 170 else 2)})
	var waveform: Dictionary = cfg.duplicate(true)
	if cfg.type == "oneshot":
		waveform = {"timings_msec": [cfg.duration_msec], "amplitudes": [128 if int(cfg.amplitude) < 0 else int(cfg.amplitude)]}
	var ahap: Dictionary = HapticNative.waveform_to_ahap(waveform)
	if ahap.Pattern.is_empty():
		return _failure("来源没有非零振动段，无法生成 AHAP")
	return _success({"type": "ahap_json", "json": JSON.stringify(ahap)})


static func _ios_to_android(cfg: Dictionary) -> Dictionary:
	match String(cfg.type):
		"impact":
			var style: int = int(cfg.style)
			return _success({"type": "oneshot", "duration_msec": _IMPACT_DURATIONS[style], "amplitude": _IMPACT_AMPLITUDES[style]})
		"notification":
			var kind: int = int(cfg.kind)
			return _success({"type": "waveform", "timings_msec": _NOTIFICATION_TIMINGS[kind].duplicate(), "amplitudes": _NOTIFICATION_AMPLITUDES[kind].duplicate()})
		"selection":
			return _success({"type": "oneshot", "duration_msec": 10, "amplitude": 50})
		"continuous":
			return _success({"type": "oneshot", "duration_msec": roundi(float(cfg.duration) * 1000.0), "amplitude": roundi(float(cfg.intensity) * 255.0)})
		"waveform":
			return _success({"type": "waveform", "timings_msec": cfg.timings_msec.duplicate(), "amplitudes": cfg.amplitudes.duplicate()})
		"transient":
			return _failure("瞬态事件没有可换算的持续时长，请先改为持续事件")
		"ahap", "ahap_json":
			var text: String = String(cfg.get("json", ""))
			if cfg.type == "ahap":
				var file: FileAccess = FileAccess.open(String(cfg.file), FileAccess.READ)
				if file == null or file.get_length() > HapticTuneConfig.MAX_BYTES:
					return _failure("AHAP 文件无法读取或过大")
				text = file.get_as_text()
			var json_error: String = _json_error(text)
			if not json_error.is_empty():
				return _failure(json_error)
			var error: String = HapticTuneConfig._validate_effect({"type": "ahap_json", "json": text}, "ios")
			if not error.is_empty():
				return _failure("AHAP 内容无效：" + error)
			return _ahap_to_android(JSON.parse_string(text), float(cfg.get("intensity_scale", 1.0)))
	return _failure("该 iOS 效果无法转换")


static func _ahap_to_android(ahap: Dictionary, intensity_scale: float) -> Dictionary:
	var events: Array[Dictionary] = []
	for entry: Dictionary in ahap.Pattern:
		if entry.has("ParameterCurve"):
			return _failure("AHAP 含控制曲线，无法按分段波形直接换算")
		var event: Dictionary = entry.Event
		if event.EventType != "HapticContinuous":
			return _failure("AHAP 含瞬态事件，持续时长未知，无法直接换算")
		var intensity: float = 1.0
		for parameter: Dictionary in event.EventParameters:
			var name: String = String(parameter.ParameterID)
			var value: float = float(parameter.ParameterValue)
			if name == "HapticIntensity":
				intensity = value
			elif name == "HapticSharpness":
				continue
			elif name in ["AttackTime", "DecayTime", "ReleaseTime", "HapticAttackTime", "HapticDecayTime", "HapticReleaseTime"] and is_zero_approx(value):
				continue
			elif name in ["Sustained", "HapticSustained"] and is_equal_approx(value, 1.0):
				continue
			else:
				return _failure("AHAP 含包络或其他事件参数，无法直接换算")
		events.append({"start": float(event.Time), "duration": float(event.EventDuration), "amplitude": roundi(clampf(intensity * intensity_scale, 0, 1) * 255.0)})
	events.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return a.start < b.start)
	var timings: Array[int] = []
	var amplitudes: Array[int] = []
	var elapsed: float = 0.0
	for event: Dictionary in events:
		if float(event.start) < elapsed - 1e-06:
			return _failure("AHAP 含重叠事件，无法按顺序波形直接换算")
		var pause: int = maxi(roundi(float(event.start) * 1000.0) - roundi(elapsed * 1000.0), 0)
		_append_segments(timings, amplitudes, pause, 0)
		_append_segments(timings, amplitudes, maxi(roundi(float(event.duration) * 1000.0), 1), int(event.amplitude))
		elapsed = float(event.start) + float(event.duration)
	return _success({"type": "waveform", "timings_msec": timings, "amplitudes": amplitudes})



static func _append_segments(timings: Array[int], amplitudes: Array[int], duration: int, amplitude: int) -> void :
	while duration > 0:
		var part: int = mini(duration, 10000)
		timings.append(part)
		amplitudes.append(amplitude)
		duration -= part


static func _success(cfg: Dictionary) -> Dictionary:
	return {"ok": true, "cfg": cfg, "error": ""}



static func _json_error(text: String) -> String:
	if text.to_utf8_buffer().size() > HapticTuneConfig.MAX_BYTES:
		return "AHAP 内容超过512KiB"
	var document: JSON = JSON.new()
	return "" if document.parse(text) == OK else "AHAP 内容无效：" + document.get_error_message()


static func _failure(error: String) -> Dictionary:
	return {"ok": false, "cfg": {}, "error": error}
