class_name HapticProfiles
extends RefCounted











enum Event{
	BUTTON, 
	PICK_UP, 
	MOVE_OK, 
	MOVE_REJECTED, 
	CUP_DONE, 
	HEX_BREAK, 
	LEVEL_WIN, 
	COMBO_NICE, 
	COMBO_GREAT, 
	COMBO_EXCELLENT, 
	COMBO_AMAZING, 
	COMBO_INCREDIBLE, 
	COMBO_UNSTOPPABLE, 
	COMBO_LEGENDARY, 
	COIN_FLY, 
	FINISH_POT_DROP, 
	GAME_ENTER, 
	FLOWER_MERGE, 
	IQ_SCORE_POP, 
	PICK_UP_STYLE1_V2, 
	MOVE_OK_STYLE1_V2, 
	FLOWER_MERGE_STYLE1_V2, 
	CUP_DONE_STYLE1_V2, 
	COMBO_NICE_STYLE1_V2, 
	COMBO_GREAT_STYLE1_V2, 
	COMBO_EXCELLENT_STYLE1_V2, 
	COMBO_AMAZING_STYLE1_V2, 
	COMBO_INCREDIBLE_STYLE1_V2, 
	COMBO_UNSTOPPABLE_STYLE1_V2, 
	COMBO_LEGENDARY_STYLE1_V2, 
	LEVEL_WIN_STYLE1_V2, 
	IQ_SCORE_POP_STYLE1_V2, 
	COIN_FLY_STYLE1_V2, 
	FINISH_POT_DROP_STYLE1_V2, 
	PICK_UP_STYLE2_V2, 
	MOVE_OK_STYLE2_V2, 
	FLOWER_MERGE_STYLE2_V2, 
	CUP_DONE_STYLE2_V2, 
	COMBO_NICE_STYLE2_V2, 
	COMBO_GREAT_STYLE2_V2, 
	COMBO_EXCELLENT_STYLE2_V2, 
	COMBO_AMAZING_STYLE2_V2, 
	COMBO_INCREDIBLE_STYLE2_V2, 
	COMBO_UNSTOPPABLE_STYLE2_V2, 
	COMBO_LEGENDARY_STYLE2_V2, 
	LEVEL_WIN_STYLE2_V2, 
	IQ_SCORE_POP_STYLE2_V2, 
	COIN_FLY_STYLE2_V2, 
	FINISH_POT_DROP_STYLE2_V2, 
}















const _IOS_SHARPNESS: float = 0.5



const _LIGHT: Dictionary = {
	"android": {"type": "oneshot", "duration_msec": 25, "amplitude": 100}, 
	"ios": {"type": "transient", "intensity": 100.0 / 255.0, "sharpness": _IOS_SHARPNESS, 
		"fallback": {"type": "impact", "style": 0}}, 
}
const _MEDIUM: Dictionary = {
	"android": {"type": "oneshot", "duration_msec": 120, "amplitude": 120}, 
	"ios": {"type": "transient", "intensity": 150.0 / 255.0, "sharpness": _IOS_SHARPNESS, 
		"fallback": {"type": "impact", "style": 1}}, 
}
const _HEAVY: Dictionary = {
	"android": {"type": "oneshot", "duration_msec": 150, "amplitude": 200}, 
	"ios": {"type": "transient", "intensity": 200.0 / 255.0, "sharpness": _IOS_SHARPNESS, 
		"fallback": {"type": "impact", "style": 2}}, 
}


const _COIN_WAVEFORM: Dictionary = {
	"type": "waveform", 
	"timings_msec": [950, 50, 50, 50, 50, 50, 50, 50, 50, 50], 
	"amplitudes": [0, 100, 0, 100, 0, 100, 0, 100, 0, 100], 
	"sharpness": _IOS_SHARPNESS, 
}
const _POT_WAVEFORM: Dictionary = {
	"type": "waveform", 
	"timings_msec": [1690, 50, 60, 50, 60, 50, 60, 50, 60, 50, 60, 50, 60, 50], 
	"amplitudes": [0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 100], 
	"sharpness": _IOS_SHARPNESS, 
}


const _COMBO_EVENTS: Array[int] = [Event.COMBO_NICE, Event.COMBO_GREAT, Event.COMBO_EXCELLENT, 
	Event.COMBO_AMAZING, Event.COMBO_INCREDIBLE, Event.COMBO_UNSTOPPABLE, Event.COMBO_LEGENDARY]

static var PROFILES: Dictionary = _build_profiles()


const _SHAKE_BASE_EVENTS: Array[int] = [
	Event.PICK_UP, 
	Event.MOVE_OK, 
	Event.FLOWER_MERGE, 
	Event.CUP_DONE, 
	Event.COMBO_NICE, 
	Event.COMBO_GREAT, 
	Event.COMBO_EXCELLENT, 
	Event.COMBO_AMAZING, 
	Event.COMBO_INCREDIBLE, 
	Event.COMBO_UNSTOPPABLE, 
	Event.COMBO_LEGENDARY, 
	Event.LEVEL_WIN, 
	Event.IQ_SCORE_POP, 
	Event.COIN_FLY, 
	Event.FINISH_POT_DROP, 
]
const _SHAKE_FIRST_EVENTS: Array[int] = [
	Event.PICK_UP_STYLE1_V2, 
	Event.MOVE_OK_STYLE1_V2, 
	Event.FLOWER_MERGE_STYLE1_V2, 
	Event.CUP_DONE_STYLE1_V2, 
	Event.COMBO_NICE_STYLE1_V2, 
	Event.COMBO_GREAT_STYLE1_V2, 
	Event.COMBO_EXCELLENT_STYLE1_V2, 
	Event.COMBO_AMAZING_STYLE1_V2, 
	Event.COMBO_INCREDIBLE_STYLE1_V2, 
	Event.COMBO_UNSTOPPABLE_STYLE1_V2, 
	Event.COMBO_LEGENDARY_STYLE1_V2, 
	Event.LEVEL_WIN_STYLE1_V2, 
	Event.IQ_SCORE_POP_STYLE1_V2, 
	Event.COIN_FLY_STYLE1_V2, 
	Event.FINISH_POT_DROP_STYLE1_V2, 
]
const _SHAKE_SECOND_EVENTS: Array[int] = [
	Event.PICK_UP_STYLE2_V2, 
	Event.MOVE_OK_STYLE2_V2, 
	Event.FLOWER_MERGE_STYLE2_V2, 
	Event.CUP_DONE_STYLE2_V2, 
	Event.COMBO_NICE_STYLE2_V2, 
	Event.COMBO_GREAT_STYLE2_V2, 
	Event.COMBO_EXCELLENT_STYLE2_V2, 
	Event.COMBO_AMAZING_STYLE2_V2, 
	Event.COMBO_INCREDIBLE_STYLE2_V2, 
	Event.COMBO_UNSTOPPABLE_STYLE2_V2, 
	Event.COMBO_LEGENDARY_STYLE2_V2, 
	Event.LEVEL_WIN_STYLE2_V2, 
	Event.IQ_SCORE_POP_STYLE2_V2, 
	Event.COIN_FLY_STYLE2_V2, 
	Event.FINISH_POT_DROP_STYLE2_V2, 
]




static func _build_profiles() -> Dictionary:
	var profiles: Dictionary = {
		Event.BUTTON: {"priority": 0, "android": _LIGHT["android"], "ios": _LIGHT["ios"]}, 
		Event.PICK_UP: {"priority": 5, "android": _LIGHT["android"], "ios": _LIGHT["ios"]}, 
		Event.MOVE_OK: {"priority": 8, "android": _LIGHT["android"], "ios": _LIGHT["ios"]}, 
		Event.HEX_BREAK: {"priority": 20, "android": _MEDIUM["android"], "ios": _MEDIUM["ios"]}, 
		Event.MOVE_REJECTED: {"priority": 25, "android": _MEDIUM["android"], "ios": _MEDIUM["ios"]}, 
		Event.CUP_DONE: {"priority": 30, "android": _MEDIUM["android"], "ios": _MEDIUM["ios"]}, 
		Event.LEVEL_WIN: {"priority": 50, "android": _HEAVY["android"], "ios": _HEAVY["ios"]}, 
		Event.COMBO_NICE: _combo_profile([100, 80, 100], [20, 0, 10], 0), 
		Event.COMBO_GREAT: _combo_profile([120, 80, 120], [40, 0, 20], 0), 
		Event.COMBO_EXCELLENT: _combo_profile([135, 90, 135], [95, 0, 85], 0), 
		Event.COMBO_AMAZING: _combo_profile([150, 100, 150], [150, 0, 150], 1), 
		Event.COMBO_INCREDIBLE: _combo_profile([175, 100, 175], [175, 0, 150], 1), 
		Event.COMBO_UNSTOPPABLE: _combo_profile([200, 100, 200], [200, 0, 150], 2), 
		Event.COMBO_LEGENDARY: _combo_profile([225, 100, 225], [225, 0, 175], 2), 
		Event.COIN_FLY: {"priority": 55, "android": _COIN_WAVEFORM, "ios": _COIN_WAVEFORM}, 
		Event.FINISH_POT_DROP: {"priority": 60, "android": _POT_WAVEFORM, "ios": _POT_WAVEFORM}, 
	}
	var entry: Dictionary = _combo_profile([50, 50, 50], [100, 0, 100], 0)
	entry.priority = 10

	var ahap: Dictionary = JSON.parse_string(entry.ios.json)
	for item: Dictionary in ahap.Pattern:
		item.Event.EventParameters[0].ParameterValue = 0.392
	entry.ios.json = JSON.stringify(ahap)
	profiles[Event.GAME_ENTER] = entry
	profiles[Event.FLOWER_MERGE] = {"priority": 8, "android": {}, "ios": {}}
	profiles[Event.IQ_SCORE_POP] = {"priority": 50, "android": {}, "ios": {}}
	for index: int in _SHAKE_BASE_EVENTS.size():
		var priority: int = int(profiles[_SHAKE_BASE_EVENTS[index]].priority)

		profiles[_SHAKE_FIRST_EVENTS[index]] = {"priority": priority, "android": {}, "ios": {}}
		profiles[_SHAKE_SECOND_EVENTS[index]] = {"priority": priority, "android": {}, "ios": {}}


	profiles[Event.COMBO_AMAZING_STYLE1_V2]["android"] = {"amplitudes": [200, 0, 240, 0, 140], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_AMAZING_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.941176470588235}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_AMAZING_STYLE2_V2]["android"] = {"amplitudes": [140, 0, 160, 0, 100], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_AMAZING_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.392156862745098}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_EXCELLENT_STYLE1_V2]["android"] = {"amplitudes": [160, 0, 200, 0, 120], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_EXCELLENT_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_EXCELLENT_STYLE2_V2]["android"] = {"amplitudes": [120, 0, 160, 0, 80], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_EXCELLENT_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_GREAT_STYLE1_V2]["android"] = {"amplitudes": [120, 0, 160, 0, 100], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_GREAT_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.392156862745098}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_GREAT_STYLE2_V2]["android"] = {"amplitudes": [100, 0, 140, 0, 60], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_GREAT_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.392156862745098}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.235294117647059}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_INCREDIBLE_STYLE1_V2]["android"] = {"amplitudes": [200, 0, 240, 0, 140], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_INCREDIBLE_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.941176470588235}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_INCREDIBLE_STYLE2_V2]["android"] = {"amplitudes": [160, 0, 200, 0, 120], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_INCREDIBLE_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_LEGENDARY_STYLE1_V2]["android"] = {"amplitudes": [200, 0, 240, 0, 140], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_LEGENDARY_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.941176470588235}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_LEGENDARY_STYLE2_V2]["android"] = {"amplitudes": [160, 0, 200, 0, 120], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_LEGENDARY_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_NICE_STYLE1_V2]["android"] = {"amplitudes": [80, 0, 120, 0, 60], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_NICE_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.235294117647059}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_NICE_STYLE2_V2]["android"] = {"amplitudes": [80, 0, 120, 0, 60], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_NICE_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.235294117647059}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_UNSTOPPABLE_STYLE1_V2]["android"] = {"amplitudes": [200, 0, 240, 0, 140], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_UNSTOPPABLE_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.941176470588235}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.COMBO_UNSTOPPABLE_STYLE2_V2]["android"] = {"amplitudes": [160, 0, 200, 0, 120], "timings_msec": [140, 100, 140, 100, 160], "type": "waveform"}
	profiles[Event.COMBO_UNSTOPPABLE_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.14, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.24}}, {"Event": {"EventDuration": 0.16, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.48}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.CUP_DONE_STYLE1_V2]["android"] = {"amplitude": 120, "duration_msec": 120, "type": "oneshot"}
	profiles[Event.CUP_DONE_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.12, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.CUP_DONE_STYLE2_V2]["android"] = {"amplitude": 120, "duration_msec": 120, "type": "oneshot"}
	profiles[Event.CUP_DONE_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.12, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.FINISH_POT_DROP_STYLE1_V2]["android"] = {"amplitudes": [80, 0, 160, 0, 160, 0, 160, 0, 160], "timings_msec": [600, 1200, 80, 80, 80, 80, 80, 80, 80], "type": "waveform"}
	profiles[Event.FINISH_POT_DROP_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.6, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 1.8}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 1.96}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 2.12}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.627450980392157}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 2.28}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.FINISH_POT_DROP_STYLE2_V2]["android"] = {"amplitudes": [100, 0, 200, 0, 200, 0, 200, 0, 200], "timings_msec": [600, 1200, 80, 80, 80, 80, 80, 80, 80], "type": "waveform"}
	profiles[Event.FINISH_POT_DROP_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.6, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.392156862745098}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 1.8}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 1.96}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 2.12}}, {"Event": {"EventDuration": 0.08, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.784313725490196}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 2.28}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.FLOWER_MERGE_STYLE1_V2]["android"] = {"amplitudes": [80, 0, 120, 0], "timings_msec": [150, 120, 150, 120], "type": "waveform"}
	profiles[Event.FLOWER_MERGE_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.15, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.15, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.27}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.FLOWER_MERGE_STYLE2_V2]["android"] = {"amplitudes": [80, 0, 80, 0], "timings_msec": [130, 120, 130, 120], "type": "waveform"}
	profiles[Event.FLOWER_MERGE_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.13, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}, {"Event": {"EventDuration": 0.13, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.313725490196078}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0.25}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.IQ_SCORE_POP_STYLE1_V2]["android"] = {"amplitudes": [140], "timings_msec": [60], "type": "waveform"}
	profiles[Event.IQ_SCORE_POP_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.06, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.549019607843137}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.IQ_SCORE_POP_STYLE2_V2]["android"] = {"amplitudes": [100], "timings_msec": [40], "type": "waveform"}
	profiles[Event.IQ_SCORE_POP_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.04, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.392156862745098}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.LEVEL_WIN_STYLE1_V2]["android"] = {"amplitudes": [0], "timings_msec": [1], "type": "waveform"}
	profiles[Event.LEVEL_WIN_STYLE1_V2]["ios"] = {"amplitudes": [0], "timings_msec": [1], "type": "waveform"}
	profiles[Event.LEVEL_WIN_STYLE2_V2]["android"] = {"amplitude": 0, "duration_msec": 1, "type": "oneshot"}
	profiles[Event.LEVEL_WIN_STYLE2_V2]["ios"] = {"amplitudes": [0], "timings_msec": [1], "type": "waveform"}
	profiles[Event.MOVE_OK_STYLE1_V2]["android"] = {"amplitude": 120, "duration_msec": 40, "type": "oneshot"}
	profiles[Event.MOVE_OK_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.04, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.MOVE_OK_STYLE2_V2]["android"] = {"amplitude": 90, "duration_msec": 30, "type": "oneshot"}
	profiles[Event.MOVE_OK_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.03, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.352941176470588}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.PICK_UP_STYLE1_V2]["android"] = {"amplitude": 120, "duration_msec": 50, "type": "oneshot"}
	profiles[Event.PICK_UP_STYLE1_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.05, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}
	profiles[Event.PICK_UP_STYLE2_V2]["android"] = {"amplitude": 120, "duration_msec": 50, "type": "oneshot"}
	profiles[Event.PICK_UP_STYLE2_V2]["ios"] = {"json": JSON.stringify({"Pattern": [{"Event": {"EventDuration": 0.05, "EventParameters": [{"ParameterID": "HapticIntensity", "ParameterValue": 0.470588235294118}, {"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}], "EventType": "HapticContinuous", "Time": 0}}], "Version": 1}), "type": "ahap_json"}

	return profiles



static func shake_event_for(event: int, style: int) -> int:
	if style not in [1, 2]:
		return event
	var index: int = _SHAKE_BASE_EVENTS.find(event)
	if index < 0:
		return event
	return _SHAKE_FIRST_EVENTS[index] if style == 1 else _SHAKE_SECOND_EVENTS[index]



static func _combo_profile(timings: Array[int], amplitudes: Array[int], fallback_style: int) -> Dictionary:
	var pattern: Array[Dictionary] = []
	var time: float = 0.0
	for i: int in timings.size():
		if amplitudes[i] > 0:
			pattern.append({"Event": {
				"EventType": "HapticContinuous", "Time": time, "EventDuration": timings[i] / 1000.0, 
				"EventParameters": [
					{"ParameterID": "HapticIntensity", "ParameterValue": amplitudes[i] / 255.0}, 
					{"ParameterID": "HapticSharpness", "ParameterValue": _IOS_SHARPNESS}, 
				], 
			}})
		time += timings[i] / 1000.0
	return {
		"priority": 40, 
		"android": {"type": "waveform", "timings_msec": timings, "amplitudes": amplitudes}, 
		"ios": {"type": "ahap_json", "json": JSON.stringify({"Version": 1, "Pattern": pattern}), 
			"fallback": {"type": "impact", "style": fallback_style}}, 
	}



static func combo_event_for_count(combo_count: int, three_levels: bool = false) -> int:
	if combo_count < 2:
		return -1
	if three_levels:
		if combo_count <= 4:
			return Event.COMBO_GREAT
		return Event.COMBO_AMAZING if combo_count <= 7 else Event.COMBO_UNSTOPPABLE
	return _COMBO_EVENTS[mini(combo_count - 2, _COMBO_EVENTS.size() - 1)]



static func is_three_level_combo_platform(os_name: String) -> bool:
	return os_name == "Android"



static func priority_of(event: int) -> int:
	var profile: Dictionary = PROFILES.get(event, {})
	return int(profile.get("priority", -1))
