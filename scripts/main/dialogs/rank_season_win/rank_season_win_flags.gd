class_name RankSeasonWinFlags
extends SpineSprite

const DESIGN_SCALE: float = 0.7748305
const FLAG_SLOTS: PackedStringArray = ["celebration_flags_left", "celebration_flags_right"]

var _hidden_slots: Array[SpineSlot] = []


func _ready() -> void :
	for slot: SpineSlot in get_skeleton().get_slots():
		if slot.get_data().get_name() not in FLAG_SLOTS:
			_hidden_slots.append(slot)
	before_world_transforms_change.connect(_filter_and_pin_flags)
	stop()


func play() -> void :
	var insets: Vector2 = UiMetrics.safe_insets()
	var layout_scale: float = minf(1.0, 
		(UiMetrics.viewport_size().y - insets.x - insets.y) / UiMetrics.DESIGN.y)
	scale = Vector2.ONE * layout_scale / DESIGN_SCALE
	position = Vector2.ZERO
	var state: SpineAnimationState = get_animation_state()
	state.clear_tracks()
	get_skeleton().set_to_setup_pose()
	state.set_animation("Appear", false, 0)
	state.add_animation("flags_idle", 0.0, true, 0)
	set_time_scale(1.0)
	visible = true
	update_skeleton(0.0)
	update_mode = SpineConstant.UpdateMode_Process


func stop() -> void :
	visible = false
	update_mode = SpineConstant.UpdateMode_Manual
	set_time_scale(0.0)
	get_animation_state().clear_tracks()


func _filter_and_pin_flags(_sprite: SpineSprite) -> void :
	for slot: SpineSlot in _hidden_slots:
		slot.set_attachment(null)
	var viewport: Vector2 = UiMetrics.viewport_size()
	var layout_scale: float = scale.x * DESIGN_SCALE
	var inverse: Transform2D = global_transform.affine_inverse()
	for side: String in ["left", "right"]:
		var half_width: float = (219.0 if side == "left" else 219.5) * layout_scale
		var center: Vector2 = Vector2(half_width if side == "left" else viewport.x - half_width, 
			119.0 * layout_scale)
		var local: Vector2 = inverse * center
		var bone: SpineBone = get_skeleton().find_bone("celebration_flags_" + side + "_1x")
		bone.set_x(local.x)
		bone.set_y( - local.y)
