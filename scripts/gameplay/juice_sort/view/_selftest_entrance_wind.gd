extends SceneTree


var _failures: Array[String] = []
var _checks: int = 0
var _oracle: PackedVector2Array = PackedVector2Array()
const ORACLE_STEP: float = 0.0005
const START_DX: float = 1458.0
const DURATION: float = 0.95


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	_checks += 1
	if not ok:
		_failures.append(label)
		print("FAIL: ", label)


func _run() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	var board: Variant = scene.instantiate()
	board.anchor_right = 0.0
	board.anchor_bottom = 0.0
	root.add_child(board)
	board.size = Vector2(1080.0, 1304.0)
	board.setup(JuiceLevel.from_dict({
		"id": 99202, "capacity": 4, "targetCups": 4, 
		"initial": ["-|0", "0|0,1,2", "1|1,2,0", "2|2,0,1"], 
		"incoming": ["x", "x", "x"], 
	}))
	board._cancel_closed_check()
	board.set_process(false)
	board.set_ambient_sway_enabled(false)
	var steady: float = _peak(board, false)
	var irregular: float = _peak(board, true)
	print("PEAK steady=%.3f irregular=%.3f" % [steady, irregular])
	_check(irregular <= steady * 1.02, "长短帧交替不能额外放大入场摆幅")
	_build_oracle(board._lay.rope_bottom - board._lay.hang_top)
	_check_profiles(board)
	_check_lifecycle(board)
	board.free()
	await _check_page()
	print("ENTRANCE_WIND_RESULT: %d checks, %d failures" % [_checks, _failures.size()])
	print("PASS" if _failures.is_empty() else "FAIL")
	quit(0 if _failures.is_empty() else 1)


func _peak(board: Variant, irregular: bool) -> float:
	board.set_content_offset_x(START_DX)
	board.begin_entrance_wind(START_DX, DURATION)
	var time: float = 0.0
	var peak: float = 0.0
	var span: float = board._lay.rope_bottom - board._lay.hang_top
	for i: int in 240:
		var delta: float = 1.0 / 30.0 if irregular and i % 2 == 1 else 1.0 / 60.0

		board.set_entrance_time(minf(time, DURATION))
		board._process(delta)
		peak = maxf(peak, absf(board._wind_amp) * span)
		time += delta
	board.end_entrance_wind()
	return peak



func _build_oracle(span: float) -> void :
	var amp: float = 0.0
	var vel: float = 0.0
	var q: float = START_DX * pow(PI / DURATION, 2.0) * 3.0 / (2.0 * span)
	_oracle.append(Vector2.ZERO)
	for i: int in 8000:
		var time: float = float(i) * ORACLE_STEP
		var driven: bool = time < DURATION
		var k1: Vector2 = _rhs(time, amp, vel, q, driven)
		var k2: Vector2 = _rhs(time + ORACLE_STEP * 0.5, 
			amp + k1.x * ORACLE_STEP * 0.5, vel + k1.y * ORACLE_STEP * 0.5, q, driven)
		var k3: Vector2 = _rhs(time + ORACLE_STEP * 0.5, 
			amp + k2.x * ORACLE_STEP * 0.5, vel + k2.y * ORACLE_STEP * 0.5, q, driven)
		var k4: Vector2 = _rhs(time + ORACLE_STEP, 
			amp + k3.x * ORACLE_STEP, vel + k3.y * ORACLE_STEP, q, driven)
		amp += ORACLE_STEP * (k1.x + 2.0 * k2.x + 2.0 * k3.x + k4.x) / 6.0
		vel += ORACLE_STEP * (k1.y + 2.0 * k2.y + 2.0 * k3.y + k4.y) / 6.0
		_oracle.append(Vector2(amp, vel))


func _rhs(time: float, amp: float, vel: float, q: float, driven: bool) -> Vector2:
	return Vector2(vel, -81.0 * amp - 8.1 * vel + (q * cos(PI * time / DURATION) if driven else 0.0))


func _oracle_at(time: float) -> Vector2:
	var index: float = time / ORACLE_STEP
	var left: int = clampi(floori(index), 0, _oracle.size() - 2)
	return _oracle[left].lerp(_oracle[left + 1], clampf(index - float(left), 0.0, 1.0))


func _check_profiles(board: Variant) -> void :
	var profiles: Dictionary = {
		"30fps": [1.0 / 30.0], "60fps": [1.0 / 60.0], "120fps": [1.0 / 120.0], 
		"交替长短帧": [1.0 / 60.0, 1.0 / 30.0], 
		"50ms长帧": [1.0 / 60.0, 0.05], "133ms长帧": [1.0 / 60.0, 0.133], 
		"417ms长帧": [1.0 / 60.0, 0.417], 
	}
	var span: float = board._lay.rope_bottom - board._lay.hang_top
	for label: String in profiles:
		board.begin_entrance_wind(START_DX, DURATION)
		var sequence: Array = profiles[label]
		var time: float = 0.0
		var peak: float = 0.0
		var max_error: float = 0.0
		var max_flower_error: float = 0.0
		var finite: bool = true
		var frame: int = 0

		while time < 4.0:
			var delta: float = float(sequence[frame % sequence.size()])

			board._process(delta)
			var state: Vector2 = _oracle_at(board._wind_time)
			if board._wind_active:
				max_error = maxf(max_error, absf(board._wind_amp - state.x) * span)
				max_error = maxf(max_error, absf(board._wind_vel - state.y) * span)
			finite = finite and is_finite(board._wind_amp) and is_finite(board._wind_vel)
			peak = maxf(peak, absf(board._wind_amp) * span)
			if board._wind_is_rigid():
				for ci: int in board._fruit_nodes:
					for flower: JuiceFruit in board._fruit_nodes[ci]:
						var expected: Vector2 = board._home_pos(ci, flower.idx)
						expected.x += board._wind_curve_dx(expected.y - board._row_y(ci))
						max_flower_error = maxf(max_flower_error, flower.position.distance_to(expected))
			if board.is_entrance_motion_active():
				var expected_dx: float = START_DX * (1.0 + cos(PI * board._wind_time / DURATION)) * 0.5
				_check(absf(board._content_dx - expected_dx) < 0.001, label + "位移和惯性使用同一采样时刻")
			else:
				_check(is_zero_approx(board._content_dx), label + "入场结束偏移为零")
			time += delta
			board.set_entrance_time(minf(time, DURATION))
			frame += 1
		_check(finite and peak < 307.0, label + "长帧下摆幅有界且无非有限值")
		_check(max_error < 0.05, label + "摆幅/摆速与独立RK4参照一致")
		_check(max_flower_error < 0.02, label + "刚性摆动期间花心贴绳")
		_check( not board.is_entrance_motion_active() and not board.is_entrance_wind_active(), 
			label + "正常收尾卸载 t=%.4f tail=%.4f speed=%.4f" % [board._wind_time, board._wind_amp * span, board._wind_vel * span])
		print("PROFILE %s peak=%.3f oracle_error=%.6f flower_error=%.6f" % [label, peak, max_error, max_flower_error])
		board.end_entrance_wind()


func _check_lifecycle(board: Variant) -> void :
	board.begin_entrance_wind(START_DX, DURATION)
	var before_end: Vector2 = board._entrance_wind_state(DURATION - 1e-06)
	var after_end: Vector2 = board._entrance_wind_state(DURATION + 1e-06)
	_check(before_end.distance_to(after_end) < 0.0001, "受迫摆与自由衰减交接摆幅和摆速连续")
	board._process(0.417)
	_check(board.is_entrance_wind_active() and board._wind_time == 0.0, "没有Tween样本时初态不卸载或自行推进")
	board.set_entrance_time(0.6)
	board.set_entrance_time(0.2)
	board._process(1.0 / 60.0)
	_check(is_equal_approx(board._wind_time, 0.6), "同帧提交的旧样本不能倒退时钟")
	board.set_entrance_time(DURATION)
	board.end_entrance_wind()
	var dx: float = board._content_dx
	board._process(0.417)
	_check( not board.is_entrance_motion_active() and board._wind_amp == 0.0
		and board._wind_vel == 0.0 and board._content_dx == dx, "取消清理待应用末样本和惯性")
	board.begin_entrance_wind(START_DX, DURATION)
	_check(board._wind_time == 0.0 and board._wind_amp == 0.0, "重入从静止初态开始")
	board.set_sway_enabled(false)
	board.set_entrance_time(DURATION)
	board._process(0.417)
	_check( not board.is_entrance_motion_active() and board._content_dx == 0.0
		and board._wind_amp == 0.0, "关闭微风总开关仍正常完成刚性横移")
	board.set_sway_enabled(true)
	board.begin_entrance_wind(START_DX, DURATION)
	board.set_entrance_time(0.4)
	board._process(1.0 / 60.0)
	board.setup(board.level())
	board._cancel_closed_check()
	_check( not board.is_entrance_motion_active() and not board._entrance_time_pending
		and board._wind_amp == 0.0, "重摆盘面清理旧入场")


func _play_page(page: Variant, result: Dictionary, key: String) -> void :
	await page.play_playfield_entrance()
	result[key] = true


func _drive_page(page: Variant, result: Dictionary, key: String) -> void :
	for i: int in 180:
		if result[key]:
			return
		var delta: float = 0.417 if i % 7 == 0 else 1.0 / 30.0
		page._board._process(delta)
		var tw: Tween = page._entrance_tween
		if tw != null and tw.is_valid():
			tw.pause()
			tw.custom_step(delta)
		await process_frame
	_check(bool(result[key]), key + "页面入场协程必须结束")


func _check_page() -> void :
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn")
	var page: Variant = scene.instantiate()
	root.add_child(page)
	page.set_process(false)
	_check_quota_entrance_layout(page)
	var board: Variant = page._board
	board.set_process(false)
	board.setup(JuiceLevel.from_dict({
		"id": 99203, "capacity": 4, "targetCups": 4, 
		"initial": ["-|0", "0|0,1,2", "1|1,2,0", "2|2,0,1"], 
		"incoming": ["x", "x", "x"], 
	}))
	board._cancel_closed_check()
	page.entrance_style = 0
	var result: Dictionary = {"first": false, "second": false, "cancel": false, "layout": false, "soft": false}
	_play_page(page, result, "first")
	var old_generation: int = page._entrance_generation
	var first_tw: Tween = page._entrance_tween
	first_tw.pause()
	first_tw.custom_step(0.35)
	_check(board._wind_time == 0.0 and not page._playfield_ready, "真实Tween只提交时间，不提前应用几何或放行")
	board._process(1.0 / 60.0)
	_check(is_equal_approx(board._wind_time, 0.35), "真实Tween样本在盘面下一次更新应用")
	var dx: float = board._content_dx
	page._layout()
	_check(board._content_dx == dx, "入场期间重算页面布局不覆盖盘面时钟位移")
	page._tutorial_active = true
	_play_page(page, result, "second")
	_check( not first_tw.is_valid() and not result.first, "重入杀旧Tween，旧协程不能提前宣告新入场结束")
	page._set_entrance_time(DURATION, old_generation)
	board._process(1.0 / 60.0)
	_check(board._wind_time == 0.0 and board._wind_amp == 0.0, "旧代次回调不能向新入场提交末样本")
	await _drive_page(page, result, "second")
	_check(page._playfield_ready and board._entrance_lock and not board.is_entrance_wind_strong(), "教学局等摆动结束仍保留引导安装锁")
	for i: int in 3:
		await process_frame
	_check(bool(result.first), "旧协程跟随接管者完成且不挂死")
	page._tutorial_active = false
	_play_page(page, result, "cancel")
	page._entrance_tween.pause()
	page._entrance_tween.custom_step(0.5)
	page._kill_entrance_tween()
	page._set_entrance_dx(0.0)
	page.visible = false
	for i: int in 4:
		board._process(0.417)
		await process_frame
	_check(bool(result.cancel) and not page._playfield_ready and board._entrance_lock
		and not board._entrance_time_pending, "离页取消不挂协程、不残留待应用时间、不解锁")
	page.visible = true
	_play_page(page, result, "layout")
	page._entrance_tween.pause()
	page._entrance_tween.custom_step(DURATION)
	board._process(1.0 / 60.0)
	page._layout()
	_check(board._content_dx == 0.0, "末样本应用后、页面协程收尾前刷新布局不能写回屏外偏移")
	await _drive_page(page, result, "layout")
	for style: int in [1]:
		page.entrance_style = style
		var key: String = "soft"
		_play_page(page, result, key)
		await _drive_page(page, result, key)
		_check(page._playfield_ready and not board._entrance_lock and board._content_dx == 0.0, 
			key + "保留正常入场、清零偏移和普通局放行")
	page._kill_entrance_tween()
	page.free()


func _check_quota_entrance_layout(page: Variant) -> void :
	var quota: JuiceQuotaBar = page._quota
	var viewport_center_x: float = UiMetrics.viewport_size().x * 0.5
	for iq_enabled: bool in [false, true]:
		quota.set_iq_layout_enabled(iq_enabled)
		for totals: Vector2i in [Vector2i(10, 6), Vector2i(3, 8)]:
			page._cancel_ui_entrance()
			quota.setup(totals.x)

			page._prepare_ui_entrance()
			quota.setup(totals.y)
			page._set_ui_entrance_time(0.12)
			_check(is_equal_approx(quota.get_global_rect().get_center().x, viewport_center_x), 
				"普通/IQ订单宽度变化后入场过程保持水平居中")
			page._set_ui_entrance_time(0.2999)
			var before_finish_x: float = quota.get_global_rect().get_center().x
			page._set_ui_entrance_time(0.3)
			var finished_transform: Transform2D = quota.get_global_transform()
			_check(is_equal_approx(quota.get_global_rect().get_center().x, before_finish_x), 
				"订单入场末帧不因恢复旧宽度支点横跳")
			page._cancel_ui_entrance()

			page._layout_quota()
			_check(quota.get_global_transform().is_equal_approx(finished_transform), 
				"重开订单重排不修正上一轮入场留下的偏移")
			page._prepare_ui_entrance()
			quota.setup(totals.x)
			page._set_ui_entrance_time(0.12)
			page._cancel_ui_entrance()
			_check(is_equal_approx(quota.get_global_rect().get_center().x, viewport_center_x), 
				"宽度变化后中途取消仍按当前订单支点归位")
			var cancelled_transform: Transform2D = quota.get_global_transform()
			page._prepare_ui_entrance()
			page._set_ui_entrance_time(JuiceGamePage.UI_ENTRANCE_DUR)
			page._cancel_ui_entrance()
			_check(quota.get_global_transform().is_equal_approx(cancelled_transform), 
				"页面复用再次入场不积累订单位移")
	quota.set_iq_layout_enabled(false)
