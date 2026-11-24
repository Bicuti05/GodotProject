extends Node









const KEY: String = "user_level_v1"

var _ok: bool = true
var _checks: int = 0


func _ready() -> void :
	var none: Array[Dictionary] = []

	var lv8: Array[Dictionary] = [
		_c("default", "A", "1"), _c("user_level_v1:lv2", "B", "1"), 
		_c("user_level_v1:lv3,lv4,lv5", "C", "5")]
	_chk("lv3 降一档取 lv2 的题，不看 difficulty", 
		_layout(LevelProvider.pick_downgrade(lv8, none, _chain(3))) == "B")
	_chk("lv2 降一档取 default", 
		_layout(LevelProvider.pick_downgrade(lv8, none, _chain(2))) == "A")
	_chk("lv4 与 lv3 同题，继续往下取 lv2", 
		_layout(LevelProvider.pick_downgrade(lv8, none, _chain(4))) == "B")
	_chk("返回的标签是降级题所用档位", 
		LevelProvider.pick_downgrade(lv8, none, _chain(4)).get("tags", {}) == {KEY: "lv2"})

	var shared: Array[Dictionary] = [
		_c("default", "A", ""), _c("user_level_v1:lv2,lv3", "A", "")]
	_chk("一直到 default 都是同一道题不换题", 
		LevelProvider.pick_downgrade(shared, none, _chain(3)).is_empty())
	_chk("lv1 用户（只剩 default 且同题）不换题", 
		LevelProvider.pick_downgrade(lv8, none, _chain(1)).is_empty())
	_chk("尚未起步（无档位）不换题", 
		LevelProvider.pick_downgrade(lv8, none, [{}] as Array[Dictionary]).is_empty())


	var base_shared: Array[Dictionary] = [
		_c("default", "A", "1", "id_a"), _c("user_level_v1:lv2", "B", "2", "id_b"), 
		_c("user_level_v1:lv3,lv4,lv5", "B", "2", "id_b")]
	var patches: Array[Dictionary] = [
		_p("default", "PA"), _p("user_level_v1:lv2", "PB"), _p("user_level_v1:lv3,lv4,lv5", "PC")]
	var hit: Dictionary = LevelProvider.pick_downgrade(base_shared, patches, _chain(3))
	_chk("策略池参与选题：lv3 降到策略池 lv2 的题面", _layout(hit) == "PB")
	_chk("同 id 但题面不同算不同题，降级题沿用基线 id", 
		String((hit.get("merged", {}) as Dictionary).get("levelUniqueId", "")) == "id_b")
	_chk("原题是策略池 lv3 的题面", 
		str((hit.get("base", {}) as Dictionary).get("initialLayout", "")) == "PC")
	_chk("同一份配置反复降级结果不变（以原题为基准）", 
		_layout(LevelProvider.pick_downgrade(base_shared, patches, _chain(3))) == "PB")

	_chk("无题面时按 levelUniqueId 判同题", 
		LevelProvider.is_same_level({"levelUniqueId": "X"}, {"levelUniqueId": "X"})
		and not LevelProvider.is_same_level({"levelUniqueId": "X"}, {"levelUniqueId": "Y"}))
	print("—— %d 项断言 ——" % _checks)
	print("PASS" if _ok else "FAIL")
	get_tree().quit(0 if _ok else 1)



func _chain(user_level: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level: int in range(user_level, 0, -1):
		out.append({KEY: "lv%d" % level})
	out.append({})
	return out


func _c(tag: String, layout: String, grade: String, unique_id: String = "") -> Dictionary:
	var out: Dictionary = {"levelUserTags": tag, "initialLayout": layout, 
		"levelUniqueId": unique_id if not unique_id.is_empty() else layout}
	if not grade.is_empty():
		out["difficulty"] = grade
	return out


func _p(tag: String, layout: String) -> Dictionary:
	return {"levelUserTags": tag, "initialLayout": layout}


func _layout(picked: Dictionary) -> String:
	return str((picked.get("merged", {}) as Dictionary).get("initialLayout", ""))


func _chk(name: String, condition: bool) -> void :
	_checks += 1
	if condition:
		return
	_ok = false
	print("  ✗ %s" % name)
