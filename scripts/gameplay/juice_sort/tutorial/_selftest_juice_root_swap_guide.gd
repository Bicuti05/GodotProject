extends SceneTree




const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const GUIDE = preload("res://scripts/gameplay/juice_sort/tutorial/juice_root_swap_guide.gd")

class ProbeBoard extends JuiceBoardView:
	var model_state: Dictionary = {}
	var view_order: Array[int] = [0, 1, 2]
	var probe_busy: bool = false
	var probe_returning: bool = false
	var probe_dragging: bool = false
	var probe_gate: bool = false
	var geometry_shift: Vector2 = Vector2.ZERO
	var probe_highlight: Dictionary = {}
	var probe_demo: Dictionary = {}
	var demo_clears: int = 0
	var highlight_clears: int = 0
	var gate_writes: int = 0
	var probe_move_gate: Callable = Callable()
	var probe_grab_gate: Callable = Callable()
	var probe_steps: int = 0
	var probe_level: JuiceLevel = null
	var probe_feedback: Dictionary = {}
	var append_position_reads: int = 0
	func state() -> Dictionary:
		return model_state
	func order() -> Array[int]:
		return view_order.duplicate()
	func is_busy() -> bool:
		return probe_busy
	func is_drop_returning() -> bool:
		return probe_returning
	func has_active_drag() -> bool:
		return probe_dragging
	func has_move_gate(gate: Callable = Callable()) -> bool:
		return (probe_gate and gate.is_null())\
		or (probe_move_gate.is_valid() and (gate.is_null() or probe_move_gate == gate))
	func has_grab_gate(gate: Callable = Callable()) -> bool:
		return probe_grab_gate.is_valid() and (gate.is_null() or probe_grab_gate == gate)
	func set_move_gate(gate: Callable = Callable()) -> void :
		gate_writes += 1
		probe_move_gate = gate
	func set_grab_gate(gate: Callable = Callable()) -> void :
		gate_writes += 1
		probe_grab_gate = gate
	func steps() -> int:
		return probe_steps
	func level() -> JuiceLevel:
		return probe_level
	func move_feedback_info() -> Dictionary:
		return probe_feedback.duplicate()
	func fruit_global_pos(col: int, idx: int) -> Vector2:
		return geometry_shift + Vector2(100 + col * 100, 200 + idx * 30)
	func drop_global_pos(col: int) -> Vector2:
		append_position_reads += 1
		return fruit_global_pos(col, (model_state["cols"][col] as Array).size())
	func rope_bottom_global_y() -> float:
		return 700.0
	func set_run_highlight(col: int, j: int, on: bool) -> void :
		if on:
			probe_highlight = {"col": col, "j": j}
		else:
			highlight_clears += 1
			probe_highlight = {}
	func set_run_demo_pos(col: int, j: int, head_global: Vector2) -> void :
		probe_demo = {"col": col, "j": j, "head": head_global}
	func clear_run_demo_pos() -> void :
		demo_clears += 1
		probe_demo = {}

class ProbeLayer extends JuiceTutorialLayer:
	var from_point: Vector2 = Vector2.INF
	var target_point: Vector2 = Vector2.INF
	var head_point: Vector2 = Vector2.INF
	var playing: bool = false
	var probe_visible: bool = false
	var hidden_texts: int = 0
	var written_texts: int = 0
	var probe_text: String = ""
	var probe_text_visible: bool = false
	var stop_calls: int = 0
	var full_clear_calls: int = 0
	func hide_text() -> void :
		hidden_texts += 1
		probe_text_visible = false
	func set_text(text: String, _error: bool = false) -> void :
		written_texts += 1
		probe_text = text
		probe_text_visible = text != ""
	func play_drag_demo(from_global: Vector2, to_global_pos: Vector2, 
			_clamp_bottom_y: float) -> void :
		if playing and from_point == from_global and target_point == to_global_pos:
			return
		from_point = from_global
		target_point = to_global_pos
		head_point = from_point.lerp(target_point, 0.5)
		playing = true
	func stop_drag_demo() -> void :
		stop_calls += 1
		playing = false
		probe_visible = false
	func is_demo_playing() -> bool:
		return playing
	func is_demo_visible() -> bool:
		return playing and probe_visible
	func demo_head_global() -> Vector2:
		return head_point if playing else Vector2.INF
	func clear_all() -> void :
		full_clear_calls += 1

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, message: String) -> void :
	_checks += 1
	if not ok:
		_failures.append(message)
		push_error("ROOT_SWAP_GUIDE: " + message)


func _fixture() -> Dictionary:
	var lv: JuiceLevel = _fixture_level()
	var st: Dictionary = R.make_state(lv)
	st["allow_root_swapping"] = true
	return st


func _fixture_level() -> JuiceLevel:
	return JuiceLevel.from_dict({"id": 98401, "capacity": 2, "targetCups": 3, 
		"initial": ["0|1,1", "1|0,0", "2|2,2"], "incoming": []})


func _new_probe_board() -> ProbeBoard:
	var board: = ProbeBoard.new()
	board.model_state = _fixture()
	board.probe_level = _fixture_level()
	return board


func _simulate_swap(board: ProbeBoard, patch: Dictionary = {}, skip_steps: int = 1, 
		done_override: int = -1) -> void :
	var rec: Dictionary = R.apply_move(board.model_state, board.probe_level, 0, 0, 1)
	_check( not rec.is_empty(), "模拟互换实际经过生产规则")
	board.probe_steps += skip_steps
	board.probe_feedback = {"player_drop": true, "root_swapped": bool(rec.get("root_swapped", false)), 
		"src": 0, "j": 0, "dst": 1}
	board.probe_feedback.merge(patch, true)
	if done_override >= 0:
		board.model_state["done"] = done_override
	board.moved.emit(board.probe_steps)


func _find(st: Dictionary, order: Array[int] = [0, 1, 2], col: int = 0) -> Dictionary:
	return GUIDE.find_swap(st, order, col)


func _test_candidates() -> void :
	var st: Dictionary = _fixture()
	var before: String = JSON.stringify(st)
	_check(_find(st) == {"src": 0, "j": 0, "dst": 1}, "错盆满串选择可当步收盆的同色盆")
	_check(JSON.stringify(st) == before, "选步不修改生产盘面")
	_check(_find({}, [], 0).is_empty(), "空状态安全拒绝")
	_check(_find(st, [1, 2]).is_empty(), "完成列不在屏幕不触发")
	_check(_find(st, [0, 2]).is_empty(), "目标盆不在屏幕不触发")
	_check(_find(st, [-1, 0, 1, 99]) == {"src": 0, "j": 0, "dst": 1}, "在场序中的越界项不影响合法目标")
	_check(_find(st, [-1, 0, 1], -1).is_empty(), "越界完成列拒绝")
	for key: String in ["allow_root_swapping", "caps", "jars", "gone"]:
		var missing: Dictionary = st.duplicate(true)
		missing.erase(key)
		_check(_find(missing).is_empty(), "必要状态缺失拒绝: " + key)
	for source: Array in [[1], [1, 1, 1], [0, 1], [1001, 1], [1001, 1001], [2001, 1], [2001, 2001]]:
		var changed: Dictionary = st.duplicate(true)
		var source_col: Array[int] = []
		source_col.assign(source)
		changed["cols"][0] = source_col
		_check(_find(changed).is_empty(), "源串必须按真实显色满容量同色: " + str(source))
	for side: int in [0, 1]:
		var locked: Dictionary = st.duplicate(true)
		locked["locks"][side] = {"condition": "collect_count", "count": 3}
		_check(_find(locked).is_empty(), "源或目标锁列拒绝")
		var gone: Dictionary = st.duplicate(true)
		gone["gone"][side] = true
		_check(_find(gone).is_empty(), "源或目标已退出拒绝")
	for cap: int in [0, 1, 3]:
		var changed: Dictionary = st.duplicate(true)
		changed["caps"][1] = cap
		_check(_find(changed).is_empty(), "目标容量需立即收盆: " + str(cap))
	var zero_source: Dictionary = st.duplicate(true)
	zero_source["caps"][0] = 0
	_check(_find(zero_source).is_empty(), "源容量为零拒绝")
	var correct_source: Dictionary = st.duplicate(true)
	correct_source["jars"][0] = 1
	_check(_find(correct_source).is_empty(), "已在正确花盆不教交换")
	var empty_target: Dictionary = st.duplicate(true)
	empty_target["cols"][1] = [] as Array[int]
	_check(_find(empty_target).is_empty(), "空目标属于整串搬移，不能教交换")
	var oversized_target: Dictionary = st.duplicate(true)
	oversized_target["cols"][1] = [0, 0, 0] as Array[int]
	_check(_find(oversized_target).is_empty(), "目标串无法回放到源容量时拒绝")
	var unknown_target: Dictionary = st.duplicate(true)
	unknown_target["cols"][1] = [1000, 0] as Array[int]
	_check( not _find(unknown_target).is_empty(), "目标原串含问号仍可交换，源满串会立即收盆")
	var frozen_target: Dictionary = st.duplicate(true)
	frozen_target["frozen_pots"] = [false, true, false] as Array[bool]
	_check(_find(frozen_target).is_empty(), "目标冻盆无法立即收盆")
	var frozen_source: Dictionary = st.duplicate(true)
	frozen_source["frozen_pots"] = [true, false, false] as Array[bool]
	_check( not _find(frozen_source).is_empty(), "源冻盆不禁止明牌花串搬出")
	var white_source: Dictionary = st.duplicate(true)
	white_source["jars"][0] = -1
	_check( not _find(white_source).is_empty(), "暂存白盆的完成串可换到目标盆")
	var next_target: Dictionary = st.duplicate(true)
	next_target["jars"][2] = 1
	next_target["locks"][1] = {"condition": "collect_count", "count": 3}
	_check(int(_find(next_target).get("dst", -1)) == 2, "跳过不可收目标后按在场顺序选择下一盆")
	var legacy: Dictionary = st.duplicate(true)
	legacy.erase("locks")
	before = JSON.stringify(legacy)
	_check( not _find(legacy).is_empty() and JSON.stringify(legacy) == before, 
		"旧状态的规则 locks 补齐只发生在查询副本")


func _test_controller() -> void :

	var board: = _new_probe_board()
	var layer: = ProbeLayer.new()
	var guide: JuiceRootSwapGuide = GUIDE.new()
	var allowed: Array[bool] = [true]
	var finishes: Array[int] = [0]
	guide.finished.connect( func() -> void : finishes[0] += 1)
	guide.setup(board, layer, func() -> bool: return allowed[0])
	var mv: Dictionary = _find(board.state())
	var before: String = JSON.stringify(board.state())
	_check( not guide.is_running() and not guide.is_processing(), "初始未启动且不空跑 process")
	_check( not guide.start({"src": 0, "j": 1, "dst": 1}), "非根部输入不启动")
	allowed[0] = false
	_check(guide.start(mv) and guide.owns_input_gates() and layer.hidden_texts == 0
		and layer.written_texts == 0, 
		"视觉互斥时先安装门控，不显示或消费引导")
	guide.stop()
	allowed[0] = true
	for blocked: String in ["probe_dragging", "probe_gate"]:
		board.set(blocked, true)
		_check( not guide.start(mv), "盘面自身阻止起播: " + blocked)
		board.set(blocked, false)
	board.probe_busy = true
	_check(guide.start(mv) and guide.owns_input_gates() and not layer.playing, 
		"收盆或补位未结束时门控立即生效，演示继续等待")
	guide.stop()
	board.probe_busy = false
	_check(guide.start(mv) and guide.is_running(), "合法候选启动")
	_check(board.probe_highlight == {"col": 0, "j": 0} and int(board.probe_demo.get("j", -1)) == 0, 
		"起抓高亮和副本都从整串首根开始")
	_check(layer.from_point == board.fruit_global_pos(0, 0)
		and layer.target_point == board.fruit_global_pos(1, 0)
		and board.append_position_reads == 0, "落点使用目标首根而非串尾追加位")
	_check(layer.hidden_texts == 0 and layer.written_texts == 1 and layer.full_clear_calls == 0
		and layer.probe_text == guide.tr("GUIDE_ROOT_SWAP") and layer.probe_text_visible, 
		"复用翻译文案条和手指，不清其他层表现")
	_check(guide.owns_input_gates() and JSON.stringify(board.state()) == before, 
		"引导安装自有门控但不改真实盘面")
	_check(bool(board.probe_grab_gate.call(0, 0))
		and not bool(board.probe_grab_gate.call(0, 1))
		and not bool(board.probe_grab_gate.call(2, 0)), "只允许指定列的首花起抓")
	_check(bool(board.probe_move_gate.call(0, 0, 1))
		and not bool(board.probe_move_gate.call(0, 0, 2))
		and not bool(board.probe_move_gate.call(1, 0, 0)), "只允许指定非空目标落子")
	var copy: Dictionary = guide.move()
	copy["src"] = 2
	_check(guide.move() == mv, "公开指定步骤返回副本，外部不能改写门控")
	allowed[0] = false
	guide._process(0.0)
	var clears: int = board.demo_clears
	var highlight_clears: int = board.highlight_clears
	var stops: int = layer.stop_calls
	guide._process(0.0)
	_check(guide.is_running() and not layer.playing and board.probe_demo.is_empty()
		and board.probe_highlight.is_empty() and not layer.probe_text_visible, 
		"互斥暂停收回文案和演示而保留运行状态")
	_check(board.demo_clears == clears and board.highlight_clears == highlight_clears
		and layer.stop_calls == stops, "持续挂起不重复清共享 seam")
	board.geometry_shift = Vector2(17, 23)
	allowed[0] = true
	guide._process(0.0)
	_check(layer.playing and layer.target_point == board.fruit_global_pos(1, 0)
		and layer.probe_text_visible and layer.probe_text == guide.tr("GUIDE_ROOT_SWAP")
		and layer.written_texts == 2, "恢复文案并按最新首根几何重新演示")
	board.probe_dragging = true
	board.drag_started.emit(0, 0)
	guide._process(0.0)
	_check(guide.is_running() and guide.owns_input_gates() and not layer.playing
		and layer.probe_text_visible and not board.probe_highlight.is_empty(), 
		"指定起抓只收回手指和副本，横幅与门控继续生效")
	board.probe_dragging = false
	board.probe_returning = true
	guide._process(0.0)
	_check(guide.is_running() and not layer.playing, "误放返位期间不退出也不叠放副本")
	board.probe_returning = false
	guide._process(0.0)
	_check(guide.is_running() and layer.playing and finishes[0] == 0, "返位后继续原步骤演示")
	board.moved.emit(board.probe_steps)
	_check(guide.is_running(), "触发引导的当前 moved 回调不误判为旁路下一步")
	_simulate_swap(board, {"player_drop": false})
	_check( not guide.is_running() and finishes[0] == 1 and not layer.probe_text_visible, 
		"旁路 try_move 即使交换成功收盆也只取消，不消费完成")
	_check( not board.drag_started.is_connected(guide._on_player_took_over)
		and not board.moved.is_connected(guide._on_board_moved)
		and not board.has_move_gate() and not board.has_grab_gate(), "退场断开信号并只清自己的门控")
	board.model_state = _fixture()
	_check(guide.start(mv), "再起播用于候选失效检查")
	board.model_state["caps"][1] = 3
	guide._process(0.0)
	_check( not guide.is_running() and finishes[0] == 2, "规则仍可交换但不再立即收盆时结束")
	board.model_state = _fixture()
	_check(guide.start(mv), "恢复合法状态可重启")
	allowed[0] = false
	guide._process(0.0)
	board.probe_demo = {"owner": "hint"}
	board.probe_highlight = {"owner": "hint"}
	layer.playing = true
	layer.set_text("Hint owns this text")
	clears = board.demo_clears
	highlight_clears = board.highlight_clears
	stops = layer.stop_calls
	guide.stop()
	guide.stop()
	_check(board.probe_demo == {"owner": "hint"} and board.probe_highlight == {"owner": "hint"}
		and layer.playing and board.demo_clears == clears and board.highlight_clears == highlight_clears
		and layer.stop_calls == stops and layer.probe_text_visible
		and layer.probe_text == "Hint owns this text", "暂停后 stop 幂等且保留后续 Hint 的共享文案与表现")
	_check(finishes[0] == 2 and not board.has_move_gate() and not board.has_grab_gate()
		and JSON.stringify(board.state()) == before, 
		"主动清场不发完成，完整生命周期不改玩法状态")
	guide.free()
	board.free()
	layer.free()


func _test_completed_feedback() -> void :
	var board: = _new_probe_board()
	var layer: = ProbeLayer.new()
	var guide: JuiceRootSwapGuide = GUIDE.new()
	var completions: Array[int] = [0]
	var cancellations: Array[int] = [0]
	guide.completed.connect( func() -> void : completions[0] += 1)
	guide.finished.connect( func() -> void : cancellations[0] += 1)
	guide.setup(board, layer)
	_check(guide.start(_find(board.state())), "正确互换完成夹具启动")
	_simulate_swap(board)
	_check(completions[0] == 1 and cancellations[0] == 0 and not guide.is_running()
		and not board.has_move_gate() and not board.has_grab_gate(), 
		"真实玩家指定互换并收盆只发 completed，清掉自有门控")
	board.moved.emit(board.probe_steps)
	_check(completions[0] == 1, "重复 moved 不会重复消费首次引导")
	guide.free()
	board.free()
	layer.free()
	for patch: Dictionary in [{"player_drop": false}, {"root_swapped": false}, 
			{"src": 2}, {"j": 1}, {"dst": 2}]:
		board = _new_probe_board()
		layer = ProbeLayer.new()
		guide = GUIDE.new()
		completions = [0]
		cancellations = [0]
		guide.completed.connect( func() -> void : completions[0] += 1)
		guide.finished.connect( func() -> void : cancellations[0] += 1)
		guide.setup(board, layer)
		_check(guide.start(_find(board.state())), "错误完成信息夹具启动: " + str(patch))
		_simulate_swap(board, patch)
		_check(completions[0] == 0 and cancellations[0] == 1 and not guide.is_running(), 
			"非指定真实互换不消费引导: " + str(patch))
		guide.free()
		board.free()
		layer.free()
	for changed: String in ["steps", "done", "level"]:
		board = _new_probe_board()
		layer = ProbeLayer.new()
		guide = GUIDE.new()
		completions = [0]
		cancellations = [0]
		guide.completed.connect( func() -> void : completions[0] += 1)
		guide.finished.connect( func() -> void : cancellations[0] += 1)
		guide.setup(board, layer)
		_check(guide.start(_find(board.state())), "完成证据夹具启动: " + changed)
		if changed == "level":
			board.probe_level = _fixture_level()
		_simulate_swap(board, {}, 2 if changed == "steps" else 1, 0 if changed == "done" else -1)
		_check(completions[0] == 0 and cancellations[0] == 1, 
			"步数、真实收盆和本局身份必须全部匹配: " + changed)
		guide.free()
		board.free()
		layer.free()


func _test_gate_takeover() -> void :
	for side: String in ["move", "grab", "both"]:
		var board: = _new_probe_board()
		var layer: = ProbeLayer.new()
		var guide: JuiceRootSwapGuide = GUIDE.new()
		var cancellations: Array[int] = [0]
		guide.finished.connect( func() -> void : cancellations[0] += 1)
		guide.setup(board, layer)
		_check(guide.start(_find(board.state())), "门控接管夹具启动: " + side)
		var external_move: Callable = func(_src: int, _j: int, _dst: int) -> bool: return false
		var external_grab: Callable = func(_col: int, _j: int) -> bool: return false
		if side in ["move", "both"]:
			board.set_move_gate(external_move)
		if side in ["grab", "both"]:
			board.set_grab_gate(external_grab)
		guide._process(0.0)
		guide.stop()
		_check( not guide.is_running() and cancellations[0] == 1, 
			"任一门控被外部接管后旧引导安全取消: " + side)
		_check(board.has_move_gate(external_move) == (side in ["move", "both"])
			and board.has_grab_gate(external_grab) == (side in ["grab", "both"]), 
			"旧 stop 只清自己的门控，保留外部接管: " + side)
		board.set_move_gate()
		board.set_grab_gate()
		guide.free()
		board.free()
		layer.free()


func _test_shown_timing() -> void :
	var board: = _new_probe_board()
	var layer: = ProbeLayer.new()
	var guide: JuiceRootSwapGuide = GUIDE.new()
	var allowed: Array[bool] = [true]
	var shows: Array[bool] = []
	guide.shown.connect( func() -> void :
		shows.append(layer.is_demo_visible() and not board.probe_demo.is_empty()
			and layer.probe_text_visible))
	guide.setup(board, layer, func() -> bool: return allowed[0])
	var mv: Dictionary = _find(board.state())
	_check(guide.start(mv) and shows.is_empty(), "仅登记演示参数不能算已展示")
	guide._process(0.0)
	_check(shows.is_empty(), "手指尚未可见时持续等待，不消费首次展示")
	layer.probe_visible = true
	guide._process(0.0)
	_check(shows == [true], "手指可见且花副本已提交后通知展示")
	guide._process(0.0)
	_check(shows.size() == 1, "持续演示仅通知一次展示")
	allowed[0] = false
	guide._process(0.0)
	allowed[0] = true
	guide._process(0.0)
	layer.probe_visible = true
	guide._process(0.0)
	_check(shows.size() == 1, "已展示的引导暂停恢复不重复通知")
	_check(guide.start(mv) and not layer.probe_visible, "显式重播仍先登记而不立即显示手指")
	board.probe_dragging = true
	board.drag_started.emit(0, 0)
	_check(guide.is_running() and shows.size() == 1 and layer.probe_text_visible
		and not layer.playing, "首次可见前起抓仍保留强制步骤，不算已展示")
	board.probe_dragging = false
	_check(guide.start(mv), "未显示候选失效夹具起播")
	board.model_state["caps"][1] = 3
	guide._process(0.0)
	_check( not guide.is_running() and shows.size() == 1 and not layer.probe_text_visible, 
		"首次可见前候选失效清掉文案且不算已展示")
	board.model_state = _fixture()
	_check(guide.start(mv), "未显示离树夹具起播")
	guide._exit_tree()
	_check( not guide.is_running() and shows.size() == 1 and not layer.probe_text_visible, 
		"首次可见前离树清掉文案且不算已展示")
	_check(guide.start(mv), "未显示暂停夹具起播")
	allowed[0] = false
	guide._process(0.0)
	_check(shows.size() == 1, "首次可见前互斥暂停不消费展示")
	allowed[0] = true
	guide._process(0.0)
	layer.probe_visible = true
	layer.head_point = Vector2.INF
	guide._process(0.0)
	_check(shows.size() == 1 and board.probe_demo.is_empty(), "手指可见但没有有效花副本不算已展示")
	layer.head_point = layer.from_point
	guide._process(0.0)
	_check(shows == [true, true], "未显示暂停后恢复可见时通知，显式重播重新记录一次")
	guide.free()
	board.free()
	layer.free()


func _test_invalid_instances() -> void :
	for free_board: bool in [true, false]:
		var board: = _new_probe_board()
		var layer: = ProbeLayer.new()
		var guide: JuiceRootSwapGuide = GUIDE.new()
		var finishes: Array[int] = [0]
		guide.finished.connect( func() -> void : finishes[0] += 1)
		guide.setup(board, layer)
		_check(guide.start(_find(board.state())), "实例失效夹具起播")
		if free_board:
			board.free()
		else:
			layer.free()
		guide._process(0.0)
		_check( not guide.is_running() and finishes[0] == 1, "盘面或表现层失效安全退场")
		guide.stop()
		guide.free()
		if free_board:
			layer.free()
		else:
			board.free()


func _test_exit_tree() -> void :
	var board: = _new_probe_board()
	var layer: = ProbeLayer.new()
	var guide: JuiceRootSwapGuide = GUIDE.new()
	root.add_child(guide)
	var allowed: Array[bool] = [true]
	guide.setup(board, layer, func() -> bool: return allowed[0])
	_check(guide.start(_find(board.state())), "离树夹具起播")
	allowed[0] = false
	guide._process(0.0)
	board.probe_demo = {"owner": "hint"}
	layer.playing = true
	layer.set_text("Hint owns this text")
	var clears: int = board.demo_clears
	var stops: int = layer.stop_calls
	guide.queue_free()
	await process_frame
	_check( not is_instance_valid(guide) and board.probe_demo == {"owner": "hint"}
		and layer.playing and board.demo_clears == clears and layer.stop_calls == stops
		and layer.probe_text_visible and layer.probe_text == "Hint owns this text", 
		"queue_free 的 exit_tree 不重复清掉后续共享文案与演示")
	board.free()
	layer.free()


func _run() -> void :
	_test_candidates()
	_test_controller()
	_test_completed_feedback()
	_test_gate_takeover()
	_test_shown_timing()
	_test_invalid_instances()
	await _test_exit_tree()
	print("JUICE_ROOT_SWAP_GUIDE checks=", _checks, " failures=", _failures.size())
	print("PASS" if _failures.is_empty() else "FAIL")
	quit(0 if _failures.is_empty() else 1)
