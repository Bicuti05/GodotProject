extends Node2D


@export var title_design_size: Vector2 = Vector2(861.789063, 141.318085)
@export var coin_glow_width_ratio: float = 1.6
@export var rays_rotation_seconds: float = 8.0

@onready var title_particles: Node2D = $TitleParticles
@onready var stars: MultiMeshInstance2D = $TitleParticles / Stars
@onready var dots: MultiMeshInstance2D = $TitleParticles / Dots
@onready var coin_glow: Node2D = $CoinGlow
@onready var glow_core: Sprite2D = $CoinGlow / Core
@onready var glow_rays: Sprite2D = $CoinGlow / Rays

var _title_running: bool = false
var _paused: bool = false
var _title_tween: Tween
var _coin_tween: Tween


func _ready() -> void :
	reset()


func play_title(title_rect: Rect2) -> void :
	_clear_title()
	var ratio: float = title_rect.size.x / title_design_size.x
	title_particles.position = title_rect.position + Vector2(0.0, (title_rect.size.y - title_design_size.y * ratio) * 0.5)
	title_particles.scale = Vector2.ONE * ratio
	title_particles.modulate.a = 0.0
	title_particles.show()
	for emitter: MultiMeshInstance2D in [stars, dots]:
		emitter.restart()

		emitter.set_process(false)
	_title_running = true
	show()
	set_process(true)
	_title_tween = _animate()
	_title_tween.tween_property(title_particles, "modulate:a", 1.0, 0.12)


func play_coin(coin_position: Vector2, coin_width: float) -> void :
	_clear_coin()
	update_coin_pose(coin_position, coin_width)
	coin_glow.modulate.a = 0.0
	coin_glow.show()
	show()
	set_process(true)
	_coin_tween = _animate()
	_coin_tween.tween_property(coin_glow, "modulate:a", 1.0, 0.1)



func update_coin_pose(coin_position: Vector2, coin_width: float) -> void :
	coin_glow.position = coin_position
	var width: float = coin_width * coin_glow_width_ratio
	glow_core.scale = Vector2.ONE * width / glow_core.texture.get_width()
	glow_rays.scale = Vector2.ONE * width / glow_rays.texture.get_width()



func stop() -> void :
	if _title_running:
		if _title_tween != null and _title_tween.is_valid():
			_title_tween.kill()
		stars.emitting = false
		dots.emitting = false
		_title_tween = _animate()
		_title_tween.tween_property(title_particles, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_title_tween.tween_callback(_clear_title)
	if coin_glow.visible:
		if _coin_tween != null and _coin_tween.is_valid():
			_coin_tween.kill()
		_coin_tween = _animate()
		_coin_tween.tween_property(coin_glow, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_coin_tween.tween_callback(_clear_coin)


func suspend(value: bool) -> void :
	if _paused == value:
		return
	_paused = value
	for tween: Tween in [_title_tween, _coin_tween]:
		if tween != null and tween.is_valid():
			if value:
				tween.pause()
			else:
				tween.play()


func reset() -> void :
	hide()
	_clear_title()
	_clear_coin()
	_paused = false
	set_process(false)


func _process(delta: float) -> void :
	if _paused or not is_visible_in_tree():
		return
	if _title_running:
		stars._process(delta)
		dots._process(delta)
	if coin_glow.visible:
		glow_rays.rotation = fposmod(glow_rays.rotation + delta * TAU / rays_rotation_seconds, TAU)


func _animate() -> Tween:
	var tween: Tween = create_tween().set_ignore_time_scale(true)
	if _paused:
		tween.pause()
	return tween


func _clear_title() -> void :
	if _title_tween != null and _title_tween.is_valid():
		_title_tween.kill()
	_title_tween = null
	_title_running = false
	if is_instance_valid(title_particles):
		title_particles.hide()
		title_particles.modulate.a = 0.0
		stars.clear()
		dots.clear()
	if is_instance_valid(coin_glow) and not coin_glow.visible:
		set_process(false)


func _clear_coin() -> void :
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.kill()
	_coin_tween = null
	if is_instance_valid(coin_glow):
		coin_glow.hide()
		coin_glow.modulate.a = 0.0
		glow_rays.rotation = 0.0
	if not _title_running:
		set_process(false)


func _exit_tree() -> void :
	reset()
