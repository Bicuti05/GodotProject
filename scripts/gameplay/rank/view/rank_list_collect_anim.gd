class_name RankListCollectAnim
extends RefCounted


static func play(owner: RankListView, source_fx: RankSourceCollectionFx, item_me: RankItemView, 
		tex: Texture2D, count: int, start_num: int, end_num: int) -> void :
	if item_me == null:
		return
	if source_fx == null or count <= 0 or end_num <= start_num:
		item_me.set_collect_num_display(end_num)
		return
	var generation: int = owner.animation_generation
	item_me.set_collect_num_display(start_num)
	var state: Dictionary = {"remain_delta": end_num - start_num, "arrived": 0}
	var on_arrive: Callable = func(_index: int) -> void :
		if not owner.animation_is_active(generation) or not is_instance_valid(item_me) or item_me.get_row_key() != "me":
			return
		state.arrived += 1
		var remain_items: int = maxi(source_fx.get_fly_count() - state.arrived, 0)
		var step: int = int(ceil(float(state.remain_delta) / float(remain_items + 1)))
		state.remain_delta -= step
		if is_instance_valid(item_me):
			item_me.set_collect_num_display(item_me.get_collect_num_display() + step)
			item_me.punch_collect_icon()
		AudioManager.play_sfx(&"rank_collect")
	source_fx.item_arrived.connect(on_arrive)
	await source_fx.play(owner, item_me, tex, count)
	if source_fx.item_arrived.is_connected(on_arrive):
		source_fx.item_arrived.disconnect(on_arrive)
	if owner.animation_is_active(generation) and is_instance_valid(item_me) and item_me.get_row_key() == "me":
		item_me.set_collect_num_display(end_num)
