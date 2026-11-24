class_name FinishConfettiEffects
extends FinishParticleGroup

func configure_emitter(name: StringName, emitter: GPUParticles2D) -> void :
	var vp: Vector2 = UiMetrics.viewport_size()
	emitter.position = vp * 0.5
	emitter.visibility_rect = Rect2( - vp, vp * 2.0)
	if name in [&"ConfettiRight", &"SparkleRight"]:
		emitter.scale.x = -1.0


func configure() -> void :
	var vp: Vector2 = UiMetrics.viewport_size()
	for emitter: GPUParticles2D in [$ConfettiFall, $Confetti, $ConfettiRight, $Sparkle, $SparkleRight]:
		emitter.position = vp * 0.5
		emitter.visibility_rect = Rect2( - vp, vp * 2.0)
