extends SceneTree


var _failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_board_view.tscn") as PackedScene
	var board: Variant = _new_board(scene)
	var original: Array = _all_flowers(board)
	var positions: Dictionary = {}
	for flower: JuiceFruit in original:
		positions[flower] = flower.global_position
	var events: Array[String] = []
	var synchronous: Dictionary = {"snapshot": {}, "deposits": []}
	board.moved.connect( func(_steps: int) -> void :
		events.append("moved")
		synchronous["snapshot"] = board.snapshot()
		synchronous["deposits"] = board.last_move_deposits()
	)
	board.cup_collected.connect( func(_type: int, _nth: int, _color: Color, _rect: Rect2) -> void :
		events.append("cup")
	)
	board.settled.connect( func() -> void : events.append("settled"))
	_check(board.complete_column_prop(), "混色盘面允许直接完成一列")
	_check(board.complete_column_fail_reason() == "", "成功后清空失败原因")
	_check(events == ["moved"], "同步结算不提前发收盆表现: %s" % str(events))
	_check(board.sync_error() == "", "同步结算后节点与状态一致: %s" % board.sync_error())
	_check(int(synchronous["snapshot"]["state"]["done"]) == 1, "moved 返回前可保存最终状态")
	_check((synchronous["deposits"] as Array).size() == 1, "同步链可读取真实收盆记录")
	_check((board.get("_history") as Array).is_empty(), "调配不伪造普通移动撤销历史")
	_check( not board.complete_column_prop() and not board.try_move(1, 0, 2), "飞行期间重复调配与直接移动被门控")
	_check(board.complete_column_fail_reason() == "flight", "飞行期间失败原因应为 flight")
	_check( not board._can_play() and board.is_busy(), "飞行阶段锁玩家输入并计入busy")
	for flower: JuiceFruit in original:
		_check(flower.global_position.distance_to(positions[flower]) < 0.01, "提交当帧不瞬移旧花")
		_check(flower.top_level, "飞行临时绕过盘面裁剪")
	var actual_flight_duration: float = float((board.get("_complete_column_flight") as Dictionary)["duration"])
	board._process(actual_flight_duration * 0.5)
	_check(events == ["moved"], "飞行中段不提前收盆")
	var changed: bool = false
	for flower: JuiceFruit in original:
		changed = changed or flower.global_position.distance_to(positions[flower]) > 1.0
	_check(changed, "真实原花节点在飞行，不是重建替换")
	board._process(actual_flight_duration * 0.5)
	_check((board.get("_complete_column_flight") as Dictionary).is_empty(), "有限时长飞行准确交接")
	_check(events == ["moved"], "交接帧才起收盆，不跳过表现")
	for flower: JuiceFruit in original:
		_check( not flower.top_level, "交接还原裁剪与层级")
	for _frame: int in 400:
		board._process(1.0 / 60.0)
	_check(events.count("cup") == 1 and events.count("settled") == 1, 
		"真实盆逐次交付且仅一次settled: %s" % str(events))
	_check(board.sync_error() == "" and not board.is_busy(), "动效收尾后盘面同步")
	_free_board(board)
	_check_staged_flight(scene)
	_check_motion_rhythm()
	_check_staged_cancellation(scene)
	await _check_particle_theme_and_reuse()


	board = _new_board(scene)
	board.set("_order", [1, 0, 2] as Array[int])
	board._reindex_slots()
	board._solve_layout()
	board._snap_all_home()

	var expected_type: int = int((board.state()["jars"] as Array)[1])
	_check(board.complete_column_prop(), "按修改后的屏幕顺序选择目标")
	_check(int((board.state()["cups"] as Array)[0]) == expected_type, "选择屏幕第一列而非列号第一列")
	board._process(10.0)
	_check( not (board.get("_beats") as Array).is_empty()
		and not bool((board.get("_beats") as Array)[0]["cup_sent"]), "长帧交接保留完整收盆表现")
	_free_board(board)


	board = _new_board(scene)
	var cancelled: Array[String] = []
	board.cup_collected.connect( func(_type: int, _nth: int, _color: Color, _rect: Rect2) -> void :
		cancelled.append("cup")
	)
	_check(board.complete_column_prop(), "重开测试调配成功")
	board._process(0.2)
	board.setup(_level())
	_check((board.get("_complete_column_flight") as Dictionary).is_empty(), "重开清理飞行引用")
	for _frame: int in 100:
		board._process(0.02)
	_check(cancelled.is_empty() and int(board.state()["done"]) == 0, "重开不交付旧盆")
	for flower: JuiceFruit in _all_flowers(board):
		_check( not flower.top_level and flower.z_index == 0, "池化复用不残留top_level")
	_free_board(board)



	board = _new_board(scene)
	_check(board.cheat_prepare_last_cup(), "准备合法末盆状态")
	var win_events: Array[String] = []
	board.moved.connect( func(_steps: int) -> void : win_events.append("moved"))
	board.cup_collected.connect( func(_type: int, _nth: int, _color: Color, _rect: Rect2) -> void :
		win_events.append("cup")
	)
	board.won.connect( func() -> void : win_events.append("won"))
	var accepted: bool = board.complete_column_prop()
	_check(accepted and board.over() == "win", "末盆同步判胜")
	_check(win_events == ["moved"], "末盆不提前发won")
	for _frame: int in 400:
		board._process(1.0 / 60.0)
	_check(win_events == ["moved", "cup", "won"], "先落盘、再交盆、最后won: %s" % str(win_events))
	_free_board(board)

	var dead_board: Variant = _new_board(scene)
	dead_board.set("_over", "dead")
	_check(dead_board.complete_column_prop(), "死局允许使用完成一列道具")
	_check(dead_board.over() == "", "成功后解除死局态")
	_free_board(dead_board)

	var blocked_board: Variant = _new_board(scene, {"id": 98972, "capacity": 2, 
		"targetCups": 2, "initial": ["0|1", "2|3", "-|4"], "incoming": ["x", "x"]})
	blocked_board.set("_over", "dead")
	_check( not blocked_board.complete_column_prop(), "没有可完成列时入口返回失败")
	_check(blocked_board.complete_column_fail_reason() == "no_column", 
		"无可用列时失败原因应为 no_column")
	_check(blocked_board.over() == "dead", "失败后还原死局态")
	_free_board(blocked_board)

	board = _new_board(scene, {"id": 98973, "capacity": 3, "targetCups": 2, 
		"initial": ["0|", "1|0,0", "1|?0,?0,2"], "incoming": ["2|2,2,3"]})
	_check(board.complete_column_prop(), "问号散在其它列时道具应成功凑满")
	_check_reveal_then_fly(board, "其它列问号")
	var hidden_left: int = 0
	for col: Array in (board.state()["cols"] as Array):
		for value: Variant in col:
			if JuiceLevel.is_hidden(int(value)):
				hidden_left += 1
	_check(hidden_left == 1, "只揭凑满所需的问号，其余问号保持问号")
	_free_board(board)

	board = _new_board(scene, {"id": 98974, "capacity": 3, "targetCups": 2, 
		"initial": ["0|?0", "1|0,0", "1|?0,2"], "incoming": ["2|2,2,3"]})
	_check(board.complete_column_prop(), "同色问号在目标列内时道具应成功凑满")
	_check_reveal_then_fly(board, "目标列内问号")
	_free_board(board)

	board = _new_board(scene, {"id": 98975, "capacity": 3, "targetCups": 2, 
		"initial": ["0|", "1|0,0", "1|?0,0"], "incoming": ["2|2,2,3"]})
	_check(board.complete_column_prop(), "明牌足够时道具应直接凑满")
	var tail_hidden: Variant = _find_hidden(board)
	_check(tail_hidden != null, "题面应保留一朵落到绳尾的问号")
	var plain_flight: Dictionary = board.get("_complete_column_flight") as Dictionary
	_check(float(plain_flight.get("delay", 0.0)) == 0.0, "明牌足够时不得等待揭问号")
	board._process(board.COMPLETE_COLUMN_FLY_DUR * 0.5)
	_check(is_instance_valid(tail_hidden)
		and (tail_hidden as JuiceFruit).fruit_type == JuiceLevel.hide_type(0), 
		"跳列期间绳尾问号不得提前揭示")
	_advance_flight_to(board, float(plain_flight["duration"]))
	for _frame: int in 400:
		board._process(1.0 / 60.0)
	_check(is_instance_valid(tail_hidden) and (tail_hidden as JuiceFruit).fruit_type == 0, 
		"收盆之后才揭示落到绳尾的问号")
	_check(board.sync_error() == "" and not board.is_busy(), "延时显色收尾后盘面同步")
	_free_board(board)


	board = _new_board(scene, {"id": 98977, "capacity": 3, "targetCups": 5, 
		"initial": ["0|1,0", "1|1,0", {"column": "0|0,0,0", "columnType": "unlock", 
			"columnInfo": {"condition": "collect_count", "count": 4}}, "-|1,0"], 
		"incoming": ["1|1,1,1", "1|1,1,1"]})
	var locked_ci: int = _locked_col(board)
	_check(locked_ci >= 0, "锁列用例的盘面必须存在锁列")
	var locked_col: Array = ((board.state()["cols"] as Array)[locked_ci] as Array).duplicate()
	var locked_nodes: Array = ((board.get("_fruit_nodes") as Dictionary)[locked_ci] as Array).duplicate()
	var locked_positions: Dictionary = {}
	for node: JuiceFruit in locked_nodes:
		locked_positions[node] = node.global_position
	_check(board.complete_column_prop(), "未锁列够用时道具应成功")
	_check((board.state()["cols"] as Array)[locked_ci] == locked_col, 
		"成功时锁列花不得被抽走或重排: %s" % str((board.state()["cols"] as Array)[locked_ci]))
	_check( not (board.state()["locks"] as Array)[locked_ci].is_empty(), "锁条件未满足前不得解锁")
	_check(_same_nodes(locked_nodes, 
		(board.get("_fruit_nodes") as Dictionary)[locked_ci] as Array), 
		"成功时锁列节点身份不得变化")

	var flight: Dictionary = board.get("_complete_column_flight") as Dictionary
	var entry_dst: Dictionary = {}
	for entry: Dictionary in (flight.get("entries", []) as Array):
		var entry_node: JuiceFruit = entry["node"]
		_check( not entry_dst.has(entry_node), "同一朵花不得重复进入汇花飞行")
		entry_dst[entry_node] = entry["dst_pos"]
	for node: JuiceFruit in locked_nodes:
		_check( not entry_dst.has(node), "锁列花不得进入汇花飞行")
		_check( not node.top_level and node.z_index == 0, "锁列花不得被抬到遮挡物之上")

	_check( not (board.get("_beats") as Array).is_empty(), "锁列用例必须产生真实收盆拍")
	for beat: Dictionary in (board.get("_beats") as Array):
		var beat_nodes: Array = beat.get("nodes", []) as Array
		for i: int in beat_nodes.size():
			var beat_node: JuiceFruit = beat_nodes[i]
			if not entry_dst.has(beat_node):
				continue
			var dst: Vector2 = entry_dst[beat_node]
			_check(is_equal_approx(dst.x, float(beat["ghost_x"]))
				and is_equal_approx(dst.y, board._lay.fruit_y(i) + float(beat["row_y"])), 
				"收走的花只能飞向本列收集位，不能落到别的列")
	board._process(board.COMPLETE_COLUMN_FLY_DUR * 0.5)
	for node: JuiceFruit in locked_nodes:
		if is_instance_valid(node):
			_check(node.global_position.distance_to(locked_positions[node]) < 1.0, 
				"跳列期间锁列花不得移动: %s"
					%str(node.global_position - locked_positions[node]))
	for _frame: int in 400:
		board._process(1.0 / 60.0)
	_check((board.state()["cols"] as Array)[locked_ci] == locked_col, 
		"收盆补位后锁列花不得变化")
	_check(board.sync_error() == "" and not board.is_busy(), "锁列用例收尾后盘面同步")
	_free_board(board)
	if _failures.is_empty():
		SortLogger.info("COMPLETE_COLUMN_VIEW_SELFTEST PASS")
		quit(0)
	else:
		for message: String in _failures:
			SortLogger.error("COMPLETE_COLUMN_VIEW_SELFTEST FAIL: " + message)
		quit(1)


func _check_staged_flight(scene: PackedScene) -> void :
	for mirrored: bool in [false, true]:
		seed(98976)
		var board: Variant = _new_board(scene, {"id": 98976, "capacity": 4, "targetCups": 2, 
			"initial": ["0|1,0,2", "1|0,3,0", "2|0,2,1", "-|3,1"], "incoming": ["x", "x"]})
		if mirrored:
			board._order.reverse()
			board._reindex_slots()
			board._solve_layout()
			board._snap_all_home()
		var original: Array = _all_flowers(board)
		var positions: Dictionary = {}
		for flower: JuiceFruit in original:
			positions[flower] = flower.global_position
		var events: Array[String] = []
		board.cup_collected.connect( func(_type: int, _nth: int, _color: Color, _rect: Rect2) -> void :
			events.append("cup")
		)
		_check(board.complete_column_prop(), "多来源盘面允许完成一列")
		var flight: Dictionary = board.get("_complete_column_flight") as Dictionary
		var entries: Array = flight["entries"]
		var gather: Array[Dictionary] = []
		var exchange: Array[Dictionary] = []
		var gather_durations: Array[float] = []
		var exchange_end: float = 0.0
		var gather_end: float = 0.0
		for entry: Dictionary in entries:
			_check( not entry.has("hover_pos") and not entry.has("yield_pos") and not entry.has("yield_start")
				and not entry.has("gather_delay") and not entry.has("exchange_delay"), "取消中心汇聚、侧移让位及错峰启动")
			if String(entry["kind"]) == "gather":
				gather.append(entry)
				gather_durations.append(float(entry["gather_duration"]))
				gather_end = maxf(gather_end, board.COMPLETE_COLUMN_FEEDBACK_DUR + float(entry["gather_duration"]))
				_check(float(entry["gather_duration"]) >= board.COMPLETE_COLUMN_GATHER_DUR * 0.6 + board.COMPLETE_COLUMN_MOTION_EXTRA_DUR
					and float(entry["gather_duration"]) <= board.COMPLETE_COLUMN_GATHER_DUR * 1.4 + board.COMPLETE_COLUMN_MOTION_EXTRA_DUR, 
					"同时起飞保留±40%基础时长差异并增加启动和缓停时间")
				var offset: Vector2 = (entry["arrival_pos"] as Vector2) - (entry["dst_pos"] as Vector2)
				_check(offset.is_equal_approx(Vector2(0.0, -15.0)) and not entry.has("suspend_pos")
					and not entry.has("offset"), "所有目标对齐中轴、统一在点位上15像素，无悬停及随机偏移")
			elif String(entry["kind"]) == "exchange":
				exchange.append(entry)
				exchange_end = maxf(exchange_end, float(entry["exchange_duration"]))
		_check(gather.size() >= 2 and exchange.size() >= 2, "题面覆盖多个目标及替换元素")
		_check(gather_durations.max() - gather_durations.min() > 0.001, "目标飞行时长仍保留随机差异")
		var duration: float = float(flight["duration"])
		_check(absf(duration - maxf(exchange_end, gather_end)) < 1e-06
			and not flight.has("hold_start") and not flight.has("slam_start") and not flight.has("settle_start"), 
			"实际飞行结束立即交接，不再叠加悬停、砸落及回弹阶段")
		_check(duration <= board.COMPLETE_COLUMN_FLY_DUR + 1e-06
			and board.COMPLETE_COLUMN_GATHER_DUR < 0.5, "保留提速后的基础飞行时长和实际交接上界")
		for flower: JuiceFruit in original:
			_check(flower.global_position.distance_to(positions[flower]) < 0.01, "提交帧不瞬移元素")
		for target: Dictionary in gather:
			for replacement_entry: Dictionary in exchange:
				_check((target["node"] as JuiceFruit).z_index > (replacement_entry["node"] as JuiceFruit).z_index, 
					"目标元素层级高于全部替换元素")
		for entry: Dictionary in entries:
			if String(entry["kind"]) != "stay":
				continue
			for replacement_entry: Dictionary in exchange:
				_check((replacement_entry["node"] as JuiceFruit).z_index > (entry["node"] as JuiceFruit).z_index, 
					"替换元素层级高于现有原位元素")
		var flight_brake: float = board.COMPLETE_COLUMN_FLIGHT_BRAKE_RATIO
		for feedback_time: float in [board.COMPLETE_COLUMN_FEEDBACK_UP_DUR, 
				board.COMPLETE_COLUMN_FEEDBACK_UP_DUR + board.COMPLETE_COLUMN_FEEDBACK_DOWN_DUR, 
				board.COMPLETE_COLUMN_FEEDBACK_DUR]:
			_advance_flight_to(board, feedback_time)
			var expected_scale: float = board._complete_column_feedback_scale(feedback_time)
			for entry: Dictionary in gather:
				var fruit: JuiceFruit = entry["node"]
				_check(board._fruit_layer_pos(fruit).distance_to(entry["from"]) < 0.01, 
					"缩放反馈期间目标元素保持原位，播完后才起飞")
				_check(fruit.scale.is_equal_approx(Vector2.ONE * expected_scale), "原位反馈依次达到120%、95%、100%")
				var effect: CompleteColumnFlowerFx = entry["feedback_fx"]
				_check(effect._burst.amount == 8 and effect._glow.visible and effect._glow.modulate.a > 0.0, 
					"反馈同时显示背后放射光和8颗扩散粒子")
				_check(effect.global_position.distance_to(fruit.tutorial_visual_center_global()) < 0.01
					and effect.z_index < fruit.z_index, "背光与粒子位于目标元素可见中心后方")
				_check(effect._overlay.visible and effect.z_index + effect._overlay.z_index > fruit.z_index, 
					"背光出现时同步显示目标元素上层glow光")
				_check(absf(effect._overlay.scale.x * effect._overlay.texture.get_width()
					- fruit.visual_diameter() * 1.4 * fruit.scale.x) < 0.001, 
					"glow光直径为元素可见图的140%，并跟随元素缩放")
				_check( not effect._trail_started and (entry["trail_ribbons"] as Array).is_empty(), 
					"原位反馈不提前发射飞行粒子或线形拖尾")
			for entry: Dictionary in exchange:
				_check(entry["feedback_fx"] == null and (entry["node"] as JuiceFruit).scale.is_equal_approx(Vector2.ONE), 
					"换位元素正常先行且没有缩放、背光或粒子")
		var sample_time: float = 0.04
		_advance_flight_to(board, board.COMPLETE_COLUMN_FEEDBACK_DUR + sample_time)
		for entry: Dictionary in entries:
			if String(entry["kind"]) == "stay":
				_check(board._fruit_layer_pos(entry["node"]).distance_to(entry["from"]) < 0.01, "原位元素不参与飞行")
			else:
				_check(board._fruit_layer_pos(entry["node"]).distance_to(entry["from"]) > 1.0, "第一阶段目标和替换元素均已开始运动")
		for entry: Dictionary in gather:
			var effect: CompleteColumnFlowerFx = entry["feedback_fx"]
			_check(effect._trail_started and effect._trail.emitting and effect._glow.visible, 
				"回弧飞行持续保留背光，并开始拖出花瓣粒子")
			var eased: float = board._complete_column_motion_progress(sample_time, float(entry["gather_duration"]), flight_brake)
			var from: Vector2 = entry["from"]
			var arrival_pos: Vector2 = entry["arrival_pos"]
			var from_control: Vector2 = entry["curve_from_control"]
			var dst_control: Vector2 = entry["curve_dst_control"]
			var expected: Vector2 = from.bezier_interpolate(from_control, dst_control, arrival_pos, eased)
			_check(board._fruit_layer_pos(entry["node"]).distance_to(expected) < 0.01, "目标沿冻结回弧轨迹飞向中轴上15像素的落位点")
			var direction: float = signf((entry["dst_pos"] as Vector2).x - from.x)
			if int(entry["src_col"]) == int(entry["dst_col"]) or is_zero_approx(direction):
				direction = -1.0 if int(entry["dst_index"]) % 2 == 0 else 1.0
			_check((expected.x - from.x) * direction < 0.0, "左右镜像题面均先朝目标列的反方向移动")
			var maximum_pullback: float = 0.0
			for sample: int in range(1, 101):
				var point: Vector2 = from.bezier_interpolate(from_control, dst_control, arrival_pos, float(sample) / 100.0)
				maximum_pullback = maxf(maximum_pullback, - (point.x - from.x) * direction)
			_check(maximum_pullback >= board._lay.fruit_d * 0.1, "回拉距离足够形成可辨识的反向回弧")
			var midpoint: Vector2 = from.bezier_interpolate(from_control, dst_control, arrival_pos, 0.5)
			_check(midpoint.y < from.lerp(arrival_pos, 0.5).y - board._lay.fruit_d * 0.2, 
				"回弧明显偏离直线并向上转向目标列")
			_check(from.bezier_interpolate(from_control, dst_control, arrival_pos, 0.0).is_equal_approx(from)
				and from.bezier_interpolate(from_control, dst_control, arrival_pos, 1.0).is_equal_approx(arrival_pos), 
				"回弧起点和中轴落位终点准确")
			_check((entry["node"] as JuiceFruit).scale.is_equal_approx(Vector2.ONE * board._complete_column_flight_scale(
				sample_time / float(entry["gather_duration"]))), "目标放大后只在飞行最后10%缩回100%")
			var ribbons: Array = entry["trail_ribbons"]
			_check(ribbons.size() == 1, "目标飞行只保留外层柔光拖尾，移除主体和中心亮芯")
			if ribbons.size() == 1:
				var outer: FireworkTrails.Ribbon = ribbons[0]
				_check(outer.target == entry["node"] and outer.rgb.is_equal_approx(entry["trail_color"])
					and absf(outer.head_alpha - 0.75) < 0.001, 
					"同色外层拖尾不透明度从30%提高到75%，不增加中心亮芯")
				var trail_width: float = board._lay.fruit_d * (entry["node"] as JuiceFruit).scale.x * 0.25 * SpiralLightFx.TRAIL_GLOW_RATIO
				_check(absf(outer.head_width - trail_width) < 0.001, "保留的外层拖尾宽度缩为此前外层的一半")
		var prop_trails: FireworkTrails = board._complete_column_trails
		var collection_trails: FireworkTrails = board._ensure_fly_trails()
		_check(prop_trails != collection_trails and collection_trails.z_index == board.SLAM_FLY_Z, 
			"道具独立低层拖尾不改变原收盆拖尾层级")
		_check(prop_trails.get_parent() == board._fruit_layer, "道具拖尾和元素共享同一坐标与层级父级")
		for entry: Dictionary in gather:
			_check(prop_trails.z_index < (entry["node"] as JuiceFruit).z_index, 
				"道具外层拖尾位于目标元素之下，不遮挡本体")
		for entry: Dictionary in exchange:
			_check(prop_trails.z_index < (entry["node"] as JuiceFruit).z_index, "道具拖尾也不遮挡替换元素")
		prop_trails._process(0.0)
		_advance_flight_to(board, board.COMPLETE_COLUMN_FEEDBACK_DUR + sample_time + 0.02)
		prop_trails._process(0.0)
		for entry: Dictionary in gather:
			var expected_width: float = board._lay.fruit_d * (entry["node"] as JuiceFruit).scale.x * 0.25 * SpiralLightFx.TRAIL_GLOW_RATIO
			_check(absf((entry["trail_ribbons"][0] as FireworkTrails.Ribbon).head_width - expected_width) < 0.001, 
				"元素继续放大时拖尾宽度同步跟随，不沿用起飞时尺寸")
			for ribbon: FireworkTrails.Ribbon in entry["trail_ribbons"]:
				_check(ribbon.pos.size() >= 2, "拖尾采样真实飞行路径")
		_advance_flight_to(board, exchange_end)
		for entry: Dictionary in exchange:
			_check(board._fruit_layer_pos(entry["node"]).distance_to(entry["dst_pos"]) < 0.01
				and (entry["node"] as JuiceFruit).scale.is_equal_approx(Vector2.ONE), "替换元素正常结束飞行并保持原尺寸")
		for node_entry: Dictionary in flight["hidden"]:
			_check( not (node_entry["node"] as CanvasItem).visible, "飞行完成前不提前显示补货节点")
		var landing_entries: Array[Dictionary] = gather.duplicate()
		landing_entries.sort_custom( func(first: Dictionary, second: Dictionary) -> bool:
			return float(first["gather_duration"]) < float(second["gather_duration"])
		)
		for entry: Dictionary in landing_entries:
			_advance_flight_to(board, board.COMPLETE_COLUMN_FEEDBACK_DUR + float(entry["gather_duration"]) * 0.95)
			_check((entry["node"] as JuiceFruit).scale.is_equal_approx(Vector2.ONE * 1.1), 
				"最后10%飞行的中点已从120%连续缩到110%，无独立回弹阶段")
			var effect: CompleteColumnFlowerFx = entry["feedback_fx"]
			_check(effect._glow.visible and effect._glow.modulate.a > 0.0 and effect._glow.modulate.a < 0.75, 
				"到位前放射光短暂渐隐，不增加到位后等待")
			_check( not effect._burst.emitting and not effect._trail.emitting
				and not effect._burst.visible and not effect._trail.visible and effect._overlay.visible
				and effect._overlay.modulate.a > 0.0 and effect._overlay.modulate.a < 0.5, 
				"飞行收尾花瓣清场，50%峰值glow平滑渐隐")
		_check(events.is_empty(), "调配结束前不提前Link或收盆")
		var target_column: int = int(flight["target"])
		var handoff_delta: float = float(flight["start"]) + float(flight["delay"]) + duration - float(board._t)
		_advance_flight_to(board, duration)
		_check((board.get("_complete_column_flight") as Dictionary).is_empty(), "按实际时长完成交接")
		for entry: Dictionary in entries:
			var flower: JuiceFruit = entry["node"]
			var expected_arrival: Vector2 = entry["arrival_pos"]
			if String(entry["kind"]) == "exchange":
				var home: Vector2 = board._home_pos_swayed(int(entry["dst_col"]), int(entry["dst_index"]))
				home.x += board._shake_dx(int(entry["dst_col"])) + board._wind_curve_dx(home.y - board._row_y(int(entry["dst_col"])))
				expected_arrival = expected_arrival.lerp(home, 1.0 - exp( - board.EASE_RATE * handoff_delta))
			_check(board._fruit_layer_pos(flower).distance_to(expected_arrival) < 0.01
				and flower.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(flower.rotation)
				and not flower.top_level, "交接帧落位与尺寸连续: kind=%s pos=%s expected=%s scale=%s top=%s" % [
					entry["kind"], board._fruit_layer_pos(flower), entry["arrival_pos"], flower.scale, flower.top_level])
		var link_beat: Dictionary = {}
		for beat: Dictionary in board._beats:
			if int(beat["col"]) == target_column:
				link_beat = beat
				break
		_check( not link_beat.is_empty() and bool(link_beat["burst_started"])
			and absf(float(link_beat["t0"]) - float(board._t)) < 1e-06, 
			"飞行交接同一帧启动整列Link，零额外等待")
		board._process(board.BURST_PULSE_UP_DUR * 0.5)
		for entry: Dictionary in gather:
			var expected: Vector2 = (entry["arrival_pos"] as Vector2).lerp(entry["dst_pos"], 0.5)
			_check(board._fruit_layer_pos(entry["node"]).distance_to(expected) < 0.01, 
				"15像素落位余量随Link首段平滑归位，不独立悬停或砸落")
		for _frame: int in 400:
			board._process(1.0 / 60.0)
		_check(events.count("cup") >= 1 and not board.is_busy() and board.sync_error() == "", "直接落位无缝接Link后正常收盆和补位")
		_free_board(board)


func _check_motion_rhythm() -> void :
	var board: JuiceBoardView = JuiceBoardView.new()
	_check(is_equal_approx(board._complete_column_flight_scale(0.9), 1.2)
		and is_equal_approx(board._complete_column_flight_scale(0.95), 1.1)
		and is_equal_approx(board._complete_column_flight_scale(1.0), 1.0), 
		"飞行最后10%从120%缓动恢复100%")
	_check(board._complete_column_flight_scale(0.89) < board._complete_column_flight_scale(0.9), 
		"飞行前90%不提前缩小，最后10%交界连续")
	for motion: Dictionary in [
		{"base": board.COMPLETE_COLUMN_GATHER_DUR, "random": board.COMPLETE_COLUMN_DEPARTURE_RANDOM_RATIO, 
			"brake": board.COMPLETE_COLUMN_FLIGHT_BRAKE_RATIO}, 
		{"base": board.COMPLETE_COLUMN_EXCHANGE_DUR, "random": board.COMPLETE_COLUMN_TIMING_RANDOM_RATIO, 
			"brake": board.COMPLETE_COLUMN_BRAKE_RATIO}, 
	]:
		for multiplier: float in [1.0 - float(motion["random"]), 1.0, 1.0 + float(motion["random"])]:
			var base_duration: float = float(motion["base"]) * multiplier
			var duration: float = base_duration + board.COMPLETE_COLUMN_MOTION_EXTRA_DUR
			var brake_ratio: float = float(motion["brake"])
			var speed: float = (1.0 + brake_ratio) / base_duration
			var brake_duration: float = base_duration * 2.0 * brake_ratio / (1.0 + brake_ratio) + board.COMPLETE_COLUMN_BRAKE_EXTRA_DUR
			var cruise_duration: float = 1.0 / speed - (board.COMPLETE_COLUMN_LAUNCH_DUR + brake_duration) * 0.5
			_check(cruise_duration > 0.0, "两类元素在随机时长上下界均保留正常中段飞行")
			var cruise_start: float = board.COMPLETE_COLUMN_LAUNCH_DUR
			var cruise_step: float = board._complete_column_motion_progress(cruise_start + 0.01, duration, brake_ratio)\
			- board._complete_column_motion_progress(cruise_start + 0.005, duration, brake_ratio)
			_check(absf(cruise_step - speed * 0.005) < 1e-06, "中段速度与原飞行速度一致，非整段慢放")
			var launch_step: float = board._complete_column_motion_progress(0.005, duration, brake_ratio)
			var landing_step: float = 1.0 - board._complete_column_motion_progress(duration - 0.005, duration, brake_ratio)
			_check(launch_step < cruise_step * 0.05 and landing_step < cruise_step * 0.05, 
				"启动从低速加速，延长后的缓停逐渐减速到零")
			_check(board._complete_column_motion_progress(0.0, duration, brake_ratio) == 0.0
				and board._complete_column_motion_progress(duration, duration, brake_ratio) == 1.0, 
				"启动和缓停不改变飞行起止位置")
			var previous: float = 0.0
			for sample: int in range(1, 201):
				var progress: float = board._complete_column_motion_progress(duration * float(sample) / 200.0, duration, brake_ratio)
				_check(progress >= previous and progress <= 1.0, "加速、正常飞行和缓停连续前进，不反向或越界")
				previous = progress
	board.free()


func _check_staged_cancellation(scene: PackedScene) -> void :
	for phase: String in ["feedback", "gather", "arrival"]:
		var board: Variant = _new_board(scene)
		var events: Array[String] = []
		board.cup_collected.connect( func(_type: int, _nth: int, _color: Color, _rect: Rect2) -> void :
			events.append("cup")
		)
		_check(board.complete_column_prop(), "各阶段中断测试允许起播")
		var flight: Dictionary = board.get("_complete_column_flight") as Dictionary
		var phase_times: Dictionary = {
			"feedback": board.COMPLETE_COLUMN_FEEDBACK_DUR * 0.5, 
			"gather": board.COMPLETE_COLUMN_FEEDBACK_DUR + (float(flight["duration"]) - board.COMPLETE_COLUMN_FEEDBACK_DUR) * 0.5, 
			"arrival": float(flight["duration"]) - 0.001, 
		}
		_advance_flight_to(board, float(phase_times[phase]))
		var ribbons: Array = []
		var effects: Array[CompleteColumnFlowerFx] = []
		for entry: Dictionary in flight["entries"]:
			ribbons.append_array(entry["trail_ribbons"])
			if entry["feedback_fx"] != null:
				effects.append(entry["feedback_fx"])
		board.setup(_level())
		for effect: CompleteColumnFlowerFx in effects:
			_check( not effect.visible and not effect._glow.visible and not effect._burst.emitting
				and not effect._trail.emitting and not effect._overlay.visible, 
				"取消各阶段后背光与粒子全部隐藏并停发")
		_check((board.get("_complete_column_flight") as Dictionary).is_empty(), "各阶段重开取消旧动效")
		_check( not is_instance_valid(board._complete_column_trails)
			or (board._complete_column_trails._ribbons as Array).is_empty(), "各阶段重开清空独立道具拖尾渲染器")
		for ribbon: FireworkTrails.Ribbon in ribbons:
			_check(ribbon.target == null and ribbon.pos.is_empty(), "重开清空旧拖尾，不跟随池化复用的新元素")
		for flower: JuiceFruit in _all_flowers(board):
			_check( not flower.top_level and flower.z_index == 0
				and flower.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(flower.rotation), 
				"取消换位或飞行后复原大小、朝向与层级")
		for _frame: int in 100:
			board._process(0.02)
		_check(events.is_empty(), "取消后不继续交付旧盆")
		_check(board.complete_column_prop(), "取消后新一轮道具可正常起播")
		board._process(0.01)
		for entry: Dictionary in (board.get("_complete_column_flight") as Dictionary)["entries"]:
			if entry["feedback_fx"] != null:
				_check(effects.has(entry["feedback_fx"]), "新一轮复用原特效节点，不重复分配发射器")
		board._process(board.COMPLETE_COLUMN_FLY_DUR)
		_check((board.get("_complete_column_flight") as Dictionary).is_empty(), "新一轮随机动效正常交接")
		_free_board(board)


func _check_particle_theme_and_reuse() -> void :
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var bird: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/bird.tres")
	var resources: = JuiceSkinResolver.new(base, bird)
	var effect: = CompleteColumnFlowerFx.new()
	effect.position = UiMetrics.viewport_size() * 0.5
	var diameter: float = 100.0
	var visible_diameter: float = diameter * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO
	var petals: Texture2D = base.effects.rope_petal
	effect.configure(diameter, petals, false, base.effects.quota_ring, Color.RED, 
		visible_diameter, base.effects.complete_column_glow, 3)
	root.add_child(effect)
	effect.advance(0.14, 1.2, false, false, 0.0)
	var material: ParticleProcessMaterial = effect._burst.process_material
	_check(material.particle_flag_disable_z and not effect._burst.local_coords and not effect._trail.local_coords, 
		"两套粒子显式关闭Z轴模拟，已发射粒子不随元素整团移动")
	_check(absf(material.scale_max / material.scale_min - 3.0) < 0.001
		and material.angular_velocity_min == 90.0 and material.angular_velocity_max == 270.0, 
		"粒子尺寸和旋转速度各保持基准值±50%随机度")
	_check(effect._burst.texture == petals and effect._burst.material != null, "花朵使用皮肤花瓣图集")
	_check(absf(effect._glow_scale * base.effects.quota_ring.get_width() - diameter * 1.6 * 0.7) < 0.001, 
		"背光在原尺寸基础上缩小30%，以元素图直径比例定标")
	var trail_material: ParticleProcessMaterial = effect._trail.process_material
	_check(absf(trail_material.emission_sphere_radius * 2.0 - visible_diameter * 0.5) < 0.001, 
		"飞行拖尾粒子的出生圆直径为当前元素图可见直径50%")
	_check(absf(material.scale_min * petals.get_width() * 0.5 - diameter * 0.14 * 0.5 * 0.5) < 0.001
		and absf(trail_material.scale_max * petals.get_width() * 0.5 - diameter * 0.14 * 1.5 * 0.5) < 0.001, 
		"扩散和飞行花瓣尺寸均缩小50%，保留各自随机区间")
	var emitter_count: int = 0
	for child: Node in effect.get_children():
		if child is GPUParticles2D:
			emitter_count += 1
	_check(emitter_count == 2 and effect.get_node_or_null("GlowPoints") == null, 
		"删除glow粒子，只保留原有扩散和飞行花瓣发射器")
	_check(effect._overlay.texture == base.effects.complete_column_glow and effect._overlay.visible
		and effect._overlay.modulate.is_equal_approx(Color(Color.RED, 0.5))
		and (effect._overlay.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, 
		"元素上层glow使用ef_glow_001、对应颜色、Add混合及50%不透明度")
	_check(absf(effect._overlay.scale.x * effect._overlay.texture.get_width() - visible_diameter * 1.4 * 1.2) < 0.001, 
		"glow光层直径为目标元素可见图的140%，随元素放大120%")
	effect.reset_for_pool()
	var feather: Texture2D = resources.color_texture(&"red", &"feather")
	_check(feather != null, "小鸟皮肤提供对应颜色羽毛")
	effect.configure(diameter, feather, true, resources.effect_texture(&"quota_ring"), Color.BLUE, 
		visible_diameter, resources.effect_texture(&"complete_column_glow"), 3)
	_check(effect._overlay.texture == base.effects.complete_column_glow, 
		"小鸟主题的完成一列glow空槽回退默认新贴图，不改变解锁glow")
	effect.advance(0.01, 1.0, false, false, 0.0)
	_check(effect._burst.texture == feather and effect._trail.texture == feather
		and effect._burst.material == null and effect._burst.modulate == Color.WHITE, 
		"小鸟反馈及飞行使用原色完整羽毛，不套花瓣图集或染色")
	_check(effect._burst.self_modulate.a == 0.0, "复用换样式首次绘制前保持透明，等待真实更新")
	_check(Color(effect._overlay.modulate, 1.0).is_equal_approx(Color.BLUE), "换色后glow光层同步使用新目标颜色")
	effect.reset_for_pool()
	for frame: int in 4:
		await process_frame
	_check( not effect.visible and not effect._burst.visible and not effect._burst.emitting
		and not effect._overlay.visible, 
		"取消后旧等待不能恢复新样式粒子")
	effect.configure(diameter, petals, false, base.effects.quota_ring, Color.RED, 
		visible_diameter, base.effects.complete_column_glow, 3)
	effect.advance(0.14, 1.2, true, false, 0.0)
	for frame: int in 5:
		await process_frame
	_check(effect._burst_lifecycle._revealed and effect._trail_lifecycle._revealed
		and effect._overlay.visible and effect._overlay.modulate.is_equal_approx(Color(Color.RED, 0.5))
		and effect._trail.emitting and effect._trail.self_modulate.a == 1.0, 
		"换回花瓣后新一轮正常起播，旧等待不会污染新一轮")
	effect.advance(1.0, 1.2, false, true, 0.0)
	_check(effect._overlay.visible and effect._overlay.modulate.a == 0.5, 
		"落位渐隐起点glow光层保持50%不透明度")
	effect.advance(1.09, 1.08, false, true, 0.5)
	_check(effect._glow.visible and absf(effect._glow.modulate.a - 0.375) < 0.001
		and effect._overlay.visible and absf(effect._overlay.modulate.a - 0.25) < 0.001, 
		"落位渐隐中点背光和glow光层都仍可见，亮度同步减半")
	effect.advance(1.18, 1.0, false, true, 1.0)
	_check( not effect._glow.visible and not effect._overlay.visible, 
		"落位渐隐末端统一清场")
	effect.reset_for_pool()
	for adapted_diameter: float in [60.0, 120.0, 180.0]:
		var adapted_visible_diameter: float = adapted_diameter * JuiceLayout.FRUIT_VISIBLE_WIDTH_RATIO
		effect.configure(adapted_diameter, petals, false, base.effects.quota_ring, Color.RED, 
			adapted_visible_diameter, base.effects.complete_column_glow, 3)
		effect.advance(0.14, 1.0, false, false, 0.0)
		_check(effect._overlay.modulate.a == 0.5, "渐隐后重播恢复glow光层50%亮度")
		_check(absf(effect._glow_scale * base.effects.quota_ring.get_width() / adapted_visible_diameter
			- effect.GLOW_DIAMETER_RATIO) < 0.001, "不同局内元素大小保持背光与可见图直径比例")
		_check(absf(trail_material.emission_sphere_radius * 2.0 / adapted_visible_diameter - 0.5) < 0.001
			and absf(effect._overlay.scale.x * effect._overlay.texture.get_width() / adapted_visible_diameter - 1.4) < 0.001, 
			"大小变化后拖尾出生范围与glow光层尺寸同步适配，不固定像素尺寸")
		effect.reset_for_pool()
	effect.free()


func _advance_flight_to(board: Variant, elapsed: float) -> void :
	var flight: Dictionary = board.get("_complete_column_flight") as Dictionary
	var next_time: float = float(flight["start"]) + float(flight["delay"]) + elapsed
	board._process(maxf(0.0, next_time - float(board.get("_t"))))



func _level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 98971, "capacity": 2, "targetCups": 2, 
		"initial": ["0|1", "1|0", "-|0,1"], "incoming": ["x", "x"]})



func _new_board(scene: PackedScene, row: Dictionary = {}) -> Variant:
	var board: Variant = scene.instantiate()

	board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	board.size = UiMetrics.viewport_size()
	root.add_child(board)
	var skin: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	board.apply_skin(JuiceSkinResolver.new(skin, skin), false)
	board.setup(_level() if row.is_empty() else JuiceLevel.from_dict(row))
	board.set_process(false)
	return board




func _check_reveal_then_fly(board: Variant, label: String) -> void :
	var flight: Dictionary = board.get("_complete_column_flight") as Dictionary
	var reveal_delay: float = float(flight.get("delay", 0.0))
	_check(reveal_delay > 0.0, label + "：主动揭问号时跳列必须等待揭开动画")
	var revealed_target: Array = (flight.get("rec", {}) as Dictionary).get("revealed_target", []) as Array
	_check( not revealed_target.is_empty(), label + "：本次结果应记录主动揭开的问号")



	var reveal_started: bool = false
	for listed_beat: Dictionary in (board.get("_beats") as Array):
		for node: JuiceFruit in (listed_beat.get("nodes", []) as Array):
			if is_instance_valid(node) and float(node.get("_reveal_time")) >= 0.0:
				reveal_started = true
	_check(reveal_started, label + "：主动揭开的问号必须先完成显色")

	var target_ci: int = int(revealed_target[0].get("col", -1))
	for node: JuiceFruit in ((board.get("_fruit_nodes") as Dictionary).get(target_ci, []) as Array):
		_check( not is_instance_valid(node) or float(node.get("_reveal_time")) < 0.0, 
			label + "：补货新节点不得被误当成问号揭开")
	var start_pos: Dictionary = {}
	for entry: Dictionary in (flight.get("entries", []) as Array):
		var node: Variant = entry.get("node")
		if is_instance_valid(node):
			start_pos[node] = (node as JuiceFruit).global_position
	board._process(reveal_delay * 0.5)
	var started_early: bool = _any_fruit_moved(start_pos)
	_check( not started_early, label + "：揭开动画期间花朵不得提前跳列")
	board._process(reveal_delay * 0.5 + board.COMPLETE_COLUMN_FLY_DUR * 0.5)
	var started: bool = _any_fruit_moved(start_pos)
	_check(started, label + "：揭开动画结束后应开始跳列")



func _find_hidden(board: Variant) -> Variant:
	for list: Array in (board.get("_fruit_nodes") as Dictionary).values():
		for fruit: JuiceFruit in list:
			if is_instance_valid(fruit) and JuiceLevel.is_hidden(fruit.fruit_type):
				return fruit
	return null



func _any_fruit_moved(start_pos: Dictionary) -> bool:
	for node: Variant in start_pos:
		if is_instance_valid(node)\
		and (node as JuiceFruit).global_position.distance_to(start_pos[node]) > 1.0:
			return true
	return false



func _all_flowers(board: Variant) -> Array:
	var flowers: Array = []
	for list: Array in (board.get("_fruit_nodes") as Dictionary).values():
		flowers.append_array(list)
	return flowers



func _locked_col(board: Variant) -> int:
	var locks: Array = board.state()["locks"] as Array
	for ci: int in locks.size():
		if not (locks[ci] as Dictionary).is_empty():
			return ci
	return -1



func _same_nodes(before: Array, after: Array) -> bool:
	if before.size() != after.size():
		return false
	for i: int in before.size():
		if before[i] != after[i]:
			return false
	return true



func _free_board(board: Variant) -> void :
	board._cancel_closed_check()
	board.free()


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
