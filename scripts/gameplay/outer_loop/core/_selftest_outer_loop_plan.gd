extends SceneTree


const Plan: = preload("res://scripts/gameplay/outer_loop/core/outer_loop_plan.gd")
const SIZE: = 25

func _initialize() -> void :

	var p1: = Plan.compute(10, false, SIZE)
	assert (p1.mode == Plan.Mode.STEADY, "p1 mode %d" % p1.mode)
	assert (p1.bg_chapter == 1, "p1 bg %d" % p1.bg_chapter)
	assert (p1.bubble_chapter == 2, "p1 bubble %d" % p1.bubble_chapter)
	assert (p1.done == 9, "p1 done %d" % p1.done)


	var p2: = Plan.compute(11, true, SIZE)
	assert (p2.mode == Plan.Mode.RISE, "p2 mode %d" % p2.mode)
	assert (p2.bg_chapter == 1 and p2.bubble_chapter == 2, "p2 ch")
	assert (p2.done_to == 10, "p2 to %d" % p2.done_to)
	assert (p2.done_from == 9, "p2 from %d" % p2.done_from)


	var p3: = Plan.compute(26, true, SIZE)
	assert (p3.mode == Plan.Mode.CROSS, "p3 mode %d" % p3.mode)
	assert (p3.from_bg_chapter == 1 and p3.from_bubble_chapter == 2, "p3 from ch")
	assert (p3.from_done == SIZE - 1, "p3 from done %d" % p3.from_done)
	assert (p3.to_bg_chapter == 2 and p3.to_bubble_chapter == 3, "p3 to ch")
	assert (p3.to_done == 0, "p3 to done %d" % p3.to_done)


	var p4: = Plan.compute(26, false, SIZE)
	assert (p4.mode == Plan.Mode.STEADY, "p4 mode %d" % p4.mode)
	assert (p4.bg_chapter == 2 and p4.bubble_chapter == 3, "p4 ch")
	assert (p4.done == 0, "p4 done %d" % p4.done)


	var p5: = Plan.compute(51, true, SIZE)
	assert (p5.mode == Plan.Mode.CROSS, "p5 mode")
	assert (p5.from_bg_chapter == 2 and p5.from_bubble_chapter == 3, "p5 from")
	assert (p5.to_bg_chapter == 3 and p5.to_bubble_chapter == 4, "p5 to")


	var p6: = Plan.compute(1, false, SIZE)
	assert (p6.mode == Plan.Mode.STEADY and p6.bg_chapter == 1 and p6.bubble_chapter == 2, "p6")
	assert (p6.done == 0, "p6 done %d" % p6.done)


	var p7: = Plan.compute(2, true, SIZE)
	assert (p7.mode == Plan.Mode.RISE, "p7 mode")


	assert (Plan.compute(SIZE + 1, true, SIZE).from_done == SIZE - 1, "cross from == SIZE-1")

	print("PASS home_backdrop_plan")
	quit()
