extends Node
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")


class ProbePage extends JuiceGamePage:
	var flight_started: bool = false
	func _ready() -> void :
		set_process(false)
	func _reset_hint_guide(_immediate: bool = false) -> void :
		pass
	func _clear_hint_guide_motion(_immediate: bool = false) -> void :
		pass
	func _fly_acquire(_color_slot: int) -> SpineSprite:
		var spr: = SpineSprite.new()
		add_child(spr)
		return spr
	func _fly_release(spr: SpineSprite) -> void :
		spr.free()
	func _fly_play_end_anim(_spr: SpineSprite) -> void :
		pass
	func _play_bloom_particles(_center: Vector2, _size: Vector2, _lifetime: float, 
			_speed_ratio: float, _size_ratio: float, _explosiveness: float, 
			_amount_min: int, _amount_max: int) -> void :
		pass
	func _fly_reveal(_spr: SpineSprite) -> void :
		pass
	func _fly_bloom_step(_u: float, _spr: SpineSprite, _center: Vector2, _sz: Vector2) -> void :
		pass
	func _fly_move_step(_u: float, _spr: SpineSprite, _from_c: Vector2, _to_c: Vector2, _sz: Vector2) -> void :
		pass
	func _play_pot_butterflies(_spr: SpineSprite, _sz: Vector2) -> void :
		pass
	func _play_hover_particles(_spr: SpineSprite, _sz: Vector2) -> void :
		pass
	func _fly_to_slot_step(_u: float, _spr: SpineSprite, _lift_c: Vector2, _from_sz: Vector2, 
			_slot: int, _tex: Texture2D) -> void :
		flight_started = true

class ProbeComboFeedback extends ComboFeedback:
	var counts: Array[int] = []

	func play(combos: Array[int], _feedback_center: Vector2, 
			_haptic_counts: Array[int] = [], _fullscreen_fx_enabled: bool = false, 
			_petal_feedback_enabled: bool = false, _timing_feedback_variant: int = 1) -> void :
		counts.append_array(combos)

class ProbeBoard extends JuiceBoardView:
	var model: JuiceLevel
	var done: int = 0
	var texture: Texture2D
	var color_slot: int = 7
	func _ready() -> void :
		set_process(false)
	func level() -> JuiceLevel:
		return model
	func state() -> Dictionary:
		return {"done": done}
	func pot_top_global_y() -> float:
		return global_position.y
	func full_blender_texture_for_type(_type_id: int) -> Texture2D:
		return texture
	func full_blender_texture_for_slot(_slot: int) -> Texture2D:
		return texture
	func slot_for_type(_type_id: int) -> int:
		return color_slot
	func cup_textures() -> Array[Texture2D]:
		return [] as Array[Texture2D]
	func cup_colors() -> PackedColorArray:
		return PackedColorArray()

var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :
	_check_config()
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"ComboFeedback": ProbeComboFeedback})
	page._progress_bling.effect_started.connect(page._quota.play_progress_impact)
	page._progress_bling.effect_stopped.connect(page._quota.stop_progress_impact)
	page._quota.progress_transform_changed.connect(page._progress_bling.sync_global_color_transform)
	page._build_fly_layer()
	var board: = ProbeBoard.new()
	board.model = JuiceLevel.from_dict({"id": 99001, "capacity": 2, "targetCups": 2, 
		"initial": ["0|0", "-|0", "1|1,1"], "incoming": ["x"]})
	var image: = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	board.texture = ImageTexture.create_from_image(image)
	page.add_child(board)
	page._board = board
	page._quota.setup(12)
	var bling: ProgressBling = page._progress_bling
	var effect_starts: Dictionary = {"count": 0}
	bling.effect_started.connect( func() -> void : effect_starts["count"] += 1)
	page._combo_tracker.reset(2, 1, 0, 0)
	board.done = 4
	page.apply_move_feedback(1)
	_check((page._combo_feedback as ProbeComboFeedback).counts == [2, 3, 4], 
		"Combo默认依次提交Nice、Great、Excellent，关闭流光不改变反馈")
	var prelude: float = page.CUP_FLY_SPINE_PREROLL_LEAD + page.CUP_BLOOM_DUR\
	+ page.CUP_FLY_RISE_DUR + page.CUP_FLY_HOLD_DUR
	var cases: Array[Dictionary] = [
		{"raw": "no", "override": -1}, {"raw": "yes", "override": -1}, 
		{"raw": "", "override": -1}, {"raw": "unknown", "override": -1}, 
		{"raw": "yes", "override": 0}, {"raw": "no", "override": 1}, 
		{"raw": "yes", "override": 99}]
	for test_case: Dictionary in cases:
		ABManager.set("sdk_value", test_case["raw"])
		UserState.clear_debug_ab_override("progress_bling")
		if int(test_case["override"]) >= 0:
			UserState.set_debug_ab_override("progress_bling", int(test_case["override"]))
		page._quota.setup(12)
		page.flight_started = false
		page._on_cup_collected(0, 0, Color.WHITE, Rect2(0, 0, 100, 100))
		var tw: Tween = page._cup_flights.back()["tw"]
		tw.pause()
		tw.custom_step(prelude + page.CUP_FLY_DUR - 0.01)
		_check(page._quota.filled_count() == 0 and page.flight_started, 
			"真实花盆仍飞向目标栏，落地前不点亮格位")
		tw.custom_step(0.02)
		_check(page._quota.filled_count() == 1 and page._cup_flights.is_empty(), 
			"落地后点亮一次并回收飞行记录")
		_check( not bling.is_playing() and int(effect_starts["count"]) == 0, 
			"关闭实验后旧SDK值和覆盖均不触发强化反馈：%s" % str(test_case))
		_check(int(ABManager.get("reads")) == 0 and int(ABManager.get("int_reads")) == 0
			and int(ABManager.get("dyes")) == 0, 
			"正式收盆不读取或染色退役参数")
	UserState.clear_debug_ab_override("progress_bling")
	page._quota.setup(12)
	page._start_cup_flight(0, null, Color.WHITE, Rect2(0, 0, 100, 100), 7)
	_check(page._quota.filled_count() == 1 and not bling.is_playing(), 
		"缺贴图仍即时点亮目标格，不触发强化反馈")
	_check(bling.play_normal(7), "独立组件仍可播放原槽7预览")
	var player: AnimationPlayer = bling.get_node("AnimationPlayer") as AnimationPlayer
	_check(bling.is_playing() and bling.visible, "组件预览启动真实单次动画")
	_check(is_equal_approx(player.get_animation(&"bling").length, 2.0)
		and player.get_animation(&"bling").loop_mode == Animation.LOOP_NONE, "2秒单圈不循环")
	_check(_color_texture(bling) == bling.normal_textures[7], "普通动效使用冻结外观槽7，不使用逻辑类型0")
	var effect_root: Control = bling.get_node("Root") as Control
	_check(is_zero_approx(effect_root.modulate.a), "整体从透明开始，无首帧闪现")
	player.advance(0.1)
	_check(is_equal_approx(effect_root.modulate.a, 0.5), "0.2秒平滑淡入，中点透明度0.5")
	player.advance(0.1)
	_check(is_equal_approx(effect_root.modulate.a, 1.0), "淡入结束保持完整原稿强度")
	player.advance(0.55)
	var clock: float = player.current_animation_position
	for node_name: String in ["Glow", "Soft", "Border"]:
		var mask: NinePatchRect = bling.get_node("Root/" + node_name) as NinePatchRect
		var angle: float = float((mask.material as ShaderMaterial).get_shader_parameter("angle"))
		_check(is_equal_approx(angle, 6.283 * 0.75 / 2.0), "原稿%s颜色方图线性旋转" % node_name)
	_check( not bling.has_node("Root/Particles"), "旧原稿粒子层已移除，不再播放旧动画")
	_check( not bling.play_excellent() and not bling.play_normal(0), "组件入口拒绝叠播")
	_check(_color_texture(bling) == bling.normal_textures[7]
		and is_equal_approx(player.current_animation_position, clock), "叠播不换色或重启动画")
	player.advance(0.95)
	_check(is_equal_approx(effect_root.modulate.a, 1.0), "1.7秒开始淡出")
	player.advance(0.15)
	_check(is_equal_approx(effect_root.modulate.a, 0.5), "末尾0.3秒淡出，中点透明度0.5")
	player.advance(0.16)
	_check(is_zero_approx(effect_root.modulate.a), "透明后才隐藏，无末帧突变")
	_check( not bling.is_playing() and not bling.visible, "单圈结束隐藏并释放播放守卫")
	var names: Array[String] = ["red", "purple", "pink", "cyan", "yellow", "green", "blue", "teal", "orange", "lavender", "violet", "lime"]
	_check(bling.normal_textures.size() == 12, "十二色资源完整")
	for color_slot: int in range(names.size()):
		_check(bling.play_normal(color_slot), "取消后可以重新播放槽%d" % color_slot)
		_check(_color_texture(bling).resource_path.ends_with("normal_%s.png" % names[color_slot]), "色槽资源对应%s" % names[color_slot])
		bling.hide_now()

	bling.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bling.size = Vector2(252.0, 274.0)
	bling._layout_effect()
	var border: NinePatchRect = bling.get_node("Root/Border") as NinePatchRect
	_check(is_equal_approx(border.position.y, JuiceQuotaBar.PANEL_Y)
		and is_equal_approx(border.size.x * border.scale.x, 242.0), "窄订单栏沿用白卡宽度与顶部")
	bling.size.x = 1056.0
	bling._layout_effect()
	_check(is_equal_approx(border.size.x * border.scale.x, 1046.0), "宽订单栏同步适配")
	var effect_count: int = int(effect_starts["count"])
	page._start_cup_flight(0, board.texture, Color.WHITE, Rect2(0, 0, 100, 100), 0)
	var cancelled_tw: Tween = page._cup_flights.back()["tw"]
	cancelled_tw.pause()
	cancelled_tw.custom_step(prelude + page.CUP_FLY_DUR * 0.5)
	page._cancel_cup_flights()
	await get_tree().create_timer(prelude + page.CUP_FLY_DUR + 0.05).timeout
	_check(int(effect_starts["count"]) == effect_count and not bling.is_playing(), 
		"飞行中取消Tween不补播落地动效")
	bling.play_excellent()
	_check(_color_texture(bling) == bling.excellent_texture, "Excellent预览保留高档资源")
	page._applying_undo = true
	var steps: int = page._combo_steps
	page._on_cups_changed()
	_check(page._combo_steps == steps and not bling.is_playing(), "撤销终止预览并保留Combo累计步数")
	page._applying_undo = false
	page._on_cups_changed()
	_check(page._combo_steps == 0, "重新起局沿用Combo重置")
	_check_additive_layers(page, bling)
	_check_full_preview(page, bling)
	_check_flower_color_mapping(page, bling)
	page.free()
	if _failures.is_empty():
		SortLogger.info("PROGRESS_BLING_SELFTEST PASS")
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check_config() -> void :
	_check(ABManager.find_config("Combo_Feedback") == null, "Combo反馈不再注册实验")
	_check(ABManager.find_config("progress_bling") == null, "退役参数不再注册或出现在AB面板")


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
		SortLogger.error("ProgressBling selftest: " + message)


func _color_texture(bling: ProgressBling) -> Texture2D:
	var border: NinePatchRect = bling.get_node("Root/Border") as NinePatchRect
	return (border.material as ShaderMaterial).get_shader_parameter("color_texture") as Texture2D


func _check_additive_layers(page: Variant, bling: ProgressBling) -> void :
	bling.hide_now()
	var player: AnimationPlayer = bling.get_node("AnimationPlayer") as AnimationPlayer
	var animation: Animation = player.get_animation(&"bling")
	_check(animation.get_track_count() == 7 and is_equal_approx(animation.length, 2.0), 
		"仅4条流光/透明度和3条粒子轨道，所有涟漪/旧粒子轨道移除")
	_check( not bling.has_node("Root/Particles") and bling._large_particles.size() == 3
		and bling._small_particles.size() == 3, "仅Unity运动的三类粒子，没有旧粒子层")
	var element_names: Array[String] = ["dot", "star", "flower"]
	for index: int in range(3):
		var large: GPUParticles2D = bling._large_particles[index]
		var small: GPUParticles2D = bling._small_particles[index]
		_check(large.texture.resource_path.ends_with("particle_%s.png" % element_names[index])
			and small.texture == large.texture, "原版%s元素静态贴图用于大小两组" % element_names[index])
		_check(is_equal_approx(large.speed_scale, 1.5) and large.use_fixed_seed and large.seed == 2312, 
			"三元素粒子使用Unity模拟速度/固定种子")
		_check((large.process_material as ParticleProcessMaterial).scale_max * 64.0 <= ProgressBling.LARGE_PARTICLE_MAX_DIAMETER + 0.001
			and (small.process_material as ParticleProcessMaterial).scale_max * 64.0 <= ProgressBling.SMALL_PARTICLE_MAX_DIAMETER + 0.001, 
			"缩小图案尺寸不超过避让边框使用的包围直径")
		var process: ParticleProcessMaterial = large.process_material as ParticleProcessMaterial
		var size_curve: Curve = (process.scale_curve as CurveTexture).curve
		var alpha: Gradient = (process.color_ramp as GradientTexture1D).gradient
		_check(is_equal_approx(process.lifetime_randomness, 0.2), "降低寿命离散，避免部分图案一闪而过")
		_check(size_curve.sample_baked(0.3) >= 0.99 and alpha.sample(0.3).a >= 0.99, 
			"前段保持清晰形状和透明度，不在淡入后立即变暗缩小")
		_check(size_curve.sample_baked(0.8) >= 0.59 and alpha.sample(0.8).a <= 0.001, 
			"图案缩成碎点之前完成淡出")
		for phase: float in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
			_check(size_curve.sample_baked(phase) >= 0.549 and size_curve.sample_baked(phase) <= 1.001, 
				"缩小保留形状下限，不反弹放大或缩成噪点")
		_check(large.material == bling.particle_match_material and small.material == large.material, 
			"三元素共享本次颜色而不是旧色动画")
	_check( not bling.has_node("ParticleRoot/Outline") and not bling.has_node("RipplePlateMask"), 
		"涟漪节点、遮罩Viewport完整移除，不只是隐藏")
	var border: NinePatchRect = bling.get_node("Root/Border") as NinePatchRect
	_check(border.texture.resource_path.ends_with("progress_bling/mask_outer.png"), 
		"旧遮罩外轮廓的薄边用于外沿对齐")
	_check(border.patch_margin_left == 80 and border.patch_margin_right == 80
		and border.scale == Vector2.ONE * 1.1, "新遮罩圆角保持比例，不横向拉扁")
	for slot: int in range(12):
		_check(bling.play_normal(slot), "原12色入口%d保留" % slot)
		var selected: Texture2D = bling.normal_textures[slot]
		_check(_color_texture(bling) == selected
			and bling.particle_match_material.get_shader_parameter("color_texture") == selected, 
			"流光和所有粒子共用槽%d原颜色纹理" % slot)
		var particle_color: Color = bling.particle_match_material.get_shader_parameter("effect_color")
		var ripple_material: ShaderMaterial = bling._impact_ripples.material as ShaderMaterial
		var ripple_color: Color = ripple_material.get_shader_parameter("ripple_color")
		_check(particle_color.is_equal_approx(ripple_color), "普通外圈和粒子使用同一正常花色")
		_check( not bool(ripple_material.get_shader_parameter("use_color_texture"))
			and not bool(bling.particle_match_material.get_shader_parameter("use_color_texture")), 
			"普通外圈和粒子不随颜色图变色")
		if slot < 10:
			_check(particle_color.is_equal_approx(bling.normal_ripple_color(slot)), "普通颜色与花色一致，仅校准淡紫素材色相")
		bling.hide_now()
	_check(bling.play_excellent(), "Excellent原入口保留")
	_check(_color_texture(bling) == bling.excellent_texture, 
		"高档原颜色纹理保留且统一取色")
	_check(bool((bling._impact_ripples.material as ShaderMaterial).get_shader_parameter("use_color_texture"))
		and bool(bling.particle_match_material.get_shader_parameter("use_color_texture")), 
		"炫彩外圈和粒子使用原炫彩颜色图，不替换成纯色")
	var small_count: int = 0
	var large_count: int = 0
	for track: int in [5, 6]:
		for key: int in range(animation.track_get_key_count(track)):
			var event: Dictionary = animation.track_get_key_value(track, key)
			if event.method == &"_emit_small_star":
				small_count += 1
			else:
				large_count += 1
	_check(small_count == 6 and large_count == 12, "按6/12分区低密度发射，不再把40颗挤在两条线上")
	_check(animation.track_get_key_time(6, 1) - animation.track_get_key_time(6, 0) < 0.075, 
		"左右首颗粒子相隔不足75ms，及时呼应")
	_check(animation.track_get_key_time(6, 11) < 0.9, "发射仍在原Unity窗口内，2秒内收完")
	var saved_size: Vector2 = bling.size
	for panel_width: float in [252.0, 852.0, 1056.0]:
		bling.size.x = panel_width
		var positions: Array[Vector2] = []
		for i: int in range(ProgressBling.LARGE_PARTICLE_COUNT):
			var point: Vector2 = bling._large_particle_birth(i)
			positions.append(point)
			_check((point.x > panel_width * 0.5) == (i % 2 == 1), "顶沿左右交替发射，不等半程才轮到右侧")
			var clearance: float = bling._particle_frame_clearance(ProgressBling.LARGE_PARTICLE_MAX_DIAMETER)
			_check( - point.y >= clearance - 0.001 and - point.y <= clearance + 8.001, 
				"顶部错落保持在既有8px带内，不扩大范围")
			var radius: float = ProgressBling.LARGE_PARTICLE_MAX_DIAMETER * sqrt(2.0) * 0.5 * panel_width / ProgressBling.STAR_SOURCE_WIDTH
			_check(point.y + radius <= - ProgressBling.PARTICLE_FRAME_GAP + 0.001, 
				"大粒子即使旋转也与顶沿留3px间隙")
			_check(absf(point.x - panel_width * 0.5) > minf(145.0, panel_width * 0.18), 
				"大粒子出生避开计数区域")
		var min_distance: float = INF
		for i: int in range(positions.size()):
			for j: int in range(i + 1, positions.size()):
				min_distance = minf(min_distance, positions[i].distance_to(positions[j]))
		_check(min_distance > 22.0 * panel_width / ProgressBling.STAR_SOURCE_WIDTH, 
			"宽度%d下分层出生距离大于最大图案宽度" % int(panel_width))
		for i: int in range(ProgressBling.SMALL_PARTICLE_COUNT):
			var point: Vector2 = bling._small_particle_birth(i)
			var radius: float = ProgressBling.SMALL_PARTICLE_MAX_DIAMETER * sqrt(2.0) * 0.5 * panel_width / ProgressBling.STAR_SOURCE_WIDTH
			_check(minf(point.x, panel_width - point.x) + radius <= - ProgressBling.PARTICLE_FRAME_GAP + 0.001, 
				"小粒子略在框外，旋转也不碰侧框")
			_check(point.y >= 45.0 and point.y <= 119.0, "小粒子保持在侧边范围")
	bling.size = saved_size
	bling._layout_effect()
	var rect: Rect2 = bling._flow_mask_rect()
	_check(is_equal_approx(rect.position.x, 5.0)
		and is_equal_approx(rect.position.y, JuiceQuotaBar.PANEL_Y)
		and is_equal_approx(rect.size.x, bling.size.x - 10.0), "旧遮罩贴实体外沿左右5px、顶部不内收")
	_check(is_equal_approx(rect.end.y, JuiceQuotaBar.BOARD_Y + 2.0), "新遮罩两侧末端接到托板背后")
	_check(is_equal_approx(border.scale.x, 1.1) and border.patch_margin_top == 80, 
		"保留完整圆角，不再缩成半尺寸或拉伸圆角末端")
	_check(border.position == rect.position and border.size * border.scale == rect.size, 
		"实际绘制矩形与内收目标一致")
	_check(_color_texture(bling) == bling.particle_match_material.get_shader_parameter("color_texture"), 
		"统一流光和粒子颜色，不再分层漂白")
	bling.hide_now()
	var dyes_before: int = int(ABManager.get("dyes"))
	var reads_before: int = int(ABManager.get("reads"))
	var state_before: Dictionary = page._board.state().duplicate(true)
	page._on_cheat_command("progress_bling_motion", ["on", "7"] as Array[String])
	_check(bling.is_playing() and bling._preview_looping
		and _color_texture(bling) == bling.normal_textures[7], "cheat可指定槽7并循环")
	page._on_cheat_command("progress_bling_motion", ["once", "excellent"] as Array[String])
	_check(bling.is_playing() and not bling._preview_looping
		and _color_texture(bling) == bling.excellent_texture, "cheat可指定Excellent单次")
	page._on_cheat_command("progress_bling_motion", ["on", "0", "base"] as Array[String])
	_check(bling.is_playing() and not bling._particle_root.visible and not bling._additions_playing, 
		"base对照只播放原版，不叠加新层")
	_check( not bling.has_node("Root/Particles"), "base也不恢复已经移除的旧粒子")
	page._on_cheat_command("progress_bling_motion", ["on", "all"] as Array[String])
	_check(_color_texture(bling) == bling.normal_textures[0], "全部颜色预览从原槽0开始")
	player.advance(2.01)
	bling._preview_timer.stop()
	bling._on_preview_timeout()
	_check(_color_texture(bling) == bling.normal_textures[1], "下一圈切到原槽1")
	page._on_cheat_command("progress_bling_motion", ["off"] as Array[String])
	_check( not bling.is_playing() and not bling._preview_looping and bling._preview_timer.is_stopped(), 
		"off清理原动画和新增层循环")
	_check(int(ABManager.get("dyes")) == dyes_before and int(ABManager.get("reads")) == reads_before
		and page._board.state() == state_before, "选色cheat不改AB或盘面")


func _check_full_preview(page: Variant, bling: ProgressBling) -> void :
	page._cancel_cup_flights()
	var quota: JuiceQuotaBar = page._quota
	var state_before: Dictionary = page._board.state().duplicate(true)
	var textures_before: Array[Texture2D] = quota._texs.duplicate()
	var count_before: String = quota._count.text
	var combo_before: int = page._combo_steps
	var dyes_before: int = int(ABManager.get("dyes"))
	var reads_before: int = int(ABManager.get("reads"))
	var resting_position: Vector2 = quota.position
	var resting_scale: Vector2 = quota.scale
	var resting_pivot: Vector2 = quota.pivot_offset
	page._on_cheat_command("progress_bling_full", ["once", "7"] as Array[String])
	_check(page._cup_flights.size() == 1 and page._progress_full_active, "完整cheat复用真实三段飞行")
	var tw: Tween = page._cup_flights.back()["tw"]
	tw.pause()
	var prelude: float = page.CUP_FLY_SPINE_PREROLL_LEAD + page.CUP_BLOOM_DUR + page.CUP_FLY_RISE_DUR + page.CUP_FLY_HOLD_DUR
	tw.custom_step(prelude + page.CUP_FLY_DUR - 0.01)
	_check( not bling.is_playing() and quota._progress_impact_tween == null, "落地前不抢播流光或整板动画")
	tw.custom_step(0.02)
	_check(bling.is_playing() and _color_texture(bling) == bling.normal_textures[7], "落地启动所选颜色的流光与粒子")
	_check(quota._preview_cup_texture != null and quota._progress_impact_tween != null, "落地覆盖测试盆、联动整个目标栏")
	_check(bling._impact_ripples.visible and bling._flow_root.visible and bling._particle_root.visible, 
		"落地外圈、旋转流光和粒子同帧并行启动")
	var impact: Tween = quota._progress_impact_tween
	impact.pause()
	impact.custom_step(0.045)
	_check(quota.position.is_equal_approx(resting_position)
		and quota.scale.is_equal_approx(resting_scale * JuiceQuotaBar.PROGRESS_IMPACT_SQUASH), "整板位置固定、以视觉中心等比收小")
	_check(quota.pivot_offset.is_equal_approx(Vector2(quota.size.x * 0.5, JuiceQuotaBar.PANEL_Y + JuiceQuotaBar.PANEL_H * 0.5)), 
		"支点位于背景板视觉中心，不在目标栏底部")
	_check(is_equal_approx(quota._board.position.y, JuiceQuotaBar.BOARD_Y), "木托板不再单独位移，与整个目标栏统一变换")
	impact.custom_step(0.025 + 0.085)
	_check(quota.position.is_equal_approx(resting_position)
		and quota.scale.is_equal_approx(resting_scale * JuiceQuotaBar.PROGRESS_IMPACT_STRETCH), "整板位置固定、等比回弹")
	impact.custom_step(0.06 + 0.09)
	_check(quota.position.is_equal_approx(resting_position) and quota.scale.is_equal_approx(resting_scale)
		and quota.pivot_offset.is_equal_approx(resting_pivot), "0.305秒恢复原位置、尺度及支点")
	var intro: Tween = bling._impact_tween
	intro.pause()
	intro.custom_step(ProgressBling.IMPACT_RIPPLE_DURATION - 0.001)
	_check(bling._impact_ripples.visible and bling._flow_root.visible, "外圈结束前旋转已在进行")
	intro.custom_step(0.002)
	_check( not bling._impact_ripples.visible and bling._flow_root.visible, "整板外圈结束不隐藏或重启旋转")
	page._on_cheat_command("progress_bling_full", ["off"] as Array[String])
	_check( not page._progress_full_active and page._progress_full_timer.is_stopped() and quota._preview_cup_texture == null, "off清掉循环、测试盆和流光")
	_check(page._cup_flights.is_empty() and not bling.is_playing(), "off不留测试飞行器")
	page._on_cheat_command("progress_bling_full", ["on", "all"] as Array[String])
	for index: int in range(13):
		var expected_slot: int = index if index < 12 else -1
		_check(page._progress_full_slot == expected_slot, "整体循环保留十二色和Excellent")
		var loop_tw: Tween = page._cup_flights.back()["tw"]
		loop_tw.pause()
		loop_tw.custom_step(prelude + page.CUP_FLY_DUR + 0.01)
		var expected: Texture2D = bling.normal_textures[index] if index < 12 else bling.excellent_texture
		_check(_color_texture(bling) == expected, "完整落地按选色播放，不替换原颜色纹理")
		bling.hide_now()
		page._progress_full_timer.stop()
		page._on_progress_full_preview_timeout()
	_check(page._progress_full_slot == 0, "Excellent后从首色重新循环")
	page._cancel_cup_flights()
	_check( not page._progress_full_active and page._cup_flights.is_empty() and quota._progress_impact_phase == 0.0, "撤销/起局/离页的取消入口清理完整cheat")
	_check(quota._texs == textures_before and quota._count.text == count_before and page._board.state() == state_before, 
		"完整预览不点亮真实格、不增加计数、不改盘面")
	_check(page._combo_steps == combo_before and int(ABManager.get("dyes")) == dyes_before and int(ABManager.get("reads")) == reads_before, 
		"完整预览不染AB、不读AB、不改Combo")


func _check_flower_color_mapping(page: Variant, bling: ProgressBling) -> void :
	page._cancel_cup_flights()
	var slot_names: Array[String] = ["red", "purple", "pink", "cyan", "yellow", "green", "blue", "teal", "orange", "lavender"]
	var skin: JuiceSkin = JuiceSkin.bead()
	var saved_slot: int = page._board.color_slot
	for type_id: int in range(JuiceTheme.SLOT_ORDER.size()):
		var appearance_slot: int = JuiceTheme.SLOT_ORDER[type_id]
		page._board.color_slot = appearance_slot
		page._on_cup_collected(type_id, 0, skin.colors[appearance_slot], Rect2(0, 0, 100, 100))
		var rec: Dictionary = page._cup_flights.back()
		_check(int(rec["color_slot"]) == appearance_slot, "花类型%d冻结映射到外观槽%d，不直接使用类型编号" % [type_id, appearance_slot])
		_check((rec["tint"] as Color).is_equal_approx(skin.colors[appearance_slot]), "飞行记录保留实际花色")
		page._cancel_cup_flights()
		bling.play_normal(appearance_slot, skin.colors[appearance_slot])
		_check(_color_texture(bling).resource_path.ends_with("normal_%s.png" % slot_names[appearance_slot]), 
			"冻结花色选择同名原流光颜色图")
		_check((bling.particle_match_material.get_shader_parameter("effect_color") as Color).is_equal_approx(bling.normal_ripple_color(appearance_slot)), 
			"普通粒子与实际花色一致")
		bling.hide_now()
	page._board.color_slot = saved_slot
