extends SceneTree




var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var scene: PackedScene = load("res://scripts/gameplay/juice_sort/view/juice_quota_bar.tscn") as PackedScene
	var bar: JuiceQuotaBar = scene.instantiate() as JuiceQuotaBar
	root.add_child(bar)
	bar.width_changed.connect( func() -> void :
		bar.size = Vector2(bar.desired_width(), bar.desired_height()))
	_check(is_equal_approx(JuiceQuotaBar.ROW_H, 108.0 * 1.18 * 1.3 * 0.9 * 0.9)
		and is_equal_approx(JuiceQuotaBar.ROW_Y + JuiceQuotaBar.ROW_H, 
			70.0 + 108.0 * 1.18 * 1.3 - JuiceQuotaBar.ROW_LIFT), "满盆和空盆再缩小 10% 并整排上提")
	_check(JuiceQuotaBar.COUNT_FONT_SIZE == 56
		and is_equal_approx(JuiceQuotaBar.COUNT_Y, JuiceQuotaBar.TAB_Y + 2.0)
		and bar._count.get_theme_font_size("font_size") == 56
		and is_equal_approx(bar._count.position.y, JuiceQuotaBar.COUNT_Y)
		and JuiceQuotaBar.COUNT_SIZE.x < JuiceQuotaBar.TAB_W
		and JuiceQuotaBar.COUNT_Y + JuiceQuotaBar.COUNT_SIZE.y < JuiceQuotaBar.TAB_Y + JuiceQuotaBar.TAB_H
		and is_equal_approx(JuiceQuotaBar.TAB_Y + JuiceQuotaBar.TAB_H, 
			JuiceQuotaBar.PANEL_Y + JuiceQuotaBar.PANEL_BORDER), 
		"计数文字框保持在页签内")
	bar.setup(3)
	_check(is_equal_approx(bar.size.x, 452.0) and not bar._scrollable(), "3 格窄栏不滚动")
	_check(bar._is_slot_fully_visible(0) and bar._is_slot_fully_visible(2), "3 格全部可见")
	_check(is_equal_approx(bar._slot_pitch(), 118.0)
		and is_equal_approx(bar._content_x(), 54.0), 
		"3 格两端各留 54px，间距收至 118px")
	var filled: Texture2D = load("res://assets/sprites/juice_sort/bonsai_yellow.png") as Texture2D
	var collector: Texture2D = load("res://assets/sprites/juice_sort/sunlight_collector_body.png") as Texture2D
	bar.set_sunlight_textures(collector, null)
	_check_collector_rects(bar, filled, "original玻璃瓶底边")
	_check(filled != null and bar._cup_rect(filled, 0).is_equal_approx(bar._slot_rect(0)), 
		"满盆和空盆使用相同尺寸与盆底落位")
	var clip: Rect2 = bar._slot_clip_rect()
	_check(bar._board.z_index > bar.z_index and not bar.has_node("PopOverlay")
		and is_equal_approx(JuiceQuotaBar.BOARD_Y, 204.0)
		and is_equal_approx(bar._board.position.y, JuiceQuotaBar.BOARD_Y), 
		"回弹与静态花盆同层，托板始终在前景")
	_check(is_equal_approx(clip.position.x, 15.0)
		and is_equal_approx(clip.end.x, bar.size.x - 15.0)
		and is_equal_approx(clip.position.y, JuiceQuotaBar.PANEL_Y)
		and is_equal_approx(clip.end.y, JuiceQuotaBar.BOARD_Y), 
		"花盆裁剪在白卡左右边框内侧、上沿和托板顶部")
	bar._start_pop(0)
	var enlarged: Rect2 = bar._scaled_about_center(bar._slot_rect(0), JuiceQuotaBar.POP_SCALE)
	var visible: Rect2 = enlarged.intersection(Rect2(clip.position.x, 0.0, clip.size.x, clip.end.y))
	_check(bar._pops.has(0) and enlarged.position.y > 0.0
		and enlarged.end.y > clip.end.y
		and is_equal_approx(visible.position.y, enlarged.position.y)
		and is_equal_approx(visible.end.y, JuiceQuotaBar.BOARD_Y), 
		"缩小后回弹顶部完整显示，底部仍被托板遮住")
	bar._kill_pop(0)
	_check( not bar._pops.has(0), "回弹结束后清理动画状态")
	bar.setup(7)
	_check(is_equal_approx(bar.size.x, 852.0) and is_equal_approx(bar._slot_pitch(), 116.0), 
		"7 格两侧各留 24px 并保持格位均匀")
	bar.setup(10)
	_check(is_equal_approx(bar.size.x, 1056.0) and not bar._scrollable(), "10 格满宽不滚动")
	_check(bar._is_slot_fully_visible(0) and bar._is_slot_fully_visible(9), "10 格全部可见")
	_check(is_equal_approx(bar._slot_pitch(), 100.0)
		and is_equal_approx(bar._view_rect().position.x, 24.0)
		and is_equal_approx(bar._view_rect().end.x, bar.size.x - 24.0), 
		"10 格首尾各距白卡边缘 24px")
	bar.setup(11)
	_check(is_equal_approx(bar.size.x, 1056.0) and bar._scrollable(), "11 格保持 10 格宽并滚动")
	_check(bar._is_slot_fully_visible(9) and not bar._is_slot_fully_visible(10), 
		"第 11 格初始不露出")

	var target: float = bar._revealed_scroll(10)
	_check(target < 0.0, "末格可被向左滚动带入窗口")
	_check(bar.tab_style != null and bar.panel_style != null
		and bar.get_node("ProgressPotBoard") is NinePatchRect, "三层九宫格资源已绑定")


	bar.setup(7)
	var before_x4: float = bar._slot_rect(4).position.x
	bar._hidden_completed_slots.append(3)
	bar._hidden_collapse[3] = 1.0
	bar._rebuild_slot_offsets()
	_check(is_equal_approx(bar._slot_rect(3).position.x, bar._slot_rect(4).position.x), 
		"完全收起的隐藏格与后一格重合，不占位")
	_check(bar._slot_rect(4).position.x < before_x4, "隐藏格之后的格子前移补位")
	_check(bar._is_slot_fully_visible(6), "收掉一格后整排仍在窗口内")


	bar.setup(7)
	var texs: Array[Texture2D] = []
	var tints: = PackedColorArray()
	for i: int in 7:
		texs.append(filled)
		tints.append(Color.WHITE)
	var hidden: Array[int] = [2]
	bar.set_cups(texs, tints, hidden)
	_check(is_equal_approx(bar._visible_weight(), 6.0), "重建时隐藏格直接收起")
	_check(is_equal_approx(bar._slot_rect(2).position.x, bar._slot_rect(3).position.x), 
		"重建后隐藏格仍不占位")


	bar.setup(7)
	bar.push_cup(filled, Color.WHITE, true)
	_check(bar._hidden_completed_slots.has(0) and is_equal_approx(float(bar._hidden_collapse.get(0, -1.0)), 0.0)
		and is_equal_approx(bar._visible_weight(), 7.0), "金猪杯点亮后从整格开始压缩")
	bar._kill_hidden_collapse(0)
	bar._set_hidden_collapse(1.0, 0)
	_check(is_equal_approx(bar._visible_weight(), 6.0), "压缩完成后少占一格")
	_check(is_equal_approx(bar._slot_rect(0).position.x, bar._slot_rect(1).position.x), 
		"压缩完成后隐藏格与后一格重合")


	bar.setup(10)
	bar.position = Vector2(12.0, 248.0)
	bar.pivot_offset = Vector2(bar.size.x * 0.5, JuiceQuotaBar.PANEL_Y + JuiceQuotaBar.PANEL_H * 0.5)
	bar.scale = Vector2.ONE * 0.95
	_check_global_rects(bar, filled, "95%缩放")
	_check(bar.cell_global_rect(9).get_center().is_equal_approx(
		Vector2(967.5, 248.0 + bar.pivot_offset.y
			+ (JuiceQuotaBar.ROW_Y + JuiceQuotaBar.ROW_H * 0.5 - bar.pivot_offset.y) * 0.95)), 
		"第10格落点不再偏右48.9px")
	bar.play_progress_impact()
	for phase: float in [JuiceQuotaBar.PROGRESS_IMPACT_DIP, JuiceQuotaBar.PROGRESS_IMPACT_REBOUND]:
		bar._set_progress_impact(phase)
		_check_global_rects(bar, filled, "整板回弹 phase=%s" % phase)
	bar.stop_progress_impact()
	_check_global_rects(bar, filled, "回弹复位")
	bar.setup(12)
	bar._set_scroll(bar._revealed_scroll(11))
	_check_global_rects(bar, filled, "缩放后滚动到末格")
	var parent: = Control.new()
	parent.position = Vector2(31.0, 47.0)
	parent.scale = Vector2(1.1, 0.9)
	root.add_child(parent)
	bar.reparent(parent, false)
	_check_global_rects(bar, filled, "父节点平移与缩放")
	var bottle: JuiceBlender = load("res://scripts/gameplay/juice_sort/view/juice_blender.tscn").instantiate() as JuiceBlender
	root.add_child(bottle)
	bottle.set_target(collector, collector, 0)
	var destination: Rect2 = bar.cup_global_rect(0, collector)
	bottle.sample_sunlight_flight(Rect2(100.0, 400.0, 180.0, 184.0), destination, 1.0)
	var body: Sprite2D = bottle.get_node("Body") as Sprite2D
	var flight_bottom: Vector2 = body.global_transform * Vector2(0.0, \
	JuiceBlender.COLLECTOR_BODY_CONTENT.end.y - body.texture.get_height() * 0.5)
	var landed_rect: Rect2 = bar._cup_rect(collector, 0)
	var landed_bottom: Vector2 = bar.get_global_transform() * Vector2(landed_rect.get_center().x, \
	landed_rect.position.y + landed_rect.size.y * 163.0 / 198.0)
	_check(is_equal_approx(flight_bottom.y, landed_bottom.y), "玻璃瓶飞行终点与入栏可见底边一致")
	bottle.queue_free()
	bar.reparent(root, false)
	parent.queue_free()
	_check_skin_capacity(bar, filled)

	bar.queue_free()
	if _failures.is_empty():
		print("PASS juice quota bar")
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
	quit(0 if _failures.is_empty() else 1)


func _check_skin_capacity(bar: JuiceQuotaBar, filled: Texture2D) -> void :
	var base: JuiceSkinDefinition = load("res://scripts/gameplay/juice_sort/view/skin/default.tres")
	var selected: JuiceSkinDefinition = JuiceSkinDefinition.new()
	selected.id = &"quota_capacity_test"
	var resources: JuiceSkinResolver = JuiceSkinResolver.new(base, selected)
	bar.scale = Vector2.ONE
	for capacity: int in [10, 8, 12, 1]:
		selected.target_bar_max_visible_count = capacity
		bar.apply_skin(resources)
		bar.setup(capacity)
		var full_size: Vector2 = bar._slot_rect(0).size
		_check(is_equal_approx(bar.size.x, JuiceQuotaBar.MAX_W), "配置%d时满屏保持最大栏宽" % capacity)
		_check(is_equal_approx(bar.size.y, JuiceQuotaBar.HEIGHT), "一屏数量不改变普通目标栏高度")
		_check(is_equal_approx(bar._slot_rect(0).end.y, JuiceQuotaBar.ROW_BOTTOM), "放大与缩小元素均保持原格位底边")
		_check(is_equal_approx(bar.layout_pivot().y, JuiceQuotaBar.PANEL_Y + JuiceQuotaBar.PANEL_H * 0.5), "一屏数量不改变白卡回弹支点")
		_check(is_equal_approx(bar._content_w(), bar._view_rect().size.x), "配置%d时均分整个窗口" % capacity)
		_check(is_equal_approx(full_size.x / full_size.y, float(bar.slot_empty_texture.get_width()) / bar.slot_empty_texture.get_height()), "目标元素保持原图比例")
		_check(full_size.y > JuiceQuotaBar.ROW_H if capacity < 10 else full_size.y <= JuiceQuotaBar.ROW_H, "尺寸按一屏数量定标")
		for total: int in [3, 4, capacity, capacity + 1, 12]:
			bar.setup(total)
			_check(bar._slot_rect(0).size.is_equal_approx(full_size), "配置%d、目标%d时元素大小与满屏相同" % [capacity, total])
			var visible: int = 0
			for i: int in total:
				if bar.is_cup_fully_visible(i):
					visible += 1
			_check(visible == mini(total, capacity), "一屏完整展示数量符合配置%d" % capacity)
			_check(bar._scrollable() == (total > capacity), "超过一屏数量才滚动")
			if total > capacity:
				bar._set_scroll(bar._revealed_scroll(total - 1))
				_check(bar.is_cup_fully_visible(total - 1), "超量末格可滑入窗口")
				_check_global_rects(bar, filled, "皮肤配置%d、目标%d" % [capacity, total])
		bar.setup(capacity + 2)
		bar._reveal(capacity + 1)
		bar.set_iq_layout_enabled(true)
		_check(is_equal_approx(bar.size.y, JuiceQuotaBar.IQ_HEIGHT), "一屏数量不改变IQ目标栏高度")
		_check(is_equal_approx(bar._board.position.y, JuiceQuotaBar.BOARD_Y), "放大元素不下移托板")
		_check(is_equal_approx(bar._bottom_count_tab.position.y, JuiceQuotaBar.BOARD_Y + 24.0), "放大元素不下移IQ底部计数页签")
		var count_y: float = bar._count.position.y
		var board_y: float = bar._board.position.y
		_check(is_equal_approx(bar._slot_clip_rect().end.y, bar._board.position.y), "裁剪下沿跟随真实托板")
		_check(is_equal_approx(bar._count.position.y, count_y), "放大后仍保持计数位置")
		_check(is_equal_approx(bar._board.position.y, board_y), "放大后保持原托板位置")
		bar.set_iq_layout_enabled(false)
		bar.set_rules_layout_enabled(true)
		_check(bar.size.is_equal_approx(JuiceRulesBar.DESIGN_SIZE) and not bar._scrollable(), "规则计数栏保持独立布局")
		bar.set_rules_layout_enabled(false)
		_check(bar._slot_rect(0).size.is_equal_approx(full_size), "关闭规则栏恢复皮肤尺寸")
		bar.setup_endless()
		_check(bar._total == mini(capacity, JuiceQuotaBar.ENDLESS_HISTORY_LIMIT) + JuiceQuotaBar.AUTO_PREVIEW_UNFINISHED_COUNT, "无尽初始窗口按皮肤数量预留")
		bar.reserve_endless_slot(100)
		_check(bar._total <= JuiceQuotaBar.ENDLESS_HISTORY_LIMIT + JuiceQuotaBar.AUTO_PREVIEW_UNFINISHED_COUNT, "无尽历史与未来格位保持有界")

	selected.target_bar_max_visible_count = 8
	bar.apply_skin(resources)
	bar.setup(12)
	bar.push_cup(filled, Color.WHITE)
	bar._reveal(11)
	bar.reveal_slot(0)
	bar._dragging = true
	selected.target_bar_max_visible_count = 0
	bar.apply_skin(resources)
	_check(bar._max_visible_count == 10 and bar.filled_count() == 1 and bar._total == 12, "换肤回退默认并保留真实收集进度")
	_check(bar._scroll_tween == null and not bar._dragging, "换肤取消旧滑动和拖动状态")
	_check(bar._scroll >= bar._view_rect().size.x - bar._content_w() and bar._scroll <= 0.0, "换肤后滚动量位于新窗口范围内")
	bar.setup(3)
	_check( not bar._scrollable() and is_zero_approx(bar._scroll), "重开少目标关复位滚动")


func _check(ok: bool, description: String) -> void :
	if not ok:
		_failures.append(description)


func _check_global_rects(bar: JuiceQuotaBar, filled: Texture2D, description: String) -> void :
	for i: int in range(bar._total):
		var local_rect: Rect2 = bar._slot_rect(i)
		var transform: Transform2D = bar.get_global_transform()
		var expected: = Rect2(transform * local_rect.position, Vector2.ZERO)
		for corner: Vector2 in [Vector2(local_rect.end.x, local_rect.position.y), 
				local_rect.end, Vector2(local_rect.position.x, local_rect.end.y)]:
			expected = expected.expand(transform * corner)
		_check(bar.cup_global_rect(i, filled).is_equal_approx(expected), 
			"%s：满盆第%d格的全局矩形与绘制一致" % [description, i])
		_check(bar.cell_global_rect(i).is_equal_approx(expected), 
			"%s：第%d格的全局矩形与绘制一致" % [description, i])
	_check_collector_rects(bar, filled, description)


func _check_collector_rects(bar: JuiceQuotaBar, filled: Texture2D, description: String) -> void :
	for slot: int in bar._total:
		var pot_rect: Rect2 = bar._cup_rect(filled, slot)
		var collector_rect: Rect2 = bar._cup_rect(bar._sunlight_collector_texture, slot)
		var pot_bottom: float = pot_rect.position.y + pot_rect.size.y * 250.0 / 261.0
		var collector_bottom: float = collector_rect.position.y + collector_rect.size.y * 163.0 / 198.0
		_check(is_equal_approx(pot_bottom, collector_bottom), "%s：第%d格玻璃瓶与花盆可见底边对齐" % [description, slot])
		_check(collector_rect.size.is_equal_approx(pot_rect.size)\
		and is_equal_approx(collector_rect.get_center().x, pot_rect.get_center().x), \
		"%s：玻璃瓶大小及横向中心不变" % description)
		_check(bar.cup_global_rect(slot, bar._sunlight_collector_texture).is_equal_approx(\
		bar.get_global_transform() * collector_rect), "%s：飞行目标与静态瓶矩形共用" % description)
