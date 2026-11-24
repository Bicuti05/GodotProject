extends SceneTree


var _failures: Array[String] = []
var _checks: int = 0
var _board_scene: PackedScene
var _flower: Texture2D

func _initialize() -> void :
	call_deferred("_run")

func _check(ok: bool, message: String) -> void :
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error(message)

func _verify_default() -> void :
	_check(ABManager.find_config("locked_column_wood") == null, "木门实验已注销")
	var level: JuiceLevel = _level()
	level.board_locks[1] = {"condition": "collect_count", "count": 2}
	var saved_ready: bool = ABManager._is_init_done
	var saved_locked: bool = ABManager._startup_control_locked
	for state: Array in [[false, false], [true, false], [true, true]]:
		ABManager._is_init_done = state[0]
		ABManager._startup_control_locked = state[1]
		for old_override: int in [0, 1, 99]:
			UserState.set_debug_ab_override("locked_column_wood", old_override)
			var board: JuiceBoardView = _new_board(level)
			_check(board.resolved_lock_visual_version() == 3, "SDK未就绪/就绪/启动锁定及旧覆盖均默认木门")
			var before: Dictionary = board.snapshot().duplicate(true)
			_check(board.restore(level, before) and board.resolved_lock_visual_version() == 3, "续局恢复默认木门")
			board.setup(level)
			_check(board.resolved_lock_visual_version() == 3, "重开默认木门")
			_free_board(board)
	UserState.clear_debug_ab_override("locked_column_wood")
	ABManager._is_init_done = saved_ready
	ABManager._startup_control_locked = saved_locked

func _level(capacity: int = 4, columns: int = 4) -> JuiceLevel:
	var initial: Array[String] = []
	for ci: int in columns:
		var flowers: Array[String] = []
		for j: int in capacity:
			flowers.append(str((ci + j) % columns))
		initial.append("%d|%s" % [ci, ",".join(flowers)])
	return JuiceLevel.from_dict({"id": 6, "capacity": capacity, "targetCups": columns, 
		"initial": initial, "incoming": []})

func _new_board(level: JuiceLevel, width: float = 1080.0) -> JuiceBoardView:
	var board: JuiceBoardView = _board_scene.instantiate() as JuiceBoardView
	board.anchor_right = 0.0
	board.anchor_bottom = 0.0
	root.add_child(board)
	board.size = Vector2(width, 1624.0 if level.layout_rows == 2 else 1352.0)
	board.set_ambient_sway_enabled(false)
	board.setup(level)
	board._cancel_closed_check()
	board.set_process(false)
	return board

func _free_board(board: JuiceBoardView) -> void :
	board.set_process(false)
	board._cancel_closed_check()
	for field: String in ["_death_task_id", "_safe_task_id", "_challenge_task_id", "_lucky_task_id"]:
		var task: int = int(board.get(field))
		if task >= 0:
			WorkerThreadPool.wait_for_task_completion(task)
			board.set(field, -1)
	board.free()


func _verify_layout() -> void :
	for width: float in [1080.0, 1755.0]:
		for rows: int in [1, 2]:
			for capacity: int in ([3, 4, 5, 6, 7, 8, 9] if rows == 1 else [4]):
				var lv: JuiceLevel = _level(capacity, 10 if rows == 2 else 4)
				lv.layout_rows = rows
				lv.layout_columns = 5 if rows == 2 else 0
				lv.board_locks[1] = {"condition": "collect_count", "count": 3}
				var flower_col: int = 6 if rows == 2 else 2
				lv.board_locks[flower_col] = {"condition": "collect_type", "count": 1, "typeId": 0}
				var board: JuiceBoardView = _new_board(lv, width)
				var before: Dictionary = board.snapshot().duplicate(true)
				for overlay: JuiceLockOverlay in board._lock_overlay_live:
					var door: WoodDoorLock = overlay.wood_door_view()
					var rect: Rect2 = board._lock_column_rect(int(board._slot_of[overlay.col]))
					_check(door != null and overlay.uses_wood_door(), "各布局木门显示")
					_check(is_equal_approx(door.size.y, rect.size.y) and door.size.x <= rect.size.x + 0.01, "木门列高/可用列宽适配")
					_check(is_equal_approx(overlay.position.x + door.position.x + door.size.x * 0.5, board._col_x(overlay.col)), "木门水平居中")
					var lock_transform: Transform2D = door._art.transform * door._lock.transform
					_check(is_equal_approx(lock_transform.x.length(), lock_transform.y.length()), "锁扣花数字等比")
					if overlay.col == flower_col:
						_check(door.condition_texture() == board.fruit_texture(0) and door._condition.visible and not door._count.visible, "目标花朵沿用本局配色")
					else:
						_check(door.remaining_count() == 3 and door._count.text == "3" and not door._condition.visible, "数字锁初值")
					var guide_scene: PackedScene = load("res://scripts/gameplay/juice_sort/tutorial/juice_lock_guide_overlay.tscn")
					var guide: JuiceLockGuideOverlay = guide_scene.instantiate() as JuiceLockGuideOverlay
					root.add_child(guide)
					guide.open(board.locked_column_global_rect(overlay.col), "collect_type" if overlay.col == flower_col else "collect_count", 3, 
						board.fruit_texture(0), board.resolved_lock_visual_version(), board.locked_column_width_ratio(overlay.col))
					var guide_door: WoodDoorLock = guide._lock_art.wood_door_view()
					_check(guide_door.size.is_equal_approx(door.size) and guide_door.global_position.is_equal_approx(door.global_position), "引导木门与真身尺寸位置一致")
					guide.close(true)
					guide.free()
				JuiceBoardView.set_lock_visual_version(1)
				_check(board.resolved_lock_visual_version() == 1, "原版调试覆盖")
				for overlay: JuiceLockOverlay in board._lock_overlay_live:
					_check( not overlay.uses_wood_door() and overlay._vine0.visible, "恢复原藤蔓")
					_check(is_equal_approx(overlay.size.x, 200.0 * board._lay.fruit_d / 230.0), "原版几何不变")
				JuiceBoardView.set_lock_visual_version(3)
				_check(board.resolved_lock_visual_version() == 3, "木门调试覆盖")
				JuiceBoardView.set_lock_visual_version(0)
				_check(board.resolved_lock_visual_version() == 3 and board.snapshot() == before, "恢复默认木门且盘面存档不变")
				board._state["done"] = 1
				board._refresh_lock_overlays()
				for overlay: JuiceLockOverlay in board._lock_overlay_live:
					if overlay.col == 1:
						_check(overlay.wood_door_view()._count.text == "2", "计数按累计收盆递减")
				_check(board.restore(lv, before), "续局恢复合法")
				_check(board.resolved_lock_visual_version() == 3, "续局保持默认木门")
				board.setup(lv)
				for overlay: JuiceLockOverlay in board._lock_overlay_live:
					if overlay.col == 1:
						_check(overlay.wood_door_view()._count.text == "3", "重开计数归初值")
				_free_board(board)


func _verify_prop_clearance() -> void :
	for width: float in [1080.0, 1755.0]:
		for rows: int in [1, 2]:
			var lv: JuiceLevel = _level(6 if rows == 1 else 4, 6 if rows == 1 else 10)
			lv.layout_rows = rows
			lv.layout_columns = 5 if rows == 2 else 0
			var locked_col: int = 1 if rows == 1 else 6
			lv.board_locks[locked_col] = {"condition": "collect_count", "count": 3}
			var board: JuiceBoardView = _new_board(lv, width)
			if rows == 1:
				board.size.y = 1304.0
			var normal_size: Vector2 = board.size
			var normal_gap: float = board._lay.gap
			var row_pitch: float = board._lay.row_pitch
			var first_visible_y: float = board._lay.first_fruit_y\
			- board._lay.fruit_d * board._skin.fruit_visual_center_offset_y_ratio
			var row_offset: float = row_pitch if rows == 2 else 0.0
			var rope_bottom: float = board._lay.rope_bottom + row_offset

			board.set_wood_lock_bottom_limit(rope_bottom + 32.0)
			_check(is_equal_approx(board._lay.gap, normal_gap), "充足空间保持原行距")

			var bottom_limit: float = rope_bottom + board.WOOD_LOCK_BOTTOM_PADDING - 80.0
			var prop_top: float = board.global_position.y + bottom_limit + 24.0
			board.set_wood_lock_bottom_limit(bottom_limit)
			_check(board.size == normal_size and board._lay.row_pitch == row_pitch, "避让不移动货架或改变盘面框")
			_check(board._lay.gap < normal_gap, "空间不足时收紧行距")
			_check(is_equal_approx(board._lay.first_fruit_y\
			- board._lay.fruit_d * board._skin.fruit_visual_center_offset_y_ratio, first_visible_y), "首花可见中心不移动")
			_check(board._lay.fruit_d <= board._lay.gap * JuiceLayout.FRUIT_VERTICAL_OVERLAP_MAX + 0.01, "收紧后花朵仍遵守重叠上限")
			var overlay: JuiceLockOverlay = board._lock_overlay_live[0]
			var door: WoodDoorLock = overlay.wood_door_view()
			_check(door.get_global_rect().end.y <= prop_top - 24.0 + 0.01, "木门与道具可见上沿至少相隔24px")
			var last_fruit: Vector2 = board._home_pos(locked_col, lv.capacity - 1)
			_check(last_fruit.y + board._lay.fruit_d * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO * 0.5\
			<= overlay.position.y + door.size.y, "末朵花的可见主体仍在门内")
			var saved: Dictionary = board.snapshot().duplicate(true)
			var gap: float = board._lay.gap
			JuiceBoardView.set_lock_visual_version(1)
			_check(is_equal_approx(board._lay.gap, normal_gap), "原藤蔓调试覆盖不收紧木门行距")
			JuiceBoardView.set_lock_visual_version(0)
			_check(is_equal_approx(board._lay.gap, gap) and board.snapshot() == saved, "切回木门恢复避让且不改玩法状态")
			board._state["locks"][locked_col] = {}
			board._solve_layout()
			board._snap_all_home()
			_check(is_equal_approx(board._lay.gap, gap) and board._home_pos(locked_col, lv.capacity - 1).is_equal_approx(last_fruit), "解锁后花位和行距不跳变")
			_check(board.restore(lv, saved) and is_equal_approx(board._lay.gap, gap), "续局保留相同避让几何")
			board.setup(lv)
			_check(is_equal_approx(board._lay.gap, gap), "重开保持相同避让几何")
			board.set_wood_lock_bottom_limit(INF)
			_check(is_equal_approx(board._lay.gap, normal_gap), "清除边界恢复原布局，INF不会误判为相同值")
			board.set_wood_lock_bottom_limit(bottom_limit)
			lv.board_locks[locked_col] = {}
			board.setup(lv)
			_check(is_equal_approx(board._lay.gap, normal_gap), "缓存盘面切到无锁关时不沿用木门压缩")
			_free_board(board)

	var incoming_level: JuiceLevel = JuiceLevel.from_dict({"id": 7, "capacity": 2, "targetCups": 4, 
		"initial": ["0|0,1", "1|1,2", "2|2,0"], 
		"incoming": [{"column": "0|0,0", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 3}}]})
	_check(incoming_level.validate().is_empty(), "补入锁资格使用合法题面")
	var incoming_board: JuiceBoardView = _new_board(incoming_level)
	_check(incoming_board._wood_lock_layout, "只有补入列带锁时也在起局冻结避让资格")
	var incoming_gap: float = incoming_board._lay.gap
	incoming_board.set_wood_lock_bottom_limit(incoming_board._lay.rope_bottom - 32.0)
	_check(incoming_board._lay.gap < incoming_gap, "补入锁出现之前已经避让，不随补列突变")
	_free_board(incoming_board)

func _verify_progress_restore() -> void :
	var lv: JuiceLevel = JuiceLevel.from_dict({"id": 9002, "capacity": 2, "targetCups": 3, 
		"initial": ["-|", "0|0", {"column": "1|1,1", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 2}}, "2|2,0"], 
		"incoming": ["-|2"]})
	var board: JuiceBoardView = _new_board(lv)
	var rec: Dictionary = JuiceRules.apply_move(board._state, lv, 3, 1, 1)
	_check( not rec.is_empty() and int(board._state["done"]) == 1, "真实收盆产生完整进度")
	board._refresh_lock_overlays()
	_check(board._lock_overlay_live[0].wood_door_view()._count.text == "1", "真实收盆后木门计数递减")
	var saved: Dictionary = board.snapshot().duplicate(true)
	_check(board.restore(lv, saved), "真实中途快照可续局")
	_check(board._lock_overlay_live[0].wood_door_view()._count.text == "1", "续局保留剩余计数")
	JuiceRules.undo_move(board._state, rec)
	board._refresh_lock_overlays()
	_check(board._lock_overlay_live[0].wood_door_view()._count.text == "2", "撤销恢复锁计数")
	_free_board(board)


func _verify_short_door() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/wood_door_lock.tscn")
	var door: WoodDoorLock = scene.instantiate() as WoodDoorLock
	root.add_child(door)
	door.configure(Vector2(170, 100), _flower)
	var t: Transform2D = door._art.transform * door._lock.transform
	var bounds: Rect2 = t * Rect2( - door.LOCK_PIVOT, door.LOCK_SIZE)
	_check(bounds.position.y >= -0.01 and bounds.end.y <= door.size.y + 0.01, "极短列仍完整容纳锁体")
	_check(is_equal_approx(t.x.length(), t.y.length()), "极短列不压扁花朵和数字")
	door.free()

func _verify_lifecycle() -> void :
	var level: JuiceLevel = _level()
	level.board_locks[1] = {"condition": "collect_count", "count": 3}
	var board: JuiceBoardView = _new_board(level)
	board._play_lock_unlock_effects([{"col": 1}])
	_check(board._wood_unlock_live.size() == 1 and board._unlock_leaf_pool.is_empty(), "木门解锁走独立CPU动效")
	var effect: WoodDoorLock = board._wood_unlock_live[0]
	board._clear_wood_unlock_effects()
	var cancelled_geometry: Array[Dictionary] = effect._fragments
	await process_frame
	_check( not effect.visible and not effect.is_processing() and effect._fragments == cancelled_geometry, "准备中取消不发布旧几何")
	board._play_lock_unlock_effects([{"col": 1}])
	if effect._fragments.is_empty():
		_check( not effect.is_processing() and effect._time == 0.0, "几何准备完成前不启动时间线，避免锁中途等待")
	var frames: int = 0
	while effect._fragments.is_empty() and frames < 120:
		await process_frame
		frames += 1
	_check( not effect._fragments.is_empty(), "取消后复用可正常准备")
	_check(is_equal_approx(effect.SHATTER_BREAK_TIME, 0.46)\
	and is_equal_approx(effect.SHATTER_FINISH_TIME, 1.91), "短预摆与门板回摆交叠，迸裂后保留碎块尾段")
	effect._time = effect.SHATTER_LOCK_FALL_TIME
	var release_pose: Vector4 = effect._shatter_lock_pose(effect._time)
	_check(is_equal_approx(release_pose.y, -12.0) and is_equal_approx(release_pose.z, 11.0)\
	and is_equal_approx(release_pose.w, 1.0), "锁小幅侧甩弹起，保持尺寸，不作整圈预翻转")
	effect._time = effect.SHATTER_BREAK_TIME
	var impact_lock_pose: Vector4 = effect._shatter_lock_pose(effect._time)
	_check(impact_lock_pose.x > release_pose.x and impact_lock_pose.y > 0.0\
	and impact_lock_pose.z > release_pose.z and impact_lock_pose.z < 90.0, 
		"锁在下落途中触发破碎，前段旋转保持克制")
	var preceding_pose: Vector4 = effect._shatter_lock_pose(effect.SHATTER_BREAK_TIME - 1e-05)
	var following_pose: Vector4 = effect._shatter_lock_pose(effect.SHATTER_BREAK_TIME + 1e-05)
	_check(preceding_pose.distance_to(impact_lock_pose) < 0.1 and following_pose.distance_to(impact_lock_pose) < 0.1, 
		"迸裂前后锁轨迹连续，不停住或回正")
	var preceding_release: Vector4 = effect._shatter_lock_pose(effect.SHATTER_LOCK_FALL_TIME - 1e-05)
	var following_release: Vector4 = effect._shatter_lock_pose(effect.SHATTER_LOCK_FALL_TIME + 1e-05)
	var incoming_velocity: Vector4 = (release_pose - preceding_release) / 1e-05
	var outgoing_velocity: Vector4 = (following_release - release_pose) / 1e-05
	_check(incoming_velocity.distance_to(outgoing_velocity) < 1.0, "锁弹起与重力下落共用释放速度，无中途悬停")
	var impulse_time: float = effect.SHATTER_HORIZONTAL_IMPULSE_TIME * effect.SHATTER_FALL_TIME_SCALE
	var impulse_travel: float = effect._fragment_horizontal_travel(impulse_time, 0.75)
	var preceding_travel: float = effect._fragment_horizontal_travel(impulse_time - 0.001, 0.75)
	var following_travel: float = effect._fragment_horizontal_travel(impulse_time + 0.001, 0.75)
	_check(absf((impulse_travel - preceding_travel) - (following_travel - impulse_travel)) < 1e-05, 
		"木块外冲转入收势时速度连续，无停顿或瞬移")
	_check(effect._fragment_horizontal_travel(0.5, 0.75) < (1.0 - exp(-0.75 * 0.5)) / 0.75, 
		"主冲击后横向余势收紧，不长时间平移滑行")
	var leading_count: int = 0
	for fragment: Dictionary in effect._fragments:
		_check(float(fragment["delay"]) <= 0.038, "碎块集中释放且保留错峰层次")
		if bool(fragment["frame_piece"]):
			_check(float(fragment["delay"]) >= 0.018 and float(fragment["delay"]) <= 0.031, 
				"门框紧接门板主冲击释放，不增加第二段等待")
		if not bool(fragment["splinter"]) and not bool(fragment["frame_piece"]) and float(fragment["delay"]) == 0.0:
			leading_count += 1
			_check(float(fragment["hinge_time"]) == 0.0, "领头木块不在破碎后短挂等待")
		var fade_end: float = float(fragment["delay"]) + float(fragment["fade_start"]) + float(fragment["fade_duration"])
		_check(fade_end < effect.SHATTER_FINISH_TIME - effect.SHATTER_BREAK_TIME, "碎块淡出完成后才回池")
	_check(leading_count >= 4, "至少四块锁心木块在破碎首帧立即运动")
	effect._time = effect.SHATTER_CRACK_TIME - 0.015
	effect._apply_time()
	_check(effect._art.position.length_squared() > 0.0 and not effect._fragment_surface.visible, "破碎前门板轻抖但保持闭合")
	effect._time = 0.0
	effect._process(effect.SHATTER_BREAK_TIME - 0.01)
	_check(effect._angles.is_equal_approx(Vector2.ZERO) and not effect._fragment_surface.visible, "开锁时双门保持闭合")
	effect._time = effect.SHATTER_BREAK_TIME
	effect._apply_time()
	var impact_door_transform: Transform2D = effect._art.transform
	_check(effect._art.scale.x / (effect.size.x / effect.DESIGN_SIZE.x) < 1.02, "门板蓄力保持小幅等比脉冲")
	effect._process(0.02)
	_check(effect._fragment_surface.visible and effect._lock.visible, "锁仍在掉落时显示碎块，不等待原锁完全淡出")
	_check(effect._art.transform.is_equal_approx(impact_door_transform), "碎块继承门板末帧姿态，迸裂时不回正跳变")
	var geometry: Array[Dictionary] = effect._fragments
	board.hide()
	_check( not effect.visible and not effect._fragment_surface.visible and board._wood_unlock_live.is_empty(), "离页立即清场")
	board.show()
	board._play_lock_unlock_effects([{"col": 1}])
	_check(effect._fragments == geometry and effect._time == 0.0, "重播复用几何并归零")
	effect._process(effect.SHATTER_FINISH_TIME)
	_check(board._wood_unlock_live.is_empty() and not effect.visible and not effect._fragment_surface.visible, "自然播放结束回池清场")
	board._play_lock_unlock_effects([{"col": 1}])
	JuiceBoardView.set_lock_visual_version(1)
	_check( not effect.visible and not effect._fragment_surface.visible, "切换调试样式取消动效")
	JuiceBoardView.set_lock_visual_version(0)
	board._play_lock_unlock_effects([{"col": 1}])
	board.setup(level)
	_check(board._wood_unlock_live.is_empty() and not effect.visible, "重开清场")
	_free_board(board)

func _verify_unlock_column_reuse() -> void :
	for stage: String in ["preparing", "closed", "shattered"]:
		var level: JuiceLevel = JuiceLevel.from_dict({"id": 9004, "capacity": 2, "targetCups": 4, 
			"initial": ["-|", "0|0", {"column": "1|1,1", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_count", "count": 1}}, "2|2,0"], 
			"incoming": ["-|2", {"column": "1|1,1", "columnType": "unlock", 
				"columnInfo": {"condition": "collect_count", "count": 3}}]})
		_check(level.validate().is_empty(), "串列回归题面合法 " + stage)
		var board: JuiceBoardView = _new_board(level)
		var old_token: int = int(board._visual_token_by_col[2])
		var unlocked: bool = board.try_move(3, 1, 1)
		_check(unlocked and not JuiceRules.is_locked(board._state, 2)
			and board._wood_unlock_live.size() == 1, "第一盆解锁木门A " + stage)
		if not unlocked or board._wood_unlock_live.size() != 1:
			_free_board(board)
			continue
		var effect: WoodDoorLock = board._wood_unlock_live[0]
		_check(int(board._wood_unlock_tokens.get(effect, -1)) == old_token, "起播绑定A的视觉列 " + stage)
		if stage != "preparing":
			var frames: int = 0
			while effect._fragments.is_empty() and frames < 120:
				await process_frame
				frames += 1
			_check( not effect._fragments.is_empty(), "串列回归几何准备完成 " + stage)
			effect.set_process(false)
			effect._time = effect.SHATTER_BREAK_TIME * 0.5 if stage == "closed" else effect.SHATTER_BREAK_TIME + 0.08
			effect._apply_time()
			_check(effect._fragment_surface.visible == (stage == "shattered"), "收盆前处于指定阶段 " + stage)
		var collected: bool = board.try_move(3, 0, 0)
		_check(collected and int(board._state["done"]) == 2, "动效结束前收走A " + stage)
		var new_token: int = int(board._visual_token_by_col.get(2, -1))
		_check(new_token >= 0 and new_token != old_token and JuiceRules.is_locked(board._state, 2), 
			"同列号补入独立且仍锁定的B " + stage)
		_check(board._wood_unlock_live.is_empty() and not effect.visible
			and not effect._fragment_surface.visible and not effect.is_processing(), "收盆当帧停止A及碎块 " + stage)
		_check( not board._wood_unlock_tokens.has(effect) and not board._wood_unlock_offsets.has(effect), 
			"回池清除旧列身份与位置绑定 " + stage)
		var replacement_door: WoodDoorLock = null
		for overlay: JuiceLockOverlay in board._lock_overlay_live:
			if overlay.col == 2:
				replacement_door = overlay.wood_door_view()
		_check(is_instance_valid(replacement_door) and replacement_door.visible
			and replacement_door._time == 0.0 and not replacement_door._shattering
			and not replacement_door._fragment_surface.visible, "B的木门保持关闭 " + stage)
		_check(JuiceRules.move_info(board._state, 2, 1, 0) == 0, "B未解锁时花朵不能移动 " + stage)
		await process_frame
		_check( not effect.visible and not effect.is_processing(), "旧异步准备不能恢复A " + stage)

		board._process(4.0)
		board._process(4.0)
		var placed: bool = board.try_move(0, 0, 3)
		var completed: bool = board.try_move(1, 0, 3) if placed else false
		_check(completed and int(board._state["done"]) == 3
			and not JuiceRules.is_locked(board._state, 2), "B满足自身条件后解锁 " + stage)
		_check(board._wood_unlock_live.size() == 1, "B只播放自己的解锁副本 " + stage)
		if board._wood_unlock_live.size() == 1:
			var replacement: WoodDoorLock = board._wood_unlock_live[0]
			_check(replacement == effect and replacement._time == 0.0
				and not replacement._fragment_surface.visible
				and int(board._wood_unlock_tokens.get(replacement, -1)) == new_token, 
				"池化副本绑定B并从头播放 " + stage)
		_free_board(board)


func _verify_unlock_token_guard() -> void :
	var level: JuiceLevel = _level()
	level.board_locks[1] = {"condition": "collect_count", "count": 3}
	level.board_locks[2] = {"condition": "collect_count", "count": 3}
	var board: JuiceBoardView = _new_board(level)
	board._play_lock_unlock_effects([{"col": 1}, {"col": 2}])
	_check(board._wood_unlock_live.size() == 2, "多列解锁副本分别起播")
	if board._wood_unlock_live.size() != 2:
		_free_board(board)
		return
	var first: WoodDoorLock = board._wood_unlock_live[0]
	var second: WoodDoorLock = board._wood_unlock_live[1]
	var second_x: float = second.position.x
	var second_token: int = int(board._visual_token_by_col[2])
	board._visual_x[second_token] = float(board._visual_x[second_token]) + 23.0
	board._update_wood_unlock_positions()
	_check(board._wood_unlock_live.size() == 2 and is_equal_approx(second.position.x, second_x + 23.0), 
		"身份不变时解锁副本正常随列横移")
	board._new_visual_token(1, board._col_x(1) + 50.0)
	board._update_wood_unlock_positions()
	_check( not first.visible and not first.is_processing() and board._wood_unlock_live == [second]
		and second.visible, "逐帧身份守卫只回收被替换列，不影响其他列")
	await process_frame
	_check( not first.visible and not first.is_processing(), "守卫取消后旧准备不恢复副本")
	_free_board(board)


func _run() -> void :
	_board_scene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn")
	_flower = load("res://assets/sprites/juice_sort/flower_purple.png")
	_verify_default()
	_verify_layout()
	_verify_prop_clearance()
	_verify_progress_restore()
	_verify_short_door()
	await _verify_lifecycle()
	await _verify_unlock_column_reuse()
	await _verify_unlock_token_guard()
	await process_frame
	print("LOCKED_COLUMN_WOOD_SELFTEST PASS %d checks" % _checks if _failures.is_empty() else "LOCKED_COLUMN_WOOD_SELFTEST FAIL: %s" % str(_failures))
	quit(0 if _failures.is_empty() else 1)
