class_name UserLevelHud
extends CanvasLayer













@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel / Label
@onready var _timer: Timer = $RefreshTimer


var _enabled: bool = false


func _ready() -> void :
	layer = SceneManager.Layer.DIALOG - 1
	visible = false



func is_enabled() -> bool:
	return _enabled



func set_enabled(on: bool) -> void :
	_enabled = on
	if on:
		_timer.start()
		_refresh()
	else:
		_timer.stop()
		visible = false


func _on_refresh_timer_timeout() -> void :
	_refresh()



func _refresh() -> void :
	var game_page: CanvasItem = SceneManager.get_page("game") as CanvasItem
	visible = game_page != null and game_page.visible
	if not visible:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	var bottom_inset: float = UiMetrics.safe_insets().y
	var lines: Array[String] = _build_lines()

	var margin: Vector2 = _panel.get_theme_stylebox("panel").get_minimum_size()
	var avail_h: float = vp.y - bottom_inset - _prop_bar_bottom(game_page)
	var wrapped_h: float = _measure_wrapped_height("\n".join(lines), vp.x - margin.x) + margin.y
	var compact: bool = wrapped_h > avail_h
	_apply_wrap_mode(compact)
	var text: String = "。".join(lines) if compact else "\n".join(lines)
	if text != _label.text:
		_label.text = text


	_panel.offset_top = - bottom_inset
	_panel.offset_bottom = - bottom_inset




func _prop_bar_bottom(game_page: Node) -> float:
	var bottom: float = 0.0
	for child: Node in game_page.get_children():
		var btn: PropBtn = child as PropBtn
		if btn != null and btn.visible:
			bottom = maxf(bottom, btn.get_global_rect().end.y)
	return bottom



func _measure_wrapped_height(text: String, width: float) -> float:
	var font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	return font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y



func _apply_wrap_mode(compact: bool) -> void :
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF if compact else TextServer.AUTOWRAP_WORD_SMART
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if compact\
	else TextServer.OVERRUN_NO_TRIMMING

	_label.clip_text = compact



func _build_lines() -> Array[String]:
	var lv: int = UserState.get_user_level()
	var dirty_now: bool = UserState.is_current_level_dirty()
	var cur_level_num: int = UserState.get_current_level()
	var lines: Array[String] = []
	if lv <= 0:
		lines.append("难度档:未起步(第 %d 关)" % cur_level_num)
		lines.append("第 %d 关通关后起步 %s" % [UserLevelLadder.START_AT_LEVEL_NUM, 
			UserLevelLadder.tag_value(UserLevelLadder.START_LEVEL)])
		return lines
	var n: int = UserLevelLadder.n_of(lv)
	var streak: int = UserState.get_user_level_clean_streak()
	var window: Array = UserState.get_user_level_recent_dirty()
	lines.append("难度档 %s(n=%d),连胜 %d 局,最近 %d 局失败 %d 局" % [
		UserLevelLadder.tag_value(lv), n, streak, n, UserLevelLadder.dirty_count(window, n)])
	lines.append("本局(第 %d 关)目前:%s(死亡 / 重开 / 用道具都算失败)" % [
		cur_level_num, "已失败" if dirty_now else "未失败"])
	lines.append(_forecast(lv, streak, window, dirty_now, false))
	lines.append(_forecast(lv, streak, window, dirty_now, true))
	return lines



func _forecast(lv: int, streak: int, window: Array, dirty_now: bool, all_dirty: bool) -> String:
	if not all_dirty and lv >= UserLevelLadder.LEVEL_MAX:
		return "升级:已封顶 %s" % UserLevelLadder.tag_value(lv)
	if all_dirty and lv <= UserLevelLadder.LEVEL_MIN:
		return "降级:已封底 %s" % UserLevelLadder.tag_value(lv)

	var eligible: bool = lv >= 3 or UserState.has_reached_user_level_3()
	var easy_promotion: bool = eligible and ABManager.difficulty_rule.should_use_easy_promotion()
	var four_losses: bool = eligible and ABManager.difficulty_rule.should_require_four_losses(lv)
	var state: Dictionary = {"level": lv, "clean_streak": streak, "recent_dirty": window}
	for k: int in range(1, UserLevelLadder.WINDOW_CAP * 2 + 1):
		var dirty: bool = all_dirty or (k == 1 and dirty_now)
		state = UserLevelLadder.settle(int(state["level"]), int(state["clean_streak"]), 
			state["recent_dirty"] as Array, dirty, easy_promotion, four_losses)
		var new_lv: int = int(state["level"])
		if new_lv == lv:
			continue
		var to: String = UserLevelLadder.tag_value(new_lv)
		if all_dirty:
			return "再失败 %d 局(含本局)降级 %s" % [k, to]
		if new_lv < lv:

			return "本局已失败,通关即降级 %s" % to
		if dirty_now:
			return "本局已失败连胜清零,之后再连胜 %d 局升级 %s" % [k - 1, to]
		return "再连胜 %d 局(含本局)升级 %s" % [k, to]
	return "推演 %d 局内不变档" % (UserLevelLadder.WINDOW_CAP * 2)
