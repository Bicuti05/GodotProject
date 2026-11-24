extends Node
const PAGE_FIXTURE = preload("res://scripts/main/pages/game/_selftest_game_page_fixture.gd")


class ProbePage extends JuiceGamePage:
	func _ready() -> void :
		set_process(false)
	func _reset_hint_guide(_immediate: bool = false) -> void :
		pass
	func _clear_hint_guide_motion(_immediate: bool = false) -> void :
		pass



class ProbeFeedback extends ComboFeedback:
	var submitted: Array[Dictionary] = []
	func play(combos: Array[int], _feedback_center: Vector2, 
			haptic_events: Array[int] = [], fullscreen_fx_enabled: bool = false, 
			petal_feedback_enabled: bool = false, _timing_feedback_variant: int = 1) -> void :

		for i: int in combos.size():
			submitted.append({"count": combos[i], 
				"haptic_event": haptic_events[i] if i < haptic_events.size() else -1, 
				"fullscreen_fx_enabled": fullscreen_fx_enabled, "fullscreen_dyes": ABManager.get("fullscreen_dyes"), 
				"petal_feedback_enabled": petal_feedback_enabled, "frequency_dyes": ABManager.get("frequency_dyes")})



class ProbeEndPage extends ProbePage:
	var end_preparations: int = 0
	func request_finish_preparation() -> void :
		pass
	func _prepare_round_end(_active: Callable) -> bool:
		end_preparations += 1
		visible = false
		return false



class ProbeFullscreenFeedback extends ComboFeedback:
	var stages: Array[int] = []
	var petals: int = 0
	func _play_top_petals() -> void :
		petals += 1
		super._play_top_petals()
	func _play_fullscreen_fx_stage_one() -> void :
		stages.append(1)
		super._play_fullscreen_fx_stage_one()
	func _play_fullscreen_fx_stage_two() -> void :
		stages.append(2)
		super._play_fullscreen_fx_stage_two()
	func _play_fullscreen_fx_stage_three() -> void :
		stages.append(3)
		super._play_fullscreen_fx_stage_three()



class ProbeBoard extends JuiceBoardView:
	var done: int = 0
	func _ready() -> void :
		set_process(false)
	func state() -> Dictionary:
		return {"done": done}
	func pot_top_global_y() -> float:
		return 500.0


var _failures: Array[String] = []


func _ready() -> void :
	call_deferred("_run")


func _run() -> void :
	if "--combo-sfx-only" in OS.get_cmdline_user_args():
		_check_sfx_config()
		await _check_sfx_page()
		for failure: String in _failures:
			SortLogger.error(failure)
		if _failures.is_empty():
			SortLogger.info("COMBO_SFX_SELFTEST PASS")
		get_tree().quit(0 if _failures.is_empty() else 1)
		return
	_check_tracker()
	_check_feedback_queue()
	_check_outer_glow()

	_check_haptic_profiles()
	await _check_haptic_page()
	await _check_haptic_trigger_log()
	var failures_before_queue: int = _failures.size()
	_check_haptic_queue()
	if _failures.size() == failures_before_queue:
		SortLogger.info("[ComboHapticTest] 开关关闭/恢复、取消待播、快照及通关优先级 PASS")
	_check_fullscreen_config()
	for raw: String in ["no", "yes"]:
		await _check_fullscreen_page(raw)
	_check_fullscreen_queue()
	_check_frequency_config()
	for raw: String in ["old", "new"]:
		for fullscreen_raw: String in ["no", "yes"]:
			await _check_frequency_page(raw, fullscreen_raw)
	_check_frequency_petals()
	await _check_frequency_end_wait()
	_check_sfx_config()
	await _check_sfx_page()
	if _failures.is_empty():
		SortLogger.info("COMBO_FEEDBACK_SELFTEST PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			SortLogger.error(failure)
		get_tree().quit(1)



func _check_fullscreen_config() -> void :
	var config: ComboFullscreenFxConfig = ABManager.combo_fullscreen_fx
	config.clear_debug_override()
	_check(ABManager.find_config("combo_fullscreen_fx") == config and config.group_count == 2
		and config.version == "1.0.10" and config.default_value == 0
		and config.timing == ABManager.TIMING_COMBO_HAPTIC, "全屏反馈注册、版本、默认值及共用时机一致")
	ABManager.set("_is_init_done", false)
	config._value_loaded = false
	_check( not config.is_fullscreen_fx_enabled() and not config._value_loaded, "全屏反馈 SDK 未就绪不启用、不缓存")
	ABManager.set("_is_init_done", true)
	for raw: Variant in ["no", "yes", "", "unknown", "YES", "true", 1, true, null]:
		ABManager.set("fullscreen_sdk_value", raw)
		config._value_loaded = false
		var expected: int = 1 if raw is String and raw == "yes" else 0
		_check(config.peek_value() == expected and config.peek_sdk_value() == expected, "全屏反馈实时读取：%s" % str(raw))
		_check(config.value() == expected, "全屏反馈懒加载经过字符串钩子")
		config.load_value_silent()
		_check(config._value == expected, "全屏反馈静默预取经过字符串钩子")
		config.reload_value()
		_check(config._value == expected, "全屏反馈染色读取经过字符串钩子")
	_check(int(ABManager.get("fullscreen_int_reads")) == 0, "全屏反馈不走 SDK 整数通道")
	for group: int in [0, 1]:
		config.set_debug_override(group)
		_check(config.is_fullscreen_fx_enabled() == (group == 1), "全屏反馈 Cheat 0/1 语义正确")
	config.clear_debug_override()



func _check_fullscreen_page(raw: String) -> void :
	ABManager.set("fullscreen_sdk_value", raw)
	ABManager.set("fullscreen_reads", 0)
	ABManager.set("fullscreen_dyes", 0)
	ABManager.combo_fullscreen_fx._value_loaded = false
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"ComboFeedback": ProbeFeedback, "Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	page._combo_tracker.reset(2, 1, 0, 0)
	board.done = 1
	page.apply_move_feedback(1)
	_check(int(ABManager.get("fullscreen_reads")) == 0 and int(ABManager.get("fullscreen_dyes")) == 0, 
		"首盆不读取或染色全屏反馈")
	HapticManager.set_enabled(false)
	board.done = 4
	page.apply_move_feedback(2)
	var feedback: ProbeFeedback = page._combo_feedback as ProbeFeedback
	_check(feedback.submitted.size() == 3 and int(ABManager.get("fullscreen_dyes")) == 1, 
		"首次 Nice 统一染色共用时机")
	for submitted: Dictionary in feedback.submitted:
		_check(submitted["fullscreen_fx_enabled"] == (raw == "yes") and submitted["fullscreen_dyes"] == 1, 
			"反馈提交前已染色，冻结正确全屏分组")
	page._combo_tracker.sync_done(3)
	board.done = 4
	page.apply_move_feedback(3)
	page._combo_tracker.reset(2, 1, 0, 0)
	page._combo_steps = 0
	board.done = 2
	page.apply_move_feedback(1)
	_check(int(ABManager.get("fullscreen_dyes")) == 1, "撤销及起局复用不重复染色全屏反馈")
	HapticManager.set_enabled(true)
	page.free()



func _check_fullscreen_queue() -> void :
	var failures_before: int = _failures.size()
	var scene: PackedScene = load("res://scripts/main/pages/game/combo_feedback.tscn") as PackedScene
	var component: Control = scene.instantiate() as Control
	component.set_script(ProbeFullscreenFeedback)
	var feedback: ProbeFullscreenFeedback = component as ProbeFullscreenFeedback
	add_child(feedback)
	_check(is_equal_approx(ComboFeedback.FULLSCREEN_FX_DURATION, 1.0), "全屏各阶段目标持续1秒")
	feedback.play([2, 3, 4, 5, 6, 7, 8, 9, 10], Vector2(300.0, 200.0), [], true)
	var expected_stages: Array[int] = [1, 1, 1, 2, 2, 2, 3, 3, 3]
	for i: int in expected_stages.size():
		_check(feedback.stages == expected_stages.slice(0, i + 1), "当前词起播时才调用正确阶段：%d" % (i + 2))
		feedback._tween.custom_step(2.0)
	_check(feedback._pending.is_empty() and feedback._tween == null, "全屏接口不改变队列收尾")
	feedback.stages.clear()
	feedback.play([4, 5], Vector2.ZERO, [], true)
	feedback.play([8], Vector2.ZERO, [], false)
	_check(feedback.stages == [1] and feedback._pending[0]["fullscreen_fx_enabled"]
		and not feedback._pending.back()["fullscreen_fx_enabled"], "切组不改写旧批，待播阶段不提前调用")
	feedback._tween.custom_step(2.0)
	_check(feedback.stages == [1, 2], "旧批保留实验阶段")
	feedback._tween.custom_step(2.0)
	_check(feedback.stages == [1, 2], "新批对照不调用全屏接口")
	feedback.hide_now()
	feedback.stages.clear()
	feedback.play([4, 5], Vector2.ZERO, [], true)
	feedback.play([2], Vector2.ZERO, [], true)
	_check(feedback.stages == [1, 1] and feedback._pending.is_empty(), "新连续链清掉旧阶段，不补播")
	feedback.hide_now()
	feedback.play([4, 5], Vector2.ZERO, [], true)
	feedback.hide_now()
	var stages_before: int = feedback.stages.size()
	var dyes_before: int = int(ABManager.get("fullscreen_dyes"))
	var reads_before: int = int(ABManager.get("fullscreen_reads"))
	feedback.play([2, 5, 8], Vector2.ZERO)
	for i: int in range(3):
		feedback._tween.custom_step(2.0)
	_check(feedback.stages.size() == stages_before and int(ABManager.get("fullscreen_dyes")) == dyes_before
		and int(ABManager.get("fullscreen_reads")) == reads_before, "取消及默认预览不补播全屏、不读AB、不染色")
	feedback.free()
	if _failures.size() == failures_before:
		SortLogger.info("[ComboFullscreenFxTest] 三阶段/级联/高次数/取消/快照/预览 PASS")



func _check_tracker() -> void :
	var tracker: JuiceComboTracker = JuiceComboTracker.new()
	tracker.reset(2, 1, 0, 0)
	_check(tracker.on_move(1, 8, 0) == [2, 3, 4, 5, 6, 7, 8], "一步级联保留原七档序列")
	_check(tracker.on_move(9, 9, 15001) == [9], "步数恰好在窗口边界仍续接")
	_check(tracker.on_move(18, 10, 30001) == [10], "时间恰好15秒仍续接")
	_check(tracker.on_move(27, 11, 45002).is_empty(), "两个窗口都超出时重新起计数")
	_check(tracker.on_move(28, 12, 45003) == [2], "新连续链第二盆回到Nice")
	tracker.sync_done(11)
	_check(tracker.on_move(29, 12, 45004) == [3], "撤销只同步盆数，不重置连续档位")
	tracker.reset(2, 1, 0, 12)
	_check(tracker.on_move(1, 13, 0).is_empty() and tracker.on_move(2, 14, 1) == [2], 
		"起局或续局重置后重新积累连续链")



func _check_feedback_queue() -> void :
	var scene: PackedScene = load("res://scripts/main/pages/game/combo_feedback.tscn") as PackedScene
	var feedback: ComboFeedback = scene.instantiate() as ComboFeedback
	add_child(feedback)
	var original: SpineSprite = feedback.get_node("Spine") as SpineSprite
	var timing: SpineSprite = feedback.get_node("TimingSpine") as SpineSprite
	_check( not original.visible and not timing.visible, "两套Spine场景默认隐藏")
	var sounds: Array = AudioManager.get("played") as Array
	var sounds_before: int = sounds.size()
	feedback.play([8, 9, 10], Vector2(300.0, 200.0))
	_check(original.visible and not timing.visible, "原版反馈起播常驻Spine")
	_check(sounds.size() == sounds_before + 1 and sounds.back()["id"] == &"combo_legendary"
		and is_equal_approx(float(sounds.back()["pitch"]), 1.0), "首次起播原调，待播项不发声")
	_check(feedback._pending.size() == 2 and feedback._pending[0]["count"] == 9, "待播反馈保留原始档位")
	feedback.play([11], Vector2(300.0, 200.0))
	_check(feedback._pending[0]["count"] == 9 and feedback._pending.back()["count"] == 11, 
		"新批不改写旧批待播项")
	feedback.hide_now()
	_check(feedback._pending.is_empty() and feedback._tween == null and feedback._sfx_id == &""
		and not original.visible and not timing.visible and not feedback.is_playing()
		and original.get_animation_state().get_current(0) == null, "清场隐藏两套Spine、清轨道、Tween、声音及队列")
	_check((AudioManager.get("active") as Dictionary).is_empty(), "清场停止已起播语音")
	_check(sounds.size() == sounds_before + 1, "取消队列不补播后续批次")
	feedback.play([9, 10], Vector2(300.0, 200.0))
	_check(original.visible and not timing.visible and feedback.is_playing(), "取消后重播原版反馈")
	_check(original.get_skeleton().get_skin().get_name() == "Legendary!", "高次数仍选择 Legendary 皮肤")

	_check(sounds.back()["id"] == &"combo_legendary" and is_equal_approx(float(sounds.back()["pitch"]), 1.0), 
		"高次数起播原调 Legendary，不额外变调")

	feedback._tween.custom_step(2.0)
	_check(original.visible and feedback._pending.is_empty(), "队列下一项继续播放")
	feedback._tween.custom_step(2.0)
	_check( not original.visible and not timing.visible and feedback._tween == null
		and not feedback.is_playing(), "队列播完自动收起两套Spine")

	feedback.play([4], Vector2(300.0, 200.0), [], false, true)
	_check(timing.visible and not original.visible, "时机2.0分支只用最终骨架")
	feedback._tween.custom_step(2.0)
	feedback.play([4], Vector2(300.0, 200.0))
	_check(original.visible and not timing.visible, "切回原版只用常驻Spine")
	feedback.hide_now()

	UserState.set_sfx_enabled(false)
	var sound_count: int = sounds.size()
	feedback.play([9], Vector2(300.0, 200.0))
	_check(original.visible and sounds.size() == sound_count, "静音仍播放反馈，不产生实际音频替身播放")
	feedback.hide_now()
	UserState.set_sfx_enabled(true)
	feedback.free()


func _check_outer_glow() -> void :
	var scene: PackedScene = load("res://scripts/main/pages/game/combo_feedback.tscn") as PackedScene
	var feedback: ComboFeedback = scene.instantiate() as ComboFeedback
	add_child(feedback)
	var original: SpineSprite = feedback.get_node("Spine") as SpineSprite
	var reference_scene: PackedScene = load("res://assets/spine/combo/combo.tscn") as PackedScene
	var reference: SpineSprite = reference_scene.instantiate() as SpineSprite
	add_child(reference)
	reference.hide()
	var was_sfx_enabled: bool = UserState.is_sfx_enabled()
	UserState.set_sfx_enabled(false)
	var failures_before: int = _failures.size()
	var center: Vector2 = Vector2(300.0, 200.0)
	feedback._apply_reference_pose(reference.get_skeleton(), reference.get_animation_state(), "Amazing!")
	feedback._filter_reference_slots(reference.get_skeleton(), true)
	var expected_scale: float = ComboFeedback.REFERENCE_CONTENT_HEIGHT / reference.get_skeleton().get_bounds().size.y
	var flower_glow_counts: Array[int] = [0, 2, 2, 3, 3, 4, 5]
	for skin_index: int in ComboFeedback.SKINS.size():
		var skin: String = ComboFeedback.SKINS[skin_index]
		feedback.play([skin_index + 2], center)
		_check(is_equal_approx(original.scale.y, expected_scale), "隐藏外发光不改变原七档共用倍率：" + skin)
		feedback._apply_reference_pose(reference.get_skeleton(), reference.get_animation_state(), skin)
		feedback._filter_reference_slots(reference.get_skeleton(), false)
		_check((original.position + reference.get_skeleton().get_bounds().get_center() * expected_scale)
			.is_equal_approx(center), "隐藏外发光不改变文字参考中心：" + skin)
		var reference_skeleton: SpineSkeleton = reference.get_skeleton()
		var reference_state: SpineAnimationState = reference.get_animation_state()
		reference_skeleton.set_to_setup_pose()
		reference_state.clear_tracks()
		reference_state.set_animation(ComboFeedback.ANIMATION, false, 0)
		var previous_time: float = 0.0
		for frame_time: float in [0.0, 0.1, 0.5, 0.9]:
			var delta: float = frame_time - previous_time
			reference.update_skeleton(delta)
			if frame_time > 0.0:
				original.update_skeleton(delta)
			_check_outer_glow_slots(original, reference, "%s %.1fs" % [skin, frame_time])
			if is_equal_approx(frame_time, 0.5):
				var active_text_glows: int = 0
				var active_flower_glows: int = 0
				for slot: SpineSlot in reference_skeleton.get_slots():
					if slot.get_attachment() == null or slot.get_color().a <= 0.0:
						continue
					var slot_name: String = slot.get_data().get_name()
					if not slot_name.begins_with(skin.to_lower().trim_suffix("!") + "_"):
						continue
					if slot_name.ends_with("_base_glow"):
						active_text_glows += 1
					elif "_flower_" in slot_name and slot_name.ends_with("_glow"):
						active_flower_glows += 1
				_check(active_text_glows == 1 and active_flower_glows == flower_glow_counts[skin_index], 
					"参考素材包含预期的文字及花朵外发光：" + skin)
			previous_time = frame_time
		feedback.hide_now()
	feedback.play([2, 3, 4, 5, 6, 7, 8], center)
	for skin: String in ComboFeedback.SKINS:
		var glow_slot: SpineSlot = original.get_skeleton().find_slot(skin.to_lower().trim_suffix("!") + "_base_glow")
		_check(original.get_skeleton().get_skin().get_name() == skin and glow_slot.get_attachment() != null
			and is_zero_approx(glow_slot.get_color().a), "串行切词首帧保留附件且隐藏外发光：" + skin)
		var duration: float = original.get_skeleton().get_data().find_animation(ComboFeedback.ANIMATION).get_duration()
		feedback._tween.custom_step(duration + 0.01)
	_check( not feedback.is_playing(), "七档外发光预览队列正常结束")
	feedback.play([5, 6], center)
	feedback.hide_now()
	feedback.play([5], center)
	original.update_skeleton(0.5)
	_check(is_zero_approx(original.get_skeleton().find_slot("amazing_base_glow").get_color().a), 
		"取消后重播不恢复外发光")
	feedback.hide_now()
	UserState.set_sfx_enabled(was_sfx_enabled)
	reference.free()
	feedback.free()
	if _failures.size() == failures_before:
		SortLogger.info("[ComboGlowTest] 七档首帧/动画更新/切词/重播隐藏外发光，附件与其它槽位保留 PASS")


func _check_outer_glow_slots(sprite: SpineSprite, reference: SpineSprite, label: String, 
		hide_glow: bool = true) -> void :
	for reference_slot: SpineSlot in reference.get_skeleton().get_slots():
		var slot_name: String = reference_slot.get_data().get_name()
		var slot: SpineSlot = sprite.get_skeleton().find_slot(slot_name)
		var has_attachment: bool = reference_slot.get_attachment() != null
		_check((slot.get_attachment() != null) == has_attachment, "保留槽位附件：%s %s" % [label, slot_name])
		var expected_color: Color = reference_slot.get_color()
		if hide_glow and (slot_name.ends_with("_base_glow")
				or ("_flower_" in slot_name and slot_name.ends_with("_glow"))):
			expected_color.a = 0.0
		_check(slot.get_color().is_equal_approx(expected_color), "只隐藏目标外发光：%s %s" % [label, slot_name])



func _check_haptic_profiles() -> void :
	_check(HapticProfiles.is_three_level_combo_platform("Android")
		and not HapticProfiles.is_three_level_combo_platform("iOS")
		and not HapticProfiles.is_three_level_combo_platform("macOS"), 
		"Combo 精简三档仅 Android 生效，iOS 及其他平台使用七档")
	var timings: Array = [[100, 80, 100], [120, 80, 120], [135, 90, 135], [150, 100, 150], 
		[175, 100, 175], [200, 100, 200], [225, 100, 225]]
	var amplitudes: Array = [[20, 0, 10], [40, 0, 20], [95, 0, 85], [150, 0, 150], 
		[175, 0, 150], [200, 0, 150], [225, 0, 175]]
	_check(HapticProfiles.combo_event_for_count(1) == -1, "首盆不产生 Combo 事件")
	for i: int in timings.size():
		var event: int = HapticProfiles.combo_event_for_count(i + 2)
		var profile: Dictionary = HapticProfiles.PROFILES[event]
		var android: Dictionary = profile["android"]
		_check(android["type"] == "waveform" and android["timings_msec"] == timings[i]
			and android["amplitudes"] == amplitudes[i], "七档 Android 参数与 PRD 一致：%d" % i)
		var ios: Dictionary = profile["ios"]
		var ahap: Dictionary = JSON.parse_string(ios["json"])
		var pattern: Array = ahap["Pattern"]
		_check(ios["type"] == "ahap_json" and int(ahap["Version"]) == 1 and pattern.size() == 2, 
			"iOS 内联 AHAP 恰好两个震动段")
		for segment: int in range(2):
			var index: int = segment * 2
			var entry: Dictionary = pattern[segment]["Event"]
			var start: float = 0.0 if segment == 0 else (timings[i][0] + timings[i][1]) / 1000.0
			_check(entry["EventType"] == "HapticContinuous" and is_equal_approx(float(entry["Time"]), start)
				and is_equal_approx(float(entry["EventDuration"]), timings[i][index] / 1000.0), 
				"iOS 震动段时间与静默间隔准确")
			var parameters: Array = entry["EventParameters"]
			_check(parameters[0]["ParameterID"] == "HapticIntensity"
				and is_equal_approx(float(parameters[0]["ParameterValue"]), amplitudes[i][index] / 255.0)
				and parameters[1]["ParameterID"] == "HapticSharpness"
				and is_equal_approx(float(parameters[1]["ParameterValue"]), 0.5), "iOS 强度归一化及锐度一致")
		_check(HapticProfiles.priority_of(event) == 40, "所有 Combo 事件优先级为40")
	for count: int in range(2, 16):
		var mapped_count: int = 3 if count <= 4 else (5 if count <= 7 else 7)
		_check(HapticProfiles.combo_event_for_count(count, true) == HapticProfiles.combo_event_for_count(mapped_count), 
			"精简组三档复用准确：%d" % count)
	_check(HapticProfiles.combo_event_for_count(100) == HapticProfiles.combo_event_for_count(8), 
		"七档 Legendary 封顶，不随次数数字增强")

	var tuned_amplitudes: Array = [
		[[80, 120, 60], [120, 160, 100], [160, 200, 120], [200, 240, 140], [200, 240, 140], [200, 240, 140], [200, 240, 140]], 
		[[80, 120, 60], [100, 140, 60], [120, 160, 80], [140, 160, 100], [160, 200, 120], [160, 200, 120], [160, 200, 120]], 
	]
	for style: int in [1, 2]:
		for i: int in 7:
			var event: int = HapticProfiles.shake_event_for(HapticProfiles.combo_event_for_count(i + 2), style)
			var profile: Dictionary = HapticProfiles.PROFILES[event]
			var amplitudes_for_event: Array = tuned_amplitudes[style - 1][i]
			_check(profile.priority == 40 and profile.android.timings_msec == [140, 100, 140, 100, 160], "新样式三脉冲时长与优先级")
			_check(profile.android.amplitudes == [amplitudes_for_event[0], 0, amplitudes_for_event[1], 0, amplitudes_for_event[2]], "新样式三脉冲振幅")
			var ahap: Dictionary = JSON.parse_string(profile.ios.json)
			_check(profile.ios.type == "ahap_json" and not profile.ios.has("fallback") and ahap.Pattern.size() == 3, "新样式面板迁移不补降级")
			for segment: int in 3:
				var entry: Dictionary = ahap.Pattern[segment].Event
				_check(entry.EventType == "HapticContinuous" and is_equal_approx(entry.Time, segment * 0.24)
					and is_equal_approx(entry.EventDuration, 0.16 if segment == 2 else 0.14), "新样式累计时间与持续时长")
				_check(is_equal_approx(entry.EventParameters[0].ParameterValue, amplitudes_for_event[segment] / 255.0)
					and entry.EventParameters[1].ParameterValue == 0.5, "新样式强度与锐度")



func _check_haptic_page() -> void :
	ABManager.set("_is_init_done", true)
	ABManager.set("fullscreen_sdk_value", "no")
	ABManager.set("fullscreen_reads", 0)
	ABManager.set("fullscreen_dyes", 0)
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"ComboFeedback": ProbeFeedback, "Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	page._combo_tracker.reset(2, 1, 0, 0)
	board.done = 1
	page.apply_move_feedback(1)
	_check(int(ABManager.get("fullscreen_dyes")) == 0 and int(ABManager.get("fullscreen_reads")) == 0, 
		"首盆不读取或染色 Combo 共用时机")
	HapticManager.set_enabled(false)
	board.done = 4
	page.apply_move_feedback(2)
	var feedback: ProbeFeedback = page._combo_feedback as ProbeFeedback
	_check(int(ABManager.get("fullscreen_dyes")) == 1 and feedback.submitted.size() == 3, 
		"关闭震动也在首次 Nice 级联统一染色")
	for submitted: Dictionary in feedback.submitted:
		var expected: int = HapticProfiles.combo_event_for_count(int(submitted["count"]), 
			HapticProfiles.is_three_level_combo_platform(OS.get_name()))
		_check(submitted["haptic_event"] == expected and submitted["fullscreen_dyes"] == 1, 
			"提交前已染色且事件快照与当前平台方案一致")

	page._combo_tracker.reset(2, 1, 0, 0)
	page._combo_steps = 0
	board.done = 2
	page.apply_move_feedback(1)
	_check(int(ABManager.get("fullscreen_dyes")) == 1, "起局复用不重复染色共用时机")
	HapticManager.set_enabled(true)
	page.free()



func _check_haptic_trigger_log() -> void :
	var failures_before: int = _failures.size()
	ABManager.set("_is_init_done", true)
	ABManager.set("fullscreen_sdk_value", "no")
	ABManager.set("fullscreen_dyes", 0)
	HapticManager.set_enabled(true)
	HapticManager._flush_pending_event()
	var played: Array = HapticManager._native.get("played") as Array
	played.clear()
	var sounds: Array = AudioManager.get("played") as Array
	sounds.clear()
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	page._combo_tracker.reset(2, 1, 0, 0)
	var feedback: ComboFeedback = page._combo_feedback as ComboFeedback
	board.done = 1
	page.apply_move_feedback(1)
	HapticManager._flush_pending_event()

	_check(played.size() == 1 and played.back() == HapticProfiles.PROFILES[HapticManager.Event.MOVE_OK]
		and sounds.is_empty() and int(ABManager.get("fullscreen_dyes")) == 0, 
		"完整触发链首盆只保留普通移动触感，不追加 Combo 或染色")
	played.clear()
	board.done = 10
	page.apply_move_feedback(2)
	_check(int(ABManager.get("fullscreen_dyes")) == 1 and feedback._pending.size() == 8, 
		"完整触发链首次级联只染一次，且剩余八个词排队不提前起播")

	for count: int in range(2, 11):
		HapticManager._flush_pending_event()
		var expected_plays: int = count - 1
		var combo_dispatches: int = 0
		for profile: Dictionary in played:
			if int(profile["priority"]) == 40:
				combo_dispatches += 1
		_check(combo_dispatches == expected_plays and sounds.size() == count - 1, 
			"完整触发链每个词起播恰好一次，入队不批量震动：%d" % count)
		_check(played.size() == expected_plays, 
			"Combo 同帧由自有波形胜出普通移动触感")

		var expected_sfx: StringName = ComboFeedback.SFX_IDS[mini(count - 2, 6)]
		_check(sounds.back()["id"] == expected_sfx and is_equal_approx(float(sounds.back()["pitch"]), 1.0), 
			"实际起播词与原始连续盆数一致，原语音不额外变调")
		var timings: Array = []
		var amplitudes: Array = []
		var event: int = HapticProfiles.combo_event_for_count(count)
		var actual: Dictionary = played.back()
		_check(actual == HapticProfiles.PROFILES[event], "页面、队列与仲裁最终派发当前平台波形")
		timings.assign(actual["android"]["timings_msec"])
		amplitudes.assign(actual["android"]["amplitudes"])
		var ahap: Dictionary = JSON.parse_string(actual["ios"]["json"])
		_check((ahap["Pattern"] as Array).size() == 2, "最终派发包含 iOS 双脉冲 AHAP")
		SortLogger.info("[ComboHapticTest] %s" % JSON.stringify({"count": count, 
			"word": ComboFeedback.skin_for_count(count), 
			"combo_dispatches": combo_dispatches, "timings_ms": timings, "amplitudes": amplitudes, 
			"dyes": ABManager.get("fullscreen_dyes")}))
		feedback._tween.custom_step(2.0)
	HapticManager._flush_pending_event()
	_check(feedback._pending.is_empty() and feedback._tween == null
		and int(ABManager.get("fullscreen_dyes")) == 1, "完整触发链播完无额外派发且不重复染色")
	page.free()
	if _failures.size() == failures_before:
		SortLogger.info("[ComboHapticTest] 正式页面→逐词队列→触感派发 PASS")



func _check_haptic_queue() -> void :
	HapticManager.set_enabled(true)
	HapticManager._flush_pending_event()
	var played: Array = HapticManager._native.get("played") as Array
	played.clear()
	var scene: PackedScene = load("res://scripts/main/pages/game/combo_feedback.tscn") as PackedScene
	var feedback: ComboFeedback = scene.instantiate() as ComboFeedback
	add_child(feedback)
	var nice: int = HapticProfiles.combo_event_for_count(2)
	var great: int = HapticProfiles.combo_event_for_count(3)
	var excellent: int = HapticProfiles.combo_event_for_count(4)
	feedback.play([2, 3, 4], Vector2(300.0, 200.0), [nice, great, excellent])
	HapticManager._flush_pending_event()
	_check(played.size() == 1 and played.back() == HapticProfiles.PROFILES[nice], "级联只在首词实际起播时震动")
	feedback.play([5], Vector2(300.0, 200.0))
	_check(feedback._pending[0]["haptic_event"] == great and feedback._pending.back()["haptic_event"] == -1, 
		"后续切回对照不改写旧批波形")
	feedback._tween.custom_step(2.0)
	HapticManager._flush_pending_event()
	_check(played.size() == 2 and played.back() == HapticProfiles.PROFILES[great], "切到第二词才播放其波形")
	feedback.hide_now()
	HapticManager._flush_pending_event()
	_check(played.size() == 2 and feedback._pending.is_empty(), "取消未起播项不再震动")
	feedback.play([2], Vector2(300.0, 200.0))
	HapticManager._flush_pending_event()
	_check(played.size() == 2, "默认预览及对照组不追加 Combo 震动")
	feedback.hide_now()
	HapticManager.set_enabled(false)
	feedback.play([2, 3], Vector2(300.0, 200.0), [nice, great])
	HapticManager._flush_pending_event()
	_check(played.size() == 2, "关闭全局开关后真正起播也不震动")
	HapticManager.set_enabled(true)
	feedback._tween.custom_step(2.0)
	HapticManager._flush_pending_event()
	_check(played.size() == 3 and played.back() == HapticProfiles.PROFILES[great], "开关恢复后下一词可正常震动")
	feedback.hide_now()

	HapticManager.play_event(HapticManager.Event.CUP_DONE)
	HapticManager.play_event(nice)
	HapticManager._flush_pending_event()
	_check(played.back() == HapticProfiles.PROFILES[nice], "同帧 Combo 胜过普通收盆")
	HapticManager.play_event(HapticManager.Event.LEVEL_WIN)
	HapticManager.play_event(great)
	HapticManager._flush_pending_event()
	_check(played.back() == HapticProfiles.PROFILES[HapticManager.Event.LEVEL_WIN], "通关先请求也胜过 Combo")
	HapticManager.play_event(great)
	HapticManager.play_event(HapticManager.Event.LEVEL_WIN)
	HapticManager._flush_pending_event()
	_check(played.back() == HapticProfiles.PROFILES[HapticManager.Event.LEVEL_WIN], "通关后请求仍胜过 Combo")
	feedback.free()


func _check_frequency_config() -> void :
	var config: ComboFreqConfig = ABManager.combo_freq
	config.clear_debug_override()
	_check(ABManager.find_config("combo_freq") == config and config.group_count == 2
		and config.version == "1.0.10" and config.default_value == 0
		and config.timing == ABManager.TIMING_COMBO_FREQ, "频率参数注册与元信息正确")
	ABManager.set("_combo_freq_dyed", false)
	ABManager.set("frequency_dyes", 0)
	ABManager.set("_is_init_done", false)
	config._value_loaded = false
	ABManager.dye_at_combo_freq()
	_check( not config.is_new_frequency_enabled() and not config._value_loaded
		and not ABManager.get("_combo_freq_dyed") and int(ABManager.get("frequency_dyes")) == 0, 
		"频率SDK未就绪不启用、不缓存、不消耗首次染色")
	ABManager.set("_is_init_done", true)
	for raw: Variant in ["old", "new", "", "unknown", "NEW", 1, true, null]:
		ABManager.set("frequency_sdk_value", raw)
		config._value_loaded = false
		var expected: int = 1 if raw is String and raw == "new" else 0
		_check(config.peek_value() == expected and config.peek_sdk_value() == expected
			and config.value() == expected, "频率实时及懒加载统一字符串读取：%s" % str(raw))
		config.load_value_silent()
		_check(config._value == expected, "频率静默读取走字符串钩子")
		config.reload_value()
		_check(config._value == expected, "频率染色读取走字符串钩子")
	_check(int(ABManager.get("frequency_int_reads")) == 0, "频率不读取SDK整数通道")
	ABManager.set("frequency_sdk_value", "new")
	ABManager.set("frequency_dyes", 0)
	ABManager.set("_startup_control_locked", true)
	ABManager.dye_at_combo_freq()
	_check(int(ABManager.get("frequency_dyes")) == 0 and not ABManager.get("_combo_freq_dyed"), "启动超时不染色")
	ABManager.set("_startup_control_locked", false)
	ABManager.dye_at_combo_freq()
	ABManager.dye_at_combo_freq()
	_check(int(ABManager.get("frequency_dyes")) == 1, "SDK就绪后补染且本进程只染一次")
	for group: int in [0, 1]:
		config.set_debug_override(group)
		_check(config.is_new_frequency_enabled() == (group == 1), "频率Cheat0/1独立覆盖")
	config.clear_debug_override()



func _check_frequency_page(raw: String, fullscreen_raw: String) -> void :
	ABManager.set("frequency_sdk_value", raw)
	ABManager.set("_combo_freq_dyed", false)
	ABManager.set("frequency_dyes", 0)
	ABManager.combo_freq._value_loaded = false
	ABManager.set("fullscreen_sdk_value", fullscreen_raw)
	ABManager.set("fullscreen_dyes", 0)
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"ComboFeedback": ProbeFeedback, "Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	var feedback: ProbeFeedback = page._combo_feedback as ProbeFeedback
	page._combo_tracker.reset(6, 1, 0, 0)
	page._combo_frequency_tracker.reset(6, 25)
	page._iq_round.reset(true, 25)
	var reference_iq: IqRoundModel = IqRoundModel.new()
	reference_iq.reset(true, 25)
	var reference_tracker: JuiceComboTracker = JuiceComboTracker.new()
	reference_tracker.reset(6, 1, 0, 0)
	for done: int in range(1, 26):
		board.done = done
		page.apply_move_feedback(done)
		reference_iq.on_move(done, reference_tracker.on_move(done, done, page._play_timer.elapsed_ms()))
		if done == 1:
			_check(int(ABManager.get("frequency_dyes")) == 1, "对照/实验首盆均由条件并集入池")
			_check(feedback.submitted.size() == (1 if raw == "new" else 0), "首盆只在新频率展示Nice")
	_check(is_equal_approx(page._iq_round.value(), reference_iq.value()), "两组IQ均保留旧连续算法")
	var expected_counts: Array[int] = []
	if raw == "new":
		expected_counts = [2, 3, 4, 5, 6, 7, 8, 8, 8]
	else:
		for count: int in range(2, 26):
			expected_counts.append(count)
	var actual_counts: Array[int] = []
	for submitted: Dictionary in feedback.submitted:
		actual_counts.append(int(submitted["count"]))
		_check(submitted["frequency_dyes"] == 1 and submitted["petal_feedback_enabled"] == (raw == "new"), 
			"频率染色在提交前完成，花瓣资格按本批快照注入")
		_check(submitted["fullscreen_fx_enabled"] == (fullscreen_raw == "yes")
			and submitted["fullscreen_dyes"] == 1, "其他实验独立取值及染色")
		var expected_haptic: int = HapticProfiles.combo_event_for_count(int(submitted["count"]), 
			HapticProfiles.is_three_level_combo_platform(OS.get_name()))
		_check(submitted["haptic_event"] == expected_haptic, "触感随实际词档位并按当前平台方案映射")
	_check(actual_counts == expected_counts, "两组反馈序列和Legendary封顶正确")
	page._combo_frequency_tracker.reset(6, 25)
	page._combo_tracker.reset(6, 1, 0, 0)
	page._combo_steps = 0
	board.done = 1
	page.apply_move_feedback(1)
	_check(int(ABManager.get("frequency_dyes")) == 1, "起局重计反馈但不重染频率")
	page.free()
	SortLogger.info("[ComboFreqTest] frequency=%s fullscreen=%s PASS" % [raw, fullscreen_raw])


func _check_frequency_end_wait() -> void :
	for cancel: String in ["finish", "hide", "new_round"]:
		var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
		var page: Variant = scene.instantiate()
		page.set_script(ProbeEndPage)
		add_child(page)
		await PAGE_FIXTURE.prepare(page)
		page._win_committed = true
		page._combo_frequency_wait_before_end = true
		var feedback: ComboFeedback = page._combo_feedback as ComboFeedback
		feedback.play([4, 8], Vector2(300.0, 200.0), [], false, true)
		var finished: Dictionary = {"done": false}
		_run_end_probe(page, finished)
		await get_tree().process_frame
		_check( not finished["done"] and page.end_preparations == 0, "末盆队列尚未结束时不进入过关清场")
		if cancel == "finish":
			page._combo_feedback.hide_now()
		elif cancel == "hide":
			page.visible = false
		else:
			page._end_flow_generation += 1
		for frame: int in 3:
			await get_tree().process_frame
		_check(finished["done"] and page.end_preparations == (1 if cancel == "finish" else 0), 
			"队列结束放行，离页/新局取消旧等待：%s" % cancel)
		page.free()


func _run_end_probe(page: JuiceGamePage, finished: Dictionary) -> void :
	await page._run_game_end_flow()
	finished["done"] = true


func _check_frequency_petals() -> void :
	var scene: PackedScene = load("res://scripts/main/pages/game/combo_feedback.tscn") as PackedScene
	var node: Node = scene.instantiate()
	node.set_script(ProbeFullscreenFeedback)
	var feedback: ProbeFullscreenFeedback = node as ProbeFullscreenFeedback
	add_child(feedback)
	var dyes_before: int = int(ABManager.get("frequency_dyes"))
	feedback.play([2, 3, 4, 5, 6, 7, 8, 8], Vector2(300.0, 200.0), [], true, true)
	_check(feedback.petals == 0, "Nice真正起播不撒花瓣，后续未播也不触发")
	for index: int in range(1, 8):
		feedback._tween.kill()
		feedback._tween = null
		feedback._play_next()
		_check(feedback.petals == maxi(0, index - 1), "Excellent及以上实际起播才调用花瓣接口")
	_check(feedback.stages == [1, 1, 1, 2, 2, 2, 3, 3], "新频率复用独立全屏三阶段")
	feedback.hide_now()
	var petals_before: int = feedback.petals
	feedback.play([2, 4], Vector2(300.0, 200.0), [], false, true)
	feedback.hide_now()
	_check(feedback.petals == petals_before, "取消待播Excellent不触发花瓣")
	feedback.play([4, 5], Vector2(300.0, 200.0), [], false, true)
	feedback.play([6], Vector2(300.0, 200.0))
	_check(feedback._pending[0]["petal_feedback_enabled"]
		and not feedback._pending.back()["petal_feedback_enabled"], "切组不追改排队花瓣快照")
	feedback.hide_now()
	petals_before = feedback.petals
	feedback.play([4], Vector2(300.0, 200.0))
	_check(feedback.petals == petals_before and int(ABManager.get("frequency_dyes")) == dyes_before, 
		"原版预览默认不撒花瓣、不染色")
	feedback.free()



func _check(condition: bool, description: String) -> void :
	if not condition:
		_failures.append(description)



func _check_sfx_config() -> void :
	var config: ComboSfxStyleConfig = ABManager.combo_sfx_style
	_check(ABManager.find_config("combo_sfx_style") == config and config.group_count == 2
		and config.version == "1.0.10" and config.default_value == 0
		and config.timing == ABManager.TIMING_COMBO_SFX_STYLE, "音效配置注册和元信息正确")
	for raw: Variant in ["default", "set1", "", "unknown", 1]:
		var is_set1: bool = raw is String and raw == "set1"
		ABManager.set("sfx_sdk_value", raw)
		config._value_loaded = false
		_check(config.is_new_combo_sfx_enabled() == is_set1, "音效SDK字符串正确映射")
		_check(config.peek_value() == (1 if is_set1 else 0), "面板映射一致")
		config.load_value_silent()
		_check(config.is_new_combo_sfx_enabled() == is_set1, "静默载入映射一致")
	ABManager.set("sfx_sdk_value", "set1")
	ABManager.set("sfx_status", "invalid")
	config._value_loaded = false
	_check( not config.is_new_combo_sfx_enabled(), "未命中set1不启用")
	ABManager.set("sfx_status", "valid")
	ABManager.set("_is_init_done", false)
	config._value_loaded = false
	ABManager.set("_combo_sfx_style_dyed", false)
	ABManager.set("sfx_dyes", 0)
	ABManager.dye_at_combo_sfx_style()
	_check( not config.is_new_combo_sfx_enabled() and not config._value_loaded
		and not ABManager.get("_combo_sfx_style_dyed"), "未就绪不缓存或消耗染色资格")
	ABManager.set("_is_init_done", true)
	ABManager.set("_startup_control_locked", true)
	ABManager.dye_at_combo_sfx_style()
	_check( not config.is_new_combo_sfx_enabled() and int(ABManager.get("sfx_dyes")) == 0, 
		"启动锁定不启用或染色")
	config.set_debug_override(1)
	_check(config.is_new_combo_sfx_enabled(), "合法Cheat优先于启动锁定")
	config.set_debug_override(2)
	_check( not config.is_new_combo_sfx_enabled(), "未知Cheat保持现状")
	config.clear_debug_override()
	ABManager.set("_startup_control_locked", false)
	ABManager.dye_at_combo_sfx_style()
	ABManager.dye_at_combo_sfx_style()
	_check(int(ABManager.get("sfx_dyes")) == 1 and int(ABManager.get("sfx_int_reads")) == 0, 
		"就绪后只染一次且始终使用字符串通道")



func _check_sfx_page() -> void :
	var scene: PackedScene = load("res://scripts/main/pages/game/juice_game_page.tscn") as PackedScene
	var page: Variant = scene.instantiate()
	page.set_script(ProbePage)
	add_child(page)
	await PAGE_FIXTURE.prepare(page, {"ComboFeedback": ProbeFeedback, "Board": ProbeBoard})
	var board: ProbeBoard = page._board as ProbeBoard
	var config: ComboSfxStyleConfig = ABManager.combo_sfx_style
	AudioManager.set_sfx_enabled(true)
	config.set_debug_override(1)
	ABManager.set("_combo_sfx_style_dyed", false)
	ABManager.set("sfx_dyes", 0)
	var sounds: Array = AudioManager.get("played")
	var before: int = sounds.size()
	page._play_major_sound(&"juice_burst", true)
	_check(sounds.back()["id"] == &"juice_burst" and int(ABManager.get("sfx_dyes")) == 0, 
		"预览保持原音频且不染色")
	board.tutorial_demo_only = true
	page._play_major_sound(&"juice_burst")
	_check(sounds.back()["id"] == &"juice_burst" and int(ABManager.get("sfx_dyes")) == 0, 
		"教学演示不参与音效实验")
	board.tutorial_demo_only = false
	page._play_major_sound(&"juice_burst")
	_check(sounds.back()["id"] == &"juice_burst_set1" and sounds.back()["volume"] == 1.2
		and int(ABManager.get("sfx_dyes")) == 1, "消除起点只替换音频并保留1.2倍音量")
	for frequency: String in ["old", "new"]:
		ABManager.set("frequency_sdk_value", frequency)
		ABManager.combo_freq._value_loaded = false
		page._combo_sfx_counts.clear()
		page._combo_steps = 0
		page._combo_tracker.reset(6, 1, 0, 0)
		page._combo_frequency_tracker.reset(6, 25)
		board.done = 9
		var count_before: int = sounds.size()
		page.apply_move_feedback(1)
		_check(sounds.size() == count_before, "逻辑完成只记档位，不提前播放上飞音效")
		for slot: int in 9:
			page._play_major_sound(&"juice_quota", false, slot)
			_check(sounds.back()["id"] == StringName("combo_set1_level%d" % mini(slot + 1, 8))
				and sounds.back()["volume"] == 1.0 and sounds.back()["pitch"] == 1.0, 
				"级联多盆按盆选档，音量音调及封顶不变")
		_check(page._combo_sfx_counts.is_empty(), "起播后移除已消费档位")
	page._combo_steps = 100
	page._combo_tracker._last_cup_time_ms = -20000
	board.done = 10
	page.apply_move_feedback(101)
	page._play_major_sound(&"juice_quota", false, 9)
	_check(sounds.back()["id"] == &"combo_set1_level1", "断连后level1")
	config.set_debug_override(0)
	page._play_major_sound(&"juice_burst")
	_check(sounds.back()["id"] == &"juice_burst" and sounds.back()["volume"] == 1.2, "对照消除保持原样")
	page._play_major_sound(&"juice_quota", false, 0)
	_check(sounds.back()["id"] == &"juice_quota" and sounds.back()["volume"] == 1.0, "对照上飞保持原样")
	_check_sfx_flight_timing(page, sounds, config)
	page._combo_sfx_counts[5] = 8
	page._cancel_cup_flights()
	_check(page._combo_sfx_counts.is_empty(), "取消和重建清空待播档位")
	AudioManager.set_sfx_enabled(false)
	ABManager.set("_combo_sfx_style_dyed", false)
	ABManager.set("sfx_dyes", 0)
	var muted_before: int = sounds.size()
	page._play_major_sound(&"juice_burst")
	_check(sounds.size() == muted_before and int(ABManager.get("sfx_dyes")) == 1, 
		"静音不发声但保留两组染色资格")
	AudioManager.set_sfx_enabled(true)
	config.clear_debug_override()
	_check(sounds.size() > before, "音效事件用例已执行")
	page.free()



func _check_sfx_flight_timing(page: JuiceGamePage, sounds: Array, config: ComboSfxStyleConfig) -> void :
	for count: int in range(1, 9):
		config.set_debug_override(1)
		page._combo_sfx_counts[0] = count
		var motion: Dictionary = {"progress": 0.0}
		var tween: Tween = page.create_tween()
		page._append_cup_flight_sound(tween, false, 0)
		tween.parallel().tween_method( func(u: float) -> void : motion["progress"] = u, 
			0.0, 1.0, page.CUP_FLY_DUR)
		tween.pause()
		var before: int = sounds.size()
		tween.custom_step(0.32)
		_check(sounds.size() == before, "实验音效不在飞行初段提前起播：%d" % count)

		config.set_debug_override(0)
		var played_at: float = -1.0
		for frame: int in 14:
			tween.custom_step(0.01)
			if sounds.size() > before and played_at < 0.0:
				played_at = 0.33 + frame * 0.01
		var attack: float = 0.1 if count == 2 else 0.09
		_check(played_at >= 0.0 and absf(played_at + attack - page.CUP_FLY_DUR) <= 0.011, 
			"八档重音对齐0.45秒落点：%d" % count)
		_check(sounds.size() == before + 1 and sounds.back()["id"] == StringName("combo_set1_level%d" % count)
			and sounds.back()["pitch"] == 1.0 and sounds.back()["volume"] == 1.0, 
			"冻结本盆选音、默认音调音量且只播一次：%d" % count)
		_check(is_equal_approx(float(motion["progress"]), 1.0) and not tween.is_running(), 
			"音效时钟不延长并行飞行：%d" % count)
		tween.kill()
	for preview: bool in [false, true]:
		config.set_debug_override(0 if not preview else 1)
		var tween: Tween = page.create_tween()
		page._append_cup_flight_sound(tween, preview, 0)
		tween.pause()
		var before: int = sounds.size()
		tween.custom_step(0.01)
		_check(sounds.size() == before + 1 and sounds.back()["id"] == &"juice_quota", 
			"对照和预览保持飞行起点播放")
		tween.kill()
	var saved_skin: JuiceSkinResolver = page._skin_resources
	var override_skin: JuiceSkinDefinition = JuiceSkinDefinition.new()
	override_skin.sounds[&"juice_quota"] = &"juice_pick"
	page._skin_resources = JuiceSkinResolver.new(JuiceSkinDefinition.new(), override_skin)
	config.set_debug_override(1)
	var overridden: Tween = page.create_tween()
	page._append_cup_flight_sound(overridden, false, 0)
	overridden.pause()
	var before_override: int = sounds.size()
	overridden.custom_step(0.01)
	_check(sounds.size() == before_override + 1 and sounds.back()["id"] == &"juice_pick", 
		"皮肤显式覆盖保持原音效及飞行起点")
	overridden.custom_step(0.45)
	_check(sounds.size() == before_override + 1, "皮肤覆盖不再补播实验音效")
	overridden.kill()
	page._skin_resources = saved_skin
	config.set_debug_override(1)
	var cancelled: Tween = page.create_tween()
	page._append_cup_flight_sound(cancelled, false, 0)
	cancelled.pause()
	var before_cancel: int = sounds.size()
	cancelled.custom_step(0.2)
	cancelled.kill()
	cancelled.custom_step(0.5)
	_check(sounds.size() == before_cancel, "取消飞行不补播待起音效")
	config.set_debug_override(0)
