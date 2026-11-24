class_name HapticNative
extends RefCounted





const _FALLBACK_AMPLITUDE_MAX: float = 255.0

var _plugin: Object = null

var _ahap_cache: Dictionary = {}

var _ahap_failed: Dictionary = {}
var _core_haptics_supported: int = -1

var _waveform_generation: int = 0


func _init() -> void :
	if Engine.has_singleton("VibratePlugin"):
		_plugin = Engine.get_singleton("VibratePlugin")



func play(profile: Dictionary, event_name: String = "DEBUG") -> void :
	if OS.get_name() == "Android":
		_play_android(profile.get("android", {}), event_name)
	else:
		_play_ios(profile.get("ios", {}), event_name)



static func _log_dispatch(event_name: String, platform: String, cfg: Dictionary, is_fallback_plan: bool = false) -> void :
	var kind: String = String(cfg.get("type", ""))
	var details: String = ""
	match kind:
		"oneshot":
			details = "时长=%d毫秒 振幅=%d" % [int(cfg.get("duration_msec", 0)), int(cfg.get("amplitude", -1))]
		"waveform":
			var timings: Array = cfg.get("timings_msec", [])
			var amplitudes: Array = cfg.get("amplitudes", [])
			var total_msec: int = 0
			var pulse_starts: Array[int] = []
			for i: int in mini(timings.size(), amplitudes.size()):
				if int(amplitudes[i]) > 0:
					pulse_starts.append(total_msec)
				total_msec += int(timings[i])
			details = "时长=%s毫秒 振幅=%s 总时长=%d毫秒 脉冲起点=%s毫秒" % [timings, amplitudes, total_msec, pulse_starts]
		"transient", "continuous":
			var intensity: float = float(cfg.get("intensity", 0.5))

			var duration: String = "系统决定" if kind == "transient" else str(float(cfg.get("duration", 0.1)) * 1000.0) + "毫秒"
			details = "时长=%s 振幅=%.3f 强度=%.6f 锐度=%.3f" % [duration, intensity * 255.0, intensity, float(cfg.get("sharpness", 0.5))]
		"impact", "notification", "selection":
			details = "时长=系统决定 振幅=系统决定 样式=%d 通知种类=%d" % [int(cfg.get("style", -1)), int(cfg.get("kind", -1))]
		_:

			details = "时长=系统决定 振幅=系统决定 配置=%s" % JSON.stringify(cfg)

	var action: String = "降级震动计划" if is_fallback_plan else "触发震动"
	SortLogger.info("[HapticManager] %s 事件=%s 平台=%s 类型=%s %s" % [action, event_name, platform, kind, details])



static func _log_ahap(event_name: String, json: String, intensity_scale: float = 1.0, sharpness_scale: float = 1.0) -> void :
	var parsed: Variant = JSON.parse_string(json)
	var events: Array[String] = []
	if parsed is Dictionary:
		for entry: Dictionary in parsed.get("Pattern", []):
			if not entry.has("Event"):
				continue
			var event: Dictionary = entry["Event"]
			var kind: String = String(event.get("EventType", ""))
			if kind != "HapticContinuous" and kind != "HapticTransient":
				continue
			var intensity: String = "系统决定"
			var amplitude: String = "系统决定"
			var sharpness: String = "系统决定"
			for parameter: Dictionary in event.get("EventParameters", []):
				if parameter.get("ParameterID", "") == "HapticIntensity":
					var value: float = clampf(float(parameter.get("ParameterValue", 0.0)) * intensity_scale, 0.0, 1.0)
					intensity = "%.6f" % value
					amplitude = "%.3f" % (value * 255.0)
				elif parameter.get("ParameterID", "") == "HapticSharpness":
					sharpness = "%.3f" % clampf(float(parameter.get("ParameterValue", 0.0)) * sharpness_scale, 0.0, 1.0)
			var duration: String = "系统决定" if kind == "HapticTransient" else str(float(event.get("EventDuration", 0.0)) * 1000.0) + "毫秒"
			events.append("{起点=%s毫秒 时长=%s 振幅=%s 强度=%s 锐度=%s}" % [str(float(event.get("Time", 0.0)) * 1000.0), duration, amplitude, intensity, sharpness])
	SortLogger.info("[HapticManager] 触发震动 事件=%s 平台=iOS 类型=ahap_json 波形事件=%s 强度系数=%.3f 锐度系数=%.3f AHAP原文=%s" % [event_name, events, intensity_scale, sharpness_scale, json])



func cancel() -> void :
	_waveform_generation += 1
	if _plugin != null:
		_plugin.cancel()
	elif OS.get_name() == "Android":
		Input.vibrate_handheld(0)



static func waveform_to_ahap(cfg: Dictionary) -> Dictionary:
	var timings: Array = cfg.get("timings_msec", [])
	var amplitudes: Array = cfg.get("amplitudes", [])
	var pattern: Array[Dictionary] = []
	var elapsed_msec: int = 0
	for i: int in mini(timings.size(), amplitudes.size()):
		var duration: int = int(timings[i])
		if int(amplitudes[i]) > 0 and duration > 0:
			pattern.append({"Event": {
				"Time": float(elapsed_msec) / 1000.0, 
				"EventType": "HapticContinuous", 
				"EventDuration": float(duration) / 1000.0, 
				"EventParameters": [
					{"ParameterID": "HapticIntensity", "ParameterValue": float(amplitudes[i]) / 255.0}, 
					{"ParameterID": "HapticSharpness", "ParameterValue": float(cfg.get("sharpness", 0.5))}, 
				], 
			}})
		elapsed_msec += duration
	return {"Version": 1.0, "Pattern": pattern}



func _play_waveform_fallback(cfg: Dictionary, event_name: String = "DEBUG") -> void :
	_waveform_generation += 1
	var generation: int = _waveform_generation
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	_log_dispatch(event_name, OS.get_name(), cfg, true)
	var timings: Array = cfg.get("timings_msec", [])
	var amplitudes: Array = cfg.get("amplitudes", [])
	var start_msec: int = Time.get_ticks_msec()
	var elapsed_msec: int = 0
	for i: int in mini(timings.size(), amplitudes.size()):
		if int(amplitudes[i]) > 0:
			var wait_msec: int = start_msec + elapsed_msec - Time.get_ticks_msec()
			if wait_msec > 0:
				await tree.create_timer(float(wait_msec) / 1000.0).timeout
			if generation != _waveform_generation:
				return
			SortLogger.info("[HapticManager] 降级脉冲 事件=%s 段序号=%d 计划起点=%d毫秒 实际起点=%d毫秒" % [event_name, i, elapsed_msec, Time.get_ticks_msec() - start_msec])
			if _plugin != null and OS.get_name() == "iOS":

				_log_dispatch(event_name, "iOS", {"type": "impact", "style": 0})
				_plugin.impact(0)
			else:
				_log_dispatch(event_name, OS.get_name(), {"type": "oneshot", "duration_msec": int(timings[i]), "amplitude": int(amplitudes[i])})
				Input.vibrate_handheld(int(timings[i]), float(amplitudes[i]) / 255.0)
		elapsed_msec += int(timings[i])




func _play_android(cfg: Dictionary, event_name: String = "DEBUG") -> void :
	if cfg.is_empty():
		return
	if _plugin == null:
		if cfg.get("type", "") == "waveform":
			_play_waveform_fallback(cfg, event_name)
		else:
			_play_handheld_fallback(cfg, event_name)
		return
	match String(cfg.get("type", "")):
		"oneshot":

			_log_dispatch(event_name, "Android", cfg)
			_plugin.vibrate(int(cfg.get("duration_msec", 0)), int(cfg.get("amplitude", -1)))
		"waveform":
			_log_dispatch(event_name, "Android", cfg)
			_plugin.vibrateWaveform(
				PackedInt32Array(cfg.get("timings_msec", [])), 
				PackedInt32Array(cfg.get("amplitudes", [])))
		"composition":
			_log_dispatch(event_name, "Android", cfg)
			var played: bool = _plugin.vibrateComposition(
				PackedInt32Array(cfg.get("primitives", [])), 
				PackedInt32Array(cfg.get("scales_percent", [])), 
				PackedInt32Array(cfg.get("delays_msec", [])))

			if not played and cfg.has("fallback"):
				_play_android(cfg["fallback"], event_name)
		_:
			SortLogger.error("HapticNative: 未知 Android 表现类型 '%s'" % cfg.get("type", ""))



func _play_handheld_fallback(cfg: Dictionary, event_name: String = "DEBUG") -> void :
	var duration_msec: int = 0
	var amplitude: int = 0
	match String(cfg.get("type", "")):
		"oneshot":
			duration_msec = int(cfg.get("duration_msec", 0))
			amplitude = int(cfg.get("amplitude", 0))
		"waveform":
			var timings: Array = cfg.get("timings_msec", [])
			var amplitudes: Array = cfg.get("amplitudes", [])
			for i in mini(timings.size(), amplitudes.size()):
				if int(amplitudes[i]) > amplitude:
					amplitude = int(amplitudes[i])
					duration_msec = int(timings[i])
		"composition":
			if cfg.has("fallback"):
				_play_handheld_fallback(cfg["fallback"], event_name)
			return
	if duration_msec > 0 and amplitude > 0:

		_log_dispatch(event_name, "Android", {"type": "oneshot", "duration_msec": duration_msec, "amplitude": clampi(amplitude, 0, 255)})
		Input.vibrate_handheld(duration_msec, clampf(amplitude / _FALLBACK_AMPLITUDE_MAX, 0.0, 1.0))




func _play_ios(cfg: Dictionary, event_name: String = "DEBUG") -> void :
	if cfg.is_empty():
		return

	if cfg.get("type", "") == "waveform":
		if _plugin != null and _is_core_haptics_supported():
			_log_dispatch(event_name, "iOS", cfg)
			_play_ahap_json(JSON.stringify(waveform_to_ahap(cfg)), event_name)
		else:
			_play_waveform_fallback(cfg, event_name)
		return
	if _plugin == null:

		SortLogger.info("[HapticManager] 触发震动 事件=%s 平台=iOS 类型=oneshot 时长=25毫秒 振幅=76.500 强度=0.3" % event_name)
		Input.vibrate_handheld(25, 0.3)
		return
	match String(cfg.get("type", "")):
		"ahap":
			if not _play_ahap(cfg, event_name) and cfg.has("fallback"):
				_play_ios(cfg["fallback"], event_name)
		"ahap_json":

			if not _play_ahap_json(String(cfg.get("json", "")), event_name) and cfg.has("fallback"):
				_play_ios(cfg["fallback"], event_name)
		"impact":
			_log_dispatch(event_name, "iOS", {"type": "impact", "style": int(cfg.get("style", 1))})
			_plugin.impact(int(cfg.get("style", 1)))
		"notification":
			_log_dispatch(event_name, "iOS", {"type": "notification", "kind": int(cfg.get("kind", 0))})
			_plugin.notificationFeedback(int(cfg.get("kind", 0)))
		"selection":
			_log_dispatch(event_name, "iOS", cfg)
			_plugin.selectionChanged()
		"transient":

			if not _is_core_haptics_supported():
				if cfg.has("fallback"):
					_play_ios(cfg["fallback"], event_name)
				return
			_log_dispatch(event_name, "iOS", cfg)
			_plugin.playTransient(float(cfg.get("intensity", 0.5)), float(cfg.get("sharpness", 0.5)))
		"continuous":

			if not _is_core_haptics_supported():
				if cfg.has("fallback"):
					_play_ios(cfg["fallback"], event_name)
				return
			_log_dispatch(event_name, "iOS", cfg)
			_plugin.playContinuous(float(cfg.get("duration", 0.1)), 
				float(cfg.get("intensity", 0.5)), float(cfg.get("sharpness", 0.5)))
		_:
			SortLogger.error("HapticNative: 未知 iOS 表现类型 '%s'" % cfg.get("type", ""))



func _play_ahap(cfg: Dictionary, event_name: String = "DEBUG") -> bool:
	if not _is_core_haptics_supported():
		return false
	var json: String = _load_ahap(String(cfg.get("file", "")))
	if json.is_empty():
		return false
	_log_ahap(event_name, json, float(cfg.get("intensity_scale", 1.0)), float(cfg.get("sharpness_scale", 1.0)))
	_plugin.playAhapData(json, float(cfg.get("intensity_scale", 1.0)), float(cfg.get("sharpness_scale", 1.0)))
	return true



func _play_ahap_json(json: String, event_name: String = "DEBUG") -> bool:
	if json.is_empty() or not _is_core_haptics_supported():
		return false
	_log_ahap(event_name, json)
	_plugin.playAhapData(json, 1.0, 1.0)
	return true


func _is_core_haptics_supported() -> bool:
	if _core_haptics_supported < 0:
		_core_haptics_supported = 1 if bool(_plugin.isCoreHapticsSupported()) else 0
	return _core_haptics_supported == 1


func _load_ahap(path: String) -> String:
	if _ahap_cache.has(path):
		return _ahap_cache[path]
	if _ahap_failed.has(path):
		return ""
	var json: String = FileAccess.get_file_as_string(path)
	if json.is_empty():
		_ahap_failed[path] = true
		SortLogger.error("HapticNative: AHAP 文件读取失败 %s" % path)
		return ""
	_ahap_cache[path] = json
	return json
