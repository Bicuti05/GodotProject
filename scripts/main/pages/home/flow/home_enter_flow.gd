class_name HomeEnterFlow
extends RefCounted

static func run(page, level_won: bool, active: Callable, params: Dictionary = {}) -> void :
	var ctx: Dictionary = {"home_page": page, "level_won": level_won, "active": active, 
		"params": params}
	await FlowRunner.new([OuterLoopProgressStep.new(), 
		HomeRankSessionStep.new()] as Array[FlowStep]).run(ctx)
