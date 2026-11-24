class_name GameDataShowStep
extends FlowStep



var elapsed_ms: int = 0
var move_attempt_count: int = 0
var win_streak_count: int = 0


func get_step_name() -> String:
	return "GameDataShow"


func should_run(ctx) -> bool:
	return ctx.page.visible and ctx.page.is_complete_panel_shown()\
	and ctx.page.is_finish_game_data_enabled()


func run(ctx) -> void :
	var data: Dictionary = ctx.page.get_finish_game_data()
	elapsed_ms = int(data["elapsed_ms"])
	move_attempt_count = int(data["move_attempt_count"])
	win_streak_count = int(data["win_streak_count"])
	await ctx.page.show_finish_game_data(data)
