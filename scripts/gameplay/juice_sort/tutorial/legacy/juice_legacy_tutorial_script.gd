class_name JuiceLegacyTutorialScript
extends RefCounted
















const BOARD: = {
	"id": 1, 
	"note": "tutorial", 
	"capacity": 3, 
	"targetCups": 3, 
	"initial": ["-|1", "0|0,1,2", "1|0,0", "2|2,1,2"], 
	"incoming": ["x|", "x|"], 
}


const LEVEL: = 1






const STEPS: Array[Dictionary] = [
	{"src": 1, "j": 1, "dst": 0, 
		"idle": "JUICE_TUTOR_STEP1", "drag": "JUICE_TUTOR_DRAG_SAME_COLOR"}, 
	{"src": 2, "j": 0, "dst": 1, 
		"idle": "JUICE_TUTOR_STEP2", "drag": "JUICE_TUTOR_DRAG_SAME_COLOR"}, 

	{"src": 0, "j": 0, "dst": 2, 
		"idle": "JUICE_TUTOR_STEP3", "drag": "JUICE_TUTOR_STEP3"}, 
	{"src": 2, "j": 2, "dst": 0, 
		"idle": "JUICE_TUTOR_STEP3", "drag": "JUICE_TUTOR_STEP3"}, 
]


const FREE_IDLE: = "JUICE_TUTOR_FREE"
const FREE_DRAG: = "JUICE_TUTOR_FREE_DRAGGING"
const WRONG_GRAB: = "JUICE_TUTOR_GRAB_GLOWING"




static func board_for() -> Dictionary:
	return BOARD.duplicate(true)


static func build_level() -> JuiceLevel:
	var lv: JuiceLevel = JuiceLevel.from_dict(board_for())
	var errs: Array[String] = lv.validate()
	if not errs.is_empty():
		SortLogger.error("JuiceLegacyTutorialScript: 教学局题面不合法 —— %s" % "\n".join(errs))
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
	var steps: Array[Dictionary] = STEPS
	if step < 0 or step >= steps.size():
		return false
	var s: Dictionary = steps[step]
	return src == int(s["src"]) and j == int(s["j"])



static func is_scripted_move(step: int, src: int, j: int, dst: int) -> bool:
	var steps: Array[Dictionary] = STEPS
	if step < 0 or step >= steps.size():
		return false
	var s: Dictionary = steps[step]
	return src == int(s["src"]) and j == int(s["j"]) and dst == int(s["dst"])












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
