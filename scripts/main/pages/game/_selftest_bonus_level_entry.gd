extends SceneTree







class FakeSource extends LevelSource:
	var meta: LevelModel = null
	var queries: int = 0

	func get_level_model(_chapter_index: int, _level_index: int) -> LevelModel:
		queries += 1
		return meta



class CountingParser extends JuiceLevelParser:
	var calls: int = 0
	var return_base_model: bool = false

	func parse_level(meta: LevelModel, fallback_result: Dictionary = {}) -> LevelModel:
		calls += 1
		if return_base_model:
			return LevelModel.new()
		return super.parse_level(meta, fallback_result)

	func _debug_override_for(_level_id: int) -> Variant:
		return null



class RecordingSaver extends LevelSaver:
	var writes: int = 0

	func load_entity(_level_id: int) -> LevelEntity:
		return null

	func save_initial(_level_id: int, _raw_level_info: Dictionary, _initial_state: Dictionary) -> String:
		writes += 1
		return "test"

	func save_state(_level_id: int, _current_state: Dictionary, _play_time_delta_ms: int = 0, 
			_round_ms: int = -1) -> void :
		writes += 1

	func clear_state(_level_id: int) -> void :
		writes += 1



class FakeBonusConfig extends BonusLevel2Config:
	var enabled: bool = true
	var reads: int = 0
	var dyes: int = 0

	func value() -> int:
		reads += 1
		return VALUE_EXPERIMENT if enabled else VALUE_CONTROL

	func reload_value() -> void :
		dyes += 1



const ROW_SINGLE: Dictionary = {"capacity": 3, "targetCups": 3, 
	"initial": ["-|", "0|1,2,0", "1|2,0,1", "2|0,1,2"], "incoming": []}

const ROW_NO_SINGLE: Dictionary = {"capacity": 2, "targetCups": 4, 
	"initial": ["0|0,1", "0|1,0", "1|0,1", "1|1,0"], "incoming": []}

const ROW_INCOMING_MULTI: Dictionary = {"capacity": 2, "targetCups": 4, 
	"initial": ["-|", "0|1,0", "1|0,1"], "incoming": ["0|1,0", "1|0,1"]}

const ROW_INCOMING_SINGLE: Dictionary = {"capacity": 2, "targetCups": 5, 
	"initial": ["0|0,1", "0|1,0", "1|0,1", "1|1,0"], "incoming": ["2|2,2"]}

const ROW_YELLOW_INCOMING: Dictionary = {"capacity": 2, "targetCups": 5, 
	"initial": ["0|0,0", "1|1,1", "1|1,1", "1|1,1"], "incoming": ["2|2,2"]}

var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")



func _run() -> void :
	var original_source: LevelSource = LevelManager._source
	var original_parsers: Dictionary = LevelManager._parsers
	var original_saver: LevelSaver = LevelManager._saver
	var original_config: BonusLevel2Config = ABManager.bonus_level2
	var original_configs: Dictionary = ABManager._configs_by_key
	var original_ready: bool = ABManager._is_init_done
	var original_locked: bool = ABManager._startup_control_locked
	var daily_count: int = UserState._daily_round_count
	var current_level: int = UserState.get_current_level()
	var coins: int = UserState.get_coins()
	var source: = FakeSource.new(null, null)
	var parser: = CountingParser.new()
	var saver: = RecordingSaver.new()
	var config: = FakeBonusConfig.new()
	LevelManager._source = source
	LevelManager._parsers = {"": parser}
	LevelManager._saver = saver
	ABManager.bonus_level2 = config
	ABManager._configs_by_key = {"bonus_level2.0": config}
	ABManager._is_init_done = false
	ABManager._startup_control_locked = false


	_check(BonusLevelEntry.is_next_bonus(13, {"bonus_type": 0}), "SDK 未就绪也应沿用已保存金币关")
	_check(BonusLevelEntry.is_next_bonus(14, {"bonus_type": 2}), "续局身份不按候选关规则重算")
	_check(BonusLevelEntry.is_next_bonus(28, {"bonus_type": 1}), "非候选关号续局也保留已保存身份")
	_check( not BonusLevelEntry.is_next_bonus(13, {"bonus_type": -1}), "快照已跳过奖励关不能重新开启")
	_check( not BonusLevelEntry.is_next_bonus(13, {"cols": [1]}), "旧快照缺 bonus_type 时保持普通关")
	_check(parser.calls == 0 and source.queries == 0 and config.reads == 0 and config.dyes == 0, 
		"续局资格只读快照，不选题、不读 AB、不染色")


	_set_row(source, 13, ROW_SINGLE)
	_check(BonusLevelEntry.is_next_bonus(13), "SDK 未就绪时候选关按 1.0 口径继续判断")
	_check(parser.calls == 1 and config.dyes == 0, "SDK 未就绪不染色，但仍读取单关题面")
	_check( not BonusLevelEntry.is_v2_enabled(), "SDK 未就绪按 1.0 口径")

	ABManager._is_init_done = true
	_set_row(source, 13, ROW_SINGLE)
	_check( not BonusLevelEntry.is_next_bonus(12), "普通关即使有单盆颜色也不显示 Bonus")
	for level_id: int in [3, 10, 12, 14, 17, 18, 20, 30, 47]:
		_check( not BonusLevelEntry.is_next_bonus(level_id), "第 %d 关新局不应显示 Bonus" % level_id)
	_check(parser.calls == 1 and config.dyes == 0, "普通关不访问题面或染色")


	config.enabled = false
	_check( not BonusLevelEntry.is_v2_enabled(), "对照组按 1.0 口径")
	_check(BonusLevelEntry.is_next_bonus(13), "1.0 对照组候选关应显示 Bonus")
	_check(parser.calls == 2 and config.dyes == 1, "候选关解析一次并在展示前染色")


	config.enabled = true
	var raw_before: String = JSON.stringify(source.meta._content)
	_check(BonusLevelEntry.is_v2_enabled(), "实验组按 2.0 口径")
	_check(BonusLevelEntry.is_next_bonus(13), "2.0 实验组候选关应显示 Bonus")
	_check(parser.calls == 3 and config.dyes == 2, "2.0 候选关同样解析一次并染色")
	_check(JSON.stringify(source.meta._content) == raw_before, "资格判断不改原题面或写金币替换方案")


	for level_id: int in [23, 33]:
		_set_row(source, level_id, ROW_SINGLE)
		_check(BonusLevelEntry.is_next_bonus(level_id), "第 %d 关合格题面应显示 Bonus" % level_id)
	_set_row(source, 18, ROW_SINGLE)
	_check( not BonusLevelEntry.is_next_bonus(18), "第 18 关不是候选关（候选关号为 13/23/33…）")


	_set_row(source, 43, ROW_INCOMING_SINGLE)
	config.enabled = false
	var dyes_before_v1: int = config.dyes
	_check(BonusLevelEntry.is_next_bonus(43), "1.0 补货列单盆颜色也满足资格")
	_check(config.dyes == dyes_before_v1 + 1, "1.0 命中候选关时染色")
	config.enabled = true
	var dyes_before_v2_skip: int = config.dyes
	_check( not BonusLevelEntry.is_next_bonus(43), "2.0 单盆颜色只在补货列、首屏看不到时不满足资格")

	_check(config.dyes == dyes_before_v2_skip + 1, "2.0 选不出金猪而回落普通关时仍应染色")


	_set_row(source, 53, ROW_YELLOW_INCOMING)
	_check(BonusLevelEntry.is_next_bonus(53), "2.0 首屏有单盆颜色时仍满足资格")
	config.enabled = false
	_check(BonusLevelEntry.is_next_bonus(53), "1.0 同样满足资格")


	_set_row(source, 63, ROW_NO_SINGLE)
	_check( not BonusLevelEntry.is_next_bonus(63), "没有单盆颜色的候选关显示普通关")
	_set_row(source, 73, ROW_INCOMING_MULTI)
	_check( not BonusLevelEntry.is_next_bonus(73), "补货花盆必须计入，白盆不能当成候选颜色")


	_set_row(source, 13, ROW_SINGLE)
	config.enabled = true
	var dyes_before: int = config.dyes
	_check(BonusLevelEntry.is_next_bonus(13, {}, false), "不曝光时仍可判断新局资格")
	_check(config.dyes == dyes_before, "expose=false 不新增染色")


	config.enabled = false
	var calls_before: int = parser.calls
	_check(BonusLevelEntry.is_next_bonus(13, {"bonus_type": 1}), "当前 AB 关闭不改变金币续局身份")
	_check( not BonusLevelEntry.is_next_bonus(13, {"bonus_type": -1}), "当前题面合格也不能覆盖普通续局身份")
	_check(parser.calls == calls_before, "两种续局都不重读题面")


	config.enabled = true
	source.meta = null
	_check( not BonusLevelEntry.is_next_bonus(13), "章节数据暂缺时返回非 Bonus，不访问空模型")
	_set_row(source, 13, ROW_SINGLE)
	parser.return_base_model = true
	_check( not BonusLevelEntry.is_next_bonus(13), "非 juice_sort 内容模型不能读取 juice 字段")
	_check(saver.writes == 0 and UserState._daily_round_count == daily_count
		and UserState.get_current_level() == current_level and UserState.get_coins() == coins, 
		"首页资格不写存档、不增加开局计数、不改关号或金币")


	LevelManager._source = original_source
	LevelManager._parsers = original_parsers
	LevelManager._saver = original_saver
	ABManager.bonus_level2 = original_config
	ABManager._configs_by_key = original_configs
	ABManager._is_init_done = original_ready
	ABManager._startup_control_locked = original_locked
	if _failures.is_empty():
		SortLogger.info("BONUS_LEVEL_ENTRY_SELFTEST PASS")
	else:
		SortLogger.error("BONUS_LEVEL_ENTRY_SELFTEST FAIL: %s" % JSON.stringify(_failures))
	quit(0 if _failures.is_empty() else 1)



func _set_row(source: FakeSource, level_id: int, row: Dictionary) -> void :
	var juice: JuiceLevel = JuiceLevel.from_dict(row)
	_check(juice.validate().is_empty(), "单关夹具必须合法：%s" % str(juice.validate()))
	var meta: = LevelModel.new()
	meta.level_id = level_id
	meta.chapter_index = LevelIndex.chapter_of(level_id)
	meta.level_index = LevelIndex.index_of(level_id)
	meta._content = row.duplicate(true)
	meta._content_parsed = true
	source.meta = meta



func _check(ok: bool, message: String) -> void :
	if not ok:
		_failures.append(message)
