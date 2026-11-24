extends CanvasLayer


const GAME_PAGE: PackedScene = preload("res://scripts/main/pages/game/juice_game_page.tscn")
var _page: JuiceGamePage
var _paused_before: bool = false
var _opened: bool = false
var _source_page: Variant = null
var _close_generation: int = 0
var _restore_pending: bool = false


func _ready() -> void :
	layer = SceneManager.Layer.DEBUG + 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	_page = GAME_PAGE.instantiate() as JuiceGamePage
	_page.play_mode = JuiceGamePage.PlayMode.ENDLESS
	_page.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_page)
	_page.endless_exit_requested.connect(close)
	SceneManager.attach_button_feedback(_page)


func open(run_seed: Variant = null) -> void :
	if OS.has_feature("rel") or _page.get("_prop_ad_in_flight"):
		return
	_close_generation += 1
	if not _opened:
		_paused_before = get_tree().paused
		_source_page = SceneManager.get_page("game")
		if is_instance_valid(_source_page) and _source_page.visible:
			_source_page.suspend_external_play()
	_opened = true
	get_tree().paused = true
	show()
	_page.show()
	_page.start_endless(run_seed)


func close() -> void :
	if not _opened:
		return
	_page.stop_endless()
	_page.hide()
	hide()
	_restore_pending = true
	if not _page.get("_prop_ad_in_flight"):
		_restore_source()
	_opened = false
	_close_generation += 1
	_release_after_tasks(_close_generation)


func _release_after_tasks(token: int) -> void :

	while token == _close_generation and is_instance_valid(_page):
		var controller: JuiceEndlessController = _page.get("_endless_controller")
		if not _page.get("_prop_ad_in_flight") and _page.get("_endless_start_count") == 0 and (controller == null or controller.get("_retired").is_empty()):
			await _page.finish_endless_resource_requests( func() -> bool: return token == _close_generation)
			if token != _close_generation:
				return
			_restore_source()
			queue_free()
			return
		await get_tree().process_frame


func _restore_source() -> void :
	if not _restore_pending:
		return
	get_tree().paused = _paused_before
	if is_instance_valid(_source_page) and _source_page.visible:
		_source_page.resume_external_play()
	_restore_pending = false


func _exit_tree() -> void :
	if _opened or _restore_pending:
		get_tree().paused = _paused_before
		if is_instance_valid(_source_page) and _source_page.visible:
			_source_page.resume_external_play()
