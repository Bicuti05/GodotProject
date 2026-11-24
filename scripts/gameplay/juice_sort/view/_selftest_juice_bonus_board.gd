extends SceneTree











const BOARD_SCENE: = "res://scripts/gameplay/juice_sort/view/juice_board_view.tscn"

const ROW: = {"capacity": 2, "targetCups": 3, 
	"initial": ["0|0,1", "0|1,0", "1|0,0"], "incoming": []}

var _failures: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :

	var board_scene: PackedScene = load(BOARD_SCENE) as PackedScene
	var level: JuiceLevel = JuiceLevel.from_dict(ROW)
	_check(level.validate().is_empty(), "夹具题面应合法: %s" % str(level.validate()))
	var board: Variant = board_scene.instantiate()
	board.size = Vector2(1080, 1304)
	root.add_child(board)

	var coin: Texture2D = board.get("bonus_coin_texture") as Texture2D
	var pig: Texture2D = board.get("bonus_pig_texture") as Texture2D
	_check(coin != null and pig != null, "场景应绑定金币与金猪贴图")


	board.call("set_bonus_candidate", false)
	board.call("setup", level, {}, PackedInt32Array([0, 1]))
	_check(int(board.call("bonus_type")) == -1, "非候选局应无金猪")
	_check(board.call("fruit_texture", 1) != coin, "非候选局花朵不应是金币图")


	board.call("set_bonus_candidate", true)
	board.call("setup", level, {}, PackedInt32Array([0, 1]))
	_check(int(board.call("bonus_type")) == 1, "候选局应选只有 1 盆的 1 号色")
	_check(board.call("fruit_texture", 1) == coin, "金猪颜色的花应为金币图")
	_check(board.call("full_blender_texture_for_type", 1) == pig, "金猪颜色的盆应为金猪图")
	_check(board.call("fruit_texture", 0) != coin, "其他颜色不应换成金币")
	_check(board.call("full_blender_texture_for_type", 0) != pig, "其他颜色的盆不应换成金猪")


	var yellow_rope: Texture2D = (board.get("rope_top_textures") as Array)[JuiceBonusLevel.YELLOW_SLOT]
	_check(board.call("_rope_top_tex", 1) == yellow_rope, "金猪列的绳子应为黄色")
	_check(board.call("_rope_top_tex", 0) != yellow_rope, "非金猪列的绳子不应用黄色")


	var yellow_tint: Color = JuiceTheme.color_of_slot(JuiceBonusLevel.YELLOW_SLOT, board.get("_skin"))
	_check(board.call("_unlock_glow_tint", 1) == yellow_tint, "金猪列的解锁光点应为黄色")
	_check(board.call("_unlock_glow_tint", 0) == board.call("color_for_type", 0), 
		"非金猪列的解锁光点应继承本列花色")

	var snap: Dictionary = board.call("snapshot")
	_check(int(snap.get("bonus_type", -9)) == 1, "快照应带 bonus_type=1")
	_check(int(snap.get("bonus_recolor_from", -9)) == -1, "无换色时快照不应带换色映射")


	board.call("set_bonus_candidate", false)
	_check(bool(board.call("restore", level, snap, PackedInt32Array([0, 1]))), "续局恢复应成功")
	_check(int(board.call("bonus_type")) == 1, "续局应从快照读回金猪颜色")
	_check(board.call("fruit_texture", 1) == coin, "续局仍应显示金币")


	var old: Dictionary = snap.duplicate(true)
	old.erase("bonus_type")
	_check(bool(board.call("restore", level, old, PackedInt32Array([0, 1]))), "老存档应能恢复")
	_check(int(board.call("bonus_type")) == -1, "老存档无 bonus_type 时应无金猪")
	var bad: Dictionary = snap.duplicate(true)
	bad["bonus_type"] = 99
	board.call("restore", level, bad, PackedInt32Array([0, 1]))
	_check(int(board.call("bonus_type")) == -1, "越界 bonus_type 应被忽略")


	board.call("set_bonus_candidate", true)
	board.call("setup", level, {}, PackedInt32Array([4, 0]))
	_check(int(board.call("bonus_type")) == 1, "黄盆多个时应选只有 1 盆的 1 号色")
	_check(int(board.call("slot_for_type", 0)) == int(board.call("slot_for_type", 1)), 
		"黄色类型的槽位应改为被替换颜色的槽位")
	_check(board.call("fruit_texture", 0) != coin, "黄色花应显示成被替换颜色的普通花，而不是金币")
	_check(board.call("full_blender_texture_for_type", 0) != pig, "黄色盆仍应是普通盆")
	var pig_pots: int = 0
	for t: int in level.types:
		if board.call("full_blender_texture_for_type", t) == pig:
			pig_pots += 1
	_check(pig_pots == 1, "全场应只有 1 只金猪(实际 %d)" % pig_pots)

	_check(board.call("_rope_top_tex", 1) == yellow_rope, "换色后金猪列的绳子仍应为黄色")
	_check(board.call("_rope_top_tex", 0) != yellow_rope, "换色后黄色列的绳子应改为被替换颜色的绳子")
	var recolor_snap: Dictionary = board.call("snapshot")
	_check(int(recolor_snap.get("bonus_recolor_from", -9)) == 0, "快照应带换色来源 0")
	_check(int(recolor_snap.get("bonus_recolor_to", -9)) == 1, "快照应带换色目标 1")


	board.call("set_bonus_candidate", false)
	board.call("setup", level, {}, PackedInt32Array([4, 0]))
	_check(int(board.call("slot_for_type", 0)) != int(board.call("slot_for_type", 1)), 
		"未恢复换色前黄色槽位应是原槽位")
	_check(bool(board.call("restore", level, recolor_snap, PackedInt32Array([4, 0]))), "换色方案续局应成功")
	_check(int(board.call("bonus_type")) == 1, "换色方案续局应读回金猪颜色")
	_check(int(board.call("slot_for_type", 0)) == int(board.call("slot_for_type", 1)), 
		"换色方案续局应恢复槽位映射")
	_check(board.call("full_blender_texture_for_type", 0) != pig, "换色方案续局黄色盆仍应是普通盆")

	_finish()


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)


func _finish() -> void :
	if _failures.is_empty():
		print("[selftest_juice_bonus_board] ALL PASS")
		quit(0)
		return
	for f: String in _failures:
		printerr("[selftest_juice_bonus_board] FAIL: " + f)
	quit(1)
