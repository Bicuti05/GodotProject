



extends Node

var _command_defs: Array = []

func _ready() -> void :






	_command_defs = [

		{"name": "win_round", "label": "完成当前局", "desc": "普通关立即通关，走真实的数据提交与判胜流程；无尽关按当前已收盆数触发时间到结束，正式无尽走正常领奖，Debug试玩只显示结束结果。入场或飞盆未完成时不执行。\n参数：无。", "category": "游戏", "section": "通用", "version": "1.0.0"}, 

		{"name": "complete_column", "label": "完成一列", "desc": "复用「完成一列」（魔法棒）道具的盘面效果：按屏幕顺序逐列调配花朵凑满彩盆，杂色随机飞到其他未锁列，同色汇满后走真实收盆，成功后清空撤销历史。\n常规方案全部会导致死局时，改用同色问号揭色兜底；仍全部致死时执行第一个方案。不使用锁列；允许在死局中使用。不消耗道具免费次数/库存/金币，也不计入本局道具用量。\n参数：无。", "category": "游戏", "section": "通用", "version": "1.0.6"}, 
		{"name": "last_cup", "label": "最后一步", "desc": "把当前盘面布置成「只差最后一步」，再拖一次即可通关。\n参数：无。", "category": "游戏", "section": "通用", "version": "1.0.1"}, 

		{"name": "sort_die", "label": "强制死亡", "desc": "直接触发死局 Toast；留空按实际盘面撤回一步后能否通关进行归因，无历史或搜索超预算为未知。不检查当前盘面是否真的已死，非法参数不触发。\n参数：留空=实际计算 / 1=刚才一步 / 2=更早已死 / 3=未知。", "category": "游戏", "section": "通用", "version": "1.0.0"}, 
		{"name": "level", "label": "跳到第n关", "desc": "跳到指定关卡并重进游戏页，同时关闭所有弹窗。\n参数：关号 n，小于 1 按 1 处理，默认 1。", "default_args": "1", "category": "游戏", "section": "通用", "version": "1.0.0", "handler": _cmd_level}, 


		{"name": "living_days", "label": "设置living_days", "desc": "覆盖安装天数 living_days（0-based，安装当天=0），同时影响 GRT 求值与 Banner 广告展示条件等所有读安装天数的地方；-1 恢复真实值。Banner 需设置后重进游戏页（如 level 21）才重新判断。\n参数：天数，默认填入当前 living_days；留空恢复真实值。", "default_args_provider": func() -> String: return str(UserState.get_install_days()), "category": "游戏", "section": "通用", "version": "1.0.8", "handler": _cmd_living_days}, 


		{"name": "locale", "label": "英语", "desc": "切换界面语言为英语，仅本次进程生效。\n参数：locale 代码 en。", "default_args": "en", "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 
		{"name": "locale", "label": "德语", "desc": "切换界面语言为德语，仅本次进程生效。\n参数：locale 代码 de。", "default_args": "de", "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 
		{"name": "locale", "label": "俄语", "desc": "切换界面语言为俄语，仅本次进程生效。\n参数：locale 代码 ru。", "default_args": "ru", "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 
		{"name": "locale", "label": "泰语", "desc": "切换界面语言为泰语，仅本次进程生效。\n参数：locale 代码 th。", "default_args": "th", "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 
		{"name": "locale", "label": "葡萄牙语", "desc": "切换界面语言为葡萄牙语（巴西），仅本次进程生效。\n参数：locale 代码 pt_BR。", "default_args": "pt_BR", "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 

		{"name": "locale", "label": "其他", "desc": "切换界面语言为其他受支持语言：命令框已填入当前 locale 代码，改成目标代码后执行，仅本次进程生效。\n支持的语言（按中文音序）：pl 波兰语 / de 德语 / ru 俄语 / fr 法语 / zh_TW 繁体中文 / fil 菲律宾语 / fi 芬兰语 / ko 韩语 / nl 荷兰语 / zh_CN 简体中文 / ro 罗马尼亚语 / ms 马来语 / bn 孟加拉语 / nb 挪威语 / pt_BR 葡萄牙语 / ja 日语 / sv 瑞典语 / th 泰语 / ta 泰米尔语 / tr 土耳其语 / ur 乌尔都语 / uk 乌克兰语 / es 西班牙语 / el 希腊语 / hu 匈牙利语 / it 意大利语 / en 英语 / id 印尼语 / vi 越南语。", "default_args_provider": func() -> String: return TranslationServer.get_locale(), "category": "游戏", "section": "切换语言", "version": "1.0.10", "handler": _cmd_locale}, 

		{"name": "skin", "label": "皮肤切换", "desc": "整套换皮肤，空缺项逐项回退默认。仅进程内生效，不改存档。参数：list / use <已登记ID> / inspect。当前只有 default。盘面空闲且引导结束时使用。", "default_args": "inspect", "category": "游戏", "section": "皮肤", "version": "1.0.8"}, 

		{"name": "rank_debug", "label": "排行榜调试面板", "desc": "调积分、段位、倒计时及预览页面。完成第20关后使用。", "category": "游戏", "section": "排行榜", "version": "1.0.7", "handler": _cmd_rank_debug}, 
		{"name": "rank_score", "label": "调整排行积分", "desc": "当前赛季积分增量，可为负数。", "default_args": "100", "category": "游戏", "section": "排行榜", "version": "1.0.7", "handler": _cmd_rank_score}, 
		{"name": "rank_collect", "label": "设置排行收集数", "desc": "将当前赛季收集数直接设为指定整数，负数按0处理。", "default_args": "100", "category": "游戏", "section": "排行榜", "version": "1.0.7", "handler": _cmd_rank_collect}, 
		{"name": "rank_tier", "label": "设置排行段位", "desc": "当前赛季段位，1～7。", "default_args": "2", "category": "游戏", "section": "排行榜", "version": "1.0.7", "handler": _cmd_rank_tier}, 
		{"name": "rank_countdown", "label": "排行赛季倒计时", "desc": "设定剩余秒数；在首页观察自动结算。", "default_args": "5", "category": "游戏", "section": "排行榜", "version": "1.0.7", "handler": _cmd_rank_countdown}, 

		{"name": "mystery_auto_unlock_test", "label": "问号自动解开测试", "desc": "进入两盆起局的最小问号测试盘面。把白盆花串末尾单朵花拖入同色盆，收掉第一盆后仍有两个问号，沿当前AB组检查染色与自动解开；揭色后仍需合并最后一盆。\n会替换当前关题面（至少第2关）并清除该关残局，可用「撤销关卡 JSON」恢复；不覆盖AB分组、不重置首次染色记录。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.10", "handler": _cmd_mystery_auto_unlock_test}, 
		{"name": "juice_endless", "label": "无尽模式", "desc": "复用正式游戏页进入限时无尽试玩：容量5、20朵花、后台预备5列补货。2分钟，每盆加3秒，顶部只显示盆数和时间条；绳子隐藏，Hint/Undo真实消耗库存或金币。暂停来源页，退出恢复；不发奖励或推进主线。\n参数：留空=随机开局、重开换题；整数=固定种子复现；off=关闭。", "category": "游戏", "section": "关卡", "version": "1.0.9", "handler": _cmd_juice_endless}, 
		{"name": "special_challenge_previous", "label": "特殊挑战前一关", "desc": "跳到当前附近的挑战前置关（27、37、47…），通关后自然进入特殊挑战。已有未完成挑战时回到它的前置关并重置盘面；待领奖时请先领取。金币、道具与已完成挑战数不变。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.6", "handler": _cmd_special_challenge_previous}, 
		{"name": "next_hard", "label": "下一关强制困难关", "desc": "把「当前关号 +1」的下一关临时设为 Hard 难度；仅本次进程生效，不改题面、进度和关卡源。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.1", "handler": _cmd_next_hard}, 
		{"name": "next_super_hard", "label": "下一关强制超级困难关", "desc": "把「当前关号 +1」的下一关临时设为 SuperHard（超级困难关）；仅本次进程生效，不改题面、进度和关卡源。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.4", "handler": _cmd_next_super_hard}, 
		{"name": "eight_columns", "label": "打开 8 列测试关", "desc": "打开 8 列适配测试关：先以 7 列开局，起局完成后用真实加绳逻辑扩出空的第 8 列。\n参数：花朵行数 3~8，默认 5。", "default_args": "5", "category": "游戏", "section": "关卡", "version": "1.0.1", "handler": _cmd_eight_columns}, 
		{"name": "long_rope", "label": "打开长绳关样例", "desc": "打开长绳关样例：容量 8~10、每色正好一盆、开局全部花朵在场（没有补货），只靠 1 个白盆周转；规则同主玩法，列满即种盆。道具栏下移、盘面加长。1~2 = 4色容量8，3~4 = 5色容量8，5 = 4色容量9，6 = 4色容量10。\n参数：样例编号 1~6，默认 1。", "default_args": "1", "category": "游戏", "section": "关卡", "version": "1.0.6", "handler": _cmd_long_rope}, 
		{"name": "challenge_time", "label": "Challenge 测试盘面", "desc": "打开第 n 个 Challenge 测试盘面，进关后按 toast 提示走一步即触发分类日志；不自动弹飘屏。\n参数：用例号 1~%d（1~3 陷阱点，4~7 妙手点），默认 1。" % JuiceDebugLevel.CHALLENGE_CASES.CASES.size(), "default_args": "1", "category": "游戏", "section": "关卡", "version": "1.0.2", "handler": _cmd_challenge_time}, 
		{"name": "juice_json_off", "label": "撤销关卡 JSON", "desc": "撤掉已灌入的关卡 JSON，那一关回到关卡表。\n灌入方式：把整段关卡 JSON 直接粘进输入框执行，不用敲命令名。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.0", "handler": _cmd_juice_json_off}, 
		{"name": "sunlight_pot_level", "label": "新版冰冻花盆", "desc": "开启阳光解冻花盆实验，撤销旧调试题面、清除目标关续局并进入正式新局；收集第一盆阳光后冰壳碎开。\n参数：实验关号，默认42；仅支持固定投放关号，题面须匹配正式配方。其他关卡存档不清除。", "default_args": "42", "category": "游戏", "section": "关卡", "version": "1.0.9", "handler": _cmd_sunlight_pot_level}, 
		{"name": "flow_domain", "label": "流量域覆盖", "desc": "覆盖关卡章节渠道用的流量域（baseline→基线章批次；其余→default 章批次 + content_sg）。仅下次冷启动生效；非关卡 AB 仍跟 SDK。\n参数：auto=取消覆盖 / baseline / experiment；留空打印当前覆盖与 SDK 值。", "default_args": "baseline", "category": "游戏", "section": "关卡", "version": "1.0.9", "handler": _cmd_flow_domain}, 

		{"name": "bonus_start_test", "label": "金猪开局测试关", "desc": "开局保证有金猪和静态金币，真实操作验证收集/砸猪。会装载调试题面并清当前关快照；off恢复关卡表。", "default_args": "on", "category": "游戏", "section": "关卡", "version": "1.0.6", "handler": _cmd_bonus_start_test}, 
		{"name": "bonus_level", "label": "正式 Bonus 关测试", "desc": "on 重开为正式金币金猪关，off重开普通局；会改变当前关存档，用于正式链路验证。", "default_args": "on", "category": "游戏", "section": "关卡", "version": "1.0.6"}, 
		{"name": "csv_levels", "label": "导入测试题库", "desc": "仅编辑器：可直接将单个CSV文件拖入独立游戏窗口，无需打开面板；嵌入运行视图需先切为独立窗口。导入后进入表内第一关，每次新开局按当前能力自动选题。清除旧/新题库覆盖关号的残局，第1关跳过教学；通关、道具、能力结算会更新开发存档。表外关号使用正式题库。\n参数：留空=选择文件；也可直接填写CSV完整路径。", "category": "游戏", "section": "关卡", "version": "1.0.10", "handler": _cmd_csv_levels}, 
		{"name": "csv_levels_info", "label": "查看测试题库", "desc": "显示测试题库、覆盖关号、能力档及正在玩的题的实际分组与ID。可用level跳关、user_level切换能力；表内没有对应能力组时回落default。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.10", "handler": _cmd_csv_levels_info}, 
		{"name": "csv_levels_off", "label": "结束题库测试", "desc": "撤销CSV题库覆盖，清除测试关残局并回首页，恢复正式题库；取消尚未完成的导入。进度、能力与经济数据保留，重启后题库覆盖也会失效。\n参数：无。", "category": "游戏", "section": "关卡", "version": "1.0.10", "handler": _cmd_csv_levels_off}, 

		{"name": "props", "label": "设置所有道具数", "desc": "把提示 / 撤回 / 加绳三种道具库存都设置为指定数量，并立即刷新道具按钮。\n参数：道具数量，小于 0 按 0 处理，默认 99。", "default_args": "99", "category": "游戏", "section": "玩家数据", "version": "1.0.0", "handler": _cmd_props}, 
		{"name": "coins", "label": "设置金币数", "desc": "把金币设置为指定数值并保存，立即刷新游戏页与首页。可用 9999 / 10000 / 99999 对比 IQ 实验下的金币布局。\n参数：非负整数，默认 99999。", "default_args": "99999", "category": "游戏", "section": "玩家数据", "version": "1.0.0", "handler": _cmd_coins}, 
		{"name": "no_ads", "label": "去除广告", "desc": "插屏直接跳过、激励广告直接发奖；跨重启保留，release 包无效。\n参数：留空=切换开关；on=开启；off=关闭。", "default_args": "", "category": "游戏", "section": "玩家数据", "version": "1.0.1", "handler": _cmd_no_ads}, 
		{"name": "clear", "label": "清除全部数据", "desc": "清空玩家存档、关卡进度（SQLite）与章节元数据缓存，然后直接退出进程，需手动重启。\n参数：无。", "category": "游戏", "section": "玩家数据", "version": "1.0.0", "handler": _cmd_clear}, 

		{"name": "grt_state", "label": "显示 GRT 状态", "desc": "打印 living_days、累计通关、插屏/激励计数、LTV、各 batch anchor 与已发送数量。\n参数：无。", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_state}, 
		{"name": "grt_hours", "label": "设置 GRT 首开后小时", "desc": "覆盖 24h 窗口用的“首次打开后 elapsed 小时”，-1 恢复真实首开时间。\n参数：小时数，默认 1。", "default_args": "1", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_hours}, 
		{"name": "grt_level", "label": "设置 GRT 累计通关数", "desc": "覆盖 GRT 求值用的累计主线通关数，-1 恢复真实值。\n参数：通关数，默认 3。", "default_args": "3", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_level}, 
		{"name": "grt_inter", "label": "设置插屏展示数", "desc": "直接设置 GRT 的插屏累计展示数并立即求值。\n参数：次数，默认 0。", "default_args": "0", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_inter}, 
		{"name": "grt_reward", "label": "设置激励展示数", "desc": "直接设置 GRT 的激励累计展示数并立即求值。\n参数：次数，默认 0。", "default_args": "0", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_reward}, 
		{"name": "grt_ltv", "label": "设置 GRT LTV", "desc": "直接注入 LTV（美元）并立即求值；同时写入编辑器 mock 值。\n参数：LTV 数值，默认 0.015。", "default_args": "0.015", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_ltv}, 
		{"name": "grt_anchor", "label": "设置 GRT anchor", "desc": "设置某个 batch 的新装 anchor：0=未评估，1=老用户，2=新装。\n参数：batch_id（默认 v1） + anchor。", "default_args": "v1 2", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_anchor}, 
		{"name": "grt_eval", "label": "强制 GRT 求值", "desc": "按当前状态立即跑一次 GRT 求值并发送命中事件。\n参数：无。", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_eval}, 
		{"name": "grt_reset", "label": "清空 GRT 状态", "desc": "清空 anchor / 已发送 / 两个广告计数，并按本地首装版本重新评估 anchor；该版本属于安装事实，重置不会清除或改写。版本未知时暂不发送。\n参数：无。", "category": "游戏", "section": "GRT", "version": "1.0.8", "handler": _cmd_grt_reset}, 

		{"name": "user_level", "label": "跳到指定难度档", "desc": "直接跳到难度档 user_level_v1：清空近期窗口与连胜（等价刚升到该档），立刻重推 SDK 标签，丢弃当前关进度并按新档位重新分流出题。\n参数：档位 0~5，0=回到未起步，默认 3。", "default_args": "3", "category": "游戏", "section": "难度", "version": "1.0.1", "handler": _cmd_user_level}, 
		{"name": "user_level_info", "label": "显示当前难度档", "desc": "只读，不改任何存档。在游戏页底部常驻显示当前档位、连胜局数、最近 n 局失败数，以及还差几局升/降级（死亡/重开/用道具算失败）；仅本次进程生效，仅游戏页可见。\n参数：留空=切换开关；on=显示；off=关闭。", "default_args": "", "category": "游戏", "section": "难度", "version": "1.0.2", "handler": _cmd_user_level_info}, 
		{"name": "daily_first_round", "label": "下一局设为当天第一局", "desc": "把当日全新开局计数归零，下一个全新开局（如通关后进下一关）按「当天第 1 局」走每日降级换题；已在进行中的当前局、续局、重开不受影响。\n降不降级仍取决于 AB daily_first_round_downgrade 分组（对照组不降）。\n参数：无。", "category": "游戏", "section": "难度", "version": "1.0.4", "handler": _cmd_daily_first_round}, 

		{"name": "prop_unlock_reset", "label": "重置道具解锁弹窗", "desc": "清掉三个道具的「解锁弹窗已弹过」标记与免费次数标记；之后用 level 跳到 3 / 5 / 10 关可反复查看弹窗。\n参数：无。", "category": "游戏", "section": "引导重置", "version": "1.0.0", "handler": _cmd_prop_unlock_reset}, 
		{"name": "mystery_guide_reset", "label": "重置问号花朵引导", "desc": "清掉问号花朵引导的「已展示过」标记；随包关卡没有问号关，需再灌一关带问号的题面才能重看。\n参数：无。", "category": "游戏", "section": "引导重置", "version": "1.0.1", "handler": _cmd_mystery_guide_reset}, 
		{"name": "lock_guide_reset", "label": "重置冰封列引导", "desc": "清掉冰封列引导的「已展示过」标记；随包关卡没有锁列关，需再灌一关开局带锁列的题面才能重看。\n参数：无。", "category": "游戏", "section": "引导重置", "version": "1.0.1", "handler": _cmd_lock_guide_reset}, 
		{"name": "prop_unlock_preview", "label": "预览道具解锁弹窗", "desc": "直接打开指定道具的解锁引导弹窗，不写「已展示」标记、不扣资源、不要求真实到达解锁关。\n参数：hint / undo / rope / fill_pot，默认 fill_pot；fill_pot 需在 complete_prop 组2/组3 且按钮可见。", "default_args": "fill_pot", "category": "游戏", "section": "引导重置", "version": "1.0.10"}, 

		{"name": "darkness", "label": "背景、花朵与花盆压暗", "desc": "同时压暗背景、花朵与花盆；仅本次进程生效，重进游戏页仍保留。\n参数：压暗百分比 0~100，0=原亮度，默认 0。", "default_args": "0", "category": "游戏", "section": "视觉测试", "version": "1.0.2"}, 
		{"name": "flower_brightness", "label": "花朵与花盆亮度", "desc": "把花朵和花盆亮度设为绝对百分比，覆盖盘面、提示/拖尾副本、飞盆及订单栏花盆；仅本次进程生效。\n参数：亮度百分比 0~200，100=原亮度，默认 100。", "default_args": "100", "category": "游戏", "section": "视觉测试", "version": "1.0.2"}, 
		{"name": "home_button_panel", "label": "首页按钮动效控制", "desc": "打开独立控制面板，对比 old/new、切换按钮难度、调整扫光与四种星光粒子。暂停底层游戏，不改AB分组、关卡、金币或存档。\n参数：留空打开；off关闭。", "category": "游戏", "section": "视觉测试", "version": "1.0.7", "handler": _cmd_home_button_panel}, 

		{"name": "proxy", "label": "抓包代理", "desc": "设置 Charles / mitmproxy 等 HTTP/HTTPS 抓包代理，作用于后续新建的关卡配置与章节图片请求，跨重启保留。仅非 rel 包生效；SDK 原生请求需另设设备系统代理。HTTPS 抓包需安装并信任抓包工具证书。\n参数：电脑局域网 IP或主机名 端口；off / --=关闭；留空=查看当前状态。例：proxy 192.168.1.2 8888。", "default_args_provider": func() -> String: return "%s %d" % [UserState.get_debug_proxy_host(), UserState.get_debug_proxy_port()] if UserState.has_debug_proxy() else "192.168.1.2 8888", "category": "游戏", "section": "工具", "version": "1.0.10", "handler": _cmd_proxy}, 
		{"name": "record", "label": "录屏模式", "desc": "画面收成 9:16（上下黑边，录完居中裁成 1080x1920）并放大，同时去广告、切英文、隐藏调试按钮，并重进当前关。off 恢复全面屏比例，调试按钮需冷启动恢复。\n参数：on [倍数]=开启，不填倍数按当前关自动撑到最大，上限 1.219；off=关闭。", "default_args": "on", "category": "游戏", "section": "工具", "version": "1.0.1", "handler": _cmd_record}, 
		{"name": "replay", "label": "用户回放", "desc": "读取 BQ 导出的埋点 CSV，打开回放页逐步重演该局；不发埋点、不写存档，仅编辑器可用。\n参数：CSV 路径 [game_id]。", "default_args": "~/Downloads/", "category": "游戏", "section": "工具", "version": "1.0.2", "handler": _cmd_replay}, 

		{"name": "timed_endless_motion", "label": "无尽开局/结束弹窗", "default_args": "flow", "desc": "只读预览两个正式组件，支持切换和重播，原速。使用最新dev原图和正式开局横幅/无尽领奖弹窗。结束为演示12盆/55.2%，不启动关卡、不通关、不发奖、不写存档或AB。暂停底层，关闭恢复。参数：flow / start / end / off；默认全流程，跳过实际游玩、演示领取不发奖。", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_timed_endless_motion}, 
		{"name": "hint_guide_motion", "label": "Hint 提示使用动效", "desc": "在当前游戏的可用Hint按钮上预览橙色光晕、放大和摇摆，复用自动提醒与死局推荐曲线；不展示走法、不消耗道具。\n参数：on=循环 / once=单次 / off=停止。", "default_args": "on", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_hint_guide_motion}, 
		{"name": "super_hard_flower_banner_animation", "label": "超级困难关花朵动画", "desc": "独立预览实验组2的紫色花朵藤蔓横幅，使用正式Spine与多语言文字。暂停底层游戏，播完自动恢复；不修改AB、关卡或存档。\n参数：super_hard=超级困难（默认）；hard=困难；off=立即关闭。", "default_args": "super_hard", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_super_hard_flower_banner_animation}, 
		{"name": "hard_flower_banner_animation", "label": "困难关花朵动画", "desc": "独立预览实验组2的红色花朵藤蔓横幅，使用正式Spine与多语言文字。暂停底层游戏，播完自动恢复；不修改AB、关卡或存档。\n参数：hard=困难（默认）；super_hard=超级困难；off=立即关闭。", "default_args": "hard", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_hard_flower_banner_animation}, 
		{"name": "rank_collectible_flow_preview", "label": "排行榜收集物全流程", "desc": "只读 yes 组全流程：局内收满礼盒→落入目标栏→完局收集→排行榜结算。五款素材（麋鹿、圣诞树、雪花、姜饼人、铃铛）、3/6/12目标、升位场景、分阶段、重播、循环、暂停和局部慢放；不改活动、积分、AB或存档。参数：off关闭。", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_rank_collectible_flow_preview}, 
		{"name": "countdown_lead_preview", "label": "加时白条", "desc": "直接播放无尽加时进度：红条停住，只在尽头多长出一小段白色，白色再消失，红条变长。可重复播放。不进无尽，不改时间或存档。\n参数：留空播放；off关闭。", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_countdown_lead_preview}, 
		{"name": "super_hard_banner_animation", "label": "超级困难关 Spine 动画", "desc": "独立预览实验组1的紫色Super Hard横幅，标题与说明使用正式多语言文字节点。暂停底层游戏，播完自动恢复；不修改AB、关卡或存档。\n参数：super_hard=超级困难（默认）；off=立即关闭。", "default_args": "super_hard", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_super_hard_banner_animation}, 
		{"name": "hard_banner_animation", "label": "困难关 Spine 动画", "desc": "独立播放实验组1的新版困难关横幅，text01／text02使用正式多语言文字节点，不显示烘焙英文图片。暂停底层游戏，播完自动恢复；不修改AB、关卡或存档。\n参数：hard=困难（默认）；super_hard=超级困难；off=立即关闭。", "default_args": "hard", "category": "动效预览", "section": "1.0.10", "version": "1.0.10", "handler": _cmd_hard_banner_animation}, 
		{"name": "combo_fullscreen_fx", "label": "Combo 全屏动效（全部连续播放=4，彩带版本=5）", "desc": "按阶段依次播放正式Combo文字、音效和定稿彩带反馈，正式全屏实验已使用同一套效果替换原花瓣。每档边缘动效持续1秒，不拦截操作，不读写AB、Combo计数、盘面或存档。再次执行从头重播。\n参数：1=第一阶段（Nice!／Great!／Excellent!＋10个圆形彩带）；2=第二阶段（Amazing!／Incredible!／Unstoppable!＋10个圆形和10个方形彩带）；3=第三阶段（Legendary!＋24个圆形/方形、12条卷曲彩带及肉粉色双侧光带）；4=全部连续播放；5=彩带版本全部连续播放（与正式全屏效果一致，文字和音效不变）；off=立即停止。", "default_args": "1", "category": "动效预览", "section": "1.0.10", "version": "1.0.10"}, 
		{"name": "combo_timing2_preview", "label": "Combo 时机2.0（最终七档）", "desc": "在游戏页正式位置播放下载12中的Spine 4.2.43最终七档混合版，花朵、花瓣、文字及原有装饰直接使用该文件。仅保留最终七个皮肤，不再切换旧花瓣版、花朵版或混合版；沿用随机出生位置、正式展示位置与原档位音效，不额外添加粒子或改变AB、Combo计数、盘面和存档。再次执行从头重播。\n参数：all或留空=七档连续预览；1~7=单档Nice!/Great!/Excellent!/Amazing!/Incredible!/Unstoppable!/Legendary!；off=立即停止。请先进入游戏页。", "default_args": "all", "category": "动效预览", "section": "1.0.10", "version": "1.0.10"}, 
		{"name": "complete_prop_preview_0", "label": "完成道具：组0（原版）", "default_args": "0", "desc": "本地覆盖complete_prop为组0：底栏保留重开，无完成一列道具。刷新当前游戏页布局；不跳关。", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_complete_prop_preview}, 
		{"name": "complete_prop_preview_1", "label": "完成道具：组1（重开上移）", "default_args": "1", "desc": "本地覆盖complete_prop为组1：重开移到左上角，无完成一列道具。", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_complete_prop_preview}, 
		{"name": "complete_prop_preview_2", "label": "完成道具：组2（开启道具）", "default_args": "2", "desc": "本地覆盖complete_prop为组2：左上重开，底栏新增完成一列道具。使用道具仍走真实库存和消耗。", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_complete_prop_preview}, 
		{"name": "complete_prop_preview_3", "label": "完成道具：组3（白底重开）", "default_args": "3", "desc": "本地覆盖complete_prop为组3：新增完成一列道具，左上重开使用白底蓝标。使用道具仍走真实库存和消耗。", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_complete_prop_preview}, 
		{"name": "complete_prop_preview_auto", "label": "完成道具：恢复SDK", "default_args": "auto", "desc": "清除complete_prop本地覆盖并刷新当前游戏页。分组覆盖沿用本地AB调试机制，跨重启保留；观察后可用此按钮恢复。", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_complete_prop_preview}, 
		{"name": "skin", "label": "切换小鸟", "desc": "加载本地小鸟主题，用于查看鸟巢开门和羽毛动效；仅切换当前游戏页，不修改AB或存档。请在盘面动效空闲时使用。", "default_args": "use bird", "category": "动效预览", "section": "1.0.9", "version": "1.0.9"}, 
		{"name": "streak_popup_1", "label": "连胜弹窗1", "desc": "直接预览第一级连胜弹窗：3连胜，数字2滚到3。使用新版无蒙层样式，不改AB、连胜数或存档。再次执行从头重播；off停止。", "default_args": "3", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_streak_popup_preview}, 
		{"name": "streak_popup_2", "label": "连胜弹窗2", "desc": "直接预览第二级连胜弹窗：7连胜，数字6滚到7。使用新版无蒙层样式，不改AB、连胜数或存档。再次执行从头重播；off停止。", "default_args": "7", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_streak_popup_preview}, 
		{"name": "streak_popup_3", "label": "连胜弹窗3", "desc": "直接预览第三级连胜弹窗：12连胜，数字11滚到12。使用新版无蒙层样式，不改AB、连胜数或存档。再次执行从头重播；off停止。", "default_args": "12", "category": "动效预览", "section": "1.0.9", "version": "1.0.10", "handler": _cmd_streak_popup_preview}, 
		{"name": "wood_door_lock_preview", "label": "关卡锁替换：原版／破碎木门", "desc": "所有流量域默认木门；0或ab恢复默认木门，1强制原版，3强制当前及后续关卡使用木门颜色锁、数字锁。沿用原版解锁条件，锁扣弹开、锁体甩落，闭合门板轻抖后直接碎裂；碎块为原始切分数量的58%，随机下落翻滚、在游戏页面顶层显示。关闭面板保留选择，不改规则、奖励或存档。\n参数：留空打开当前选择；0或ab恢复默认木门；1强制原版；3强制木门；off关闭面板。", "category": "动效预览", "section": "1.0.9", "version": "1.0.9", "handler": _cmd_wood_door_lock_preview}, 
		{"name": "daily_checkin_preview", "label": "打卡动效预览", "desc": "直接播放正式打卡动效，可重复查看；不改金币、存档、日期或AB。\n参数：天数1～7 奖励组1/2；off关闭。例：4 1=第4天庆祝无金币，2 1=墨镜＋300金币。", "default_args": "4 1", "category": "动效预览", "section": "打卡", "version": "1.0.8", "handler": _cmd_daily_checkin_preview}, 
		{"name": "home_button_preview", "label": "首页按钮扫光与星光", "desc": "与游戏页签同一控制面板；可预览普通、困难、超级困难、Bonus及特殊挑战按钮。\n参数：留空打开；off关闭。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7", "handler": _cmd_home_button_panel}, 
		{"name": "iq_genius_preview", "label": "IQ Genius 新版入场", "desc": "直接播放正式新版enter：原速、2秒整组淡出、2.2秒结束，不排队idle/exit，保留多语言标题。支持重播与关闭；暂停底层，不改IQ、AB、奖励或存档。参数：off关闭。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7", "handler": _cmd_iq_genius_preview}, 
		{"name": "iq_motion_preview", "label": "IQ进度拖尾与呼吸", "desc": "独立预览原版/新版、微量增长、跨节点、连续加分、满格与取消重播；不改IQ、AB或存档。参数：off关闭。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7", "handler": _cmd_iq_motion_preview}, 
		{"name": "rank_first_collect_preview", "label": "前三名收集花衔接调试", "desc": "前三名原地收集／第二升第一／仅收集，复用正式六花收集、积分回弹、升位和皇冠动画。支持重播、循环、慢放、暂停与阶段时间。不修改积分、赛季或存档。参数：off关闭。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7", "handler": _cmd_rank_first_collect_preview}, 

		{"name": "combo_preview", "label": "Combo 动效", "desc": "在游戏页正式位置预览 Combo 动效与声音，不读写 AB、Combo 计数、盘面或存档。再次执行从头重播。\n参数：留空/all=依次播放七档；1~6=Nice!/Great!/Excellent!/Amazing!/Incredible!/Unstoppable!；7 及任意更大正整数=Legendary!；不接受x2/x3参数；off=立即停止。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7"}, 
		{"name": "special_challenge_reward_preview", "label": "特殊挑战奖励控制面板", "desc": "切换1／2／3项奖励，查看宝箱、道具、光晕、持续星光及领取／翻倍模拟发放，可重播或关闭。暂停底层游戏，不实际发奖、不查询广告、不跳关、不写存档。\n参数：留空=3项；1／2／3=选择；off=关闭。", "category": "动效预览", "section": "1.0.6", "version": "1.0.6", "handler": _cmd_special_challenge_reward_preview}, 
		{"name": "bonus_motion_preview", "label": "Bonus 完整动效流程", "desc": "独立预览横幅、金币入罐、金猪飞入顶栏、飞出砸猪和飞金币；支持分段、循环、慢放。暂停底层游戏，不改AB、关卡、存档或奖励。\n参数：留空打开；off关闭。", "category": "动效预览", "section": "1.0.6", "version": "1.0.6", "handler": _cmd_bonus_motion_preview}, 
		{"name": "rank_trail_preview", "label": "完局/排行榜收集拖尾", "desc": "真实收集层的两种飞行与参考光带；支持重播、慢放与到达计数。暂停底层，不改积分、奖励或存档。参数：off关闭。", "category": "动效预览", "section": "1.0.7", "version": "1.0.7", "handler": _cmd_rank_trail_preview}, 
		{"name": "clover_coin_preview", "label": "四叶草金币 Spine 对比", "desc": "新旧金币自转对比、慢放与八枚飞币演示。仅预览，不修改金币余额或正式素材。参数：留空打开；off关闭。", "category": "动效预览", "section": "1.0.6", "version": "1.0.6", "handler": _cmd_clover_coin_preview}, 
		{"name": "streak_banner", "label": "预览连胜横幅", "desc": "纯预览连胜横幅，不读写横幅展示去重标记，也不改连胜数与存档。\n参数：连胜数 1~999（默认10）；样式组 0=奖杯版 / 1=新版拦截 / 2=新版不拦截（默认跟随当前 AB 组）。", "default_args": "10", "category": "动效预览", "section": "1.0.6", "version": "1.0.6"}, 
		{"name": "bonus_banner", "label": "预览 Bonus 横幅", "desc": "纯预览 Bonus Level 开局横幅，不改盘面与展示去重标记。\n参数：无。", "category": "动效预览", "section": "1.0.6", "version": "1.0.6"}, 

		{"name": "streak_motion", "label": "连胜奖杯整体动画", "desc": "预览奖杯、三朵花骨架、文字与光效。暂停底层盘面，不改连胜或存档。\n参数：once/on/off [连胜数] [slow]；on循环，slow慢放。", "default_args": "on 10", "category": "动效预览", "section": "1.0.4", "version": "1.0.4", "handler": _cmd_streak_motion}, 
		{"name": "progress_bling_full", "label": "完整落盆反馈", "desc": "预览完整飞盆、落地回弹、流光与粒子，不改变真实完成数或存档。\n参数：on=循环 / once=单次 / off=停止；颜色 0~11 / excellent / all。", "default_args": "on 0", "category": "动效预览", "section": "1.0.4", "version": "1.0.4"}, 
		{"name": "progress_bling_motion", "label": "进度条流光与粒子", "desc": "直接预览流光、外框与粒子，不读写 AB、Combo 或存档。\n参数：on / once / off；颜色 0~11 / excellent / all；all=完整效果 / base=仅原流光。", "default_args": "on all", "category": "动效预览", "section": "1.0.4", "version": "1.0.4"}, 
		{"name": "super_hard_banner", "label": "预览超级困难关横幅", "desc": "纯预览超级困难关（紫色版）横幅，不修改真实困难关判定，也不改展示去重标记。\n参数：章节号，1/2 为前两章文案（百分比 40%~60%），3 及以上为后续章文案（百分比 15%~40% 或 60%~85%，随文案而定），默认 3。", "default_args": "3", "category": "动效预览", "section": "1.0.4", "version": "1.0.4"}, 
		{"name": "good_luck", "label": "预览好运问号", "desc": "预览 Good Luck 动效（与 Smart Move! 同位置），不经好运问号判定、不染色、不看 AB 分组。\n参数：无。", "category": "动效预览", "section": "1.0.4", "version": "1.0.4"}, 

		{"name": "challenge_banner", "label": "预览 Challenge 飘屏", "desc": "只播放 Challenge 飘屏 UI，不改盘面、不进频控；只切换本次标题，不改游戏语言。\n参数：留空=当前游戏语言；1 英语 / 2 法语 / 3 俄语 / 4 西班牙语 / 5 葡萄牙语。例：challenge_banner 2。", "default_args": "", "category": "动效预览", "section": "1.0.2", "version": "1.0.2"}, 
		{"name": "smart_move", "label": "预览脱困点赞", "desc": "预览 Smart Move! 文案与点赞手势；手势放在某一列的两朵花之间。\n参数：无。", "category": "动效预览", "section": "1.0.2", "version": "1.0.2"}, 

		{"name": "trail", "label": "预览花朵拖尾", "desc": "预览花朵拖尾效果。\n参数：留空=10 种颜色依次播放；填色号则只播该色：0 红 / 1 紫 / 2 粉 / 3 浅蓝 / 4 黄 / 5 绿 / 6 蓝 / 7 青绿 / 8 橙 / 9 淡紫。", "default_args": "", "category": "动效预览", "section": "1.0.1", "version": "1.0.1"}, 
		{"name": "hard_banner", "label": "预览困难关横幅", "desc": "纯预览困难关横幅，不修改真实困难关判定，也不改展示去重标记。\n参数：章节号，1/2 为前两章文案（百分比 40%~60%），3 及以上为后续章文案（百分比 15%~40% 或 60%~85%，随文案而定），默认 3。", "default_args": "3", "category": "动效预览", "section": "1.0.1", "version": "1.0.1"}, 




		{"name": "mock_panel", "label": "【打开广告与授权 Mock 配置面板】", "category": "广告与授权", "version": "1.0.1", "handler": _cmd_mock_panel}, 

		{"name": "haptic_panel", "label": "【打开震动调试面板】", "category": "震动", "version": "1.0.4", "handler": _cmd_haptic_panel}, 

		{"name": "ab_debug", "label": "【AB 实验调试】设置 group_id、查看关卡实验、逐项切换固定 key 实验分组", "category": "AB实验", "version": "1.0.1", "handler": _cmd_ab_debug}, 
	]
	_register_commands()
	CheatBus.command_issued.connect(_on_command_issued)
	if OS.has_feature("editor") and not OS.has_feature("rel"):
		get_tree().root.files_dropped.connect(_on_files_dropped, CONNECT_DEFERRED)



func _register_commands() -> void :
	for def: Dictionary in _command_defs:
		var cmd: = CheatCommand.new()
		cmd.name = def["name"]
		cmd.label = def["label"]
		cmd.default_args = def.get("default_args", "")

		cmd.default_args_provider = def.get("default_args_provider", Callable())
		cmd.category = def.get("category", "")
		cmd.section = def.get("section", "")

		cmd.version = def.get("version", "")
		cmd.desc = def.get("desc", "")
		CheatBus.register_command(cmd)



func _on_command_issued(cmd_name: String, args: Array[String]) -> void :



	if cmd_name.begins_with("{") or cmd_name.begins_with("["):
		var parts: Array[String] = [cmd_name]
		parts.append_array(args)
		await _cmd_juice_json(parts)
		return
	for def: Dictionary in _command_defs:
		if def["name"] == cmd_name and def.has("handler"):
			(def["handler"] as Callable).call(args)
			return



func _cmd_streak_popup_preview(args: Array[String]) -> void :
	if args.size() != 1 or args[0] not in ["3", "7", "12", "off"]:
		SceneManager.show_toast("连胜弹窗预览：3 / 7 / 12 / off")
		return
	var page: JuiceGamePage = SceneManager.get_page("game") as JuiceGamePage
	if not is_instance_valid(page) or not page.visible:
		SceneManager.show_toast("请先进入游戏页再预览连胜弹窗")
		return
	if not is_instance_valid(page._start_banner):
		SceneManager.show_toast("请等待游戏页加载完成")
		return
	if page._start_banner.visible and not args[0] == "off":
		if not page._start_banner._tier_streak.visible:
			SceneManager.show_toast("请等待当前开局横幅结束再预览")
			return
	page._start_banner.hide_now()
	if args[0] == "off":
		return
	var preview_args: Array[String] = [args[0], "2"]
	page._cheat_preview_streak_banner(preview_args)

func _cmd_complete_prop_preview(args: Array[String]) -> void :
	if args.size() != 1 or not args[0] in ["0", "1", "2", "3", "auto"]:
		SceneManager.show_toast("完成道具预览：0 / 1 / 2 / 3 / auto")
		return
	var page: JuiceGamePage = SceneManager.get_page("game") as JuiceGamePage
	if not is_instance_valid(page) or not page.visible or page.is_endless():
		SceneManager.show_toast("请先进入普通游戏页，结束动效后再切换")
		return
	if args[0] == "auto":
		ABManager.complete_prop.clear_debug_override()
	else:
		ABManager.complete_prop.set_debug_override(int(args[0]))
	page._freeze_complete_prop_group()
	page._layout()
	page.refresh_economy_ui()
	SceneManager.show_toast("complete_prop 当前组：%d" % ABManager.complete_prop.value())

var _special_challenge_reward_preview: CanvasLayer
var _home_button_fx_panel: HomeButtonFxPanel
const HOME_BUTTON_FX_PANEL_SCENE_PATH: String = "res://scripts/debug/ui/home_button_fx_panel.tscn"


func _cmd_home_button_panel(args: Array[String]) -> void :
	if args.size() > 1 or ( not args.is_empty() and args[0] != "off"):
		SceneManager.show_toast("首页按钮预览：留空打开；off关闭")
		return
	if not args.is_empty():
		if is_instance_valid(_home_button_fx_panel):
			_home_button_fx_panel.close()
		return
	if not is_instance_valid(_home_button_fx_panel):
		if not ResourceLoader.exists(HOME_BUTTON_FX_PANEL_SCENE_PATH, "PackedScene"):
			SceneManager.show_toast("首页按钮控制面板资源缺失，请恢复工程资源后重启游戏")
			return
		var packed_scene: PackedScene = load(HOME_BUTTON_FX_PANEL_SCENE_PATH) as PackedScene
		if packed_scene == null:
			SceneManager.show_toast("首页按钮控制面板加载失败，请重启游戏后重试")
			return
		var panel: Node = packed_scene.instantiate()
		if not panel is HomeButtonFxPanel:
			if is_instance_valid(panel):
				panel.free()
			SceneManager.show_toast("首页按钮控制面板资源不匹配，请恢复工程资源后重试")
			return
		_home_button_fx_panel = panel as HomeButtonFxPanel
		get_tree().root.add_child(_home_button_fx_panel)
	_home_button_fx_panel.open()


func _cmd_special_challenge_reward_preview(args: Array[String]) -> void :
	if args.size() > 1 or ( not args.is_empty() and args[0] not in ["1", "2", "3", "off"]):
		SceneManager.show_toast("奖励预览参数：1／2／3；off=关闭")
		return
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_special_challenge_reward_preview):
			_special_challenge_reward_preview.close()
		return
	if not is_instance_valid(_special_challenge_reward_preview):
		_special_challenge_reward_preview = load("res://scripts/debug/ui/special_challenge_reward_preview_panel.tscn").instantiate()
		get_tree().root.add_child(_special_challenge_reward_preview)
	_special_challenge_reward_preview.open(int(args[0]) if not args.is_empty() else 3)

func _cmd_clear(_args: Array[String]) -> void :
	UserState.reset_all()
	LevelManager.reset_all_progress()
	LevelManager.clear_cache()
	get_tree().quit()


func _cmd_next_hard(_args: Array[String]) -> void :
	var level_id: int = UserState.get_current_level() + 1
	LevelManager.cheat_force_hard_level(level_id)
	print("[Cheat] 第 %d 关在本次进程中强制为 Hard" % level_id)


func _cmd_next_super_hard(_args: Array[String]) -> void :
	var level_id: int = UserState.get_current_level() + 1
	LevelManager.cheat_force_hard_level(level_id, "SuperHard")
	print("[Cheat] 第 %d 关在本次进程中强制为 SuperHard" % level_id)



func _cmd_locale(args: Array[String]) -> void :
	var locale: String = args[0] if args.size() > 0 else "en"
	TranslationServer.set_locale(locale)
	print("[Cheat] locale = ", TranslationServer.get_locale())


static func _arg_int(args: Array[String], idx: int, fallback: int) -> int:
	if idx >= args.size() or not args[idx].is_valid_int():
		return fallback
	return int(args[idx])




func _cmd_ab_debug(_args: Array[String]) -> void :
	SceneManager.show_debug_panel("ab_debug")



func _cmd_replay(args: Array[String]) -> void :
	if not OS.has_feature("editor"):
		SceneManager.show_toast("用户回放只在编辑器中可用")
		return
	var params: Dictionary = {}
	if args.size() > 0:
		params["file"] = args[0]
	if args.size() > 1:
		params["game_id"] = args[1]
	SceneManager.show_debug_panel("juice_replay", params)














func _cmd_juice_json(args: Array[String]) -> void :
	var res: Dictionary = JuiceDebugLevel.load_from_text(" ".join(args))
	print("[Cheat] juice_json: %s" % String(res["message"]))
	for e: String in (res["errors"] as Array):
		print("  ✗ %s" % e)
	if not bool(res["ok"]):
		SceneManager.show_toast(String(res["message"]))
		return
	JuiceDebugLevel.enter(int(res["level"]))


func _cmd_mystery_auto_unlock_test(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if not args.is_empty():
		SceneManager.show_toast("mystery_auto_unlock_test 不需要参数")
		return
	var result: Dictionary = JuiceDebugLevel.load_mystery_auto_unlock_test()
	if not bool(result["ok"]):
		SortLogger.error("问号自动解开测试题面装载失败：%s" % str(result))
		SceneManager.show_toast(String(result["message"]))
		return
	JuiceDebugLevel.enter.bind(int(result["level"]), {
		"cheat_mystery_auto_unlock_test": true, 
		"skip_prop_unlock": true, 
		"skip_opening_banner": true, 
	}).call_deferred()


func _cmd_sunlight_pot_level(args: Array[String]) -> void :
	if args.size() > 1 or args.any( func(value: String) -> bool: return not value.is_valid_int()):
		SceneManager.show_toast("用法：sunlight_pot_level 关号，例如42")
		return
	var level: int = _arg_int(args, 0, 42)
	if not JuiceSunlightPotVariant.scheduled(level):
		SceneManager.show_toast("第 %d 关不在冻盆实验投放表，请使用42等固定关号" % level)
		return
	SceneManager.hide_all_dialogs()
	SceneManager.hide_page("game")
	JuiceLevelParser.clear_debug_row()
	LevelManager.clear_game_state(level)
	ABManager.sunlight_gameplay.set_debug_override(1)
	_cmd_level([str(level)])
	SceneManager.show_toast("冻盆实验已开启，正在加载第 %d 关正式新局" % level)



func _cmd_long_rope(args: Array[String]) -> void :
	var res: Dictionary = JuiceDebugLevel.load_long_rope_case(_arg_int(args, 0, 1))
	if not bool(res["ok"]):
		push_error("[Cheat] long_rope: %s\n%s" % [
			String(res["message"]), "\n".join(res["errors"] as Array[String])])
		SceneManager.show_toast(String(res["message"]))
		return
	SceneManager.hide_all_dialogs()
	JuiceDebugLevel.enter(int(res["level"]))
	SceneManager.hide_page("home")




func _cmd_eight_columns(args: Array[String]) -> void :
	var rows: int = clampi(
		_arg_int(args, 0, JuiceDebugLevel.DEFAULT_ROWS), 
		JuiceDebugLevel.MIN_ROWS, 
		JuiceDebugLevel.MAX_ROWS)
	var res: Dictionary = JuiceDebugLevel.load_eight_columns(rows)
	if not bool(res["ok"]):
		push_error("[Cheat] eight_columns: %s\n%s" % [
			String(res["message"]), "\n".join(res["errors"] as Array[String])])
		SceneManager.show_toast(String(res["message"]))
		return
	SceneManager.hide_all_dialogs()
	JuiceDebugLevel.enter(int(res["level"]), {"cheat_eight_columns_rows": rows})
	SceneManager.hide_page("home")




func _cmd_challenge_time(args: Array[String]) -> void :
	var n: int = _arg_int(args, 0, 1)
	var res: Dictionary = JuiceDebugLevel.load_challenge_case(n)
	if not bool(res["ok"]):
		push_error("[Cheat] challenge_time: %s\n%s" % [
			String(res["message"]), "\n".join(res["errors"] as Array[String])])
		SceneManager.show_toast(String(res["message"]))
		return
	var tip: String = String(res["tip"]) + "(只打分类日志,不自动弹飘屏)"
	print("[Cheat] %s · %s" % [String(res["message"]), tip])
	SceneManager.hide_all_dialogs()
	JuiceDebugLevel.enter(int(res["level"]), {"cheat_challenge_tip": tip})
	SceneManager.hide_page("home")









func _cmd_user_level(args: Array[String]) -> void :
	if args.is_empty():
		print("[Cheat] user_level: 需要一个参数(0~%d)" % UserLevelLadder.LEVEL_MAX)
		SceneManager.show_toast("用法:user_level <0~%d>" % UserLevelLadder.LEVEL_MAX)
		return
	var csv_status: Dictionary = LevelManager.cheat_csv_level_status()
	if bool(csv_status["switching"]):
		SceneManager.show_toast("正在切换测试题库，请稍候")
		return
	if bool(csv_status["active"]):
		SceneManager.hide_all_dialogs()
		SceneManager.hide_page("game")
	var want: int = clampi(int(args[0].strip_edges()), 0, UserLevelLadder.LEVEL_MAX)
	var cur: int = UserState.get_user_level()
	UserState.cheat_set_user_level(want)
	UserLevelTag.reassert()
	var level: int = UserState.get_current_level()
	LevelManager.clear_game_state(level)
	SceneManager.hide_all_dialogs()

	SceneManager.show_page("game")
	SceneManager.hide_page("home")
	print("[Cheat] user_level: %d -> %d(窗口与连胜已清空),第 %d 关已按新档位重载" % [cur, want, level])
	SceneManager.show_toast("难度档 %d → %d,第 %d 关已重载" % [cur, want, level])


const _CSV_TEST_BANK_SCRIPT: = preload("res://scripts/debug/juice_csv_test_bank.gd")
var _csv_test_bank: JuiceCsvTestBank


func _on_files_dropped(files: PackedStringArray) -> void :
	await _get_csv_test_bank().import_dropped_files(files)


func _get_csv_test_bank() -> JuiceCsvTestBank:
	if _csv_test_bank == null or not is_instance_valid(_csv_test_bank):
		_csv_test_bank = _CSV_TEST_BANK_SCRIPT.new() as JuiceCsvTestBank
		_csv_test_bank.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_csv_test_bank)
	return _csv_test_bank


func _cmd_csv_levels(args: Array[String]) -> void :
	if not OS.has_feature("editor") or OS.has_feature("rel"):
		SceneManager.show_toast("CSV 题库测试仅在编辑器运行的客户端可用")
		return
	var bank: JuiceCsvTestBank = _get_csv_test_bank()
	if args.is_empty():
		bank.choose_file()
	else:
		await bank.import_file(" ".join(args))


func _cmd_csv_levels_info(_args: Array[String]) -> void :
	if OS.has_feature("editor") and not OS.has_feature("rel"):
		_get_csv_test_bank().show_status()


func _cmd_csv_levels_off(_args: Array[String]) -> void :
	if OS.has_feature("editor") and not OS.has_feature("rel"):
		await _get_csv_test_bank().stop()




func _cmd_daily_first_round(_args: Array[String]) -> void :
	UserState.cheat_reset_daily_round_count()
	print("[Cheat] daily_first_round: 当日全新开局计数已归零，下一个全新开局为当天第 1 局")
	SceneManager.show_toast("下一局为当天第一局")




func _cmd_user_level_info(args: Array[String]) -> void :
	if _user_level_hud == null or not is_instance_valid(_user_level_hud):
		_user_level_hud = _USER_LEVEL_HUD.instantiate() as UserLevelHud
		get_tree().root.add_child(_user_level_hud)
	var mode: String = args[0].strip_edges().to_lower() if not args.is_empty() else ""
	var on: bool = not _user_level_hud.is_enabled()
	if mode == "on":
		on = true
	elif mode == "off":
		on = false
	_user_level_hud.set_enabled(on)
	print("[Cheat] user_level_info = %s" % ("开" if on else "关"))



func _cmd_juice_json_off(_args: Array[String]) -> void :
	var lv: int = JuiceDebugLevel.clear()
	if lv <= 0:
		print("[Cheat] juice_json_off: 本来就没装调试题面")
		return
	print("[Cheat] juice_json_off: 第 %d 关已撤回关卡表(重进这一关生效)" % lv)
	SceneManager.show_toast("第 %d 关已撤回关卡表" % lv)



func _cmd_props(args: Array[String]) -> void :
	var n: int = maxi(int(args[0]) if args.size() > 0 else 99, 0)
	for kind in ["hint", "undo", "rope", "fill_pot"]:
		UserState.set_prop_count(kind, n)
	_refresh_game_economy_ui()
	print("[Cheat] 所有道具 = %d" % n)




func _cmd_prop_unlock_reset(_args: Array[String]) -> void :
	UserState.clear_prop_unlock_shown()
	print("[Cheat] 已重置道具解锁弹窗标记(hint/撤回/增加绳子),跳到 3/5 关可重看 hint/增加绳子")




func _cmd_mystery_guide_reset(_args: Array[String]) -> void :
	UserState.reset_mystery_guide_shown()
	print("[Cheat] 已重置问号花朵引导标记,灌一关带 ?N 的题面可重看")




func _cmd_lock_guide_reset(_args: Array[String]) -> void :
	UserState.reset_lock_guide_shown()
	print("[Cheat] 已重置冰封列引导标记,灌一关开局带 columnType:\"unlock\" 的题面可重看")


func _cmd_special_challenge_previous(_args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	var challenge: Dictionary = UserState.get_special_challenge()
	if challenge.get("status", "") in ["win_pending", "reward_pending"]:
		SceneManager.show_toast("请先领取当前特殊挑战奖励，再跳转前一关")
		return
	var level: int = int(challenge.get("after_level", UserState.get_special_challenge_offer_after()))
	if level <= 0:
		level = maxi(SpecialChallengeRules.FIRST_ANCHOR, UserState.get_current_level())
		while not SpecialChallengeRules.is_anchor(level):
			level += 1
	SceneManager.hide_all_dialogs()
	SceneManager.hide_page("game")
	JuiceDebugLevel.clear()
	if not challenge.is_empty():
		LevelManager.clear_game_state(UserState.get_current_level())
	UserState.set("_special_challenge", {})
	UserState.set("_special_challenge_offer_after", 0)
	LevelManager.clear_game_state(level)
	_cmd_level([str(level)])
	SceneManager.show_toast("第 %d 关，通关后进入特殊挑战" % level)









func _cmd_level(args: Array[String]) -> void :
	var level: int = int(args[0]) if args.size() > 0 else 1
	var csv_status: Dictionary = LevelManager.cheat_csv_level_status()
	if bool(csv_status["switching"]):
		SceneManager.show_toast("正在切换测试题库，请稍候")
		return

	if bool(csv_status["active"]):
		SceneManager.hide_all_dialogs()
		SceneManager.hide_page("game")
		LevelManager.clear_game_state(maxi(1, level))
	UserState.cheat_jump_to_level(level)
	SceneManager.hide_all_dialogs()
	print("[Cheat] 跳到第 %d 关" % UserState.get_current_level())
	SceneManager.show_page("game")
	SceneManager.hide_page("home")



func _cmd_flow_domain(args: Array[String]) -> void :
	if args.is_empty():
		var cheat: String = ABManager.get_flow_domain_cheat_mode()
		var sdk: String = ABManager.read_sdk_flow_domain()
		var msg: String = "流量域覆盖=%s，SDK=%s（空=未就绪）" % [
			cheat, sdk if not sdk.is_empty() else "（空）"]
		print("[Cheat] %s" % msg)
		SceneManager.show_toast(msg)
		return
	var mode: String = String(args[0]).strip_edges().to_lower()
	if mode != ABManager.FLOW_DOMAIN_CHEAT_AUTO\
	and mode != ABManager.FLOW_DOMAIN_CHEAT_BASELINE\
	and mode != ABManager.FLOW_DOMAIN_CHEAT_EXPERIMENT:
		SceneManager.show_toast("用法：flow_domain auto|baseline|experiment")
		return
	ABManager.set_flow_domain_cheat_mode(mode)
	var tip: String = "流量域覆盖已设为 %s，请冷启动后验证章节渠道" % mode
	print("[Cheat] %s" % tip)
	SceneManager.show_toast(tip)




func _cmd_living_days(args: Array[String]) -> void :
	var days: int = (0 if args[0] == "ab" else int(args[0])) if not args.is_empty() else -1
	UserState.set_debug_install_days(days)
	print("[Cheat] living_days = %d（-1 为真实值）" % days)
	GrtManager.force_evaluate()



func _cmd_coins(args: Array[String]) -> void :
	var raw_value: String = args[0] if args.size() > 0 else "99999"
	if args.size() > 1 or not raw_value.is_valid_int():
		SceneManager.show_toast("用法：coins <非负整数>，例如 coins 99999")
		return
	var n: int = int(raw_value)
	if n < 0:
		SceneManager.show_toast("金币数不能小于 0")
		return
	UserState.set_coins(n)
	_refresh_game_economy_ui()
	_refresh_home_coin_ui()
	SortLogger.info("[Cheat] 金币 = %d" % UserState.get_coins())
	SceneManager.show_toast("金币已设置为 %d" % UserState.get_coins())




func _cmd_no_ads(args: Array[String]) -> void :
	var on: bool = not UserState.is_debug_no_ads()
	if args.size() > 0 and args[0] != "":
		on = args[0] == "on"
	UserState.set_debug_no_ads(on)
	_refresh_game_economy_ui()
	SceneManager.show_toast("已去除所有广告" if UserState.is_debug_no_ads() else "已开启广告")
	print("[Cheat] 去广告 = %s" % ("开" if UserState.is_debug_no_ads() else "关"))




const RECORD_BASE_H: = 2340.0

const RECORD_MAX_ZOOM: = 2340.0 / 1920.0



const RECORD_HEADER_BOTTOM: = 155.0

const RECORD_QUOTA_VIS_TOP: = -4.0
const RECORD_QUOTA_VIS_H: = 236.0

const RECORD_POT_VIS_TOP: = 638.0

const RECORD_BTN_VIS_TOP: = -10.0
const RECORD_BTN_VIS_H: = 200.0
const RECORD_BTN_Y_FROM_BAR: = 8.0

const RECORD_QUOTA_LIFT: = 24.0













func _cmd_record(args: Array[String]) -> void :
	var on: bool = args.is_empty() or args[0] != "off"
	var root: Window = get_tree().root
	if on:
		var gap: float = (RECORD_POT_VIS_TOP - RECORD_HEADER_BOTTOM - RECORD_QUOTA_VIS_H) * 0.5
		var content_bottom: float = _record_content_bottom()
		var zoom: float = 1.0
		if content_bottom > 0.0:
			zoom = RECORD_BASE_H / (content_bottom + gap * 2.0 + RECORD_BTN_VIS_H)
		for a: String in args:
			if a.is_valid_float():
				zoom = float(a)
		zoom = clampf(zoom, 1.0, RECORD_MAX_ZOOM)
		var h: int = roundi(RECORD_BASE_H / zoom)
		root.content_scale_size = Vector2i(roundi(float(h) * 9.0 / 16.0), h)
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		SafeAreaSim.set_notch(0, 0)
		JuiceGamePage.debug_quota_shift = RECORD_HEADER_BOTTOM + gap - RECORD_QUOTA_VIS_TOP\
		- JuiceGamePage.QUOTA_Y - RECORD_QUOTA_LIFT
		JuiceGamePage.debug_prop_bar_shift = 0.0
		if content_bottom > 0.0:
			var bottom_gap: float = maxf((float(h) - content_bottom - RECORD_BTN_VIS_H) * 0.5, 0.0)
			var btn_y: float = content_bottom + bottom_gap - RECORD_BTN_VIS_TOP
			JuiceGamePage.debug_prop_bar_shift = btn_y - RECORD_BTN_Y_FROM_BAR\
			- (float(h) - JuiceGamePage.PROP_BAR_RESERVED_H)
			print("[Cheat] 录屏间距 上=%.0f 下=%.0f" % [gap, bottom_gap])
		_cmd_no_ads(["on"])
		_cmd_locale(["en"])
		_cmd_hide_debug([])
		print("[Cheat] 录屏放大倍数 = %.3f" % zoom)
	else:
		root.content_scale_size = Vector2i(UiMetrics.DESIGN)
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		SafeAreaSim.disable()
		JuiceGamePage.debug_quota_shift = 0.0
		JuiceGamePage.debug_prop_bar_shift = 0.0
	SceneManager.reapply_safe_area()
	SceneManager.hide_all_dialogs()
	SceneManager.show_page("game")
	print("[Cheat] 录屏模式 = %s,逻辑视口 %s" % ["开" if on else "关", str(UiMetrics.viewport_size())])




func _record_content_bottom() -> float:
	var game_page: JuiceGamePage = SceneManager.get_page("game") as JuiceGamePage
	if game_page == null or not game_page.visible:
		return -1.0
	var board: JuiceBoardView = game_page.get_node_or_null("Board") as JuiceBoardView
	if board == null:
		return -1.0
	return board.track_bottom_global_y()




func _refresh_game_economy_ui() -> void :
	var game_page: Node = SceneManager.get_page("game")
	if game_page != null and game_page.visible and game_page.has_method("refresh_economy_ui"):
		game_page.call("refresh_economy_ui")



func _refresh_home_coin_ui() -> void :
	var home_page: Node = SceneManager.get_page("home")
	if home_page != null and home_page.visible and home_page.has_method("refresh_coin_hud"):
		home_page.call("refresh_coin_hud")



func _cmd_hide_debug(_args: Array[String]) -> void :
	var overlay: = get_tree().get_first_node_in_group("cheat_overlay") as CheatOverlay
	if overlay == null:

		for node in get_tree().get_nodes_in_group(""):
			if node is CheatOverlay:
				overlay = node
				break
	if overlay == null:

		for child in get_parent().get_children():
			if child is CheatOverlay:
				overlay = child
				break
	if overlay != null:
		overlay.visible = false
		print("[Cheat] 调试按钮已隐藏，下次冷启动恢复")
	else:
		push_error("[Cheat] 找不到 CheatOverlay 节点")






const _USER_LEVEL_HUD: PackedScene = preload("res://scripts/debug/ui/user_level_hud.tscn")
var _user_level_hud: UserLevelHud = null




const _MOCK_UNIKIT_PANEL: PackedScene = preload("res://scripts/debug/ui/mock_unikit_panel.tscn")
var _mock_unikit_panel: MockUnikitPanel = null




func _cmd_mock_panel(_args: Array[String]) -> void :
	if _mock_unikit_panel == null or not is_instance_valid(_mock_unikit_panel):
		_mock_unikit_panel = _MOCK_UNIKIT_PANEL.instantiate() as MockUnikitPanel
		get_tree().root.add_child(_mock_unikit_panel)
	await _mock_unikit_panel.open()




const _HAPTIC_DEBUG_PANEL: PackedScene = preload("res://scripts/debug/ui/haptic_debug_panel.tscn")
var _haptic_debug_panel: HapticDebugPanel = null




func _cmd_haptic_panel(_args: Array[String]) -> void :
	if _haptic_debug_panel == null or not is_instance_valid(_haptic_debug_panel):
		_haptic_debug_panel = _HAPTIC_DEBUG_PANEL.instantiate() as HapticDebugPanel
		get_tree().root.add_child(_haptic_debug_panel)
	_haptic_debug_panel.open()


var _clover_coin_preview: CanvasLayer
var _juice_endless_preview: CanvasLayer


func _cmd_juice_endless(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() == 1 and args[0].to_lower() == "off":
		if is_instance_valid(_juice_endless_preview):
			_juice_endless_preview.close()
		return
	if args.size() > 1 or (args.size() == 1 and not args[0].is_valid_int()):
		SceneManager.show_toast("参数应为整数种子或 off")
		return
	if not is_instance_valid(_juice_endless_preview):
		_juice_endless_preview = load("res://scripts/debug/ui/juice_endless_preview.gd").new()
		get_tree().root.add_child(_juice_endless_preview)
	if args.is_empty():
		_juice_endless_preview.open()
	else:
		_juice_endless_preview.open(int(args[0]))




func _cmd_clover_coin_preview(args: Array[String]) -> void :
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_clover_coin_preview):
			_clover_coin_preview.close()
		return
	if not is_instance_valid(_clover_coin_preview):
		_clover_coin_preview = load("res://scripts/debug/ui/clover_coin_preview.gd").new()
		get_tree().root.add_child(_clover_coin_preview)
	_clover_coin_preview.open()


const _STREAK_MOTION_PREVIEW: PackedScene = preload("res://scripts/debug/ui/streak_motion_preview.tscn")
var _streak_motion_preview: CanvasLayer

func _cmd_streak_motion(args: Array[String]) -> void :
	var mode: String = args[0] if not args.is_empty() else "on"
	if mode == "off":
		if is_instance_valid(_streak_motion_preview):
			_streak_motion_preview.close()
		return
	if mode != "on" and mode != "once":
		SortLogger.warn("[Cheat] streak_motion 参数：on/once/off [连胜数] [slow]")
		return
	var count: int = 10
	if args.size() > 1:
		if not args[1].is_valid_int():
			SortLogger.warn("[Cheat] 连胜数必须是整数")
			return
		count = maxi(2, args[1].to_int())
	if not is_instance_valid(_streak_motion_preview):
		_streak_motion_preview = _STREAK_MOTION_PREVIEW.instantiate() as CanvasLayer
		get_tree().root.add_child(_streak_motion_preview)
	_streak_motion_preview.open(count, mode == "on", args.has("slow"))


const _WOOD_DOOR_LOCK_PREVIEW: PackedScene = preload("res://scripts/debug/ui/wood_door_lock_preview.tscn")
var _wood_door_lock_preview: CanvasLayer = null


func _cmd_wood_door_lock_preview(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() == 1 and args[0] == "off":
		if is_instance_valid(_wood_door_lock_preview):
			_wood_door_lock_preview.call("close")
		return
	if args.size() > 1 or ( not args.is_empty() and args[0] not in ["0", "ab", "1", "3"]):
		SceneManager.show_toast("wood_door_lock_preview 参数：0或ab＝恢复默认木门，1＝原版，3＝木门，off＝关闭")
		return
	if not is_instance_valid(_wood_door_lock_preview):
		_wood_door_lock_preview = _WOOD_DOOR_LOCK_PREVIEW.instantiate() as CanvasLayer
		get_tree().root.add_child(_wood_door_lock_preview)
	var version: int = -1
	if not args.is_empty():
		version = 0 if args[0] == "ab" else int(args[0])
	_wood_door_lock_preview.call("open", version)


const _BONUS_MOTION_PREVIEW: PackedScene = preload("res://scripts/debug/ui/bonus_motion_preview.tscn")
var _bonus_motion_preview: BonusMotionPreview = null

func _cmd_bonus_motion_preview(args: Array[String]) -> void :
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_bonus_motion_preview):
			_bonus_motion_preview.close()
		return
	if not is_instance_valid(_bonus_motion_preview):
		_bonus_motion_preview = _BONUS_MOTION_PREVIEW.instantiate() as BonusMotionPreview
		get_tree().root.add_child(_bonus_motion_preview)
	_bonus_motion_preview.open()


func _cmd_bonus_start_test(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if not args.is_empty() and args[0] == "off":
		_cmd_juice_json_off([])
		SceneManager.show_page("game")
		return
	var row: Dictionary = {"id": UserState.get_current_level(), "capacity": 4, "targetCups": 3, 
		"initial": ["0|0,0,0", "1|1,1,1", "2|2,2,2", "-|0,1,2"], "incoming": [], 
		"note": "Bonus opening motion test"}
	var result: Dictionary = JuiceDebugLevel.load_from_text(JSON.stringify(row))
	if not bool(result["ok"]):
		SceneManager.show_toast(String(result["message"]))
		return
	SceneManager.hide_all_dialogs()
	JuiceDebugLevel.enter(int(result["level"]), {"cheat_bonus_start_test": true})
	SceneManager.hide_page("home")
	SceneManager.show_toast("金猪开局测试：最右串底部依次补到同色盆；最后剩下的金币补进金猪")


func _cmd_rank_debug(_args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	await SceneManager.warm_page_threaded("rank_debug")
	SceneManager.show_dlg("rank_debug")

func _cmd_rank_score(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	RankManager.cheat_adjust_collect_num(int(args[0]) if not args.is_empty() else 100)
	_refresh_rank_debug_consumers()

func _cmd_rank_collect(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if not args.is_empty() and not args[0].is_valid_int():
		SceneManager.show_toast("请输入整数收集数")
		return
	var count: int = maxi(int(args[0]) if not args.is_empty() else 100, 0)
	RankManager.cheat_adjust_collect_num(count - RankManager.get_collect_num())
	_refresh_rank_debug_consumers()

func _cmd_rank_tier(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	RankManager.cheat_set_tier(int(args[0]) if not args.is_empty() else 2)
	_refresh_rank_debug_consumers()

func _cmd_rank_countdown(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	RankManager.cheat_set_remaining_seconds(int(args[0]) if not args.is_empty() else 5)
	_refresh_rank_debug_consumers()

func _refresh_rank_debug_consumers() -> void :
	var home: Node = SceneManager.get_page("home")
	if home != null and home.visible:
		home.refresh_entry_ui()
	var rank: Node = SceneManager.get_page("rank")
	if rank != null and rank.visible:
		rank.cheat_refresh()


var _rank_first_collect_generation: int = 0

func _cmd_rank_first_collect_preview(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	_rank_first_collect_generation += 1
	var generation: int = _rank_first_collect_generation
	if not args.is_empty() and args[0] == "off":
		SceneManager.hide_page("rank_first_collect_preview")
		return
	await SceneManager.warm_page_threaded("rank_first_collect_preview")
	if generation == _rank_first_collect_generation:
		SceneManager.show_debug_panel("rank_first_collect_preview")


var _rank_trail_preview: CanvasLayer

func _cmd_rank_trail_preview(args: Array[String]) -> void :
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_rank_trail_preview):
			_rank_trail_preview.close()
		return
	if not is_instance_valid(_rank_trail_preview):
		_rank_trail_preview = load("res://scripts/debug/ui/rank_trail_preview.gd").new()
		get_tree().root.add_child(_rank_trail_preview)
	_rank_trail_preview.open()


var _countdown_lead_preview: CanvasLayer
var _hard_banner_animation_preview: CanvasLayer


func _cmd_countdown_lead_preview(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() > 1 or ( not args.is_empty() and args[0] != "off"):
		SceneManager.show_toast("加时白条：留空播放；off关闭")
		return
	if not args.is_empty():
		if is_instance_valid(_countdown_lead_preview):
			_countdown_lead_preview.close()
		return
	if not is_instance_valid(_countdown_lead_preview):
		_countdown_lead_preview = load("res://scripts/debug/ui/countdown_lead_preview.gd").new()
		get_tree().root.add_child(_countdown_lead_preview)
	_countdown_lead_preview.open()


func _cmd_super_hard_flower_banner_animation(args: Array[String]) -> void :
	_cmd_super_hard_banner_animation(args, true)


func _cmd_hard_flower_banner_animation(args: Array[String]) -> void :
	_cmd_hard_banner_animation(args, true)


func _cmd_super_hard_banner_animation(args: Array[String], flower_style: bool = false) -> void :
	var preview_args: Array[String] = []
	preview_args.append_array(args)
	if preview_args.is_empty():
		preview_args.append("super_hard")
	_cmd_hard_banner_animation(preview_args, flower_style)


func _cmd_hard_banner_animation(args: Array[String], flower_style: bool = false) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() > 1 or ( not args.is_empty() and args[0] not in ["hard", "super_hard", "off"]):
		var command: String = "hard_flower_banner_animation" if flower_style else "hard_banner_animation"
		SceneManager.show_toast("%s: hard / super_hard / off" % command)
		return
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_hard_banner_animation_preview):
			_hard_banner_animation_preview.close()
		return
	if not is_instance_valid(_hard_banner_animation_preview):
		_hard_banner_animation_preview = load("res://scripts/debug/ui/hard_banner_animation_preview.tscn").instantiate()
		get_tree().root.add_child(_hard_banner_animation_preview)
	_hard_banner_animation_preview.open( not args.is_empty() and args[0] == "super_hard", flower_style)


var _iq_motion_preview: CanvasLayer
func _cmd_iq_motion_preview(args: Array[String]) -> void :
	if not args.is_empty() and args[0] == "off":
		if is_instance_valid(_iq_motion_preview):
			_iq_motion_preview.close()
		return
	if not is_instance_valid(_iq_motion_preview):
		_iq_motion_preview = load("res://scripts/debug/ui/iq_motion_preview.gd").new()
		get_tree().root.add_child(_iq_motion_preview)
	_iq_motion_preview.open()


func _cmd_iq_genius_preview(args: Array[String]) -> void :
	if args.size() > 1 or ( not args.is_empty() and args[0] != "off"):
		SceneManager.show_toast("IQ Genius预览：留空播放；off关闭")
		return
	if not args.is_empty():
		if is_instance_valid(_iq_motion_preview):
			_iq_motion_preview.close()
		return
	if not is_instance_valid(_iq_motion_preview):
		_iq_motion_preview = load("res://scripts/debug/ui/iq_motion_preview.gd").new()
		get_tree().root.add_child(_iq_motion_preview)
	_iq_motion_preview.open(true)




func _cmd_grt_state(_args: Array[String]) -> void :
	print("[Cheat] GRT 状态: " + JSON.stringify(GrtManager.debug_state()))
	print("[Cheat] GRT 已发送: " + JSON.stringify(UserState.get_grt_sent_events()))


func _cmd_grt_hours(args: Array[String]) -> void :
	var hours: float = float(args[0]) if not args.is_empty() else 1.0
	GrtManager.set_debug_hours(hours)
	print("[Cheat] GRT 首开后小时 = %.3f（-1 为真实值）" % hours)
	GrtManager.force_evaluate()


func _cmd_grt_level(args: Array[String]) -> void :
	var n: int = int(args[0]) if not args.is_empty() else 3
	GrtManager.set_debug_completed_level(n)
	print("[Cheat] GRT 累计通关数 = %d（-1 为真实值）" % n)
	GrtManager.force_evaluate()


func _cmd_grt_inter(args: Array[String]) -> void :
	var n: int = maxi(0, int(args[0]) if not args.is_empty() else 0)
	UserState.cheat_set_grt_show_counts(n, UserState.get_grt_reward_show_count())
	print("[Cheat] GRT 插屏展示数 = %d" % n)
	GrtManager.force_evaluate()


func _cmd_grt_reward(args: Array[String]) -> void :
	var n: int = maxi(0, int(args[0]) if not args.is_empty() else 0)
	UserState.cheat_set_grt_show_counts(UserState.get_grt_inter_show_count(), n)
	print("[Cheat] GRT 激励展示数 = %d" % n)
	GrtManager.force_evaluate()


func _cmd_grt_ltv(args: Array[String]) -> void :
	var value: float = float(args[0]) if not args.is_empty() else 0.015
	MockUnikitConfig.set_mock_grt_ltv(value)
	GrtManager.set_debug_ltv(value)
	print("[Cheat] GRT LTV = %.6f" % value)


func _cmd_grt_anchor(args: Array[String]) -> void :
	var batch_id: String = args[0] if not args.is_empty() else "v1"
	var anchor: int = int(args[1]) if args.size() > 1 else GrtEventDefinition.ANCHOR_NEW
	if anchor < GrtEventDefinition.ANCHOR_UNSET or anchor > GrtEventDefinition.ANCHOR_NEW:
		SceneManager.show_toast("grt_anchor：anchor 只能是 0 / 1 / 2")
		return
	UserState.set_grt_new_install_anchor(batch_id, anchor)
	print("[Cheat] GRT batch=%s anchor=%d" % [batch_id, anchor])
	GrtManager.force_evaluate()


func _cmd_grt_eval(_args: Array[String]) -> void :
	GrtManager.force_evaluate()
	print("[Cheat] GRT 强制求值完成")


func _cmd_grt_reset(_args: Array[String]) -> void :
	UserState.cheat_clear_grt_state()
	GrtManager.rearm_anchors()
	print("[Cheat] GRT 状态已清空并重新评估 anchor")


var _checkin_preview_generation: int = 0
var _checkin_preview_dialog: Node
var _checkin_preview_loading: bool = false
var _checkin_preview_process_mode: int = Node.PROCESS_MODE_INHERIT
const CHECKIN_PREVIEW_REWARDS = preload("res://scripts/data/abtest/ab_configs/daily_first_win_checkin/daily_first_win_checkin_config.gd")

func _cmd_daily_checkin_preview(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() == 1 and args[0] == "off":
		_checkin_preview_generation += 1
		_checkin_preview_loading = false
		if _owns_checkin_preview(_checkin_preview_dialog):
			_checkin_preview_dialog.hide_panel()
			_checkin_preview_dialog.process_mode = _checkin_preview_process_mode
			_checkin_preview_dialog = null
		return
	if args.size() > 2 or (args.size() >= 1 and not args[0].is_valid_int()) or (args.size() == 2 and not args[1].is_valid_int()):
		SceneManager.show_toast("打卡预览：天数1～7 奖励组1/2；off关闭")
		return
	var day: int = int(args[0]) if not args.is_empty() else 4
	var group: int = int(args[1]) if args.size() == 2 else 1
	if day < 1 or day > 7 or group < 1 or group > 2:
		SceneManager.show_toast("天数请选择1～7，奖励组请选择1或2")
		return
	if _checkin_preview_loading:
		SceneManager.show_toast("打卡预览资源准备中，请稍候；off可取消")
		return
	var existing: Node = SceneManager.get_page("daily_first_win_checkin")
	if is_instance_valid(existing) and existing.visible and not _owns_checkin_preview(existing):
		SceneManager.show_toast("正式打卡正在播放，不能用预览覆盖")
		return
	if _owns_checkin_preview(_checkin_preview_dialog):
		_checkin_preview_dialog.hide_panel()
		_checkin_preview_dialog.process_mode = _checkin_preview_process_mode
		_checkin_preview_dialog = null
	_checkin_preview_generation += 1
	var generation: int = _checkin_preview_generation
	_checkin_preview_loading = true
	await SceneManager.warm_page_threaded("daily_first_win_checkin")
	if generation != _checkin_preview_generation:
		return
	_checkin_preview_loading = false

	existing = SceneManager.get_page("daily_first_win_checkin")
	if is_instance_valid(existing) and existing.visible:
		SceneManager.show_toast("正式打卡正在播放，预览已取消")
		return
	var rewards: Dictionary = CHECKIN_PREVIEW_REWARDS.rewards_for_group(group)
	var reward: int = int(rewards.get(day, 0))
	var before: int = UserState.get_coins()
	var result: Dictionary = {"day_index": day, "completed_days_before": day - 1, 
		"reward_by_day": rewards, "reward_coins": reward, "coins_before": before, 
		"coins_after": before + reward, "cheat_motion_preview": true}
	if not is_instance_valid(existing):
		SceneManager.show_toast("打卡预览资源未准备好")
		return

	_checkin_preview_process_mode = existing.process_mode
	existing.process_mode = Node.PROCESS_MODE_ALWAYS
	var dialog: Node = SceneManager.show_dlg("daily_first_win_checkin", {"settlement": result})
	if not is_instance_valid(dialog):
		SceneManager.show_toast("打卡预览未能打开")
		return
	_checkin_preview_dialog = dialog
	var preview_started: bool = false
	while generation == _checkin_preview_generation and is_instance_valid(dialog) and not dialog.is_closed():


		if _owns_checkin_preview(dialog):
			preview_started = true
		elif preview_started:
			_checkin_preview_dialog = null
			return
		await get_tree().process_frame
	if generation != _checkin_preview_generation:
		return
	if _owns_checkin_preview(dialog):
		SceneManager.hide_dlg("daily_first_win_checkin")
		while generation == _checkin_preview_generation and is_instance_valid(dialog) and dialog.visible:
			await get_tree().process_frame
		if generation == _checkin_preview_generation and is_instance_valid(dialog):
			dialog.process_mode = _checkin_preview_process_mode
			_checkin_preview_dialog = null

func _owns_checkin_preview(dialog: Node) -> bool:
	if not is_instance_valid(dialog) or dialog != _checkin_preview_dialog:
		return false
	var presentation: Node = dialog.get_node_or_null("Presentation")
	return is_instance_valid(presentation) and bool(presentation.settlement.get("cheat_motion_preview", false))


var _rank_collectible_preview_request: int = 0

func _cmd_rank_collectible_flow_preview(args: Array[String]) -> void :
	_rank_collectible_preview_request += 1
	var request: int = _rank_collectible_preview_request
	if OS.has_feature("rel"):
		return
	if not args.is_empty() and args != ["off"]:
		SceneManager.show_toast("rank_collectible_flow_preview / rank_collectible_flow_preview off")
		return
	if not args.is_empty() and args[0] == "off":
		SceneManager.hide_page("rank_collectible_flow_preview")
		return
	await SceneManager.warm_page_threaded("rank_collectible_flow_preview")
	if request == _rank_collectible_preview_request:
		SceneManager.show_debug_panel("rank_collectible_flow_preview")

var _timed_endless_motion_request: int = 0

func _cmd_timed_endless_motion(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		return
	if args.size() > 1 or ( not args.is_empty() and args[0] not in ["flow", "start", "end", "off"]):
		SceneManager.show_toast("timed_endless_motion flow / start / end / off")
		return
	_timed_endless_motion_request += 1
	var request: int = _timed_endless_motion_request
	var mode: String = args[0] if not args.is_empty() else "flow"
	if mode == "off":
		SceneManager.hide_page("timed_endless_popup_preview")
		return
	await SceneManager.warm_page_threaded("timed_endless_popup_preview")
	if request == _timed_endless_motion_request:
		SceneManager.show_debug_panel("timed_endless_popup_preview", {"mode": mode})

func _cmd_hint_guide_motion(args: Array[String]) -> void :
	var mode: String = args[0] if args.size() == 1 else "on"
	if args.size() > 1 or mode not in ["on", "once", "off"]:
		SceneManager.show_toast("Hint动效参数：on / once / off")
		return
	var page: JuiceGamePage = SceneManager.get_page("game") as JuiceGamePage
	if not is_instance_valid(page) or not page.is_visible_in_tree() or not page._prop_ui.has("hint"):
		SceneManager.show_toast("请先进入已显示Hint按钮的游戏页")
		return
	var btn: PropBtn = page._prop_ui["hint"]["btn"]
	if mode == "off":
		page._clear_hint_guide_motion(true)
		return
	if not btn.play_hint_guide_motion(mode == "on", false):
		SceneManager.show_toast("Hint当前不可用，或其他引导正在播放")



func _cmd_proxy(args: Array[String]) -> void :
	if OS.has_feature("rel"):
		SceneManager.show_toast("rel 包不支持抓包代理")
		return
	if args.is_empty():
		var status: String = "%s:%d" % [UserState.get_debug_proxy_host(), UserState.get_debug_proxy_port()] if UserState.has_debug_proxy() else "已关闭"
		SceneManager.show_toast("抓包代理：%s" % status)
		return
	if args.size() == 1 and args[0].to_lower() in ["off", "--"]:
		UserState.clear_debug_proxy()
		SortLogger.info("[Cheat] 抓包代理已关闭，后续新建请求直连")
		SceneManager.show_toast("抓包代理已关闭，后续新建请求直连")
		return
	if args.size() != 2:
		SceneManager.show_toast("用法：proxy <电脑IP或主机名> <端口> / proxy off")
		return
	var host: String = args[0].strip_edges()
	if host.is_empty() or host.contains("://") or host.contains("/"):
		SceneManager.show_toast("代理地址只填电脑IP或主机名，不带协议或路径")
		return
	if not args[1].is_valid_int() or int(args[1]) < 1 or int(args[1]) > 65535:
		SceneManager.show_toast("代理端口必须是 1～65535 的整数")
		return
	var port: int = int(args[1])
	UserState.set_debug_proxy(host, port)
	SortLogger.info("[Cheat] 抓包代理 = %s:%d，后续新建请求生效，跨重启保留" % [host, port])
	SceneManager.show_toast("抓包代理：%s:%d，后续新建请求生效" % [host, port])
