class_name HomeNavigationFlow
extends RefCounted


static var _request: RefCounted

static func run(source = null, params: Dictionary = {}, owner_active: Callable = Callable()) -> bool:
	if _request != null:
		return false
	var request: = RefCounted.new()
	_request = request
	var ctx: Dictionary = {"source": source, "params": params, "page": null, "aborted": false, "committed": false}
	ctx.active = func() -> bool:
		return _request == request and (source == null or (is_instance_valid(source) and source.is_inside_tree() and source.visible)) and ( not owner_active.is_valid() or owner_active.call())
	var lease: RefCounted = PagePreparationCoordinator.begin_foreground()
	await FlowRunner.new([
		PrepareHomeSourceStep.new(), PrepareHomeBaseStep.new(), CommitHomeNavigationStep.new(), 
	] as Array[FlowStep]).run(ctx)
	PagePreparationCoordinator.end_foreground(lease)
	if not ctx.committed and ctx.active.call() and is_instance_valid(source) and source.has_method("cancel_home_navigation"):
		source.cancel_home_navigation()
	if _request == request:
		_request = null
	return ctx.committed
