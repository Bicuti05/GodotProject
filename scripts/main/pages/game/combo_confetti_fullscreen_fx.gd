class_name ComboConfettiFullscreenFx
extends ComboFullscreenFx

const GLOW_WIDTH_MULTIPLIER: float = 1.2
const CONFETTI_REFERENCE_SCALE_RANGE: Vector2 = Vector2(45.0 / 60.0, 84.0 / 60.0)
const CONFETTI_SCALE_RANGE: Vector2 = Vector2(30.6 / 60.0, 66.825 / 60.0)

const CONFETTI_LAYOUT: Array = [
	[
		Vector4(0.03278074, 0.19859246, 0.0, 45.0 / 60.0), 
		Vector4(0.98358525, 0.23891738, 1.0, 84.0 / 60.0), 
		Vector4(0.07304409, 0.30669484, 2.0, 71.0 / 60.0), 
		Vector4(0.92839681, 0.40149003, 3.0, 58.0 / 60.0), 
		Vector4(0.03636565, 0.47281556, 0.0, 84.0 / 60.0), 
		Vector4(0.94495921, 0.53744788, 1.0, 45.0 / 60.0), 
		Vector4(0.05085521, 0.61054154, 2.0, 58.0 / 60.0), 
		Vector4(0.98000553, 0.65812866, 3.0, 71.0 / 60.0), 
		Vector4(0.08417736, 0.87118527, 2.0, 45.0 / 60.0), 
		Vector4(0.91855141, 0.90452516, 3.0, 84.0 / 60.0), 
	], 
	[
		Vector4(0.02029591, 0.17955057, 0.0, 54.0 / 60.0), 
		Vector4(0.9750455, 0.19293691, 1.0, 69.0 / 60.0), 
		Vector4(0.06471688, 0.22153481, 6.0, 48.0 / 60.0), 
		Vector4(0.94444444, 0.27031954, 7.0, 63.0 / 60.0), 
		Vector4(0.05866912, 0.29833907, 0.0, 72.0 / 60.0), 
		Vector4(0.90515609, 0.32867669, 1.0, 54.0 / 60.0), 
		Vector4(0.04524183, 0.40588196, 0.0, 63.0 / 60.0), 
		Vector4(0.93055555, 0.45893662, 1.0, 72.0 / 60.0), 
		Vector4(0.06668702, 0.48176712, 6.0, 54.0 / 60.0), 
		Vector4(0.92973649, 0.51885991, 7.0, 69.0 / 60.0), 
		Vector4(0.02894616, 0.54967648, 0.0, 48.0 / 60.0), 
		Vector4(0.95728792, 0.56441694, 1.0, 63.0 / 60.0), 
		Vector4(0.08874198, 0.59084922, 6.0, 72.0 / 60.0), 
		Vector4(0.93703704, 0.63939477, 7.0, 54.0 / 60.0), 
		Vector4(0.04673383, 0.66972238, 0.0, 69.0 / 60.0), 
		Vector4(0.92032393, 0.69875725, 1.0, 48.0 / 60.0), 
		Vector4(0.99086873, 0.75078663, 7.0, 72.0 / 60.0), 
		Vector4(0.04988982, 0.778607, 0.0, 54.0 / 60.0), 
		Vector4(0.07244608, 0.85273887, 6.0, 48.0 / 60.0), 
		Vector4(0.92360804, 0.88894047, 7.0, 63.0 / 60.0), 
	], 
	[
		Vector4(0.04444445, 0.16880341, 0.0, 57.0 / 60.0), 
		Vector4(0.94907405, 0.18076923, 4.0, 57.0 / 60.0), 
		Vector4(0.92777777, 0.21581197, 1.0, 72.0 / 60.0), 
		Vector4(0.03148148, 0.23888888, 5.0, 51.0 / 60.0), 
		Vector4(0.05277778, 0.27393161, 2.0, 78.0 / 60.0), 
		Vector4(0.94444442, 0.28589742, 6.0, 78.0 / 60.0), 
		Vector4(0.94907405, 0.32094016, 3.0, 57.0 / 60.0), 
		Vector4(0.06481481, 0.34401709, 7.0, 72.0 / 60.0), 
		Vector4(0.96296295, 0.39102565, 4.0, 51.0 / 60.0), 
		Vector4(0.94444445, 0.42606837, 1.0, 78.0 / 60.0), 
		Vector4(0.06481481, 0.48418804, 2.0, 72.0 / 60.0), 
		Vector4(0.92777777, 0.49615383, 6.0, 72.0 / 60.0), 
		Vector4(0.962963, 0.53119656, 3.0, 51.0 / 60.0), 
		Vector4(0.05277778, 0.55427352, 7.0, 78.0 / 60.0), 
		Vector4(0.04444445, 0.58931623, 0.0, 57.0 / 60.0), 
		Vector4(0.94907406, 0.60128205, 4.0, 57.0 / 60.0), 
		Vector4(0.92777778, 0.63632478, 1.0, 72.0 / 60.0), 
		Vector4(0.03148148, 0.65940169, 5.0, 51.0 / 60.0), 
		Vector4(0.05277778, 0.69444443, 2.0, 78.0 / 60.0), 
		Vector4(0.94444445, 0.70641025, 6.0, 78.0 / 60.0), 
		Vector4(0.94907407, 0.74145299, 3.0, 57.0 / 60.0), 
		Vector4(0.96296295, 0.81153847, 4.0, 51.0 / 60.0), 
		Vector4(0.94444444, 0.84658118, 1.0, 78.0 / 60.0), 
		Vector4(0.04444444, 0.86965812, 5.0, 57.0 / 60.0), 
	], 
]
const CURL_LAYOUT: Array[Vector4] = [
	Vector4(0.06481481, 0.20384616, 8.0, 84.0 / 60.0), 
	Vector4(0.96296298, 0.25085471, 9.0, 75.0 / 60.0), 
	Vector4(0.04444444, 0.30897437, 10.0, 84.0 / 60.0), 
	Vector4(0.92777775, 0.3559829, 8.0, 75.0 / 60.0), 
	Vector4(0.94907407, 0.46111112, 10.0, 75.0 / 60.0), 
	Vector4(0.03148148, 0.51923076, 8.0, 84.0 / 60.0), 
	Vector4(0.94444445, 0.56623931, 9.0, 75.0 / 60.0), 
	Vector4(0.06481481, 0.62435896, 10.0, 84.0 / 60.0), 
	Vector4(0.04444444, 0.72948719, 9.0, 84.0 / 60.0), 
	Vector4(0.9277778, 0.77649571, 10.0, 75.0 / 60.0), 
	Vector4(0.05277778, 0.83461541, 8.0, 84.0 / 60.0), 
	Vector4(0.94907405, 0.88162391, 9.0, 75.0 / 60.0), 
]


func _layout_emitters() -> void :
	var screen_size: Vector2 = UiMetrics.viewport_size()
	position = Vector2.ZERO
	size = screen_size
	for side: int in 2:
		var direction_x: float = 1.0 if side == 0 else -1.0
		var side_x: float = 0.0 if side == 0 else screen_size.x
		var confetti: GPUParticles2D = _petals[side]
		confetti.position = Vector2(side_x + direction_x * PETAL_EDGE_INSET, screen_size.y * 0.5)
		var confetti_items: PackedVector4Array = PackedVector4Array()
		for reference_item: Vector4 in CONFETTI_LAYOUT[_stage - 1]:
			if (reference_item.x < 0.5) == (side == 0):
				confetti_items.append(reference_item)
		_set_reference_items(confetti, _shuffle_reference_items(confetti_items), screen_size)
		_configure_petal_motion(confetti.process_material as ParticleProcessMaterial, 
			screen_size.x, direction_x)
		var curl: GPUParticles2D = _flowers[side]
		curl.position = Vector2(side_x + direction_x * FLOWER_EDGE_INSET, screen_size.y * 0.5)
		var curl_items: PackedVector4Array = PackedVector4Array()
		for reference_item: Vector4 in CURL_LAYOUT:
			if (reference_item.x < 0.5) == (side == 0):
				curl_items.append(reference_item)
		_set_reference_items(curl, _shuffle_reference_items(curl_items), screen_size)
		_configure_flower_motion(curl.process_material as ParticleProcessMaterial, 
			screen_size.x, direction_x)
	for emitter: GPUParticles2D in _petals + _flowers:
		emitter.visibility_rect = Rect2( - emitter.position - Vector2.ONE * CULL_MARGIN, 
			screen_size + Vector2.ONE * CULL_MARGIN * 2.0)
	var glow_scale: Vector2 = Vector2(
		screen_size.x / UiMetrics.DESIGN.x * GLOW_WIDTH_MULTIPLIER, 
		screen_size.y / UiMetrics.DESIGN.y)
	_glows[0].position = Vector2(0.0, screen_size.y * 365.0 / UiMetrics.DESIGN.y)
	_glows[1].position = Vector2(screen_size.x - _glows[1].texture.get_width() * glow_scale.x, 
		screen_size.y * 367.0 / UiMetrics.DESIGN.y)
	for glow: Sprite2D in _glows:
		glow.modulate = Color.WHITE
		glow.scale = glow_scale


func _set_reference_items(emitter: GPUParticles2D, reference_items: PackedVector4Array, 
		screen_size: Vector2) -> void :
	for item_index: int in reference_items.size():
		var reference_item: Vector4 = reference_items[item_index]
		var size_ratio: float = (reference_item.w - CONFETTI_REFERENCE_SCALE_RANGE.x) / (
			CONFETTI_REFERENCE_SCALE_RANGE.y - CONFETTI_REFERENCE_SCALE_RANGE.x)
		reference_item.w = lerpf(CONFETTI_SCALE_RANGE.x, CONFETTI_SCALE_RANGE.y, size_ratio)
		reference_items[item_index] = reference_item
	super._set_reference_items(emitter, reference_items, screen_size)


func _set_strength(strength: float) -> void :
	for lifecycle: GpuParticleLifecycle in _active_lifecycles:
		lifecycle.set_opacity(strength)
	for glow: Sprite2D in _glows:
		glow.self_modulate.a = strength if _stage == 3 else 0.0
