extends SceneTree


var _failures: Array[String] = []

func _initialize() -> void :
	call_deferred("_run")

func _check(condition: bool, message: String) -> void :
	if not condition:
		_failures.append(message)

func _run() -> void :
	var scene: PackedScene = load("res://scripts/widget/prop_btn/prop_btn.tscn")
	var btn: PropBtn = scene.instantiate()
	root.add_child(btn)
	btn.size = Vector2(204, 228)
	btn.configure(PropBtn.PropType.HINT)
	btn.refresh(12, 1200, true, false, 3, false, true)
	await process_frame
	var icon: Control = btn.get_node("Icon")
	var bg: Control = btn.get_node("Bg")
	var glow: Control = btn.get_node("DeadGlow")
	var badge: Control = btn.get_node("Badge")
	var coin: Control = btn.get_node("CoinBadge")
	btn.set_base_scale(Vector2.ONE * 0.82)
	icon.scale = Vector2.ONE * 0.9
	icon.rotation = 0.05
	var root_transform: Transform2D = btn.get_transform()
	var bg_transform: Transform2D = bg.get_transform()
	var icon_transform: Transform2D = icon.get_transform()
	var badge_transform: Transform2D = badge.get_transform()
	var coin_transform: Transform2D = coin.get_transform()
	_check(btn.play_hint_guide_motion(true, false), "Available Hint starts APK feedback")
	var motion: Tween = btn.get("_dead_shake_tween")
	motion.pause()
	btn._apply_dead_motion(0.53333336)
	_check(absf(icon.scale.x - 0.9 * 1.265) < 0.001
		and is_equal_approx(bg.scale.x, 1.1), "Two scale layers preserve actual baselines")
	_check(glow.modulate.is_equal_approx(PropBtn.TOOL_PROMPT_ORANGE), "Peak glow is orange")
	btn.play_hint_guide_motion(true, false)
	_check(btn.get("_dead_shake_tween") == motion, "Repeated on keeps current cycle")
	btn.set_dead_glow(false)
	_check(btn.is_hint_guide_motion_playing() and glow.visible, 
		"Clearing dead recommendation does not cancel a live Hint reminder")
	btn._apply_dead_motion(0.3)
	_check(is_equal_approx(icon.rotation, 0.05 + deg_to_rad(15.0)), "Positive turn is 15 degrees")
	btn._apply_dead_motion(0.46666667)
	_check(is_equal_approx(icon.rotation, 0.05 - deg_to_rad(15.0)), "Negative turn is 15 degrees")
	btn._apply_dead_motion(1.2)
	_check(is_zero_approx(glow.modulate.a) and is_equal_approx(icon.scale.x, 0.9), 
		"Quiet interval has no glow and restores icon size")
	_check(btn.get_transform().is_equal_approx(root_transform)
		and badge.get_transform().is_equal_approx(badge_transform)
		and coin.get_transform().is_equal_approx(coin_transform), "Root and badges stay fixed")
	_check( not btn.get_node("HintGuideMotion").is_playing(), "Old rings and particles do not play")
	btn.button_down.emit()
	_check( not btn.is_hint_guide_motion_playing() and not glow.visible
		and icon.get_transform().is_equal_approx(icon_transform)
		and bg.get_transform().is_equal_approx(bg_transform), "Press restores all local transforms")
	btn.play_hint_guide_motion(true, false)
	btn.set_dead_glow(true)
	_check( not btn.is_hint_guide_motion_playing() and not btn.play_hint_guide_motion(true, false), 
		"Dead recommendation preempts Hint")
	var dead_motion: Tween = btn.get("_dead_shake_tween")
	btn.stop_hint_guide_motion(true)
	_check(glow.visible and btn.get("_dead_shake_tween") == dead_motion, 
		"Hint cleanup does not cancel dead recommendation")
	btn.set_dead_glow(false)
	btn.play_unlock_highlight()
	_check( not btn.play_hint_guide_motion(true, false), "Unlock takes priority")
	btn.stop_unlock_highlight()
	btn.refresh(12, 1200, false, false, 3, false, true)
	_check( not btn.play_hint_guide_motion(true, false), "Unavailable Hint cannot play")
	btn.refresh(12, 1200, true, false, 3, false, true)
	btn.play_hint_guide_motion(false, false)
	var single: Tween = btn.get("_dead_shake_tween")
	single.pause()
	single.custom_step(1.51)
	_check( not btn.is_hint_guide_motion_playing() and not glow.visible, 
		"Single shot ends after the 1.5 second cycle")
	btn.play_hint_guide_motion(true, false)
	btn.stop_hint_guide_motion()
	var fade: Tween = btn.get("_dead_shake_tween")
	btn.play_hint_guide_motion(true, false)
	_check(btn.is_hint_guide_motion_playing() and btn.get("_dead_shake_tween") != fade, 
		"Restart cancels old fade without a stale completion callback")
	btn.hide()
	_check( not btn.is_hint_guide_motion_playing() and not glow.visible
		and icon.get_transform().is_equal_approx(icon_transform), "Hide restores icon pose")
	btn.show()
	btn.play_hint_guide_motion(true, false)
	root.remove_child(btn)
	_check( not btn.is_hint_guide_motion_playing() and not glow.visible, 
		"Leaving the tree cancels playback")
	btn.free()
	print("HINT_MOTION_PARAMETER_CHECK ", JSON.stringify({"passed": _failures.is_empty(), "failures": _failures}))
	quit(0 if _failures.is_empty() else 1)
