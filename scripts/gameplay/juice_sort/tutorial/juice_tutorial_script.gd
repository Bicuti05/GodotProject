class_name JuiceTutorialScript
extends RefCounted



const LEVEL: = 1
const BOARD: = {
	"id": 1, "note": "tutorial", "capacity": 4, "targetCups": 4, 
	"initial": ["-|0,0,0,0", "0|2,2,2,2", "2|3,1,1,3", "1|1,1", "3|3,3"], 
	"incoming": [], 
}


const SCRIPTED_STEPS: = 5
const STEPS: Array[Dictionary] = [
	{"src": 2, "j": 2, "dst": 3, "idle": "JUICE_TUTOR_CONNECT_FLOWERS", "drag": "JUICE_TUTOR_CONNECT_FLOWERS", "focus": true}, 
	{"src": 2, "j": 0, "dst": 4, "idle": "JUICE_TUTOR_CONNECT_FLOWERS", "drag": "JUICE_TUTOR_CONNECT_FLOWERS", "focus": true}, 
	{"src": 1, "j": 0, "dst": 2, "idle": "JUICE_TUTOR_STEP2", "drag": "JUICE_TUTOR_STEP2", "collect": true, "focus": true}, 
	{"src": 0, "j": 0, "dst": 1, "idle": "JUICE_TUTOR_STEP2", "drag": "JUICE_TUTOR_STEP2", "collect": true, "focus": true}, 
	{"src": 4, "j": 3, "dst": 0, "idle": "JUICE_TUTOR_STEP3", "drag": "JUICE_TUTOR_STEP3"}, 
	{"src": 3, "j": 3, "dst": 4, "idle": "JUICE_TUTOR_FREE", "drag": "JUICE_TUTOR_FREE", "collect": true, "free": true}, 
	{"src": 0, "j": 0, "dst": 3, "idle": "JUICE_TUTOR_FREE", "drag": "JUICE_TUTOR_FREE", "collect": true, "free": true}, 
]
const WRONG_GRAB: = "JUICE_TUTOR_GRAB_GLOWING"


static func board_for() -> Dictionary:
	return BOARD.duplicate(true)


static func steps_for() -> Array[Dictionary]:
	return STEPS.duplicate(true)


static func build_level() -> JuiceLevel:
	var lv: JuiceLevel = JuiceLevel.from_dict(board_for())
	var errs: Array[String] = lv.validate()
	if not errs.is_empty():
		SortLogger.error("JuiceTutorialScript: 教学题面不合法 —— %s" % "\n".join(errs))
	return lv


static func build_model() -> JuiceLevelModel:
	var m: = JuiceLevelModel.new()
	m.level_id = LEVEL
	m.chapter_index = 1
	m.level_index = LEVEL
	m.raw = board_for()
	m.juice = build_level()
	return m


static func is_scripted_grab(step: int, src: int, j: int) -> bool:
	if step < 0 or step >= STEPS.size():
		return false
	var s: Dictionary = STEPS[step]
	return src == int(s.src) and j == int(s.j)


static func is_scripted_move(step: int, src: int, j: int, dst: int) -> bool:
	if step < 0 or step >= STEPS.size():
		return false
	var s: Dictionary = STEPS[step]
	return src == int(s.src) and j == int(s.j) and dst == int(s.dst)












static func why_key(st: Dictionary, src: int, j: int, dst: int) -> String:


	match JuiceRules.reject_reason(st, src, j, dst):
		JuiceRules.Reject.FULL:
			return "JUICE_TUTOR_WHY_FULL"
		JuiceRules.Reject.COLOR:
			return "JUICE_TUTOR_WHY_COLOR"
		JuiceRules.Reject.LOCKED:
			return "JUICE_TOAST_LOCKED_DROP"
		JuiceRules.Reject.MYSTERY:
			return "JUICE_TOAST_MYSTERY_EMPTY_ONLY"

	return "JUICE_TUTOR_WHY_FOLLOW"
