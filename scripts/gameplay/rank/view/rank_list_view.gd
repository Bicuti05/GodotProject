class_name RankListView
extends Control

const ListLayout = preload("res://scripts/gameplay/rank/view/rank_list_layout.gd")
const FinishMotion = preload("res://scripts/gameplay/rank/view/motion/rank_finish_motion.gd")

const RISE_TWEEN_SEC: float = 0.45

const CLIP_SLACK: float = 48.0
const ROW_X: float = CLIP_SLACK

signal gift_tapped(rank_pos: int, global_rect: Rect2)
var animation_generation: int = 0
var _animation_tweens: Array[Tween] = []

@export var podium: RankFinishPodium = null
@export var overlay_scene: PackedScene = null
@export var collect_icon_fade_material: ShaderMaterial = null

@export var item_scene: PackedScene = null
@export var zone_banner_scene: PackedScene = null
@export var element_pool_scene: PackedScene = null
@export var top_safe_padding: float = 0.0
@export var bottom_safe_padding: float = 0.0

@onready var _scroll: ScrollContainer = $Scroll
@onready var _content: Control = $Scroll / Content
@onready var _pool: RankAvatarPool = $AvatarPool
@export var collect_source_scene: PackedScene = null
@export var land_burst_scene: PackedScene = null
var _collect_source_fx: RankSourceCollectionFx

var _element_pool: RankCollectElementPool = null
const PREPARE_FRAME_BUDGET_USEC: int = 2000
const MAX_BINDINGS_PER_FRAME: int = 6
const BUFFER_ROWS: int = 3
const ANIMATION_SLACK_ROWS: int = 2

var _layout: ListLayout = ListLayout.new()
var _snapshot: RankSnapshot
var _ready_entries: Dictionary = {}
var _bound_rows: Dictionary = {}
var _bound_locales: Dictionary = {}
var _preparation_generation: int = 0
var _first_screen_prepared: bool = false
var _pool_capacity: int = 0
var _window: Array[int] = []
var _window_dirty: bool = true
var _player_hidden: bool = false
var _refresh_pending: bool = false
var _setting_scroll: bool = false
var _scroll_samples: PackedInt32Array = []
var _frame_samples: PackedInt32Array = []
var _committed_scroll: float = 0.0
var _target_scroll: float = 0.0
var _staged_scroll: float = 0.0
var _staged_nodes: Dictionary = {}
var _staged_queue: Array[int] = []
var _staged_window: Array[int] = []
var _stage_active: bool = false
var _scroll_restore_queued: bool = false
var _last_scroll_batch_frame: int = -1
var _resizing_pool: bool = false
var _drag_enabled: bool = true
var _scroll_sample_index: int = 0
var preparation_stats: Dictionary = {"created": 0, "bound": 0, "max_batch_usec": 0, 
	"scroll_updates": 0, "scroll_created": 0, "pool_capacity": 0}

var _overlay_item: RankItemView
var _land_burst: RankRowLandBurstFx
var _top3_row_state: Dictionary = {}
var _items: Array[RankItemView] = []
var _banners: Array[RankZoneBanner] = []
var _fourth_fill_item: RankItemView
var _fourth_fill_preview: RankItemView
var _fourth_fill_y: float = 0.0
var _row_nodes: Array[Control] = []
var _row_base_y: Array[float] = []
var _row_rank: Array[int] = []
var _shift_active: bool = false
var _shift_to: Dictionary = {}
var _shift_from: Dictionary = {}
var _shift_delay: Dictionary = {}
var _shift_t: float = 0.0
var _drag_helper: ScrollDragHelper = null
var _scroll_mouse_filter_rest: int = Control.MOUSE_FILTER_STOP


func _ready() -> void :
	_drag_helper = ScrollDragHelper.attach(_scroll)
	_scroll_mouse_filter_rest = _scroll.mouse_filter
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	_scroll.resized.connect(_on_scroll_resized)
	set_process(false)


func attach_podium(value: RankFinishPodium) -> void :
	podium = value
	if not podium.gift_tapped.is_connected(_on_podium_gift_tapped):
		podium.gift_tapped.connect(_on_podium_gift_tapped)


func _on_podium_gift_tapped(rank_pos: int, global_rect: Rect2) -> void :
	gift_tapped.emit(rank_pos, global_rect)


func set_snapshot(snap: RankSnapshot, _instant: bool = false, refresh: bool = true) -> void :
	cancel_preparation()
	_snapshot = snap
	var previous_by_key: Dictionary = {}
	for item: RankItemView in _items:
		previous_by_key[item.get_row_key()] = item
		item.hide()
	for banner: RankZoneBanner in _banners:
		banner.hide()
	_layout.build(snap, podium != null, top_safe_padding, bottom_safe_padding)
	_row_nodes.clear()
	_row_nodes.resize(_layout.entries.size())
	_row_base_y.clear()
	_row_rank.clear()
	_ready_entries.clear()
	for entry: Dictionary in _layout.entries:
		_row_base_y.append(float(entry.y))
		_row_rank.append(int(entry.rank))

	var me_index: int = int(_layout.key_indices.get("me", -1))
	if me_index >= 0 and previous_by_key.has("me"):
		_row_nodes[me_index] = previous_by_key.me
	_content.custom_minimum_size = Vector2(size.x, _layout.content_height)
	_window.clear()
	if snap != null and snap.is_valid() and _ensure_element_pool():
		if podium != null:
			podium.bind_snapshot(snap, _pool, _element_pool.get_texture())
			if _collect_source_fx != null:
				_collect_source_fx.retarget_receiver(podium.find_item("me"))
		if _pool_capacity > 0 and refresh:
			_refresh_window()
			_first_screen_prepared = true
	elif podium != null:
		podium.hide()


func update_player_profile(nickname: String, avatar_index: int) -> void :
	var index: int = int(_layout.key_indices.get("me", -1))
	if index < 0:
		SortLogger.error("RankListView: profile update requires a player list row")
		return
	var entry: Dictionary = _layout.entries[index]

	var row: Dictionary = entry.row
	if String(row.get("nickname", "")) == nickname and int(row.get("avatar_index", -1)) == avatar_index:
		return
	row.nickname = nickname
	row.avatar_index = avatar_index
	var item: RankItemView = _row_nodes[index] as RankItemView
	if item == null:
		return

	item.bind(row, _avatar_for(avatar_index), _element_pool.get_texture())
	item.prepare_text()
	_bound_rows[item] = entry.duplicate(true)
	_bound_locales[item] = TranslationServer.get_locale()
	preparation_stats.bound += 1


func _view_height() -> float:
	return maxf(_scroll.size.y, 1.0)


func _entry_y(index: int) -> float:
	if not _top3_row_state.is_empty():
		var rank: int = _row_rank[index]
		var old_rank: int = int(_top3_row_state.get("old_rank", 0))
		if rank >= 4 and rank < old_rank:
			var order: int = old_rank - 1 - rank
			var progress: float = clampf(float(_top3_row_state.get("rise", 0.0)) * (old_rank - 3) - order, 0.0, 1.0)
			return _row_base_y[index] + RankItemView.ROW_PITCH * progress
	if not _shift_active or not _shift_to.has(index):
		return _row_base_y[index]
	var progress: float = _shift_t
	if _shift_delay.has(index):
		var delay: float = float(_shift_delay[index])
		progress = _ease_out_back(clampf((_shift_t - delay) / maxf(0.01, 1.0 - delay), 0.0, 1.0), 1.15)
	return lerpf(float(_shift_from[index]), float(_shift_to[index]), progress)


func _wanted_window(scroll: float = -1.0) -> Array[int]:
	if scroll < 0.0:
		scroll = get_scroll_vertical()
	var wanted: Array[int] = []
	var padding: float = BUFFER_ROWS * RankItemView.ROW_PITCH
	var candidates: Vector2i = _layout.range_for_scroll(scroll, _view_height(), 
		BUFFER_ROWS + ANIMATION_SLACK_ROWS if _shift_active or not _top3_row_state.is_empty() else BUFFER_ROWS)
	if candidates.x < 0:
		return wanted
	for index: int in range(candidates.x, candidates.y + 1):
		var entry: Dictionary = _layout.entries[index]
		var y: float = _entry_y(index)
		if y + float(entry.height) >= scroll - padding and y <= scroll + _view_height() + padding:
			wanted.append(index)
	return wanted


func _bind_entry(index: int) -> void :
	_bind_node(index, _row_nodes[index])
	_ready_entries[index] = true


func _bind_node(index: int, node: Control, reveal: bool = true) -> void :
	var entry: Dictionary = _layout.entries[index]
	var unchanged: bool = _bound_rows.get(node, {}) == entry\
	and _bound_locales.get(node, "") == TranslationServer.get_locale()
	if node is RankItemView:

		unchanged = unchanged and node.get_row_key() == entry.key\
		and node.get_collect_num_display() == int(entry.row.get("collect_num", 0))\
		and node._collect_icon.texture == _element_pool.get_texture()
	if not unchanged:
		if node is RankItemView:
			var item: RankItemView = node as RankItemView
			if item.get_row_key() != entry.key:
				item.reset_for_reuse()
			item.bind(entry.row, _avatar_for(int(entry.row.get("avatar_index", 0))), _element_pool.get_texture())
			item.prepare_text()
		else:
			(node as RankZoneBanner).setup(entry.kind, int(entry.from_rank), int(entry.to_rank))
		_bound_rows[node] = entry.duplicate(true)
		_bound_locales[node] = TranslationServer.get_locale()
		preparation_stats.bound += 1
	node.position = Vector2(ROW_X, _entry_y(index))
	node.visible = reveal and not (_player_hidden and entry.key == "me")
	node.process_mode = Node.PROCESS_MODE_INHERIT if reveal else Node.PROCESS_MODE_DISABLED


func _refresh_window() -> void :
	if _snapshot == null or _items.is_empty():
		return
	_clear_scroll_stage()
	var started: int = Time.get_ticks_usec()
	var wanted: Array[int] = _wanted_window()
	if wanted == _window and not _window_dirty and not _shift_active and _top3_row_state.is_empty():
		_committed_scroll = get_scroll_vertical()
		_target_scroll = _committed_scroll
		_refresh_pending = false
		return
	var me_index: int = int(_layout.key_indices.get("me", -1))
	var retained: Dictionary = {}
	for index: int in _row_nodes.size():
		var node: Control = _row_nodes[index]
		if node == null:
			continue
		if wanted.has(index) or index == me_index:
			retained[node] = true
		else:
			node.hide()
			node.process_mode = Node.PROCESS_MODE_DISABLED
			_row_nodes[index] = null
			_ready_entries.erase(index)
	if me_index >= 0 and _row_nodes[me_index] != null:
		retained[_row_nodes[me_index]] = true
	var free_items: Array[RankItemView] = []
	var free_banners: Array[RankZoneBanner] = []
	for item: RankItemView in _items:
		if not retained.has(item):
			free_items.append(item)
	for banner: RankZoneBanner in _banners:
		if not retained.has(banner):
			free_banners.append(banner)
	var bindings: Array[int] = wanted.duplicate()
	if me_index >= 0 and not bindings.has(me_index):
		bindings.append(me_index)
	for index: int in bindings:
		if _row_nodes[index] == null:
			if _row_rank[index] > 0:
				if free_items.is_empty():
					SortLogger.error("RankListView: virtual row pool exhausted")
					return
				_row_nodes[index] = free_items.pop_back()
			else:
				if free_banners.is_empty():
					SortLogger.error("RankListView: virtual banner pool exhausted")
					return
				_row_nodes[index] = free_banners.pop_back()
		if not _ready_entries.has(index) or _window_dirty:
			_bind_entry(index)
		elif _shift_active or not _top3_row_state.is_empty():
			_row_nodes[index].position.y = _entry_y(index)
	_window = wanted
	_window_dirty = false
	_refresh_pending = false
	_committed_scroll = get_scroll_vertical()
	_target_scroll = _committed_scroll
	if _collect_source_fx != null:
		_collect_source_fx.retarget_receiver(find_my_item())
	_record_scroll_batch(Time.get_ticks_usec() - started)


func _record_scroll_batch(elapsed: int) -> void :
	preparation_stats.scroll_updates += 1
	preparation_stats.max_batch_usec = maxi(preparation_stats.max_batch_usec, elapsed)
	if _scroll_samples.size() < 1800:
		_scroll_samples.append(elapsed)
	else:
		_scroll_samples[_scroll_sample_index] = elapsed
		_scroll_sample_index = (_scroll_sample_index + 1) % 1800


func prepare_first_screen(snap: RankSnapshot, focus_rank: int, active: Callable) -> bool:
	if not active.call():
		return false
	var started: int = Time.get_ticks_usec()
	set_snapshot(snap, true, false)
	var generation: int = _preparation_generation
	while _resizing_pool:
		await get_tree().process_frame
		if generation != _preparation_generation or not active.call():
			return false
	await get_tree().process_frame
	if generation != _preparation_generation or not active.call() or snap == null or not snap.is_valid():
		return false
	_sync_scroll_layout()
	_pool_capacity = maxi(_items.size(), _required_capacity())
	preparation_stats.pool_capacity = _pool_capacity
	var batch_started: int = Time.get_ticks_usec()
	while _items.size() < _pool_capacity or _banners.size() < 2:
		if _items.size() < _pool_capacity:
			_ensure_item(_items.size()).hide()
		else:
			_ensure_banner(_banners.size()).hide()
		preparation_stats.created += 1
		var elapsed: int = Time.get_ticks_usec() - batch_started
		preparation_stats.max_batch_usec = maxi(preparation_stats.max_batch_usec, elapsed)
		if elapsed >= PREPARE_FRAME_BUDGET_USEC:
			await get_tree().process_frame
			if generation != _preparation_generation or not active.call():
				return false
			batch_started = Time.get_ticks_usec()
	_target_scroll = _layout.scroll_for_rank(focus_rank, _view_height(), podium == null)
	_window_dirty = true
	while not _advance_scroll_window():
		await get_tree().process_frame
		if generation != _preparation_generation or not active.call():
			_clear_scroll_stage()
			return false
	_sync_scroll_layout()
	if absf(get_scroll_vertical() - _target_scroll) > 1.0:
		SortLogger.error("RankListView: first screen scroll not committed, target=%.1f actual=%.1f" % [
			_target_scroll, get_scroll_vertical()])
		return false
	_first_screen_prepared = true
	preparation_stats["first_screen_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	return true


func _sync_scroll_layout() -> void :


	var was_setting: bool = _setting_scroll
	_setting_scroll = true
	_scroll.get_minimum_size()
	_scroll.notification(Container.NOTIFICATION_SORT_CHILDREN)


	var content_size: Vector2 = _content.get_combined_minimum_size().max(_scroll.size)
	_scroll.fit_child_in_rect(_content, Rect2(
		Vector2( - _scroll.scroll_horizontal, - _scroll.scroll_vertical), content_size))
	_setting_scroll = was_setting


func prepare_animation(active: Callable) -> bool:
	var generation: int = _preparation_generation
	if _overlay_item == null:
		_overlay_item = (overlay_scene if overlay_scene != null else item_scene).instantiate() as RankItemView
		_overlay_item.name = "Item"
		_overlay_item.visible = false
		$RiseOverlay.add_child(_overlay_item)
		_apply_collect_icon_fade(_overlay_item)
		await get_tree().process_frame
		if generation != _preparation_generation or not active.call():
			return false
	if not await _overlay_item.prepare_rise_fx(active):
		return false
	if _collect_source_fx == null:
		_collect_source_fx = collect_source_scene.instantiate() as RankSourceCollectionFx
		_collect_source_fx.name = "CollectSourceFx"
		_collect_source_fx.visible = false
		add_child(_collect_source_fx)
		await get_tree().process_frame
		if generation != _preparation_generation or not active.call():
			return false
	if _land_burst == null:
		_land_burst = land_burst_scene.instantiate() as RankRowLandBurstFx
		_land_burst.name = "LandBurst"
		_land_burst.visible = false
		$RiseOverlay.add_child(_land_burst)
		await get_tree().process_frame
		if generation != _preparation_generation or not active.call():
			return false
	if podium != null and _fourth_fill_preview == null:
		_fourth_fill_preview = item_scene.instantiate() as RankItemView
		_fourth_fill_preview.name = "FourthFillPreview"
		_fourth_fill_preview.visible = false
		_content.add_child(_fourth_fill_preview)
		_apply_collect_icon_fade(_fourth_fill_preview)
		await get_tree().process_frame
	return generation == _preparation_generation and active.call()


func get_prepared_item_count() -> int:
	return _items.size()


func get_layout_entry_count() -> int:
	return _layout.entries.size()


func is_first_screen_ready() -> bool:
	return _first_screen_prepared


func cancel_preparation() -> void :
	_preparation_generation += 1
	set_process(false)
	_first_screen_prepared = false
	_refresh_pending = false
	_clear_scroll_stage()
	_window.clear()
	_window_dirty = true


func _required_capacity() -> int:

	return mini(_layout.item_count, ceili(_view_height() / RankItemView.ROW_PITCH) * 2
		+ BUFFER_ROWS * 2 + ANIMATION_SLACK_ROWS * 2 + 5)


func _clear_scroll_stage() -> void :
	_staged_nodes.clear()
	_staged_queue.clear()
	_staged_window.clear()
	_stage_active = false


func _advance_scroll_window() -> bool:
	if _snapshot == null or _items.is_empty():
		return true
	var started: int = Time.get_ticks_usec()
	_last_scroll_batch_frame = Engine.get_process_frames()
	if not _stage_active:
		_staged_scroll = clampf(_target_scroll, 0.0, maxf(_layout.content_height - _view_height(), 0.0))
		_staged_window = _wanted_window(_staged_scroll)
		if _staged_window == _window and not _window_dirty:
			_set_scroll_unchecked(_staged_scroll)
			_committed_scroll = get_scroll_vertical()
			_clear_scroll_stage()
			_record_scroll_batch(Time.get_ticks_usec() - started)
			return true
		_staged_queue = _staged_window.duplicate()
		var me: int = int(_layout.key_indices.get("me", -1))
		if me >= 0 and not _staged_queue.has(me):
			_staged_queue.append(me)

		for index: int in _row_nodes.size():
			var node: Control = _row_nodes[index]
			if node == null:
				continue
			var entry: Dictionary = _layout.entries[index]
			var on_screen: bool = float(entry.y) + float(entry.height) > _committed_scroll\
			and float(entry.y) < _committed_scroll + _view_height()
			if not _staged_queue.has(index) and index != me and not on_screen:
				node.hide()
				node.process_mode = Node.PROCESS_MODE_DISABLED
				_row_nodes[index] = null
				_ready_entries.erase(index)
		_stage_active = true
	var available: Array[Control] = []
	for node: Control in _items + _banners:
		if not _row_nodes.has(node) and not _staged_nodes.values().has(node):
			available.append(node)
	var batch_count: int = 0
	while not _staged_queue.is_empty():
		var index: int = _staged_queue.pop_front()
		var node: Control = _row_nodes[index]
		if node == null:
			for candidate: Control in available:
				if (candidate is RankItemView) == (_row_rank[index] > 0):
					node = candidate
					available.erase(candidate)
					break
		if node == null:
			SortLogger.error("RankListView: staged window exceeded fixed pool")
			_clear_scroll_stage()
			return true

		if not _ready_entries.has(index) or _window_dirty:
			var before_bound: int = preparation_stats.bound
			_bind_node(index, node, _row_nodes[index] == node and node.visible)
			batch_count += int(preparation_stats.bound) - before_bound
		_staged_nodes[index] = node
		if (Time.get_ticks_usec() - started >= PREPARE_FRAME_BUDGET_USEC or batch_count >= MAX_BINDINGS_PER_FRAME)\
		and not _staged_queue.is_empty():
			_record_scroll_batch(Time.get_ticks_usec() - started)
			preparation_stats["deferred_batches"] = int(preparation_stats.get("deferred_batches", 0)) + 1
			return false
	for node: Control in _items + _banners:
		if not _staged_nodes.values().has(node):
			node.hide()
			node.process_mode = Node.PROCESS_MODE_DISABLED
	_row_nodes.fill(null)
	_ready_entries.clear()
	for index: int in _staged_nodes:
		var node: Control = _staged_nodes[index]
		_row_nodes[index] = node
		_ready_entries[index] = true
		node.position = Vector2(ROW_X, _entry_y(index))
		node.visible = not (_player_hidden and _layout.entries[index].key == "me")
		node.process_mode = Node.PROCESS_MODE_INHERIT
	_set_scroll_unchecked(_staged_scroll)
	_committed_scroll = get_scroll_vertical()
	_window = _staged_window.duplicate()
	_window_dirty = false
	_clear_scroll_stage()
	_record_scroll_batch(Time.get_ticks_usec() - started)
	return true


func _process(_delta: float) -> void :
	if _refresh_pending and not _resizing_pool and _last_scroll_batch_frame != Engine.get_process_frames():
		if _advance_scroll_window():
			_refresh_pending = not is_equal_approx(_committed_scroll, _target_scroll)

		_frame_samples.append(int(Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0))
		if _frame_samples.size() > 1800:
			_frame_samples.remove_at(0)
	set_process(_refresh_pending and not _resizing_pool)


func _on_scroll_resized() -> void :
	if not _first_screen_prepared:
		return
	_window_dirty = true
	_clear_scroll_stage()
	if _required_capacity() > _items.size():
		_resize_pool()
	else:
		_on_scroll_changed(get_scroll_vertical())


func _resize_pool() -> void :
	if _resizing_pool:
		return
	_resizing_pool = true
	var generation: int = _preparation_generation
	_drag_helper.set_process_input(false)
	_drag_helper.set_process(false)
	var batch_started: int = Time.get_ticks_usec()
	while generation == _preparation_generation and _items.size() < _required_capacity():
		_ensure_item(_items.size()).hide()
		preparation_stats.created += 1
		if Time.get_ticks_usec() - batch_started >= PREPARE_FRAME_BUDGET_USEC:
			await get_tree().process_frame
			batch_started = Time.get_ticks_usec()
	_pool_capacity = _items.size()
	preparation_stats.pool_capacity = _pool_capacity
	if generation == _preparation_generation:
		_target_scroll = get_scroll_vertical()
		while not _advance_scroll_window():
			await get_tree().process_frame
			if generation != _preparation_generation:
				break
	_resizing_pool = false
	if generation == _preparation_generation:
		_drag_helper.set_process_input(_drag_enabled)
		_on_scroll_changed(get_scroll_vertical())


func _on_scroll_changed(_value: float) -> void :
	if _setting_scroll or not _first_screen_prepared:
		return
	if _shift_active or _player_hidden:
		_refresh_window()
		return
	_target_scroll = get_scroll_vertical()
	_refresh_pending = true
	set_process(true)


	if not _scroll_restore_queued:
		_scroll_restore_queued = true
		_restore_display_scroll.call_deferred(_preparation_generation)


func _restore_display_scroll(generation: int) -> void :
	_scroll_restore_queued = false
	if generation == _preparation_generation and _refresh_pending and not _shift_active and not _player_hidden:
		_set_scroll_unchecked(_committed_scroll)
		if not _resizing_pool and _last_scroll_batch_frame != Engine.get_process_frames():
			if _advance_scroll_window():
				_refresh_pending = not is_equal_approx(_committed_scroll, _target_scroll)
		set_process(_refresh_pending and not _resizing_pool)


func _set_scroll_unchecked(value: float) -> void :
	_setting_scroll = true
	_scroll.scroll_vertical = int(round(value))
	_setting_scroll = false


func get_performance_stats() -> Dictionary:
	var result: Dictionary = preparation_stats.duplicate()
	var samples: PackedInt32Array = _scroll_samples.duplicate()
	samples.sort()
	var frames: PackedInt32Array = _frame_samples.duplicate()
	frames.sort()
	if not frames.is_empty():
		result["frame_cpu_p95_usec"] = frames[mini(frames.size() - 1, ceili(frames.size() * 0.95) - 1)]
		result["frame_cpu_p99_usec"] = frames[mini(frames.size() - 1, ceili(frames.size() * 0.99) - 1)]
		result["frame_cpu_max_usec"] = frames[-1]
	if not samples.is_empty():
		result["update_p95_usec"] = samples[mini(samples.size() - 1, ceili(samples.size() * 0.95) - 1)]
		result["update_p99_usec"] = samples[mini(samples.size() - 1, ceili(samples.size() * 0.99) - 1)]
		result["update_max_usec"] = samples[-1]
	return result


const ENTER_ANIM_ROW_RADIUS: int = 8
const ENTER_SLIDE_STEP_SEC: float = 0.05
const ENTER_SLIDE_DURATION_SEC: float = 0.3

func begin_enter_mask() -> void :
	modulate.a = 0.0


func end_enter_mask() -> void :
	modulate.a = 1.0


func play_enter_anim() -> void :
	var generation: int = animation_generation
	var entries: Array[Control] = _visible_entries_top_to_bottom()
	if entries.is_empty():
		end_enter_mask()
		return
	var center: int = _visible_row_index_of_me(entries)
	if center < 0 and podium != null and podium.find_item("me") != null:

		center = 0
	var lo: int = 0
	var hi: int = entries.size() - 1
	if center >= 0:
		lo = maxi(0, center - ENTER_ANIM_ROW_RADIUS)
		hi = mini(entries.size() - 1, center + ENTER_ANIM_ROW_RADIUS)

	var slide_from_x: float = ROW_X + size.x
	var scroll_rect: Rect2 = ($Scroll as ScrollContainer).get_global_rect()
	var animated: Array[Control] = []
	for i in entries.size():
		var node: Control = entries[i]
		if i >= lo and i <= hi and scroll_rect.intersects(node.get_global_rect()):
			node.modulate.a = 0.0
			node.position.x = slide_from_x
			animated.append(node)
		else:
			node.modulate.a = 1.0
			node.position.x = ROW_X
	if animated.is_empty():
		end_enter_mask()
		return
	end_enter_mask()
	await get_tree().process_frame
	if not animation_is_active(generation):
		return
	for node in animated:
		node.modulate.a = 1.0
		var tw: = create_animation_tween()
		tw.tween_property(node, "position:x", ROW_X, ENTER_SLIDE_DURATION_SEC)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		await get_tree().create_timer(ENTER_SLIDE_STEP_SEC).timeout
		if not animation_is_active(generation):
			return
	await get_tree().create_timer(maxf(ENTER_SLIDE_DURATION_SEC - ENTER_SLIDE_STEP_SEC, 0.0)).timeout


func play_rise_anim(from_snap: RankSnapshot, to_snap: RankSnapshot) -> void :
	var old_rank: int = from_snap.my_rank_pos if from_snap != null else -1
	var new_rank: int = to_snap.my_rank_pos if to_snap != null else -1
	if old_rank < 1 or new_rank < 1:
		return
	var generation: int = animation_generation
	if not await prepare_animation( func() -> bool: return animation_is_active(generation)):
		return
	if podium != null and new_rank <= 3:
		await podium.play_rise(self, from_snap, to_snap)
	else:
		await RankListRiseAnim.play(self, old_rank, new_rank)
	if animation_is_active(generation):
		set_snapshot(to_snap, true)
		_refresh_window()
		if not animation_is_active(generation):
			return
		end_fourth_fill()
		if podium != null and old_rank > 3 and new_rank <= 3:
			podium.set_entered_avatar_scale(new_rank)


func begin_fourth_fill(snap: RankSnapshot) -> void :
	var row: int = row_index_of_rank(4)
	if row < 0 or snap.rows.size() < 4:
		return
	if not is_instance_valid(_fourth_fill_preview):
		_fourth_fill_preview = item_scene.instantiate() as RankItemView
		_fourth_fill_preview.name = "FourthFillPreview"
		_content.add_child(_fourth_fill_preview)
		_apply_collect_icon_fade(_fourth_fill_preview)
	_fourth_fill_item = _fourth_fill_preview
	var entry: Dictionary = snap.rows[3]
	_fourth_fill_item.bind(entry, _avatar_for(int(entry.get("avatar_index", 0))), _element_pool.get_texture())
	_fourth_fill_y = row_base_y_at(row)
	_fourth_fill_item.position = Vector2(ROW_X, _fourth_fill_y - RankItemView.ROW_PITCH)
	_fourth_fill_item.modulate.a = 1.0
	_fourth_fill_item.show()


func sample_fourth_fill(progress: float) -> void :
	if is_instance_valid(_fourth_fill_item):

		var eased: float = 1.0 - pow(1.0 - clampf(progress, 0.0, 1.0), 3.0)
		_fourth_fill_item.position.y = _fourth_fill_y - RankItemView.ROW_PITCH * (1.0 - eased)


func end_fourth_fill() -> void :
	if is_instance_valid(_fourth_fill_item):
		_fourth_fill_item.position.y = _fourth_fill_y
		_fourth_fill_item.modulate.a = 1.0
		_fourth_fill_item.hide()
	_fourth_fill_item = null


func begin_top3_row_rise(old_rank: int) -> Dictionary:
	var row: int = row_index_of_rank(old_rank)
	var real_me: RankItemView = row_node_at(row) as RankItemView
	if real_me == null:
		return {}
	var overlay: RankItemView = get_rise_overlay_item()
	overlay.clone_bind_from(real_me)
	overlay.position = Vector2.ZERO
	overlay.pivot_offset = overlay.size * 0.5
	overlay.scale = Vector2.ONE
	overlay.visible = true

	var clip: Control = overlay.get_parent() as Control
	clip.clip_contents = true
	_player_hidden = true
	real_me.visible = false
	overlay.set_rise_outline(true)
	overlay.play_rise_arrows()
	set_drag_enabled(false)
	_top3_row_state = {"row": row, "real": real_me, "start_y": row_base_y_at(row), 
		"dst_y": row_base_y_at(row_index_of_rank(4)), "scroll": get_scroll_vertical(), "old_rank": old_rank, "rise": 0.0}
	return _top3_row_state


func sample_top3_row_rise(state: Dictionary, plan: Dictionary, sample: Dictionary) -> void :
	if state.is_empty():
		return
	var rise: float = float(sample.rise_progress)
	_top3_row_state.rise = rise
	var content_y: float = lerpf(float(state.start_y), float(state.dst_y), rise)
	set_scroll_vertical(lerpf(float(state.scroll), 0.0, rise))
	var overlay: RankItemView = get_rise_overlay_item()
	overlay.position = Vector2(0.0, content_y_to_overlay_y(content_y) - FinishMotion.FLYOUT_PX * float(sample.flyout_progress))
	overlay.scale = sample.row_scale
	overlay.set_rise_arrow_alpha(1.0)
	var passed: int = mini(int(plan.slots), int(floor(rise * (int(plan.slots) + 1))))
	overlay.set_rank_only(maxi(4, int(plan.old_rank) - passed))

	for rank: int in range(4, int(plan.old_rank)):
		var row: int = row_index_of_rank(rank)
		var node: Control = row_node_at(row)
		if node == null:
			continue
		var order: int = int(plan.old_rank) - 1 - rank
		var progress: float = clampf(rise * (int(plan.slots) + 1) - order, 0.0, 1.0)
		node.position.y = row_base_y_at(row) + RankItemView.ROW_PITCH * progress


func end_top3_row_rise() -> void :
	if not _top3_row_state.is_empty():
		var real_me: Variant = _top3_row_state.real
		if is_instance_valid(real_me):
			real_me.visible = true
		for row: int in range(int(_top3_row_state.row) + 1):
			var node: Control = row_node_at(row)
			if node != null:
				node.position.y = row_base_y_at(row)
	_top3_row_state = {}
	_player_hidden = false
	var overlay: RankItemView = get_rise_overlay_item()
	if overlay == null:
		return
	overlay.set_rise_outline(false)
	overlay.stop_rise_arrows()
	overlay.set_rise_arrow_alpha(1.0)
	overlay.scale = Vector2.ONE
	overlay.pivot_offset = Vector2.ZERO
	overlay.visible = false
	(overlay.get_parent() as Control).clip_contents = false


func row_index_of_rank(rank_pos: int) -> int:
	return int(_layout.rank_indices.get(rank_pos, -1))


func row_node_at(row_index: int) -> Control:
	return _row_nodes[row_index] if row_index >= 0 and row_index < _row_nodes.size() else null


func row_base_y_at(row_index: int) -> float:
	return _row_base_y[row_index] if row_index >= 0 and row_index < _row_base_y.size() else 0.0


func get_rise_overlay_item() -> RankItemView:
	return _overlay_item


func play_rise_land_burst(overlay_y: float) -> void :
	var burst: = $RiseOverlay / LandBurst as RankRowLandBurstFx
	if burst == null:
		return
	burst.position = Vector2(0.0, overlay_y)
	burst.play()


func content_y_to_overlay_y(content_y: float) -> float:
	return content_y - float(($Scroll as ScrollContainer).scroll_vertical) - ($RiseOverlay as Control).position.y


func scroll_target_for_row(row_index: int) -> float:
	var scroll: ScrollContainer = $Scroll
	var view_h: float = scroll.size.y
	var content_h: float = maxf(_content.custom_minimum_size.y, view_h)
	return clampf(row_base_y_at(row_index) - view_h * 0.5, 0.0, maxf(content_h - view_h, 0.0))


func get_scroll_vertical() -> float:
	return float(($Scroll as ScrollContainer).scroll_vertical)


func set_scroll_vertical(value: float) -> void :
	_set_scroll_unchecked(value)
	if _first_screen_prepared:
		_refresh_window()


func set_drag_enabled(enabled: bool) -> void :
	_drag_enabled = enabled
	var scroll: ScrollContainer = $Scroll
	if scroll != null:
		scroll.mouse_filter = _scroll_mouse_filter_rest if enabled else Control.MOUSE_FILTER_IGNORE
	if _drag_helper == null or not is_instance_valid(_drag_helper):
		return
	_drag_helper.set_process_input(enabled)
	if not enabled:
		_drag_helper.set_process(false)


func build_rise_shift_deltas(old_rank: int, new_rank: int) -> Dictionary:
	var deltas: Dictionary = {}
	for r in range(new_rank, old_rank):
		var src_row: int = row_index_of_rank(r)
		var dst_row: int = row_index_of_rank(r + 1)
		if src_row < 0 or dst_row < 0:
			continue
		deltas[src_row] = _row_base_y[dst_row] - _row_base_y[src_row]
	return deltas


func build_rise_collapse_targets(old_row: int) -> Dictionary:
	var targets: Dictionary = {}
	var half: float = RankItemView.ROW_PITCH * 0.5
	for i in _row_nodes.size():
		if i == old_row:
			continue
		targets[i] = _row_base_y[i] + (half if i < old_row else - half)
	return targets


func build_rise_settle_targets(old_rank: int, new_rank: int) -> Array:
	var deltas: Dictionary = build_rise_shift_deltas(old_rank, new_rank)
	var targets: Dictionary = {}
	for i in _row_nodes.size():
		targets[i] = _row_base_y[i] + float(deltas.get(i, 0.0))
	var wave: Array[int] = []
	for k in deltas.keys():
		wave.append(int(k))
	wave.sort()
	return [targets, wave]


func begin_shift(targets: Dictionary, wave_rows: Array = []) -> void :
	var current_y: Dictionary = {}
	for index: int in targets:
		current_y[index] = _entry_y(index)
	_shift_active = true
	_shift_to = targets
	_shift_from = current_y
	_shift_delay = {}
	for ordinal in wave_rows.size():
		_shift_delay[int(wave_rows[ordinal])] = minf(0.28, float(ordinal) * 0.08)
	_shift_t = 0.0
	_apply_shift()


func set_shift_t(t: float) -> void :
	_shift_t = t
	_apply_shift()


func end_shift() -> void :
	_shift_active = false
	_shift_to = {}
	_shift_from = {}
	_shift_delay = {}
	_shift_t = 0.0


func _apply_shift() -> void :
	if _shift_active:
		_refresh_window()


static func _ease_out_back(t: float, overshoot: float) -> float:
	var x: float = t - 1.0
	return 1.0 + (overshoot + 1.0) * x * x * x + overshoot * x * x


func play_collect_anim(count: int) -> void :
	var item_me: RankItemView = _item_by_key("me")
	if item_me == null or count <= 0:
		return
	if not _ensure_element_pool():
		return
	var tex: Texture2D = _element_pool.get_texture()
	var start_num: int = item_me.get_collect_num_display()
	var end_num: int = RankManager.get_collect_num()
	await RankListCollectAnim.play(self, _collect_source_fx, item_me, tex, 
		count, start_num, end_num)


func scroll_rank_to_center(rank_pos: int) -> void :
	var row: int = row_index_of_rank(rank_pos)
	if row < 0:
		if podium != null and rank_pos <= 3:
			set_scroll_vertical(0.0)
		return
	set_scroll_vertical(scroll_target_for_row(row))


func scroll_to_me() -> void :
	var scroll: ScrollContainer = $Scroll
	var index: int = int(_layout.key_indices.get("me", -1))
	var my_y: float = _row_base_y[index] if index >= 0 else -1.0
	if my_y < 0.0:
		return
	set_scroll_vertical(maxf(my_y - size.y * 0.5 + RankItemView.ROW_PITCH * 0.5, 0.0))


func get_visible_item_count() -> int:
	var n: int = 0
	for it in _items:
		if it.visible:
			n += 1
	return n


func get_item_at(idx: int) -> RankItemView:
	var ordinal: int = 0
	for i: int in _row_rank.size():
		if _row_rank[i] > 0:
			if ordinal == idx:
				return _row_nodes[i] as RankItemView
			ordinal += 1
	return null


func find_my_item() -> RankItemView:
	return _item_by_key("me")


func get_visible_banner_count() -> int:
	var n: int = 0
	for b in _banners:
		if b.visible:
			n += 1
	return n


func is_moving() -> bool:
	return _shift_active or _player_hidden


func _ensure_item(idx: int) -> RankItemView:
	while _items.size() <= idx:
		var node: RankItemView = item_scene.instantiate() as RankItemView
		node.visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
		node.gift_pressed.connect(_on_item_gift_pressed.bind(node))
		_content.add_child(node)
		_apply_collect_icon_fade(node)
		_items.append(node)
		if _first_screen_prepared and not _resizing_pool:
			preparation_stats.scroll_created += 1
	var it: RankItemView = _items[idx]
	it.visible = true
	return it


func _apply_collect_icon_fade(item: RankItemView) -> void :

	if collect_icon_fade_material != null:
		(item.get_node("CollectIcon") as TextureRect).material = collect_icon_fade_material


func _on_item_gift_pressed(rank_pos: int, item: RankItemView) -> void :
	if is_moving():
		return
	gift_tapped.emit(rank_pos, item.get_gift_button_global_rect())


func _ensure_banner(idx: int) -> RankZoneBanner:
	while _banners.size() <= idx:
		var node: RankZoneBanner = zone_banner_scene.instantiate() as RankZoneBanner
		node.visible = false
		_content.add_child(node)
		_banners.append(node)
		if _first_screen_prepared and not _resizing_pool:
			preparation_stats.scroll_created += 1
	var b: RankZoneBanner = _banners[idx]
	b.visible = true
	return b


func _avatar_for(avatar_index: int) -> Texture2D:
	return _pool.get_texture(avatar_index)


func _visible_entries_top_to_bottom() -> Array[Control]:
	var entries: Array[Control] = []
	for it in _items:
		if it.visible:
			entries.append(it)
	for b in _banners:
		if b.visible:
			entries.append(b)
	entries.sort_custom( func(a: Control, b2: Control) -> bool: return a.position.y < b2.position.y)
	return entries


func _visible_row_index_of_me(entries: Array[Control]) -> int:
	for i in entries.size():
		var it: = entries[i] as RankItemView
		if it != null and it.get_row_key() == "me":
			return i
	return -1


func _item_by_key(key: String) -> RankItemView:
	var index: int = int(_layout.key_indices.get(key, -1))
	if index >= 0 and _ready_entries.has(index):
		return _row_nodes[index] as RankItemView
	return podium.find_item(key) if podium != null else null


func _ensure_element_pool() -> bool:
	if _element_pool != null:
		return true
	if element_pool_scene == null:
		SortLogger.error("RankListView: 未注入收集元素池场景")
		return false
	_element_pool = element_pool_scene.instantiate() as RankCollectElementPool
	if _element_pool == null:
		SortLogger.error("RankListView: 收集元素池根节点类型不符")
		return false
	add_child(_element_pool)
	return true


func animation_is_active(generation: int) -> bool:
	return generation == animation_generation and is_inside_tree() and is_visible_in_tree()


func create_animation_tween() -> Tween:
	var tw: = create_tween()
	_animation_tweens.append(tw)
	var tween_ref: WeakRef = weakref(tw)
	tw.finished.connect( func() -> void : _animation_tweens.erase(tween_ref.get_ref()), CONNECT_ONE_SHOT)
	return tw


func wait_animation(tw: Tween, generation: int) -> void :
	while animation_is_active(generation) and tw.is_valid() and tw.is_running():
		await get_tree().process_frame


func cancel_animations() -> void :
	cancel_preparation()
	animation_generation += 1
	_player_hidden = false
	end_fourth_fill()
	if podium != null:
		podium.cancel_animations()
	for tw: Tween in _animation_tweens:
		if tw.is_valid():
			tw.kill()
	_animation_tweens.clear()
	if _collect_source_fx != null:
		_collect_source_fx.cancel_all()
	if _land_burst != null:
		_land_burst.stop()
	end_shift()
	var overlay: RankItemView = get_rise_overlay_item()
	end_top3_row_rise()
	if overlay != null:
		overlay.reset_for_reuse()
		overlay.visible = false
	for item: RankItemView in _items:
		item.set_avatar_visible(true)
		item.reset_first_place_fx()
		item.reset_rise_fx()
		item.reset_tilt()
		item.reset_collect_punch()
		item.scale = Vector2.ONE
		item.modulate.a = 1.0
		item.position.x = ROW_X
	for banner: RankZoneBanner in _banners:
		banner.modulate.a = 1.0
		banner.position.x = ROW_X
	set_drag_enabled(true)
