class_name ReportGameEndStep
extends FlowStep


func get_step_name() -> String:
	return "ReportGameEnd"


func run(ctx) -> void :
	ctx.page.report_game_end()
