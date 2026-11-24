class_name RankFinishPodium
extends Control


signal gift_tapped(rank_pos: int, global_rect: Rect2)
signal avatar_landed(rank: int)

const Motion = preload("res://scripts/gameplay/rank/view/motion/rank_finish_motion.gd")
const SweepFx = preload("res://scripts/gameplay/rank/view/rank_podium_sweep_fx.gd")
const AVATAR_Z: int = 100
const CROWN_GLOW_TURN_SEC: float = 30.0
const COLLECT_FEEDBACK_LEAD_SEC: float = 0.2
const ENTER_RISE_SEC: float = 0.3
const ENTER_SETTLE_SEC: float = 0.12
const ENTER_FIRST_DELAY_SEC: float = 0.06
const ENTER_FROM_SCALE: float = 0.95
const ENTER_PEAK_SCALE: float = 1.02
const ENTER_SIDE_OFFSET: float = 60.0
const ENTER_FIRST_OFFSET: float = 80.0
const ENTER_GLOW_FADE_SEC: float = 0.16
const ENTER_DURATION: float = ENTER_FIRST_DELAY_SEC + ENTER_RISE_SEC + ENTER_SETTLE_SEC

const CROWN_GLOW_FOCUS: Vector2 = Vector2(142.0, 126.5) / 281.0

@onready var _cards: Array[RankItemView] = [$First, $Second, $Third]
@onready var _first_crown: TextureRect = $First / Crown
@onready var _crown_glow: TextureRect = $CrownGlow
@onready var _flight_layer: Control = $FlightLayer
@onready var _sweeps: Array[SweepFx] = [$First / Bg / SweepFx, $Second / Bg / SweepFx, $Third / Bg / SweepFx]
@onready var _gift_fx: Array[RankThemeIdleView] = [
	$First / GiftButton / GiftFx, $Second / GiftButton / GiftFx, $Third / GiftButton / GiftFx]

var _avatar_clones: Array[Control] = []
var _name_clones: Array[Control] = []
var _hidden_items: Array[RankItemView] = []
var _hidden_names: Array[Control] = []
var _avatar_rest: Array[Dictionary] = []
var _landing_rest: Array[Dictionary] = []
var _landing_tweens: Array[Tween] = [null, null, null]
var _pool: RankAvatarPool
var _element_tex: Texture2D
var _motion: Motion = Motion.new()
var _crown_glow_tween: Tween = null
var _enter_tween: Tween = null
var _crown_glow_fade_tween: Tween = null
var _enter_prepared: bool = false
var _card_rest: Array[Dictionary] = []


func _ready() -> void :
	_flight_layer.z_as_relative = false
	_flight_layer.z_index = AVATAR_Z + 2
	for index: int in _gift_fx.size():
		_gift_fx[index].set_texture((_cards[index].get_node("GiftButton") as TextureButton).texture_normal)
	for card: RankItemView in _cards:
		_card_rest.append({"position": card.position, "scale": card.scale, 
			"pivot": card.pivot_offset, "alpha": card.modulate.a})
		var crown: Control = card.get_node("Crown")
		crown.z_as_relative = false
		crown.z_index = AVATAR_Z + 5
		var rest: Dictionary = {}
		for name: String in ["Avatar", "AvatarFrame"]:
			var node: Control = card.get_node(name)
			node.z_as_relative = false
			node.z_index = AVATAR_Z + (1 if name == "AvatarFrame" else 0)
			rest[name] = {"position": node.position, "scale": node.scale, "pivot": node.pivot_offset}
		_avatar_rest.append(rest)
		var landing: Dictionary = {}
		for name: String in ["Bg", "RankIcon", "Info", "CollectBg", "CollectIcon", "GiftButton", "Crown"]:
			var node: Control = card.get_node(name)
			landing[name] = {"position": node.position, "scale": node.scale, "pivot": node.pivot_offset, "rotation": node.rotation}
		_landing_rest.append(landing)



func prepare_enter() -> void :
	_reset_enter()
	_enter_prepared = true
	_crown_glow.modulate.a = 0.0
	for index: int in _cards.size():
		var card: RankItemView = _cards[index]
		var offset: float = ENTER_FIRST_OFFSET if index == 0 else ENTER_SIDE_OFFSET
		card.pivot_offset = Vector2(card.size.x * 0.5, card.size.y)
		card.position = Vector2(_card_rest[index].position) + Vector2(0.0, offset)
		card.scale = Vector2(_card_rest[index].scale) * ENTER_FROM_SCALE
		card.modulate.a = 0.0



func play_enter() -> Tween:
	if not _enter_prepared or _enter_tween != null:
		prepare_enter()
	_enter_tween = create_tween().set_parallel(true)
	for index: int in _cards.size():
		var card: RankItemView = _cards[index]
		var delay: float = ENTER_FIRST_DELAY_SEC if index == 0 else 0.0
		var rest: Dictionary = _card_rest[index]
		_enter_tween.tween_property(card, "position", rest.position, ENTER_RISE_SEC)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		_enter_tween.tween_property(card, "modulate:a", rest.alpha, ENTER_RISE_SEC)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)
		_enter_tween.tween_property(card, "scale", Vector2(rest.scale) * ENTER_PEAK_SCALE, ENTER_RISE_SEC)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
		_enter_tween.tween_property(card, "scale", rest.scale, ENTER_SETTLE_SEC)\
		.from(Vector2(rest.scale) * ENTER_PEAK_SCALE).set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT).set_delay(delay + ENTER_RISE_SEC)
	_enter_tween.tween_callback(_finish_enter).set_delay(ENTER_DURATION)
	return _enter_tween


func _finish_enter() -> void :
	_enter_prepared = false
	_enter_tween = null
	_restore_cards()
	_start_crown_glow()
	_crown_glow_fade_tween = create_tween()
	_crown_glow_fade_tween.tween_property(_crown_glow, "modulate:a", 1.0, ENTER_GLOW_FADE_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _restore_cards() -> void :
	for index: int in _cards.size():
		var card: RankItemView = _cards[index]
		var rest: Dictionary = _card_rest[index]
		card.position = rest.position
		card.scale = rest.scale
		card.pivot_offset = rest.pivot
		card.modulate.a = rest.alpha


func _reset_enter() -> void :
	if _enter_tween != null and _enter_tween.is_valid():
		_enter_tween.kill()
	_enter_tween = null
	if _crown_glow_fade_tween != null and _crown_glow_fade_tween.is_valid():
		_crown_glow_fade_tween.kill()
	_crown_glow_fade_tween = null
	_enter_prepared = false
	_crown_glow.modulate.a = 1.0
	_restore_cards()


func bind_snapshot(snap: RankSnapshot, pool: RankAvatarPool, element_tex: Texture2D) -> void :
	_pool = pool
	_element_tex = element_tex
	visible = true
	if not _enter_prepared:
		_start_crown_glow()
	for card: RankItemView in _cards:
		card.visible = false
	for rank: int in range(1, 4):
		_bind_rank(snap, rank)
	for index: int in _gift_fx.size():
		var fx: RankThemeIdleView = _gift_fx[index]
		if _cards[index].visible and not fx.visible:
			fx.show()
			fx.start_idle_fx()

			var motes: CPUParticles2D = fx.get_node("Host/RiseMotes")
			var half: Vector2 = fx.size * 0.5
			motes.emission_rect_extents = Vector2(half.x * 0.55, 10.0)
			motes.initial_velocity_min = half.y * 0.55 * 0.55
			motes.initial_velocity_max = half.y * 0.55 * 0.9


func _start_crown_glow() -> void :
	if _crown_glow_tween != null and _crown_glow_tween.is_valid():
		return
	_crown_glow.pivot_offset = _crown_glow.size * CROWN_GLOW_FOCUS
	_crown_glow_tween = create_tween().set_loops()
	_crown_glow_tween.tween_property(_crown_glow, "rotation", TAU, CROWN_GLOW_TURN_SEC).as_relative().set_trans(Tween.TRANS_LINEAR)


func _bind_rank(snap: RankSnapshot, rank: int) -> void :
	for row: Dictionary in snap.rows:
		if int(row.get("rank_pos", 0)) != rank:
			continue
		var card: RankItemView = _cards[rank - 1]
		_restore_avatar(rank)
		card.bind(row, _pool.get_texture(int(row.get("avatar_index", 0))), _element_tex)
		card.set_avatar_visible(true)
		card.visible = true
		return


func find_item(key: String) -> RankItemView:
	for card: RankItemView in _cards:
		if card.visible and card.get_row_key() == key:
			return card
	return null


func set_first_crown_visible(on: bool) -> void :
	_first_crown.visible = on


func play_rise(list: RankListView, from_snap: RankSnapshot, to_snap: RankSnapshot) -> void :
	var generation: int = list.animation_generation
	var me: RankItemView = list.find_my_item()
	if me == null:
		return
	if from_snap.my_rank_pos == to_snap.my_rank_pos:

		_sweeps[to_snap.my_rank_pos - 1].play(list, to_snap.my_rank_pos, generation, false)
		var lead: Tween = list.create_animation_tween()
		lead.tween_interval(COLLECT_FEEDBACK_LEAD_SEC)
		await list.wait_animation(lead, generation)
		return
	var plan: Dictionary = Motion.build(from_snap.my_rank_pos, to_snap.my_rank_pos)
	var state: Dictionary = {"row": {}, "winner_bound": false, "committed": false, 
		"sweep": false, "vibrated": false, "flight_started": false, 
		"fourth_started": false, "incoming_flyer": null, "overtaken_sounds": 0, 
		"swap_transfers": []}
	list.set_drag_enabled(false)
	if plan.branch == "enter_top3":
		state.row = list.begin_top3_row_rise(from_snap.my_rank_pos)
		if state.row.is_empty():
			return
		AudioManager.play_sfx(&"rank_rise_begin")
	var apply: Callable = func(time: float) -> void :
		if not list.animation_is_active(generation):
			return
		var sample: Dictionary = _motion.sample(plan, time)
		if plan.branch == "enter_top3":
			_sample_enter(list, to_snap, plan, state, sample, time)
		else:
			_sample_swap(to_snap, plan, state, sample, time)
		if time >= plan.sweep_at and not state.sweep:
			state.sweep = true
			_sweeps[to_snap.my_rank_pos - 1].play(list, to_snap.my_rank_pos, generation)
		if time >= plan.vibrate_at and not state.vibrated:
			state.vibrated = true
			_play_landing(list, to_snap.my_rank_pos, generation)
			HapticManager.play_event(HapticManager.Event.BUTTON)
	apply.call(0.0)
	var tween: Tween = list.create_animation_tween()
	tween.tween_method(apply, 0.0, float(plan.duration), float(plan.duration)).set_trans(Tween.TRANS_LINEAR)
	await list.wait_animation(tween, generation)
	if not list.animation_is_active(generation):
		return
	apply.call(float(plan.duration))
	list.end_top3_row_rise()
	_clear_transfers()
	_restore_avatar(from_snap.my_rank_pos)
	list.set_drag_enabled(true)


func _sample_enter(list: RankListView, snap: RankSnapshot, plan: Dictionary, 
		state: Dictionary, sample: Dictionary, time: float) -> void :
	list.sample_top3_row_rise(state.row, plan, sample)
	var passed: int = Motion.overtaken_count(plan, time)
	while int(state.overtaken_sounds) < passed:
		var sound_index: int = mini(int(state.overtaken_sounds), RankListRiseAnim._OVER_ITEM_SOUND_KINDS.size() - 1)
		AudioManager.play_sfx(RankListRiseAnim._OVER_ITEM_SOUND_KINDS[sound_index])
		state.overtaken_sounds += 1
	var rank: int = int(plan.new_rank)
	if time >= plan.fly_at:
		if not state.fourth_started:
			state.fourth_started = true
			list.begin_fourth_fill(snap)
		list.sample_fourth_fill(Motion.segment(time, plan.fly_at, plan.fly_at + 0.2))
	var rest_y: float = _rest_y(rank)
	if time >= plan.winner_at:
		if state.incoming_flyer == null:
			state.incoming_flyer = _make_flight_clone(state.row.real as RankItemView)
			state.incoming_target = _cards[rank - 1].get_avatar_global_rect()
		var winner: Vector2 = Motion.winner(time - float(plan.winner_at), rest_y)
		var clone: Control = state.incoming_flyer
		var target: Rect2 = state.incoming_target
		var center: Vector2 = target.get_center() + _cards[rank - 1].get_global_transform().y * (winner.x - rest_y)
		clone.scale = target.size / clone.size * winner.y
		clone.global_position = center - clone.size * clone.scale * 0.5

		if time >= plan.commit_at and not state.winner_bound:
			state.winner_bound = true
			_bind_rank(snap, rank)
			_cards[rank - 1].set_avatar_visible(false)
			_hidden_items.append(_cards[rank - 1])
	if time >= plan.commit_at and not state.committed:
		state.committed = true
		for other_rank: int in range(1, 4):
			if other_rank != rank:
				_bind_rank(snap, other_rank)


func _make_flight_clone(item: RankItemView) -> Control:
	var clone: Control = item.make_avatar_clone()
	clone.z_index = 0
	for index: int in clone.get_child_count():
		var node: Control = clone.get_child(index) as Control
		node.z_as_relative = true
		node.z_index = index
	_flight_layer.add_child(clone)
	_avatar_clones.append(clone)
	return clone


func _sample_swap(snap: RankSnapshot, plan: Dictionary, 
		state: Dictionary, sample: Dictionary, time: float) -> void :
	if not state.flight_started:
		_set_avatar_transform(int(plan.old_rank), _rest_y(int(plan.old_rank)), float(sample.mount_scale))
	if time >= plan.fly_at and not state.flight_started:
		state.flight_started = true
		_start_swap_transfers(snap, plan, state)
		AudioManager.play_sfx(&"rank_rise_begin")
	if time >= plan.commit_at and not state.committed:
		state.committed = true
		bind_snapshot(snap, _pool, _element_tex)

		for rank: int in range(int(plan.new_rank), int(plan.old_rank) + 1):
			_cards[rank - 1].set_avatar_visible(false)
	for transfer: Dictionary in state.swap_transfers:
		_sample_swap_transfer(transfer, plan, sample, time)


func _start_swap_transfers(snap: RankSnapshot, plan: Dictionary, state: Dictionary) -> void :
	for rank: int in range(int(plan.new_rank), int(plan.old_rank) + 1):
		var source: RankItemView = _cards[rank - 1]
		var destination_rank: int = 0
		for row: Dictionary in snap.rows:
			if RankItemView.make_row_key(row) == source.get_row_key():
				destination_rank = int(row.rank_pos)
				break
		var destination: RankItemView = _cards[destination_rank - 1]
		var source_name: Control = source.get_node("Info/Nickname")
		var destination_name: Control = destination.get_node("Info/Nickname")
		var name_clone: Control = source_name.duplicate() as Control
		name_clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_clone.z_as_relative = true
		name_clone.z_index = 2
		name_clone.pivot_offset = Vector2.ZERO
		name_clone.scale = Vector2.ONE
		name_clone.show()
		_flight_layer.add_child(name_clone)
		_name_clones.append(name_clone)
		state.swap_transfers.append({"avatar": _make_flight_clone(source), "name": name_clone, 
			"destination_rank": destination_rank, "player": rank == int(plan.old_rank), 
			"start_avatar": source.get_avatar_global_rect(), "end_avatar": destination.get_avatar_global_rect(), 
			"start_name": source_name.get_global_rect(), "end_name": destination_name.get_global_rect()})
		source.set_avatar_visible(false)
		source_name.hide()
		_hidden_items.append(source)
		_hidden_names.append(source_name)


func _sample_swap_transfer(transfer: Dictionary, plan: Dictionary, sample: Dictionary, time: float) -> void :
	var clone: Control = transfer.avatar
	var name_clone: Control = transfer.name
	var start: Rect2 = transfer.start_avatar
	var destination: Rect2 = transfer.end_avatar
	var name_start: Rect2 = transfer.start_name
	var name_destination: Rect2 = transfer.end_name
	if time >= plan.land_at:
		var card: RankItemView = _cards[int(transfer.destination_rank) - 1]
		destination = card.get_avatar_global_rect()
		name_destination = (card.get_node("Info/Nickname") as Control).get_global_rect()
	var progress: float = smoothstep(float(plan.fly_at), float(plan.land_at), time)
	var center: Vector2 = start.get_center().lerp(destination.get_center(), progress)
	var name_offset: float = 18.0 * sin(PI * progress)
	if transfer.player:
		var flight: Vector2 = sample.flyer_progress
		center = Vector2(lerpf(start.get_center().x, destination.get_center().x, flight.x), 
			lerpf(start.get_center().y, destination.get_center().y - float(sample.flyer_above), flight.y))
		clone.scale = start.size.lerp(destination.size, progress) / clone.size * float(sample.flyer_scale)
		name_offset = - float(sample.flyer_above) * float(sample.flyer_progress.y) * 0.35
	else:
		center.y += 30.0 * sin(PI * progress)
		clone.scale = start.size.lerp(destination.size, progress) / clone.size
	clone.global_position = center - clone.size * clone.scale * 0.5
	name_clone.scale = name_start.size.lerp(name_destination.size, progress) / name_clone.size
	name_clone.global_position = name_start.position.lerp(name_destination.position, progress) + Vector2(0.0, name_offset)


func set_entered_avatar_scale(rank: int) -> void :
	_set_avatar_transform(rank, _rest_y(rank), 1.05)


func _play_landing(list: RankListView, rank: int, generation: int) -> void :
	if not list.animation_is_active(generation):
		return
	AudioManager.play_sfx(&"rank_podium_landed")
	_reset_landing(rank)
	var sample: Callable = func(age: float) -> void :
		if not list.animation_is_active(generation):
			return

		var board: float = _landing_amount(age)
		var content: float = _landing_amount(maxf(0.0, age - 0.035))
		for name: String in _landing_rest[rank - 1]:
			var node: Control = _cards[rank - 1].get_node(name)
			var rest: Dictionary = _landing_rest[rank - 1][name]
			if name == "Bg":
				node.pivot_offset = Vector2(node.size.x * 0.5, node.size.y)
				node.position = Vector2(rest.position) + Vector2(0.0, board * 12.0)
				node.scale = Vector2(rest.scale) * Vector2(1.0 + board * 0.02, 1.0 - board * 0.04)
			elif name == "Crown":
				var crown: float = _landing_amount(maxf(0.0, age - 0.025))
				node.pivot_offset = Vector2(node.size.x * 0.5, node.size.y)
				node.position = Vector2(rest.position) + Vector2(0.0, crown * 9.0)
				node.scale = Vector2(rest.scale) * Vector2(1.0 + crown * 0.04, 1.0 - crown * 0.08)
				node.rotation = float(rest.rotation) + deg_to_rad(crown * 4.0)
			else:
				node.pivot_offset = node.size * 0.5
				node.position = Vector2(rest.position) + Vector2(0.0, content * 6.0)
				node.scale = Vector2(rest.scale) * (1.0 - content * 0.012)
	sample.call(0.0)
	var tween: Tween = list.create_animation_tween()
	_landing_tweens[rank - 1] = tween
	tween.tween_method(sample, 0.0, 0.4, 0.4).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback( func() -> void :
		_landing_tweens[rank - 1] = null
		_reset_landing(rank))
	avatar_landed.emit(rank)


static func _landing_amount(age: float) -> float:
	if age < 0.06:
		return sin(Motion.segment(age, 0.0, 0.06) * PI * 0.5)
	if age < 0.16:
		return lerpf(1.0, -0.55, (1.0 - cos(Motion.segment(age, 0.06, 0.16) * PI)) * 0.5)
	return lerpf(-0.55, 0.0, (1.0 - cos(Motion.segment(age, 0.16, 0.36) * PI)) * 0.5)


func _reset_landing(rank: int) -> void :
	var tween: Tween = _landing_tweens[rank - 1]
	if tween != null and tween.is_valid():
		tween.kill()
	_landing_tweens[rank - 1] = null
	for name: String in _landing_rest[rank - 1]:
		var node: Control = _cards[rank - 1].get_node(name)
		var rest: Dictionary = _landing_rest[rank - 1][name]
		node.position = rest.position
		node.scale = rest.scale
		node.pivot_offset = rest.pivot
		node.rotation = rest.rotation


func _rest_y(rank: int) -> float:
	return float(_avatar_rest[rank - 1].Avatar.position.y)


func _set_avatar_transform(rank: int, y: float, factor: float) -> void :
	var rest: Dictionary = _avatar_rest[rank - 1]
	var avatar: Control = _cards[rank - 1].get_node("Avatar")
	var center: Vector2 = Vector2(rest.Avatar.position) + avatar.size * 0.5
	for name: String in ["Avatar", "AvatarFrame"]:
		var node: Control = _cards[rank - 1].get_node(name)
		var position_at_rest: Vector2 = rest[name].position
		node.position = position_at_rest + Vector2(0.0, y - _rest_y(rank))
		node.pivot_offset = center - position_at_rest
		node.scale = Vector2(rest[name].scale) * factor


func _restore_avatar(rank: int) -> void :
	if rank < 1 or rank > 3 or _avatar_rest.is_empty():
		return
	for name: String in ["Avatar", "AvatarFrame"]:
		var node: Control = _cards[rank - 1].get_node(name)
		var rest: Dictionary = _avatar_rest[rank - 1][name]
		node.position = rest.position
		node.scale = rest.scale
		node.pivot_offset = rest.pivot


func cancel_animations() -> void :
	_reset_enter()
	for fx: RankThemeIdleView in _gift_fx:
		fx.hide()
		fx.reset_motion()

		for name: String in ["RiseMotes", "Sparkles"]:
			var particles: CPUParticles2D = fx.get_node("Host/" + name)
			particles.amount = particles.amount
	if _crown_glow_tween != null and _crown_glow_tween.is_valid():
		_crown_glow_tween.kill()
	_crown_glow_tween = null
	_crown_glow.rotation = 0.0
	_clear_transfers()
	for rank: int in range(1, 4):
		_restore_avatar(rank)
		_reset_landing(rank)
	for sweep: SweepFx in _sweeps:
		sweep.stop()
	for card: RankItemView in _cards:
		card.reset_rise_fx()
		card.reset_first_place_fx()
		card.reset_tilt()
		card.scale = Vector2.ONE
		card.pivot_offset = Vector2.ZERO
		card.modulate.a = 1.0
		card.set_avatar_visible(true)


func _clear_transfers() -> void :
	for clone: Control in _avatar_clones:
		clone.hide()
		clone.queue_free()
	_avatar_clones.clear()
	for clone: Control in _name_clones:
		clone.hide()
		clone.queue_free()
	_name_clones.clear()
	for item: RankItemView in _hidden_items:
		item.set_avatar_visible(true)
	_hidden_items.clear()
	for name: Control in _hidden_names:
		name.show()
	_hidden_names.clear()


func _on_gift_pressed(rank_pos: int) -> void :
	gift_tapped.emit(rank_pos, _cards[rank_pos - 1].get_gift_button_global_rect())
