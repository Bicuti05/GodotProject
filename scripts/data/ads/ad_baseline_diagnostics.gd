class_name AdBaselineDiagnostics
extends RefCounted



static var _inter_requests: int = 0
static var _inter_started: int = 0
static var _inter_closed: int = 0
static var _banner_requests: int = 0
static var _banner_impressions: int = 0


static func enabled() -> bool:
	return OS.is_debug_build() and not OS.has_feature("rel")


static func _yes(value: bool) -> String:
	return "是" if value else "否"


static func _result(value: bool) -> String:
	return "满足" if value else "不满足"


static func _scene(position: String, stage: String) -> String:
	var name: String = "SDK回调（未提供展示场景）"
	match position:
		TrackingEvents.AD_POSITION_GAME_END:
			name = "通关后点击下一步"
		TrackingEvents.AD_POSITION_GAME_RESTART:
			name = "确认重开关卡"
		TrackingEvents.AD_POSITION_GAME_PAGE:
			name = "游戏页"
	var stages: Dictionary = {
		"startup_preload": "启动预加载", "game_enter_preload": "进关提前一关预加载", 
		"show_gate": "页面展示资格检查", "finish_gate": "通关插屏资格检查", 
		"restart_gate": "重开插屏资格检查", "level_start": "本局模型确定后的四参数检查", 
		"show": "展示前检查", "hide": "页面收起Banner", "sdk_callback": "SDK回调", 
		"config_ready": "启动配置就绪", "config_updated": "参数更新后的配置快照", 
	}
	return "%s／%s" % [name, str(stages.get(stage, stage))]


static func _counts() -> String:
	return "安装第%d天（安装当天为第0天）；累计成功完局=%d局，当天成功完局=%d局；业务累计插屏真实展示（GRT计数）=%d次；本进程插屏请求/开始/关闭=%d/%d/%d次，Banner请求/有效展示回调=%d/%d次（进程重启后这些诊断计数归零，Banner刷新或重复回调也计入回调数）" % [
		UserState.get_install_days(), UserState.get_completed_level_count(), 
		UserState.get_daily_completed_level_count(), UserState.get_grt_inter_show_count(), 
		_inter_requests, _inter_started, _inter_closed, _banner_requests, _banner_impressions]


static func _write(key: String, position: String, stage: String, message: String) -> void :
	if not enabled():
		return
	SortLogger.info("[AD_BASELINE] 参数=%s；场景=%s；%s；%s" % [key, _scene(position, stage), 
		message.replace("\n", "\\n").replace("\r", "\\r"), _counts()])


static func _config(snapshot: Dictionary, unit: String) -> String:
	return "当前配置=%s；来源=%s；当前生效值=%d%s；客户端兜底值=%d%s；匹配规则=%s；配置快照已读取或已被调试覆盖=%s" % [
		str(snapshot["raw"]), str(snapshot["source"]), int(snapshot["effective"]), unit, int(snapshot["fallback"]), unit, str(snapshot["rule"]), _yes(bool(snapshot["loaded"]))]


static func reason_text(reason: String) -> String:
	var reasons: Dictionary = {
		"load_already_requested": "已发起过Banner加载，本次不重复加载；不代表已有库存或已显示", 
		"debug_no_ads": "调试去广告开关已打开，本次不展示广告", 
		"ab_not_ready": "AB配置尚未初始化完成，本次不预加载Banner；下面仅为现有配置快照", 
		"unlock_threshold": "尚未达到广告解锁门槛", 
		"sdk_error": "SDK报告加载或展示错误；不能据此认定四个配置参数未生效", 
		"inventory_not_ready": "SDK库存检查不通过，本次没有请求播放，也不启动冷却", 
		"fullscreen_ad_busy": "其他全屏广告正在展示或激励结算中，本次不请求播放", 
		"cooldown": "插屏仍在冷却期，本次不展示", 
		"daily_protection": "当天额外保护尚未结束，本次不展示插屏", 
		"already_checked": "本次通关已检查过插屏，不重复检查或展示", 
		"page_hidden": "游戏页已隐藏，本次不展示插屏", 
		"finish_ad_busy": "完成页广告正在展示或结算，本次不展示插屏", 
		"ad_busy": "完成页或重开插屏正在处理，本次忽略重复重开确认", 
		"level_model_missing": "关卡模型缺失，无法判定本局展示资格", 
		"next_not_pressed": "尚未点击完成页下一步，本次不尝试插屏", 
		"show_already_requested": "页面已记录Banner展示请求，本次不重复请求；不代表真实显示成功", 
		"special_challenge": "当前是特殊挑战，页面规则禁止展示Banner；解锁参数通过也不能展示", 
		"row_limit": "本局盘面行数超出Banner允许范围，页面规则禁止展示", 
		"hidden_by_page": "页面主动收起并销毁Banner（离页、完成页或资格失效等），停止刷新", 
	}
	return str(reasons.get(reason, reason))



static func log_interstitial(position: String, context: Dictionary, cooldown: Dictionary, 
		blocked_reason: String = "") -> void :
	if not enabled():
		return
	var stage: String = str(context.get("stage", "show"))
	var day: int = UserState.get_install_days()
	var round_number: int = int(context.get("won_level", context.get("level_id", -1)))
	var after_completion: bool = bool(context.get("after_completion", stage == "finish_gate"))
	var unlocked: bool = UserState.is_interstitial_unlocked()
	var unlock: Dictionary = ABManager.inter_unlock_level.get_log_snapshot(day)
	var protect: Dictionary = ABManager.inter_protect_by_day.get_log_snapshot(day)
	var cd: Dictionary = ABManager.inter_cd_by_day.get_log_snapshot(day)
	var n: int = int(unlock["effective"])
	var unlock_ok: bool = unlocked or (round_number >= 0 and round_number > n)
	var unlock_result: String = _result(unlock_ok) if round_number >= 0 or unlocked else "本局关号未知，暂不判断"
	var unlock_rule: String = "本局关号=%d；未解锁时需本局关号>%d（第%d局仍不展示，第%d局才允许尝试）" % [round_number, n, n, n + 1]
	if round_number < 0:
		unlock_rule = "当前没有本局关号；未解锁时需本局关号>%d，累计完局数不替代本局关号" % n
	if unlocked:
		unlock_rule += "；已保存插屏解锁标记，忽略本参数门槛，直接放行"
	var suffix: String = "；本次门控未通过，后续未执行的步骤仅展示只读条件快照" if not blocked_reason.is_empty() else "；只表示此项条件，不能单独证明广告已展示"
	_write("inter_unlock_level", position, stage, "%s；已解锁=%s；%s；条件=%s%s" % [
		_config(unlock, "局"), _yes(unlocked), unlock_rule, unlock_result, suffix])
	var today: int = UserState.get_daily_completed_level_count()
	var protected: int = int(protect["effective"])
	var protect_ok: bool = protected <= 0 or (today > protected if after_completion else today >= protected)
	var protect_rule: String
	if day == 0:
		protect_rule = "当天成功完局=%d；安装第0天不启用每日额外保护，无需比较完局数，直接放行" % today
	elif protected <= 0:
		protect_rule = "当天成功完局=%d；保护值为0，无额外保护，无需比较完局数，直接放行" % today
	elif after_completion:
		protect_rule = "当天成功完局=%d；通关后计数已包含本局，需%d>%d（完成第%d局时仍保护，第%d局才允许尝试）" % [today, today, protected, protected, protected + 1]
	else:
		protect_rule = "当天已成功完局=%d；本局尚未完成时按开局/重开口径，需%d>=%d；重开不增加完局数" % [today, today, protected]
	_write("inter_protect_by_day", position, stage, "%s；%s；条件=%s%s；从无广告保护计数的旧版（如1.0.9）升级时，当天只计升级后成功完局；已有计数的存档继续沿用；跨天计数归零" % [
		_config(protect, "局"), protect_rule, _result(protect_ok), suffix])
	var cd_ok: bool = bool(cooldown["allowed"])
	log_cooldown(position, stage, cd, cooldown, suffix)
	var expected: String
	if stage == "level_start" or stage == "config_ready" or stage == "config_updated":
		expected = "本步骤仅查看当前条件快照，不请求插屏；插屏实际尝试只在通关点击下一步或确认重开时发生；快照总条件=%s" % (_result(unlock_ok and protect_ok and cd_ok) if round_number >= 0 or unlocked else "本局关号未知，暂不判断")
	elif not blocked_reason.is_empty():
		expected = "本次预期：不请求展示；原因：%s" % reason_text(blocked_reason)
	elif round_number < 0 and not unlocked:
		expected = "本次仅查看参数快照，缺少本局关号；实际展示在通关或重开时判断"
	elif not unlock_ok or not protect_ok or not cd_ok or UserState.is_debug_no_ads():
		expected = "本次条件快照仍有拦截，不应展示；请查看上面不满足的参数及调试去广告开关"
	else:
		expected = "本次条件快照允许尝试插屏；下一步仍需通过去广告开关、广告互斥和SDK库存检查；仅真实开始回调才能确认已展示"
	_write("interstitial", position, stage, "%s；调试去广告=%s" % [expected, _yes(UserState.is_debug_no_ads())])


static func log_cooldown(position: String, stage: String, snapshot: Dictionary, 
		cooldown: Dictionary, suffix: String = "") -> void :
	if not enabled():
		return
	var rule: String = "本进程尚未记录插屏关闭时间，首次尝试不受冷却拦截（进程重启不会恢复旧关闭时间）" if int(cooldown["last_closed_msec"]) < 0 else "距上次插屏关闭=%.3f秒；需间隔>=%.3f秒；还需等待=%.3f秒" % [
		float(cooldown["elapsed_msec"]) / 1000.0, float(cooldown["cooldown_msec"]) / 1000.0, 
		float(cooldown["remaining_msec"]) / 1000.0]
	_write("inter_cd_by_day", position, stage, "%s；%s；条件=%s%s；通关/重开共用冷却；无库存不启动冷却；真实展示并关闭后才记录起点；下次尝试按当时天数/配置再判断" % [
		_config(snapshot, "秒"), rule, _result(bool(cooldown["allowed"])), suffix])


static func log_banner(position: String, context: Dictionary, blocked_reason: String = "") -> void :
	if not enabled():
		return
	var stage: String = str(context.get("stage", "show_gate"))
	var snapshot: Dictionary = ABManager.banner_unlock_level.get_log_snapshot(UserState.get_install_days())
	var n: int = int(snapshot["effective"])
	var level_id: int = UserState.get_current_level() if stage.ends_with("preload") else int(context.get("level_id", -1))
	var check_level: int = level_id + 1 if stage == "game_enter_preload" else level_id
	var unlocked: bool = UserState.is_banner_unlocked()
	var allowed: bool = unlocked or (level_id >= 0 and check_level > n)
	var rule: String = "本局普通关关号=%d；未解锁时需关号>%d（第%d关不显示，第%d关起可显示）；累计成功完局数不参与解锁" % [level_id, n, n, n + 1]
	if level_id < 0:
		rule = "当前没有本局普通关关号；未解锁时需关号>%d，累计成功完局数不参与解锁" % n
	if stage == "game_enter_preload":
		rule = "普通关进度=%d，提前一关预加载使用%d+1=%d判断；需%d>%d；累计成功完局数不参与解锁；这里只加载，不展示、不写解锁标记" % [level_id, level_id, check_level, check_level, n]
	elif stage == "startup_preload":
		rule = "普通关进度=%d；启动预加载需%d>%d；累计成功完局数不参与解锁；只加载、不展示、不写解锁标记" % [level_id, check_level, n]
	if unlocked:
		rule += "；已保存Banner解锁标记，忽略本参数门槛，直接放行"
	var expected: String = "预期：本参数满足；还需普通关、盘面最多6行、去广告关闭等页面条件通过；请求SDK不等于已显示"
	if stage == "level_start" or stage == "config_ready" or stage == "config_updated":
		expected = "本步骤仅查看配置/页面条件快照，不据此确认Banner已请求或显示；正式展示资格和SDK请求见后续同场景日志"
	elif not allowed:
		expected = "预期：解锁条件不满足，本次不展示/不发起新的预加载"
	elif stage.ends_with("preload"):
		expected = "预期：解锁条件满足，仅允许预加载；不会在这个步骤显示Banner"
	if not blocked_reason.is_empty():
		expected = "本次实际处理：%s；参数条件只是快照，不代表已请求或显示Banner" % reason_text(blocked_reason)
	var page_result: String = "此步骤仅检查解锁参数，页面条件在正式展示前判断"
	if context.has("model_available"):
		var model_ok: bool = bool(context["model_available"])
		var special: bool = bool(context.get("special_challenge", false))
		var rows_ok: bool = int(context.get("max_rows", -1)) >= 0 and int(context.get("max_rows", -1)) <= 6
		var page_ok: bool = model_ok and not special and rows_ok and not UserState.is_debug_no_ads()
		page_result = "模型有效=%s，特殊挑战=%s，行数<=6=%s，去广告关闭=%s；页面条件=%s" % [
			_yes(model_ok), _yes(special), _yes(rows_ok), _yes( not UserState.is_debug_no_ads()), _result(page_ok)]
		if not page_ok:
			expected = "预期：页面条件不满足，即使解锁参数通过也不能展示Banner"
	_write("banner_unlock_level", position, stage, "%s；已解锁=%s；%s；参数条件=%s；%s；%s；调试去广告=%s；盘面行数=%s（上限6）" % [
		_config(snapshot, "关"), _yes(unlocked), rule, _result(allowed) if level_id >= 0 or unlocked else "本局关号未知，暂不判断", page_result, expected, 
		_yes(UserState.is_debug_no_ads()), str(context.get("max_rows", "此步骤未提供"))])



static func log_event(key: String, event: String, position: String, context: Dictionary = {}) -> void :
	if not enabled():
		return
	var text: String = ""
	match event:
		"inter_request":
			_inter_requests += 1
			text = "已向SDK发起插屏播放请求；还没有确认真实展示，接下来等待开始回调"
		"inter_started":
			_inter_started += 1
			text = "已收到本次插屏真实开始回调；此时才算真实展示，仍需等待关闭后启动冷却"
		"inter_closed":
			_inter_closed += 1
			text = "SDK插屏关闭回调已收到；冷却时间将在本次等待流程确认关闭后记录"
		"banner_request":
			_banner_requests += 1
			text = "已向SDK发起Banner展示请求；加载成功或请求返回都不代表已显示，需观察真实画面/有效展示回调"
		"banner_impression":
			_banner_impressions += 1
			text = "收到SDK的Banner有效展示回调；这是回调次数，包含Banner刷新及重复回调，不是独立展示次数"
		"inventory_ready":
			text = "SDK插屏库存检查通过；仍需广告互斥检查，尚未请求播放"
		"preload_requested":
			text = "已发起Banner预加载请求；本步骤不显示Banner，也不写解锁标记"
		"loaded":
			text = "SDK广告加载成功回调已收到；仅代表加载成功，不代表已经展示"
		"cooldown_started":
			text = "本次插屏已确认关闭并记录冷却起点；关闭时间戳=%s毫秒；从现在起按当前安装天数配置限制下一次插屏" % str(context.get("last_closed_msec", -1))
		"not_shown":
			text = "本次插屏未完成真实展示，未更新冷却时间；详细拦截/SDK原因见同场景前面的日志"
		_:
			text = reason_text(event)
	if context.has("message"):
		text += "；SDK错误内容=%s（回调未提供展示ID时不猜测归属）" % str(context["message"])
	if context.has("ad_show_id"):
		text += "；本次SDK展示ID=%s" % str(context["ad_show_id"])
	_write(key, position, str(context.get("stage", "sdk_callback")), text)
