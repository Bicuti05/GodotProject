class_name PreloadBannerStep
extends FlowStep










func get_step_name() -> String:
	return "PreloadBanner"

func should_run(ctx) -> bool:
	return not ctx.aborted

func run(_ctx) -> void :
	AdManager.maybe_preload_banner_on_game_enter()
