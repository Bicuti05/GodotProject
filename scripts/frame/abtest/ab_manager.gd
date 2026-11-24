extends Node




















signal init_done
signal params_updated(update_type: String, user_info: Dictionary)
signal locsrv_fetched(success: bool)
signal remote_config_ready



var _is_init_done: bool = false

var _startup_control_locked: bool = false
var _is_locsrv_fetched: bool = false






var allow_root_swapping: AllowRootSwappingConfig


var banner_unlock_level: BannerUnlockLevelConfig

var bgm_test: BgmTestConfig
var _bgm_scene_dyed: bool = false

var bonus_level2: BonusLevel2Config
var christmas_theme: ChristmasThemeConfig
var coin_bonus_level_rule: CoinBonusLevelRuleConfig
var _coin_bonus_level_dyed: bool = false

var cold_start_optimization: ColdStartOptimizationConfig
var combo_freq: ComboFreqConfig
var _combo_freq_dyed: bool = false

var combo_fullscreen_fx: ComboFullscreenFxConfig

var combo_sfx_style: ComboSfxStyleConfig
var _combo_sfx_style_dyed: bool = false

var complete_prop: CompletePropConfig

var complete_sfx_style: CompleteSfxStyleConfig
var _complete_sfx_style_dyed: bool = false
var daily_first_round_downgrade: DailyFirstRoundDowngradeConfig
var daily_first_win_checkin: DailyFirstWinCheckinConfig
var location_judge: LocationJudgeConfig
var difficulty_rule: DifficultyRuleConfig
var _difficulty_rule_dyed: bool = false
var error_animation: ErrorAnimationConfig
var finish_ad_reward: FinishAdRewardConfig
var _daily_first_win_checkin_dyed: bool = false
var game_data_2_0: GameData2Config
var game_enter_haptic: GameEnterHapticConfig
var _game_enter_haptic_dyed: bool = false
var hard_level_banner_style: HardLevelBannerStyleConfig
var _hard_level_banner_style_dyed: bool = false
var inter_cd_by_day: InterCdByDayConfig
var inter_protect_by_day: InterProtectByDayConfig
var inter_unlock_level: InterUnlockLevelConfig
var iq_data: IqDataConfig
var _iq_data_dyed: bool = false
var iq_score_boost: IqScoreBoostConfig
var _iq_score_boost_dyed: bool = false
var level_target_coins: LevelTargetCoinsConfig
var _level_target_coins_dyed: bool = false
var logo_design: LogoDesignConfig
var _logo_design_dyed: bool = false
var long_link: LongLinkConfig
var _long_link_dyed: bool = false
var main_btn: MainBtnConfig
var mainline_timed_endless: MainlineTimedEndlessConfig
var _mainline_timed_endless_dyed: bool = false
var mystery_auto_unlock: MysteryAutoUnlockConfig
var _mystery_auto_unlock_dyed: bool = false
var new_guide: NewGuideConfig
var _new_guide_dyed: bool = false
var rank_collectible_fx: RankCollectibleFxConfig
var _rank_collectible_activity_dyed: bool = false
var rank_unlock_timing: RankUnlockTimingConfig
var rank_update: RankUpdateConfig
var revive_prompt_style: RevivePromptStyleConfig
var same_color_flower_merge_sfx: SameColorFlowerMergeSfxConfig
var _same_color_flower_merge_sfx_dyed: bool = false
var same_color_highlight: SameColorHighlightConfig
var shake_v2: ShakeV2Config
var _shake_v2_dyed: bool = false
var sort_dead_return_to_safe_state: SortDeadReturnToSafeStateConfig
var sort_reveal_memory: SortRevealMemoryConfig
var sort_rope_capacity_knots: SortRopeCapacityKnotsConfig
var special_level2: SpecialLevel2Config
var special_theme: SpecialThemeConfig
var _special_theme_dyed: bool = false
var splash: SplashConfig
var _splash_dyed: bool = false
var splash_min_display_seconds: SplashMinDisplaySecondsConfig
var _splash_min_display_seconds_dyed: bool = false

var streak_banner: StreakBannerConfig
var _streak_banner_dyed: bool = false
var sunlight_gameplay: SunlightGameplayConfig
var _sunlight_gameplay_dyed: bool = false


var _configs_by_key: Dictionary = {}








const TIMING_APP_START: String = "app_start"
const TIMING_BGM_SCENE: String = "bgm_scene"

const TIMING_SPLASH_ENTER: String = "splash_enter"

const TIMING_BONUS_LEVEL: String = "bonus_level"
const TIMING_COIN_BONUS_LEVEL: String = "coin_bonus_level"

const TIMING_DAILY_FIRST_ROUND: String = "daily_first_round"
const TIMING_DAILY_FIRST_WIN_CHECKIN: String = "daily_first_win_checkin"

const TIMING_DIFFICULTY_RULE: String = "difficulty_rule"
const TIMING_ENTER_GAME: String = "enter_game"
const TIMING_NEW_GUIDE: String = "new_guide"

const TIMING_ENTER_SPLASH: String = "enter_splash"

const TIMING_GAME_ENTER_HAPTIC: String = "game_enter_haptic"

const TIMING_SHAKE_V2: String = "shake_v2"

const TIMING_IQ_SCORE_BOOST: String = "iq_score_boost"

const TIMING_IQ_DATA: String = "iq_data"
const TIMING_SUNLIGHT_GAMEPLAY: String = "sunlight_gameplay"
const TIMING_ENTER_HOME: String = "enter_home"
const TIMING_ENTER_RANK: String = "enter_rank"

const TIMING_RANK_COLLECTIBLE_ACTIVITY: String = "rank_collectible_activity"

const TIMING_HARD_LEVEL_BANNER_STYLE: String = "hard_level_banner_style"
const TIMING_FINISH_AD_REWARD: String = "finish_ad_reward"

const TIMING_GAME_DATA: String = "game_data"

const TIMING_LEVEL_TARGET_COINS: String = "level_target_coins"

const TIMING_MYSTERY_AUTO_UNLOCK: String = "mystery_auto_unlock"
const TIMING_MAINLINE_TIMED_ENDLESS: String = "mainline_timed_endless"

const TIMING_REVEAL_MEMORY: String = "reveal_memory"

const TIMING_COMBO_FREQ: String = "combo_freq"

const TIMING_COMBO_HAPTIC: String = "combo_haptic"
const TIMING_COMBO_SFX_STYLE: String = "combo_sfx_style"

const TIMING_COMPLETE_SFX_STYLE: String = "complete_sfx_style"
const TIMING_LOCATION_JUDGE: String = "location_judge"

const TIMING_LOGO_DESIGN: String = "logo_design"

const TIMING_LONG_LINK: String = "long_link"
const TIMING_ERROR_ANIMATION: String = "error_animation"

const TIMING_DEAD_RETURN_TO_SAFE: String = "dead_return_to_safe"


const TIMING_DEAD_REVIVE_PROMPT: String = "dead_revive_prompt"


const TIMING_SAME_COLOR_FLOWER_MERGE_SFX: String = "same_color_flower_merge_sfx"

const TIMING_SAME_COLOR_HIGHLIGHT: String = "same_color_highlight"

const TIMING_SPECIAL_LEVEL: String = "special_level"

const TIMING_SPECIAL_THEME: String = "special_theme"

const TIMING_STREAK_BANNER: String = "streak_banner"




func _ready() -> void :
	_register_configs()
	UniKit.abtest_module.abtest_ready.connect(_on_abtest_ready)
	UniKit.abtest_module.abtest_params_updated.connect(_on_abtest_params_updated)
	UniKit.abtest_module.abtest_locsrv_fetched.connect(_on_abtest_locsrv_fetched)
	UniKit.abtest_module.abtest_remote_config_ready.connect(_on_abtest_remote_config_ready)




func _register_configs() -> void :
	allow_root_swapping = AllowRootSwappingConfig.new()
	banner_unlock_level = BannerUnlockLevelConfig.new()
	bgm_test = BgmTestConfig.new()

	bonus_level2 = BonusLevel2Config.new()
	christmas_theme = ChristmasThemeConfig.new()
	coin_bonus_level_rule = CoinBonusLevelRuleConfig.new()
	cold_start_optimization = ColdStartOptimizationConfig.new()
	combo_freq = ComboFreqConfig.new()
	combo_fullscreen_fx = ComboFullscreenFxConfig.new()
	combo_sfx_style = ComboSfxStyleConfig.new()

	complete_prop = CompletePropConfig.new()
	complete_sfx_style = CompleteSfxStyleConfig.new()
	daily_first_round_downgrade = DailyFirstRoundDowngradeConfig.new()
	daily_first_win_checkin = DailyFirstWinCheckinConfig.new()
	location_judge = LocationJudgeConfig.new()
	difficulty_rule = DifficultyRuleConfig.new()
	error_animation = ErrorAnimationConfig.new()
	finish_ad_reward = FinishAdRewardConfig.new()
	game_data_2_0 = GameData2Config.new()
	game_enter_haptic = GameEnterHapticConfig.new()
	hard_level_banner_style = HardLevelBannerStyleConfig.new()
	inter_cd_by_day = InterCdByDayConfig.new()
	inter_protect_by_day = InterProtectByDayConfig.new()
	inter_unlock_level = InterUnlockLevelConfig.new()
	iq_data = IqDataConfig.new()
	iq_score_boost = IqScoreBoostConfig.new()
	level_target_coins = LevelTargetCoinsConfig.new()
	logo_design = LogoDesignConfig.new()
	long_link = LongLinkConfig.new()
	main_btn = MainBtnConfig.new()
	mainline_timed_endless = MainlineTimedEndlessConfig.new()
	mystery_auto_unlock = MysteryAutoUnlockConfig.new()
	new_guide = NewGuideConfig.new()
	rank_collectible_fx = RankCollectibleFxConfig.new()
	rank_unlock_timing = RankUnlockTimingConfig.new()
	rank_update = RankUpdateConfig.new()

	revive_prompt_style = RevivePromptStyleConfig.new()
	same_color_flower_merge_sfx = SameColorFlowerMergeSfxConfig.new()
	same_color_highlight = SameColorHighlightConfig.new()
	shake_v2 = ShakeV2Config.new()
	sort_dead_return_to_safe_state = SortDeadReturnToSafeStateConfig.new()
	sort_reveal_memory = SortRevealMemoryConfig.new()
	sort_rope_capacity_knots = SortRopeCapacityKnotsConfig.new()
	special_level2 = SpecialLevel2Config.new()
	special_theme = SpecialThemeConfig.new()
	splash = SplashConfig.new()
	splash_min_display_seconds = SplashMinDisplaySecondsConfig.new()
	streak_banner = StreakBannerConfig.new()
	sunlight_gameplay = SunlightGameplayConfig.new()


	for prop: Dictionary in get_property_list():
		if not (int(prop.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var member: Variant = get(prop.get("name", &""))
		if member is AbConfigBase:
			var cfg: AbConfigBase = member
			cfg.init_default()
			_configs_by_key[cfg.key] = cfg
	SortLogger.mark("注册 AB config 完成：(count=%d)" % _configs_by_key.size())

func _on_abtest_ready(_user_info: Dictionary) -> void :
	SortLogger.mark("AB 测初始化成功（abtest_ready 回调）")
	_complete_initialization()



func initialize_for_editor() -> void :
	if not OS.has_feature("editor") or OS.has_feature("android") or OS.has_feature("ios"):
		return
	SortLogger.mark("编辑器 AB 本地初始化")
	_complete_initialization()



func _complete_initialization() -> void :
	if _is_init_done or _startup_control_locked:
		return
	_is_init_done = true

	dye_at_app_start()
	init_done.emit()

func _on_abtest_params_updated(update_type: String, user_info: Dictionary) -> void :
	SortLogger.mark("AB 参数更新（abtest_params_updated 回调）：(update_type=%s)" % update_type)
	if _startup_control_locked:
		return
	_reload_ad_configs()
	params_updated.emit(update_type, user_info)


func _on_abtest_remote_config_ready() -> void :
	SortLogger.mark("AB 远端配置到达（abtest_remote_config_ready 回调）")
	if _startup_control_locked:
		return
	_reload_ad_configs()
	remote_config_ready.emit()



func _reload_ad_configs() -> void :
	if not _is_init_done or _startup_control_locked:
		return
	for cfg: AbConfigBase in [banner_unlock_level, inter_cd_by_day, inter_protect_by_day, inter_unlock_level]:
		cfg.reload_value()

func _on_abtest_locsrv_fetched(success: bool) -> void :
	if _startup_control_locked:
		return
	_is_locsrv_fetched = success
	SortLogger.mark("服务端分流拉取完成：(success=%s)" % success)
	locsrv_fetched.emit(success)





func await_ready(timeout_sec: float = 2.0) -> bool:
	if _startup_control_locked:
		return false
	if _is_init_done:
		return true
	var timer: SceneTreeTimer = get_tree().create_timer(timeout_sec)
	while not _is_init_done and timer.time_left > 0.0:
		await get_tree().process_frame
	if not _is_init_done:
		_startup_control_locked = true
		for cfg: AbConfigBase in _configs_by_key.values():
			cfg.init_default()
			cfg._value_loaded = true

		_is_init_done = true
		SortLogger.warn("启动 AB 等待超时，本次会话固定对照组，下次冷启动重新判断")
		return false
	return _is_init_done



func get_ab_string(key: String, default_value: String = "") -> String:
	SortLogger.mark("读取 AB 字符串：(key=%s, default=%s)" % [key, default_value])
	var value: String = default_value if _startup_control_locked else UniKit.abtest_module.get_ab_string(key, default_value)
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value

func get_ab_int(key: String, default_value: int = 0) -> int:
	SortLogger.mark("读取 AB 整数：(key=%s, default=%d)" % [key, default_value])
	var value: int = default_value if _startup_control_locked else UniKit.abtest_module.get_ab_int(key, default_value)
	SortLogger.mark("UniKit 返回：(%d)" % value)
	return value

func get_ab_float(key: String, default_value: float = 0.0) -> float:
	SortLogger.mark("读取 AB 浮点数：(key=%s, default=%f)" % [key, default_value])
	var value: float = default_value if _startup_control_locked else UniKit.abtest_module.get_ab_float(key, default_value)
	SortLogger.mark("UniKit 返回：(%f)" % value)
	return value




func dye_ab(key: String) -> void :
	SortLogger.mark("染色 AB 实验：(key=%s)" % key)
	if _startup_control_locked:
		return
	if key.is_empty():
		SortLogger.warn("dye_ab: 空 key，跳过染色")
		return

	UniKit.abtest_module.get_ab_string(key, "")
	UniKit.abtest_module.dye_ab(key)


func is_dyeing(key: String) -> bool:
	SortLogger.mark("查询 AB 实验是否已染色：(key=%s)" % key)
	var value: bool = UniKit.abtest_module.is_dyeing(key)
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value


func get_group_status(key: String) -> String:
	SortLogger.mark("查询 AB 实验分组状态：(key=%s)" % key)
	var value: String = UniKit.abtest_module.get_group_status(key)
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value


func get_experiment_value(key: String) -> Variant:
	SortLogger.mark("读取 AB 实验原始值：(key=%s)" % key)
	var value: Variant = null if _startup_control_locked else UniKit.abtest_module.get_experiment_value(key)
	SortLogger.mark("UniKit 返回：(%s)" % str(value))
	return value



func get_all_ab_experiments() -> Dictionary:
	SortLogger.mark("读取全部 AB 实验")
	var value: Dictionary = {} if _startup_control_locked else UniKit.abtest_module.get_all_ab_experiments()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(value))
	return value

func get_all_publish_ab_experiments() -> Dictionary:
	SortLogger.mark("读取全部已发布 AB 实验")
	var value: Dictionary = {} if _startup_control_locked else UniKit.abtest_module.get_all_publish_ab_experiments()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(value))
	return value

func get_ab_dyeing_tag() -> String:
	SortLogger.mark("读取 AB 染色标签")
	var value: String = UniKit.abtest_module.get_ab_dyeing_tag()
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value


func get_ab_dyeing_time(key: String) -> String:
	SortLogger.mark("读取 AB 实验染色时机：(key=%s)" % key)
	var value: String = "" if _startup_control_locked else UniKit.abtest_module.get_dyeing_time(key)
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value


func get_all_dyeing_times() -> Dictionary:
	SortLogger.mark("读取全部 AB 染色时机")
	var value: Dictionary = UniKit.abtest_module.get_all_dyeing_times()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(value))
	return value

func get_ab_all_tag() -> String:
	SortLogger.mark("读取 AB 全量标签")
	var value: String = UniKit.abtest_module.get_ab_all_tag()
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value

func get_ab_group_id() -> String:
	SortLogger.mark("读取 AB 分组 ID")
	var value: String = UniKit.abtest_module.get_ab_group_id()
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value

func get_ab_country() -> String:
	SortLogger.mark("读取 AB 国家")
	var value: String = UniKit.abtest_module.get_ab_country()
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value



func get_ab_locsrv(key: String, default_value: String = "") -> String:
	SortLogger.mark("读取服务端分流参数：(key=%s, default=%s)" % [key, default_value])
	var value: String = default_value if _startup_control_locked else UniKit.abtest_module.get_ab_locsrv_param(key, default_value)
	SortLogger.mark("UniKit 返回：(%s)" % value)
	return value

func get_all_ab_locsrv() -> Dictionary:
	SortLogger.mark("读取全部服务端分流参数")
	var value: Dictionary = {} if _startup_control_locked else UniKit.abtest_module.get_all_ab_locsrv_params()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(value))
	return value

func fetch_ab_locsrv() -> void :
	SortLogger.mark("拉取服务端分流结果")
	if _startup_control_locked:
		return
	UniKit.abtest_module.fetch_remote_ab_result()

func dye_ab_locsrv(key: String) -> void :
	SortLogger.mark("染色服务端分流实验：(key=%s)" % key)
	if _startup_control_locked:
		return
	UniKit.abtest_module.dye_ab_locsrv(key)

func dye_ab_locsrv_tag(tag: String) -> void :
	SortLogger.mark("按标签染色服务端分流：(tag=%s)" % tag)
	if _startup_control_locked:
		return
	UniKit.abtest_module.dye_ab_locsrv_tag(tag)

func set_ab_locsrv_all_tag(tags: Array[String]) -> void :
	SortLogger.mark("设置服务端分流全量标签：(tags=%s)" % [tags])
	UniKit.abtest_module.set_ab_locsrv_all_tag(tags)

func get_ab_user_info() -> Dictionary:
	SortLogger.mark("读取 AB 用户信息")
	var value: Dictionary = UniKit.abtest_module.get_ab_user_info()
	SortLogger.mark("UniKit 返回：(%s)" % JSON.stringify(value))
	return value





func set_ab_group_id(group_id: String) -> void :
	SortLogger.mark("写入 AB 分组 ID：(group_id=%s)" % group_id)
	UniKit.abtest_module.set_ab_group_id(group_id)

func set_ab_country(country: String) -> void :
	SortLogger.mark("写入 AB 国家：(country=%s)" % country)
	UniKit.abtest_module.set_ab_country(country)







const FLOW_DOMAIN_TAG_KEY: = "pm_flow_domain"
const FLOW_DOMAIN_DATA_KEY: = "pm_flow_domain_data"
const FLOW_DOMAIN_BASELINE: = "baseline"
const FLOW_DOMAIN_CHEAT_AUTO: = "auto"
const FLOW_DOMAIN_CHEAT_BASELINE: = "baseline"
const FLOW_DOMAIN_CHEAT_EXPERIMENT: = "experiment"
const FLOW_DOMAIN_CHEAT_PATH: = "user://flow_domain_cheat.json"




func read_sdk_flow_domain() -> String:
	SortLogger.mark("读取 SDK 流量域")
	var value: String = parse_flow_domain(UniKitManager.get_inner_tags())
	SortLogger.mark("流量域返回：(%s)" % value)
	return value


static func parse_flow_domain(inner: Dictionary) -> String:
	var raw: Variant = inner.get(FLOW_DOMAIN_TAG_KEY)
	var domain_map: Variant = inner.get(FLOW_DOMAIN_DATA_KEY)
	if domain_map is Dictionary and (domain_map as Dictionary).has(FLOW_DOMAIN_TAG_KEY):
		raw = (domain_map as Dictionary)[FLOW_DOMAIN_TAG_KEY]
	return (raw as String).strip_edges() if raw is String else ""


func is_sdk_baseline_domain() -> bool:
	return read_sdk_flow_domain() == FLOW_DOMAIN_BASELINE



func get_flow_domain_cheat_mode() -> String:
	if not FileAccess.file_exists(FLOW_DOMAIN_CHEAT_PATH):
		return FLOW_DOMAIN_CHEAT_AUTO
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLOW_DOMAIN_CHEAT_PATH))
	if not (parsed is Dictionary):
		return FLOW_DOMAIN_CHEAT_AUTO
	var mode: String = String((parsed as Dictionary).get("mode", FLOW_DOMAIN_CHEAT_AUTO)).strip_edges()
	if mode == FLOW_DOMAIN_CHEAT_BASELINE or mode == FLOW_DOMAIN_CHEAT_EXPERIMENT:
		return mode
	return FLOW_DOMAIN_CHEAT_AUTO


func set_flow_domain_cheat_mode(mode: String) -> void :
	var normalized: String = mode.strip_edges().to_lower()
	if normalized.is_empty() or normalized == FLOW_DOMAIN_CHEAT_AUTO:
		if FileAccess.file_exists(FLOW_DOMAIN_CHEAT_PATH):
			DirAccess.remove_absolute(FLOW_DOMAIN_CHEAT_PATH)
		SortLogger.mark("流量域 Cheat 覆盖：auto")
		return
	if normalized != FLOW_DOMAIN_CHEAT_BASELINE and normalized != FLOW_DOMAIN_CHEAT_EXPERIMENT:
		SortLogger.warn("set_flow_domain_cheat_mode: 非法 mode=%s，忽略" % mode)
		return
	var file: = FileAccess.open(FLOW_DOMAIN_CHEAT_PATH, FileAccess.WRITE)
	if file == null:
		SortLogger.error("set_flow_domain_cheat_mode: 无法写入 %s" % FLOW_DOMAIN_CHEAT_PATH)
		return
	file.store_string(JSON.stringify({"mode": normalized}))
	file.close()
	SortLogger.mark("流量域 Cheat 覆盖：%s（下次冷启动生效）" % normalized)




func is_ab_init_done() -> bool:
	return _is_init_done

func is_ab_locsrv_fetched() -> bool:
	return _is_locsrv_fetched



func get_all_configs() -> Array[AbConfigBase]:
	var out: Array[AbConfigBase] = []
	for cfg: AbConfigBase in _configs_by_key.values():
		out.append(cfg)
	return out

func find_config(key: String) -> AbConfigBase:
	return _configs_by_key.get(key, null) as AbConfigBase




















func dye_at_coin_bonus_level() -> void :
	if _coin_bonus_level_dyed or _startup_control_locked or not _is_init_done:
		return
	if not coin_bonus_level_rule.is_coin_bonus_enabled() and not coin_bonus_level_rule.is_control_group():
		return
	_dye_at_timing(TIMING_COIN_BONUS_LEVEL)
	_coin_bonus_level_dyed = true




func dye_at_combo_haptic() -> void :
	_dye_at_timing(TIMING_COMBO_HAPTIC)




func dye_at_combo_freq() -> void :
	if _combo_freq_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_COMBO_FREQ)
	_combo_freq_dyed = true




func dye_at_combo_sfx_style() -> void :
	if _combo_sfx_style_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_COMBO_SFX_STYLE)
	_combo_sfx_style_dyed = true




func dye_at_daily_first_round() -> void :
	_dye_at_timing(TIMING_DAILY_FIRST_ROUND)




func dye_at_new_guide() -> void :
	if _new_guide_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(new_guide.key):
		new_guide.load_value_silent()
	else:
		_dye_at_timing(TIMING_NEW_GUIDE)
	_new_guide_dyed = true



func dye_at_enter_game() -> void :
	_dye_at_timing(TIMING_ENTER_GAME)




func dye_at_enter_splash() -> void :
	if _splash_min_display_seconds_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_ENTER_SPLASH)
	_splash_min_display_seconds_dyed = true




func dye_at_iq_score_boost() -> void :
	if _iq_score_boost_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_IQ_SCORE_BOOST)
	_iq_score_boost_dyed = true





func dye_at_level_target_coins() -> void :
	if _level_target_coins_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(level_target_coins.key):
		level_target_coins.load_value_silent()
	else:
		_dye_at_timing(TIMING_LEVEL_TARGET_COINS)
	_level_target_coins_dyed = true


func dye_at_sunlight_gameplay() -> void :
	if _sunlight_gameplay_dyed or not is_ab_init_done():
		return
	_sunlight_gameplay_dyed = true
	_dye_at_timing(TIMING_SUNLIGHT_GAMEPLAY)



func dye_at_enter_home() -> void :
	_dye_at_timing(TIMING_ENTER_HOME)



func dye_at_finish_ad_reward() -> void :
	_dye_at_timing(TIMING_FINISH_AD_REWARD)




func dye_at_game_data() -> void :
	if not is_ab_init_done():
		return
	_dye_at_timing(TIMING_GAME_DATA)




func dye_at_iq_data() -> void :
	if _iq_data_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_IQ_DATA)
	_iq_data_dyed = true






func dye_at_hard_level_banner_style() -> void :
	if _hard_level_banner_style_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(hard_level_banner_style.key):
		hard_level_banner_style.load_value_silent()
	else:
		_dye_at_timing(TIMING_HARD_LEVEL_BANNER_STYLE)
	_hard_level_banner_style_dyed = true




func dye_at_reveal_memory() -> void :
	_dye_at_timing(TIMING_REVEAL_MEMORY)



func dye_at_dead_return_to_safe() -> void :
	_dye_at_timing(TIMING_DEAD_RETURN_TO_SAFE)




func dye_at_dead_revive_prompt() -> void :
	_dye_at_timing(TIMING_DEAD_REVIVE_PROMPT)




func dye_at_logo_design() -> void :
	if _logo_design_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_LOGO_DESIGN)
	_logo_design_dyed = true




func dye_at_splash_enter() -> void :
	if _splash_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(splash.key):
		splash.load_value_silent()
	else:
		_dye_at_timing(TIMING_SPLASH_ENTER)
	_splash_dyed = true




func dye_at_long_link() -> void :
	if _long_link_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_LONG_LINK)
	_long_link_dyed = true



func dye_at_mainline_timed_endless() -> void :
	if _mainline_timed_endless_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_MAINLINE_TIMED_ENDLESS)
	_mainline_timed_endless_dyed = true




func dye_at_mystery_auto_unlock() -> void :
	if _mystery_auto_unlock_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_MYSTERY_AUTO_UNLOCK)
	_mystery_auto_unlock_dyed = true



func dye_at_app_start() -> void :
	_dye_at_timing(TIMING_APP_START)




func dye_at_bgm_scene() -> void :
	if _bgm_scene_dyed or _startup_control_locked or not is_ab_init_done():
		return
	_dye_at_timing(TIMING_BGM_SCENE)
	_bgm_scene_dyed = true



func _dye_at_timing(t: String) -> void :
	if _startup_control_locked:
		return
	var count: int = 0
	for cfg: AbConfigBase in _configs_by_key.values():
		if cfg.timing == t:
			cfg.reload_value()
			count += 1
	SortLogger.mark("按染色时机刷新 config 完成：(timing=%s, count=%d)" % [t, count])



func dye_at_bonus_level() -> void :
	_dye_at_timing(TIMING_BONUS_LEVEL)



func dye_at_error_animation() -> void :
	_dye_at_timing(TIMING_ERROR_ANIMATION)



func dye_at_location_judge() -> void :
	_dye_at_timing(TIMING_LOCATION_JUDGE)




func dye_at_same_color_flower_merge_sfx() -> void :
	if _same_color_flower_merge_sfx_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(same_color_flower_merge_sfx.key):
		same_color_flower_merge_sfx.load_value_silent()
	else:
		_dye_at_timing(TIMING_SAME_COLOR_FLOWER_MERGE_SFX)
	_same_color_flower_merge_sfx_dyed = true



func dye_at_same_color_highlight() -> void :
	if not is_ab_init_done():
		return
	_dye_at_timing(TIMING_SAME_COLOR_HIGHLIGHT)



func dye_at_special_level() -> void :
	if not is_ab_init_done():
		return
	_dye_at_timing(TIMING_SPECIAL_LEVEL)




func dye_at_special_theme() -> void :
	if _special_theme_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_SPECIAL_THEME)
	_special_theme_dyed = true




func dye_at_streak_banner() -> void :
	if _streak_banner_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_STREAK_BANNER)
	_streak_banner_dyed = true



func dye_at_daily_first_win_checkin() -> void :
	if _daily_first_win_checkin_dyed or _startup_control_locked or not _is_init_done:
		return
	_dye_at_timing(TIMING_DAILY_FIRST_WIN_CHECKIN)
	_daily_first_win_checkin_dyed = true




func dye_at_difficulty_rule() -> void :
	if _difficulty_rule_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(difficulty_rule.key):
		difficulty_rule.load_value_silent()
	else:
		_dye_at_timing(TIMING_DIFFICULTY_RULE)
	_difficulty_rule_dyed = true




func dye_at_game_enter_haptic() -> void :
	if _game_enter_haptic_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(game_enter_haptic.key):
		game_enter_haptic.load_value_silent()
	else:
		_dye_at_timing(TIMING_GAME_ENTER_HAPTIC)
	_game_enter_haptic_dyed = true




func dye_at_shake_v2() -> void :
	if _shake_v2_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(shake_v2.key):
		shake_v2.load_value_silent()
	else:
		_dye_at_timing(TIMING_SHAKE_V2)
	_shake_v2_dyed = true




func dye_at_complete_sfx_style() -> void :
	if _complete_sfx_style_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(complete_sfx_style.key):
		complete_sfx_style.load_value_silent()
	else:
		_dye_at_timing(TIMING_COMPLETE_SFX_STYLE)
	_complete_sfx_style_dyed = true


func dye_at_enter_rank() -> void :
	if not is_ab_init_done():
		return
	_dye_at_timing(TIMING_ENTER_RANK)


func dye_at_rank_collectible_activity() -> void :
	if _rank_collectible_activity_dyed or _startup_control_locked or not _is_init_done:
		return
	if is_dyeing(rank_collectible_fx.key):
		rank_collectible_fx.load_value_silent()
	else:
		_dye_at_timing(TIMING_RANK_COLLECTIBLE_ACTIVITY)
	_rank_collectible_activity_dyed = true
