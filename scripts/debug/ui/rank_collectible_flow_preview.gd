extends PageScene

@onready var _game: JuiceGamePage = $Views / Game
@onready var _rank: RankGameFinishPage = $Views / Preview
@onready var _views: Control = $Views
@onready var _panel: PanelContainer = $Panel
@onready var _kind: OptionButton = $Panel / Margin / Rows / Kind / Style
@onready var _count: OptionButton = $Panel / Margin / Rows / Kind / Count
@onready var _mode: OptionButton = $Panel / Margin / Rows / Mode
@onready var _speed_choice: OptionButton = $Panel / Margin / Rows / Options / Speed
@onready var _step: OptionButton = $Panel / Margin / Rows / Options / Step
@onready var _rules: CheckButton = $Panel / Margin / Rows / Options / Rules
@onready var _loop: CheckButton = $Panel / Margin / Rows / Options / Loop
@onready var _pause_button: Button = $Panel / Margin / Rows / Buttons / Pause
@onready var _fold_button: Button = $Panel / Margin / Rows / Buttons / Fold
@onready var _status: Label = $Panel / Margin / Rows / Status

var _opened: bool = false
var _previous_paused: bool = false
var _generation: int = 0
var _paused: bool = false
var _speed: float = 1.0
var _elapsed: float = 0.0
var _stage: String = "准备中"
var _stage_started: float = 0.0
var _completed_time: float = -1.0
var _running: bool = false
var _folded: bool = false
var _awaiting_cup: bool = false
var _gift_tween: Tween
var _cup_rect: Rect2
var _game_arrivals: int = 0
var _rank_arrivals: int = 0
var _next_source_time: float = 0.0
var _players: Array[AnimationPlayer] = []
var _cpu: Array[CPUParticles2D] = []
var _gpu: Array[GPUParticles2D] = []
var _items: Array[RankItemView] = []
var _events: Array[String] = []
var _settings: Dictionary = {"kind": 0, "count": 6, "mode": 0, "step": 0, "rules": false}
var completed_runs: int = 0

func _ready() -> void :
	for text: String in ["麋鹿", "圣诞树", "雪花", "姜饼人", "铃铛"]:
		_kind.add_item(text)
	for number: int in [3, 6, 12]:
		_count.add_item("%d个目标" % number, number)
	_count.select(1)
	for text: String in ["榜中不升位", "榜中升位", "第4名进入前三", "第2名升第1名", "已是第1名"]:
		_mode.add_item(text)
	for text: String in ["完整流程", "局内收满", "礼盒入目标栏", "完局飞出到账", "排行榜结算"]:
		_step.add_item(text)
	for text: String in ["0.25倍", "0.5倍", "正常1倍"]:
		_speed_choice.add_item(text)
	_speed_choice.select(2)
	_rank.collect_feedback_stage.connect(_mark)
	get_viewport().size_changed.connect(_layout)
	_panel.resized.connect(_layout)
	hide()
	set_process(false)

func _on_show(_params: Dictionary = {}) -> void :
	if OS.has_feature("rel"):
		return
	if not _opened:
		_previous_paused = get_tree().paused
		_opened = true
	get_tree().paused = true
	show()
	set_process(true)
	replay()

func _layout() -> void :
	var view: Vector2 = UiMetrics.viewport_size()
	_panel.size.x = view.x - 32.0
	_panel.position = Vector2(16.0, maxf(0.0, view.y - UiMetrics.safe_insets().y - _panel.size.y - 8.0))

func _process(delta: float) -> void :
	var speed: float = 0.0 if _paused or not _running else _speed
	if _running:
		_elapsed += delta * speed
	if _game._board != null:
		_game._board.motion_preview_speed = speed
	if _game._rank_fly != null:
		_game._rank_fly.playback_speed = speed
		for tween: Tween in _game._rank_fly._tweens:
			_clock(tween, speed)
		for effect: CanvasItem in _game._rank_fly._effects:
			if is_instance_valid(effect) and effect is CPUParticles2D:
				(effect as CPUParticles2D).speed_scale = speed
		for effect: CanvasItem in _game._rank_fly._effects:
			if is_instance_valid(effect) and effect is RankCollectTrail:
				var trail: RankCollectTrail = effect as RankCollectTrail
				trail.playback_speed = speed
				_clock(trail._fade, speed)
				if is_instance_valid(trail._core):
					trail._core.set_process(speed > 0.0)
				for particle: CPUParticles2D in trail._particles:
					particle.speed_scale = speed
	_clock(_gift_tween, speed)
	if _running and _gift_tween != null and _gift_tween.is_valid() and _gift_tween.is_running():
		var time: float = _gift_tween.get_total_elapsed_time()
		var phases: Array[String] = ["礼盒显出", "礼盒抬起", "礼盒停留", "礼盒飞入目标栏"]
		var phase: int = 3
		if time < JuiceGamePage.CUP_BLOOM_DUR:
			phase = 0
		elif time < JuiceGamePage.CUP_BLOOM_DUR + JuiceGamePage.CUP_FLY_RISE_DUR:
			phase = 1
		elif time < JuiceGamePage.CUP_BLOOM_DUR + JuiceGamePage.CUP_FLY_RISE_DUR + JuiceGamePage.CUP_FLY_HOLD_DUR:
			phase = 2
		if _stage != phases[phase]:
			_mark(phases[phase])
	if _game._quota != null:
		_clock(_game._quota._scroll_tween, speed)
		for tween: Tween in _game._quota._pop_tweens.values():
			_clock(tween, speed)
		for tweens: Array in _game._quota._ring_tweens.values():
			for tween: Tween in tweens:
				_clock(tween, speed)
	if _game._rank_bar != null:
		for tween: Tween in [_game._rank_bar._slide_tween, _game._rank_bar._float_tween, 
			_game._rank_bar._punch_tween, _game._rank_bar._icon_impact]:
			_clock(tween, speed)
	for player: AnimationPlayer in _players:
		if is_instance_valid(player):
			player.speed_scale = speed
	for particle: CPUParticles2D in _cpu:
		if is_instance_valid(particle):
			particle.speed_scale = speed
	for particle: GPUParticles2D in _gpu:
		if is_instance_valid(particle):
			particle.speed_scale = speed
	for tween: Tween in _rank._list._animation_tweens:
		_clock(tween, speed)
	if _rank._content_ready:
		for tween: Tween in [_rank._crown._fly_tween, _rank._crown._idle_tween, _rank._crown._land_tween, 
			_rank._podium._crown_glow_tween, _rank._rise_tip_tween, _rank._continue_tween, _rank._encourage_tween, _rank._scrim_tween]:
			_clock(tween, speed)
	for item: RankItemView in _items:
		if is_instance_valid(item):
			_clock(item._collect_punch_tween, speed)
	var total: float = _completed_time if _completed_time >= 0.0 else _elapsed
	_status.text = "%s · 阶段%.2fs / 总%.2fs · %.2fx\n局内 %d/%d  |  排行演出 %d/6" % [
		_stage, maxf(0.0, total - _stage_started), total, _speed, _game_arrivals, int(_settings.count), _rank_arrivals]

func _clock(tween: Tween, speed: float) -> void :
	if tween != null and tween.is_valid():
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_speed_scale(speed)

func _cache_clocks() -> void :
	_players.clear()
	_cpu.clear()
	_gpu.clear()
	_items.clear()
	for node: Node in _views.find_children("*", "AnimationPlayer", true, false):
		_players.append(node as AnimationPlayer)
	for node: Node in _views.find_children("*", "CPUParticles2D", true, false):
		_cpu.append(node as CPUParticles2D)
	for node: Node in _views.find_children("*", "GPUParticles2D", true, false):
		_gpu.append(node as GPUParticles2D)
	for node: Node in _rank.find_children("*", "Control", true, false):
		if node is RankItemView:
			_items.append(node as RankItemView)

func _disable_input(node: Node) -> void :
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children():
		_disable_input(child)

func replay() -> void :
	if not _opened:
		return
	stop()
	_settings = {"kind": _kind.selected, "count": _count.get_selected_id(), "mode": _mode.selected, "step": _step.selected, "rules": _rules.button_pressed}
	_paused = false
	_pause_button.text = "暂停"
	_elapsed = 0.0
	_completed_time = -1.0
	_game_arrivals = 0
	_rank_arrivals = 0
	_events.clear()
	_next_source_time = 0.0
	_cup_rect = Rect2()
	_gift_tween = null
	_views.modulate.a = 0.0
	_mark("准备正式场景（不计播放时间）")
	_run(_generation)

func _run(generation: int) -> void :
	var active: Callable = func() -> bool: return _valid(generation)
	var count: int = int(_settings.count)
	var step: int = int(_settings.step)
	var kind: int = int(_settings.kind)
	var mode: int = int(_settings.mode)
	if not await _game.prepare_rank_collectible_motion_preview(kind, count, bool(_settings.rules), active):
		if active.call():
			_mark("准备失败，可重新播放")
		return
	var texture: Texture2D = _game._skin_resources.active_skin.rank_collectible_elements[kind].texture
	var snapshots: Array[RankSnapshot] = make_snapshots(mode, count)
	var ctx: Dictionary = await _rank.prepare_motion_preview(snapshots[0], snapshots[1], count, texture, active)
	if ctx.is_empty() or not active.call():
		return
	if not _game._board.cup_collected.is_connected(_cup_collected):
		_game._board.cup_collected.connect(_cup_collected)
	if not _game._rank_fly.item_arrived.is_connected(_game_arrived):
		_game._rank_fly.item_arrived.connect(_game_arrived)
	if not _rank._list._collect_source_fx.item_arrived.is_connected(_rank_arrived):
		_rank._list._collect_source_fx.item_arrived.connect(_rank_arrived)
	_disable_input(_views)
	if not _game._rank_round.presentation_stage_changed.is_connected(_mark):
		_game._rank_round.presentation_stage_changed.connect(_mark)
	_cache_clocks()
	_rank.hide()
	_game.show()
	_views.modulate.a = 1.0
	_running = true
	_set_folded(true)
	if step in [0, 1]:
		_awaiting_cup = true
		_mark("局内收集物合成 → 收入礼盒")
		_game._board.motion_preview_speed = _speed
		if not _game._board.try_move(1, 0, 0):
			_mark("测试盘面未能完成移动")
			_running = false
			return
		while active.call() and _awaiting_cup:
			await get_tree().process_frame
		if not active.call():
			return
		if step == 1:
			while active.call() and _game._board.is_busy():
				await get_tree().process_frame
	elif step == 2:
		_cup_rect = _game.rank_motion_preview_rect()
		_start_gift(count - 1)
	if step in [0, 2]:
		while active.call() and _gift_tween != null and _gift_tween.is_valid() and _gift_tween.is_running():
			await get_tree().process_frame
		if not active.call():
			return
	if step in [3, 4]:
		_game.rank_motion_preview_fill_gift()
	if step in [0, 3]:
		_mark("礼盒飞出收集物 → 临时收集栏逐枚到账")
		_next_source_time = _elapsed
		await _game._rank_round.play_collect(_game, _source.bind(generation))
		if not active.call():
			return
	if step in [0, 4]:
		_mark("排行榜入场 → 收集与积分反馈")
		_game.hide()
		_rank.show()
		await _rank.play_show_presentation(ctx)
		if not active.call():
			return
		_mark("升位反馈 → 皇冠／激励 → 继续按钮")
		await _rank.finish_show_feedback(ctx)
		if not active.call():
			return
	_mark("播放完成")
	completed_runs += 1
	_completed_time = _elapsed

	await _wait_visual(1.5, generation)
	if not active.call():
		return
	if _loop.button_pressed:
		replay()

func _cup_collected(_type: int, nth: int, _color: Color, rect: Rect2) -> void :
	if not _running or not _awaiting_cup:
		return
	_cup_rect = rect
	_awaiting_cup = false
	if int(_settings.step) == 0:
		_start_gift(nth)

func _start_gift(slot: int) -> void :
	_mark("礼盒出现 → 抬起 → 停留 → 飞入真实目标位")
	_gift_tween = _game.play_rank_motion_preview_gift(_cup_rect, slot)
	_clock(_gift_tween, _speed)

func _source(index: int, generation: int) -> Vector2:


	while _valid(generation) and (_paused or _elapsed < _next_source_time):
		await get_tree().process_frame
	if not _valid(generation):
		return Vector2.ZERO
	_next_source_time = _elapsed + 0.08
	return await _game.rank_motion_preview_source(index)

func _wait_visual(seconds: float, generation: int) -> void :
	var until: float = _elapsed + seconds
	while _valid(generation) and _elapsed < until:
		await get_tree().process_frame

func _game_arrived(_index: int) -> void :
	if _running:
		_game_arrivals += 1

func _rank_arrived(_index: int) -> void :
	if _running:
		_rank_arrivals += 1

func _mark(stage: String) -> void :
	_stage = stage
	_stage_started = _elapsed
	_events.append("%.3fs %s" % [_elapsed, stage])

func _set_folded(folded: bool) -> void :
	_folded = folded
	for path: String in ["Kind", "Mode", "Options", "Notice"]:
		_panel.get_node("Margin/Rows/" + path).visible = not folded
	_fold_button.text = "展开" if folded else "收起"
	_panel.reset_size()
	_layout()

func _on_fold_pressed() -> void :
	_set_folded( not _folded)

func _on_pause_pressed() -> void :
	_paused = not _paused
	_pause_button.text = "继续" if _paused else "暂停"

func _on_speed_selected(index: int) -> void :
	_speed = [0.25, 0.5, 1.0][index]
	if _opened:
		replay()

func _valid(generation: int) -> bool:
	return _opened and visible and generation == _generation

func stop() -> void :
	_generation += 1
	_running = false
	_awaiting_cup = false
	_game.cancel_rank_motion_preview()
	_rank._on_hide()
	_stage = "已停止"

func close() -> void :
	SceneManager.hide_page("rank_collectible_flow_preview")

func _on_hide() -> void :
	stop()
	hide()
	set_process(false)
	_restore_pause()

func _on_back_request() -> void :
	close()

func _exit_tree() -> void :
	_restore_pause()

func _restore_pause() -> void :
	if _opened:
		_opened = false
		get_tree().paused = _previous_paused

static func make_snapshots(mode: int, count: int) -> Array[RankSnapshot]:
	var starts: Array[int] = [20, 20, 4, 2, 1]
	var ends: Array[int] = [20, 15, 3, 1, 1]
	var start: int = starts[mode]
	var finish: int = ends[mode]
	var snapshots: Array[RankSnapshot] = []
	for after: bool in [false, true]:
		var snap: = RankSnapshot.new()
		snap.event_id = "rank-collectible-motion-preview"
		snap.participant_count = 50
		snap.upgrade_end_rank = 15
		snap.downgrade_start_rank = 41
		for rank: int in range(1, 51):
			var me: bool = rank == start
			var score: int = 1000 + (count if after else 0) if me else (
				1100 + count - rank if rank < finish else (1001 if rank < start else 900 - rank))
			snap.rows.append({"is_me": me, "nickname": "Me" if me else "Bot%d" % rank, 
				"avatar_index": 1 if me else rank % 12 + 1, "collect_num": score, 
				"online_text_key": RankFakeUserGenerator.ONLINE_KEY_NOW})
		snap.rows.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.collect_num) > int(b.collect_num))
		for index: int in snap.rows.size():
			snap.rows[index].rank_pos = index + 1
			if snap.rows[index].is_me:
				snap.my_rank_pos = index + 1
				snap.my_collect_num = int(snap.rows[index].collect_num)
		snapshots.append(snap)
	return snapshots
