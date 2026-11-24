class_name RatingManager
extends RefCounted




const _REVIEW_AFTER_COMPLETIONS: int = 5

const _ANDROID_PACKAGE: String = "com.oakever.sortparade"
const _IOS_CONFIG_PATH: String = "res://unikit_config.tres"



static func open_store_rating_page() -> void :
	if OS.has_feature("editor"):
		SceneManager.show_toast("Editor 中无法打开商店评分页")
		return
	if OS.has_feature("android"):
		var market_url: String = "market://details?id=%s" % _ANDROID_PACKAGE
		if OS.shell_open(market_url) != OK:
			OS.shell_open("https://play.google.com/store/apps/details?id=%s" % _ANDROID_PACKAGE)
	elif OS.has_feature("ios"):
		var config: UniKitConfig = load(_IOS_CONFIG_PATH) as UniKitConfig
		if config == null or config.ios == null or config.ios.app_store_id.is_empty():
			push_error("RatingManager: iOS App Store ID 未配置")
			return
		var review_url: String = "itms-apps://itunes.apple.com/app/id%s?action=write-review"\
		%config.ios.app_store_id
		if OS.shell_open(review_url) != OK:
			OS.shell_open("%s?action=write-review" % config.ios.app_store_url)



static func maybe_request_in_app_review() -> void :
	if UserState.get_completed_level_count() != _REVIEW_AFTER_COMPLETIONS\
	or UserState.has_sent_review_request():
		return
	if OS.has_feature("editor"):
		SceneManager.show_toast("Editor 中无法显示应用内评分弹窗")
		UserState.mark_review_request_sent()
		return
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		return
	if not NativeUtilManager.can_request_store_review():
		return

	UserState.mark_review_request_sent()
	if OS.has_feature("ios") and OS.is_debug_build():
		SceneManager.show_toast("Debug包无法提交评分")

		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		await tree.create_timer(0.5).timeout
	elif OS.has_feature("android") and OS.is_debug_build():
		SceneManager.show_toast("发起Google Play评分弹窗请求")

		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		await tree.create_timer(0.5).timeout
	NativeUtilManager.request_store_review()
