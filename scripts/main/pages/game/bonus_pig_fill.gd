class_name BonusPigFill
extends Control



const ACCENT_DURATION: float = JuiceBoardView.BURST_DUR
const COLLECT_STAGGER: float = 0.0
const FLIGHT_DURATION: float = JuiceBoardView.GHOST_FADE_DUR + JuiceBoardView.SLAM_FLY_DUR
const ENTRY_DURATION: float = 0.0
@export var pig_texture: Texture2D
@export var coin_texture: Texture2D
@export var entry_point_texture: Texture2D
@export var entry_star_texture: Texture2D
@export var mouth_anchor: Vector2 = Vector2(0.5, 0.085)
@onready var _pig: TextureRect = $Pig
var _coins: Array[Sprite2D] = []
var _tween: Tween = null
var _generation: int = 0
var _running: bool = false
var _pig_rect: Rect2
var _coin_speed: float = 1.0
var _origins: Array[Vector2] = []
var _ribbons: Array[FireworkTrails.Ribbon] = []
var _trails: FireworkTrails
var _sample_time: float = 0.0
var _coin_diameter: float = 100.0
var _count: int = 0
var _entry_events: Array[float] = []
var _entered: Array[bool] = []
var _entry_particles: Array[Sprite2D] = []
const ENTRY_PARTICLE_LIFE: float = 0.28
const ENTRY_FEEDBACK_STAGGER: float = 0.045

func _ready() -> void :
	_pig.texture = pig_texture
	_trails = BonusGoldTrails.new()
	_trails.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(_trails)
	move_child(_trails, 0)
	_trails.set_process(false)
	_trails.prepare_pool(6)
	for i: int in range(6):
		var coin: = Sprite2D.new()
		coin.texture = coin_texture
		add_child(coin)
		_coins.append(coin)
	var add_material: = CanvasItemMaterial.new()
	add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i: int in range(30):
		var particle: = Sprite2D.new()
		particle.texture = entry_star_texture if i % 5 == 4 else entry_point_texture
		particle.material = add_material
		particle.hide()
		add_child(particle)
		_entry_particles.append(particle)
	cancel()

func is_running() -> bool:
	return _running

func pig_global_rect() -> Rect2:
	return _pig_rect

func cancel() -> void :
	_generation += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_running = false
	visible = false
	if _pig != null:
		_pig.hide()
		_pig.scale = Vector2.ONE
	for coin: Sprite2D in _coins:
		coin.hide()
	if _trails != null:
		_trails.clear_all()
	_ribbons.clear()
	_entry_events.clear()
	for particle: Sprite2D in _entry_particles:
		particle.hide()

func play(pig_rect: Rect2, origins: Array[Vector2], diameter: float, speed: float = 1.0) -> void :
	cancel()
	var generation: int = _generation
	_coin_speed = maxf(speed, 0.01)
	_pig_rect = pig_rect
	_origins = origins.duplicate()
	_coin_diameter = diameter
	_count = mini(_origins.size(), _coins.size())
	if _count == 0:
		return
	_running = true
	visible = true
	_pig.size = pig_rect.size
	_pig.global_position = pig_rect.position
	_pig.pivot_offset = Vector2(pig_rect.size.x * 0.5, pig_rect.size.y)
	_pig.show()
	_entered.resize(_count)
	_entered.fill(false)
	_ribbons.resize(_count)
	_ribbons.fill(null)
	for i: int in range(_count):
		var coin: Sprite2D = _coins[i]
		coin.scale = Vector2.ONE * diameter / coin_texture.get_width()
		coin.rotation = 0.0
		coin.modulate = Color.WHITE
		coin.global_position = _origins[i]
		coin.show()
	_sample_time = 0.0
	_sample_collection(0.0)
	var total: float = ACCENT_DURATION + float(_count - 1) * COLLECT_STAGGER + FLIGHT_DURATION + ENTRY_DURATION + ENTRY_PARTICLE_LIFE + float(_count - 1) * ENTRY_FEEDBACK_STAGGER + 0.04
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_speed_scale(_coin_speed)
	_tween.tween_method(_sample_collection, 0.0, total, total)
	var tw: Tween = _tween
	while generation == _generation and tw.is_valid() and tw.is_running():
		await get_tree().process_frame
	if generation == _generation:
		_running = false
		_tween = null

func _sample_collection(age: float) -> void :
	var mouth: Vector2 = _pig_rect.position + mouth_anchor * _pig_rect.size
	var punch: float = 0.0
	for i: int in range(_count):
		var coin: Sprite2D = _coins[i]
		var motion_age: float = age - ACCENT_DURATION
		var arrival: float = motion_age - FLIGHT_DURATION
		if motion_age < 0.0:

			var up: float = JuiceBoardView.BURST_PULSE_UP_DUR
			var down: float = JuiceBoardView.BURST_PULSE_DOWN_DUR
			var peak: float = JuiceBoardView.BURST_PULSE_SCALE
			var pulse: float = lerpf(1.0, peak, smoothstep(0.0, up, age)) if age < up else lerpf(peak, 1.0, smoothstep(up, up + down, age))
			coin.scale = Vector2.ONE * pulse * _coin_diameter / coin_texture.get_width()
			coin.global_position = _origins[i]
		else:
			var motion: Dictionary = JuiceBoardView.sample_collection_motion(_origins[i], mouth, i, motion_age)
			if bool(motion["done"]):
				if not _entered[i]:
					_entered[i] = true
					_entry_events.append(ACCENT_DURATION + FLIGHT_DURATION + float(i) * ENTRY_FEEDBACK_STAGGER)
				if _ribbons[i] != null:
					_ribbons[i].detach()
				if coin.visible:
					coin.hide()
			else:
				coin.modulate.a = 1.0
				coin.scale = Vector2.ONE * float(motion["scale"]) * _coin_diameter / coin_texture.get_width()
				coin.global_position = motion["center"]
				if bool(motion["flight"]) and _ribbons[i] == null:
					_ribbons[i] = _trails.add_ribbon(coin, _coin_diameter * JuiceBoardView.SLAM_TRAIL_WIDTH_RATIO, 
						Color(1.0, 0.78, 0.27), JuiceBoardView.SLAM_TRAIL_HEAD_ALPHA, JuiceBoardView.SLAM_TRAIL_LIFETIME)
		if arrival >= 0.0 and arrival < 0.2:
			punch = maxf(punch, sin(arrival / 0.2 * PI))
	_pig.scale = Vector2(1.0 + punch * 0.035, 1.0 - punch * 0.025)

	for ribbon: FireworkTrails.Ribbon in _trails._ribbons:
		_trails._sample(ribbon, age)
		_trails._expire(ribbon, age)
	_trails._rebuild()
	(_trails as BonusGoldTrails).update_dust_targets()
	_sample_entry_particles(age, mouth)
	_sample_time = age

func set_coin_playback_speed(speed: float) -> void :
	_coin_speed = maxf(speed, 0.01)


func _sample_entry_particles(age: float, mouth: Vector2) -> void :
	for event: int in range(_entry_events.size()):
		var t: float = age - _entry_events[event]
		for j: int in range(5):
			var particle: Sprite2D = _entry_particles[event * 5 + j]
			if t < 0.0 or t >= ENTRY_PARTICLE_LIFE:
				particle.hide()
				continue
			var direction: Vector2 = Vector2.from_angle( - PI + 0.25 + float(j) * (PI - 0.5) / 4.0)
			var distance: float = lerpf(58.0, 0.0, smoothstep(0.0, 0.16, t)) if j < 3 else (30.0 * (1.0 - exp( - t / 0.08)) if j == 3 else 0.0)
			particle.global_position = mouth + direction * distance
			var diameter: float = 44.0 if j == 4 else 28.0 + j * 4.0
			particle.scale = Vector2.ONE * diameter / particle.texture.get_width()
			particle.modulate = Color(1.0, 0.84, 0.38, smoothstep(0.0, 0.03, t) * (1.0 - smoothstep(0.06, ENTRY_PARTICLE_LIFE, t)))
			particle.show()
