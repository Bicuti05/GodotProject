class_name BgmSceneController
extends RefCounted


var _splash_finished: bool = false
var _selected_music_id: StringName = &""


func initialize() -> void :
	SceneManager.top_fullscreen_page_changed.connect(_on_top_fullscreen_page_changed)
	ABManager.init_done.connect(_on_ab_ready)
	AdManager.fullscreen_ad_active_changed.connect(_on_fullscreen_ad_active_changed)


func on_splash_finished() -> void :
	if _splash_finished:
		return
	_splash_finished = true
	_sync_music_selection()


func _on_top_fullscreen_page_changed(_route: String) -> void :
	_sync_music_selection()


func _sync_music_selection() -> void :
	if not _splash_finished:
		return

	ABManager.dye_at_bgm_scene()
	var id: StringName = ABManager.bgm_test.get_music_id()
	if id != _selected_music_id:
		_selected_music_id = id
		if id == &"":
			AudioManager.stop_music(0.0)
		else:
			AudioManager.play_music(id)


func _on_ab_ready() -> void :
	_sync_music_selection()


func _on_fullscreen_ad_active_changed(active: bool) -> void :
	if active:
		AudioManager.pause_music(&"fullscreen_ad")
	else:
		AudioManager.resume_music(&"fullscreen_ad")
