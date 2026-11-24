extends SceneTree

var _failures: Array[String] = []


class ControlledCoverDownloader extends LevelDownloader:
	const TEST_IMAGE: String = "res://assets/builtin/61d33d3cf670a36c31e294293f56f616.webp"
	var requests: Array[Dictionary] = []
	var released: Dictionary = {}
	var failures: Dictionary = {}
	var cached: Dictionary = {}
	var release_all: bool = false

	func fetch_chapter_cover(url: String, size: int = 512, active: Callable = Callable(), download_started: Callable = Callable()) -> String:
		if cached.has(url):
			return String(cached[url])
		requests.append({"url": url, "size": size})
		if download_started.is_valid():
			download_started.call()
		while not release_all and not released.has(url):
			if active.is_valid() and not active.call():
				return ""
			await get_tree().process_frame
		if active.is_valid() and not active.call():
			return ""
		if int(failures.get(url, 0)) > 0:
			failures[url] = int(failures[url]) - 1
			return ""
		cached[url] = TEST_IMAGE
		return TEST_IMAGE


class CoverTestManager extends "res://scripts/data/level_data/level_manager.gd":
	var cover_toast_events: Array[String] = []

	func _queue_chapter_cover_download_toast(action: String, chapter: int, kind: String) -> void :
		cover_toast_events.append("%s%d章%s" % [action, chapter, "大背景" if kind == "image" else "缩略图"])

	func _ready() -> void :
		_downloader = ControlledCoverDownloader.new()
		add_child(_downloader)
		_source = LevelSource.new(_downloader, ContentLevelExperimentResolver.new(ABManager))
		_chapter_art = {
			"2": {"image": ControlledCoverDownloader.TEST_IMAGE}, 
			"3": {"image_url": "test://3_image", "thumbnail_url": "test://3_thumbnail"}, 
			"4": {"thumbnail_url": "test://4_thumbnail"}, 
			"5": {"image_url": "test://5_image"}, 
			"6": {"thumbnail_url": "test://6_thumbnail"}, 
		}


class TutorialStartHost extends RefCounted:
	func should_run_tutorial_now(_state: Dictionary) -> bool:
		return true
	func start_tutorial_board() -> void :
		pass


class RoundStartHost extends RefCounted:
	var started: bool = true
	func should_run_tutorial_now(_state: Dictionary) -> bool:
		return false
	func start_round(_state: Dictionary) -> bool:
		return started
	func show_fallback_toast_if_needed() -> void :
		pass

func _check(value: bool, message: String) -> void :
	if not value:
		_failures.append(message)

func _wait_until(predicate: Callable, seconds: float = 5.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return predicate.call()


func _prepare_test_cover(manager: Node, chapter: int, image: bool, state: Dictionary) -> void :
	await manager.ensure_chapter_cover_async(chapter, image, not image, func() -> bool: return state.active)
	state.done = true


func _check_chapter_prefetch() -> void :
	var manager: = CoverTestManager.new()
	root.add_child(manager)
	var downloader: ControlledCoverDownloader = manager._downloader as ControlledCoverDownloader
	manager.prefetch_next_chapter_covers(1)
	_check(downloader.requests.is_empty(), "预取入口同步开始下载，未延后进关工作")
	_check( await _wait_until( func() -> bool: return downloader.requests.size() == 1), "第1章未预取第3章缩略图")
	_check(manager._chapter_cover_files.has("2_image") and downloader.requests[0] == {"url": "test://3_thumbnail", "size": 1080}, "第1章预取错位或内置第2章大图仍下载")
	_check(manager.cover_toast_events == ["开始下载3章缩略图"], "内置图冒充网络下载或网络开始未提示")
	_check(manager._chapter_textures.is_empty() and manager._chapter_cover_paths.is_empty(), "文件预取提前创建了显示纹理")
	await manager.wait_chapter_covers_idle()
	_check(manager._chapter_cover_downloads.has("3_thumbnail"), "进关汇合错误等待或取消未来图片")
	manager.prefetch_next_chapter_covers(1)
	manager.prefetch_next_chapter_covers(1, true)
	var canceled: Dictionary = {"active": true, "done": false}
	_prepare_test_cover(manager, 3, false, canceled)
	await process_frame
	canceled.active = false
	_check( await _wait_until( func() -> bool: return canceled.done), "离页不能停止等待预取任务")
	await manager.wait_chapter_covers_idle()
	_check(downloader.requests.size() == 1 and manager._chapter_cover_downloads.has("3_thumbnail"), "首页重复下载或离页取消持久预取")
	_check(manager.cover_toast_events.has("继续下载3章缩略图"), "首页复用下载时没有继续下载提示")
	downloader.released["test://3_thumbnail"] = true
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_files.has("3_thumbnail")), "跨页面下载未继续完成")
	_check(manager._chapter_textures.is_empty(), "取消显示等待后仍提交纹理")
	_check(manager.cover_toast_events.has("下载完成3章缩略图"), "文件下载完成未提示")
	await manager.ensure_chapter_cover_async(3, false, true)
	_check(downloader.requests.size() == 1 and manager.load_local_texture(manager.get_chapter_thumbnail_path(3)) != null, "首页未复用下载文件准备纹理")
	downloader.failures["test://3_image"] = 1
	manager.prefetch_next_chapter_covers(2)
	_check( await _wait_until( func() -> bool: return downloader.requests.size() == 3), "第2章没有并行发起第3章大图及第4章缩略图")
	_check(downloader.requests[1] == {"url": "test://3_image", "size": 1024} and downloader.requests[2] == {"url": "test://4_thumbnail", "size": 1080}, "第2章预取目标或尺寸错误")
	var joined: Dictionary = {"active": true, "done": false}
	_prepare_test_cover(manager, 4, false, joined)
	downloader.released["test://3_image"] = true
	downloader.released["test://4_thumbnail"] = true
	_check( await _wait_until( func() -> bool: return joined.done and manager._chapter_cover_downloads.is_empty()), "首页未加入进行中的下载")
	_check(downloader.requests.size() == 3 and not manager._chapter_cover_files.has("3_image"), "下载失败未保留待重试状态或首页重复发请求")
	_check( not manager.cover_toast_events.has("下载完成3章大背景"), "失败下载错误提示完成")
	manager.prefetch_next_chapter_covers(2)
	await process_frame
	_check(downloader.requests.size() == 3, "同章进关重复重试失败项")
	manager.prefetch_next_chapter_covers(2, true)
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_files.has("3_image")), "回首页没有重试失败的大图")
	_check(downloader.requests.size() == 4, "回首页重试重复下载成功的缩略图")
	_check(manager.cover_toast_events.has("下载完成3章大背景"), "重试成功未提示下载完成")

	var promoted: Dictionary = {"active": true, "done": false}
	_prepare_test_cover(manager, 5, true, promoted)
	_check( await _wait_until( func() -> bool: return downloader.requests.size() == 5), "未构造首页独占下载")
	manager.prefetch_next_chapter_covers(4)
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_downloads["5_image"].persistent), "预取未接管已有独占下载")
	promoted.active = false
	_check( await _wait_until( func() -> bool: return promoted.done), "接管后页面取消没有结束")
	downloader.released["test://5_image"] = true
	downloader.released["test://6_thumbnail"] = true
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_downloads.is_empty()), "接管下载未落盘")
	_check(manager._chapter_cover_files.has("5_image") and downloader.requests.size() == 6, "接管下载被取消或重新请求")

	manager._chapter_cover_files.erase("5_image")
	downloader.cached.erase("test://5_image")
	downloader.released.erase("test://5_image")
	manager._chapter_cover_prefetches.clear()
	manager.prefetch_next_chapter_covers(4)
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_downloads.has("5_image")), "未构造失效下载")
	manager._chapter_cover_epoch += 1
	manager._chapter_cover_downloads.clear()
	manager._chapter_cover_prefetches.clear()
	manager.prefetch_next_chapter_covers(4)
	_check( await _wait_until( func() -> bool: return downloader.requests.size() == 8), "新代次没有发起新下载")
	_check(manager._chapter_cover_downloads.has("5_image") and not manager._chapter_cover_files.has("5_image"), "旧任务清理了新代次任务或发布失效文件")
	downloader.released["test://5_image"] = true
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_downloads.is_empty()), "新代次下载未完成")

	manager._chapter_cover_files.clear()
	manager._chapter_cover_prefetches.clear()
	var toast_count: int = manager.cover_toast_events.size()
	manager.prefetch_next_chapter_covers(4)
	_check( await _wait_until( func() -> bool: return manager._chapter_cover_files.has("5_image") and manager._chapter_cover_files.has("6_thumbnail")), "重启预取没有命中磁盘文件")
	_check(downloader.requests.size() == 8, "重启后重复下载磁盘命中文件")
	_check(manager.cover_toast_events.size() == toast_count, "磁盘命中仍展示下载开始或完成提示")
	manager.queue_free()
	await process_frame

func _check_outer_loop_preparation(home: HomePage) -> void :
	SceneManager.hide_page("home")
	var active: Callable = func() -> bool: return not home.visible
	UserState.set_current_level(28)
	UserState.commit_hex_board_revealed(2, [0])
	UserState.set("_outer_loop_pending_level", 27)
	var paths: Dictionary = LevelManager.get("_chapter_cover_paths")
	var textures: Dictionary = LevelManager.get("_chapter_textures")

	var image: = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.PURPLE)
	var preview: Texture2D = ImageTexture.create_from_image(image)
	paths["3_thumbnail"] = "test://chapter_3_thumbnail"
	textures[paths["3_thumbnail"]] = preview

	var canceled: Dictionary = {"active": true, "done": false, "result": true}
	var background: Texture2D = home._background.texture
	_prepare_cancelable(home, canceled)
	await process_frame
	canceled.active = false
	_check( await _wait_until( func() -> bool: return canceled.done), "取消的章节准备未结束")
	await home._components.wait_idle()
	_check( not canceled.result and home._background.texture == background, "取消的章节准备修改了背景或报告成功")
	_check(UserState.get_outer_loop_pending_level() == 27, "取消的章节准备消费了标记")
	_check( await home.prepare_for_display(active), "常驻外循环首页准备失败")
	var chapter_background: Texture2D = LevelManager.load_local_texture(LevelManager.get_chapter_image_path(2))
	_check( not home.visible and chapter_background != null and home._background.texture == chapter_background, "显示前未绑定第2章正式背景")
	_check(home._hex_board != null and home._hex_backdrop != null, "显示前未准备章节组件")
	_check(UserState.get_outer_loop_pending_level() == 27 and UserState.get_hex_board_revealed(2) == [0], "预加载提前消费标记或改写揭格存档")
	if home._hex_board != null:
		_check(home._hex_board.visible and home._hex_board.get_node("Picture").texture == preview, "显示前未准备正确缩略图")
		_check(home._hex_board.get_node("ProgressLabel").text == "1/25", "预加载没有保留普通揭格的起始进度")
	var first_show: Dictionary = {"captured": false, "correct": false}
	var capture: Callable = func() -> void :
		if home.visible and not first_show.captured:
			first_show.captured = true
			first_show.correct = home._background.texture == chapter_background and home._hex_board != null
	home.visibility_changed.connect(capture)
	SceneManager.show_page("home")
	_check(first_show.captured and first_show.correct, "首页首次可见时仍显示默认背景")
	home.visibility_changed.disconnect(capture)
	SceneManager.hide_page("home")
	await home._components.wait_idle()
	await LevelManager.wait_chapter_covers_idle()
	UserState.set_current_level(26)
	UserState.set("_outer_loop_pending_level", 25)
	UserState.commit_hex_board_revealed(1, range(24))
	var board: HexBoard = home._hex_board
	_check( await home.prepare_for_display(active), "跨章首页准备失败")
	var previous_background: Texture2D = home._hex_backdrop.default_bg
	_check(previous_background != null and home._background.texture == previous_background, "跨章预加载提前切换新章背景")
	if home._hex_board != null:
		_check(home._hex_board == board and home._hex_board.get_node("ProgressLabel").text == "24/25", "跨章没有复用板子或保留旧章24格")
	_check(UserState.get_outer_loop_pending_level() == 25 and UserState.get_hex_board_revealed(1).size() == 24, "跨章预加载提前提交进度")
	UserState.set_current_level(28)
	UserState.set("_outer_loop_pending_level", 0)
	_check( await home.prepare_for_display(active), "缓存首页再次准备失败")
	_check(home._background.texture == chapter_background and home._hex_board == board, "复用首页残留旧章背景或重建板子")
	UserState.set_current_level(21)

func _prepare_cancelable(home: HomePage, state: Dictionary) -> void :
	state.result = await home.prepare_for_display( func() -> bool: return state.active and not home.visible)
	state.done = true

func _run() -> void :
	var host: = Node.new()
	root.add_child(host)
	current_scene = host
	ABManager.initialize_for_editor()
	UserState.set_rank_disabled(true)
	ABManager.main_btn.set_debug_override(MainBtnConfig.VALUE_OLD_EFFECT)
	InitDataStep.new().run(null)
	await LoadStartupLevelsStep.new().run(null)
	await _wait_until( func() -> bool: return LevelManager.is_level_state_resolved(1))
	await _check_chapter_prefetch()

	var covers: = ControlledCoverDownloader.new()
	covers.release_all = true
	root.add_child(covers)
	LevelManager.set("_downloader", covers)
	UserState.set_current_level(1)
	await StartRoundStep.new().run({"page": TutorialStartHost.new(), "current_state": {}, "aborted": false})
	_check( await _wait_until( func() -> bool: return LevelManager.get("_chapter_cover_files").has("3_thumbnail")), "冷启动教学进第1章未触发预取")
	UserState.set_current_level(28)
	var normal: = RoundStartHost.new()
	normal.started = false
	var failed: Dictionary = {"page": normal, "current_state": {}, "aborted": false}
	await StartRoundStep.new().run(failed)
	_check(failed.aborted and not LevelManager.get("_chapter_cover_prefetches").has("3_image"), "开局失败仍触发未来图片下载")
	normal.started = true
	await StartRoundStep.new().run({"page": normal, "current_state": {"resumed": true}, "aborted": false})
	_check( await _wait_until( func() -> bool: return LevelManager.get("_chapter_cover_files").has("3_image") and LevelManager.get("_chapter_cover_files").has("4_thumbnail")), "冷启动恢复第2章未触发未来图片预取")
	LevelManager.get("_chapter_cover_paths").clear()
	LevelManager.get("_chapter_textures").clear()
	UserState.set_current_level(1)
	RequestWarmPagesStep.new().run(null)
	_check( not SceneManager.get("_page_load_started_usec").has("home"), "通用启动请求包含首页")
	var ctx: = LauncherFlowContext.new(host)
	await ResolveInitialRouteStep.new().run(ctx)
	_check(ctx.initial_page == "game", "首关可玩时未直进游戏")
	await WarmPagesStep.new().run(ctx)
	_check(SceneManager.get_page("home") == null, "直进游戏时创建了首页")
	_check( not ResourceLoader.has_cached("res://scripts/main/pages/home/home_button_fx.tscn"), "启动加载了首页按钮特效")
	_check( not ResourceLoader.has_cached("res://scripts/gameplay/outer_loop/view/hex_board.tscn"), "启动加载了章节板")

	UserState.set_current_level(21)
	UserState.set_rank_disabled(false)
	RankManager.ensure_profile()
	RankManager.ensure_season()
	_check(RankManager.has_pending_session(), "未构造晚到赛季状态")
	RouteInitialPageStep.new().run(ctx)
	_check(SceneManager.get_page("game").visible and SceneManager.get_page("home") == null, "Splash 后重新判断了路由")
	UserState.set_rank_disabled(true)
	var game: Node = SceneManager.get_page("game")
	var explicit_process: = Node.new()
	explicit_process.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.add_child(explicit_process)
	game.return_home()
	_check(game.visible, "基础首页准备前隐藏了来源页")
	_check(game.process_mode == Node.PROCESS_MODE_DISABLED, "首页加载期间游戏仍在处理")
	_check( not explicit_process.can_process(), "显式处理模式子节点未暂停")
	_check( await _wait_until( func() -> bool:
		var page: Node = SceneManager.get_page("home")
		return page != null and page.visible and not game.visible), "首次返回首页未完成")
	_check(explicit_process.process_mode == Node.PROCESS_MODE_PAUSABLE, "来源页处理模式未恢复")
	explicit_process.queue_free()
	var home: HomePage = SceneManager.get_page("home") as HomePage
	_check(home != null, "基础首页缺失")
	if home == null:
		_finish()
		return
	_check(home._hex_board == null and home._rank_entry == null and home._home_button_fx == null, "关闭的分组创建了组件")
	_check(SceneManager.get_page("loading") == null, "返回首页显示了 Loading")
	var same_home: Node = home
	SceneManager.hide_page("home")
	await HomeNavigationFlow.run()
	_check(SceneManager.get_page("home") == same_home, "返回首页未复用缓存")
	await _check_outer_loop_preparation(home)

	SceneManager.hide_page("home")
	UserState.set_rank_disabled(false)
	await ResolveInitialRouteStep.new().run(ctx)
	_check(ctx.initial_page == "home", "待处理赛季未在 Logo 下选择首页")
	await WarmPagesStep.new().run(ctx)
	_check( not home.visible and home._rank_entry == null, "基础首页预热创建了排行榜组件")
	home.visible = true
	var active_state: Dictionary = {"active": true}
	var active: Callable = func() -> bool: return active_state.active and home.visible
	home._components.start(["rank"], active)
	await process_frame
	active_state.active = false
	home._components.cancel()
	await home._components.wait_idle()
	_check(home._rank_entry == null, "取消后旧请求创建了排行榜组件")
	active_state.active = true
	_check( await home._components.ensure_group("rank", active), "取消后不能重试准备排行榜组")
	_check(home._avatar_pool != null and home._rank_entry != null and home._avatar_button != null, "普通 Node 和 UI 组件未完整绑定")
	_check(home._rank_entry.mouse_filter == Control.MOUSE_FILTER_STOP and home._avatar_button.mouse_filter == Control.MOUSE_FILTER_STOP, "动态入口不能接收点击")
	_check(home._avatar_button.frame_kind == 1, "头像入树前配置丢失")
	_check(is_equal_approx(home._rank_entry_layout.scale.x, 0.9), "排行榜入口缩放丢失")
	var entry: Node = home._rank_entry
	_check( await home._components.ensure_group("rank", active) and home._rank_entry == entry, "组件重复创建")
	_check( await home._components.ensure_group("chapter", active), "章节组准备失败")
	_check(home._hex_board != null and home._hex_backdrop != null and not home._hex_board.visible, "章节未绑定或提前显示旧章")
	_check(home._hex_backdrop.board == home._hex_board, "章节组件注入失败")
	_check( await home._components.ensure_group("fx", active), "按钮特效组准备失败")
	_check(home._home_button_fx != null, "按钮特效未绑定")
	UserState.set_rank_disabled(true)
	home._play_ready = true
	home._refresh_play_button()
	await home._on_play_pressed()
	_check( not home.visible and game.visible, "Play未进入游戏")
	await home._components.wait_idle()
	await LevelManager.wait_chapter_covers_idle()
	_check( not home._home_button_fx.visible, "离页后按钮特效仍可见")
	_check( not home._components.get("_running") and LevelManager.get("_chapter_cover_loads").is_empty(), "离页后存在首页任务")

	UserState.set_rank_disabled(false)
	_check(RankManager.has_pending_session(), "返回首页会话回归缺少待处理状态")
	await game.return_home()
	_check( await _wait_until( func() -> bool:
		var dialog: Node = SceneManager.get_page("rank_introduction")
		return dialog != null and dialog.visible), "游戏离页清理关闭了新首页会话")
	_finish()

func _finish() -> void :
	for failure: String in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: home conditional loading, fixed initial route, stopped source, groups, cancellation and cache reuse")
	quit(0 if _failures.is_empty() else 1)
