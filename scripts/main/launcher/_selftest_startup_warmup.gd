extends SceneTree

var _failures: Array[String] = []
var _second_finished: bool = false

class DelayedAuthStep extends FlowStep:
	var finished: bool = false
	func is_blocking() -> bool:
		return false
	func run(ctx) -> void :
		ctx.auth_started = true
		await ctx.launcher.get_tree().create_timer(0.12).timeout
		finished = true
		ctx.auth_finished = true

class OverlapProbeStep extends FlowStep:
	func run(ctx) -> void :
		ctx.overlapped = ctx.auth_started and not ctx.auth_finished
		await ctx.launcher.get_tree().process_frame

class InitWaitOverlapProbe extends FlowStep:
	func run(ctx) -> void :
		ctx.work_started_msec = Time.get_ticks_msec()
		await ctx.launcher.get_tree().create_timer(0.15).timeout
		ctx.work_finished_msec = Time.get_ticks_msec()

class InitWaitBarrierProbe extends WaitLogoReadyStep:
	func run(ctx) -> void :
		ctx.joined_msec = Time.get_ticks_msec()

class WarmOrderProbeStep extends FlowStep:
	func run(ctx) -> void :
		ctx.warm_before_splash = ctx.warm_before_splash and (ctx.logo_visible or ctx.splash_started)
		ctx.overlapped = ctx.overlapped or (ctx.auth_started and not ctx.auth_finished)
		await ctx.launcher.get_tree().process_frame
		ctx.warm_count += 1

class GpuOrderProbeStep extends WarmOrderProbeStep:
	func run(ctx) -> void :
		ctx.gpu_at_logo = ctx.logo_visible and not ctx.splash_started
		await super.run(ctx)

class SplashWorkOrderProbeStep extends FlowStep:
	var kind: String
	func _init(p_kind: String) -> void :
		kind = p_kind
	func run(ctx) -> void :
		ctx.work_in_splash = ctx.work_in_splash and ctx.splash_started and not ctx.logo_visible
		ctx.overlapped = ctx.overlapped or (ctx.auth_started and not ctx.auth_finished)
		ctx.splash_work.append(kind)
		if kind in ["WarmPages", "WarmAudio", "WarmFinishRender"]:
			ctx.warm_count += 1
		await ctx.launcher.get_tree().process_frame

class LogoOrderProbeStep extends FlowStep:
	func run(ctx) -> void :
		ctx.logo_visible = true

class SplashOrderProbeStep extends FlowStep:
	func run(ctx) -> void :
		ctx.warm_count_at_splash = ctx.warm_count
		ctx.splash_started = true
		ctx.logo_visible = false
		await ctx.launcher.get_tree().process_frame

class AuthOrderProbeStep extends DelayedAuthStep:
	func run(ctx) -> void :
		ctx.warm_count_at_auth = ctx.warm_count
		ctx.auth_after_splash = ctx.splash_started and not ctx.logo_visible
		await super.run(ctx)

class LauncherProbe extends Node:
	var completed_after_auth: bool = false
	var splash_complete_msec: int = -1
	var context: Dictionary
	func wait_splash_complete(_splash) -> void :
		completed_after_auth = context.auth_finished
		splash_complete_msec = Time.get_ticks_msec()

class CancelledDb extends "res://scripts/common/db/db_manager.gd":
	func _resolve_db_path() -> String:
		return "res://cancelled.db"

class InvalidDb extends "res://scripts/common/db/db_manager.gd":
	func _resolve_db_path() -> String:
		return "res://migration_failure.db"

class QuietFailureContext extends LauncherFlowContext:
	func fail_startup(_message: String) -> void :
		startup_failed = true

class ControlledAuth extends EditorAuth:
	var events: Array[String] = []
	var cmp_finished: bool = false
	var cmp_sync: bool = false
	var allow_att: bool = false
	var allow_push: bool = false
	var push_finished: bool = false
	var probe_type: int = 0
	func check_privacy_required() -> bool:
		return false
	func check_cmp() -> void :
		events.append("cmp_started")
		if cmp_sync:
			finish_cmp()
	func finish_cmp() -> void :
		cmp_finished = true
		cmp_completed.emit()
	func can_show_att() -> bool:
		events.append("att_checked")
		return allow_att
	func show_att_alert(_source: String) -> void :
		events.append("att_shown")
		att_status_changed.emit.call_deferred(UniKit.ATT_STATUS_AUTHORIZED)
	func can_request_permission(type: int = 2) -> bool:
		probe_type = type
		return allow_push
	func request_push_permission() -> void :
		events.append("push_requested")
		(Engine.get_main_loop() as SceneTree).create_timer(0.05).timeout.connect( func() -> void :
			push_finished = true
			events.append("push_finished")
			push_permission_done.emit()
		)
	func set_push_enabled(_enabled: bool) -> void :
		events.append("push_enabled")

class AuthProbe extends "res://scripts/data/auth/auth_manager.gd":
	var module: ControlledAuth = ControlledAuth.new()
	func _ready() -> void :
		_bind_signals(module, module, "（自测）")
	func _auth_module() -> Variant:
		return module
	func _push_module() -> Variant:
		return module

class AuthStartStep extends FlowStep:
	func is_blocking() -> bool:
		return false
	func run(ctx) -> void :
		ctx.auth_started = true
		await ctx.auth.initialize()
		ctx.auth_finished = true

func _run() -> void :
	var launcher: = LauncherProbe.new()
	root.add_child(launcher)
	current_scene = launcher
	if AudioManager.get("_sfx_streams").keys() != [&"button_click"]:
		_failures.append("首屏前同步加载了非按钮音效")
	AudioManager.play_sfx(&"button_click")
	if AudioManager.get("_sfx_players")[0].stream != AudioManager.get("_BUTTON_CLICK_STREAM"):
		_failures.append("提前按钮点击音不可用")
	AudioManager.stop_all_sfx()

	await RequestWarmPagesStep.new().run({"launcher": launcher})
	SceneManager.request_page_threaded("splash")
	SceneManager.request_page_threaded("privacy")
	if not SceneManager.get("_page_load_started_usec").is_empty():
		_failures.append("启动不应线程请求Splash和隐私页面")
	SceneManager.warm_page("splash")
	SceneManager.warm_page("privacy")
	var splash: SplashPage = SceneManager.get_page("splash") as SplashPage
	if splash == null or splash.visible or splash.get("_running"):
		_failures.append("完整Splash未隐藏准备或提前启动了进度")
	SceneManager.request_page_threaded("home")
	_second_warm_home()
	await SceneManager.warm_page_threaded("home")
	while not _second_finished:
		await process_frame
	await WarmPagesStep.new().run({"launcher": launcher, "initial_page": "home"})
	for page_name: String in ["home", "privacy"]:
		var page: CanvasItem = SceneManager.get_page(page_name)
		if page == null or not page.is_inside_tree() or page.visible:
			_failures.append("页面未完整隐藏预热: " + page_name)
	for route: String in ["game", "finish"]:
		if SceneManager.get_page(route) != null:
			_failures.append("首页首屏提前创建另一页: " + route)
	for route: String in ["rank", "rank_game_finish"]:
		if SceneManager.get_page(route) != null or ResourceLoader.has_cached(SceneManager.PAGE_SCENES[route]):
			_failures.append("启动不应请求或创建排行榜UI: " + route)
	var home: Node = SceneManager.get_page("home")
	await SceneManager.warm_page_threaded("home")
	if SceneManager.get_page("home") != home:
		_failures.append("同页重复预热未复用实例")
	var privacy: Node = SceneManager.get_page("privacy")
	if privacy != null:
		if SceneManager.show_dlg("privacy") != privacy:
			_failures.append("隐私弹窗展示未复用预热实例")
		SceneManager.hide_page("privacy")
		await process_frame
	if not SceneManager.get("_page_load_started_usec").is_empty() or not SceneManager.get("_warming_pages").is_empty():
		_failures.append("线程请求或预热未清理")
	await WarmAudioStep.new().run(null)
	await AudioManager.warm_startup_resources()
	var streams: Dictionary = AudioManager.get("_sfx_streams")
	if streams.size() != AudioManager.SFX_PATHS.size() or not AudioManager.get("_sfx_load_requests").is_empty():
		_failures.append("全部音效未加载或请求未清理")
	for id: StringName in AudioManager.SFX_PATHS:
		if not streams.get(id) is AudioStream or not AudioManager.SFX_CONFIG.has(id):
			_failures.append("音效资源或配置缺失: " + id)
	AudioManager.play_sfx(&"finish_reward", 1.25, 0.8)
	AudioManager.play_sfx(&"finish_reward", 1.25, 0.8)
	if AudioManager.call("_playing_count", &"finish_reward") != 1:
		_failures.append("同ID达并发上限后的重播行为回归")
	var player: AudioStreamPlayer = AudioManager.get("_sfx_players")[0]
	if player.bus != &"SFX" or not is_equal_approx(player.pitch_scale, 0.8) or not is_equal_approx(player.volume_db, linear_to_db(1.25)):
		_failures.append("音效音调、音量或Bus回归")
	AudioManager.stop_all_sfx()
	AudioManager.set_sfx_enabled(false)
	AudioManager.play_sfx(&"juice_pick")
	if AudioManager.call("_playing_count", &"juice_pick") != 0:
		_failures.append("音效关闭后仍播放")
	AudioManager.set_sfx_enabled(true)

	ABManager.initialize_for_editor()

	await process_frame
	var hold_started_msec: int = Time.get_ticks_msec()
	var logo_ctx: Dictionary = {"launcher": launcher, "logo_shown_msec": hold_started_msec}
	await FlowRunner.new([AwaitAbtestReadyStep.new(), InitWaitOverlapProbe.new(), InitWaitBarrierProbe.new()] as Array[FlowStep]).run(logo_ctx)
	print("LOGO_HOLD_SAMPLE: elapsed_ms=", Time.get_ticks_msec() - hold_started_msec)

	if AwaitAbtestReadyStep.LOGO_HOLD_SECONDS != 1.6 or Time.get_ticks_msec() - hold_started_msec < 1566:
		_failures.append("Logo最短1.6秒展示被缩短")
	if logo_ctx.work_finished_msec > logo_ctx.joined_msec or logo_ctx.work_started_msec - hold_started_msec < 1566:
		_failures.append("数据准备应在共同 AB/Logo 等待完成后开始")

	var ctx: Dictionary = {"launcher": launcher, "splash_page": null, 
		"auth_started": false, "auth_finished": false, "overlapped": false}
	launcher.context = ctx
	await FlowRunner.new([DelayedAuthStep.new(), OverlapProbeStep.new(), WaitSplashCompleteStep.new()] as Array[FlowStep]).run(ctx)
	if not ctx.overlapped or not launcher.completed_after_auth or PrivacyCmpAttStep.new().is_blocking():
		_failures.append("必要权限并发模式或Splash汇合屏障失效")
	await _test_splash_min_display(launcher)
	await _test_privacy_warmup_order(launcher)
	await _test_cmp_detached(launcher)
	await _test_work_progress(launcher)
	await _test_logo_gpu_guard(launcher)
	await _test_rank_startup_worker(launcher)
	if _failures.is_empty():
		print("PASS: startup concurrent requests, cached pages, required auth barrier and detached CMP/ATT")
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)

class DelayedProgressStep extends FlowStep:
	var heartbeat: int = 0
	func run(ctx) -> void :
		var report: Callable = ctx.progress_callback()
		report.call(0.5)
		for _frame in range(8):
			await ctx.launcher.get_tree().process_frame
			heartbeat += 1


func _test_work_progress(launcher: LauncherProbe) -> void :
	var ctx: = LauncherFlowContext.new(launcher)
	ctx.splash_page = SceneManager.show_page("splash") as SplashPage
	ctx.begin_stage("delayed_load", 20.0, 45.0)
	var stale: Callable = ctx.progress_callback()
	stale.call(0.5)
	await ctx.splash_page.wait_loading_progress(32.5, ctx.splash_page.get_progress_generation())
	for _frame in range(8):
		await process_frame
	_rope_check(is_equal_approx(ctx.splash_page._current_progress, 0.325), "进度停在真实完成值，不随时间越界")
	var age: float = ctx.splash_page._butterfly_age
	await process_frame
	_rope_check(ctx.splash_page._butterfly_age > age, "资源等待期间蝴蝶时钟继续推进")
	await ctx.finish_stage()
	ctx.begin_stage("audio", 45.0, 55.0)
	stale.call(1.0)
	_rope_check(is_equal_approx(ctx.splash_page._target_progress, 0.45), "旧阶段回调不能推进新阶段")
	var failed_ctx: = LauncherFlowContext.new(launcher)
	failed_ctx.splash_page = ctx.splash_page
	failed_ctx.begin_stage("required", 45.0, 55.0)

	failed_ctx.startup_failed = true
	await FlowRunner.new([StartupProgressStep.new(DelayedProgressStep.new(), 55.0, 70.0), 
		WaitSplashCompleteStep.new(), RouteInitialPageStep.new()] as Array[FlowStep]).run(failed_ctx)
	_rope_check(ctx.splash_page._current_progress < 1.0 and not ctx.splash_page._completed, 
		"必要工作失败不执行收尾或路由")
	var generation: int = ctx.splash_page.get_progress_generation()
	SceneManager.hide_page("splash")
	ctx.splash_page = SceneManager.show_page("splash") as SplashPage
	ctx.splash_page.begin_loading_stage("new_session", 0.0, 5.0, ctx.splash_page.get_progress_generation())
	ctx.splash_page.set_loading_progress(99.0, generation)
	_rope_check(ctx.splash_page._target_progress == 0.0 and not ctx.is_startup_active(), 
		"缓存重播复位且拒绝旧展示进度")
	_rope_check( not RouteInitialPageStep.new().should_run(ctx), "缓存重播后旧流程不能路由首屏")
	var wrapper_ctx: = LauncherFlowContext.new(launcher)
	wrapper_ctx.splash_page = ctx.splash_page
	var delayed: = DelayedProgressStep.new()
	await StartupProgressStep.new(delayed, 0.0, 5.0).run(wrapper_ctx)
	_rope_check(delayed.heartbeat == 8 and is_equal_approx(ctx.splash_page._current_progress, 0.05), 
		"异步工作持续让帧且包装器等实际完成后抵达边界")
	var auth: = AuthProbe.new()
	root.add_child(auth)
	var stages: Array[String] = []
	await auth.initialize( func(stage: String, completed: bool) -> void :
		stages.append(stage + (":done" if completed else ":begin"))
	)
	_rope_check(stages == ["privacy:begin", "privacy:done", "push:begin", "push:done", "cmp:begin", "cmp:done"], 
		"权限子阶段按真实顺序报告，CMP完成回调不参与进度")
	auth.module.finish_cmp()
	_rope_check(stages.size() == 6, "晚到CMP不会改写已完成的启动进度")
	auth.free()
	SceneManager.hide_page("splash")


func _test_logo_gpu_guard(launcher: LauncherProbe) -> void :
	var ctx: = LauncherFlowContext.new(launcher)
	ctx.logo_page = SceneManager.show_page("logo") as LogoPage
	ctx.begin_logo_stage("guard_test")
	_rope_check(ctx.is_logo_preparation_active() and not ctx.is_startup_active(), 
		"Logo准备不依赖Splash，且不能放宽Splash代次守卫")
	_rope_check( not ShowSplashStep.new().should_run(ctx), "GPU预绘未完成不能交接Splash")
	ctx.gpu_ready = true
	_rope_check(ShowSplashStep.new().should_run(ctx), "GPU准备完成允许交接")
	ctx.startup_failed = true
	await FlowRunner.new([ShowSplashStep.new(), PrivacyCmpAttStep.new(), 
		WaitSplashCompleteStep.new(), RouteInitialPageStep.new()] as Array[FlowStep]).run(ctx)
	_rope_check(ctx.splash_page == null and not ctx.auth_ready and ctx.logo_page.visible, 
		"Logo准备失败不显示Splash、不请求权限、不路由")
	ctx.startup_failed = false
	SceneManager.hide_page("logo")
	_rope_check( not ctx.is_logo_preparation_active() and not ShowSplashStep.new().should_run(ctx), 
		"隐藏Logo取消旧准备及交接")
	if DisplayServer.get_name() == "headless":
		ctx.logo_page = SceneManager.show_page("logo") as LogoPage
		ctx.gpu_ready = false
		await WarmStartupGpuStep.new().run(ctx)
		_rope_check(ctx.gpu_ready and not FinishParticleCache._render_ready
			and not is_instance_valid(GameEffectsPreparer._startup_board), 
			"Headless跳过GPU绘制且不写真实预绘状态")
		SceneManager.hide_page("logo")


func _test_rank_startup_worker(launcher: LauncherProbe) -> void :
	UserState.set("_rank_unlocked", true)
	UserState.set("_rank_current_entity", {})
	UserState.set("_rank_disabled", false)
	var ready: bool = await RankManager.prepare_startup_session( func() -> bool: return is_instance_valid(launcher))
	var entity: Dictionary = UserState.get_rank_current_entity()
	_rope_check(ready and entity.get("bots", []).size() == RankManager.BOT_COUNT, "异步启动生成完整赛季并持久化")
	var expected: Dictionary = RankSnapshotBuilder.create_entity(String(entity.event_id), int(entity.start_time), 
		int(entity.end_time), int(entity.start_tier), RankManager.BOT_COUNT)
	_rope_check(entity == expected, "工作线程与同步生成保留相同机器人、种子和赛季规则")
	_rope_check( await RankManager.prepare_startup_session( func() -> bool: return is_instance_valid(launcher))
		and UserState.get_rank_current_entity() == entity, "已有赛季启动复用，不重复生成")

func _test_splash_min_display(launcher: LauncherProbe) -> void :
	var splash: SplashPage = SceneManager.show_page("splash") as SplashPage
	for elapsed_msec: int in [0, 1500, 2500]:
		var started_msec: int = Time.get_ticks_msec()
		var ctx: Dictionary = {"launcher": launcher, "splash_page": splash, 
			"splash_shown_msec": started_msec - elapsed_msec, "auth_finished": true}
		launcher.context = ctx
		launcher.splash_complete_msec = -1
		await WaitSplashCompleteStep.new().run(ctx)
		var waited_msec: int = launcher.splash_complete_msec - started_msec
		print("SPLASH_HOLD_SAMPLE: prior_elapsed_ms=", elapsed_msec, " waited_ms=", waited_msec, 
			" total_ms=", launcher.splash_complete_msec - ctx.splash_shown_msec)
		_rope_check(launcher.splash_complete_msec - ctx.splash_shown_msec >= 2000, 
			"Splash未满2秒不能收尾")
		_rope_check(waited_msec <= maxi(2000 - elapsed_msec, 0) + 250, 
			"只补足Splash剩余时间，已满2秒不额外等待")
	SceneManager.hide_page("splash")

func _test_privacy_warmup_order(launcher: LauncherProbe) -> void :
	var original_first_session: bool = UserState.is_first_session()
	for first_session: bool in [true, false]:
		UserState.set("_first_session_runtime", first_session)
		var ctx: Dictionary = {"launcher": launcher, "splash_page": null, 
			"auth_started": false, "auth_finished": false, "overlapped": false, 
			"warm_count": 0, "warm_count_at_auth": -1, "warm_count_at_splash": -1, 
			"logo_visible": false, "splash_started": false, "warm_before_splash": true, 
			"auth_after_splash": false, "gpu_at_logo": false, "work_in_splash": true, "splash_work": []}
		launcher.context = ctx
		var probes: Array[FlowStep] = []
		var auth_count: int = 0
		var steps: Array[FlowStep] = LauncherFlow._build_prefix() + LauncherFlow._build_steps()
		_rope_check(steps.size() == 24 and steps[0] is ConsumeFirstSessionStep
			and steps[2] is ShowLogoStep and steps[-1] is RouteInitialPageStep, 
			"所有启动保留完整启动序列")
		for wrapped: FlowStep in steps:
			var step: FlowStep = wrapped.step if wrapped is StartupProgressStep else wrapped
			if step is ShowLogoStep:
				probes.append(LogoOrderProbeStep.new())
			elif step is ShowSplashStep:
				probes.append(SplashOrderProbeStep.new())
			elif step is PrivacyCmpAttStep:
				probes.append(AuthOrderProbeStep.new())
				auth_count += 1
			elif step is WarmStartupGpuStep:
				probes.append(GpuOrderProbeStep.new())
			elif step is InitDataStep or step is LoadStartupLevelsStep:
				probes.append(WarmOrderProbeStep.new())
			elif step is RequestWarmPagesStep or step is PrepareRankSessionStep or step is ResolveInitialRouteStep\
			or step is WarmPagesStep or step is WarmAudioStep or step is WarmFinishRenderStep:
				probes.append(SplashWorkOrderProbeStep.new(step.get_step_name()))
			elif step is WaitSplashCompleteStep:
				probes.append(step)
		await FlowRunner.new(probes).run(ctx)
		_rope_check(auth_count == 1 and ctx.warm_count == 6 and launcher.completed_after_auth, 
			"权限仅启动一次且Splash仍等待必要选择")
		_rope_check(ctx.warm_before_splash and ctx.warm_count_at_splash == 3 and ctx.gpu_at_logo, 
			"Logo完成首次GPU预绘，之后才显示Splash")
		_rope_check(ctx.work_in_splash and ctx.splash_work == ["RequestWarmPages", "PrepareRankSession", 
			"ResolveInitialRoute", "WarmPages", "WarmAudio", "WarmFinishRender"], 
			"资源请求、排行榜、首屏判断、页面装配、音效及完整池继续在Splash顺序执行")
		_rope_check(ctx.warm_count_at_auth == 3 and ctx.auth_after_splash, 
			"Splash显示后立即请求权限，此时Logo下3项预热已完成并发起")
		_rope_check(ctx.overlapped, "权限流程与Splash准备并发（弹窗下方继续准备）")
	UserState.set("_first_session_runtime", original_first_session)


func _test_cmp_detached(launcher: LauncherProbe) -> void :
	for allow_att: bool in [false, true]:
		var auth: = AuthProbe.new()
		auth.module.allow_att = allow_att
		root.add_child(auth)
		var ctx: Dictionary = {"launcher": launcher, "splash_page": null, "auth": auth, 
			"auth_started": false, "auth_finished": false}
		launcher.context = ctx
		var started: int = Time.get_ticks_msec()

		await FlowRunner.new([AuthStartStep.new(), WaitSplashCompleteStep.new()] as Array[FlowStep]).run(ctx)
		if Time.get_ticks_msec() - started >= 500 or not launcher.completed_after_auth or auth.module.cmp_finished:
			_failures.append("CMP未回调时仍阻塞Splash/路由")
		if auth.module.probe_type != 0 or UserState.get_push_ask_count() != 0:
			_failures.append("启动期不应探测或消费 Push 申请次数")
		if "att_checked" in auth.module.events:
			_failures.append("CMP完成前提前判断ATT")

		auth.module.finish_cmp()
		if not "att_checked" in auth.module.events or ("att_shown" in auth.module.events) != allow_att:
			_failures.append("晚到CMP回调未按SDK判据处理ATT")
		await process_frame
		auth.free()

	var auth: = AuthProbe.new()
	auth.module.allow_push = true
	auth.module.cmp_sync = true
	auth.module.allow_att = true
	root.add_child(auth)
	await auth.initialize()
	if auth.module.push_finished or UserState.get_push_ask_count() != 0:
		_failures.append("启动期仍在申请 Push 或消费次数")
	var expected: Array[String] = ["push_enabled", "cmp_started", "att_checked", "att_shown"]
	if auth.module.events != expected:
		_failures.append("隐私后CMP/ATT顺序或同步回调发生回归")
	await process_frame
	auth.free()

func _second_warm_home() -> void :
	await SceneManager.warm_page_threaded("home")
	_second_finished = true



func _run_effect_warmup() -> void :
	var launcher: = LauncherProbe.new()
	root.add_child(launcher)
	current_scene = launcher
	var ctx: Dictionary = {"launcher": launcher}
	var step: = GameEffectsPreparer.new()
	UserState.set("_effects_warmed", true)
	if not step.should_run(ctx):
		_failures.append("旧effects_warmed标记跳过了特效组资源签名")
	if not _failures.is_empty():
		for failure: String in _failures:
			SortLogger.error(failure)
		quit(1)
		return
	await _test_effect_warmup_policy(step, ctx)
	if _failures.is_empty():
		SortLogger.info("PASS: effect startup warmup")
	for failure: String in _failures:
		SortLogger.error(failure)
	quit(0 if _failures.is_empty() else 1)




func _check_warm_effect_cleanup(board: JuiceBoardView) -> void :
	_rope_check( not board.get("_warming_effects") and board.get("_warm_effect_releases").is_empty()
		and board.get("_warm_effect_tweens").is_empty(), "预热临时登记和Tween清空")
	var pools: Dictionary = {
		"_unlock_spine_pool": 1, "_unlock_leaf_pool": 1, "_unlock_glow_pool": 1, 
	}
	for effect: CanvasItem in board.get_node("FruitLayer").get_children():
		if effect is GPUParticles2D or effect is SpineSprite or effect is Sprite2D:
			_rope_check( not effect.visible, "盘面中没有预热效果继续可见")
	var mystery: JuiceMysteryRevealEffects = board.mystery_effects_for_skin(board.skin_resources())
	for pool_name: String in ["_mystery_petal_pool", "_mystery_glow_pool", "_mystery_flash_pool", "_mystery_star_pool"]:
		pools[pool_name] = 2 if pool_name == "_mystery_petal_pool" else 1
	for pool_name: String in pools:
		var pool: Array = mystery.get(pool_name) if pool_name.begins_with("_mystery_") else board.get(pool_name)
		_rope_check(pool.size() == pools[pool_name], "预热对象完整回池: " + pool_name)
		for effect: CanvasItem in pool.duplicate():
			_rope_check( not effect.visible, "预热效果隐藏: " + pool_name)
			if effect is GPUParticles2D:
				_rope_check( not effect.emitting, "预热粒子停止: " + pool_name)
				effect.finished.emit()
				_rope_check(pool.size() == pools[pool_name], "晚到粒子回调不重复入池: " + pool_name)
			elif effect is SpineSprite:
				_rope_check(effect.get_animation_state().get_current(0) == null, "预热Spine轨道清空")


func _rope_check(ok: bool, label: String) -> void :
	if not ok:
		_failures.append(label)



func _run_full_launch() -> void :
	UserState.set_debug_ab_override("cold_start_optimization", 1 if "--optimized" in OS.get_cmdline_user_args() else 0)
	change_scene_to_file("res://scripts/main/launcher/launcher.tscn")
	var started_msec: int = Time.get_ticks_msec()
	var logo_visible_msec: int = -1
	var fade_started_msec: int = -1
	var logo_hidden_msec: int = -1
	var splash_started: bool = false
	while Time.get_ticks_msec() - started_msec < 12000:
		await process_frame
		var logo: CanvasItem = SceneManager.get_page("logo") as CanvasItem
		if logo != null and logo.visible:
			if logo_visible_msec < 0:
				logo_visible_msec = Time.get_ticks_msec()
			if logo.modulate.a < 1.0 and fade_started_msec < 0:
				fade_started_msec = Time.get_ticks_msec()
		var splash: CanvasItem = SceneManager.get_page("splash") as CanvasItem
		if splash != null and splash.visible and not splash_started:
			splash_started = true
			var privacy: CanvasItem = SceneManager.get_page("privacy") as CanvasItem
			_rope_check(privacy != null and not privacy.visible, "Splash前隐私弹窗已隐藏准备")
			_rope_check(SceneManager.get_page("home") == null and SceneManager.get_page("game") == null, 
				"Splash显示前不实例化业务整页；独立Board缓存不属于首屏页面")
			_rope_check(AudioManager.get("_sfx_streams").size() == 1, 
				"Splash显示前只准备同步按钮音效")
		if logo != null and not logo.visible and splash != null and splash.visible and logo_hidden_msec < 0:
			logo_hidden_msec = Time.get_ticks_msec()
		var page: CanvasItem = SceneManager.get_page("game") as CanvasItem
		if page == null or not page.visible:
			page = SceneManager.get_page("home") as CanvasItem
		if page == null or not page.visible or splash == null or splash.visible:
			continue
		if page == SceneManager.get_page("game") and SceneManager.get_page("home") != null:
			_failures.append("直进游戏的启动路径不应准备首页")
		for page_name: String in ["splash", "home" if SceneManager.get_page("home") != null else "game", "privacy"]:
			if SceneManager.get_page(page_name) == null:
				_failures.append("完整启动缺少页面: " + page_name)
		if AudioManager.get("_sfx_streams").size() != AudioManager.SFX_PATHS.size():
			_failures.append("路由发生在全部音效准备完之前")
		if logo_visible_msec < 0 or fade_started_msec - logo_visible_msec < 1566:
			_failures.append("完整启动Logo不透明展示不足1.6秒")
		var splash_elapsed_msec: int = Time.get_ticks_msec() - logo_hidden_msec
		print("FULL_SPLASH_HOLD_SAMPLE: logo_hidden_ms=", logo_hidden_msec, " splash_elapsed_ms=", splash_elapsed_msec)
		if logo_hidden_msec < 0 or splash_elapsed_msec < 2000:
			_failures.append("完整启动Logo隐藏后Splash展示不足2秒")
		if not ResourceLoader.has_cached("res://scripts/debug/cheat_commands.gd") or not SceneManager.PAGE_SCENES.has("ab_debug"):
			_failures.append("延迟调试工具未注入")
		if _failures.is_empty():
			print("PASS: startup concurrent requests; FULL LAUNCH with CMP never completing, elapsed_ms=", Time.get_ticks_msec() - started_msec)
		for failure: String in _failures:
			push_error(failure)


		SceneManager.hide_page("game" if page == SceneManager.get_page("game") else "home")
		PagePreparationCoordinator._background_generation += 1
		for i: int in 30:
			await process_frame

		if is_instance_valid(FinishParticleCache._viewport):
			FinishParticleCache._viewport.free()
		FinishParticleCache._viewport = null
		FinishParticleCache._groups.clear()
		FinishParticleCache._resources.clear()
		FinishParticleCache._point_data_job = null
		await process_frame
		quit(0 if _failures.is_empty() else 1)
		return
	push_error("完整启动超时，CMP未回调时流程未放行")
	quit(1)



func _run_logo_gpu() -> void :
	var launcher: = Node.new()
	root.add_child(launcher)
	current_scene = launcher
	var ctx: = LauncherFlowContext.new(launcher)
	ctx.logo_page = SceneManager.show_page("logo") as LogoPage
	var active: Callable = ctx.is_logo_preparation_active
	_rope_check( not await GameEffectsPreparer.prepare_startup(launcher, func() -> bool: return false), 
		"已经取消的Logo准备不创建盘面")
	await WarmStartupGpuStep.new().run(ctx)
	_rope_check(ctx.gpu_ready and not ctx.startup_failed and FinishParticleCache._render_ready, 
		"Logo下完成两组真实预绘")
	_rope_check(SceneManager.get_page("game") == null and SceneManager.get_page("home") == null
		and ctx.initial_page.is_empty() and AudioManager.get("_sfx_streams").size() == 1, 
		"Logo预绘不准备整页、不判断首屏、不加载全部音效")
	var board: JuiceBoardView = GameEffectsPreparer._startup_board
	_rope_check(is_instance_valid(board) and not board.visible and board.is_connection_particles_warmed(), 
		"缓存真实盘面且预绘后隐藏")
	var leaf: GPUParticles2D = board.get("_unlock_leaf_pool")[0]
	var fireworks: FireworkShow = FinishParticleCache._groups["fireworks"]
	var star: GPUParticles2D = fireworks.get("_pool_stars")[0]
	var spark: Node = fireworks.get("_pool_sparks")[0]
	var trails: FireworkTrails = fireworks.get("_trails")
	var groups: Dictionary = FinishParticleCache._groups.duplicate()
	_rope_check(fireworks.get("_pool_glows").size() == 1 and fireworks.get("_pool_sparks").size() == 1
		and trails.get("_available_ribbons").size() == 1 and not fireworks.visible, 
		"Logo烟花仅保留一组预绘对象，未提前建完整池")
	await GameEffectsPreparer.prepare_startup(launcher, active)
	_rope_check(GameEffectsPreparer._startup_board == board, "重复Logo准备复用真实盘面")
	await ShowSplashStep.new().run(ctx)
	ctx.begin_stage("WarmPages", 30.0, 50.0)


	var game_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd") as GDScript
	_rope_check(game_script != null and game_script.can_instantiate(), "游戏页脚本可实例化")
	var game: Node = await SceneManager.prepare_page_for_display("game", ctx.is_startup_active)
	_rope_check(game != null and game.get_node("Board") == board and game.get("_game_effects_ready"), 
		"Splash游戏页接入同一Board，预绘完成状态仍有效")
	_rope_check(board.get("_unlock_leaf_pool")[0] == leaf and not leaf.visible and not leaf.emitting, 
		"交接复用同一发射器且隐藏停发")
	_rope_check( not is_instance_valid(GameEffectsPreparer._startup_board), "盘面缓存只交接一次")
	var render_state: Dictionary = {"unexpected_render": false}
	var watch_render: Callable = func() -> void :
		if FinishParticleCache._viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			render_state.unexpected_render = true
	RenderingServer.frame_post_draw.connect(watch_render)
	var progress_values: Array[float] = []
	var ready: bool = await FinishParticleCache.prepare(launcher, func(ratio: float) -> void : progress_values.append(ratio))
	RenderingServer.frame_post_draw.disconnect(watch_render)
	_rope_check(ready and not render_state.unexpected_render, 
		"Splash补齐烟花池时离屏视口保持停绘，不重复预绘")
	_rope_check(fireworks.get("_pool_glows").size() == 6 and fireworks.get("_pool_sparks").size() == 120
		and trails.get("_available_ribbons").size() == 120, 
		"Splash分帧补齐6组烟花、120颗Spark与120条ribbon")
	_rope_check(fireworks.get("_pool_stars")[0] == star and fireworks.get("_pool_sparks")[0] == spark, 
		"补池复用Logo预绘星光与Spark")
	for key: String in groups:
		_rope_check(FinishParticleCache._groups[key] == groups[key], "保留同一完成页配方: " + key)
	_rope_check(progress_values.size() > 10 and is_equal_approx(progress_values[-1], 1.0), 
		"完整池进度按真实创建推进并到达完成")
	for index: int in range(1, progress_values.size()):
		_rope_check(progress_values[index] >= progress_values[index - 1], "池创建进度保持单调")
	var finished: = Node2D.new()
	var placeholder: = Node2D.new()
	placeholder.name = "FireworkLayer"
	finished.add_child(placeholder)
	launcher.add_child(finished)
	FinishParticleCache.inject_fireworks(finished)
	_rope_check(finished.get_node("FireworkLayer") == fireworks and not fireworks.visible and not star.emitting, 
		"完成页交接同一完整烟花池并保持隐藏停发")
	SceneManager.hide_page("splash")
	for failure: String in _failures:
		SortLogger.error(failure)
	if _failures.is_empty():
		SortLogger.info("PASS: Logo GPU preparation and cached handoff")
	quit(0 if _failures.is_empty() else 1)


func _test_effect_warmup_policy(step, ctx: Dictionary) -> void :
	var key: String = EffectWarmupPolicy.signature("mystery_reveal")
	_rope_check(key.length() == 64 and key == EffectWarmupPolicy.signature("mystery_reveal"), "签名稳定")
	UserState.set("_current_level", 42)
	UserState.set("_coins", 73)
	EffectWarmupPolicy._cache_checked = true
	EffectWarmupPolicy._cache_identity = "isolated-cache-generation"
	EffectWarmupPolicy._process_rendered.clear()
	_rope_check(EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), "旧布尔标记不能证明新组完成")
	var before_saves: int = UserState.get("test_save_calls")
	if DisplayServer.get_name() == "headless":
		await step.run(ctx.launcher)
		_rope_check(UserState.get("test_save_calls") == before_saves and ctx.launcher.get_child_count() == 0, 
			"Headless不创建实例、不写成功")
		EffectWarmupPolicy.mark_rendered("mystery_reveal", func() -> bool: return true)
		_rope_check(EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), "Headless不能冒充GPU预绘")

	var record: Dictionary = {"signature": key, "cache": "isolated-cache-generation"}
	_rope_check(UserState.mark_effect_warmup_record("mystery_reveal:default", record), "签名记录可保存")
	_rope_check( not EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), "同签名同缓存省去完整预绘")
	_rope_check(step.should_run(ctx), "历史记录不冒充本次实例已经就绪")
	EffectWarmupPolicy._cache_identity = "removed-and-recreated-cache"
	_rope_check(EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), "缓存删除重建使记录失效")
	EffectWarmupPolicy._cache_identity = "isolated-cache-generation"
	var old_manifest: Dictionary = EffectWarmupPolicy._manifest.duplicate(true)
	EffectWarmupPolicy._manifest["groups"]["mystery_reveal"] = "changed-recipe"
	_rope_check(EffectWarmupPolicy.signature("mystery_reveal") != key and EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), 
		"配方变化独立失效")
	EffectWarmupPolicy._manifest = old_manifest
	EffectWarmupPolicy.mark_rendered("mystery_reveal", func() -> bool: return false)
	_rope_check(EffectWarmupPolicy._process_rendered.is_empty(), "取消不记录成功")
	UserState.set("test_save_failure", true)
	_rope_check( not UserState.mark_effect_warmup_record("mystery_reveal:default", {"signature": "failed"})
		and UserState.get_effect_warmup_record("mystery_reveal:default") == record, "保存失败回滚历史")
	UserState.set("test_save_failure", false)
	UserState.set("_effect_warmup_records", {})
	UserState.call("_load_data")
	_rope_check(UserState.get_effect_warmup_record("mystery_reveal:default") == record
		and UserState.get_current_level() == 42 and UserState.get_coins() == 73, "重载保留签名和玩家数据")
	UserState.reset_all()
	_rope_check(UserState.get_effect_warmup_record("mystery_reveal:default") == record, "游戏清档保留设备事实")


func _run_data_init() -> void :
	var launcher: = LauncherProbe.new()
	root.add_child(launcher)
	current_scene = launcher

	var old: = SQLite.new()
	old.path = "res://test.db"
	assert (old.open_db())
	assert (old.query("CREATE TABLE level_progress(level_id INTEGER PRIMARY KEY, completed INTEGER DEFAULT 0, score INTEGER DEFAULT 0, cost_time_ms INTEGER DEFAULT 0, completed_at INTEGER DEFAULT 0, updated_at INTEGER DEFAULT 0, raw_level_info TEXT, initial_state TEXT, current_state TEXT)"))
	assert (old.query("INSERT INTO level_progress VALUES(1,1,117,311,10,10,'{}','{}','{}')"))
	old.close_db()
	var cancelled: = CancelledDb.new()
	root.add_child(cancelled)
	_rope_check( not await cancelled.init_async( func() -> bool: return false)
		and not cancelled.get("_initialized") and cancelled.get("_db") == null, "取消时join后关闭私有连接")
	_rope_check( await cancelled.init_async() and cancelled.load_level_entity(1).is_empty(), "取消后可以重试")
	(cancelled.get("_db") as SQLite).close_db()
	cancelled.free()
	var broken: = SQLite.new()
	broken.path = "res://migration_failure.db"
	assert (broken.open_db())
	assert (broken.query("CREATE TABLE level_progress(level_id INTEGER PRIMARY KEY)"))
	broken.close_db()
	var invalid: = InvalidDb.new()
	root.add_child(invalid)
	_rope_check( not await invalid.init_async() and not invalid.get("_initialized"), "任一迁移SQL失败不开放业务连接")
	assert (broken.open_db())
	assert (broken.query("SELECT name FROM sqlite_master WHERE name='special_challenge_progress'"))
	_rope_check(broken.query_result.is_empty(), "失败事务回滚已创建的挑战表")
	broken.close_db()
	invalid.free()
	var handshake: Dictionary = {"calls": 0, "exclusive": true}
	var active: Callable = func() -> bool:
		handshake.calls += 1
		handshake.exclusive = handshake.exclusive and not DbManager.get("_initialized")
		return true
	assert ( await DbManager.init_async(active))
	_rope_check(handshake.calls > 0 and handshake.exclusive, "线程join交接前业务读写关闭")
	var row: Dictionary = DbManager.load_level_entity(1)
	_rope_check(row.has("game_id") and row.has("start_times") and row.has("play_time_ms"), "旧库补齐列")
	UserState.set("_current_level", 1)
	UserState.set("_pending_level_completion", 1)
	assert (DbManager.save_special_challenge({"instance_id": "isolated-special", "raw_level_info": "{}", "initial_state": "{}", "current_state": "{}", "game_id": "test", "updated_at": 10}))
	var reward: Dictionary = {"coins": 300, "hint": 1, "undo": 1, "rope": 0}
	var coins_before: int = UserState.get_coins()
	UserState.set("_special_challenge", {"instance_id": "isolated-special", "status": "win_pending", "reward": reward})
	var signals: Array[String] = []
	LevelManager.special_challenge_completed.connect( func(_instance: String) -> void : signals.append("special"))
	var ctx: = LauncherFlowContext.new(launcher)
	ctx.cold_start_optimized = true
	ctx.splash_page = SceneManager.show_page("splash") as SplashPage
	await StartupProgressStep.new(InitDataStep.new(), 0.0, 10.0).run(ctx)
	row = DbManager.load_level_entity(1)
	_rope_check(ctx.data_ready and not ctx.startup_failed and UserState.get_current_level() == 2
		and UserState.get_pending_level_completion() == 0, "先完成普通journal再读当前关号")
	_rope_check(row.score == 117 and row.cost_time_ms == 311 and row.current_state == null, "恢复不抹统计且清盘面")
	_rope_check( not UserState.has_special_challenge() and UserState.get_coins() == coins_before + 300
		and signals.is_empty(), "挑战静默恢复后自动领取冻结的单倍奖励")
	await _test_special_challenge_startup(launcher, ctx.splash_page, signals)
	await StartupProgressStep.new(InitGrtAnchorStep.new(), 10.0, 15.0).run(ctx)
	await StartupProgressStep.new(LoadStartupLevelsStep.new(), 15.0, 30.0).run(ctx)
	_rope_check(ctx.anchors_ready and ctx.levels_ready and not ctx.startup_failed, "本地准备按顺序完成")
	_rope_check( not LevelManager.get("_startup_refresh_started"), "Splash期间不启动延迟章节刷新")
	var required: Array[String] = ["data_ready", "anchors_ready", "levels_ready", "gpu_ready", "initial_page_ready", "audio_ready", "finish_ready", "auth_ready"]
	for missing: String in required:
		var gate: = QuietFailureContext.new(launcher)
		gate.cold_start_optimized = true
		gate.splash_page = ctx.splash_page
		gate.begin_stage("required_gate", 30.0, 40.0)
		for ready_flag: String in required:
			gate.set(ready_flag, true)
		gate.set(missing, false)
		await WaitSplashCompleteStep.new().run(gate)
		_rope_check(gate.startup_failed and gate.splash_page._current_progress < 1.0
			and not RouteInitialPageStep.new().should_run(gate), "缺必要准备不收尾或路由: " + missing)
	SceneManager.hide_page("splash")
	if _failures.is_empty():
		SortLogger.info("PASS: Splash worker data preparation")
	for failure: String in _failures:
		SortLogger.error(failure)
	quit(0 if _failures.is_empty() else 1)


func _test_special_challenge_startup(launcher: Node, splash: SplashPage, signals: Array[String]) -> void :
	var packages: Array[Dictionary] = [
		{"coins": 300, "hint": 1, "undo": 1, "rope": 0}, 
		{"coins": 0, "hint": 0, "undo": 0, "rope": 1}, 
		{"coins": 0, "hint": 1, "undo": 2, "rope": 0}, 
	]
	var tmp_path: String = String(UserState.call("_resolve_save_path")) + ".tmp"
	for optimized: bool in [false, true]:
		for status: String in ["win_pending", "reward_pending"]:
			for package: Dictionary in packages:
				var pending: Dictionary = {"instance_id": "isolated-special", "status": status, "reward": package}
				UserState.set("_special_challenge", pending.duplicate(true))
				assert (UserState.call("_save_data") == OK)
				UserState.call("_load_data")
				var cursor: int = UserState.get_current_level()
				var completed: int = UserState.get("_special_challenge_completed")
				var streak: int = UserState.get_win_streak_count()
				var balances: Dictionary = {"coins": UserState.get_coins()}
				for kind: String in ["hint", "undo", "rope"]:
					balances[kind] = UserState.get_prop_count(kind)

				assert (DirAccess.make_dir_absolute(tmp_path) == OK)
				var failed: = QuietFailureContext.new(launcher)
				failed.cold_start_optimized = optimized
				failed.splash_page = splash
				failed.begin_stage("challenge_recovery", 0.0, 10.0)
				await InitDataStep.new().run(failed)
				assert (DirAccess.remove_absolute(tmp_path) == OK)
				_rope_check(failed.startup_failed and not failed.data_ready
					and not RouteInitialPageStep.new().should_run(failed), "奖励恢复失败阻断路由")
				_rope_check(UserState.get_special_challenge() == pending
					and UserState.get_coins() == balances.coins
					and UserState.get("_special_challenge_completed") == completed, "失败保留冻结奖励与领取身份")
				var ctx: = LauncherFlowContext.new(launcher)
				ctx.cold_start_optimized = optimized
				ctx.splash_page = splash
				ctx.begin_stage("challenge_recovery", 0.0, 10.0)
				await InitDataStep.new().run(ctx)
				UserState.call("_load_data")
				_rope_check( not ctx.startup_failed and not UserState.has_special_challenge()
					and not bool(LevelManager.get_next_round_descriptor(false).is_special)
					and UserState.get_current_level() == cursor, "重启领奖后进入下一普通关且不跳关")
				_rope_check(UserState.get_coins() == balances.coins + package.coins
					and UserState.get("_special_challenge_completed") == completed + 1
					and UserState.get_win_streak_count() == streak, "只领取单倍且不重复计通关")
				for kind: String in ["hint", "undo", "rope"]:
					_rope_check(UserState.get_prop_count(kind) == balances[kind] + package[kind], "冻结道具只发一倍: " + kind)
				await InitDataStep.new().run(ctx)
				UserState.call("_load_data")
				_rope_check(UserState.get_coins() == balances.coins + package.coins
					and UserState.get("_special_challenge_completed") == completed + 1, "再次重启不重复发奖")
				for kind: String in ["hint", "undo", "rope"]:
					_rope_check(UserState.get_prop_count(kind) == balances[kind] + package[kind], "再次重启不重复发道具: " + kind)

		var playing: Dictionary = {"instance_id": "isolated-special", "status": "playing"}
		UserState.set("_special_challenge", playing)
		var ctx: = LauncherFlowContext.new(launcher)
		ctx.cold_start_optimized = optimized
		ctx.splash_page = splash
		ctx.begin_stage("challenge_recovery", 0.0, 10.0)
		await InitDataStep.new().run(ctx)
		_rope_check( not ctx.startup_failed and UserState.get_special_challenge() == playing, "未通关挑战仍可续局")
		UserState.set("_special_challenge", {})
		assert (UserState.call("_save_data") == OK)
	_rope_check(signals.is_empty(), "全部启动恢复均不补报挑战成功")


func _run_warmup_persistence() -> void :
	EffectWarmupPolicy._cache_checked = true
	EffectWarmupPolicy._cache_identity = "isolated-cache-generation"
	_rope_check( not EffectWarmupPolicy.needs_full_warmup("mystery_reveal"), "第二进程读取历史签名")
	var preparer: = GameEffectsPreparer.new()
	_rope_check(preparer.should_run(null), "第二进程仍需要真实实例")
	var board: JuiceBoardView = load(GameEffectsPreparer.BOARD_SCENE_PATH).instantiate() as JuiceBoardView
	_rope_check( not board.is_connection_particles_warmed(), "历史签名不伪造新Board粒子状态")
	board.free()
	if _failures.is_empty():
		SortLogger.info("PASS: persisted effect warmup skips restart")
	for failure: String in _failures:
		SortLogger.error(failure)
	quit(0 if _failures.is_empty() else 1)


func _run_cold_start() -> void :
	var launcher: = Node.new()
	root.add_child(launcher)
	current_scene = launcher
	var cfg: ColdStartOptimizationConfig = ABManager.cold_start_optimization
	ABManager.init_done.connect( func() -> void :
		assert (ABManager.events == ["get:yes", "dye"], "初始化完成前必须 get→dye")
	, CONNECT_ONE_SHOT)
	ABManager.raw = "yes"
	ABManager._complete_initialization()
	assert (cfg.value() == 1 and cfg.is_cold_start_optimization_enabled() and not cfg.is_control_group())
	ABManager.raw = "no"
	assert (cfg.peek_sdk_value() == 0 and cfg.peek_value() == 0)
	assert (cfg.is_cold_start_optimization_enabled(), "面板预览不能覆盖业务来源/值")
	cfg.reload_value()
	assert (cfg.is_control_group() and not cfg.is_cold_start_optimization_enabled())
	for raw: String in ["", "unknown", "YES"]:
		ABManager.raw = raw
		cfg.reload_value()
		assert (cfg.value() == 0 and not cfg.is_control_group() and not cfg.is_cold_start_optimization_enabled())
	ABManager.raw = "yes"
	ABManager.status = "invalid"
	cfg.reload_value()
	assert ( not cfg.is_cold_start_optimization_enabled() and not cfg.is_control_group())
	for override: int in [0, 1, 3]:
		UserState.set_debug_ab_override(cfg.key, override)
		assert (cfg.is_cold_start_optimization_enabled() == (override == 1))
		assert (cfg.is_control_group() == (override == 0))
	UserState.clear_debug_ab_override(cfg.key)
	ABManager._is_init_done = false
	ABManager.events.clear()
	await ABManager.await_ready(0.03)
	assert (ABManager._startup_control_locked and not cfg.is_cold_start_optimization_enabled() and not cfg.is_control_group())
	ABManager.raw = "yes"
	ABManager.status = "valid"
	ABManager._complete_initialization()
	assert (ABManager.events.is_empty(), "晚到 SDK 不切组、不补染色")
	assert ( not cfg.is_cold_start_optimization_enabled())
	var prefix: Array[FlowStep] = LauncherFlow._build_prefix()
	assert (prefix[2] is ShowLogoStep and prefix[-1] is AwaitAbtestReadyStep and prefix[-1].is_blocking())
	for optimized: bool in [false, true]:
		var names: Array[String] = []
		var last_percent: float = LauncherFlowContext.AUTH_STAGE_END_PERCENT
		for step: FlowStep in LauncherFlow._build_steps(optimized):
			names.append(step.get_step_name())
			if step is StartupProgressStep:
				var wrapped: StartupProgressStep = step as StartupProgressStep
				assert ( not (wrapped.step is PrivacyCmpAttStep), "权限阶段不拥有进度边界")
				assert (wrapped._start_percent == last_percent and wrapped._end_percent > last_percent)
				last_percent = wrapped._end_percent
		assert (last_percent == 95.0 and names[-1] == "RouteInitialPage")
		assert (names.find("PrivacyCmpAtt") == names.find("ShowSplash") + 1)
		assert ((names.find("ShowSplash") < names.find("InitData")) == optimized)
		assert ((names.find("ShowSplash") < names.find("WarmStartupGpu")) == optimized)
		assert (names.count("WarmStartupGpu") == 1, "默认及首局皮肤共用唯一分组准备阶段")
		assert (names.find("LoadStartupLevels") < names.find("WarmStartupGpu"), "只读预测在启动数据就绪后执行")
		assert (names.find("InitData") < names.find("LoadStartupLevels"))
		GameEffectsPreparer.set_startup_mode(optimized)
		FinishParticleCache.set_startup_mode(optimized)
		assert (FinishParticleCache.SCENES["confetti"].ends_with("_optimized.tscn") == optimized)
	var splash: SplashPage = SceneManager.show_page("splash", {"cold_start_optimized": true}) as SplashPage
	assert (splash.get_node("ProgressBar/StaticButterfly").visible and not splash.get_node("ProgressBar/Butterfly").visible)
	assert (splash.get_node("ProgressBar/Butterfly").process_mode == Node.PROCESS_MODE_DISABLED)
	for layer: String in ["AmbientLight", "AmbientFoliage"]:
		assert ( not splash.get_node(layer).visible and splash.get_node(layer).process_mode == Node.PROCESS_MODE_DISABLED)
	splash._current_progress = 0.5
	splash._update_progress_butterfly()
	assert (splash.get_node("ProgressBar/StaticButterfly").position == Vector2(346, -44))
	splash.set_cold_start_optimized(false)
	assert ( not splash.get_node("ProgressBar/StaticButterfly").visible and splash.get_node("ProgressBar/Butterfly").visible)
	assert (splash.get_node("AmbientLight").visible and splash.get_node("AmbientFoliage").visible)

	assert ( await splash.prepare_logo_for_display( func() -> bool: return splash.visible))
	SceneManager.hide_page("splash")
	SortLogger.info("PASS: cold start AB source, lock, flow and Splash parameters")
	quit()
