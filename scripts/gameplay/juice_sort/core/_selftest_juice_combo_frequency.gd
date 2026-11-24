extends SceneTree

const Tracker = preload("res://scripts/gameplay/juice_sort/core/juice_combo_frequency_tracker.gd")


func _initialize() -> void :
	for capacity: int in [2, 3, 4, 5]:
		for skip: int in [2, 3]:
			var tracker = Tracker.new( func() -> int: return skip)
			tracker.reset(capacity, 12)
			var cups: Array[int] = []
			var counts: Array[int] = []
			for done: int in range(1, 13):
				var result: Array[int] = tracker.on_move(done)
				if not result.is_empty():
					cups.append(done)
					counts.append_array(result)
			assert (cups == ([1, 4, 7, 10, 12] if skip == 2 else [1, 5, 9, 12]), "跳过口径和末盆正确")
			assert (counts == ([1, 2, 3, 4, 5] if skip == 2 else [1, 2, 3, 4]), "反馈逐次累计")
	for capacity: int in [6, 7, 10]:
		var tracker = Tracker.new( func() -> int: assert (false, "固定间隔不读取随机源");return 3)
		tracker.reset(capacity, 7)
		assert (tracker.on_move(7) == [1, 2, 3], "级联逐盆计算，末盆与间隔重合仅触发一次")
		assert (tracker.on_move(7).is_empty(), "同一盘面不重复触发")
	var draws: Array[int] = [2, 3, 2, 3]
	var random_tracker = Tracker.new( func() -> int: return draws.pop_front())
	random_tracker.reset(4, 9)
	assert (random_tracker.on_move(1) == [1] and random_tracker.on_move(3).is_empty(), "首盆反馈，跳过两盆")
	assert (random_tracker.on_move(4) == [2] and random_tracker.on_move(7).is_empty(), "重新抽取跳过三盆")
	assert (random_tracker.on_move(8) == [3] and random_tracker.on_move(9) == [4], "末盆强制，不要求满足间隔")
	var tracker = Tracker.new( func() -> int: return 2)
	tracker.reset(6, 30)
	assert (tracker.on_move(1) == [1] and tracker.on_move(2).is_empty(), "第一次跳过推进")
	tracker.sync_done(1)
	assert (tracker.on_move(2).is_empty() and tracker.on_move(3) == [2], "撤销保留剩余间隔和次数")
	tracker.reset(6, 30, 10)
	assert (tracker.on_move(10).is_empty() and tracker.on_move(12).is_empty(), "续局不补播首盆，重新等待间隔")
	assert (tracker.on_move(13) == [1], "续局下一反馈从Nice开始")
	tracker.reset(6, 30)
	assert (tracker.on_move(22) == [1, 2, 3, 4, 5, 6, 7, 8], "计次不受步数时间窗口或七档上限影响")
	tracker.reset(4, 1)
	assert (tracker.on_move(1) == [1], "首末盆重合只反馈一次")
	print("COMBO_FREQUENCY_SELFTEST PASS")
	quit(0)
