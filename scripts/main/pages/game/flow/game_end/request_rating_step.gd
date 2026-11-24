class_name RequestRatingStep
extends FlowStep





func get_step_name() -> String:
	return "RequestRating"


func run(ctx) -> void :
	var tree: SceneTree = ctx.page.get_tree()
	while not ctx.page.is_finish_presentation_complete():
		if not ctx.page.is_inside_tree() or not ctx.page.visible:
			return
		await tree.process_frame
	await RatingManager.maybe_request_in_app_review()
