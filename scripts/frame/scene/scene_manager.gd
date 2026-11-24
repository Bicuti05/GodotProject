extends Node


signal top_fullscreen_page_changed(route: String)


const FULLSCREEN_DIALOG_ROUTES: PackedStringArray = ["finish", "rank_game_finish", "timed_endless_reward"]
var _top_fullscreen_page_name: String = ""










var PAGE_SCENES: Dictionary = {
	"rank": "res://scripts/main/pages/rank/rank_page.tscn", 
	"rank_game_finish": "res://scripts/main/pages/rank_game_finish/rank_game_finish_page.tscn", 
	"rank_change": "res://scripts/main/dialogs/rank_change/rank_change_dialog.tscn", 
	"rank_new_season": "res://scripts/main/dialogs/rank_new_season/rank_new_season_dialog.tscn", 
	"rank_introduction": "res://scripts/main/dialogs/rank_introduction/rank_introduction_dialog.tscn", 
	"rank_season_win": "res://scripts/main/dialogs/rank_season_win/rank_season_win_page.tscn", 
	"avatar_select": "res://scripts/main/dialogs/avatar_select/avatar_select_dialog.tscn", 
	"new_scene": "res://scripts/gameplay/outer_loop/view/new_scene_page.tscn", 
	"logo": "res://scripts/main/pages/logo/logo_page.tscn", 
	"splash": "res://scripts/main/pages/splash/splash_page.tscn", 
	"loading": "res://scripts/main/dialogs/loading/loading_overlay.tscn", 
	"privacy": "res://scripts/main/dialogs/privacy/privacy_dialog.tscn", 
	"confirm": "res://scripts/main/dialogs/confirm/confirm_dialog.tscn", 
	"setting": "res://scripts/main/dialogs/settings/settings_dialog.tscn", 
	"home": "res://scripts/main/pages/home/home_page.tscn", 

	"game": "res://scripts/main/pages/game/juice_game_page.tscn", 

	"game_dead_toast": "res://scripts/main/dialogs/game_dead_toast/game_dead_toast.tscn", 
	"reset_confirm": "res://scripts/main/dialogs/reset_confirm/reset_confirm_dialog.tscn", 
	"prop_unlock": "res://scripts/main/dialogs/prop_unlock/prop_unlock_dialog.tscn", 

	"special_challenge_reward": "res://scripts/main/dialogs/special_challenge_reward/special_challenge_reward_dialog.tscn", 
	"finish": "res://scripts/main/dialogs/finish/finish_dialog.tscn", 
	"timed_endless_reward": "res://scripts/main/dialogs/timed_endless_reward/timed_endless_reward_dialog.tscn", 
	"daily_first_win_checkin": "res://scripts/main/dialogs/daily_first_win_checkin/daily_first_win_checkin_dialog.tscn", 
	"finish_ad_reward": "res://scripts/main/dialogs/finish_ad_reward/finish_ad_reward_dialog.tscn", 
}


















enum Layer{
	PAGE = 0, 
	DIALOG = 100, 
	TOAST = 200, 
	DEBUG = 300, 
}




var PAGE_LAYERS: Dictionary = {
	"rank": Layer.PAGE, 
	"rank_game_finish": Layer.DIALOG, 
	"rank_change": Layer.DIALOG, 
	"rank_new_season": Layer.DIALOG, 
	"rank_introduction": Layer.DIALOG, 
	"rank_season_win": Layer.DIALOG, 
	"avatar_select": Layer.DIALOG, 
	"new_scene": Layer.DIALOG, 
	"logo": Layer.PAGE, 
	"splash": Layer.PAGE, 
	"home": Layer.PAGE, 
	"game": Layer.PAGE, 

	"confirm": Layer.DIALOG, 
	"setting": Layer.DIALOG, 
	"privacy": Layer.DIALOG, 
	"game_dead_toast": Layer.DIALOG, 
	"reset_confirm": Layer.DIALOG, 
	"prop_unlock": Layer.DIALOG, 
	"special_challenge_reward": Layer.DIALOG, 
	"finish": Layer.DIALOG, 
	"timed_endless_reward": Layer.DIALOG, 
	"daily_first_win_checkin": Layer.DIALOG, 
	"finish_ad_reward": Layer.DIALOG, 








	"loading": Layer.TOAST, 
}


var _layers: Dictionary = {}


var _page_layers: Dictionary = {}


var _page_cache: Dictionary = {}















func _layer_root(lv: int) -> CanvasLayer:
	var cl: CanvasLayer = _layers.get(lv, null)
	if cl != null and is_instance_valid(cl):
		return cl
	cl = CanvasLayer.new()
	cl.name = "UILayer%d" % lv
	cl.layer = lv
	var host: Node = get_tree().current_scene
	if host == null:

		push_error("SceneManager: current_scene 为空,桶 %d 退回挂 root" % lv)
		host = get_tree().root
	host.add_child(cl)
	_layers[lv] = cl
	return cl



func _page_layer_root(page_name: String) -> CanvasLayer:
	var canvas: CanvasLayer = _page_layers.get(page_name, null)
	if canvas != null and is_instance_valid(canvas):
		return canvas
	var bucket: CanvasLayer = _layer_root(Layer.PAGE)
	if bucket.get_child_count() >= Layer.DIALOG - 1:
		SortLogger.error("SceneManager: PAGE 画布数量已达 99，不能占用关号 HUD 的 99 层")
		return null
	canvas = CanvasLayer.new()
	canvas.name = "PageCanvas_" + page_name
	canvas.layer = bucket.get_child_count()
	bucket.add_child(canvas)
	_page_layers[page_name] = canvas
	return canvas



func _place_page_layer(canvas: CanvasLayer, below_node: Variant) -> void :
	var bucket: Node = canvas.get_parent()
	if is_instance_valid(below_node) and below_node.get_parent() is CanvasLayer\
	and below_node.get_parent() != canvas and below_node.get_parent().get_parent() == bucket:
		var below_index: int = below_node.get_parent().get_index()
		var dst_index: int = below_index - 1 if canvas.get_index() < below_index else below_index
		bucket.move_child(canvas, dst_index)
	else:
		if below_node != null:
			SortLogger.error("SceneManager: 指定的下方插入目标不在 PAGE 桶或是同一页")
		bucket.move_child(canvas, -1)
	for index: int in range(bucket.get_child_count()):
		(bucket.get_child(index) as CanvasLayer).layer = index
	_refresh_top_fullscreen_page()



func _layer_of(page_name: String) -> int:
	if not PAGE_LAYERS.has(page_name):
		push_error("SceneManager: 页面 '%s' 未登记桶归属(PAGE_LAYERS),按 PAGE 兜底" % page_name)
		return Layer.PAGE
	return int(PAGE_LAYERS[page_name])


const ASYNC_PAGES: PackedStringArray = ["game", "home", "finish", "rank", "rank_game_finish", "timed_endless_reward"]
var _page_load_started_usec: Dictionary = {}
var _warming_pages: Dictionary = {}

func request_page_threaded(page_name: String) -> void :
	if not ASYNC_PAGES.has(page_name) or not PAGE_SCENES.has(page_name) or _page_load_started_usec.has(page_name):
		return
	var cached: Node = _page_cache.get(page_name, null)
	if is_instance_valid(cached):
		return
	var err: Error = ResourceLoader.load_threaded_request(PAGE_SCENES[page_name], "PackedScene", false)
	if err != OK:
		push_error("SceneManager: 页面 '%s' 线程加载请求失败, err=%d" % [page_name, err])
		return
	_page_load_started_usec[page_name] = Time.get_ticks_usec()


func warm_page(page_name: String) -> Node:
	var cached: Node = _page_cache.get(page_name, null)
	if is_instance_valid(cached):
		return cached
	return _add_scene(page_name, _layer_of(page_name), {}, null, false)



func warm_page_threaded(page_name: String, active: Callable = Callable(), can_work: Callable = Callable()) -> void :
	if not PAGE_SCENES.has(page_name):
		return
	if not ASYNC_PAGES.has(page_name):
		if active.is_valid() and not active.call():
			return
		if can_work.is_valid() and not can_work.call():
			return
		warm_page(page_name)
		return
	var node: Node = _page_cache.get(page_name, null)
	if is_instance_valid(node):
		return
	if _warming_pages.has(page_name):
		while _warming_pages.has(page_name):
			await get_tree().process_frame
		return
	request_page_threaded(page_name)
	if not _page_load_started_usec.has(page_name):
		return
	_warming_pages[page_name] = true
	var path: String = PAGE_SCENES[page_name]
	var wait_started: int = Time.get_ticks_usec()
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("SceneManager: 页面 '%s' 线程加载失败" % page_name)
		_page_load_started_usec.erase(page_name)
		_warming_pages.erase(page_name)
		return
	var packed: PackedScene = ResourceLoader.load_threaded_get(path) as PackedScene
	var loaded_at: int = Time.get_ticks_usec()
	var request_elapsed: int = loaded_at - int(_page_load_started_usec[page_name])
	_page_load_started_usec.erase(page_name)
	if packed == null:
		push_error("SceneManager: 页面 '%s' 线程加载结果不是 PackedScene" % page_name)
		_warming_pages.erase(page_name)
		return

	node = _page_cache.get(page_name, null)
	if is_instance_valid(node):
		_warming_pages.erase(page_name)
		return
	if not await wait_preparation_permission(active, can_work):
		_warming_pages.erase(page_name)
		return
	node = packed.instantiate()
	node.visible = false
	var instantiated_at: int = Time.get_ticks_usec()

	await get_tree().process_frame
	var cached_after_frame: Node = _page_cache.get(page_name, null)
	if is_instance_valid(cached_after_frame):
		node.free()
		_warming_pages.erase(page_name)
		return
	if not await wait_preparation_permission(active, can_work):
		node.free()
		_warming_pages.erase(page_name)
		return
	var attach_started: int = Time.get_ticks_usec()
	var category: int = _layer_of(page_name)
	var host: CanvasLayer = _page_layer_root(page_name) if category == Layer.PAGE else _layer_root(category)
	if host == null:
		node.free()
		_warming_pages.erase(page_name)
		return
	if node.has_method("prepare_cached_dependencies"):
		node.prepare_cached_dependencies()
	host.add_child(node)
	_page_cache[page_name] = node
	_bind_fullscreen_observer(page_name, node)
	_warming_pages.erase(page_name)
	SortLogger.info("[PageLoad] page=%s resource_elapsed_ms=%.2f resource_wait_ms=%.2f instantiate_ms=%.2f attach_ms=%.2f" % [
		page_name, request_elapsed / 1000.0, (loaded_at - wait_started) / 1000.0, 
		(instantiated_at - loaded_at) / 1000.0, (Time.get_ticks_usec() - attach_started) / 1000.0])

var _display_load_leases: Dictionary = {}
var _display_loading_owner: RefCounted



func load_page_for_display(route: String, active: Callable) -> Node:
	if not active.call():
		return null
	var lease: RefCounted = begin_display_loading()
	var page: Node = await prepare_page_for_display(route, active)
	end_display_loading(lease)
	return page



func prepare_page_for_display(route: String, active: Callable, can_work: Callable = Callable(), background: bool = false) -> Node:
	if not active.call():
		return null
	var state: Dictionary = {"done": false, "page": null}
	_load_display_page(route, active, state, can_work, background)
	while active.call() and not state.done:
		await get_tree().process_frame
	return state.page if active.call() and state.done else null



func prepare_page_ui(route: String, page: Node) -> void :
	_attach_button_feedback(page)
	_apply_safe_area(route, page)


func begin_display_loading() -> RefCounted:
	var lease: = RefCounted.new()
	if _display_load_leases.is_empty():
		var loading: Node = get_page("loading")
		if loading == null or not loading.visible:
			_display_loading_owner = RefCounted.new()
			loading = show_loading()
			loading.set_meta(&"display_loading_owner", _display_loading_owner)
	_display_load_leases[lease] = true
	return lease


func end_display_loading(lease: RefCounted) -> void :
	_display_load_leases.erase(lease)
	if _display_load_leases.is_empty() and _display_loading_owner != null:
		var loading: Node = get_page("loading")
		if loading != null and loading.has_meta(&"display_loading_owner")\
		and loading.get_meta(&"display_loading_owner") == _display_loading_owner:
			hide_loading()
		_display_loading_owner = null


var _preparing_pages: Dictionary = {}



func _load_display_page(route: String, active: Callable, state: Dictionary, 
		can_work: Callable, background: bool) -> void :
	while active.call() and _preparing_pages.has(route):
		await get_tree().process_frame
	if not active.call():
		state.done = true
		return
	_preparing_pages[route] = true
	await warm_page_threaded(route, active, can_work)
	var page: Node = get_page(route)
	if page != null and not page.visible and await wait_preparation_permission(active, can_work):
		prepare_page_ui(route, page)
		var prepared: bool = true
		if page.has_method("set_preparation_work_permission"):
			page.set_preparation_work_permission(can_work)
		if background and page.has_method("prepare_for_background"):
			prepared = await page.prepare_for_background(active)
		elif page.has_method("prepare_for_display"):
			prepared = await page.prepare_for_display(active)
		if page.has_method("set_preparation_work_permission"):
			page.set_preparation_work_permission(Callable())
		if prepared and active.call():
			state.page = page
	_preparing_pages.erase(route)
	state.done = true


func wait_preparation_permission(active: Callable, can_work: Callable) -> bool:
	while ( not active.is_valid() or active.call()) and can_work.is_valid() and not can_work.call():
		await get_tree().process_frame
	return not active.is_valid() or active.call()




const COMPONENT_FRAME_BUDGET_USEC: int = 2000

func instantiate_page_components(page: Node, scenes: Dictionary, active: Callable, pause_components: bool = false, can_work: Callable = Callable()) -> bool:
	var batch_started: int = Time.get_ticks_usec()
	for component_path: String in scenes:
		if not await wait_preparation_permission(active, can_work):
			return false
		var placeholder: Node = page.get_node(component_path)
		if placeholder.get_meta(&"component_ready", false):
			continue
		var started: int = Time.get_ticks_usec()
		var component: Node = null
		if page.has_method("take_prepared_component"):
			component = page.take_prepared_component(component_path)
		if component == null:
			component = (scenes[component_path] as PackedScene).instantiate()
		if component is CanvasItem:
			(component as CanvasItem).visible = false
		if pause_components:
			component.process_mode = Node.PROCESS_MODE_DISABLED
		if Time.get_ticks_usec() - batch_started >= COMPONENT_FRAME_BUDGET_USEC:
			await get_tree().process_frame
			batch_started = Time.get_ticks_usec()
		if not await wait_preparation_permission(active, can_work):
			component.free()
			return false
		var parent: Node = placeholder.get_parent()
		var index: int = placeholder.get_index()
		component.name = placeholder.name
		if component is Control and placeholder is Control and not placeholder.get_meta(&"component_preserve_layout", false):
			for property: String in ["layout_mode", "anchor_left", "anchor_top", "anchor_right", "anchor_bottom", 
				"offset_left", "offset_top", "offset_right", "offset_bottom", "grow_horizontal", "grow_vertical", 
				"custom_minimum_size", "mouse_filter", "clip_contents", "z_index", "z_as_relative"]:
				component.set(property, placeholder.get(property))
		elif component is Control and placeholder is Control:
			component.z_index = placeholder.z_index
			component.z_as_relative = placeholder.z_as_relative
		elif component is Node2D and placeholder is Node2D:
			component.transform = placeholder.transform
			component.z_index = placeholder.z_index
			component.z_as_relative = placeholder.z_as_relative
		for baseline: StringName in [_SAFE_TOP_BASELINE_META, _SAFE_BOTTOM_BASELINE_META, 
			_SAFE_TOP_GROW_BOTTOM_BASELINE_META, _SAFE_BOTTOM_GROW_TOP_BASELINE_META, _COLLAPSE_BASELINE_META]:
			if placeholder.has_meta(baseline):
				component.set_meta(baseline, placeholder.get_meta(baseline))
		for group: StringName in placeholder.get_groups():
			component.add_to_group(group)
		var component_properties: Dictionary = placeholder.get_meta(&"component_properties", {})
		for property: String in component_properties:
			component.set(property, component_properties[property])
		parent.remove_child(placeholder)
		placeholder.free()
		if page.has_method("prepare_component_dependencies"):
			page.prepare_component_dependencies(component_path, component)
		parent.add_child(component)
		parent.move_child(component, index)

		_attach_button_feedback(component)
		component.set_meta(&"component_ready", true)
		SortLogger.info("[PageComponent] path=%s prepare_ms=%.2f" % [component_path, 
			(Time.get_ticks_usec() - started) / 1000.0])
		if Time.get_ticks_usec() - batch_started >= COMPONENT_FRAME_BUDGET_USEC:
			await get_tree().process_frame
			batch_started = Time.get_ticks_usec()
	return active.call()







func _add_scene(page_name: String, layer: int, params: Dictionary = {}, below_node: Variant = null, 
		show_now: bool = true) -> Node:
	if not PAGE_SCENES.has(page_name):
		push_error("SceneManager: 未知页面 '%s'" % page_name)
		return null

	var host: CanvasLayer = _page_layer_root(page_name) if layer == Layer.PAGE else _layer_root(layer)
	if host == null:
		return null
	var node: Node = _page_cache.get(page_name, null)
	if node == null or not is_instance_valid(node):
		var load_started: int = Time.get_ticks_usec()
		var packed: PackedScene = load(PAGE_SCENES[page_name])
		if packed == null:
			push_error("SceneManager: 无法加载场景 '%s'" % PAGE_SCENES[page_name])
			return null
		var loaded_at: int = Time.get_ticks_usec()
		node = packed.instantiate()
		var instantiated_at: int = Time.get_ticks_usec()


		if layer == Layer.PAGE or below_node != null or not show_now:
			node.visible = false
		host.add_child(node)
		_page_cache[page_name] = node
		_bind_fullscreen_observer(page_name, node)
		SortLogger.info("[PageLoad] page=%s resource_ms=%.2f instantiate_ms=%.2f attach_ms=%.2f" % [
			page_name, (loaded_at - load_started) / 1000.0, 
			(instantiated_at - loaded_at) / 1000.0, (Time.get_ticks_usec() - instantiated_at) / 1000.0])
	elif node.get_parent() != host:

		if below_node != null or not show_now:
			node.visible = false
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		host.add_child(node)
		_page_cache[page_name] = node

	if layer == Layer.PAGE:
		if below_node != null:
			node.visible = false
		_place_page_layer(host, below_node)
	else:

		host.move_child(node, -1)


	if not show_now:
		node.visible = false
		return node
	node.visible = true
	_refresh_top_fullscreen_page()



	_attach_button_feedback(node)


	_apply_safe_area(page_name, node)







	if node.has_method("_on_show"):
		node._on_show(params)

	return node










func show_page(page_name: String, params: Dictionary = {}, below_node: Variant = null) -> Node:
	if _layer_of(page_name) != Layer.PAGE:
		push_error("SceneManager: '%s' 的桶归属不是 PAGE,不能用 show_page(请改 PAGE_LAYERS,或改用桶归属对应的入口:show_dlg/show_debug_panel)" % page_name)
		return null
	return _add_scene(page_name, Layer.PAGE, params, below_node)



func prepare_page_below(page_name: String, below_node: Variant) -> Node:
	if _layer_of(page_name) != Layer.PAGE:
		push_error("SceneManager: '%s' 的桶归属不是 PAGE,不能用 prepare_page_below" % page_name)
		return null
	return _add_scene(page_name, Layer.PAGE, {}, below_node, false)



func hide_page(page_name: String) -> void :
	var node: Node = _page_cache.get(page_name, null)
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("_on_hide"):
		node._on_hide()
	else:
		node.visible = false














func show_dlg(dlg_name: String, params: Dictionary = {}) -> Node:
	if _layer_of(dlg_name) != Layer.DIALOG:
		push_error("SceneManager: '%s' 的桶归属不是 DIALOG,不能用 show_dlg(请改 PAGE_LAYERS,或改用桶归属对应的入口:show_page/show_debug_panel)" % dlg_name)
		return null
	return _add_scene(dlg_name, Layer.DIALOG, params)


func hide_dlg(dlg_name: String) -> void :
	hide_page(dlg_name)




func hide_all_dialogs() -> void :
	for page_name in PAGE_LAYERS:
		if int(PAGE_LAYERS[page_name]) != Layer.DIALOG:
			continue
		var node: Node = _page_cache.get(page_name, null)
		if node != null and is_instance_valid(node) and node.visible:
			hide_dlg(page_name)







func show_toast(msg: String, hold: float = Toast.DEFAULT_HOLD) -> void :
	Toast.popup(msg, _layer_root(Layer.TOAST), hold)









func show_loading() -> Node:
	if _layer_of("loading") != Layer.TOAST:
		push_error("SceneManager: 'loading' 的桶归属不是 TOAST,不能用 show_loading(请改 PAGE_LAYERS)")
		return null
	var loading: Node = _add_scene("loading", Layer.TOAST)
	if loading.has_meta(&"display_loading_owner"):
		loading.remove_meta(&"display_loading_owner")
	return loading


func hide_loading() -> void :
	hide_page("loading")







func show_debug_panel(panel_name: String, params: Dictionary = {}) -> Node:
	if not PAGE_SCENES.has(panel_name):
		return null
	if _layer_of(panel_name) != Layer.DEBUG:
		push_error("SceneManager: '%s' 的桶归属不是 DEBUG,不能用 show_debug_panel(请改 PAGE_LAYERS,或改用桶归属对应的入口:show_page/show_dlg)" % panel_name)
		return null
	return _add_scene(panel_name, Layer.DEBUG, params)



func get_page(page_name: String) -> Node:
	var node: Node = _page_cache.get(page_name, null)
	if node != null and is_instance_valid(node):
		return node
	return null




func reapply_safe_area() -> void :
	for page_name in _page_cache:
		var node: Node = _page_cache[page_name]
		if not is_instance_valid(node) or not node.visible:
			continue
		_apply_safe_area(page_name, node)




func get_active_page_names() -> Array[String]:
	var entries: Array = []
	for page_name in _page_cache:
		var node: Node = _page_cache[page_name]
		if not is_instance_valid(node) or not node.visible or not node.is_inside_tree():
			continue
		var category: int = _layer_of(page_name)
		if category == Layer.PAGE and node.get_parent() != _page_layers.get(page_name):
			continue
		entries.append({
			"name": page_name, 
			"layer": (node.get_parent() as CanvasLayer).layer if category == Layer.PAGE else category, 
			"idx": node.get_index(), 
		})
	entries.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		if a["layer"] != b["layer"]:
			return a["layer"] < b["layer"]
		return a["idx"] < b["idx"])
	var out: Array[String] = []
	for e in entries:
		out.append(e["name"])
	return out



func get_top_fullscreen_page_name() -> String:
	var routes: Array[String] = get_active_page_names()
	for index: int in range(routes.size() - 1, -1, -1):
		var route: String = routes[index]
		if _layer_of(route) == Layer.PAGE or route in FULLSCREEN_DIALOG_ROUTES:
			var node: CanvasItem = _page_cache.get(route, null) as CanvasItem
			if node != null and node.is_visible_in_tree() and not node.is_queued_for_deletion():
				return route
	return ""


func _refresh_top_fullscreen_page() -> void :
	var route: String = get_top_fullscreen_page_name()
	if route == _top_fullscreen_page_name:
		return
	_top_fullscreen_page_name = route
	top_fullscreen_page_changed.emit(route)


func _on_cached_page_tree_exiting(route: String) -> void :
	_page_cache.erase(route)
	_refresh_top_fullscreen_page.call_deferred()


func _bind_fullscreen_observer(route: String, node: CanvasItem) -> void :
	if not node.visibility_changed.is_connected(_refresh_top_fullscreen_page):
		node.visibility_changed.connect(_refresh_top_fullscreen_page)
		node.tree_exiting.connect(_on_cached_page_tree_exiting.bind(route))







func is_topmost(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	for lv in [Layer.DEBUG, Layer.DIALOG]:
		var cl: CanvasLayer = _layers.get(lv, null)
		if cl == null or not is_instance_valid(cl):
			continue
		var top: Node = null
		for child in cl.get_children():
			if child is CanvasItem and (child as CanvasItem).visible:
				top = child
		if top != null:
			return top == node
	var page_bucket: CanvasLayer = _layers.get(Layer.PAGE, null)
	if is_instance_valid(page_bucket):
		for index: int in range(page_bucket.get_child_count() - 1, -1, -1):
			var canvas: CanvasLayer = page_bucket.get_child(index) as CanvasLayer
			for child: Node in canvas.get_children():
				if child is CanvasItem and (child as CanvasItem).is_visible_in_tree():
					return child == node
	return false








const PRESS_SCALE_RATIO: float = 0.9
const RELEASE_OVERSHOOT_RATIO: float = 1.03


const PRESS_OFFSET_Y: float = 0.0
const RELEASE_OVERSHOOT_OFFSET_Y: float = 0.0
const PRESS_DURATION: float = 4.0 / 60.0
const RELEASE_OVERSHOOT_DURATION: float = 8.0 / 60.0
const RELEASE_RECOVER_DURATION: float = 10.0 / 60.0
const _FEEDBACK_TWEEN_META: StringName = &"_ui_feedback_tween"
const _FEEDBACK_BASE_POS_META: StringName = &"_ui_feedback_base_pos"
const _FEEDBACK_ENABLED_META: StringName = &"_ui_feedback_enabled"
const _FEEDBACK_PRESS_ACTIVE_META: StringName = &"_ui_feedback_press_active"


func play_press_feedback(node: CanvasItem, base_scale: Vector2 = Vector2.ONE) -> void :
	if not is_instance_valid(node):
		return
	if not bool(node.get_meta(_FEEDBACK_ENABLED_META, true)):
		return

	if bool(node.get_meta(_FEEDBACK_PRESS_ACTIVE_META, false)):
		return


	var current_tween: Tween = null
	if node.has_meta(_FEEDBACK_TWEEN_META):
		current_tween = node.get_meta(_FEEDBACK_TWEEN_META) as Tween
	if current_tween != null and current_tween.is_valid() and current_tween.is_running():
		return
	node.set_meta(_FEEDBACK_PRESS_ACTIVE_META, true)
	_ensure_center_pivot(node)
	var base_pos: Vector2 = _resolve_feedback_base_pos(node)
	_kill_feedback_tween(node)
	var t: = node.create_tween()
	t.tween_property(node, "scale", base_scale * PRESS_SCALE_RATIO, PRESS_DURATION)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(node, "position:y", base_pos.y + PRESS_OFFSET_Y, PRESS_DURATION)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	node.set_meta(_FEEDBACK_TWEEN_META, t)


func play_release_feedback(node: CanvasItem, base_scale: Vector2 = Vector2.ONE) -> void :
	if not is_instance_valid(node):
		return
	if not bool(node.get_meta(_FEEDBACK_ENABLED_META, true)):
		return

	if not bool(node.get_meta(_FEEDBACK_PRESS_ACTIVE_META, false)):
		return
	node.set_meta(_FEEDBACK_PRESS_ACTIVE_META, false)
	_ensure_center_pivot(node)
	var base_pos: Vector2 = _resolve_feedback_base_pos(node)
	_kill_feedback_tween(node)
	var t: = node.create_tween()

	t.tween_property(node, "scale", base_scale * RELEASE_OVERSHOOT_RATIO, RELEASE_OVERSHOOT_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(node, "position:y", base_pos.y + RELEASE_OVERSHOOT_OFFSET_Y, RELEASE_OVERSHOOT_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	t.tween_property(node, "scale", base_scale, RELEASE_RECOVER_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(node, "position:y", base_pos.y, RELEASE_RECOVER_DURATION)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	node.set_meta(_FEEDBACK_TWEEN_META, t)








func _resolve_feedback_base_pos(node: CanvasItem) -> Vector2:
	if node.has_meta(_FEEDBACK_BASE_POS_META):
		return node.get_meta(_FEEDBACK_BASE_POS_META)
	var pos: = Vector2.ZERO
	if node is Control:
		pos = (node as Control).position
	elif node is Node2D:
		pos = (node as Node2D).position
	node.set_meta(_FEEDBACK_BASE_POS_META, pos)
	return pos




func bind_press_release_scale(button: BaseButton, base_scale: Vector2 = Vector2.ONE) -> void :
	if not is_instance_valid(button):
		return
	if button.has_meta(_FEEDBACK_BOUND_META):
		return
	button.set_meta(_FEEDBACK_BOUND_META, true)
	_ensure_center_pivot(button)
	button.button_down.connect( func() -> void : play_press_feedback(button, base_scale))
	button.button_up.connect( func() -> void : play_release_feedback(button, base_scale))




func set_button_feedback_enabled(button: BaseButton, enabled: bool) -> void :
	if not is_instance_valid(button):
		return
	button.set_meta(_FEEDBACK_ENABLED_META, enabled)
	if not enabled:
		reset_button_feedback(button)
	clear_button_feedback_baseline(button)




func reset_button_feedback(button: BaseButton, base_scale: Vector2 = Vector2.ONE) -> void :
	if not is_instance_valid(button):
		return
	_kill_feedback_tween(button)
	button.set_meta(_FEEDBACK_PRESS_ACTIVE_META, false)
	button.scale = base_scale
	if button.has_meta(_FEEDBACK_BASE_POS_META):
		button.position = button.get_meta(_FEEDBACK_BASE_POS_META) as Vector2
	var was_disabled: bool = button.disabled
	button.disabled = true
	button.set_pressed_no_signal(false)
	button.disabled = was_disabled
	button.release_focus()
	button.queue_redraw()





const _FEEDBACK_BOUND_META: StringName = &"_btn_feedback_bound"

func _attach_button_feedback(node: Node) -> void :
	if node is BaseButton:

		bind_press_release_scale(node as BaseButton)
	for child in node.get_children():
		_attach_button_feedback(child)



func attach_button_feedback(node: Node) -> void :
	_attach_button_feedback(node)






func claim_button_feedback(button: Node) -> void :
	if not is_instance_valid(button):
		return
	button.set_meta(_FEEDBACK_BOUND_META, true)






func clear_button_feedback_baseline(node: CanvasItem) -> void :
	if not is_instance_valid(node):
		return
	if node.has_meta(_FEEDBACK_BASE_POS_META):
		node.remove_meta(_FEEDBACK_BASE_POS_META)


func _ensure_center_pivot(node: CanvasItem) -> void :
	if node is Control:
		var ctrl: Control = node




		var s: Vector2 = ctrl.size
		if s.x > 0.0 and s.y > 0.0:
			ctrl.pivot_offset = s * 0.5

func _kill_feedback_tween(node: CanvasItem) -> void :
	if not node.has_meta(_FEEDBACK_TWEEN_META):
		return
	var t: Tween = node.get_meta(_FEEDBACK_TWEEN_META)
	if t and t.is_valid():
		t.kill()





const _INPUT_BLOCKER_NAME: StringName = &"_InputBlocker"

func block_input_briefly(target: Control, duration: float = 1.5) -> void :
	if target == null or duration <= 0.0:
		return
	var existing: = target.get_node_or_null(NodePath(_INPUT_BLOCKER_NAME))
	if existing != null:
		existing.queue_free()
	var blocker: = Control.new()
	blocker.name = _INPUT_BLOCKER_NAME
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP



	blocker.z_as_relative = true
	blocker.z_index = 1000
	target.add_child(blocker)
	target.get_tree().create_timer(duration).timeout.connect( func() -> void :
		if is_instance_valid(blocker):
			blocker.queue_free()
	)











const _SAFE_TOP_GROUP: StringName = &"_safe_top"
const _SAFE_BOTTOM_GROUP: StringName = &"_safe_bottom"
const _SAFE_TOP_BASELINE_META: StringName = &"_safe_top_baseline"
const _SAFE_BOTTOM_BASELINE_META: StringName = &"_safe_bottom_baseline"




const _SAFE_TOP_GROW_BOTTOM_GROUP: StringName = &"_safe_top_grow_bottom"
const _SAFE_TOP_GROW_BOTTOM_BASELINE_META: StringName = &"_safe_top_grow_bottom_baseline"





const _SAFE_BOTTOM_GROW_TOP_GROUP: StringName = &"_safe_bottom_grow_top"
const _SAFE_BOTTOM_GROW_TOP_BASELINE_META: StringName = &"_safe_bottom_grow_top_baseline"




const _COLLAPSE_WHEN_TOP_SAFE_GROUP: StringName = &"_collapse_when_top_safe"
const _COLLAPSE_BASELINE_META: StringName = &"_collapse_when_top_safe_baseline"



const _SAFE_AREA_PAGES: Array[StringName] = [
	&"home", 
	&"game", 
	&"rank", 
	&"rank_game_finish", 


]

func _apply_safe_area(page_name: String, node: Node) -> void :
	if not _SAFE_AREA_PAGES.has(StringName(page_name)):
		return



	var insets: Vector2 = UiMetrics.safe_insets()
	var top_inset: float = insets.x
	var bottom_inset: float = insets.y

	if top_inset <= 0.0 and bottom_inset <= 0.0 and page_name != "home":
		return
	for n in node.find_children("*", "Control", true, false):
		var c: = n as Control

		var is_absolute: bool = is_equal_approx(c.anchor_top, c.anchor_bottom)
		if c.is_in_group(_SAFE_TOP_GROUP):
			if not c.has_meta(_SAFE_TOP_BASELINE_META):
				c.set_meta(_SAFE_TOP_BASELINE_META, Vector2(c.offset_top, c.offset_bottom))
			var baseline: Vector2 = c.get_meta(_SAFE_TOP_BASELINE_META)
			c.offset_top = baseline.x + top_inset
			if is_absolute:
				c.offset_bottom = baseline.y + top_inset


		if c.is_in_group(_SAFE_TOP_GROW_BOTTOM_GROUP):







			if not c.has_meta(_SAFE_TOP_GROW_BOTTOM_BASELINE_META):
				c.set_meta(_SAFE_TOP_GROW_BOTTOM_BASELINE_META, c.offset_bottom - c.offset_top)
			var base_height: float = c.get_meta(_SAFE_TOP_GROW_BOTTOM_BASELINE_META)
			c.offset_bottom = c.offset_top + base_height + top_inset
		if c.is_in_group(_SAFE_BOTTOM_GROUP):
			if not c.has_meta(_SAFE_BOTTOM_BASELINE_META):
				c.set_meta(_SAFE_BOTTOM_BASELINE_META, Vector2(c.offset_top, c.offset_bottom))
			var baseline: Vector2 = c.get_meta(_SAFE_BOTTOM_BASELINE_META)
			c.offset_bottom = baseline.y - bottom_inset
			if is_absolute:
				c.offset_top = baseline.x - bottom_inset






		if c.is_in_group(_SAFE_BOTTOM_GROW_TOP_GROUP):
			if not c.has_meta(_SAFE_BOTTOM_GROW_TOP_BASELINE_META):
				c.set_meta(_SAFE_BOTTOM_GROW_TOP_BASELINE_META, c.offset_bottom - c.offset_top)
			var base_height: float = c.get_meta(_SAFE_BOTTOM_GROW_TOP_BASELINE_META)
			c.offset_top = c.offset_bottom - base_height - bottom_inset



		if c.is_in_group(_COLLAPSE_WHEN_TOP_SAFE_GROUP):
			if not c.has_meta(_COLLAPSE_BASELINE_META):

				c.set_meta(_COLLAPSE_BASELINE_META, 
					[c.visible, c.custom_minimum_size.y, c.size_flags_vertical])
			var baseline: Array = c.get_meta(_COLLAPSE_BASELINE_META)
			if top_inset > 0.0:
				c.visible = false
				c.custom_minimum_size.y = 0.0
				c.size_flags_vertical = 0
			else:
				c.visible = bool(baseline[0])
				c.custom_minimum_size.y = float(baseline[1])
				c.size_flags_vertical = int(baseline[2])
