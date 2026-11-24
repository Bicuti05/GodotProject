class_name FinishRewardParticles
extends FinishParticleGroup
const SPARKLE_TEXTURE: Texture2D = preload("res://assets/effect/texture/point/ef_point_001.png")
const DOT_TEXTURE: Texture2D = preload("res://assets/effect/texture/point/ef_point_glow002.png")
func configure() -> void :
	for tex: Texture2D in [SPARKLE_TEXTURE, DOT_TEXTURE]:
		var pm: = ParticleProcessMaterial.new()

		pm.particle_flag_disable_z = true
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS

		var flower_points: Image = Image.create(34, 1, false, Image.FORMAT_RGBF)
		for i: int in 34:
			flower_points.set_pixel(i, 0, Color(float(i % 7) * 40.0, float(i / 7) * 40.0, 0.0))
		pm.emission_point_count = 34
		pm.emission_point_texture = ImageTexture.create_from_image(flower_points)
		pm.direction = Vector3(0.0, -1.0, 0.0)
		pm.spread = 180.0
		pm.gravity = Vector3.ZERO
		pm.initial_velocity_min = 0.0
		pm.initial_velocity_max = 18.0

		pm.scale_min = 0.0859 if tex == DOT_TEXTURE else 0.427
		pm.scale_max = 0.1641 if tex == DOT_TEXTURE else 0.708
		pm.color_ramp = _twinkle_ramp()
		var p: = GPUParticles2D.new()
		p.name = "FlowerSparkle" if tex == SPARKLE_TEXTURE else "FlowerDot"
		p.texture = tex
		p.process_material = pm
		p.amount = 7
		p.lifetime = 1.7
		p.visible = false
		p.emitting = false
		p.local_coords = false
		p.visibility_rect = Rect2(-1200.0, -1600.0, 2400.0, 3200.0)
		add_child(p)

	var points: PackedVector2Array = (preload("res://assets/sprites/finish/rainbow_emission_points.tres") as Resource).get_meta("points")
	var image: Image = Image.create(points.size(), 1, false, Image.FORMAT_RGBF)
	for i: int in points.size():
		image.set_pixel(i, 0, Color(points[i].x, points[i].y, 0.0))
	var material: ParticleProcessMaterial = ($RainbowSparkles as GPUParticles2D).process_material as ParticleProcessMaterial
	material.emission_point_count = points.size()
	material.emission_point_texture = ImageTexture.create_from_image(image)
	material.color_ramp = _twinkle_ramp()



func _twinkle_ramp() -> GradientTexture1D:
	var g: = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0), 
	])
	var texture: = GradientTexture1D.new()
	texture.gradient = g
	return texture
