class_name HideBannerStep
extends FlowStep









func get_step_name() -> String:
	return "HideBanner"


func run(ctx) -> void :
	ctx.page.hide_banner_ad()
