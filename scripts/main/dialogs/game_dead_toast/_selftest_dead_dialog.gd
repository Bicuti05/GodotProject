extends SceneTree



func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var state: Node = root.get_node("UserState")
	state.clear_prop_unlock_shown()

	state.set("_prop_early_unlocked", {"rope": true})
	state.mark_prop_unlock_shown("rope")
	state.grant_prop_free_use("rope")
	assert (state._save_data() == OK)
	state.set("_prop_early_unlocked", {})
	assert (state._load_data() == OK)
	assert (state.is_prop_early_unlocked("rope") and state.is_prop_unlock_shown("rope"))
	assert (state.is_prop_free_available("rope"))
	state.consume_prop_free_use("rope")
	state.grant_prop_free_use("rope")
	assert ( not state.is_prop_free_available("rope"))
	var stored: ConfigFile = ConfigFile.new()
	assert (stored.load_encrypted_pass("res://save.cfg", state.SAVE_PASSWORD) == OK)
	assert (stored.get_value("progress", "prop_early_unlocked")["rope"])
	var old_level: int = state.get_current_level()
	state.set_current_level(1)
	var prop: PropBtn = load("res://scripts/widget/prop_btn/prop_btn.tscn").instantiate()
	root.add_child(prop)
	prop.configure(PropBtn.PropType.ROPE)
	prop.refresh(1, 0, true, false, 0, false)
	assert (prop.get_business_state() == PropBtn.PropState.LOCKED)
	assert ( not prop.get_node("Icon").visible and prop.get_node("LockOverlay").visible)
	prop.set_early_unlocked(state.is_prop_early_unlocked("rope"))
	assert (prop.needs_ad_ready(1, 0, true, false, 0, true))
	prop.refresh(1, 0, true, true, 0, false, true)
	assert (prop.get_business_state() == PropBtn.PropState.FREE and not prop.disabled)
	assert (prop.get_node("Icon").texture == prop.rope_texture)
	prop.set_dead_dialog_icon(true)
	assert (prop.get_node("Icon").texture == prop.rope_dead_texture)
	prop.refresh(1, 0, false, true, 0, false, true)
	assert (prop.get_node("Icon").texture == prop.rope_disabled_texture)
	prop.refresh(1, 0, true, true, 0, false, true)
	assert (prop.get_node("Icon").texture == prop.rope_dead_texture)
	prop.set_dead_dialog_icon(false)
	assert (prop.get_node("Icon").texture == prop.rope_texture)
	prop.set_dead_glow(true)
	var shake: Tween = prop.get("_dead_shake_tween") as Tween
	assert (shake != null and prop.get_node("DeadGlow").visible)
	prop.set_dead_glow(true)
	assert (prop.get("_dead_shake_tween") == shake)
	prop.set_dead_glow(false)
	assert (prop.get("_dead_shake_tween") == null)
	var page_script: GDScript = load("res://scripts/main/pages/game/juice_game_page.gd")
	var page: JuiceGamePage = page_script.new()
	state.set_current_level(5)
	page.set("_prop_ui", {"rope": {"btn": prop}})
	assert (page._pending_prop_unlock_keys().is_empty())
	page.set("_prop_ui", {})
	page.free()
	prop.free()
	state.clear_prop_unlock_shown()
	state.set_current_level(old_level)
	var host: Control = Control.new()
	root.add_child(host)
	host.position = Vector2(30, 40)
	var button: Button = Button.new()
	host.add_child(button)
	button.position = Vector2(100, 1900)
	button.z_index = 20
	var position_before: Vector2 = button.global_position
	var index_before: int = button.get_index()
	var toast: GameDeadToast = load("res://scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn").instantiate()
	root.add_child(toast)
	assert (toast.get_child_count() == 2)
	assert (toast.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("Card").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("Card/Title").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("Card/Hint").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("RedesignedCard").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("RedesignedCard/Title").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert (toast.get_node("RedesignedCard/Hint").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	_test_dead_toast_multiline(toast)
	_test_dead_toast_cheer(toast)
	_test_redesigned_card_layout(toast)
	for _i: int in range(2):
		toast._on_show()
		assert (toast.visible and toast.get_node("Card/Title").visible)
		assert (toast.get_node("Card").visible and not toast.get_node("RedesignedCard").visible)
		assert (button.get_parent() == host and button.get_index() == index_before)
		assert (button.global_position.is_equal_approx(position_before) and button.z_index == 20)
		toast._on_hide()
		assert ( not toast.visible)
	toast.free()
	host.free()
	_test_dead_undo_availability()
	_test_dead_recovery_recommendations(page_script)
	await _test_reset_confirm()
	print("PASS dead dialog")
	quit()



func _test_dead_toast_cheer(toast: GameDeadToast) -> void :
	var original_locale: String = TranslationServer.get_locale()
	var hint: RichTextLabel = toast.get_node("Card/Hint") as RichTextLabel
	var cheer_hint: RichTextLabel = toast.get_node("RedesignedCard/Hint") as RichTextLabel
	var card: Control = toast.get_node("Card") as Control
	var redesigned_card: Control = toast.get_node("RedesignedCard") as Control
	TranslationServer.set_locale("en")
	toast._on_show({"filled_pots": 3, "target_pots": 5})
	assert (String(toast.get("_cheer_key")) == "")
	assert ( not hint.text.contains("\n"))
	assert (card.visible and not redesigned_card.visible)
	toast._on_show({"revive_prompt_redesigned": true, "filled_pots": 3, "target_pots": 5})
	var key: String = String(toast.get("_cheer_key"))
	assert (key.begins_with("JUICE_DEAD_CHEER_PROGRESS_"))

	assert ( not card.visible and redesigned_card.visible)
	assert ( not hint.text.contains("\n"))
	assert (cheer_hint.get_parsed_text().ends_with(_expected_cheer(key, 3)))

	assert (cheer_hint.text.contains("[color=#0AA733]"))
	assert ( not cheer_hint.text.contains("{ACCENT_OPEN}") and not cheer_hint.text.contains("{ACCENT_CLOSE}"))

	toast._on_show({"revive_prompt_redesigned": true, "filled_pots": 2, "target_pots": 4})
	key = String(toast.get("_cheer_key"))
	assert (key.begins_with("JUICE_DEAD_CHEER_PLAIN_"))
	assert (cheer_hint.get_parsed_text().ends_with(_expected_cheer(key, 2)))
	assert ( not cheer_hint.get_parsed_text().contains("%d"))
	assert ( not cheer_hint.text.contains("[color=#0AA733]"))

	var picked: String = key
	TranslationServer.set_locale("ja")
	toast._apply_localized_copy()
	assert (String(toast.get("_cheer_key")) == picked)
	assert (cheer_hint.get_parsed_text().ends_with(_expected_cheer(picked, 2)))
	toast._on_hide()
	assert (String(toast.get("_cheer_key")) == "")
	assert ( not card.visible and not redesigned_card.visible)
	TranslationServer.set_locale(original_locale)



func _expected_cheer(key: String, filled: int) -> String:
	var raw: String = tr(key).replace("{ACCENT_OPEN}", "").replace("{ACCENT_CLOSE}", "")
	return raw % filled if raw.contains("%d") else raw



func _test_redesigned_card_layout(toast: GameDeadToast) -> void :
	var original_locale: String = TranslationServer.get_locale()
	var card: Panel = toast.get_node("RedesignedCard") as Panel
	var hint: RichTextLabel = toast.get_node("RedesignedCard/Hint") as RichTextLabel
	var expected_bottom: float = UiMetrics.viewport_size().y - UiMetrics.safe_insets().y\
	- toast.PROP_BAR_RESERVED_H - toast.CARD_BOTTOM_GAP
	TranslationServer.set_locale("en")
	toast._on_show({"revive_prompt_redesigned": true, "filled_pots": 3, "target_pots": 5})
	assert (is_equal_approx(card.size.x, toast.REDESIGNED_CARD_W))
	assert (is_equal_approx(hint.size.x, toast.REDESIGNED_BODY_W))
	assert (is_equal_approx(hint.position.x, toast.REDESIGNED_BODY_X))
	assert (is_equal_approx(hint.position.y, toast.REDESIGNED_BODY_TOP))
	assert (hint.get_content_height() > 0.0)
	assert (is_equal_approx(card.size.y, 
		toast.REDESIGNED_BODY_TOP + float(hint.get_content_height()) + toast.REDESIGNED_BOTTOM_PAD))
	assert (absf(card.position.y + card.size.y - expected_bottom) <= 0.51)
	assert (is_equal_approx(card.position.x, UiMetrics.center_left(toast.REDESIGNED_CARD_W)))
	assert (hint.get_theme_font_size("normal_font_size") == 48)
	assert ( not hint.scroll_active)

	TranslationServer.set_locale("fil")
	toast._apply_localized_copy()
	toast._layout()
	var tall: float = card.size.y
	assert (tall > toast.REDESIGNED_BODY_TOP + toast.REDESIGNED_BOTTOM_PAD)
	TranslationServer.set_locale("en")
	toast._apply_localized_copy()
	toast._layout()
	assert (card.size.y < tall)
	assert (absf(card.position.y + card.size.y - expected_bottom) <= 0.51)
	var current_size: Vector2 = card.size
	toast._layout()
	assert (card.size.is_equal_approx(current_size))
	toast._on_hide()
	TranslationServer.set_locale(original_locale)
	toast._apply_localized_copy()
	toast._layout()



func _test_dead_toast_multiline(toast: GameDeadToast) -> void :
	var original_locale: String = TranslationServer.get_locale()
	var card: NinePatchRect = toast.get_node("Card") as NinePatchRect
	var hint: RichTextLabel = toast.get_node("Card/Hint") as RichTextLabel
	var card_title: Label = toast.get_node("Card/Title") as Label
	var expected_bottom: float = UiMetrics.viewport_size().y - UiMetrics.safe_insets().y\
	- toast.PROP_BAR_RESERVED_H - toast.CARD_BOTTOM_GAP
	for hint_unwinnable: bool in [false, true]:

		TranslationServer.set_locale("fil")
		toast._on_show({"hint_unwinnable": hint_unwinnable})
		var filipino_height: float = card.size.y
		assert (filipino_height > toast.CARD_SIZE.y)
		for locale: String in ["fil", "en", "fil"]:
			TranslationServer.set_locale(locale)
			toast._apply_localized_copy()
			toast._layout()
			var hint_top: float = 100.0
			var base_hint_bottom: float = 160.0
			var content_height: float = float(hint.get_content_height())
			var extra_height: float = maxf(0.0, content_height - (base_hint_bottom - hint_top))
			assert (content_height > 0.0 and hint.size.y >= content_height)
			assert (is_equal_approx(hint.offset_top, hint_top))
			assert (is_equal_approx(card.size.x, toast.CARD_SIZE.x))
			assert (is_equal_approx(card.size.y, toast.CARD_SIZE.y + extra_height))
			assert (absf(card.position.y + card.size.y - expected_bottom) <= 0.51)
			assert (is_equal_approx(card.size.y - hint.offset_bottom, 
				toast.CARD_SIZE.y - base_hint_bottom))
			assert (hint.get_theme_font_size("normal_font_size") == 48)
			assert (card_title.visible)
			assert ( not hint.scroll_active)
			var copy_key: String = "JUICE_DEAD_OTHER_BOOSTERS_HINT" if hint_unwinnable\
			else "JUICE_DEAD_BOOSTER_HINT"
			var expected_copy: String = tr(copy_key).replace("{ACCENT_OPEN}", "")\
			.replace("{ACCENT_CLOSE}", "").replace("%1", "").replace("%2", "")
			assert (hint.get_parsed_text() == expected_copy)
			if hint_unwinnable:
				assert (hint.text.contains("[color=#FB6458]") and hint.text.contains("[/color]"))
			if locale == "fil":
				assert (is_equal_approx(card.size.y, filipino_height))

			var current_size: Vector2 = card.size
			toast._layout()
			assert (card.size.is_equal_approx(current_size))

		hint.text = "OK"
		toast._layout()
		assert (card.size.is_equal_approx(toast.CARD_SIZE))
		assert (absf(card.position.y + card.size.y - expected_bottom) <= 0.51)
		toast._on_show({"hint_unwinnable": hint_unwinnable})
		assert (is_equal_approx(card.size.y, filipino_height))
	toast._on_hide()
	TranslationServer.set_locale(original_locale)
	toast._apply_localized_copy()
	toast._layout()


func _test_dead_undo_availability() -> void :
	var board_script: GDScript = GDScript.new()
	board_script.source_code = "extends \"res://scripts/gameplay/juice_sort/view/juice_board_view.gd\"\n# 保留真实复活门控，只省略加绳动画。\nfunc add_rope() -> bool:\n\tif _over != \"\" or has_rope():\n\t\treturn false\n\t_state[\"extra_rope_used\"] = true\n\treturn true\n"







	assert (board_script.reload() == OK)
	var page_script: GDScript = GDScript.new()
	page_script.source_code = "extends \"res://scripts/main/pages/game/juice_game_page.gd\"\n# 记录资格门控之后是否真的进入效果、计账或广告，不触及真实服务。\nvar applied: int = 0\nvar charged: int = 0\nvar ad_requests: int = 0\nfunc _apply_prop(_key: String) -> bool:\n\tapplied += 1\n\treturn true\nfunc _charge_prop(_key: String, _btn: PropBtn) -> void:\n\tcharged += 1\nfunc _use_prop_via_ad(_key: String) -> void:\n\tad_requests += 1\nfunc _after_prop_applied(_key: String, _was_dead: bool = false) -> void:\n\tpass  #TODO: 隔离资格回归不执行演出／埋点／写盘收尾。\n"














	assert (page_script.reload() == OK)
	var state: Node = root.get_node("UserState")
	var ab: Node = root.get_node("ABManager")
	var safe_config: AbConfigBase = ab.find_config("sort_dead_return_to_safe_state")
	var previous_override: int = state.get_debug_ab_override(safe_config.key)
	var previous_level: int = state.get_current_level()
	var previous_coins: int = state.get_coins()
	var previous_count: int = state.get_prop_count("undo")
	var previous_free: bool = state.is_prop_free_available("undo")

	state.set_current_level(5)
	state.set_coins(10000)
	state.set_prop_count("undo", 1)
	state.grant_prop_free_use("undo")
	var board: JuiceBoardView = board_script.new()
	board.set("_level", JuiceLevel.new())
	var page: JuiceGamePage = page_script.new()
	page.set("_board", board)
	page.set("_playfield_ready", true)
	page.set("_ui_props_ready", true)
	var undo: PropBtn = load("res://scripts/widget/prop_btn/prop_btn.tscn").instantiate()
	undo.configure(PropBtn.PropType.UNDO)
	root.add_child(undo)
	page.set("_prop_ui", {"undo": {"btn": undo}})
	for return_to_safe: bool in [false, true]:
		safe_config.set_debug_override(1 if return_to_safe else 0)
		for attribution: int in [JuiceSolver.DeathAttribution.LAST_MOVE, 
				JuiceSolver.DeathAttribution.EARLIER, JuiceSolver.DeathAttribution.UNKNOWN]:
			board.set("_death_attribution", attribution)
			for has_history: bool in [false, true]:
				board.set("_history", [{}] if has_history else [])
				board.set("_over", "dead")

				var available: bool = has_history
				assert (page._prop_effect_available("undo") == available)
				undo.refresh(5, 0, available, true, 0, false)
				assert (undo.get_state() == (PropBtn.PropState.FREE if available else PropBtn.PropState.DISABLED))

				if has_history:
					for tier: int in [PropBtn.PropState.FREE, PropBtn.PropState.COUNT, 
							PropBtn.PropState.COIN, PropBtn.PropState.AD]:
						undo.refresh(5, 10000 if tier == PropBtn.PropState.COIN else 0, 
							available, tier == PropBtn.PropState.FREE, 
							1 if tier == PropBtn.PropState.COUNT else 0, tier == PropBtn.PropState.AD)
						assert (undo.get_business_state() == tier)
						page.set("applied", 0)
						page.set("charged", 0)
						page.set("ad_requests", 0)
						page._use_prop("undo")
						assert (int(page.get("applied")) == (1 if available and tier != PropBtn.PropState.AD else 0))
						assert (int(page.get("charged")) == int(page.get("applied")))
						assert (int(page.get("ad_requests")) == (1 if available and tier == PropBtn.PropState.AD else 0))

				board.set("_state", {"extra_rope_used": false})
				assert (board.revive_with_rope())
				assert (board.over() == "" and board.has_rope())
				assert (page._prop_effect_available("undo") == has_history)
				undo.refresh(5, 0, page._prop_effect_available("undo"), true, 0, false)
				assert (undo.get_state() == (PropBtn.PropState.FREE if has_history else PropBtn.PropState.DISABLED))
	board.set("_over", "dead")
	board.set("_history", [{}])
	board.set("_shift_queue", [{}] as Array[Dictionary])
	assert ( not page._prop_effect_available("undo"))
	board.set("_shift_queue", [] as Array[Dictionary])
	assert (page._prop_effect_available("undo"))
	state.set_current_level(previous_level)
	state.set_coins(previous_coins)
	state.set_prop_count("undo", previous_count)
	if not previous_free:
		state.consume_prop_free_use("undo")
	if previous_override >= 0:
		safe_config.set_debug_override(previous_override)
	else:
		safe_config.clear_debug_override()
	page.set("_prop_ui", {})
	page.set("_board", null)
	page.free()
	board.free()
	undo.free()



func _test_dead_recovery_recommendations(page_script: GDScript) -> void :
	var state: Node = root.get_node("UserState")
	var previous_level: int = state.get_current_level()
	state.set_current_level(5)
	var board_script: GDScript = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd")
	var board: JuiceBoardView = board_script.new()
	board.set("_over", "dead")
	var page: JuiceGamePage = page_script.new()
	page.set("_board", board)
	var prop_scene: PackedScene = load("res://scripts/widget/prop_btn/prop_btn.tscn")
	var undo_btn: PropBtn = prop_scene.instantiate()
	undo_btn.configure(PropBtn.PropType.UNDO)
	root.add_child(undo_btn)
	var rope_btn: PropBtn = prop_scene.instantiate()
	rope_btn.configure(PropBtn.PropType.ROPE)
	root.add_child(rope_btn)
	page.set("_prop_ui", {"undo": {"btn": undo_btn}, "rope": {"btn": rope_btn}})
	for attribution: int in [JuiceSolver.DeathAttribution.LAST_MOVE, 
			JuiceSolver.DeathAttribution.UNKNOWN, JuiceSolver.DeathAttribution.EARLIER]:
		board.set("_death_attribution", attribution)
		for has_history: bool in [false, true]:
			board.set("_history", [{}] if has_history else [])
			for has_rope: bool in [false, true]:
				board.set("_state", {"extra_rope_used": has_rope})
				page._sync_dead_prop_glows()
				var undo_recommended: bool = has_history and attribution == JuiceSolver.DeathAttribution.LAST_MOVE
				var rope_recommended: bool = not has_rope and attribution != JuiceSolver.DeathAttribution.LAST_MOVE
				assert (undo_btn.get_node("DeadGlow").visible == undo_recommended)
				assert (rope_btn.get_node("DeadGlow").visible == rope_recommended)
				assert ((undo_btn.get("_dead_shake_tween") != null) == undo_recommended)
				assert ((rope_btn.get("_dead_shake_tween") != null) == rope_recommended)
	page._sync_dead_prop_glows(false)
	assert ( not undo_btn.get_node("DeadGlow").visible and not rope_btn.get_node("DeadGlow").visible)
	state.set_current_level(1)
	state.clear_prop_unlock_shown()
	board.set("_death_attribution", JuiceSolver.DeathAttribution.UNKNOWN)
	board.set("_history", [{}])
	board.set("_state", {"extra_rope_used": false})
	page._sync_dead_prop_glows()
	assert ( not undo_btn.get_node("DeadGlow").visible and not rope_btn.get_node("DeadGlow").visible)
	assert ( not state.is_prop_early_unlocked("undo") and not state.is_prop_early_unlocked("rope"))
	state.set_current_level(previous_level)
	page.set("_prop_ui", {})
	page.set("_board", null)
	page.free()
	board.free()
	undo_btn.free()
	rope_btn.free()


func _test_reset_confirm() -> void :
	var dialog: ResetConfirmDialog = load("res://scripts/main/dialogs/reset_confirm/reset_confirm_dialog.tscn").instantiate()
	root.add_child(dialog)
	var state: Dictionary = {"calls": 0, "hidden_at_confirm": false}
	var callback: Callable = Callable(self, "_record_reset_confirm").bind(state, dialog)
	for streak: int in [0, 2, 3, 5]:
		dialog.show()
		await dialog._on_show({"done": 2, "total": 10, "streak": streak, "on_confirm": callback})
		assert (dialog._body.visible and dialog._restart_btn.visible and dialog._cancel_btn.visible)
		assert ( not dialog._card.has_node("NewLayout"))
		assert (dialog._card.custom_minimum_size == Vector2(1008.0, 1104.0))
		var copy_key: String = "JUICE_RESET_DIALOG_BODY_STREAK" if streak >= 3 else "JUICE_RESET_DIALOG_BODY"
		assert (dialog._body_key == StringName(copy_key))
		var expected_copy: String = tr(copy_key).format({"N": streak} if streak >= 3 else {"N": 2, "M": 10})
		assert (dialog._body.get_parsed_text() == expected_copy)
		assert (dialog._body.text.contains("[b][color=#6f320d]"))
		dialog._on_cancel_pressed()
		await _wait_reset_hidden(dialog)
		assert (state["calls"] == 0)

	for use_close_button: bool in [true, false]:
		dialog.show()
		await dialog._on_show({"on_confirm": callback})
		if use_close_button:
			dialog._close_btn.pressed.emit()
		else:
			dialog._on_back_request()
		await _wait_reset_hidden(dialog)
		assert (state["calls"] == 0)
	dialog.show()
	await dialog._on_show({"on_confirm": callback})
	await dialog._on_restart_pressed()
	assert (state["calls"] == 1 and state["hidden_at_confirm"] and not dialog.visible)
	dialog._on_restart_pressed()
	assert (state["calls"] == 1)
	dialog.free()


func _wait_reset_hidden(dialog: ResetConfirmDialog) -> void :
	var deadline: int = Time.get_ticks_msec() + 2000
	while dialog.visible and Time.get_ticks_msec() < deadline:
		await process_frame
	assert ( not dialog.visible)


func _record_reset_confirm(state: Dictionary, dialog: ResetConfirmDialog) -> void :
	state["calls"] += 1
	state["hidden_at_confirm"] = not dialog.visible
