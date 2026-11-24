class_name DailyFirstWinCheckinStep
extends FlowStep

func get_step_name() -> String:
	return "DailyFirstWinCheckin"

func should_run(ctx) -> bool:
	return not ctx.aborted and ctx.page.visible

func run(ctx) -> void :
	if not await ctx.page.show_daily_first_win_checkin():
		ctx.aborted = true
