class_name OuterLoopBackdrop
extends Node




const Plan: = preload("res://scripts/gameplay/outer_loop/core/outer_loop_plan.gd")


const REVEAL_START_DELAY_SEC: float = 0.75


var background: TextureRect
var board: HexBoard
@export var default_bg: Texture2D



var _revealing: bool = false
var _progress_level: int = 0
var _generation: int = 0
var _title_chapter: int = 1
var _popup_title_chapter: int = 0

var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	_rng.randomize()



func setup(bg: TextureRect, hex_board: HexBoard) -> void :
	background = bg
	board = hex_board


func prepare_for_display(current_level: int, level_won: bool, active: Callable) -> bool:
	if not active.call():
		return false
	var p: = Plan.compute(current_level, level_won, LevelIndex.CHAPTER_SIZE)
	var bg_chapter: int = p.from_bg_chapter if p.mode == Plan.Mode.CROSS else p.bg_chapter
	var picture_chapter: int = p.from_bubble_chapter if p.mode == Plan.Mode.CROSS else p.bubble_chapter
	if bg_chapter > 1:
		await LevelManager.ensure_chapter_cover_async(bg_chapter, true, false, active)
	if not active.call():
		return false
	await LevelManager.ensure_chapter_cover_async(picture_chapter, false, true, active)
	if not active.call():
		return false
	if p.mode == Plan.Mode.CROSS:
		await LevelManager.ensure_chapter_cover_async(p.to_bg_chapter, true, false, active)
		if not active.call():
			return false
		await LevelManager.ensure_chapter_cover_async(p.to_bubble_chapter, false, true, active)
		if not active.call():
			return false
	var done: int = p.done if p.mode == Plan.Mode.STEADY else p.done_from if p.mode == Plan.Mode.RISE else p.from_done
	_apply_steady(bg_chapter, picture_chapter, done, false)
	return active.call()




func refresh(current_level: int, level_won: bool) -> void :
	if _revealing:
		return
	_revealing = true
	_progress_level = current_level
	_generation += 1
	var generation: int = _generation
	var p: = Plan.compute(current_level, level_won, LevelIndex.CHAPTER_SIZE)
	var bg_chapter: int = p.bg_chapter if p.mode != Plan.Mode.CROSS else p.from_bg_chapter

	_apply_steady(bg_chapter, 
		p.bubble_chapter if p.mode != Plan.Mode.CROSS else p.from_bubble_chapter, 
		p.done if p.mode == Plan.Mode.STEADY else p.done_from if p.mode == Plan.Mode.RISE else p.from_done)
	if bg_chapter > 1:
		await LevelManager.ensure_chapter_cover_async(bg_chapter, true, false, func() -> bool: return _is_active(generation))
	if not _is_active(generation):
		return
	await LevelManager.ensure_chapter_cover_async(p.bubble_chapter if p.mode != Plan.Mode.CROSS else p.from_bubble_chapter, false, true, func() -> bool: return _is_active(generation))
	if not _is_active(generation):
		return
	match p.mode:
		Plan.Mode.STEADY:
			_apply_steady(p.bg_chapter, p.bubble_chapter, p.done)
		Plan.Mode.RISE:
			_apply_steady(p.bg_chapter, p.bubble_chapter, p.done_from)
			await _play_reveals(p.bg_chapter, p.done_to, generation)
			if _is_active(generation):
				_sync_revealed(p.bg_chapter, p.done_to)
		Plan.Mode.CROSS:
			await _apply_cross(p, generation)
	if generation != _generation:
		return
	_revealing = false
	_progress_level = 0
	LevelManager.release_unused_chapter_textures(LevelIndex.chapter_of(current_level))
	_retry_missing_art(current_level, generation)



func _retry_missing_art(current_level: int, generation: int) -> void :
	var p: = Plan.compute(current_level, false, LevelIndex.CHAPTER_SIZE)
	while _is_active(generation) and (_background_texture(p.bg_chapter) == null\
	or LevelManager.load_local_texture(LevelManager.get_chapter_thumbnail_path(p.bubble_chapter)) == null):
		await get_tree().create_timer(LevelManager.UNAVAILABLE_RETRY_INTERVAL).timeout
		if not _is_active(generation):
			return
		if p.bg_chapter > 1:
			await LevelManager.ensure_chapter_cover_async(p.bg_chapter, true, false, func() -> bool: return _is_active(generation))
		if not _is_active(generation):
			return
		await LevelManager.ensure_chapter_cover_async(p.bubble_chapter, false, true, func() -> bool: return _is_active(generation))
		if not _is_active(generation):
			return
		_apply_steady(p.bg_chapter, p.bubble_chapter, p.done)


func cancel() -> void :
	_generation += 1
	_revealing = false
	if _progress_level > 0:

		var p: = Plan.compute(_progress_level, false, LevelIndex.CHAPTER_SIZE)
		if p.done == 0:

			UserState.commit_hex_board_revealed(p.bg_chapter, [])
		else:
			_sync_revealed(p.bg_chapter, p.done, false)
		_progress_level = 0
	if board != null:
		board.cancel_reveal()
	SceneManager.hide_dlg("new_scene")


func _is_active(generation: int) -> bool:
	return generation == _generation and background != null and background.is_visible_in_tree()



func refresh_titles() -> void :
	if board != null:
		board.set_title(tr("OUTER_LOOP_SCENE") % _title_chapter)
	var popup: Node = SceneManager.get_page("new_scene")
	if popup != null and popup.visible and _popup_title_chapter > 0:
		popup.set_title(LevelManager.get_chapter_title(_popup_title_chapter))



func _apply_steady(bg_ch: int, pic_ch: int, done: int, save_revealed: bool = true) -> void :
	_set_background(bg_ch)
	_set_picture(pic_ch)
	_sync_revealed(bg_ch, done, true, save_revealed)



func _set_background(bg_ch: int) -> void :
	_title_chapter = bg_ch
	refresh_titles()
	if background != null:
		var tex: Texture2D = _background_texture(bg_ch)
		background.texture = tex if tex != null else default_bg


func _set_picture(pic_ch: int) -> void :
	if board == null:
		return
	var tex: Texture2D = LevelManager.load_local_texture(LevelManager.get_chapter_thumbnail_path(pic_ch))

	board.visible = tex != null
	board.set_picture(tex)









func _sync_revealed(chapter: int, done: int, update_view: bool = true, save_revealed: bool = true) -> Array:
	var target: int = clampi(done, 0, HexBoard.CELL_COUNT)
	var revealed: Array = UserState.get_hex_board_revealed(chapter)
	var dirty: bool = false

	for i in range(revealed.size() - 1, -1, -1):
		var v: int = int(revealed[i])
		if v < 0 or v >= HexBoard.CELL_COUNT:
			revealed.remove_at(i)
			dirty = true
	if revealed.size() > target:
		revealed.resize(target)
		dirty = true


	if revealed.has(HexBoard.CENTER_CELL) and revealed.size() < HexBoard.CELL_COUNT:
		revealed.erase(HexBoard.CENTER_CELL)
		revealed.append(_pick_unrevealed(revealed))
		dirty = true
	while revealed.size() < target:
		revealed.append(_pick_unrevealed(revealed))
		dirty = true
	if dirty and save_revealed:
		UserState.commit_hex_board_revealed(chapter, revealed)
	if update_view and board != null:
		board.apply_revealed(revealed)
		board.set_progress(revealed.size(), HexBoard.CELL_COUNT)
	return revealed






func _play_reveals(chapter: int, to_done: int, generation: int) -> void :
	if board == null or not board.visible:
		return
	var revealed: Array = UserState.get_hex_board_revealed(chapter)
	var target: int = clampi(to_done, 0, HexBoard.CELL_COUNT)
	if revealed.size() >= target:
		return


	await get_tree().create_timer(REVEAL_START_DELAY_SEC).timeout
	while revealed.size() < target:
		if not _is_active(generation):
			return
		var idx: int = _pick_unrevealed(revealed)
		if idx < 0:
			break
		revealed.append(idx)
		UserState.commit_hex_board_revealed(chapter, revealed)
		await board.play_reveal(idx)
		if not _is_active(generation):
			return
		board.set_progress(revealed.size(), HexBoard.CELL_COUNT)







func _pick_unrevealed(revealed: Array) -> int:
	var pool: Array[int] = []
	for i in HexBoard.CELL_COUNT:
		if i == HexBoard.CENTER_CELL:
			continue
		if not revealed.has(i):
			pool.append(i)
	if pool.is_empty():

		return -1 if revealed.has(HexBoard.CENTER_CELL) else HexBoard.CENTER_CELL
	return pool[_rng.randi_range(0, pool.size() - 1)]



func _apply_cross(p: OuterLoopPlan, generation: int) -> void :
	_set_background(p.from_bg_chapter)
	_set_picture(p.from_bubble_chapter)
	_sync_revealed(p.from_bg_chapter, p.from_done)
	await _play_reveals(p.from_bg_chapter, HexBoard.CELL_COUNT, generation)
	if not _is_active(generation):
		return
	await LevelManager.ensure_chapter_cover_async(p.to_bg_chapter, true, false, func() -> bool: return _is_active(generation))
	if not _is_active(generation):
		return
	await LevelManager.ensure_chapter_cover_async(p.to_bubble_chapter, false, true, func() -> bool: return _is_active(generation))
	if not _is_active(generation):
		return
	var to_tex: Texture2D = _background_texture(p.to_bg_chapter)
	if to_tex == null or not board.visible:
		_apply_steady(p.to_bg_chapter, p.to_bubble_chapter, p.to_done)
		return
	await _run_new_scene_popup(p, to_tex, generation)



func _run_new_scene_popup(p: OuterLoopPlan, to_tex: Texture2D, generation: int) -> void :
	_popup_title_chapter = p.to_bg_chapter
	var hex_size: Vector2 = board.hex_outer_size()
	var page: NewScenePage = SceneManager.show_dlg("new_scene", {
		"image": to_tex, 
		"title": LevelManager.get_chapter_title(p.to_bg_chapter), 
		"origin": board.hex_center_global(), 
		"origin_diameter": hex_size.x, 
		"shape_aspect": hex_size.x / hex_size.y, 
	}) as NewScenePage
	if page == null:
		SortLogger.error("OuterLoopBackdrop: new_scene 页面缺失")
		_apply_steady(p.to_bg_chapter, p.to_bubble_chapter, p.to_done)
		return
	while _is_active(generation) and page.visible and not page.is_cover_opaque():
		await get_tree().process_frame
	if not _is_active(generation):
		return
	_apply_steady(p.to_bg_chapter, p.to_bubble_chapter, p.to_done)
	while _is_active(generation) and page.visible and not page.is_closed():
		await get_tree().process_frame
	if _is_active(generation):
		SceneManager.hide_dlg("new_scene")



func _bg_path(chapter: int) -> String:
	return LevelManager.get_chapter_image_path(chapter)



func _background_texture(chapter: int) -> Texture2D:
	if chapter == 1:
		return default_bg
	var path: String = _bg_path(chapter)
	return LevelManager.load_local_texture(path) if path != "" else null
