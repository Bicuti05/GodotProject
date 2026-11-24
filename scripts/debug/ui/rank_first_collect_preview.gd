extends PageScene

@onready var _page: RankGameFinishPage = $Preview
@onready var _panel: PanelContainer = $Panel
@onready var _mode: OptionButton = $Panel / Margin / Rows / Mode
@onready var _speed_choice: OptionButton = $Panel / Margin / Rows / Options / Speed
@onready var _delta: SpinBox = $Panel / Margin / Rows / Options / Delta
@onready var _loop: CheckButton = $Panel / Margin / Rows / Options / Loop
@onready var _pause_button: Button = $Panel / Margin / Rows / Buttons / Pause
@onready var _status: Label = $Panel / Margin / Rows / Status

var _generation: int = 0
var _opened: bool = false
var _previous_paused: bool = false
var _paused: bool = false
var _speed: float = 1.0
var _elapsed: float = 0.0
var _stage: String = "准备中"
var _arrivals: int = 0
var _events: Array[String] = []
var _players: Array[AnimationPlayer] = []
var _particles: Array[CPUParticles2D] = []
var _items: Array[RankItemView] = []
var _running: bool = false
var completed_runs: int = 0


func _ready() -> void :
	_mode.add_item("已是第一名：收集 → 扫光粒子 → 大皇冠下砸")
	_mode.add_item("第二名：收集 → 升到第一 → 皇冠飞入")
	_mode.add_item("只看第一名收集与图标回弹")
	_mode.add_item("已是第二名：收集 → 扫光粒子（无皇冠动效）")
	_mode.add_item("已是第三名：收集 → 扫光粒子（无皇冠动效）")
	for text: String in ["0.25倍", "0.5倍", "正常", "2倍"]:
		_speed_choice.add_item(text)
	_speed_choice.select(2)
	_disable_preview_input(_page)
	get_viewport().size_changed.connect(_layout)
	_page.collect_feedback_stage.connect(_mark)
	_layout()
	hide()
	set_process(false)
	call_deferred("_open_standalone")


func _open_standalone() -> void :
	if get_tree().current_scene == self:
		if not OS.has_feature("mobile") and not OS.has_feature("android") and not OS.has_feature("ios"):
			var usable: Rect2i = DisplayServer.screen_get_usable_rect()
			var unit: int = maxi(1, mini(45, mini((usable.size.y - 80) / 26, (usable.size.x - 40) / 12)))
			var window: Window = get_window()
			window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			window.unresizable = true
			window.size = Vector2i(unit * 12, unit * 26)
			window.position = usable.position + (usable.size - window.size) / 2
		_on_show()


func _disable_preview_input(node: Node) -> void :
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		(node as Control).focus_mode = Control.FOCUS_NONE
	for child: Node in node.get_children():
		_disable_preview_input(child)


func _layout() -> void :
	var view: Vector2 = UiMetrics.viewport_size()
	_panel.position = Vector2(24.0, view.y - UiMetrics.safe_insets().y - _panel.size.y - 24.0)
	_panel.size.x = view.x - 48.0


func _on_show(params: Dictionary = {}) -> void :
	_generation += 1
	var generation: int = _generation
	if not _opened:
		_previous_paused = get_tree().paused
		_opened = true
	get_tree().paused = true
	show()
	set_process(true)
	_stage = "准备榜单"
	var ready_ui: bool = await _page.prepare_content( func() -> bool: return _valid(generation))
	if not ready_ui or not _valid(generation):
		return
	if not await _page._list.prepare_animation( func() -> bool: return _valid(generation)):
		return
	if not _page._list._collect_source_fx.item_arrived.is_connected(_on_arrived):
		_page._list._collect_source_fx.item_arrived.connect(_on_arrived)
	_disable_preview_input(_page)
	_cache_clocks()
	_layout()
	if bool(params.get("auto_play", true)):
		replay()
	else:
		if not await _reset_scene(make_snapshot(1)):
			return
		_stage = "就绪"


func _cache_clocks() -> void :
	_players.clear()
	_particles.clear()
	_items.clear()
	for node: Node in _page.find_children("*", "AnimationPlayer", true, false):
		_players.append(node as AnimationPlayer)
	for node: Node in _page.find_children("*", "CPUParticles2D", true, false):
		_particles.append(node as CPUParticles2D)
	for node: Node in _page.find_children("*", "Control", true, false):
		if node is RankItemView:
			_items.append(node as RankItemView)


func _process(delta: float) -> void :
	if not _page._content_ready:
		return
	var speed: float = 0.0 if _paused else _speed
	if _running:
		_elapsed += delta * speed
	for player: AnimationPlayer in _players:
		player.speed_scale = speed
	for particle: CPUParticles2D in _particles:
		particle.speed_scale = speed
	for tween: Tween in _page._list._animation_tweens:
		_set_speed(tween, speed)
	for tween: Tween in [_page._crown._fly_tween, 
		_page._crown._idle_tween, _page._crown._land_tween, 
		_page._podium._crown_glow_tween, _page._rise_tip_tween, _page._continue_tween, _page._scrim_tween]:
		_set_speed(tween, speed)
	for item: RankItemView in _items:
		_set_speed(item._collect_punch_tween, speed)
	var item: RankItemView = _page._list.find_my_item()
	var score: int = item.get_collect_num_display() if item != null else 0
	_status.text = "%s · %.3fs · 到达 %d/6 · 显示积分 %d\n%s" % [
		_stage, _elapsed, _arrivals, score, "\n".join(_events.slice(maxi(0, _events.size() - 3)))]


func _set_speed(tween: Tween, speed: float) -> void :
	if tween != null and tween.is_valid():
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_speed_scale(speed)


func _reset_scene(snap: RankSnapshot) -> bool:
	_page._on_hide()
	var generation: int = _generation
	await _page._list.prepare_first_screen(snap, snap.my_rank_pos, func() -> bool: return _valid(generation))
	if not await _page._list.prepare_animation( func() -> bool: return _valid(generation)):
		return false
	_disable_preview_input(_page)
	_cache_clocks()
	_page._update_scroll_fade()
	_page._list.end_enter_mask()
	_page.show()
	_page._start_scrim_fade()
	_page._clock.hide()
	_page._continue_btn.hide()
	_page._list.set_drag_enabled(false)
	_page._list.scroll_rank_to_center(snap.my_rank_pos)
	if snap.my_rank_pos == 1:
		_page._attach_resting_crown()
	return true


func replay() -> void :
	if not _opened:
		return
	stop()
	var generation: int = _generation
	_paused = false
	_pause_button.text = "暂停"
	_elapsed = 0.0
	_arrivals = 0
	_events.clear()
	var start_rank: int = 3 if _mode.selected == 4 else (2 if _mode.selected in [1, 3] else 1)
	var stay_rank: bool = _mode.selected in [3, 4]
	var before: RankSnapshot = make_snapshot(start_rank, 0, stay_rank)
	var after: RankSnapshot = make_snapshot(start_rank, int(_delta.value), stay_rank)
	if not await _reset_scene(before) or not _valid(generation):
		return
	_running = true
	_mark("收集开始")
	var item: RankItemView = _page._list.find_my_item()

	await RankListCollectAnim.play(_page._list, _page._list._collect_source_fx, item, 
		item._collect_icon.texture, int(_delta.value), before.my_collect_num, after.my_collect_num)
	if not _valid(generation):
		return
	_mark("收集结束")
	if _mode.selected != 2:
		await _page.play_post_collect_feedback(before, after)
		if not _valid(generation):
			return
		await _page._show_rise_tip(_page._resolve_finish_tip({}, before, after), _page._generation)
		if not _valid(generation):
			return
		if before.my_rank_pos != 1 and after.my_rank_pos == 1:
			_mark("皇冠飞入")
			_page._podium.set_first_crown_visible(false)
			await _page._crown.play_fly_in(_page._list.find_my_item())
			if not _valid(generation):
				return
		_page._continue_btn.show()
		_page._continue_btn.modulate.a = 0.0
		_page._reveal_continue()
	_mark("播放完成")
	_running = false
	completed_runs += 1
	if _loop.button_pressed:
		var remaining: float = 0.8
		while _valid(generation) and (remaining > 0.0 or _has_sweep_tail()):
			await get_tree().process_frame
			remaining -= get_process_delta_time() * (0.0 if _paused else _speed)
		if _valid(generation) and _loop.button_pressed:
			replay()


func _has_sweep_tail() -> bool:
	for sweep: RankPodiumSweepFx in _page._podium._sweeps:
		if sweep.visible:
			return true
	return false


func _mark(stage: String) -> void :
	_stage = stage
	_events.append("%.3fs  %s" % [_elapsed, stage])


func _on_arrived(index: int) -> void :
	if _running:
		_arrivals += 1
		_events.append("%.3fs  花朵%d到达" % [_elapsed, index + 1])


func stop() -> void :
	_generation += 1
	_running = false
	_page._generation += 1
	_page._list.cancel_animations()
	_page._crown.hide_crown()
	_page._hide_rise_tip()
	if _page._continue_tween != null and _page._continue_tween.is_valid():
		_page._continue_tween.kill()
	_stage = "已停止"


func _on_pause_pressed() -> void :
	_paused = not _paused
	_pause_button.text = "继续" if _paused else "暂停"


func _on_speed_selected(index: int) -> void :
	_speed = [0.25, 0.5, 1.0, 2.0][index]


func _on_mode_selected(_index: int) -> void :
	if _opened:
		replay()


func _valid(generation: int) -> bool:
	return _opened and visible and generation == _generation


func close() -> void :
	if get_tree().current_scene == self:
		_on_hide()
		get_tree().quit()
	else:
		SceneManager.hide_page("rank_first_collect_preview")


func _on_hide() -> void :
	stop()
	_page._on_hide()
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


static func make_snapshot(start_rank: int, delta: int = 0, stay_rank: bool = false) -> RankSnapshot:
	var snap: RankSnapshot = RankSnapshot.new()
	snap.event_id = "rank-first-collect-preview"
	snap.participant_count = 50
	snap.upgrade_end_rank = 15
	snap.downgrade_start_rank = 41
	var bot: int = 0
	for rank: int in range(1, 51):
		var is_me: bool = rank == start_rank
		if not is_me:
			bot += 1
		snap.rows.append({"is_me": is_me, "nickname": "Me" if is_me else "Bot%d" % bot, 
			"avatar_index": 1 if is_me else bot % 12 + 1, 
			"collect_num": 400 - rank if stay_rank and rank < start_rank else 200 - rank + (delta if is_me else 0), 
			"online_text_key": RankFakeUserGenerator.ONLINE_KEY_NOW})
	snap.rows.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.collect_num) != int(b.collect_num):
			return int(a.collect_num) > int(b.collect_num)
		return not bool(a.is_me) and bool(b.is_me))
	for index: int in snap.rows.size():
		snap.rows[index].rank_pos = index + 1
		if bool(snap.rows[index].is_me):
			snap.my_rank_pos = index + 1
			snap.my_collect_num = int(snap.rows[index].collect_num)
	return snap
