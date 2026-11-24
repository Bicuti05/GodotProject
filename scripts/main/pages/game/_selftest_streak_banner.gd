extends Node




var _failures: int = 0


func _ready() -> void :
	call_deferred("_run")


func _check(value: bool, label: String) -> void :
	if not value:
		_failures += 1
		SortLogger.error("[StreakBannerSelftest] FAIL: " + label)


func _run() -> void :
	var mapping: Dictionary = {
		"no": StreakBannerConfig.VALUE_ORIGINAL, 
		"yes1": StreakBannerConfig.VALUE_TIERED_BLOCKING, 
		"yes2": StreakBannerConfig.VALUE_TIERED_PASSTHROUGH, 
		"": StreakBannerConfig.VALUE_ORIGINAL, 
		"yes": StreakBannerConfig.VALUE_ORIGINAL, 
		"unknown": StreakBannerConfig.VALUE_ORIGINAL, 
	}
	for raw: String in mapping:
		_check(
			StreakBannerConfig.group_for_raw_string(raw) == int(mapping[raw]), 
			"AB 字符串映射：" + raw
		)

	var tiers: Dictionary = {
		2: StreakTierBanner.TIER_LV1, 5: StreakTierBanner.TIER_LV1, 
		6: StreakTierBanner.TIER_LV2, 10: StreakTierBanner.TIER_LV2, 
		11: StreakTierBanner.TIER_LV3, 100: StreakTierBanner.TIER_LV3, 
	}
	for count: int in tiers:
		_check(
			StreakTierBanner.tier_for_count(count) == int(tiers[count]), 
			"档位边界：" + str(count)
		)

	var picked: Dictionary = StreakCopy.pick_lines(7, 75.0, true, "")
	var lines: PackedStringArray = picked["lines"]
	_check(lines.size() == 2, "文案返回标题与副标题")
	_check(String(lines[0]).contains("7"), "标题包含连胜数")
	_check( not String(picked["key"]).is_empty(), "副标题 key 非空")

	var roll: StreakRollNumber = preload(
		"res://scripts/main/pages/game/streak_roll_number.tscn"
	).instantiate() as StreakRollNumber
	add_child(roll)
	await get_tree().process_frame
	roll.configure(160, Color.WHITE, Color.WHITE, Color.BLACK)
	roll.prepare(2, 3)
	_check(roll.visible and roll.get_node("From").visible, "滚动前数字立即显示")
	_check(roll.get_node("From").text == "2", "滚动前显示 N-1")
	_check( not roll.get_node("To").visible and roll._tween == null, "准备数字时不显示终点、不启动滚动")
	roll.play(2, 3)
	_check(roll.has_node("FromShadow") and roll.has_node("ToShadow"), "数字阴影层存在")
	_check(roll.get_node("From").text == "2", "滚动起点为 N-1")
	_check(roll.get_node("To").text == "3", "滚动终点为 N")
	roll.hide_now()
	roll.queue_free()

	var tier_banner: StreakTierBanner = preload(
		"res://scripts/main/pages/game/streak_tier_banner.tscn"
	).instantiate() as StreakTierBanner
	add_child(tier_banner)
	await get_tree().process_frame
	_check(tier_banner.has_node("Stage/Content/Lv1/NumberRoll"), "Lv1 数字滚动节点存在")
	var viewport_size: Vector2 = UiMetrics.viewport_size()

	var body_center: Vector2 = Vector2(
		StreakTierBanner.DESIGN_SIZE.x * 0.5, StreakTierBanner.BODY_CENTER_Y[0]
	)
	_check((tier_banner._stage.position + body_center * tier_banner._stage.scale).is_equal_approx(
		viewport_size * 0.5), "主体包围盒中心对齐屏幕正中")
	var title_label: Label = tier_banner.get_node("Stage/Content/Lv1/Title") as Label
	var title_base_label: Label = tier_banner.get_node("Stage/Content/Lv1/TitleBase") as Label
	var title_orange: Label = tier_banner.get_node("Stage/Content/Lv1/TitleOrange") as Label
	_check(title_base_label.get_theme_constant("outline_size") == 40, "标题描边按 Figma 10px OUTSIDE 落地")
	var title_base_shadow: Label = tier_banner.get_node("Stage/Content/Lv1/TitleBaseShadow") as Label
	_check(title_base_shadow.get_theme_constant("outline_size") == 40, "base 投影层与描边同宽")
	_check(is_equal_approx(StreakTierBanner.TITLE_SHADOW_OFFSET_Y, 4.8), "base 投影按 Figma y+4.8 下移")
	var title_mat: ShaderMaterial = title_label.material as ShaderMaterial
	_check( not bool(title_mat.get_shader_parameter("use_mid")), "标题字面使用双档黄色渐变")
	_check(title_orange.get_theme_color("font_shadow_color").is_equal_approx(
		Color(0.545098, 0.180392, 0.007843)), "橙色层投影取 Figma #8B2E02")
	_check(tier_banner.get_node("Stage/Content/Lv1").get_children().filter(
		func(node: Node) -> bool: return node is Label and String(node.name) in ["TitleBase", "TitleOrange", "Title"]
	).size() == 3, "标题由 base / 橙色 / 字面 3 层可见 Label 实现")
	_check(tier_banner.has_node("Stage/Content/Lv1/SubtitleShadow"), "副标题投影独立成层")
	_check(tier_banner.has_node("Stage/Content/Lv2/NumberRoll"), "Lv2 数字滚动节点存在")
	_check(tier_banner.has_node("Stage/Content/Lv3/NumberRoll"), "Lv3 数字滚动节点存在")
	_check(tier_banner.has_node("Stage/Spine"), "共享 Spine 美术节点存在")
	_check(tier_banner.get_node("Stage") is CanvasGroup, "Spine与文字先整体合成后淡出")
	var glow: TextureRect = tier_banner.get_node("Stage/Glow") as TextureRect
	_check(glow.texture.resource_path == "res://assets/effect/texture/glow/ef_glow_001.png", 
		"底光使用指定ef_glow_001贴图")
	_check(glow.get_index() < tier_banner.get_node("Stage/Spine").get_index(), "底光绘制在Spine下方")
	_check(glow.size.is_equal_approx(Vector2(900.0, 900.0)), "底光再次缩小25%")
	_check((glow.position + glow.size * 0.5).is_equal_approx(Vector2(540.0, 1130.0)), "底光中心再上移15像素")
	var burst: StreakBurstParticles = tier_banner.get_node("Stage/BurstParticles") as StreakBurstParticles
	_check(glow.get_index() < burst.get_index() and burst.get_index() < tier_banner.get_node("Stage/Spine").get_index(), 
		"扩散粒子位于底光上方、Spine后方")
	_check( not burst.visible, "扩散粒子默认隐藏")
	_check( not tier_banner.has_node("Stage/Content/Lv1/Shield"), "Lv1 旧盾牌节点已替换")
	_check( not tier_banner.has_node("Stage/Content/Lv2/Art"), "Lv2 旧主体节点已替换")
	_check( not tier_banner.has_node("Stage/Content/Lv3/ShieldFrame"), "Lv3 旧盾牌节点已替换")
	var spine: SpineSprite = tier_banner.get_node("Stage/Spine") as SpineSprite
	_check( not spine.visible, "Spine 默认隐藏")
	for tier_index: int in StreakTierBanner.SPINE_ANIMATIONS.size():
		var animation: SpineAnimation = spine.get_skeleton().get_data().find_animation(
			StreakTierBanner.SPINE_ANIMATIONS[tier_index]
		)
		_check(animation != null and is_equal_approx(animation.get_duration(), 4.0), 
			"三级素材动画存在且为4秒：" + str(tier_index + 1))
		_check(spine.get_skeleton().find_slot(StreakTierBanner.SPINE_SHIELD_SLOTS[tier_index]) != null, 
			"数字跟随的盾牌槽位存在：" + str(tier_index + 1))
	for count: int in [3, 7, 12]:
		var number: StreakRollNumber = tier_banner._numbers[StreakTierBanner.tier_for_count(count) - 1]
		var base_position: Vector2 = number.position
		var reference_rect: Rect2 = number.get_global_rect()
		tier_banner.play(count, false)
		_check(burst.visible == (count >= 11), "只在第三阶播放扩散粒子：" + str(count))
		_check(glow.modulate.to_html(false) == ["ffb67e", "35c2ff", "a135ff"][StreakTierBanner.tier_for_count(count) - 1], 
			"三级底光采用指定颜色：" + str(count))
		_check(is_zero_approx(glow.modulate.a), "底光从入场起点开始渐显")
		_check(number.is_visible_in_tree() and number.get_node("From").visible, 
			"数字随弹窗入场显示：" + str(count))
		_check(number.get_node("From").text == str(count - 1) and number._tween == null, 
			"入场先显示 N-1，不提前滚动：" + str(count))
		var initial_y: float = number.get_node("From").position.y
		tier_banner._process(StreakTierBanner.ROLL_DELAY * 0.5)
		_check(number.get_node("From").visible and is_equal_approx(number.get_node("From").position.y, initial_y), 
			"滚动延迟内保留起点数字：" + str(count))
		tier_banner._process(StreakTierBanner.ROLL_DELAY * 0.5)
		_check(number._tween != null and number.get_node("To").text == str(count), 
			"原定时点开始滚到 N：" + str(count))
		tier_banner._sample(0.0)
		_check(spine.visible and tier_banner._spine_track != null, "起播显示 Spine：" + str(count))
		_check(is_equal_approx(tier_banner._spine_track.get_track_time(), 0.0), "重播从第0帧开始")
		_check(tier_banner.get_node("Backdrop").visible, "三档弹窗均显示局内黑遮罩")
		_check(is_zero_approx(tier_banner._backdrop.color.a), "黑遮罩在入场起点透明")
		tier_banner._sample(StreakTierBanner.DURATION * StreakTierBanner.SPINE_REFERENCE_TIME / 4.0)
		_check(number.get_global_rect().position.is_equal_approx(reference_rect.position), 
			"稳定姿态数字保持原位置，Spine全局变换不重复叠加：" + str(count))
		_check(number.get_global_rect().size.is_equal_approx(reference_rect.size), 
			"稳定姿态数字保持原尺寸：" + str(count))
		_check(is_zero_approx(number.rotation), "数字保持正向，不因隐藏参考姿态翻转")
		_check(is_equal_approx(tier_banner._spine_track.get_track_time(), StreakTierBanner.SPINE_REFERENCE_TIME), 
			"素材4秒映射到弹窗2.6秒")
		tier_banner._sample(StreakTierBanner.EXIT_START)
		_check(is_equal_approx(tier_banner._backdrop.color.a, 0.8), "黑遮罩峰值不透明度80%")
		_check(is_equal_approx(glow.modulate.a, 1.0), "底光随主体保持显示直到退场起点")
		_check(is_equal_approx(spine.modulate.a, 1.0), "Spine 在2.25秒开始退场")
		_check(is_equal_approx(tier_banner._stage.self_modulate.a, 1.0), "合成层在退场起点保持完整显示")
		tier_banner._sample((StreakTierBanner.EXIT_START + StreakTierBanner.DURATION) * 0.5)
		_check(is_equal_approx(tier_banner._backdrop.color.a, 0.4), "黑遮罩随弹窗同步淡出")
		_check(is_equal_approx(tier_banner._stage.self_modulate.a, 0.5), "只对合成结果应用退场透明度")
		_check(is_equal_approx(spine.modulate.a, 1.0) and is_equal_approx(tier_banner._content.modulate.a, 1.0), 
			"退场不降低内部Spine和文字层透明度，避免叠层重影")
		tier_banner._sample(StreakTierBanner.DURATION)
		_check(is_zero_approx(tier_banner._backdrop.color.a), "黑遮罩退场完全透明")
		_check(is_zero_approx(tier_banner._stage.self_modulate.a), "合成层退场完全透明")
		tier_banner.hide_now()
		_check( not burst.visible and not burst._playing and burst._trails._ribbons.is_empty(), 
			"横幅取消或重播时清空粒子与拖尾")
		_check(is_zero_approx(glow.modulate.a) and glow.scale.is_equal_approx(Vector2.ONE), 
			"取消或重播时复位底光透明度与缩放")
		_check( not spine.visible and tier_banner._spine_track == null, "清场隐藏 Spine 并释放轨道")
		_check(is_equal_approx(tier_banner._stage.self_modulate.a, 1.0), "取消或重播时复位合成层透明度")
		_check(number.position.is_equal_approx(base_position) and number.scale.is_equal_approx(Vector2.ONE), 
			"清场复位数字定位，避免重播漂移")
	_check_particle_burst(burst)
	tier_banner.hide_now()
	tier_banner.queue_free()

	if _failures == 0:
		SortLogger.info("STREAK_BANNER_PASS")
	get_tree().quit(_failures)


func _check_particle_burst(burst: StreakBurstParticles) -> void :
	burst.play(31415)
	_check(burst._states.size() == 23 and burst._trails._ribbons.size() == 8, 
		"第一组15颗，第二组增加30%取整至8颗")
	for index: int in burst._states.size():
		var state: StreakBurstParticles.ParticleState = burst._states[index]
		var has_trail: bool = index >= StreakBurstParticles.PRIMARY_COUNT
		var min_size: float = StreakBurstParticles.BASE_SIZE * (1.25 if has_trail else 0.4)
		var max_size: float = StreakBurstParticles.BASE_SIZE * (3.75 if has_trail else 1.92)
		var range_multiplier: float = 1.5 if has_trail else 1.2
		_check(state.sprite.texture.resource_path == "res://assets/effect/texture/streak_banner/ef_point_010.png", 
			"使用改名后的用户星形贴图，不覆盖已有ef_point_009")
		_check(state.diameter >= min_size and state.diameter <= max_size, 
			"第一组尺寸不变，第二组在上版基础上增大25%")
		if has_trail:
			_check(is_equal_approx(burst._trails._ribbons[index - StreakBurstParticles.PRIMARY_COUNT].head_width, 
				state.diameter * StreakBurstParticles.TRAIL_WIDTH_RATIO), "拖尾宽度跟随第二组粒子尺寸")
		_check(state.start_speed >= StreakBurstParticles.BASE_SPEED * 0.5 * range_multiplier and state.start_speed <= StreakBurstParticles.BASE_SPEED * 1.5 * range_multiplier, 
			"粒子速度具备正负50%随机范围")
		_check(state.residual_speed > 0.0, "粒子减速后保留微弱速度")
		var base_lifetime: float = StreakBurstParticles.LIFETIME if has_trail else StreakBurstParticles.PRIMARY_LIFETIME
		_check(state.lifetime >= base_lifetime * 0.65 and state.lifetime <= base_lifetime * 1.35, 
			"两组粒子寿命随机度为正负35%")
		_check(state.tint.r >= StreakBurstParticles.PARTICLE_COLOR.r and state.tint.r <= 1.0\
		and state.tint.g >= StreakBurstParticles.PARTICLE_COLOR.g and state.tint.g <= 1.0\
		and is_equal_approx(state.tint.b, 1.0), "粒子颜色随机介于纯白和紫色之间")
		if not has_trail:
			_check(is_zero_approx(state.gravity), "第一组不受重力")
		else:
			var upward_angle: float = wrapf(state.direction.angle() + PI * 0.5, - PI, PI)
			_check(absf(upward_angle) <= StreakBurstParticles.TRAIL_SPREAD * 0.5, 
				"第二组发射方向在向上270度扇形内")
			_check(is_equal_approx(state.gravity, 53.9), "第二组重力在上版基础上减弱50%")
	var first: StreakBurstParticles.ParticleState = burst._states[0]
	var start: Vector2 = first.sprite.position
	burst.sample(0.1)
	var early_distance: float = first.sprite.position.distance_to(start)
	burst.sample(0.5)
	var settled: Vector2 = first.sprite.position
	burst.sample(0.6)
	var late_distance: float = first.sprite.position.distance_to(settled)
	_check(late_distance > 0.0 and early_distance > late_distance * 5.0, "先快速扩散、后平滑减速但不完全静止")
	var original_time: float = 0.6 / StreakBurstParticles.LIFETIME_RATIO
	var speed_factor: float = first.start_speed / StreakBurstParticles.BASE_SPEED
	var original_distance: float = 18.0 * speed_factor * original_time\
	+ (1450.0 - 18.0) * speed_factor * (1.0 - exp(-3.6 * original_time)) / 3.6
	_check(is_equal_approx(first.sprite.position.distance_to(start), original_distance * StreakBurstParticles.RANGE_RATIO), 
		"扩散范围在上版基础上再缩小25%")
	var falling: StreakBurstParticles.ParticleState = burst._states[StreakBurstParticles.PRIMARY_COUNT]
	var distance: float = falling.residual_speed * 0.6\
	+ (falling.start_speed - falling.residual_speed) * (1.0 - exp( - StreakBurstParticles.DECAY_RATE * 0.6)) / StreakBurstParticles.DECAY_RATE
	_check(is_equal_approx(falling.sprite.position.y - falling.start_position.y - falling.direction.y * distance, 
		0.5 * StreakBurstParticles.TRAIL_GRAVITY * 0.6 * 0.6), "第二组扩散时受减弱30%的重力产生下坠")
	var falling_fade: float = StreakBurstParticles.FADE_DURATION * falling.lifetime / StreakBurstParticles.LIFETIME
	burst.sample(falling.lifetime - falling_fade * 0.5)
	_check(is_equal_approx(falling.sprite.modulate.a, 0.5) and falling.ribbon.head_alpha > 0.375, 
		"拖尾淡出比粒子更慢")
	burst.sample(falling.lifetime)
	_check( not falling.sprite.visible and falling.ribbon.head_alpha > 0.0 and burst.visible, 
		"星形消失后仍保留拖尾余韵，不提前清空")
	burst.sample((StreakBurstParticles.LIFETIME + StreakBurstParticles.FADE_DURATION\
	* (StreakBurstParticles.TRAIL_FADE_MULTIPLIER - 1.0)) * 1.35 + 0.0001)
	_check(is_equal_approx(StreakBurstParticles.LIFETIME, 1.183) and not burst.visible\
	and burst._trails._ribbons.is_empty(), "两组各自寿命结束后同步清场")
	burst.play(31415)
	_check(first.sprite.position.is_equal_approx(start) and burst._trails._ribbons.size() == 8, 
		"重播从起点开始且不叠加旧拖尾")
	burst.reset()
	_check( not burst.visible and not burst._trails.is_processing() and burst._trails._ribbons.is_empty(), 
		"清场停用拖尾采样并删除残留")
	for state: StreakBurstParticles.ParticleState in burst._states:
		_check( not state.sprite.visible, "清场隐藏全部粒子")
