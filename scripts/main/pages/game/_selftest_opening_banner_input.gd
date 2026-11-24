extends Node

class ProbePage extends JuiceGamePage:
	var tutorial: bool = false
	var mystery: bool = false
	var locked: bool = false
	var prop_unlock: bool = false

	func should_run_tutorial_now(_restore: Dictionary) -> bool:
		return tutorial

	func should_run_mystery_guide_now(restore: Dictionary) -> bool:
		return mystery and restore.is_empty()

	func should_run_lock_guide_now(restore: Dictionary) -> bool:
		return locked and restore.is_empty()

	func _pending_prop_unlock_keys() -> Array[String]:
		var keys: Array[String] = []
		if prop_unlock:
			keys.append("hint")
		return keys

var _failures: int = 0

func _ready() -> void :
	call_deferred("_run")

func _check(value: bool, label: String) -> void :
	if not value:
		_failures += 1
		SortLogger.error("[OpeningBannerInput] FAIL: " + label)

func _run() -> void :
	var page: = ProbePage.new()
	var board: = JuiceBoardView.new()
	page._board = board
	var ctx: = GameStartContext.new(page)
	_check( not page._opening_banner_has_guide(ctx), "无引导不锁")
	for kind: String in ["tutorial", "mystery", "locked", "prop_unlock"]:
		page.set(kind, true)
		_check(page._opening_banner_has_guide(ctx), kind + "命中输入门控")
		page.set(kind, false)
	page._tutorial_active = true
	_check(page._opening_banner_has_guide(ctx), "已装好的新手引导")
	page._tutorial_active = false
	page.mystery = true
	page.locked = true
	page.prop_unlock = true
	ctx.skip_mystery_guide = true
	ctx.skip_lock_guide = true
	ctx.skip_prop_unlock = true
	_check( not page._opening_banner_has_guide(ctx), "跳过所有后续引导")
	ctx.skip_mystery_guide = false
	ctx.skip_lock_guide = false
	ctx.current_state = {"resumed": true}
	_check( not page._opening_banner_has_guide(ctx), "续局跳过问号与锁列")
	var generation: int = page._begin_opening_banner_input_lock()
	_check( not board._input_enabled and not page._ui_button_is_ready("hint")
		and not page._ui_button_is_ready("reset"), "横幅期间盘面/道具/重开被锁")

	page._playfield_ready = true
	page._ui_props_ready = true
	page._use_prop("hint")
	var next_generation: int = page._begin_opening_banner_input_lock()
	page._end_opening_banner_input_lock(generation)
	_check( not board._input_enabled, "旧横幅不能解锁新横幅")
	page._end_opening_banner_input_lock(next_generation)
	_check(board._input_enabled and page._ui_button_is_ready("hint"), "恢复原输入状态")
	board.set_input_enabled(false)
	generation = page._begin_opening_banner_input_lock()
	page._end_opening_banner_input_lock(generation)
	_check( not board._input_enabled, "不会打开其他入口原先关闭的输入")
	board.set_input_enabled(true)
	generation = page._begin_opening_banner_input_lock()
	page._cancel_opening_banner_input_lock()
	var active_generation: int = page._begin_opening_banner_input_lock()
	page._end_opening_banner_input_lock(generation)
	_check( not board._input_enabled, "取消后旧协程不得解锁新局")
	page._end_opening_banner_input_lock(active_generation)
	_check(board._input_enabled, "取消/重入可正常恢复")
	_check( not page._opening_banner_should_lock_input(false, true, 0), 
		"对照组连胜横幅不额外锁")
	_check(page._opening_banner_should_lock_input(false, true, 1), 
		"连胜实验组1锁整段横幅")
	_check( not page._opening_banner_should_lock_input(false, true, 2), 
		"连胜实验组2不额外锁")
	_check(page._opening_banner_should_lock_input(true, true, 2), 
		"实验组2遇引导仍沿用引导锁")

	_check( not page._opening_banner_should_lock_input(false, false, 0), 
		"特殊挑战横幅不额外锁")
	page.free()
	board.free()
	if _failures == 0:
		SortLogger.info("OPENING_BANNER_INPUT_PASS")
	get_tree().quit(_failures)
