class_name FinishCardBurst
extends FinishParticleGroup

const POINT_DATA_JOB: GDScript = preload("res://scripts/main/dialogs/finish/effects/finish_particle_point_data_job.gd")
var _point_pixels: PackedByteArray = PackedByteArray()


func set_preparation_data(pixels: PackedByteArray) -> void :
	_point_pixels = pixels


func configuration_uploads_texture(_name: StringName) -> bool:
	return true


func configure_emitter(_name: StringName, emitter: GPUParticles2D) -> void :
	if _point_pixels.is_empty():

		var rng: = RandomNumberGenerator.new()
		rng.randomize()
		_point_pixels = POINT_DATA_JOB.generate(rng)
	var points: Image = Image.create_from_data(64, 1, false, Image.FORMAT_RGBF, _point_pixels)
	var material: ParticleProcessMaterial = emitter.process_material as ParticleProcessMaterial
	material.emission_point_texture = ImageTexture.create_from_image(points)
	material.emission_point_count = 64


func configure() -> void :
	var points: Image = Image.create(64, 1, false, Image.FORMAT_RGBF)
	var half: = Vector2(140.0, 269.2308 * 0.5)
	for i: int in 64:
		var point: Vector2
		match i % 4:
			0: point = Vector2(randf_range( - half.x, half.x), - half.y + randf() * 5.0)
			1: point = Vector2(randf_range( - half.x, half.x), half.y - randf() * 5.0)
			2: point = Vector2( - half.x + randf() * 5.0, randf_range( - half.y, half.y))
			3: point = Vector2(half.x - randf() * 5.0, randf_range( - half.y, half.y))
		points.set_pixel(i, 0, Color(point.x, point.y, 0.0))
	var burst: GPUParticles2D = $Burst
	var material: ParticleProcessMaterial = burst.process_material.duplicate() as ParticleProcessMaterial
	material.emission_point_texture = ImageTexture.create_from_image(points)
	material.emission_point_count = 64
	burst.process_material = material
