class_name RankCollectImpact
extends RefCounted



const PRESS_SEC: float = 0.025
const REBOUND_SEC: float = 0.045
const SETTLE_SEC: float = 0.09

static func play(host: Node, target: CanvasItem, base_position: Vector2, 
		base_scale: Vector2, previous: Tween, speed: float = 1.0) -> Tween:
	if is_instance_valid(previous):
		previous.kill()
	var tween: Tween = host.create_tween()
	tween.set_speed_scale(maxf(speed, 0.01))


	tween.tween_property(target, "position", base_position + Vector2(0, 5), PRESS_SEC)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", base_scale * Vector2(1.07, 0.92), PRESS_SEC)
	tween.tween_property(target, "position", base_position + Vector2(0, -4), REBOUND_SEC)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", base_scale * Vector2(0.98, 1.06), REBOUND_SEC)
	tween.tween_property(target, "position", base_position, SETTLE_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(target, "scale", base_scale, SETTLE_SEC)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween
