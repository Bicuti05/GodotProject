class_name HomeCoinBonusFx
extends TextureRect

const CYCLE_DURATION: float = 3.2
const SWAY_CYCLE_DURATION: float = 7.2
const SWAY_AMPLITUDE: float = 15.0
const SWAY_TIME_OFFSET: float = 0.21204
const BUTTON_BREATH_REFERENCE: float = 0.035
const BUTTON_SWAY_SPEED_BOOST: float = 0.65
const BUTTON_SWAY_RESPONSE: float = 0.16
const TAG_PIVOT_RATIO: Vector2 = Vector2(0.45454545, 0.28181818)
const SWEEP_DELAY: float = 0.42
const SWEEP_DURATION: float = 0.85
const GLEAM_DELAYS: Array[float] = [0.32, 0.94, 1.24]
const GLEAM_DURATION: float = 0.46

@export var button: BaseButton
@export var face: NinePatchRect
@export var sweep: NinePatchRect

@onready var _tag: TextureRect = $Tag
@onready var _gleams: Array[TextureRect] = [$Tag / TopGleam, $Tag / RightGleam, $Tag / LeftGleam]

var _enabled: bool = false
var _sweep_enabled: bool = true
var _application_active: bool = true
var _running: bool = false
var _elapsed: float = 0.0
var _sway_elapsed: float = 0.0
var _button_sway_speed_target: float = 1.0
var _button_sway_speed: float = 1.0
var _button_sway_speed_velocity: float = 0.0
var _sweep_material: ShaderMaterial


func _ready() -> void :
	process_priority = 1
	_sweep_material = sweep.material.duplicate() as ShaderMaterial
	sweep.material = _sweep_material
	_update_layout()
	_reset_pose()
	set_process(false)


func set_effect_enabled(enabled: bool, allow_sweep: bool = true) -> void :
	_sweep_enabled = allow_sweep
	if not allow_sweep:
		sweep.visible = false
	if _enabled == enabled:
		return
	_enabled = enabled
	set_process(enabled)
	if not enabled:
		_set_running(false)
		_reset_pose()


func set_button_motion(progress: float, strength: float) -> void :
	var motion_progress: float = clampf(progress, 0.0, 1.0)
	var strength_ratio: float = clampf(strength / BUTTON_BREATH_REFERENCE, 0.0, 1.25)
	var drive: float = smoothstep(0.0, 0.4, motion_progress)\
	if motion_progress <= 0.4 else 1.0 - smoothstep(0.4, 1.0, motion_progress)
	_button_sway_speed_target = 1.0 + drive * strength_ratio * BUTTON_SWAY_SPEED_BOOST


func _process(delta: float) -> void :
	_set_running(_enabled and _application_active and can_process() and is_visible_in_tree()\
	and not button.disabled and not button.button_pressed\
	and button.mouse_filter != Control.MOUSE_FILTER_IGNORE and button.modulate.a >= 0.98)
	if not _running:
		return
	_elapsed += delta
	var phase: float = fposmod(_elapsed, CYCLE_DURATION)
	_update_button_sway(delta)
	_tag.rotation = deg_to_rad(_sway_angle(_sway_elapsed))
	_animate_sweep(phase)
	for index: int in range(_gleams.size()):
		var gleam: TextureRect = _gleams[index]
		var progress: float = clampf((phase - GLEAM_DELAYS[index]) / GLEAM_DURATION, 0.0, 1.0)
		var highlight: float = pow(sin(progress * PI), 2.0)
		gleam.visible = highlight > 0.005
		gleam.self_modulate.a = highlight * 0.9
		gleam.scale = Vector2.ONE * (0.28 + highlight * 0.62)
		gleam.rotation = progress * PI * 0.18


func _sway_angle(elapsed: float) -> float:
	var phase: float = fposmod(elapsed + SWAY_TIME_OFFSET, SWAY_CYCLE_DURATION)
	return sin(phase * TAU / SWAY_CYCLE_DURATION) * SWAY_AMPLITUDE


func _update_button_sway(delta: float) -> void :
	var previous_speed: float = _button_sway_speed
	var damping: float = 2.0 / BUTTON_SWAY_RESPONSE
	var displacement: float = _button_sway_speed - _button_sway_speed_target
	var velocity_term: float = _button_sway_speed_velocity + displacement * damping
	var decay: float = exp( - damping * delta)
	_button_sway_speed = _button_sway_speed_target + (displacement + velocity_term * delta) * decay
	_button_sway_speed_velocity = (_button_sway_speed_velocity - velocity_term * damping * delta) * decay
	_sway_elapsed += (previous_speed + _button_sway_speed) * delta * 0.5


func _animate_sweep(phase: float) -> void :
	var progress: float = (phase - SWEEP_DELAY) / SWEEP_DURATION
	sweep.visible = _sweep_enabled and progress > 0.0 and progress < 1.0
	if not sweep.visible:
		return
	if sweep.texture != face.texture:
		sweep.texture = face.texture
	_sweep_material.set_shader_parameter("progress", lerpf(-0.3, 1.3, progress))
	_sweep_material.set_shader_parameter("envelope", smoothstep(0.0, 0.13, progress)\
	* (1.0 - smoothstep(0.78, 1.0, progress)))


func _set_running(running: bool) -> void :
	if _running == running:
		return
	_running = running
	_elapsed = 0.0
	if not running:
		_reset_pose()


func _reset_pose() -> void :
	_sway_elapsed = 0.0
	_button_sway_speed_target = 1.0
	_button_sway_speed = 1.0
	_button_sway_speed_velocity = 0.0
	_tag.rotation = deg_to_rad(_sway_angle(0.0))
	sweep.visible = false
	_sweep_material.set_shader_parameter("envelope", 0.0)
	for gleam: TextureRect in _gleams:
		gleam.visible = false
		gleam.self_modulate.a = 0.0
		gleam.scale = Vector2.ONE
		gleam.rotation = 0.0


func _on_button_resized() -> void :
	if is_node_ready():
		_update_layout()


func _update_layout() -> void :
	_tag.pivot_offset = _tag.size * TAG_PIVOT_RATIO
	for gleam: TextureRect in _gleams:
		gleam.pivot_offset = gleam.size * 0.5
	_sweep_material.set_shader_parameter("button_size", face.size)
	sweep.patch_margin_left = face.patch_margin_left
	sweep.patch_margin_top = face.patch_margin_top
	sweep.patch_margin_right = face.patch_margin_right
	sweep.patch_margin_bottom = face.patch_margin_bottom
	sweep.texture = face.texture


func _on_button_down() -> void :
	_set_running(false)


func _on_visibility_changed() -> void :
	if is_node_ready() and not is_visible_in_tree():
		_set_running(false)


func _notification(what: int) -> void :
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_active = false
		if is_node_ready():
			_set_running(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_active = true
	elif what == NOTIFICATION_PAUSED and is_node_ready():
		_set_running(false)


func _exit_tree() -> void :
	_set_running(false)
