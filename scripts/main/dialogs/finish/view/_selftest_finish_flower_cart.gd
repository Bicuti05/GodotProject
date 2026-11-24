extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")

func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)

func _run() -> void :
	var layer: RewardLayer = load("res://scripts/main/dialogs/finish/view/reward_layer.tscn").instantiate()
	root.add_child(layer)
	_check_particle_materials(layer)
	_check(layer.get("_rainbow_source_points").is_empty(), "首次实例化不集中读图取样")
	await layer.prepare_render_points()
	var cart: SpineSprite = layer.get("_basket") as SpineSprite
	var skeleton: SpineSkeleton = cart.get_skeleton()
	for name: String in ["Appear", "Loop", "Disappear"]:
		_check(skeleton.get_data().find_animation(name) != null, "交付动画存在: " + name)
	_check(absf(skeleton.get_data().find_animation("Appear").get_duration() - RewardLayer.APPEAR_DUR) < 0.001, "入场等待来自实际Spine时长")
	_check(absf(skeleton.get_data().find_animation("Disappear").get_duration() - RewardLayer.DISAPPEAR_DUR) < 0.001, "原始Spine出场时长保持不变")
	_check(layer.get("_rear_wheels").size() == 2 and layer.get("_flower_bones").size() == 34, "真实后轮与花附件绑定")
	var rainbow: Sprite2D = layer.get("_rainbow") as Sprite2D
	var rainbow_stars: GPUParticles2D = layer.get("_rainbow_sparkles") as GPUParticles2D
	_check(rainbow.texture.resource_path.ends_with("finish/rainbow.png"), "静态绑定用户彩虹原图")
	_check((rainbow_stars.process_material as ParticleProcessMaterial).emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_POINTS and _point_samples(rainbow_stars).size() > 100, "彩虹闪烁只从Alpha轮廓出生")
	var image: Image = rainbow.texture.get_image()
	if image.is_compressed(): image.decompress()
	var expected_points: = PackedVector2Array()
	for y: int in range(0, image.get_height(), 24):
		for x: int in range(0, image.get_width(), 24):
			if image.get_pixel(x, y).a >= 0.4:
				expected_points.append(Vector2(x, y) - Vector2(image.get_size()) * 0.5)
	var point_data: Resource = load("res://assets/sprites/finish/rainbow_emission_points.tres")
	_check(point_data.get_meta("source_sha256") == FileAccess.get_sha256("res://assets/sprites/finish/rainbow.png"), "原图更新必须重生成发射点")
	_check(layer.get("_rainbow_source_points") == expected_points, "离线点完整保持原24px/Alpha0.40取样算法")
	for point: Vector2 in _point_samples(rainbow_stars):
		var source: Vector2 = (point - rainbow.position) / rainbow.scale + Vector2(image.get_size()) * 0.5
		_check(image.get_pixel(roundi(source.x), roundi(source.y)).a >= 0.39, "彩虹透明洞不产生闪光")
	var clip_slot: SpineSlot = skeleton.find_slot("root")
	_check(clip_slot != null and clip_slot.get_attachment() != null, "交付原骨架保留root裁剪附件")
	layer.play_appear(false)
	_check(clip_slot.get_attachment() == null, "运行时进场关闭窄裁剪框")
	_check(layer.get("_cart_phase") == 1 and not layer.get("_particles")[0].emitting, "进场不提前发花朵待机粒子")
	_check(is_zero_approx(layer.get("_rays").modulate.a) and is_zero_approx(layer.get("_rays").rotation), "进场期间旋转背景光隐藏且未旋转")
	_check(is_zero_approx(layer.get("_core").modulate.a), "光核与旋转光一起等花车停稳")
	_check(layer.get("_wheel_trails")[0].emitting and layer.get("_wheel_trails")[1].emitting, "两后轮各发射一份拖尾")
	for i: int in [1, 2, 3]:
		var tween: Tween = layer.get("_active_tweens")[i]
		tween.pause()
		tween.custom_step(0.19)
	_check(layer.get("_title_layers")[0].modulate.a == 0.0, "标题延后200ms才出现")
	for i: int in [1, 2, 3]:
		(layer.get("_active_tweens")[i] as Tween).custom_step(0.45)
	_check(is_equal_approx(layer.get("_title_layers")[0].modulate.a, 1.0), "标题640ms入场完成")

	var animation: SpineAnimationState = cart.get_animation_state()
	animation.update(0.9)
	animation.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_check(clip_slot.get_attachment() == null, "真实进场动画更新不恢复裁剪框")
	layer._update_cart_emitters(0.016)
	for i: int in 2:
		var wheel: SpineBone = layer.get("_rear_wheels")[i]
		var expected: Vector2 = layer._bone_in_fx(wheel) + Vector2(0.0, 118.0 * RewardLayer.BASKET_SCALE)
		_check((layer.get("_wheel_trails")[i] as GPUParticles2D).position.is_equal_approx(expected), "后轮拖尾随骨架运动")
	var idle_tween_start: int = layer.get("_active_tweens").size()
	layer._start_cart_idle()
	_check(clip_slot.get_attachment() == null, "待机保持无局部裁剪")
	_check(is_zero_approx(layer.get("_rays").modulate.a), "停稳那帧旋转光从零渐显，不突然出现")
	(layer.get("_active_tweens")[idle_tween_start] as Tween).custom_step(RewardLayer.RAYS_FADE_IN_DUR)
	(layer.get("_active_tweens")[idle_tween_start + 1] as Tween).custom_step(0.5)
	_check(is_equal_approx(layer.get("_rays").modulate.a, 1.0) and layer.get("_rays").rotation > 0.0, "待机后旋转光渐显并开始旋转")
	_check( not layer.get("_wheel_trails")[0].emitting and layer.get("_particles")[0].emitting, "停稳收轮尾，启动旧花朵闪烁")
	for particle: GPUParticles2D in layer.get("_particles"):
		_check(particle.amount == 7 and is_equal_approx(particle.lifetime, 1.7), "花朵闪烁保留上一版数量与寿命")
		_check((particle.process_material as ParticleProcessMaterial).emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_POINTS and _point_samples(particle).size() == 34, "花上粒子绑定各花，不散到车身")
	var left_butterfly: SpineSprite = layer.get("_butterfly_orange")
	_check(left_butterfly.skeleton_data_res.resource_path.ends_with("effect_butterfly_oringe.tres"), "左侧使用橙色自然扇翅骨架")
	_check(absf(left_butterfly.get_skeleton().get_bounds().size.x * left_butterfly.scale.x - 65.0) < 0.2, "左侧新骨架首帧实际宽度65px")

	for i: int in range(layer.get("_active_tweens").size() - 3, layer.get("_active_tweens").size()):
		(layer.get("_active_tweens")[i] as Tween).custom_step(RewardLayer.BUTTERFLY_FADE_DUR)
	layer._process(RewardLayer.BUTTERFLY_ARRIVE_DUR)
	var butterfly_positions: = PackedVector2Array()
	for entry: Dictionary in layer.get("_butterflies"):
		var node: SpineSprite = entry["node"]
		butterfly_positions.append(node.position)
		_check(absf(node.scale.x) * (RewardLayer.BUTTERFLY_BBOX_W_ORANGE if node.name == "ButterflyOrange" else RewardLayer.BUTTERFLY_BBOX_W_RED if node.name == "ButterflyRed" else RewardLayer.BUTTERFLY_BBOX_W_GREEN) <= 65.01, "蝴蝶缩至65px宽")
		var center: Vector2 = node.position + (entry["center_offset"] as Vector2)
		var flower: Vector2 = layer._bone_in_fx(entry["bone"] as SpineBone)
		_check(absf(center.x - flower.x) <= 8.01 and center.y < flower.y - 20.0, "蝴蝶落点跟随花上方而不是屏幕两侧")
	var title: CurveLabel = layer.get("_title_layers")[0]
	var band_y: float = rainbow.position.y + (RewardLayer.RAINBOW_BAND_CENTER_Y - image.get_height() * 0.5) * rainbow.scale.y
	var glyph_y: float = title.position.y + title.size.y * 0.5 - title.amplitude - float(title.get_theme_font_size("font_size")) * 0.4
	_check(is_equal_approx(band_y - glyph_y, 16.0), "彩虹中央彩带跟随弧形标题视觉中心")
	_check(is_equal_approx(rainbow.texture.get_width() * rainbow.scale.x, title.size.x * 1.344), "彩虹宽跟随标题宽")
	_check(is_equal_approx(rainbow.scale.y, 0.48), "彩虹竖向缩放为原图0.48倍")
	layer.play_disappear()
	_check(clip_slot.get_attachment() == null, "出场仍关闭裁剪框")
	for i: int in layer.get("_butterflies").size():
		var node: SpineSprite = layer.get("_butterflies")[i]["node"]
		_check(node.visible and node.position.is_equal_approx(butterfly_positions[i]), "Next时蝴蝶从原位置开始退场，不瞬间隐藏")
	for tween: Tween in layer.get("_active_tweens"):
		tween.pause()
		tween.custom_step(0.18)

	animation.update(0.55)
	animation.apply(skeleton)
	skeleton.update_world_transform(SpineConstant.Physics_Update)
	_check(clip_slot.get_attachment() == null, "真实出场骨骼更新不恢复裁剪")
	layer._process(0.55)
	for i: int in layer.get("_butterflies").size():
		var entry: Dictionary = layer.get("_butterflies")[i]
		var node: SpineSprite = entry["node"]
		var expected: Vector2 = layer._bone_in_fx(entry["bone"] as SpineBone) + (entry["carry_offset"] as Vector2)
		_check(node.visible and node.position.is_equal_approx(expected) and is_equal_approx(node.modulate.a, 1.0), "蝴蝶被花车带走，不另飞离或淡出")
		_check( not node.position.is_equal_approx(butterfly_positions[i]), "蝴蝶跟随真实出场位移，不停在原地")
	_check(layer.get("_particles")[0].modulate.a > 0.0 and layer.get("_particles")[0].modulate.a < 1.0, "花上粒子退出时淡出，不滞留或硬切")
	for tween: Tween in layer.get("_active_tweens"):
		tween.custom_step(0.5)
	for entry: Dictionary in layer.get("_butterflies"):
		_check((entry["node"] as SpineSprite).visible and is_equal_approx((entry["node"] as SpineSprite).modulate.a, 1.0), "花车出场途中蝴蝶保持扇翅与可见")
	_check(is_zero_approx(layer.get("_particles")[0].modulate.a), "花车退远前粒子已收完")
	_check(layer.get("_cart_phase") == 3 and not rainbow_stars.emitting, "出场停止闪烁与扫光发射")
	_check( not layer.get("_wheel_trails")[0].emitting and not layer.get("_particles")[0].emitting, "出场不新发轮尾或花闪光")
	layer.reset()
	_check( not layer.get("_butterfly_orange").visible and not layer.get("_butterfly_green").visible, "整页收尾才清蝴蝶")
	_check( not layer.visible and layer.get("_cart_phase") == 0, "复用恢复隐藏基线")
	_check(layer.get("_active_tweens").is_empty() and not rainbow_stars.visible, "复用无旧Tween和旧彩虹粒子")
	skeleton.set_to_setup_pose()
	_check(clip_slot.get_attachment() != null, "setup pose确实恢复原附件，未改共享资源")
	layer.play_appear(true, true)
	_check(clip_slot.get_attachment() == null, "缓存复用进场再次关闭恢复的裁剪附件")

	var untouched: SpineSprite = SpineSprite.new()
	untouched.skeleton_data_res = cart.skeleton_data_res
	root.add_child(untouched)
	_check(untouched.get_skeleton().find_slot("root").get_attachment() != null, "共享交付资源与其他骨架实例未修改")
	untouched.free()
	_check(layer.get("_title_layers")[0].modulate.a == 0.0, "再次进场不露上一局标题")
	_check(is_zero_approx(layer.get("_rays").modulate.a) and is_zero_approx(layer.get("_rays").rotation), "再次进场不露旧旋转光")
	_check(is_equal_approx(layer.get("_particles")[0].modulate.a, 1.0) and is_equal_approx(rainbow_stars.modulate.a, 1.0), "复用恢复粒子Alpha，不延续退场透明度")
	layer.reset()
	layer.free()
	await _test_warm_pose()
	var petals: GPUParticles2D = load("res://scripts/main/dialogs/finish/ui/confetti_fall.tscn").instantiate()
	_check(petals.texture.resource_path.ends_with("petal_gold_atlas.png"), "仅顶部下落层使用游戏已有花瓣图集")
	_check((petals.material as ShaderMaterial).shader.code.contains("petal_color_7"), "GPU下落花瓣保留原八色随机配色")
	_check(petals.amount == 26 and is_equal_approx(petals.lifetime, 8.0), "下落密度与时长不改")
	petals.free()
	_test_cart_screen_staging()

	var panel: FinishDialog = load("res://scripts/main/dialogs/finish/finish_dialog.tscn").instantiate()
	root.add_child(panel)
	await panel.prepare_for_display( func() -> bool: return true)
	panel._fireworks._ensure_pool()
	_check_particle_materials(panel)
	panel.reset_content()
	panel.visible = true
	var exit_count: Array[int] = [0]
	panel.next_pressed.connect( func() -> void : exit_count[0] += 1)
	panel._request_next()
	_check(exit_count[0] == 0 and panel.get("_next_requested"), "Next立即锁输入，但不提前导航")
	panel._request_next()
	var decoration: GPUParticles2D = panel.get_node("ConfettiFall")
	_check(decoration.modulate.a == 1.0, "Next点击瞬间不硬切下落粒子")
	(panel.get("_cart_exit_tween") as Tween).custom_step(0.22)
	_check(decoration.modulate.a > 0.0 and decoration.modulate.a < 1.0, "顶部花瓣与其他装饰统一淡出")
	(panel.get("_cart_exit_tween") as Tween).custom_step(0.58)
	_check(exit_count[0] == 0, "0.8秒可见退场尚未完成，不提前导航")
	(panel.get("_cart_exit_tween") as Tween).custom_step(0.11)
	_check(exit_count[0] == 1, "0.9秒可见退场结束后立即转发一次Next，不等待骨骼尾帧")
	panel.reset_content()
	panel.visible = true
	_check(decoration.modulate.a == 1.0, "面板复用恢复所有装饰Alpha")
	panel._request_next()
	panel.reset_content()
	await create_timer(0.03).timeout
	_check(exit_count[0] == 1 and panel.get("_cart_exit_tween") == null, "隐藏复用取消旧出场导航")
	panel.free()
	if _failures.is_empty():
		print("PASS: finish flower cart timeline, wheel anchors, rainbow mask, petals and delayed Next")
	else:
		for failure: String in _failures: push_error(failure)
	quit(0 if _failures.is_empty() else 1)



func _test_warm_pose() -> void :
	var layer: RewardLayer = load("res://scripts/main/dialogs/finish/view/reward_layer.tscn").instantiate()
	root.add_child(layer)

	layer.set("_cart_phase", 1)
	layer._start_rainbow_sparkles()
	layer.reset()
	await layer.prepare_render_points()
	_check( not layer.get("_rainbow_sparkles").visible and not layer.get("_rainbow_sparkles").emitting, "准备后立即复位清掉旧星点起播")
	layer.reset()
	layer._prepare_cart_warm_pose()
	var cart: SpineSprite = layer.get("_basket")
	_check(cart.get_animation_state().get_current(0).get_animation().get_name() == "Loop", "预绘直接应用Loop，避开屏外候场")
	var screen: Rect2 = Rect2(Vector2.ZERO, UiMetrics.viewport_size())
	var bounds: Rect2 = cart.get_skeleton().get_bounds()
	var visible_bounds: Rect2 = cart.get_global_transform() * bounds
	_check(visible_bounds.has_area() and screen.intersects(visible_bounds), "预绘花车有实际屏内可见面积")
	for bone: SpineBone in layer.get("_flower_bones"):
		_check(screen.has_point(cart.to_global(Vector2(bone.get_world_x(), bone.get_world_y()))), "预绘花附件在屏内")
	for butterfly: Dictionary in layer.get("_butterflies"):
		var node: SpineSprite = butterfly["node"]
		_check(node.visible and is_equal_approx(node.modulate.a, 1.0) and screen.has_point(node.global_position), "预绘三只蝴蝶可见且不透明")
	_check(layer.get("_active_tweens").is_empty(), "预绘姿态不启动业务Tween")
	var samples: PackedVector2Array = layer.get("_rainbow_source_points")
	layer.reset()
	await layer.prepare_render_points()
	_check(layer.get("_rainbow_source_points") == samples, "页面复用保留彩虹取样缓存")
	_check(layer.get("_butterflies").is_empty() and cart.get_animation_state().get_current(0) == null, "预绘后清空蝴蝶和花车轨道")
	layer.free()
	if DisplayServer.get_name() != "headless":
		await _test_warm_render()


func _test_warm_render() -> void :
	var panel: FinishDialog = load("res://scripts/main/dialogs/finish/finish_dialog.tscn").instantiate()
	var host: Node = Node.new()
	root.add_child(host)
	var parent: CanvasLayer = CanvasLayer.new()
	host.add_child(parent)
	parent.add_child(Node.new())
	parent.add_child(panel)
	parent.add_child(Node.new())
	var original_index: int = panel.get_index()

	var cache: Dictionary = SceneManager.get("_page_cache")
	var original_page: Node = SceneManager.get_page("finish")
	cache["finish"] = panel
	var observed: Dictionary = {"cart": false, "gpu": false, "draw_calls": 0}
	var on_draw: Callable = func() -> void :
		var viewport: SubViewport = host.get_node_or_null("FinishRenderWarmupViewport") as SubViewport
		if viewport == null or panel.get_parent() != viewport:
			return
		var reward: RewardLayer = panel.get("_reward")
		if reward.visible and reward.get("_cart_phase") == 2:
			observed["cart"] = true
			observed["gpu"] = reward.get("_particles")[0].visible and reward.get("_particles")[0].emitting\
			and reward.get("_rainbow_sparkles").visible and reward.get("_rainbow_sparkles").emitting
			observed["draw_calls"] = maxi(int(observed["draw_calls"]), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	RenderingServer.frame_post_draw.connect(on_draw)
	await panel.prepare_render_pool()
	var viewport: = SubViewport.new()
	viewport.name = "FinishRenderWarmupViewport"
	viewport.size = Vector2i(UiMetrics.viewport_size())
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(viewport)
	panel.hide()
	panel.reparent(viewport, false)
	await panel.warm_render_pipeline()
	panel.hide()
	panel.reset_content()
	panel.reparent(parent, false)
	parent.move_child(panel, original_index)
	viewport.queue_free()
	RenderingServer.frame_post_draw.disconnect(on_draw)
	_check(observed["cart"] and observed["gpu"] and int(observed["draw_calls"]) > 0, "真实离屏预热提交花车及GPU粒子绘制")
	_check(panel.get_parent() == parent and panel.get_index() == original_index and not panel.visible, "预热结束恢复原父节点、顺序及隐藏状态")
	var reward: RewardLayer = panel.get("_reward")
	_check(reward.get("_active_tweens").is_empty() and reward.get("_cart_phase") == 0, "真实预热收尾清空业务动画")
	for particle: GPUParticles2D in reward.get("_particles") + reward.get("_wheel_trails") + [reward.get("_rainbow_sparkles")]:
		_check( not particle.visible and not particle.emitting and is_zero_approx(particle.preprocess), "预热后粒子停发隐藏且恢复预模拟配置")
	reward.play_appear(false)
	_check(reward.get("_cart_phase") == 1 and is_zero_approx(reward.get("_rays").modulate.a), "预热后正式入场重新从Appear及隐藏背景光开始")
	reward.reset()
	if original_page != null:
		cache["finish"] = original_page
	else:
		cache.erase("finish")
	host.free()
	print("PASS: rendered finish warmup and cached-page reset")



func _test_cart_screen_staging() -> void :
	var original_size: Vector2i = root.size
	var original_scale: Vector2i = root.content_scale_size
	for viewport_size: Vector2i in [Vector2i(1080, 2340), Vector2i(1080, 2600), Vector2i(1755, 2340), Vector2i(3120, 2340)]:
		root.content_scale_size = viewport_size
		root.size = viewport_size
		for presentation_scale: float in [1.0, 0.65]:
			var layer: RewardLayer = load("res://scripts/main/dialogs/finish/view/reward_layer.tscn").instantiate()
			root.add_child(layer)
			layer.pivot_offset = Vector2(UiMetrics.center_x(), 0.0)
			layer.scale = Vector2.ONE * presentation_scale
			if presentation_scale < 1.0:
				layer.position.y = -200.0
			layer._layout()
			var cart: SpineSprite = layer.get("_basket")
			var skeleton: SpineSkeleton = cart.get_skeleton()
			var state: SpineAnimationState = cart.get_animation_state()
			var rest_points: = PackedVector2Array()
			for stage: Dictionary in layer.get("_pot_staging"):
				var bone: SpineBone = stage["bone"]
				rest_points.append(cart.to_global(Vector2(bone.get_world_x(), bone.get_world_y())))
			layer.play_appear(false)
			for sample: float in [0.0, 0.72, 1.4]:
				state.clear_tracks()
				skeleton.set_to_setup_pose()
				state.set_animation("Appear", false, 0)
				state.update(sample)
				state.apply(skeleton)
				layer._disable_cart_clipping()
				layer._adapt_cart_staging(cart)
				skeleton.update_world_transform(SpineConstant.Physics_Update)
				if sample < 0.73:
					var wheel: SpineBone = skeleton.find_bone("car2")
					var left_wheel: Vector2 = cart.to_global(Vector2(wheel.get_world_x(), wheel.get_world_y()))
					_check(left_wheel.x - 240.0 * absf(cart.global_scale.x) > UiMetrics.viewport_size().x, 
						"候场花车完全在右屏外: %s scale=%s t=%s" % [viewport_size, presentation_scale, sample])
				for stage: Dictionary in layer.get("_pot_staging"):
					var bone: SpineBone = stage["bone"]
					var center: Vector2 = cart.to_global(Vector2(bone.get_world_x(), bone.get_world_y()))
					_check(center.y + 260.0 * absf(cart.global_scale.y) < 0.0, 
						"候场花盆含花瓣边界完全在顶屏外: %s scale=%s t=%s y=%s" % [viewport_size, presentation_scale, sample, center.y])
			state.clear_tracks()
			skeleton.set_to_setup_pose()
			state.set_animation("Appear", false, 0)
			state.update(RewardLayer.APPEAR_DUR)
			state.apply(skeleton)
			layer._adapt_cart_staging(cart)
			skeleton.update_world_transform(SpineConstant.Physics_Update)
			for i: int in rest_points.size():
				var bone: SpineBone = layer.get("_pot_staging")[i]["bone"]
				var center: Vector2 = cart.to_global(Vector2(bone.get_world_x(), bone.get_world_y()))
				_check(center.distance_to(rest_points[i]) < 2.0, "幅度适配不改停靠点: %s scale=%s" % [viewport_size, presentation_scale])
			for sample: float in [0.0, 0.2, 0.4, 0.4667, 0.5]:
				state.clear_tracks()
				skeleton.set_to_setup_pose()
				state.set_animation("Disappear", false, 0)
				state.update(sample)
				state.apply(skeleton)
				var exit_bone: SpineBone = skeleton.find_bone("bone")
				var original_x: float = exit_bone.get_x()
				_check(original_x >= float(layer.get("_exit_base_x")), "采样覆盖右移蓄力及回到停靠点前: t=%s" % sample)
				layer._adapt_cart_staging(cart)
				_check(is_equal_approx(exit_bone.get_x(), original_x), 
					"右移蓄力保持交付动画幅度: %s scale=%s t=%s" % [viewport_size, presentation_scale, sample])
			state.clear_tracks()
			skeleton.set_to_setup_pose()
			state.set_animation("Disappear", false, 0)
			state.update(0.9)
			state.apply(skeleton)
			layer._disable_cart_clipping()
			layer._adapt_cart_staging(cart)
			skeleton.update_world_transform(SpineConstant.Physics_Update)
			var right_wheel: SpineBone = skeleton.find_bone("car6")
			var right_position: Vector2 = cart.to_global(Vector2(right_wheel.get_world_x(), right_wheel.get_world_y()))
			_check(right_position.x + 380.0 * absf(cart.global_scale.x) < 0.0, 
				"0.9秒出口时车把和蝴蝶余量都在左屏外: %s scale=%s x=%s" % [viewport_size, presentation_scale, right_position.x])
			_test_cart_staging_after_reuse(layer, viewport_size, presentation_scale)
			layer.reset()
			layer.free()
	root.content_scale_size = original_scale
	root.size = original_size



func _test_cart_staging_after_reuse(layer: RewardLayer, viewport_size: Vector2i, presentation_scale: float) -> void :
	for repeat_index: int in 4:
		var cart: SpineSprite = layer.get("_basket")
		var skeleton: SpineSkeleton = cart.get_skeleton()
		var state: SpineAnimationState = cart.get_animation_state()
		var entry_bone: SpineBone = skeleton.find_bone("bone2")
		var exit_bone: SpineBone = skeleton.find_bone("bone")
		var context: String = "%s scale=%s repeat=%d" % [viewport_size, presentation_scale, repeat_index]
		_check(is_equal_approx(float(layer.get("_entry_base_x")), entry_bone.get_data().get_x()), 
			"复用后进场基准来自setup pose: " + context)
		_check(is_equal_approx(float(layer.get("_exit_base_x")), exit_bone.get_data().get_x()), 
			"复用后退场基准来自setup pose: " + context)
		for stage: Dictionary in layer.get("_pot_staging"):
			var bone: SpineBone = stage["bone"]
			_check(is_equal_approx(float(stage["base_y"]), bone.get_data().get_y()), 
				"复用后花盆基准来自setup pose: " + context)
		layer.play_appear(false)
		state.clear_tracks()
		skeleton.set_to_setup_pose()
		state.set_animation("Appear", false, 0)
		state.apply(skeleton)
		layer._disable_cart_clipping()
		layer._adapt_cart_staging(cart)
		skeleton.update_world_transform(SpineConstant.Physics_Update)
		var left_wheel: SpineBone = skeleton.find_bone("car2")
		var left_position: Vector2 = cart.to_global(Vector2(left_wheel.get_world_x(), left_wheel.get_world_y()))
		_check(left_position.x - 240.0 * absf(cart.global_scale.x) > UiMetrics.viewport_size().x, 
			"重复复用后花车从右屏外进场: " + context)
		state.update(RewardLayer.APPEAR_DUR)
		state.apply(skeleton)
		layer._adapt_cart_staging(cart)
		skeleton.update_world_transform(SpineConstant.Physics_Update)
		layer.play_disappear()
		state.update(0.4)
		state.apply(skeleton)
		var lunge_x: float = exit_bone.get_x()
		layer._adapt_cart_staging(cart)
		_check(is_equal_approx(exit_bone.get_x(), lunge_x), "重复复用不放大右移蓄力: " + context)
		state.update(0.5)
		state.apply(skeleton)
		layer._adapt_cart_staging(cart)
		skeleton.update_world_transform(SpineConstant.Physics_Update)
		var right_wheel: SpineBone = skeleton.find_bone("car6")
		var right_position: Vector2 = cart.to_global(Vector2(right_wheel.get_world_x(), right_wheel.get_world_y()))
		_check(right_position.x + 380.0 * absf(cart.global_scale.x) < 0.0, 
			"重复复用后0.9秒花车与蝴蝶余量完全离屏: " + context)


func _point_samples(particle: GPUParticles2D) -> PackedVector2Array:
	var pm: ParticleProcessMaterial = particle.process_material as ParticleProcessMaterial

	var layer: RewardLayer = particle.get_parent().get_parent() as RewardLayer
	var image: Image = layer.get("_rainbow_point_image") if particle.name == "RainbowSparkles" else layer.get("_flower_point_image")
	_check(pm.emission_point_texture == layer.get("_rainbow_point_texture" if particle.name == "RainbowSparkles" else "_flower_point_texture"), "发射器绑定真实出生点纹理")
	_check(image.get_format() == pm.emission_point_texture.get_format(), "出生点上传图与纹理格式一致: " + str(particle.name))
	var points: = PackedVector2Array()
	for i: int in pm.emission_point_count:
		var point: Color = image.get_pixel(i, 0)
		points.append(Vector2(point.r, point.g))
	return points


func _check_particle_materials(node: Node) -> void :
	_check( not node is CPUParticles2D, "完成页发射器使用GPU粒子: " + str(node.name))
	if node is GPUParticles2D:
		var pm: ParticleProcessMaterial = node.process_material as ParticleProcessMaterial
		_check(pm != null and pm.particle_flag_disable_z, "GPU材质显式关闭Z模拟: " + str(node.name))
	for child: Node in node.get_children():
		_check_particle_materials(child)
