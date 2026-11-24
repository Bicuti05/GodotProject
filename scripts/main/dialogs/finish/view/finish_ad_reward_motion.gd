class_name FinishAdRewardMotion
extends Node2D

const PROP_POP_SCALE: float = 2.5
const PROP_FADE_DUR: float = 0.18
const TARGET_PUNCH_SCALE: float = 1.12
const TARGET_PUNCH_DUR: float = 0.18


var _page: Node
var _target: Control
var _parent: Node
var _index: int
var _layout: Dictionary
var _kind: String
var _after: int
var _tween: Tween
var _punch: Tween
var _punch_control: Control
var _punch_base_scale: Vector2
var _playing: bool = false
var _play_generation: int = 0

var _coin_haptic: int = 0

var haptic_style: int = 0

func play(page: Node, target: Control, icon: Control, reward: Dictionary, 
		before: int, after: int, texture: Texture2D, panel: Node) -> void :
	_play_generation += 1
	var play_generation: int = _play_generation
	show()
	_page = page
	_target = target
	_kind = String(reward["kind"])
	_after = after
	z_index = 200
	_page.set_finish_ad_reward_display(_kind, before, after)
	_parent = target.get_parent()
	_index = target.get_index()
	_layout = {"size": target.size, "scale": target.scale, 
		"rotation": target.rotation, "pivot": target.pivot_offset, 
		"mouse": target.mouse_filter, "disabled": target.disabled if target is BaseButton else false, 
		"anchors": [target.anchor_left, target.anchor_top, target.anchor_right, target.anchor_bottom], 
		"offsets": [target.offset_left, target.offset_top, target.offset_right, target.offset_bottom]}
	var holder: = Node2D.new()
	add_child(holder)
	holder.global_transform = target.get_global_transform()
	target.reparent(holder, false)
	for side: int in range(4):
		target.set_anchor(side, 0.0)
	target.pivot_offset = _layout.size * 0.5
	target.position = Vector2.ZERO
	target.size = _layout.size
	target.scale = Vector2.ONE
	target.rotation = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if target is BaseButton:
		target.disabled = true
	_punch_control = icon if _kind == "coins" else target
	_punch_base_scale = _punch_control.scale
	var dst_center: Vector2 = icon.get_global_rect().get_center()
	var dst_size: Vector2 = icon.get_global_rect().size
	var start_center: Vector2 = UiMetrics.viewport_size() * 0.5
	var count: int = page.WIN_COIN_FLY_COUNT if _kind == "coins" else int(reward["count"])
	var min_dur: float = page.WIN_COIN_POP_DUR + page.WIN_COIN_FLY_DUR * (1.0 - page.WIN_COIN_FLY_SPEED_RAND)
	var max_dur: float = page.WIN_COIN_POP_DUR + page.WIN_COIN_FLY_DUR * (1.0 + page.WIN_COIN_FLY_SPEED_RAND)
	var last_delay: float = float(count - 1) * page.WIN_COIN_FLY_STAGGER
	var generation: int = panel._presentation_generation
	_playing = true
	_tween = create_tween().set_parallel(true)

	HapticManager.cancel_event(_coin_haptic)
	_coin_haptic = 0
	if _kind == "coins" and haptic_style > 0:
		_coin_haptic = HapticManager.play_event(HapticProfiles.shake_event_for(HapticProfiles.Event.COIN_FLY, haptic_style))
	for i: int in range(count):
		var sprite: Node2D
		var base_scale: float
		if _kind == "coins":
			sprite = page.get_win_coin_scene().instantiate() as Node2D
			base_scale = page.WIN_COIN_FLY_SIZE / page.WIN_COIN_BBOX_W
		else:
			var prop: = Sprite2D.new()
			prop.texture = texture
			sprite = prop
			base_scale = minf(dst_size.x / float(texture.get_width()), dst_size.y / float(texture.get_height()))
		var start_scale: float = 1.25 if _kind == "coins" else PROP_POP_SCALE
		var dst_scale: float = 0.85 if _kind == "coins" else 1.0
		sprite.scale = Vector2.ONE * base_scale * (1.0 if _kind == "coins" else start_scale)
		sprite.z_index = 80
		add_child(sprite)
		sprite.global_position = start_center
		if _kind == "coins":
			var anim: SpineAnimationState = (sprite as SpineSprite).get_animation_state()
			if anim != null:
				var entry: SpineTrackEntry = anim.set_animation(page.WIN_COIN_ANIM, true, 0)
				if entry != null:
					entry.set_track_time(randf() * page.WIN_COIN_ANIM_DUR * page.WIN_COIN_SPIN_DESYNC_RATIO)
		var trail: GPUParticles2D = _make_reward_trail(page)
		add_child(trail)
		trail.global_position = start_center
		var delay: float = float(i) * page.WIN_COIN_FLY_STAGGER
		var angle: float = randf_range(0.0, TAU)
		var settle_center: Vector2 = start_center + Vector2.from_angle(angle)\
		* randf_range(page.WIN_COIN_POP_DIST_MIN, page.WIN_COIN_POP_DIST_MAX)
		var ctrl: Vector2 = (settle_center + dst_center) * 0.5\
		+ Vector2((float(i) - float(count - 1) * 0.5) * 25.0, 
			page.WIN_COIN_ARC_HEIGHT * randf_range(1.0 - page.WIN_COIN_ARC_RAND, 1.0 + page.WIN_COIN_ARC_RAND))
		var dur: float = page.WIN_COIN_FLY_DUR * randf_range(1.0 - page.WIN_COIN_FLY_SPEED_RAND, 1.0 + page.WIN_COIN_FLY_SPEED_RAND)
		_tween.tween_method( func(t: float) -> void :
			sprite.global_position = start_center.lerp(settle_center, 1.0 - pow(1.0 - t, 3.0)), 
			0.0, 1.0, page.WIN_COIN_POP_DUR).set_delay(delay)
		_tween.tween_callback( func() -> void : trail.emitting = true).set_delay(delay + page.WIN_COIN_POP_DUR)
		_tween.tween_method( func(t: float) -> void :
			var pos: Vector2 = settle_center.lerp(ctrl, t).lerp(ctrl.lerp(dst_center, t), t)
			sprite.global_position = pos
			sprite.scale = Vector2.ONE * base_scale * lerpf(start_scale, dst_scale, t)
			trail.global_position = pos, 
			0.0, 1.0, dur).set_delay(delay + page.WIN_COIN_POP_DUR)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_callback( func() -> void :
			trail.emitting = false
			if _kind == "coins":
				sprite.hide()
				AudioManager.play_sfx(&"coin_fly")
			_punch_reward_target()
		).set_delay(delay + page.WIN_COIN_POP_DUR + dur)
		if _kind != "coins":
			_tween.tween_property(sprite, "modulate:a", 0.0, PROP_FADE_DUR)\
			.set_delay(delay + page.WIN_COIN_POP_DUR + dur)
			_tween.tween_callback(sprite.hide).set_delay(delay + page.WIN_COIN_POP_DUR + dur + PROP_FADE_DUR)
	_tween.tween_method( func(value: float) -> void :
		_page.set_finish_ad_reward_display(_kind, roundi(value), after), 
		float(before), float(after), maxf(page.WIN_COIN_FLY_STAGGER, last_delay + max_dur - min_dur))\
		.set_delay(min_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_tween.tween_callback(stop.bind(false)).set_delay(last_delay + max_dur + maxf(TARGET_PUNCH_DUR, 
		page.WIN_COIN_TRAIL_LIFETIME * (1.0 + page.WIN_COIN_TRAIL_LIFETIME_RANDOMNESS)))
	while _playing and play_generation == _play_generation:
		await get_tree().process_frame

		if _playing and play_generation == _play_generation and not panel.is_ad_claim_current(generation):
			stop()


func _make_reward_trail(page: Node) -> GPUParticles2D:
	var pm: = ParticleProcessMaterial.new()

	pm.particle_flag_disable_z = true
	pm.lifetime_randomness = page.WIN_COIN_TRAIL_LIFETIME_RANDOMNESS
	pm.gravity = Vector3.ZERO
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = page.WIN_COIN_FLY_SIZE * 0.5
	var scale_amount: float = page.WIN_COIN_TRAIL_SIZE / float(page.WIN_COIN_TRAIL_TEX.get_width())
	pm.scale_min = scale_amount * (1.0 - page.WIN_COIN_TRAIL_SIZE_RANDOMNESS)
	pm.scale_max = scale_amount * (1.0 + page.WIN_COIN_TRAIL_SIZE_RANDOMNESS)
	var ramp: = GradientTexture1D.new()
	ramp.gradient = page._make_win_coin_trail_ramp()
	pm.color_ramp = ramp
	var add_mat: = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var p: = GPUParticles2D.new()
	p.texture = page.WIN_COIN_TRAIL_TEX
	p.process_material = pm
	p.material = add_mat
	p.emitting = false
	p.one_shot = false
	p.z_index = 79
	p.modulate = page.CUP_BLOOM_PARTICLE_GOLD
	p.amount = maxi(1, roundi(page.WIN_COIN_TRAIL_RATE * page.WIN_COIN_TRAIL_LIFETIME))
	p.lifetime = page.WIN_COIN_TRAIL_LIFETIME
	p.visibility_rect = Rect2( - page.WIN_COIN_FLY_SIZE, - page.WIN_COIN_FLY_SIZE, 
		page.WIN_COIN_FLY_SIZE * 2.0, page.WIN_COIN_FLY_SIZE * 2.0)
	return p


func _punch_reward_target() -> void :
	if _punch != null and _punch.is_valid():
		_punch.kill()
	_punch_control.scale = _punch_base_scale * TARGET_PUNCH_SCALE
	_punch = create_tween()
	_punch.tween_property(_punch_control, "scale", _punch_base_scale, TARGET_PUNCH_DUR)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func stop(cancel_haptic: bool = true) -> void :

	if cancel_haptic:
		HapticManager.cancel_event(_coin_haptic)
		_coin_haptic = 0
	if not _playing:
		return
	_playing = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _punch != null and _punch.is_valid():
		_punch.kill()
	_punch_control.scale = _punch_base_scale
	_page.set_finish_ad_reward_display(_kind, 
		UserState.get_coins() if _kind == "coins" else UserState.get_prop_count(_kind), _after)
	_target.reparent(_parent, false)
	_parent.move_child(_target, _index)
	_target.pivot_offset = _layout.pivot
	_target.scale = _layout.scale
	_target.rotation = _layout.rotation
	for side: int in range(4):
		_target.set_anchor(side, _layout.anchors[side])
		_target.set_offset(side, _layout.offsets[side])
	_target.mouse_filter = _layout.mouse
	if _target is BaseButton:
		_target.disabled = _layout.disabled

	hide()
	for child: Node in get_children():
		child.queue_free()

func _exit_tree() -> void :
	stop()
