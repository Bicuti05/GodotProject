class_name InitializeUniKitStep
extends FlowStep






func get_step_name() -> String:
	return "InitializeUniKit"


func run(_ctx) -> void :

	NativeUtilManager.set_crashlytics_key("boot_step", "%s:load_config" % get_step_name())
	var cfg_path: = "res://unikit_config.tres"
	if not ResourceLoader.exists(cfg_path):
		SortLogger.error("[InitializeUniKitStep] %s 不存在，UniKit 无法 initialize" % cfg_path)
		return
	var cfg: = load(cfg_path) as UniKitConfig
	if cfg == null:
		SortLogger.error("[InitializeUniKitStep] %s 加载失败或类型不符，UniKit 无法 initialize" % cfg_path)
		return
	var plat_cfg = cfg.ios if OS.has_feature("ios") else cfg.android
	if plat_cfg == null:
		SortLogger.error("[InitializeUniKitStep] unikit_config.tres 当前平台子配置未创建，UniKit 无法 initialize")
		return

	var p: = UniKitInitParams.new()
	p.production_id = plat_cfg.production_id
	if cfg.ios != null:
		p.app_store_id = cfg.ios.app_store_id
		p.app_store_url = cfg.ios.app_store_url


	p.first_open_time_ms = NativeUtilManager.get_first_open_time_ms()
	p.is_debug = OS.is_debug_build()

	p.is_show_log = OS.is_debug_build() or OS.has_feature("pre")


	NativeUtilManager.set_crashlytics_key("boot_step", "%s:sdk_initialize" % get_step_name())
	SortLogger.info("[InitializeUniKitStep] 调用 UniKit.initialize(production_id=%s)" % p.production_id)
	UniKitManager.initialize(p)



	NativeUtilManager.set_crashlytics_key("boot_step", "%s:register_cmd_callback" % get_step_name())
	SortLogger.info("[InitializeUniKitStep] 调用 UniKit.register_cmd_callback()")
	AuthManager.register_cmd_callback()
	NativeUtilManager.set_crashlytics_key("boot_step", "%s:init_ab_for_editor" % get_step_name())

	ABManager.initialize_for_editor()
