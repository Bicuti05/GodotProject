extends Node


var _failures: int = 0


func _ready() -> void :
	call_deferred("_run")


func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures += 1
		push_error("IQ_SELFTEST: " + message)


func _near(actual: float, expected: float, message: String) -> void :
	_check(absf(actual - expected) < 1e-05, message)


func _run() -> void :
	_test_ab_config()
	_test_scores()
	_test_boosted_scores()
	_test_guarantee()
	_test_boosted_guarantee()
	_test_journal()
	await _test_page()
	await _test_boosted_page()
	_test_boosted_progress()
	_test_genius_locales()
	_test_genius_animation()
	_test_progress_animation()
	await _test_flow()
	if _failures == 0:
		print("IQ_SELFTEST PASS")
	get_tree().quit(0 if _failures == 0 else 1)


func _test_scores() -> void :
	for level_id: int in range(1, 5):
		_check(IqRoundModel.is_round_eligible(level_id, false, false) == (level_id >= 4), "first three levels")
	_check( not IqRoundModel.is_round_eligible(100, true, false), "special excluded")
	_check( not IqRoundModel.is_round_eligible(100, false, true), "bonus excluded")
	var model: = IqRoundModel.new()
	for target: int in [1, 3, 7, 11, 17]:
		model.reset(true, target)
		_near(model.value(), 40.0, "new round starts at 40")
		for done: int in range(1, target + 1):
			model.on_move(done, [] as Array[int])
		_near(model.value(), 100.0, "base total remains 60 for target %d" % target)
	for streak: int in range(1, 11):
		var expected: int = 0 if streak == 1 else (3 if streak <= 3 else 4)
		_check(IqRoundModel.combo_bonus(streak) == expected, "combo tier %d" % streak)
	var combo: = JuiceComboTracker.new()
	combo.reset(4, 1, 0, 0)
	model.reset(true, 8)
	for done: int in range(1, 9):
		model.on_move(done, combo.on_move(done, done, done * 1000))
	_near(model.value(), 126.0, "existing combo tracker awards each collected cup")
	combo.reset(4, 1, 0, 0)
	model.reset(true, 4)
	model.on_move(1, combo.on_move(1, 1, 1000))
	model.on_move(1, combo.on_move(11, 1, 16000))
	model.on_move(2, combo.on_move(12, 2, 16001))
	_near(model.value(), 70.0, "exceeding both combo windows restarts without extra IQ")
	model.on_move(3, combo.on_move(13, 3, 17000))
	_near(model.value(), 88.0, "second cup after interruption earns combo two again")
	for boundary: Array in [[11, 16001], [12, 16000]]:
		combo.reset(4, 1, 0, 0)
		model.reset(true, 3)
		model.on_move(1, combo.on_move(1, 1, 1000))
		model.on_move(2, combo.on_move(boundary[0], 2, boundary[1]))
		_near(model.value(), 40.0 + 120.0 / 3.0 + 3.0, "either inclusive combo window keeps extra IQ")
	combo.reset(4, 1, 0, 0)
	model.reset(true, 3)
	model.on_move(3, combo.on_move(1, 3, 1000))
	_near(model.value(), 106.0, "cascade scores all cups including combo 2 and 3")
	model.on_move(3, [2, 3] as Array[int])
	_near(model.value(), 106.0, "duplicate moved does not score")
	model.sync_done(1)
	model.on_move(2, [4] as Array[int])
	_near(model.value(), 110.0, "undo keeps score; repeated cup only adds combo")
	model.sync_done(0)
	model.on_move(3, [5, 6, 7] as Array[int])
	_near(model.value(), 122.0, "multi-step undo keeps base high-water mark")
	var restored: = IqRoundModel.new()
	restored.reset(true, 3, 3, model.snapshot())
	_near(restored.value(), model.value(), "resume restores base and combo")
	restored.reset(true, 7, 2)
	_near(restored.value(), 40.0 + 120.0 / 7.0, "old snapshot only reconstructs earned base")
	model.reset(false, 3)
	model.on_move(3, [2, 3] as Array[int])
	_near(model.value(), 40.0, "excluded round does not score")
	model.reset(true, 3)
	_near(model.value(), 40.0, "restart resets IQ")


func _test_guarantee() -> void :
	var rolls: Array[int] = [0]
	var random_iq: Callable = func() -> int:
		rolls[0] += 1
		return 160
	var model: = IqRoundModel.new()
	model.reset(true, 1, 1, {"combo_points": 39})
	_near(model.value(), 139.0, "139 before guarantee")
	var result: Dictionary = model.finalize(false, 60.0, false, 4, random_iq)
	_check(result.guarantee_triggered and result.final_iq == 160.0, "normal eligible guarantee includes A boundary")
	_check(model.finalize(true, -1.0, false, 0, random_iq) == result and rolls[0] == 1, "finalization freezes one random roll")
	for bonus: int in [40, 41, 100]:
		model.reset(true, 1, 1, {"combo_points": bonus})
		_check( not model.finalize(false, 99.0, true, 4, random_iq).guarantee_triggered, "140 or higher never draws guarantee")
	for pct: float in [-1.0, 59.999]:
		model.reset(true, 1, 1)
		_check( not model.finalize(false, pct, true, 4, random_iq).guarantee_triggered, "missing or below-A time")
	for kind: String in ["hint", "undo", "rope"]:
		model.reset(true, 1, 1)
		_check( not model.finalize(true, 99.0, true, 4, random_iq).guarantee_triggered, kind + " removes guarantee eligibility")
	model.reset(true, 1, 1)
	_check( not model.finalize(false, 60.0, false, 3, random_iq).guarantee_triggered, "normal needs four intervening completions")
	for difficulty: String in ["Hard", "SuperHard"]:
		model.reset(true, 1, 1)
		_check(model.finalize(false, 60.0, true, 0, random_iq).guarantee_triggered, difficulty + " bypasses interval")
	model.reset(true, 2, 1)
	_check( not model.finalize(false, 60.0, true, 4, random_iq).guarantee_triggered, "no guarantee before last cup")
	for i: int in 100:
		model.reset(true, 1, 1)
		var value: float = float(model.finalize(false, 60.0, true, 0).final_iq)
		_check(value >= 140.0 and value <= 160.0 and value == floorf(value), "random integer bounds")
	_check(ResultPercentileBank.lookup_percentile("time", 24, 91.6) >= 60.0, "existing time bank A exact boundary")
	_check(ResultPercentileBank.lookup_percentile("time", 24, 91.601) < 60.0, "existing time bank just above A duration")
	_check(ResultPercentileBank.lookup_percentile("time", 999, 0.0) == -1.0, "unknown shape has no guarantee standard")


func _test_journal() -> void :
	UserState.reset_all()
	_check(UserState.get_iq_rounds_since_guarantee() == 4, "first guarantee starts eligible")
	var guarantee: Dictionary = {"participated": true, "mainline": true, "guarantee_triggered": true, "final_iq": 151.0}
	_check(UserState.begin_level_completion(10, guarantee), "save pending IQ completion")
	UserState._load_data()
	_check(UserState.get_pending_iq_completion(10) == guarantee, "pending random value survives process reload")
	_check(UserState.begin_level_completion(10, {"final_iq": 159.0}), "repeated begin is idempotent")
	_check(UserState.get_pending_iq_completion(10) == guarantee, "retry cannot overwrite frozen IQ")
	UserState.fail_save = true
	_check( not UserState.finalize_level_completion(10), "save failure blocks finalize")
	_check(UserState.get_iq_rounds_since_guarantee() == 4 and UserState.get_pending_iq_completion(10) == guarantee, "failure restores interval and pending")
	UserState.fail_save = false
	_check(UserState.finalize_level_completion(10), "commit pending guarantee")
	_check(UserState.get_iq_rounds_since_guarantee() == 0, "any difficulty guarantee resets cooldown")
	_check( not UserState.finalize_level_completion(10), "duplicate finalize does not count twice")

	UserState.begin_level_completion(11, {"participated": false, "mainline": false})
	UserState.finalize_level_completion(11)
	_check(UserState.get_iq_rounds_since_guarantee() == 0, "excluded round does not count")
	for count: int in range(1, 5):
		UserState.begin_level_completion(11 + count, {"participated": count != 2, "mainline": true, "guarantee_triggered": false})
		UserState.finalize_level_completion(11 + count)
		_check(UserState.get_iq_rounds_since_guarantee() == count, "intervening mainline completion count")
	UserState._load_data()
	_check(UserState.get_iq_rounds_since_guarantee() == 4, "cooldown survives reload")
	UserState.fail_save = true
	_check( not UserState.begin_level_completion(30, guarantee) and UserState.get_pending_level_completion() == 0, "begin failure rolls back pending")
	UserState.fail_save = false
	UserState.reset_all()
	_check(UserState.get_iq_rounds_since_guarantee() == 4 and UserState.get_pending_iq_completion(30).is_empty(), "reset clears IQ journal")
	UserState.begin_level_completion(20, guarantee)
	LevelManager.mark_success = false
	_check( not UserState.recover_pending_level_completion(), "SQLite failure leaves pending recovery intact")
	_check(UserState.get_iq_rounds_since_guarantee() == 4, "failed recovery cannot consume guarantee interval")
	LevelManager.mark_success = true
	_check(UserState.recover_pending_level_completion(), "cold-start recovery finalizes frozen IQ")
	_check(UserState.get_iq_rounds_since_guarantee() == 0 and UserState.get_completed_level_count() == 1, "recovery counts once")
	_check(UserState.recover_pending_level_completion() and UserState.get_completed_level_count() == 1, "repeated recovery is idempotent")
	UserState.reset_all()


func _test_page() -> void :
	var page = load("res://iq_page_seams.tscn").instantiate()
	add_child(page)
	await get_tree().process_frame
	for ready: bool in [false, true]:
		ABManager._is_init_done = ready
		for raw: String in ["no", "yes", "", "invalid"]:
			ABManager.raw = raw
			for level_id: int in range(1, 5):
				page._level_model.level_id = level_id
				_reset_ab(raw, ready)
				page._configure_iq_round()
				_check(page._iq_progress.visible == (level_id >= 4), "IQ eligibility is independent of SDK readiness and value")
				var expected_calls: Array = ["get:iq_score_boost", "dye:iq_score_boost"] if ready and level_id >= 4 else []
				_check(ABManager.calls == expected_calls, "only eligible new rounds fetch then dye")
				if level_id < 4:
					page._configure_iq_round({"enabled": true})
					_check( not page._iq_progress.visible and ABManager.calls.is_empty(), "early snapshot cannot enable IQ")
	ABManager._is_init_done = true
	page._level_model.level_id = 10
	page._configure_iq_round()
	_check(page._iq_progress.visible and page._level_label.visible, "eligible round keeps level title and shows IQ above orders")
	_near(page._iq_progress.get_node("FillClip").size.x, 16.5, "initial IQ reaches first track marker")
	_near(page._iq_progress.get_global_rect().position.x, 324.0, "IQ track centers on actual viewport")
	_near(page._iq_progress.get_node("FillClip").global_position.y, 276.0, "fill top matches new Figma layout")
	_near(page._quota._count.position.x + page._quota._count.size.x * 0.5, page._quota._bottom_count_tab.position.x + page._quota._bottom_count_tab.size.x * 0.5, "order count centers in compact tab")
	_check(page._quota._bottom_count_tab.visible and page._quota._iq_tab.visible, "IQ enables both new tabs")
	_near(page._hard_badge.position.y, 76.0, "IQ keeps original difficulty badge position")
	page.hard = true
	page._refresh_iq_header()
	_near(page._iq_progress.global_position.y, 184.0, "difficulty does not move IQ into header")
	page.hard = false
	page._refresh_iq_header()
	for excluded: String in ["early", "special", "bonus"]:
		page._level_model.level_id = 3 if excluded == "early" else 10
		page.special = excluded == "special"
		page._bonus_type = 0 if excluded == "bonus" else -1
		ABManager.calls.clear()
		page._configure_iq_round()
		_check( not page._iq_progress.visible and page._level_label.visible, excluded + " keeps level label")
		_check(ABManager.calls.is_empty(), excluded + " does not fetch or dye IQ")
		_check(page._finalize_iq_win().mainline == (excluded == "early"), excluded + " journal mainline classification")
	page.special = false
	page._bonus_type = -1
	page._level_model.level_id = 10
	ABManager.calls.clear()
	page._configure_iq_round()
	page._iq_round.on_move(2, [1, 2] as Array[int])
	var saved: Dictionary = page._iq_round.snapshot()
	var saved_iq: float = page._iq_round.value()
	page.done = 2
	page._configure_iq_round(saved)
	_check(page._iq_round.enabled, "resume preserves enabled IQ")
	_near(page._iq_round.value(), saved_iq, "resume preserves earned base and combo points")
	page._configure_iq_round({"enabled": false})
	_check( not page._iq_round.enabled and not page._iq_progress.visible, "legacy disabled snapshot remains disabled until restart")
	_near(page._hard_badge.position.y, 76.0, "legacy disabled snapshot keeps original hard badge geometry")
	var legacy_result: Dictionary = page._finalize_iq_win()
	_check(legacy_result.mainline and not legacy_result.participated, "legacy disabled mainline still counts guarantee interval")
	page.done = 0
	page._configure_iq_round()
	_check(page._iq_round.enabled and page._iq_progress.visible, "restart enables IQ after a legacy disabled snapshot")
	_near(page._iq_round.value(), 40.0, "restart starts IQ at 40")
	page.done = 2
	page._configure_iq_round({}, true)
	_near(page._iq_round.value(), 60.0, "snapshot without IQ state reconstructs earned base only")
	page.done = 0
	for kind: String in ["hint", "undo", "rope"]:
		page._configure_iq_round()
		page.done = 6
		page._tracking_prop_used_round = {kind: 1}
		_check( not page._finalize_iq_win().guarantee_triggered, "page reads actual " + kind + " usage")
	page.done = 0
	page._tracking_prop_used_round = {}
	page._configure_iq_round()
	page.done = 6
	var result: Dictionary = page._finalize_iq_win()
	_check(result.guarantee_triggered, "page finalization uses original target flowers and finish time")
	UserState.begin_level_completion(10, result)
	page._iq_round.reset(true, 6)
	_check(page._finalize_iq_win() == result, "page retry reuses persisted final IQ instead of drawing again")
	UserState.reset_all()
	SceneManager.calls.clear()
	var started: int = Time.get_ticks_msec()
	var feedback = page._iq_genius_feedback
	var timing: Dictionary = {"delta": 0.0}
	var record_delta: Callable = func() -> void :
		timing.delta += get_process_delta_time()
	get_tree().process_frame.connect(record_delta)
	get_tree().create_timer(0.05).timeout.connect( func() -> void :
		_check(feedback.visible and feedback.is_playing(), "genius animation stays active during entrance"))
	_check( await page.show_iq_genius_feedback(), "genius feedback finishes")
	get_tree().process_frame.disconnect(record_delta)
	_check(Time.get_ticks_msec() - started >= 2150 and Time.get_ticks_msec() - started < 3000 and SceneManager.calls.is_empty() and not feedback.visible, 
		"feedback uses original speed + 2.0s start/0.2s unified fade; actual_ms=%d frame_delta_sum=%.4f" % [Time.get_ticks_msec() - started, timing.delta])
	_check(page._iq_genius_shown, "genius feedback is recorded as single shot")
	await page.show_iq_genius_feedback()
	_check( not feedback.visible, "same round feedback is single-shot")
	page._iq_genius_shown = false
	get_tree().create_timer(0.05).timeout.connect( func() -> void :
		page._end_flow_generation += 1
		page._configure_iq_round())
	_check( not await page.show_iq_genius_feedback(), "old feedback wait cancels after round generation changes")
	_check( not feedback.visible, "new round clears old genius display")
	var ui: IqProgressBar = page._iq_progress
	var stops: Array[float] = [16.5, 171.0, 277.0, 414.0]
	for i: int in IqProgressBar.MARK_VALUES.size():
		ui.set_iq(IqProgressBar.MARK_VALUES[i], false)
		_near(ui.get_node("FillClip").size.x, stops[i], "fill meets each physical marker")
	ui.set_iq(139.999, false)
	_check(ui.get_node("FillClip").size.x < 277.0, "mask uses actual IQ without rounding")
	ui.set_iq(140.0, false)
	_near(ui.get_node("FillClip").size.x, 277.0, "mask reaches IQ badge at 140")
	_check( not ui.has_node("Arrows"), "new fill uses no triangle overlay")
	var fill: TextureRect = ui.get_node("FillClip/Fill")
	_check(fill.size == Vector2(414.0, 26.0), "partial progress keeps full texture width and height")
	_check(ui.get_node("FillClip").clip_contents, "partial progress uses a straight clip instead of a rounded end cap")
	var glow: TextureRect = ui.get_node("FillClip/Glow")
	var glow_material: ShaderMaterial = glow.material as ShaderMaterial
	_check(glow_material.shader.code.contains("blend_add"), "front glow uses plus lighter blend")
	_check(glow_material.get_shader_parameter("fill_mask") == fill.texture, "front glow masks with the actual fill texture alpha")
	_check(glow.size == Vector2(35.0, 50.0), "front glow retains taller original dimensions")
	_near(glow.position.y, -12.0, "taller glow is vertically centered on full fill")
	var mask_rect: Vector4 = glow_material.get_shader_parameter("mask_uv_rect")
	_near(mask_rect.x * fill.size.x, glow.position.x, "alpha mask tracks glow origin")
	_near(mask_rect.y * fill.size.y, glow.position.y, "alpha mask tracks taller glow origin")
	_near(mask_rect.z * fill.size.x, glow.size.x, "alpha mask covers glow width")
	_near(mask_rect.w * fill.size.y, glow.size.y, "alpha mask covers glow height")
	var other_ui: IqProgressBar = load("res://scripts/main/pages/game/iq_progress_bar.tscn").instantiate()
	add_child(other_ui)
	other_ui.set_iq(90.0, false)
	var other_material: ShaderMaterial = other_ui.get_node("FillClip/Glow").material as ShaderMaterial
	_check(other_material != glow_material, "each UI instance owns independent moving alpha mask")
	_check(glow_material.get_shader_parameter("mask_uv_rect") == mask_rect, "another UI cannot move this progress mask")
	other_ui.queue_free()
	_near(glow.position.x + glow.size.x, ui.get_node("FillClip").size.x, "glow follows fill tip")
	ui.set_iq(0.0, false)
	_check(ui.get_node("FillClip").size.x == 0.0 and not glow.visible, "empty progress does not leak glow")
	ui.set_iq(200.0, false)
	_check(ui.get_node("FillClip").size.x == 414.0 and ui._iq == 200.0, "UI caps bar without changing actual IQ")
	_check(ui.get_node("FillClip").size.x == fill.size.x, "full progress reveals original right rounded cap")
	for viewport_width: float in [1315.0, 1755.0]:
		UiMetrics.test_size.x = viewport_width
		page._level_block.position.x = (viewport_width - 470.0) * 0.5
		page._coin_hud.position.x = viewport_width - 318.0
		page._refresh_iq_header()
		_near(ui.get_global_rect().position.x, viewport_width * 0.5 - 216.0, "wide viewport keeps IQ centered with quota")
		_near(ui.size.x, 432.0, "wide viewport does not stretch whole component")
	UiMetrics.test_size.x = 1080.0
	UiMetrics.test_safe_top = 28.0
	page._refresh_iq_header()
	_near(ui.global_position.y, 212.0, "IQ follows quota safe area exactly once")
	UiMetrics.test_safe_top = 1000.0
	page._refresh_iq_header()
	_near(page._quota.get_global_rect().end.y, 604.0, "large inset cannot push order count into board")
	UiMetrics.test_safe_top = 0.0
	for total: int in [1, 3, 6, 10, 11]:
		page._quota.setup(total)
		page._refresh_iq_header()
		_check(page._quota.size.x >= 524.0, "narrow orders leave room for full IQ tab")
		_near(ui.global_position.x + ui.size.x * 0.5, 540.0, "IQ remains centered for every order count")
		_near(page._quota._board.position.y, 204.0, "IQ preserves fly-to-pot geometry")
	page._quota.set_iq_layout_enabled(false)
	_check( not page._quota._bottom_count_tab.visible and not page._quota._iq_tab.visible, "control hides new tabs on reuse")
	_near(page._quota._count.position.y, JuiceQuotaBar.COUNT_Y, "control restores top order count")
	_check(page._quota._count.get_theme_font_size("font_size") == 56, "control restores original count typography")
	page._quota.set_iq_layout_enabled(true)
	page._refresh_iq_header()
	ui.size.x = 300.0
	ui.set_iq(90.0, false)
	_near(ui.get_node("FillClip").size.x, 171.0 * 300.0 / 432.0, "responsive fill stays aligned to scaled background")
	_near(fill.size.x, 414.0 * 300.0 / 432.0, "responsive fill scales full image rather than partial progress")
	mask_rect = glow_material.get_shader_parameter("mask_uv_rect")
	_near(mask_rect.x * fill.size.x, glow.position.x, "responsive alpha mask follows the scaled fill")
	page.queue_free()
	await get_tree().process_frame


func _test_genius_locales() -> void :
	var original_locale: String = TranslationServer.get_locale()
	var feedback = load("res://scripts/main/pages/game/iq_genius_feedback.tscn").instantiate()
	add_child(feedback)
	for locale: String in ["zh_CN", "en", "pt_BR", "id", "fil", "es", "ru", "de", "ja", "fr", "ko", "it", "pl", "tr", "uk", "zh_TW", "th", "ms", "vi", "ro", "nl", "nb", "fi", "el", "sv", "hu", "bn", "ta", "ur"]:
		TranslationServer.add_translation(load("res://assets/localization/translations.%s.translation" % locale))
		TranslationServer.set_locale(locale)
		feedback.present()
		var title = feedback.get_node("TitleViewport/Title")
		_check(title._display_text == tr("GAME_IQ_GENIUS_TITLE") and title._display_text != "GAME_IQ_GENIUS_TITLE", 
			"genius title translation resolves " + locale)
		_check( not title._items.is_empty() and title._fit_scale > 0.0 and title._fit_scale <= 1.0, 
			"genius title shapes and fits " + locale)
		for item: Dictionary in title._items:
			_check(item.glyph.index > 0, "genius title fallback glyph exists " + locale)
			var ts: TextServer = TextServerManager.get_primary_interface()
			var key: Vector2i = Vector2i(title.FONT_SIZE, 0)
			ts.font_render_glyph(item.glyph.font_rid, key, item.glyph.index)
			var glyph_rect: Rect2 = Rect2(ts.font_get_glyph_offset(item.glyph.font_rid, key, item.glyph.index), 
				ts.font_get_glyph_size(item.glyph.font_rid, key, item.glyph.index))
			if glyph_rect.has_area():
				glyph_rect.position += item.position
				glyph_rect = glyph_rect.grow(title.OUTLINE_RADIUS)
				var bounds: Rect2 = Transform2D(item.angle, Vector2.ONE * title._fit_scale, 0.0, item.origin) * glyph_rect
				_check(bounds.position.x >= 0.0 and bounds.position.y >= 0.0
					and bounds.end.x <= title.size.x and bounds.end.y + 8.0 <= title.size.y, 
					"genius title ink stays inside cache %s bounds=%s" % [locale, bounds])
		feedback.hide_now()
	_near(feedback.get_node("Composite/Dim").color.a, 0.8, "genius dims real board with design opacity")
	_check(feedback.get_node("TitleViewport").render_target_update_mode == SubViewport.UPDATE_ONCE, 
		"title mask updates once per language change while Spine moves the cached text")
	UiMetrics.test_size.x = 1315.0
	feedback._layout()
	_near(feedback.get_node("Composite/Content").position.x, 117.5, "genius centers on actual viewport width")
	UiMetrics.test_size.x = 1080.0
	TranslationServer.set_locale(original_locale)
	feedback.queue_free()


func _test_genius_animation() -> void :
	var feedback: Control = load("res://scripts/main/pages/game/iq_genius_feedback.tscn").instantiate()
	add_child(feedback)
	var spine: SpineSprite = feedback.get_node("Composite/Content/Spine")
	var title: TextureRect = feedback.get_node("Composite/Content/Spine/TitleAnchor/Title")
	var composite: CanvasGroup = feedback.get_node("Composite")
	_near(spine.skeleton_data_res.find_animation("enter").get_duration(), 2.5, "new delivered entrance duration")
	_check(spine.skeleton_data_res.find_animation("idle") == null, "new source has no idle; only enter is played")
	feedback.present()
	feedback.set_process(false)
	_check(spine.get_skeleton().find_slot("title_iq_genius").get_attachment() == null, "baked title suppressed, colleague title kept")
	feedback._advance_animation(1.99)
	_near(composite.self_modulate.a, 1.0, "composite remains visible before 2.0s")
	_near(spine.get_animation_state().get_current(0).get_track_time(), 1.99, "enter retains original playback speed")
	feedback._advance_animation(0.11)
	_near(composite.self_modulate.a, 0.5, "flattened group fades halfway at 2.1s")
	_near(feedback.modulate.a, 1.0, "parent alpha does not fade internal draw layers")
	_near(composite.modulate.a, 1.0, "composite inherited alpha remains unchanged")
	_near(spine.modulate.a, 1.0, "Spine alpha is not independently faded")
	_check(feedback.is_playing(), "end flow waits for group fade")
	feedback._advance_animation(0.21)
	_check( not feedback.visible and not feedback.is_playing() and not feedback.is_processing(), "group hidden and stopped by 2.2s")
	feedback.present()
	feedback.set_process(false)
	_near(composite.self_modulate.a, 1.0, "replay restores composite opacity")
	_near(spine.get_animation_state().get_current(0).get_track_time(), 0.0, "replay clears old tracks and begins only enter")
	feedback.hide_now()
	_check(spine.get_animation_state().get_current(0) == null, "cancel clears tracks")

	spine.skeleton_data_res = null
	feedback.hide_now()
	feedback.present()
	_check( not feedback.visible and not feedback.is_playing() and not feedback.is_processing(), 
		"unavailable skeleton skips genius without blocking end flow")
	feedback.queue_free()


func _test_progress_animation() -> void :
	var ui: IqProgressBar = load("res://scripts/main/pages/game/iq_progress_bar.tscn").instantiate()
	add_child(ui)
	ui.set_iq(40.0, false)
	ui.show()
	ui.set_iq(180.0)
	var tween: Tween = ui._progress_tween
	_check(tween != null, "score increase starts a progress tween")
	tween.pause()
	_near(ui.get_node("FillClip").size.x, 16.5, "progress increase does not jump to target")
	_check(ui._iq == 180.0, "animation does not delay actual target IQ")
	for quarter: int in range(1, 3):
		tween.custom_step(IqProgressBar.PROGRESS_DURATION * 0.25)
		_near(ui.get_node("FillClip").size.x, lerpf(16.5, 414.0, quarter * 0.25), "progress advances equal distances at equal times")
		var glow: TextureRect = ui.get_node("FillClip/Glow")
		_near(glow.position.x + glow.size.x, ui.get_node("FillClip").size.x, "glow follows animated cut line")
	ui.set_iq(180.0)
	_check(ui._progress_tween == tween, "same target refresh preserves running tween")
	var current: float = ui.get_node("FillClip").size.x
	ui.set_iq(200.0)
	_check(ui._progress_tween == tween, "above maximum IQ preserves tween to capped endpoint")
	ui.set_iq(140.0)
	_near(ui.get_node("FillClip").size.x, current, "retarget starts from visible progress without jumping")
	_check( not tween.is_valid(), "retarget cancels old progress tween")
	tween = ui._progress_tween
	tween.pause()
	tween.custom_step(IqProgressBar.PROGRESS_DURATION * 0.5)
	_near(ui.get_node("FillClip").size.x, lerpf(current, 277.0, 0.5), "retarget continues with linear progression")
	ui.hide()
	_check( not tween.is_valid() and ui._progress_tween == null, "hiding UI cancels old progress animation")
	_near(ui.get_node("FillClip").size.x, 277.0, "hidden UI settles at target for next display")
	ui.show()
	ui.set_iq(40.0, false)
	_near(ui.get_node("FillClip").size.x, 16.5, "new round resets immediately without downward animation")
	ui.set_iq(90.0)
	tween = ui._progress_tween
	tween.pause()
	tween.custom_step(IqProgressBar.PROGRESS_DURATION)
	_near(ui.get_node("FillClip").size.x, 171.0, "progress reaches exact target at fixed duration")
	ui.queue_free()


func _test_flow() -> void :
	var fake = load("res://iq_flow_page.gd").new()
	add_child(fake)
	await GameEndFlow.run(fake, 10)
	_check(fake.calls.find("iq_end") < fake.calls.find("coin") and fake.calls.find("coin") < fake.calls.find("finish"), "actual GameEndFlow orders IQ then coin then finish")
	fake.calls.clear()
	fake.cancel_iq = true
	await GameEndFlow.run(fake, 10)
	_check( not fake.calls.has("coin") and not fake.calls.has("finish"), "cancelled IQ step stops old presentation chain")
	fake.queue_free()


func _reset_ab(raw: String, ready: bool = true, locked: bool = false) -> void :
	ABManager.raw = raw
	ABManager._is_init_done = ready
	ABManager._startup_control_locked = locked
	ABManager._iq_score_boost_dyed = false
	ABManager.iq_score_boost = IqScoreBoostConfig.new()
	ABManager.iq_score_boost.init_default()
	ABManager._configs_by_key = {"iq_score_boost": ABManager.iq_score_boost}
	ABManager.calls.clear()


func _test_ab_config() -> void :
	UserState.reset_all()
	for raw: String in ["no", "exp_1", "exp_2", "yes", "", "invalid"]:
		_reset_ab(raw)
		var config: IqScoreBoostConfig = ABManager.iq_score_boost
		var group: int = 1 if raw == "exp_1" else (2 if raw == "exp_2" else 0)
		_check(config.key == "iq_score_boost" and config.version == "1.0.10" and config.group_count == 3, "AB metadata and three cheat groups")
		_check(config.value() == group and config.peek_value() == group and config.peek_sdk_value() == group, "all reads map exact SDK string " + raw)
		_check(config.is_score_boost_enabled() == (group > 0) and config.should_use_s_grade_guarantee() == (group == 2), "semantic methods " + raw)
		config.load_value_silent()
		_check( not ABManager.calls.has("dye:iq_score_boost") and not ABManager.calls.has("get_int:iq_score_boost"), "silent/string channel does not dye or use int")
		ABManager.calls.clear()
		ABManager.dye_at_iq_score_boost()
		_check(ABManager.calls == ["get:iq_score_boost", "dye:iq_score_boost"], "all three groups fetch immediately before dye")
		ABManager.calls.clear()
		ABManager.dye_at_iq_score_boost()
		_check(ABManager.calls.is_empty(), "dye guard spans repeated rounds")
	_reset_ab("exp_2", false)
	_check(ABManager.iq_score_boost.value() == 0, "SDK not ready defaults to control")
	ABManager.dye_at_iq_score_boost()
	_check(ABManager.calls.is_empty() and not ABManager._iq_score_boost_dyed, "unready SDK does not consume dye guard")
	ABManager._is_init_done = true
	ABManager.dye_at_iq_score_boost()
	_check(ABManager.iq_score_boost.value() == 2, "SDK readiness can be used at a later new round")
	_reset_ab("exp_2", true, true)
	ABManager.dye_at_iq_score_boost()
	_check(ABManager.calls.is_empty() and not ABManager._iq_score_boost_dyed, "startup timeout never dyes")
	_check(ABManager.iq_score_boost.value() == 0, "startup timeout uses SDK fallback")
	for group: int in range(3):
		ABManager.iq_score_boost.set_debug_override(group)
		_check(ABManager.iq_score_boost.value() == group and ABManager.iq_score_boost.peek_value() == group, "cheat overrides timeout with group %d" % group)
	ABManager.iq_score_boost.clear_debug_override()
	_reset_ab("no")


func _test_boosted_scores() -> void :
	for use_s: bool in [false, true]:
		for target: int in [1, 3, 7, 17]:
			var control: = IqRoundModel.new()
			var boosted: = IqRoundModel.new()
			control.reset(true, target)
			boosted.reset(true, target, 0, {}, true, use_s)
			_near(boosted.value(), 60.0, "boosted round initial 60")
			for done: int in range(1, target + 1):
				control.on_move(done, [done] as Array[int])
				boosted.on_move(done, [done] as Array[int])
				_near(boosted.value() - control.value(), 20.0, "base and combo scoring remain identical")
			boosted.sync_done(0)
			boosted.on_move(target, [2] as Array[int])
			var saved: Dictionary = boosted.snapshot()
			var restored: = IqRoundModel.new()
			restored.reset(true, target, target, saved)
			_near(restored.value(), boosted.value(), "boosted resume keeps high-water base and combo")
			_check(restored.score_boost_enabled and restored.s_grade_guarantee == use_s, "snapshot freezes both rules")
			_near(restored.genius_iq(), 160.0, "boosted threshold 160")
			restored.reset(true, target)
			_near(restored.value(), 40.0, "reuse can restore control")
	var old: = IqRoundModel.new()
	old.reset(true, 6, 2, {"enabled": true, "combo_points": 3})
	_near(old.value(), 63.0, "old enabled snapshot preserves 40 initial")
	_check( not old.score_boost_enabled and not old.s_grade_guarantee, "old snapshot defaults to old rules")


func _test_boosted_guarantee() -> void :
	var rolls: Array[int] = [0]
	var random_iq: Callable = func() -> int:
		rolls[0] += 1
		return 170
	var model: = IqRoundModel.new()
	for use_s: bool in [false, true]:
		model.reset(true, 1, 1, {"combo_points": 39}, true, use_s)
		_near(model.value(), 159.0, "159 before boosted guarantee")
		var before_rolls: int = rolls[0]
		var result: Dictionary = model.finalize(false, 80.0, false, 4, random_iq)
		_check(result.guarantee_triggered and result.final_iq == 170.0, "both boosted rules guarantee below 160")
		_check(model.finalize(true, -1.0, false, 0, random_iq) == result and rolls[0] == before_rolls + 1, "boosted retry draws once")
		for bonus: int in [40, 41, 100]:
			model.reset(true, 1, 1, {"combo_points": bonus}, true, use_s)
			before_rolls = rolls[0]
			_check( not model.finalize(false, 99.0, true, 4, random_iq, 99.0).guarantee_triggered and rolls[0] == before_rolls, "IQ at/above 160 never rolls")
		for prop: String in ["hint", "undo", "rope"]:
			model.reset(true, 1, 1, {}, true, use_s)
			_check( not model.finalize(true, 99.0, true, 4, random_iq, 99.0).guarantee_triggered, "both groups reject successful prop " + prop)
		model.reset(true, 2, 1, {}, true, use_s)
		_check( not model.finalize(false, 99.0, true, 4, random_iq, 99.0).guarantee_triggered, "boosted guarantee requires final cup")
		model.reset(false, 1, 1, {}, true, use_s)
		_check( not model.finalize(false, 99.0, true, 4, random_iq, 99.0).guarantee_triggered, "excluded rounds never guarantee")
		for i: int in 100:
			model.reset(true, 1, 1, {}, true, use_s)
			var iq: float = float(model.finalize(false, 80.0, true, 0).final_iq)
			_check(iq >= 160.0 and iq <= 180.0 and iq == floorf(iq), "boosted random integer range")
	model.reset(true, 1, 1, {}, true)
	_check(model.finalize(false, 60.0, false, 4, random_iq).guarantee_triggered, "exp1 A exact boundary plus four completions")
	for pct: float in [-1.0, 59.999]:
		model.reset(true, 1, 1, {}, true)
		_check( not model.finalize(false, pct, true, 4, random_iq, 99.0).guarantee_triggered, "exp1 uses only time A")
	for interval: int in range(4):
		model.reset(true, 1, 1, {}, true)
		_check( not model.finalize(false, 80.0, false, interval, random_iq).guarantee_triggered, "exp1 Normal interval below four")
	for difficulty: String in ["Hard", "SuperHard"]:
		model.reset(true, 1, 1, {}, true)
		_check(model.finalize(false, 60.0, true, 0, random_iq).guarantee_triggered, "exp1 " + difficulty + " ignores interval")
	for grades: Array in [[80.0, -1.0], [-1.0, 80.0], [79.999, 80.0], [80.0, 79.999]]:
		model.reset(true, 1, 1, {}, true, true)
		_check(model.finalize(false, grades[0], false, 0, random_iq, grades[1]).guarantee_triggered, "exp2 either S at exact boundary ignores interval")
	for grades: Array in [[-1.0, -1.0], [79.999, 79.999], [60.0, 60.0]]:
		model.reset(true, 1, 1, {}, true, true)
		_check( not model.finalize(false, grades[0], true, 4, random_iq, grades[1]).guarantee_triggered, "exp2 A alone never guarantees, even Hard")
	for roll: int in [0, 160, 180, 999]:
		model.reset(true, 1, 1, {}, true)
		var fixed: Callable = func() -> int: return roll
		_near(model.finalize(false, 60.0, true, 0, fixed).final_iq, clampi(roll, 160, 180), "boosted inclusive random clamp")
	_check(ResultPercentileBank.lookup_percentile("time", 24, 74.8) >= 80.0 and ResultPercentileBank.lookup_percentile("time", 24, 74.801) < 80.0, "original time S exact boundary")
	_check(ResultPercentileBank.lookup_percentile("step", 24, 25.0) >= 80.0 and ResultPercentileBank.lookup_percentile("step", 24, 26.0) < 80.0, "original step S exact boundary")


func _test_boosted_page() -> void :
	var page = load("res://iq_page_seams.tscn").instantiate()
	add_child(page)
	await get_tree().process_frame
	for raw: String in ["exp_1", "exp_2"]:
		_reset_ab(raw)
		page.done = 0
		page._configure_iq_round()
		_near(page._iq_round.value(), 60.0, "page config starts either group at 60")
		_check(page._iq_round.s_grade_guarantee == (raw == "exp_2"), "page freezes selected guarantee")
		page._iq_round.on_move(2, [1, 2] as Array[int])
		page.done = 2
		var saved: Dictionary = page._iq_round.snapshot()
		var iq: float = page._iq_round.value()
		_reset_ab("no")
		page._configure_iq_round(saved, true)
		_near(page._iq_round.value(), iq, "resume does not change initial/earned score after SDK changes")
		_check(ABManager.calls.is_empty() and page._iq_round.s_grade_guarantee == (raw == "exp_2"), "resume restores rules without fetch or dye")
	_reset_ab("exp_2")
	page._configure_iq_round({"enabled": true, "combo_points": 3}, true)
	_near(page._iq_round.value(), 63.0, "legacy enabled resume remains control despite SDK exp2")
	page._configure_iq_round({}, true)
	_near(page._iq_round.value(), 60.0, "resume without any IQ key reconstructs old score")
	_check( not page._iq_round.score_boost_enabled and ABManager.calls.is_empty(), "empty legacy resume never fetches experiment")
	page.done = 0
	page._configure_iq_round()
	_near(page._iq_round.value(), 60.0, "restart after legacy resume applies experiment")
	UserState.reset_all()
	UserState.begin_level_completion(9, {"participated": true, "mainline": true, "guarantee_triggered": true})
	UserState.finalize_level_completion(9)
	page.attempts = 25
	page.elapsed_ms = 91600
	page.done = 6
	var result: Dictionary = page._finalize_iq_win()
	_check(result.guarantee_triggered and result.final_iq >= 160.0 and result.final_iq <= 180.0, "page exp2 step S bypasses fresh cooldown using actual attempts")
	UserState.begin_level_completion(10, result)
	page._iq_round.reset(true, 6, 6, {}, true, true)
	_check(page._finalize_iq_win() == result, "boosted persisted final IQ is reused without reroll")
	UserState.reset_all()
	page.attempts = 26
	page.elapsed_ms = 74801
	page.done = 0
	page._configure_iq_round()
	page.done = 6
	_check( not page._finalize_iq_win().guarantee_triggered, "page exp2 counts all attempts and rejects below-S time/step")
	page.done = 0
	page.elapsed_ms = 74800
	page._configure_iq_round()
	page.done = 6
	_check(page._finalize_iq_win().guarantee_triggered, "page exp2 time S works without step S")
	for prop: String in ["hint", "undo", "rope"]:
		page.done = 0
		page._configure_iq_round()
		page._tracking_prop_used_round = {prop: 1}
		page.done = 6
		_check( not page._finalize_iq_win().guarantee_triggered, "page exp2 observes real prop usage " + prop)
	page._tracking_prop_used_round = {}
	page.done = 0
	page._level_model.juice.total_flowers = 999
	page._configure_iq_round()
	page.done = 6
	_check( not page._finalize_iq_win().guarantee_triggered, "page missing shape has no guarantee")
	page._level_model.juice.total_flowers = 24
	page._iq_round.reset(true, 6, 6, {"combo_points": 39}, true, true)
	_check( await page.show_iq_genius_feedback() and not page._iq_genius_shown, "boosted IQ159 skips Genius")
	page._iq_round.reset(true, 6, 6, {"combo_points": 40}, true, true)
	_check( await page.show_iq_genius_feedback() and page._iq_genius_shown, "boosted IQ160 plays Genius once")
	page.queue_free()
	await get_tree().process_frame
	_reset_ab("no")


func _test_boosted_progress() -> void :
	var ui: IqProgressBar = load("res://scripts/main/pages/game/iq_progress_bar.tscn").instantiate()
	add_child(ui)
	ui.show()
	ui.set_score_boost_enabled(true)
	for i: int in IqProgressBar.BOOSTED_MARK_VALUES.size():
		ui.set_iq(IqProgressBar.BOOSTED_MARK_VALUES[i], false)
		_near(ui.get_node("FillClip").size.x, IqProgressBar.FILL_STOPS[i + 1], "boosted mapping hits same physical marker")
	_check(ui.get_node("Marks/Iq40").text == "60" and ui.get_node("Marks/Iq90").text == "110" and ui.get_node("Marks/Iq180").text == "200", "boosted visible labels update")
	ui.set_iq(159.999, false)
	_check( not ui._badge_unlocked, "boosted badge locked just below 160")
	ui.set_iq(160.0, false)
	_check(ui._badge_unlocked, "boosted badge unlocks at 160")
	ui.set_iq(60.0, false)
	ui.set_iq(200.0)
	var tween: Tween = ui._progress_tween
	tween.pause()
	tween.custom_step(IqProgressBar.PROGRESS_DURATION * 0.5)
	_near(ui._display_width, lerpf(16.5, 414.0, 0.5), "boosted animation retains linear 0.4 seconds")
	ui.set_score_boost_enabled(false)
	_check( not tween.is_valid() and ui._progress_tween == null, "switching rules cancels old tween")
	ui.set_iq(40.0, false)
	_near(ui._display_width, 16.5, "reuse restores control start")
	_check(ui.get_node("Marks/Iq40").text == "40" and ui.get_node("Marks/Iq90").text == "90" and ui.get_node("Marks/Iq180").text == "180", "reuse restores control labels")
	_check( not ui._badge_unlocked and not ui._badge_impact.emitting and not ui._badge_impact.visible, "reuse clears badge and particles")
	ui.set_countdown_progress(0.5)
	ui.set_score_boost_enabled(true)
	_near(ui._display_width, 207.0, "score rule switch leaves countdown geometry intact")
	ui.set_iq(60.0, false)
	_check(ui.get_node("Marks").visible and not ui._countdown_mode, "IQ restores marks after countdown reuse")
	ui.queue_free()
