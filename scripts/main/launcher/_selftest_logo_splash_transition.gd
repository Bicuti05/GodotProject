extends SceneTree


var _failures: int = 0
var _manager: Variant
var _launcher: Node
var _step: Variant
var _watch: Dictionary = {}


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	if not ok:
		_failures += 1
	print("PASS: " if ok else "FAIL: ", label)


func _start_step(ctx: Variant, state: Dictionary) -> void :
	await _step.run(ctx)
	state.done = true


func _observe_frame() -> void :
	if _watch.is_empty():
		return
	var splash: Variant = _manager.get_page("splash")
	var logo: Variant = _manager.get_page("logo")
	if logo == null:
		return
	if logo.visible:
		_watch.timer_not_started = _watch.timer_not_started and _watch.context.splash_shown_msec == -1
	if splash == null:
		_watch.logo_held = _watch.logo_held and logo.visible and is_equal_approx(logo.modulate.a, 1.0)
		return
	if not splash.visible:
		_watch.hidden_frames += 1
		_watch.logo_held = _watch.logo_held and logo.visible and is_equal_approx(logo.modulate.a, 1.0)
		_watch.not_started = _watch.not_started and not splash._running
	elif logo.visible:
		if _watch.fade_started_msec < 0:
			_watch.fade_started_msec = Time.get_ticks_msec()
		var tween: Tween = logo.get("_fade_tween") as Tween
		if tween != null:
			_watch.fade_tween = tween
			var expected_alpha: float = maxf(1.0 - tween.get_total_elapsed_time() / 0.4, 0.0)
			_watch.alpha_matches_time = _watch.alpha_matches_time and is_equal_approx(logo.modulate.a, expected_alpha)
		_watch.order_correct = _watch.order_correct\
		and (splash.get_parent() as CanvasLayer).layer < (logo.get_parent() as CanvasLayer).layer
		_watch.alpha_monotonic = _watch.alpha_monotonic and logo.modulate.a <= _watch.last_alpha + 1e-05
		_watch.last_alpha = logo.modulate.a


func _transition(label: String) -> void :
	var ctx: Variant = load("res://scripts/main/launcher/flow/launcher_flow_context.gd").new(_launcher)
	ctx.logo_page = _manager.show_page("logo")
	var state: Dictionary = {"done": false}
	_watch = {"hidden_frames": 0, "logo_held": true, "not_started": true, 
		"order_correct": true, "alpha_monotonic": true, "last_alpha": 1.0, "fade_started_msec": -1, 
		"fade_tween": null, "alpha_matches_time": true, 
		"context": ctx, "timer_not_started": true}

	await create_timer(0.02).timeout
	ctx.splash_shown_msec = 1
	_start_step(ctx, state)
	_check( not state.done and ctx.logo_page.visible and ctx.logo_page.modulate.a == 1.0, 
		label + "等待期间 Logo 完整展示，Flow 未放行")
	var deadline: int = Time.get_ticks_msec() + 3000
	while _manager.get_page("splash") == null and Time.get_ticks_msec() < deadline:
		await process_frame
	var splash: Variant = _manager.get_page("splash")
	_check(splash != null and not splash.visible and not splash._running, 
		label + "线程资源就绪后 Splash 完整隐藏准备且未启动进度")
	while not state.done and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(state.done, label + "转场正常结束")
	_check(_watch.hidden_frames >= 2 and _watch.logo_held and _watch.not_started, 
		label + "至少两个帧边界内保持隐藏，不提前启动 Splash 或渐隐 Logo")
	_check(_watch.order_correct and _watch.alpha_monotonic, 
		label + "渐隐期间页序正确且 Logo alpha 单调下降")

	var tween: Tween = _watch.fade_tween as Tween
	print("LOGO_FADE_SAMPLE: ", label, "observed_wall_ms=", Time.get_ticks_msec() - _watch.fade_started_msec, 
		" tween_elapsed_ms=", tween.get_total_elapsed_time() * 1000.0 if tween != null else -1)
	_check(_step.get_script().get_script_constant_map().get("_LOGO_FADE_DURATION_SECONDS") == 0.4
		and tween != null and tween.get_total_elapsed_time() >= 0.4 and _watch.alpha_matches_time, 
		label + "Logo渐隐为0.4秒，alpha与Tween累计时间一致")
	_check(splash.visible and splash._running and not ctx.logo_page.visible
		and is_zero_approx(ctx.logo_page.modulate.a), label + "收尾仅 Splash 可见且进度已启动")
	_check(_watch.timer_not_started and ctx.splash_shown_msec >= _watch.fade_started_msec
		and ctx.splash_shown_msec <= Time.get_ticks_msec(), 
		label + "Logo隐藏前不计时，完全隐藏后才记录Splash展示起点")
	_watch = {}
	_manager.hide_page("splash")


func _run() -> void :
	_manager = root.get_node("SceneManager")
	_launcher = Node.new()
	_launcher.name = "LauncherTransitionTest"
	root.add_child(_launcher)
	current_scene = _launcher
	_step = load("res://scripts/main/launcher/flow/show_splash_step.gd").new()
	process_frame.connect(_observe_frame)
	await _transition("首次创建：")
	var cached: Variant = _manager.get_page("splash")
	await _transition("缓存复用：")
	_check(_manager.get_page("splash") == cached, "两次转场复用同一 Splash 实例")
	var ctx: Variant = load("res://scripts/main/launcher/flow/launcher_flow_context.gd").new(_launcher)
	var state: Dictionary = {"done": false}
	var shown_before_msec: int = Time.get_ticks_msec()
	_start_step(ctx, state)
	while not state.done:
		await process_frame
	_check(ctx.splash_page == cached and cached.visible and cached._running, 
		"无 Logo 时完成隐藏准备后直接显示 Splash，不启动渐隐")
	_check(ctx.splash_shown_msec >= shown_before_msec and ctx.splash_shown_msec <= Time.get_ticks_msec(), 
		"无Logo时从Splash显示开始计时")
	_manager.hide_page("splash")
	ctx.logo_page = _manager.show_page("logo")
	state = {"done": false}
	_start_step(ctx, state)
	_check(ctx.splash_shown_msec == -1, "再次转场清除上次Splash计时")
	await process_frame
	ctx.logo_page.free()
	shown_before_msec = Time.get_ticks_msec()
	while not state.done:
		await process_frame
	_check(state.done and ctx.splash_page == cached and cached.visible, 
		"隐藏准备期间 Logo 被释放时安全显示 Splash，不挂住 Flow")
	_check(ctx.splash_shown_msec >= shown_before_msec and ctx.splash_shown_msec <= Time.get_ticks_msec(), 
		"等待中Logo释放时从Splash显示开始计时")
	_manager.hide_page("splash")
	process_frame.disconnect(_observe_frame)
	print("LOGO_SPLASH_RESULT: %d failures" % _failures)
	quit(0 if _failures == 0 else 1)
