extends RefCounted

const DESIGN_SIZE: = Vector2(1080.0, 2344.0)

static func apply(stage: Node2D, viewport_size: Vector2) -> void :
	var insets: Vector2 = UiMetrics.safe_insets()
	var usable: Vector2 = Vector2(viewport_size.x, viewport_size.y - insets.x - insets.y)
	var factor: = minf(usable.x / DESIGN_SIZE.x, usable.y / DESIGN_SIZE.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (usable - DESIGN_SIZE * factor) * 0.5 + Vector2(0, insets.x)
