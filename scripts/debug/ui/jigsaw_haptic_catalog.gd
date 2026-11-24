class_name JigsawHapticCatalog
extends RefCounted

















const AHAP_DIR: String = "res://assets/haptic/"


const _SHOT_DEFAULT: Dictionary = {"type": "oneshot", "duration_msec": 25, "amplitude": 100}

const ENTRIES: Array[Dictionary] = [

	{"group": "拿起 / 落地", "name": "拿起牌·对照组（CardClickControl）", 
		"scene": "主玩法拖起一张牌，点击牌实验（click_card_ue）未命中实验组时", 
		"file": "card_click_control.json", "priority": 10, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "拿起 / 落地", "name": "拿起牌·实验组（CardClickExp）", 
		"scene": "主玩法拖起一张牌（click_card_ue 实验组）；迷你拼图点击牌也用它", 
		"file": "card_click_exp_v3.json", "priority": 10, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "拿起 / 落地", "name": "牌放置落地（CardPlace）", 
		"scene": "牌飞行结束、放回落点时（haptic_place 实验组）", 
		"file": "card_place.json", "priority": 8, 
		"android": {"type": "oneshot", "duration_msec": 25, "amplitude": 100}}, 


	{"group": "发牌翻面", "name": "发牌·普通关 Set1（CardDeal_NormalTypeOne）", 
		"scene": "普通关 NormalSet1 发牌动画翻面（haptic_deal 实验组）", 
		"file": "card_deal_normal_type_one.json", "priority": 10, 
		"android": {"type": "waveform", "timings_msec": [0, 80, 50, 200, 80, 200], "amplitudes": [0, 100, 0, 60, 0, 160]}}, 
	{"group": "发牌翻面", "name": "发牌·普通关 Set2/Set3（CardDeal_NormalTypeTwo）", 
		"scene": "普通关 NormalSet2 / Set3 发牌动画翻面（haptic_deal 实验组）", 
		"file": "card_deal_normal_type_two.json", "priority": 10, 
		"android": {"type": "waveform", "timings_msec": [0, 300, 80, 100], "amplitudes": [0, 100, 0, 100]}}, 
	{"group": "发牌翻面", "name": "发牌·Hard 关（CardDeal_HardTypeOne）", 
		"scene": "Hard 关发牌动画翻面（haptic_deal 实验组）", 
		"file": "card_deal_hard_type_one.json", "priority": 10, 
		"android": {"type": "waveform", "timings_msec": [0, 410, 80, 150, 200, 150], "amplitudes": [0, 60, 0, 100, 0, 100]}}, 
	{"group": "发牌翻面", "name": "发牌·SuperHard 关（CardDeal_SuperHardTypeOne）", 
		"scene": "SuperHard 关发牌动画翻面（haptic_deal 实验组）", 
		"file": "card_deal_super_hard_type_one.json", "priority": 10, 
		"android": {"type": "waveform", 
			"timings_msec": [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100], 
			"amplitudes": [0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 30]}}, 


	{"group": "Link / 连击", "name": "普通 link（Link）", 
		"scene": "两张牌拼接成功", 
		"file": "card_link_v2.json", "priority": 5, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "Link / 连击", "name": "点赞反馈（ThumbsUp）", 
		"scene": "触发点赞场景时", 
		"file": "card_link_v2.json", "priority": 10, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "Link / 连击", "name": "Smart 反馈（SmartMove）", 
		"scene": "迟疑 / 连续失败后成功连接（smart_move 实验），参数暂复用 link", 
		"file": "card_link_v2.json", "priority": 22, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "Link / 连击", "name": "迷你拼图 link（MiniPuzzleLink）", 
		"scene": "迷你拼图形成 link（mini_puzzle_ui 实验），复用 link", 
		"file": "card_link_v2.json", "priority": 15, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "Link / 连击", "name": "连击原版·第1次（ComboLink1）", 
		"scene": "连击第 1 次 link（combo_sound 实验组原版）", 
		"file": "card_link_v2.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 100, 80, 100], "amplitudes": [0, 30, 0, 30]}}, 
	{"group": "Link / 连击", "name": "连击原版·第2次（ComboLink2）", 
		"scene": "连击第 2 次 link", 
		"file": "card_link54_exp_level2.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 100, 80, 100], "amplitudes": [0, 50, 0, 50]}}, 
	{"group": "Link / 连击", "name": "连击原版·第3次起（ComboLink3）", 
		"scene": "连击第 3 次起 link，第 4 次起复用", 
		"file": "card_link54_exp_level3.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 100, 80, 100], "amplitudes": [0, 100, 0, 100]}}, 
	{"group": "Link / 连击", "name": "连击递进 V1·第1次（ComboV1Link1）", 
		"scene": "连击第 1 次 link，表现组 1（combo 震动递进 v2）", 
		"file": "combo_v1_level1.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 100, 80, 100], "amplitudes": [0, 40, 0, 20]}}, 
	{"group": "Link / 连击", "name": "连击递进 V1·第2次（ComboV1Link2）", 
		"scene": "连击第 2 次 link，表现组 1", 
		"file": "combo_v1_level2.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 200, 100, 150], "amplitudes": [0, 90, 0, 30]}}, 
	{"group": "Link / 连击", "name": "连击递进 V1·第3次起（ComboV1Link3）", 
		"scene": "连击第 3 次起 link，表现组 1", 
		"file": "combo_v1_level3.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 250, 100, 150], "amplitudes": [0, 180, 0, 100]}}, 
	{"group": "Link / 连击", "name": "连击递进 V2·第1次（ComboV2Link1）", 
		"scene": "连击第 1 次 link，表现组 2（Unity 线上已固化使用这一组）", 
		"file": "combo_v2_level1.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [0, 120, 80, 120], "amplitudes": [0, 40, 0, 20]}}, 
	{"group": "Link / 连击", "name": "连击递进 V2·第2次（ComboV2Link2）", 
		"scene": "连击第 2 次 link，表现组 2（线上固化）", 
		"file": "combo_v2_level2.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [150, 100, 150], "amplitudes": [150, 0, 150]}}, 
	{"group": "Link / 连击", "name": "连击递进 V2·第3次起（ComboV2Link3）", 
		"scene": "连击第 3 次起 link，表现组 2（线上固化）", 
		"file": "combo_v2_level3.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [200, 100, 200], "amplitudes": [200, 0, 150]}}, 
	{"group": "Link / 连击", "name": "连击递进 V3·第1次（ComboV3Link1）", 
		"scene": "连击第 1 次 link，表现组 3", 
		"file": "combo_v3_level1.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [200, 100, 100], "amplitudes": [40, 0, 20]}}, 
	{"group": "Link / 连击", "name": "连击递进 V3·第2次（ComboV3Link2）", 
		"scene": "连击第 2 次 link，表现组 3", 
		"file": "combo_v3_level2.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [200, 100, 200], "amplitudes": [90, 0, 40]}}, 
	{"group": "Link / 连击", "name": "连击递进 V3·第3次起（ComboV3Link3）", 
		"scene": "连击第 3 次起 link，表现组 3", 
		"file": "combo_v3_level3.json", "priority": 20, 
		"android": {"type": "waveform", "timings_msec": [200, 100, 200], "amplitudes": [200, 0, 150]}}, 


	{"group": "Double Combo", "name": "Double Combo V1（DoubleComboV1）", 
		"scene": "单次交换形成双 link（double_combo_vibration 实验组 1，两记等重）。Unity 代码里未找到直接调用点", 
		"file": "double_combo_v1.json", "priority": 25, 
		"android": {"type": "waveform", "timings_msec": [100, 80, 100], "amplitudes": [150, 0, 150]}}, 
	{"group": "Double Combo", "name": "Double Combo V2（DoubleComboV2）", 
		"scene": "同上，实验组 2（两记等重、更长更钝）", 
		"file": "double_combo_v2.json", "priority": 25, 
		"android": {"type": "waveform", "timings_msec": [120, 100, 120], "amplitudes": [120, 0, 120]}}, 
	{"group": "Double Combo", "name": "Double Combo V3（DoubleComboV3）", 
		"scene": "同上，实验组 3（前轻后重）", 
		"file": "double_combo_v3.json", "priority": 25, 
		"android": {"type": "waveform", "timings_msec": [100, 80, 100], "amplitudes": [100, 0, 180]}}, 


	{"group": "撒花", "name": "撒花·对照组（Confetti）", 
		"scene": "触发撒花场景（confetti_vibration 对照组，即「震动太小」的现状）", 
		"file": "confitte_v2.json", "priority": 30, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "撒花", "name": "撒花 V1（ConfettiV1）", 
		"scene": "触发撒花场景，实验组 1（单记 200ms，强度最弱）", 
		"file": "confetti_v1.json", "priority": 30, 
		"android": {"type": "waveform", "timings_msec": [0, 200], "amplitudes": [0, 100]}}, 
	{"group": "撒花", "name": "撒花 V2（ConfettiV2）", 
		"scene": "触发撒花场景，实验组 2", 
		"file": "confetti_v2.json", "priority": 30, 
		"android": {"type": "waveform", "timings_msec": [0, 200], "amplitudes": [0, 140]}}, 
	{"group": "撒花", "name": "撒花 V3（ConfettiV3）", 
		"scene": "触发撒花场景，实验组 3（强度最强）", 
		"file": "confetti_v3.json", "priority": 30, 
		"android": {"type": "waveform", "timings_msec": [0, 200], "amplitudes": [0, 180]}}, 


	{"group": "完局 / 结算", "name": "完局（GameFinish）", 
		"scene": "拼图完成、进入结算（vibration_up 实验组）；Android 无专属参数，Unity 里由 AHAP 的降级单发承担", 
		"file": "game_finish_back2.json", "priority": 50, 
		"android": {"type": "oneshot", "duration_msec": 150, "amplitude": 200}}, 
	{"group": "完局 / 结算", "name": "结算页弹出（GameFinishHapticExtraExp）", 
		"scene": "结算页面弹出（haptic_score 实验组），长约 1.1 秒", 
		"file": "game_finish_haptic_extra_exp.json", "priority": 50, 
		"android": {"type": "waveform", "timings_msec": [0, 1000, 100], "amplitudes": [0, 100, 60]}}, 
	{"group": "完局 / 结算", "name": "每日首次完局激励（DailyIncentiveWin）", 
		"scene": "每日首次完局，激励动效弹出、盖章（与 Spine 动画 + 音效同步）", 
		"file": "daily_incentive_win.json", "priority": 50, 
		"android": {"type": "waveform", "timings_msec": [0, 400, 100, 200, 0], "amplitudes": [0, 30, 0, 200, 0]}}, 
	{"group": "完局 / 结算", "name": "迷你拼图拼成一张图（MiniPuzzleMatch）", 
		"scene": "迷你拼图 2×2 拼成一张图、消除（mini_puzzle_ui 实验）", 
		"file": "mini_puzzle_match.json", "priority": 25, 
		"android": {"type": "waveform", "timings_msec": [300, 80, 100], "amplitudes": [100, 0, 80]}}, 
	{"group": "完局 / 结算", "name": "迷你拼图完局结算（MiniPuzzleFinish）", 
		"scene": "迷你拼图完局结算，复用完局震动", 
		"file": "game_finish_back2.json", "priority": 55, 
		"android": {"type": "oneshot", "duration_msec": 150, "amplitude": 200}}, 


	{"group": "连线玩法（LinkGame）", "name": "点击图案（LinkGameCardClick）", 
		"scene": "连线玩法点击图案、起线那一下", 
		"file": "link_game_card_click.json", "priority": 10, 
		"android": {"type": "waveform", "timings_msec": [100, 80, 100], "amplitudes": [80, 0, 60]}}, 
	{"group": "连线玩法（LinkGame）", "name": "拖动连线（LinkGameDrag）", 
		"scene": "拖动连线，手指每移动一段距离震一次（静止不触发），最轻、高频", 
		"file": "link_game_drag.json", "priority": 5, 
		"android": {"type": "oneshot", "duration_msec": 60, "amplitude": 60}}, 
	{"group": "连线玩法（LinkGame）", "name": "link 成功（LinkGameLink）", 
		"scene": "一组连通成功", 
		"file": "link_game_link.json", "priority": 15, 
		"android": {"type": "waveform", "timings_msec": [120, 80, 120], "amplitudes": [100, 0, 60]}}, 
	{"group": "连线玩法（LinkGame）", "name": "开局（LinkGameStart）", 
		"scene": "开局发题、棋盘出场", 
		"file": "link_game_start.json", "priority": 10, 
		"android": {"type": "waveform", "timings_msec": [150, 150, 150, 150, 50], "amplitudes": [100, 80, 60, 50, 0]}}, 
	{"group": "连线玩法（LinkGame）", "name": "完局（LinkGameFinish）", 
		"scene": "连线玩法完局，两记重击，总长约 1.85 秒", 
		"file": "link_game_finish.json", "priority": 55, 
		"android": {"type": "waveform", "timings_msec": [500, 1200, 150], "amplitudes": [100, 0, 200]}}, 
	{"group": "连线玩法（LinkGame）", "name": "碰撞（LinkGameCollide）", 
		"scene": "线撞到其他线 / 其他卡片，负反馈，短促偏重", 
		"file": "link_game_collide.json", "priority": 25, 
		"android": {"type": "waveform", "timings_msec": [120], "amplitudes": [120]}}, 


	{"group": "其他", "name": "Pinata 进度推进（PinataProgressAdvance）", 
		"scene": "Pinata 主页进度条推进（daily_task_optimization 实验），长约 0.8 秒", 
		"file": "pinata_progress.json", "priority": 10, 
		"android": {"type": "oneshot", "duration_msec": 500, "amplitude": 76}}, 
	{"group": "其他", "name": "排行榜元素收集（RankCollect）", 
		"scene": "局内排行榜元素收集", 
		"file": "rank_collect.json", "priority": 20, "android": _SHOT_DEFAULT, "android_default": true}, 
	{"group": "其他", "name": "默认·旧版等级一（Default）", 
		"scene": "无 AHAP 的老震动：Pinata 按钮点击（haptic_pinata）、完局对照组。iOS 在 Unity 里是单发 100，这里用 Core Haptics 瞬时事件近似", 
		"file": "", "priority": 0, "android": _SHOT_DEFAULT, 
		"ios": {"type": "transient", "intensity": 100.0 / 255.0, "sharpness": 0.5}}, 
]



static func profile_of(entry: Dictionary) -> Dictionary:
	var file: String = String(entry.get("file", ""))
	var ios: Dictionary = entry.get("ios", {})
	if ios.is_empty() and not file.is_empty():
		ios = {"type": "ahap", "file": AHAP_DIR + file}
	return {"android": entry.get("android", {}), "ios": ios}
