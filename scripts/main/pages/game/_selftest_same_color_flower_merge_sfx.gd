extends Node

const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")
const KEY: String = "same_color_flower_merge_sfx"


class ProbePage extends JuiceGamePage:
	func _ready() -> void :
		set_process(false)

var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :
	_check_config()
	var page: JuiceGamePage = load("res://scripts/main/pages/game/juice_game_page.tscn").instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page)
	var board: JuiceBoardView = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn").instantiate()
	page.add_child(board)
	board.set_process(false)
	page._board = board
	board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	board.same_color_merge_sound_requested.connect(page._on_same_color_merge_sound_requested)
	var step: = ValidDropStep.new()
	for group: String in ["default", "set1", "set2"]:
		_reset(group)
		_setup_board(board)
		_drop(step, board, 0, 0, 1)
		_expect_sound(_sound_for(group), "普通同色连接：" + group)
		_check(ABManager.dyes == 1 and ABManager.events == ["get", "dye", "play"], "先get→dye再播音：" + group)
		_check( not board._connection_pending.is_empty(), "普通连接仍排队原视觉反馈")
		_setup_board(board)
		_drop(step, board, 0, 0, 1)
		_expect_sound(_sound_for(group), "连续同色连接：" + group)
		_check(ABManager.dyes == 1, "同进程重复连接不重复染色")

		_reset(group)
		_setup_board(board, true)
		_drop(step, board, 0, 0, 1)
		_expect_sound(_sound_for(group), "直接满盆：" + group)
		_check( not board._beats.is_empty(), "满盆仍沿原收盆链")
		_check(board._connection_pending.is_empty(), "直接收盆不依赖双花视觉反馈")

	_reset("set2")
	_setup_board(board)
	_drop(step, board, 0, 0, 3)
	_expect_sound(&"juice_move", "空绳移动保留原音效")
	_check(ABManager.reads == 0 and ABManager.dyes == 0, "空绳移动不读取或染色")
	board.set_allow_root_swapping_enabled(true)
	_setup_board(board)
	_drop(step, board, 0, 0, 2)
	_expect_sound(&"juice_move", "根部交换保留原音效")
	_check(ABManager.reads == 0 and ABManager.dyes == 0, "根部交换不入池")
	board.set_allow_root_swapping_enabled(false)
	_setup_board(board)
	_drop(step, board, 0, 0, 2)
	_check(AudioManager.played.is_empty() and ABManager.dyes == 0, "异色失败不播放合并音效或染色")
	_setup_board(board)
	var cancelled: = JuiceDropContext.new(board, 0, 0, 1)
	cancelled.outcome = JuiceDropContext.Outcome.VALID
	cancelled.handled = true
	step.run(cancelled)
	_check(AudioManager.played.is_empty() and ABManager.dyes == 0, "取消松手不补播或染色")
	_setup_board(board)
	board.try_move(0, 0, 1)
	_expect_sound(&"juice_move", "直接try_move沿原音效")
	_check(ABManager.dyes == 0, "try_move不入池")
	_setup_board(board)
	board.tutorial_demo_only = true
	_drop(step, board, 0, 0, 1)
	_check(AudioManager.played.is_empty() and ABManager.dyes == 0, "教学演示静默且不入池")
	board.tutorial_demo_only = false

	_setup_board(board)
	board.same_color_merge_sound_requested.disconnect(page._on_same_color_merge_sound_requested)
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"juice_move", "无页面订阅的独立盘面沿原音效")
	board.same_color_merge_sound_requested.connect(page._on_same_color_merge_sound_requested)
	_reset("set1")
	_setup_board(board, false, 1)
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"juice_merge_set1", "同色连接保留原花色升调", 1.088)

	_reset("set1")
	_setup_board(board)
	UserState.set_sfx_enabled(false)
	_drop(step, board, 0, 0, 1)
	_check(AudioManager.played.is_empty() and ABManager.dyes == 1, "静音不播放但仍统一染色")
	UserState.set_sfx_enabled(true)
	_reset("set2")
	_setup_board(board)
	ABManager._is_init_done = false
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"juice_move", "SDK未就绪沿原音效")
	_check( not ABManager._same_color_flower_merge_sfx_dyed, "未就绪不消耗首次守卫")
	ABManager._is_init_done = true
	_setup_board(board)
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"juice_merge_set2", "SDK就绪后真实合并重取分组")
	_check(ABManager.dyes == 1, "后续合并补染色")

	_reset("set1")
	ABManager.already_dyed = true
	_setup_board(board)
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"juice_merge_set1", "SDK已染色读取固定组")
	_check(ABManager.reads == 1 and ABManager.dyes == 0, "已有染色记录只静默读")

	_reset("set1")
	var skin: = JuiceSkinDefinition.new()
	skin.sounds[&"juice_move"] = &"move_rejected"
	page._skin_resources = JuiceSkinResolver.new(skin, skin)
	_setup_board(board)
	_drop(step, board, 0, 0, 1)
	_expect_sound(&"move_rejected", "皮肤显式覆盖优先于实验fallback")
	page._skin_resources = null

	for field: String in ["_closed_task_id", "_challenge_task_id"]:
		var task_id: int = int(board.get(field))
		if task_id >= 0:
			WorkerThreadPool.wait_for_task_completion(task_id)
			board.set(field, -1)
	page.free()
	if _failures.is_empty():
		SortLogger.info("SAME_COLOR_MERGE_SFX_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check_config() -> void :
	for raw: Variant in ["default", "set1", "set2", "", "unknown", 1]:
		_reset(raw)
		var set1: bool = raw is String and raw == "set1"
		var set2: bool = raw is String and raw == "set2"
		var config: SameColorFlowerMergeSfxConfig = ABManager.same_color_flower_merge_sfx
		_check(config.group_count == 3 and config.version == "1.0.10", "三组与版本登记")
		_check(config.is_merge_sfx_set1_enabled() == set1, "SDK字符串set1映射")
		_check(config.is_merge_sfx_set2_enabled() == set2, "SDK字符串set2映射")
		_check(ABManager.int_reads == 0 and ABManager.dyes == 0, "懒读走字符串且不染色")
		ABManager.sdk_value = "set1" if set2 else "set2"
		config.peek_value()
		_check(config.is_merge_sfx_set1_enabled() == set1, "面板peek不改业务缓存")
		_check(config.is_merge_sfx_set2_enabled() == set2, "面板peek不改set2缓存")
	for status: String in ["invalid", "unknown", ""]:
		_reset("set1")
		ABManager.sdk_status = status
		_check( not ABManager.same_color_flower_merge_sfx.is_merge_sfx_set1_enabled(), "SDK未命中不启用")
	_reset("set2")
	ABManager._startup_control_locked = true
	for override: int in [0, 1, 2, 9]:
		UserState.set_debug_ab_override(KEY, override)
		_check(ABManager.same_color_flower_merge_sfx.is_merge_sfx_set1_enabled() == (override == 1), "Cheat优先与非法覆盖set1")
		_check(ABManager.same_color_flower_merge_sfx.is_merge_sfx_set2_enabled() == (override == 2), "Cheat优先与非法覆盖set2")
	UserState.clear_debug_ab_override(KEY)
	ABManager.dye_at_same_color_flower_merge_sfx()
	_check( not ABManager.same_color_flower_merge_sfx.is_merge_sfx_set2_enabled() and ABManager.dyes == 0, "启动锁定不切组或染色")
	ABManager._startup_control_locked = false
	_reset("set2")
	ABManager.same_color_flower_merge_sfx.load_value_silent()
	_check(ABManager.same_color_flower_merge_sfx.value() == 2 and ABManager.dyes == 0, "静默读取统一字符串钩子")


func _reset(raw: Variant) -> void :
	UserState.clear_debug_ab_override(KEY)
	ABManager.same_color_flower_merge_sfx = SameColorFlowerMergeSfxConfig.new()
	ABManager.same_color_flower_merge_sfx.init_default()
	ABManager._configs_by_key[KEY] = ABManager.same_color_flower_merge_sfx
	ABManager._same_color_flower_merge_sfx_dyed = false
	ABManager._startup_control_locked = false
	ABManager._is_init_done = true
	ABManager.sdk_value = raw
	ABManager.sdk_status = "valid"
	ABManager.already_dyed = false
	ABManager.reads = 0
	ABManager.int_reads = 0
	ABManager.dyes = 0
	ABManager.events.clear()
	AudioManager.played.clear()


func _setup_board(board: JuiceBoardView, full: bool = false, color: int = 0) -> void :
	board.setup(JuiceLevel.from_dict({"id": 98121, "capacity": 4, "targetCups": 3, 
		"initial": ["-|%d" % color, "%d|%s" % [color, "%d,%d,%d" % [color, color, color] if full else str(color)], 
			"1|1" if color == 0 else "0|0", "2|"], "incoming": []}))
	AudioManager.played.clear()


func _drop(step: ValidDropStep, board: JuiceBoardView, src: int, j: int, dst: int) -> void :
	var ctx: = JuiceDropContext.new(board, src, j, dst)
	ctx.root_swapped = JuiceRules.is_root_swap(board.state(), src, j, dst)
	ctx.outcome = JuiceDropContext.Outcome.VALID
	step.run(ctx)


func _sound_for(group: String) -> StringName:
	return &"juice_merge_set1" if group == "set1" else (&"juice_merge_set2" if group == "set2" else &"juice_move")


func _expect_sound(id: StringName, message: String, pitch: float = 1.0) -> void :
	_check(AudioManager.played.size() == 1, message + "只派发一次")
	if AudioManager.played.size() == 1:
		var sound: Dictionary = AudioManager.played[0]
		_check(sound.id == id and is_equal_approx(sound.volume, 1.0) and is_equal_approx(sound.pitch, pitch), message + "原参数与音效ID")
	SortLogger.info("[MergeSfxTest] " + message)


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error(message)
