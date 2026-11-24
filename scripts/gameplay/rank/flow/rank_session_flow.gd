class_name RankSessionFlow
extends RefCounted

const DIALOG_LEASE: StringName = &"rank_dialog_lease"

static func run(owner: Node, active: Callable, on_open_rank: Callable = Callable(), 
		on_start_game: Callable = Callable()) -> void :
	var ctx: Dictionary = {"owner": owner, "active": active, "on_open_rank": on_open_rank, "on_start_game": on_start_game}
	await FlowRunner.new([RankSettleDialogStep.new(), RankNewSeasonDialogStep.new()] as Array[FlowStep]).run(ctx)

static func is_active(ctx: Dictionary) -> bool:
	return is_instance_valid(ctx.owner) and ctx.active.call()

static func show_dialog(ctx: Dictionary, route: String, params: Dictionary = {}, 
		finished: Callable = Callable()) -> Node:
	if not is_active(ctx):
		return null
	if route in ["rank_introduction", "rank_new_season", "rank_change", "rank_season_win", "rank_game_finish"]:
		ABManager.dye_at_enter_rank()
	var dlg: Node = SceneManager.show_dlg(route, params)
	if dlg == null:
		return null
	var lease: = RefCounted.new()
	dlg.set_meta(DIALOG_LEASE, lease)
	while is_active(ctx) and dlg.visible and dlg.get_meta(DIALOG_LEASE, null) == lease:
		if finished.is_valid() and finished.call(dlg):
			break
		await ctx.owner.get_tree().process_frame
	if dlg.get_meta(DIALOG_LEASE, null) == lease:
		SceneManager.hide_dlg(route)
	return dlg
