extends SceneTree








class FakeAbGateway extends RefCounted:
	var ready: bool = true
	var published: Dictionary = {}
	var values: Dictionary = {}
	var dyed_keys: Array[String] = []

	func is_ab_init_done() -> bool:
		return ready

	func get_all_ab_experiments() -> Dictionary:
		return published

	func get_ab_string(key: String, default_value: String = "") -> String:
		return String(values.get(key, default_value))

	func dye_ab(key: String) -> void :
		dyed_keys.append(key)


var _ok: bool = true
var _checks: int = 0


func _initialize() -> void :
	_test_key_parsing()
	_test_needs_fetch()
	_test_matching()
	_test_index_patches()
	_test_merge_entry()
	_test_gateway_and_dye()
	_finish()


func _test_key_parsing() -> void :
	var parsed: Dictionary = ContentLevelExperimentResolver.parse_key("content_sg||level||3_4")
	_chk("合法 key 解析成功", bool(parsed.ok))
	_chk("合法 key 起始章", int(parsed.start) == 3)
	_chk("合法 key 结束章", int(parsed.end) == 4)

	for invalid_key: String in [
		"content_sg||level||_1_1", 
		"content_sg||level||1__2", 
		"content_sg||level||1_1_", 
		"content_sg||level||0_1", 
		"content_sg||level||4_3", 
		"content_sg||level||1_x", 
		"content_sg||level||5", 
		"content_sg||level_pic||1_2", 
		"other_key", 
	]:
		_chk("非法 key 被拒: %s" % invalid_key, 
			not bool(ContentLevelExperimentResolver.parse_key(invalid_key).ok))


func _test_needs_fetch() -> void :
	_chk("策略池名要拉", ContentLevelExperimentResolver.needs_fetch("pool_a"))
	_chk("空值不拉", not ContentLevelExperimentResolver.needs_fetch(""))
	_chk("default 不拉", not ContentLevelExperimentResolver.needs_fetch("default"))
	_chk("Default 大小写容错", not ContentLevelExperimentResolver.needs_fetch(" Default "))


func _test_matching() -> void :
	var keys: Array = [
		"content_sg||level||1_1", 
		"content_sg||level||3_4", 
		"other_key", 
	]
	_chk("范围起点命中", 
		ContentLevelExperimentResolver.match_keys_for_chapter(keys, 3).size() == 1)
	_chk("范围终点命中", 
		ContentLevelExperimentResolver.match_keys_for_chapter(keys, 4).size() == 1)
	_chk("范围外不命中", 
		ContentLevelExperimentResolver.match_keys_for_chapter(keys, 2).is_empty())

	keys.append("content_sg||level||4_5")
	var overlapping: Array[String] = ContentLevelExperimentResolver.match_keys_for_chapter(keys, 4)
	_chk("重叠实验全部返回", overlapping.size() == 2)
	_chk("重叠实验按区间起点稳定排序", overlapping[0] == "content_sg||level||3_4")


	var inner: Array = ["content_sg||level||8_9"]
	_chk("内含区间与批次有交集", 
		ContentLevelExperimentResolver.match_keys_overlapping(inner, 6, 10).size() == 1)
	_chk("内含区间不覆盖批次首章", 
		ContentLevelExperimentResolver.match_keys_for_chapter(inner, 6).is_empty())
	_chk("无交集批次不拉", 
		ContentLevelExperimentResolver.match_keys_overlapping(inner, 1, 5).is_empty())


func _test_index_patches() -> void :

	var basic: Dictionary = ContentLevelExperimentResolver.index_patches(
		[{"chapterIndex": 2, "levelIndex": 3}], 1, 5)
	_chk("key 是全局关号", basic.has(28))

	var raw: Array = [
		{"chapterIndex": 3, "levelIndex": 1}, 
		{"chapterIndex": 4, "levelIndex": 2}, 
		{"chapterIndex": 6, "levelIndex": 1}, 
		"not a dictionary", 
	]
	var picked: Dictionary = ContentLevelExperimentResolver.index_patches(raw, 3, 4)
	_chk("区间内关被采纳", picked.has(LevelIndex.level_id_of(3, 1))\
	and picked.has(LevelIndex.level_id_of(4, 2)))
	_chk("区间外关被丢弃", not picked.has(LevelIndex.level_id_of(6, 1)))
	_chk("非法条目被丢弃", picked.size() == 2)



	var crossed: Dictionary = ContentLevelExperimentResolver.index_patches(
		[{"chapterIndex": 1, "levelIndex": 30}], 1, 5)
	_chk("跨章闸门：levelIndex 越界被丢弃", crossed.is_empty())
	_chk("跨章闸门：没有污染到隔壁章的关号", not crossed.has(30))


	_chk("idx == CHAPTER_SIZE 合法", ContentLevelExperimentResolver.index_patches(
		[{"chapterIndex": 1, "levelIndex": LevelIndex.CHAPTER_SIZE}], 1, 5).has(25))
	for bad: Dictionary in [
		{"chapterIndex": 1, "levelIndex": 0}, 
		{"chapterIndex": 1, "levelIndex": -1}, 
		{"chapterIndex": 0, "levelIndex": 1}, 
	]:
		_chk("非法关号被丢弃: %s" % str(bad), 
			ContentLevelExperimentResolver.index_patches([bad], 1, 5).is_empty())


	var multi: Dictionary = ContentLevelExperimentResolver.index_patches([
		{"chapterIndex": 1, "levelIndex": 1, "tag": "first"}, 
		{"chapterIndex": 1, "levelIndex": 1, "tag": "second"}, 
	], 1, 5)
	var bucket: Array = multi[1] as Array
	_chk("同关号多条全部保留成候选", bucket.size() == 2)
	_chk("候选顺序即服务端下发顺序", 
		String((bucket[0] as Dictionary).tag) == "first"\
		and String((bucket[1] as Dictionary).tag) == "second")

	_chk("空数组 → 空表", ContentLevelExperimentResolver.index_patches([], 1, 5).is_empty())



func _test_merge_entry() -> void :
	var base: Dictionary = {
		"levelIndex": 3, 
		"levelUniqueId": "uid-default", 
		"levelUserTags": "default", 
		"stepLimit": 7, 
		"imageUrl": "img-default", 
		"animation": "", 
		"difficulty": 12, 
		"difficultyType": "Normal", 
		"initialLayout": "LAYOUT-DEFAULT", 
		"levelDataSource": "full", 
	}
	var patch: Dictionary = {
		"chapterIndex": 1, 
		"levelIndex": 3, 
		"difficultyType": "Hard", 
		"initialLayout": "LAYOUT-POOL", 
		"levelDataSource": "pool", 
	}
	var merged: Dictionary = ContentLevelExperimentResolver.merge_entry(base, patch)

	_chk("patch 字段覆盖: initialLayout", String(merged.initialLayout) == "LAYOUT-POOL")
	_chk("patch 字段覆盖: difficultyType", String(merged.difficultyType) == "Hard")
	_chk("patch 字段覆盖: levelDataSource", String(merged.levelDataSource) == "pool")

	_chk("保留 default: levelUniqueId", String(merged.levelUniqueId) == "uid-default")
	_chk("保留 default: levelUserTags", String(merged.levelUserTags) == "default")
	_chk("保留 default: stepLimit", int(merged.stepLimit) == 7)
	_chk("保留 default: imageUrl", String(merged.imageUrl) == "img-default")
	_chk("保留 default: animation", merged.has("animation"))
	_chk("保留 default: difficulty", int(merged.difficulty) == 12)
	_chk("patch 独有字段进入结果", int(merged.chapterIndex) == 1)


	var blanked: Dictionary = ContentLevelExperimentResolver.merge_entry(base, {"imageUrl": ""})
	_chk("patch 给空串也覆盖", String(blanked.imageUrl) == "")


	_chk("base 未被原地修改", String(base.levelDataSource) == "full"\
	and String(base.initialLayout) == "LAYOUT-DEFAULT")


func _test_gateway_and_dye() -> void :
	var gateway: = FakeAbGateway.new()
	var key: = "content_sg||level||1_1"
	gateway.published[key] = "SDK 列表值不作为最终分组值"
	gateway.values[key] = "pool_a"
	var resolver: = ContentLevelExperimentResolver.new(gateway)

	_chk("value 取 SDK string 真值", resolver.value_of(key) == "pool_a")
	resolver.dye_for_chapter(1)
	_chk("命中章号染对应 key", gateway.dyed_keys == [key])


	gateway.values[key] = ""
	resolver.dye_for_chapter(1)
	_chk("空 value 仍染色", gateway.dyed_keys == [key, key])
	gateway.values[key] = "default"
	resolver.dye_for_chapter(1)
	_chk("default 仍染色", gateway.dyed_keys == [key, key, key])

	gateway.dyed_keys.clear()
	resolver.dye_for_chapter(2)
	_chk("范围外章不染色", gateway.dyed_keys.is_empty())

	gateway.ready = false
	_chk("SDK 未就绪枚举不到 key", resolver.all_keys().is_empty())
	resolver.dye_for_chapter(1)
	_chk("SDK 未就绪不染色", gateway.dyed_keys.is_empty())


func _chk(name: String, condition: bool) -> void :
	_checks += 1
	if condition:
		return
	_ok = false
	print("  ✗ %s" % name)


func _finish() -> void :
	print("—— %d 项断言 ——" % _checks)
	print("PASS" if _ok else "FAIL")
	quit(0 if _ok else 1)
