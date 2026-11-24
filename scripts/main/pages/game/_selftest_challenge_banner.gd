extends SceneTree
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")



var _failures: Array[String] = []
var _scene: PackedScene


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures.append(label)


func _new_banner() -> Variant:
	var banner: Variant = _scene.instantiate()
	root.add_child(banner)
	banner.set_process(false)
	return banner


func _test_motion(fps: int) -> void :
	var banner: Variant = _new_banner()
	var center: Vector2 = root.get_visible_rect().size * 0.5
	banner.play(center)
	banner.set_process(false)
	var duration: float = banner.CARD_DURATION
	var frame_delta: float = 1.0 / float(fps)
	var start: Dictionary = banner._motion_at(0.0)
	var finish: Dictionary = banner._motion_at(duration)
	var half_w: float = banner.CARD_SIZE.x * banner._display_scale * 0.5
	_check(float(start["center"].x) - half_w > banner._right
		and float(finish["center"].x) + half_w < banner._left, "%dfps横幅从右屏外进入并向左完整离屏" % fps)
	var monotonic: bool = true
	var scale_fixed: bool = true
	var readable: bool = true
	var trailing: bool = true
	var independent: bool = false
	var tail_after_card: bool = false
	var max_particles: int = 0
	var prev_x: float = float(start["center"].x)
	var witness: Dictionary = {}
	var witness_origin: Vector2 = Vector2.ZERO
	for frame: int in ceili((duration + banner.PETAL_LIFE_MAX + 0.15) * float(fps)):
		banner._process(frame_delta)
		if banner._card.visible:
			monotonic = monotonic and banner._card_center.x <= prev_x + 0.001
			prev_x = banner._card_center.x
			scale_fixed = scale_fixed and banner._card.scale.is_equal_approx(Vector2.ONE * banner._display_scale)
			if banner._time > banner.IN_DURATION and banner._time < banner.IN_DURATION + banner.HOLD_DURATION:
				readable = readable and banner._card.modulate.a == 1.0\
				and absf(banner._card_center.x - center.x) <= banner.HOLD_DRIFT_PX * 0.5 + 0.01
		max_particles = maxi(max_particles, banner.active_petal_count())
		for petal: Dictionary in banner._petals:
			if not bool(petal["active"]):
				continue
			if witness.is_empty():
				witness = petal
				witness_origin = petal["origin"]
			if float(petal["age"]) <= frame_delta * 1.01:
				var birth: float = banner._time - float(petal["age"])
				var birth_center: Vector2 = banner._motion_at(birth)["center"]
				trailing = trailing and float(petal["origin"].x) > birth_center.x + half_w - 2.0\
				and float(petal["velocity"].x) < 0.0
		if not witness.is_empty() and bool(witness["active"]) and float(witness["age"]) > 0.2:
			independent = independent or (witness["origin"] as Vector2).is_equal_approx(witness_origin)
		if not banner._card.visible and banner.active_petal_count() > 0:
			tail_after_card = true
	_check(monotonic and scale_fixed and readable, "%dfps右进/缓慢左漂展示/左出,无回弹或缩放跳变" % fps)
	_check(trailing and independent and max_particles > 0 and max_particles <= banner.PETAL_POOL_SIZE, 
		"%dfps花瓣从右后方出生向左飘,独立运动且有固定数量上限" % fps)
	_check(tail_after_card and not banner.visible and banner.active_petal_count() == 0 and not banner.is_processing(), 
		"%dfps卡片离开后保留尾迹,自然散尽后停止更新" % fps)
	for boundary: float in [banner.IN_DURATION, banner.IN_DURATION + banner.HOLD_DURATION]:
		var before: Dictionary = banner._motion_at(boundary - 1e-05)
		var after: Dictionary = banner._motion_at(boundary + 1e-05)
		_check((before["center"] as Vector2).distance_to(after["center"]) < 0.01
			and absf(float(before["vx"]) - float(after["vx"])) < 0.3, 
			"%dfps阶段交接位置/速度连续 t=%.2f" % [fps, boundary])
	banner.queue_free()


func _test_cancel() -> void :
	var banner: Variant = _new_banner()
	banner.play(root.get_visible_rect().size * 0.5)
	banner.set_process(false)
	for frame: int in 40:
		banner._process(1.0 / 60.0)
	var pool_count: int = banner._petals.size()
	banner.dismiss()
	banner.dismiss()
	var count: int = banner.active_petal_count()
	for frame: int in 10:
		banner._process(1.0 / 60.0)
	_check( not banner._card.visible and banner.active_petal_count() <= count, 
		"拖花/点赞让路在0.15秒内退卡,停止新增粒子且重复dismiss幂等")
	banner.play(Vector2(400, 600))
	banner.set_process(false)
	_check(banner.active_petal_count() == 0 and banner._time == 0.0 and not banner._dismissing
		and banner._petals.size() == pool_count, "复播清理旧尾迹/时间/取消状态并复用粒子池")
	banner._process(0.45)
	_check(banner.active_petal_count() <= 8, "掉帧单帧发射有上限,不堆出粒子团")
	banner.hide_now()
	banner.hide_now()
	_check( not banner.visible and not banner.is_processing() and banner.active_petal_count() == 0
		and banner._card.scale == Vector2.ONE and banner._card.rotation == 0.0
		and banner._card.modulate == Color.WHITE, "离页/后台/死亡硬取消完整复原姿态与粒子")
	_check(banner.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and banner._card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "横幅与拖尾不拦截输入")
	banner.queue_free()


func _test_title_locales() -> void :
	var banner: Variant = _new_banner()
	var cases: Dictionary[String, String] = {
		"en": "en", "en_US": "en", "en-GB": "en", 
		"fr_FR": "fr", "fr-CA": "fr", "FR_fr": "fr", 
		"ru_RU": "ru", "es_MX": "es", "es-ES": "es", 
		"pt_BR": "pt", "pt-PT": "pt", 
		"ar_SA": "en", "ar-EG": "en", "zh_CN": "en", "de_DE": "en", "fil_PH": "en", "": "en", "unknown": "en", 
	}
	_check(banner.title_textures.size() == 5 and banner.title_positions.size() == 5, 
		"五种语言原始标题与Figma位置静态绑定齐全")
	var background: TextureRect = banner.get_node("Card/TitleBackground")
	var patch: AtlasTexture = background.texture
	_check(patch.region == Rect2(167, 54, 442, 99)
		and background.position == patch.region.position
		and background.size == patch.region.size, 
		"旧英文标题只在原文字区域覆盖,原横幅装饰贴图不变")
	banner.play(Vector2(540, 650))
	banner.set_process(false)
	banner._process(0.65)
	var previous_center: Vector2 = banner._card_center
	var previous_time: float = banner._time
	var previous_particles: int = banner.active_petal_count()
	for locale: String in cases:
		var language: String = cases[locale]
		banner._apply_title_locale(locale)
		_check(banner._title.texture == banner.title_textures[language]
			and banner._title.texture.resource_path == "res://assets/sprites/game_challenge_title_%s.png" % language
			and banner._title.size == banner._title.texture.get_size()
			and banner._title.position.is_equal_approx(banner.title_positions[language]), 
			"当前游戏语言%s选择%s原始标题,地区码归一化/无素材回退英文" % [locale, language])
	_check(banner._time == previous_time and banner._card_center == previous_center
		and banner.active_petal_count() == previous_particles, 
		"替换标题不重置飘屏进度、位置或花瓣尾迹")
	var expected_language: String = TranslationServer.get_locale().replace("-", "_").get_slice("_", 0).to_lower()
	if not banner.title_textures.has(expected_language):
		expected_language = "en"
	banner.play(Vector2(540, 650))
	banner.set_process(false)
	_check(banner._title.texture == banner.title_textures[expected_language], 
		"正式play入口按当前游戏语言选择标题")
	_check(banner._title.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and background.mouse_filter == Control.MOUSE_FILTER_IGNORE, 
		"新增标题层不拦截玩家操作")
	for language: String in banner.title_textures:
		var image: Image = banner.title_textures[language].get_image()
		var opaque_dark_background: bool = false
		for row: int in image.get_height():
			for column: int in image.get_width():
				var pixel: Color = image.get_pixel(column, row)
				if pixel.a > 0.99 and pixel.r < 0.3 and pixel.g < 0.3 and pixel.b < 0.3:
					opaque_dark_background = true
		_check(image.get_pixel(0, 0).a == 0.0 and not opaque_dark_background
			and image.get_used_rect().size != Vector2i.ZERO, 
			"%s标题保留透明背景与原始文字,无黑灰色底" % language)
	banner.queue_free()


func _test_page_integration() -> void :
	var host: Node = Node.new()
	root.add_child(host)
	current_scene = host
	var page_scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn")
	var page: Variant = page_scene.instantiate()
	host.add_child(page)
	await PAGE_FIXTURE.prepare(page, {}, ["preview"], false, true)
	page._board.setup(JuiceLevel.from_dict({"id": 99234, "capacity": 4, "targetCups": 4, 
		"initial": ["-|", "0|0,1,2", "1|1,2,0", "2|2,0,1"], "incoming": []}))
	page._board._cancel_closed_check()
	page._board.set_process(false)

	page._layout()
	page._quota.position.y += 35.0
	page.position = Vector2(30.0, 20.0)
	var board: Variant = page._board
	var shelf_y: float = board.layout().plank_top
	var quota_bottom: float = (page._quota.get_global_transform() * Vector2(0.0, page._quota.size.y)).y
	var shelf_top: float = (board.get_global_transform() * Vector2(0.0, shelf_y)).y
	page._show_challenge_banner()
	page._challenge_banner.set_process(false)
	var center_global: Vector2 = page._challenge_banner.get_global_transform() * page._challenge_banner._dst_center
	print("CHALLENGE_POSITION: quota_bottom=%.2f shelf_top=%.2f center_y=%.2f" % [
		quota_bottom, shelf_top, center_global.y])
	_check(is_equal_approx(center_global.y, (quota_bottom + shelf_top) * 0.5)
		and center_global.y > quota_bottom and center_global.y < shelf_top
		and is_equal_approx(center_global.x, root.get_visible_rect().size.x * 0.5), 
		"横幅居中于订单栏和木架之间,安全区/页面位移不影响定位")
	page.position = Vector2.ZERO
	page._layout()
	var snapshot: String = JSON.stringify(page._board.snapshot())
	var previous_locale: String = TranslationServer.get_locale()
	var locales: Array[String] = ["en", "fr", "ru", "es", "pt"]
	for language_index: int in locales.size():
		var args: Array[String] = [str(language_index + 1)]
		page._on_cheat_command("challenge_banner", args)
		page._challenge_banner.set_process(false)
		_check(page._challenge_banner._title.texture == page._challenge_banner.title_textures[locales[language_index]]
			and TranslationServer.get_locale() == previous_locale
			and JSON.stringify(page._board.snapshot()) == snapshot
			and page._challenge_toasted.is_empty(), 
			"cheat语言参数%d只选择%s标题,不改游戏语言/盘面/频控" % [language_index + 1, locales[language_index]])
	TranslationServer.set_locale("fr")
	page._show_challenge_banner()
	page._challenge_banner.set_process(false)
	_check(page._challenge_banner._title.texture == page._challenge_banner.title_textures["en"], 
		"默认飘屏固定英语,不保留cheat标题或随游戏语言切换")
	TranslationServer.set_locale(previous_locale)
	var system_language: String = TranslationServer.get_locale().replace("-", "_").get_slice("_", 0).to_lower()
	if not page._challenge_banner.title_textures.has(system_language):
		system_language = "en"
	var no_args: Array[String] = []
	page._on_cheat_command("challenge_banner", no_args)
	page._challenge_banner.set_process(false)
	_check(page._challenge_banner._title.texture == page._challenge_banner.title_textures[system_language], 
		"cheat不填参数仍按当前游戏语言预览")
	page._challenge_banner._process(0.65)
	var previous_time: float = page._challenge_banner._time
	var previous_texture: Texture2D = page._challenge_banner._title.texture
	var invalid_args: Array[Array] = [["0"], ["6"], ["7"], ["-1"], ["en"], ["2.5"], ["1", "2"]]
	for invalid: Array in invalid_args:
		var args: Array[String] = []
		args.assign(invalid)
		page._on_cheat_command("challenge_banner", args)
		_check(page._challenge_banner._time == previous_time
			and page._challenge_banner._title.texture == previous_texture
			and TranslationServer.get_locale() == previous_locale, 
			"无效cheat参数%s不重播、不更改标题或游戏语言" % str(invalid))
	page._show_challenge_banner()
	page._challenge_banner.set_process(false)
	page._challenge_banner._process(0.65)
	page._on_board_drag_started(1, 0)
	_check( not page._challenge_banner._dismissing, "开始拖花不打断横幅")
	page._show_challenge_banner()
	page._challenge_banner.set_process(false)
	page._challenge_banner._process(0.6)
	page._challenge_clear_joint = page._board.get_global_transform() * Vector2(400, 500)
	page._play_challenge_clear_fx()
	_check(page._challenge_banner._dismissing and page._like_spine.visible, 
		"Smart Move/点赞起播时横幅让路,原点赞仍播放")
	_check(JSON.stringify(page._board.snapshot()) == snapshot, 
		"飘屏/拖花/点赞预览让路不改盘面快照")
	page._hide_challenge_banner()
	_check( not page._challenge_banner.visible and page._challenge_banner.active_petal_count() == 0, 
		"页面清场接口立即收起横幅和残留尾迹")
	for field: String in ["_death_task_id", "_challenge_task_id"]:
		var task: int = int(page._board.get(field))
		if task != -1:
			WorkerThreadPool.wait_for_task_completion(task)
			page._board.set(field, -1)
	page.queue_free()


func _run() -> void :
	_scene = load("res://scripts/main/pages/game/challenge_banner.tscn")
	root.size = Vector2i(540, 1170)
	root.content_scale_size = Vector2i(1080, 2340)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	await process_frame
	var banner: Variant = _new_banner()
	_check(banner._card.texture.get_size() == Vector2(775, 224) and banner.petal_textures.size() == 5, 
		"新横幅775×224与五张原始花瓣静态绑定齐全")
	banner.queue_free()
	_test_title_locales()
	for fps: int in [30, 60, 120]:
		_test_motion(fps)
	_test_cancel()

	for width: int in [720, 1080, 1755]:
		root.content_scale_size = Vector2i(width, 2340)
		await process_frame
		var adapted: Variant = _new_banner()
		adapted.position = Vector2(30, 0)
		adapted.play(Vector2(width * 0.5 - 30, 650))
		adapted.set_process(false)
		_check(is_equal_approx(adapted._right - adapted._left, float(width))
			and adapted.CARD_SIZE.x * adapted._display_scale <= width - 96.0 + 0.01, 
			"%d宽视口适配边界/横幅大小并保留页面偏移" % width)
		adapted.queue_free()
	root.content_scale_size = Vector2i(1080, 2340)
	await process_frame
	await _test_page_integration()
	await process_frame
	print("CHALLENGE_BANNER_RESULT: %d failures" % _failures.size())
	quit(0 if _failures.is_empty() else 1)
