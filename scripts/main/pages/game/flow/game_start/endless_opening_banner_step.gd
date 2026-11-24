class_name EndlessOpeningBannerStep
extends FlowStep

func get_step_name() -> String:
	return "EndlessOpeningBanner"

func should_run(ctx) -> bool:
	return ctx.active() and not ctx.skip_opening_banner

func run(ctx) -> void :
	if not await ctx.page.show_endless_opening_banner(ctx):
		ctx.aborted = true
