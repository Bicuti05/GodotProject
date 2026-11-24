class_name JuiceRulesBar
extends Control


const DESIGN_SIZE: = Vector2(1008.0, 285.0)

const OUTER_WITH_IQ_RECT: = Rect2(0, 10, 1008, 213)
const OUTER_BODY_REGION: = Rect2(0, 53, 1008, 160)
const RULE_KEYS: Array[StringName] = [
	&"JUICE_RULE_CONNECT_SAME_COLOR", &"JUICE_RULE_COLLECT_BY_COLOR", &"JUICE_RULE_USE_EMPTY_ROPES", 
]
const RULE_TEXT_SIZE: = Vector2(180, 90)
const RULE_TEXT_ORIGINS: Array[Vector2] = [Vector2(163, 98), Vector2(473, 98), Vector2(794, 98)]
const RULE_TEXT_FONT_SIZE: = 34
const RULE_TEXT_MIN_FONT_SIZE: = 20
const GUIDE_FIELDS: Array[StringName] = [
	&"guide_connect_same_color", &"guide_collect_by_color", &"guide_use_empty_ropes", 
]
const ICON_ORIGINS: Array[Vector2] = [Vector2(33, 83), Vector2(343, 83), Vector2(664, 83)]
const RULE_ICON_SIZE: = Vector2(120, 120)
const RULE_FOCUS_WIDTH_RATIO: = 0.5
const RULE_FOCUS_PEAK_RATIO: = 1.025
const RULE_SCREEN_MARGIN: = 12.0
const RULE_BACKGROUND_PADDING: = 4.0
const RULE_FOCUS_OFFSET: = Vector2(0, -6)
const RULE_FOCUS_IN_DURATION: = 0.2
const RULE_FOCUS_SETTLE_DURATION: = 0.12
const RULE_FOCUS_OUT_DURATION: = 0.22

const TARGET_REFERENCE: = Rect2(4, 4, 52, 52)

@onready var _groups: Array[Control] = [$ConnectRule, $CollectRule, $EmptyRule]
@onready var _backgrounds: Array[NinePatchRect] = [$ConnectRule / Background, $CollectRule / Background, $EmptyRule / Background]
@onready var _icons: Array[TextureRect] = [$ConnectRule / Icon, $CollectRule / Icon, $EmptyRule / Icon]
@onready var _labels: Array[Label] = [$ConnectRule / Text, $CollectRule / Text, $EmptyRule / Text]
@onready var _target_slot: Control = $TargetSlot
@onready var _target_icon: TextureRect = $TargetSlot / Icon
@onready var _count: Label = $Count
@onready var _outer: TextureRect = $Outer
@onready var _entrance_glow: NinePatchRect = $EntranceGlow
var _outer_with_iq: Texture2D
var _outer_without_iq: AtlasTexture
var _iq_tab_enabled: bool = false
var _active_rule: int = -1
var _dim_amounts: = Vector3.ZERO
var _rule_tweens: Array[Tween] = [null, null, null]
var _rule_content_rects: Array[Rect2] = [Rect2(), Rect2(), Rect2()]


func _ready() -> void :
	_outer_with_iq = _outer.texture
	_outer_without_iq = AtlasTexture.new()
	_outer_without_iq.atlas = _outer_with_iq
	_outer_without_iq.region = OUTER_BODY_REGION
	_outer_without_iq.filter_clip = true
	set_iq_tab_enabled(_iq_tab_enabled)
	_refresh_labels()
	set_count(_count.text)
	set_active_rule(_active_rule, false)
	set_entrance_glow_alpha(0.0)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	set_notify_transform(true)


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_labels()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not is_visible_in_tree():

		set_active_rule(_active_rule, false)
	elif what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():

		for i: int in _groups.size():
			_set_rule_position(_groups[i].position, i)


func _on_viewport_size_changed() -> void :
	set_active_rule(_active_rule, false)


func _exit_tree() -> void :
	_cancel_rule_tweens()



func set_iq_tab_enabled(enabled: bool) -> void :
	_iq_tab_enabled = enabled
	if not is_node_ready():
		return
	_outer.texture = _outer_with_iq if enabled else _outer_without_iq
	_outer.position = OUTER_WITH_IQ_RECT.position + Vector2(0, 0 if enabled else OUTER_BODY_REGION.position.y)
	_outer.size = OUTER_WITH_IQ_RECT.size if enabled else OUTER_BODY_REGION.size



func set_entrance_glow_alpha(alpha: float) -> void :
	if not is_node_ready():
		return
	var color: Color = _entrance_glow.self_modulate
	color.a = clampf(alpha, 0.0, 1.0)
	_entrance_glow.self_modulate = color
	_entrance_glow.visible = color.a > 0.0


func _refresh_labels() -> void :
	for i: int in RULE_KEYS.size():
		var label: Label = _labels[i]
		label.text = tr(RULE_KEYS[i])

		label.clip_text = false
		var font_size: int = RULE_TEXT_FONT_SIZE
		label.add_theme_font_size_override(&"font_size", font_size)
		_set_line_height(label, font_size)
		label.size = RULE_TEXT_SIZE
		while label.get_minimum_size().y > RULE_TEXT_SIZE.y and font_size > RULE_TEXT_MIN_FONT_SIZE:
			font_size -= 1
			label.add_theme_font_size_override(&"font_size", font_size)
			_set_line_height(label, font_size)

		label.clip_text = true
		label.size = RULE_TEXT_SIZE
		label.position = RULE_TEXT_ORIGINS[i] - ICON_ORIGINS[i]
		_refresh_rule_pivot(i)
	if _active_rule >= 0:
		set_active_rule(_active_rule, false)


func _refresh_rule_pivot(index: int) -> void :
	var content: Rect2 = _icons[index].get_rect().merge(_labels[index].get_rect())
	_rule_content_rects[index] = content
	_groups[index].pivot_offset = content.get_center()

	var background: Rect2 = Rect2(Vector2(content.position.x, 0), 
		Vector2(content.size.x, RULE_ICON_SIZE.y)).grow(RULE_BACKGROUND_PADDING)
	_backgrounds[index].position = background.position
	_backgrounds[index].size = background.size


func _set_line_height(label: Label, font_size: int) -> void :
	var font: Font = label.get_theme_font(&"font")
	label.add_theme_constant_override(&"line_spacing", roundi(36.0 * float(font_size) / float(RULE_TEXT_FONT_SIZE) - font.get_height(font_size)))


func apply_skin(resources: JuiceSkinResolver) -> void :
	for i: int in GUIDE_FIELDS.size():
		var visual: JuiceSkinVisual = resources.single_visual(GUIDE_FIELDS[i])
		var rect: Rect2 = visual.display_rect(Rect2(ICON_ORIGINS[i], RULE_ICON_SIZE))
		_icons[i].texture = visual.texture
		_icons[i].position = rect.position - ICON_ORIGINS[i]
		_icons[i].size = rect.size
		_refresh_rule_pivot(i)
	var empty: JuiceSkinVisual = resources.single_visual(&"guide_target_empty_icon")
	var target_rect: Rect2 = empty.display_rect(TARGET_REFERENCE)
	_target_icon.texture = empty.texture
	_target_icon.position = target_rect.position
	_target_icon.size = target_rect.size
	if _active_rule >= 0:
		set_active_rule(_active_rule, false)


func set_count(text: String) -> void :
	_count.text = text

	_count.size = Vector2(100, 40).max(_count.get_minimum_size())
	_count.position = Vector2(534, 252) - _count.size * 0.5



func set_active_rule(index: int, animate: bool = true) -> void :
	var next_rule: int = index if index >= 0 and index < RULE_KEYS.size() else -1
	if animate and next_rule == _active_rule:
		return
	_active_rule = next_rule
	if not is_node_ready():
		return
	_cancel_rule_tweens()
	for i: int in RULE_KEYS.size():
		var focused: bool = i == _active_rule
		_groups[i].z_index = 3 if focused else 0
		var dst_dim: float = 0.0 if focused or _active_rule < 0 else 1.0
		var factor: float = DESIGN_SIZE.x * RULE_FOCUS_WIDTH_RATIO / _rule_content_rects[i].size.x if focused else 1.0
		var dst_scale: Vector2 = Vector2.ONE * factor
		var dst_pos: Vector2 = ICON_ORIGINS[i] + (RULE_FOCUS_OFFSET if focused else Vector2.ZERO)
		if not animate or not is_visible_in_tree():
			_set_rule_dim(dst_dim, i)
			_set_rule_scale(dst_scale, i)
			_set_rule_position(dst_pos, i)
			continue
		var duration: float = RULE_FOCUS_IN_DURATION if focused else RULE_FOCUS_OUT_DURATION
		var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rule_tweens[i] = tween
		tween.tween_method(_set_rule_dim.bind(i), _dim_amounts[i], dst_dim, duration)
		tween.tween_method(_set_rule_scale.bind(i), _groups[i].scale, dst_scale * RULE_FOCUS_PEAK_RATIO if focused else dst_scale, duration)
		tween.tween_method(_set_rule_position.bind(i), _groups[i].position, dst_pos, duration)
		if focused:
			tween.chain().tween_method(_set_rule_scale.bind(i), dst_scale * RULE_FOCUS_PEAK_RATIO, dst_scale, RULE_FOCUS_SETTLE_DURATION)


func _set_rule_scale(value: Vector2, index: int) -> void :
	_groups[index].scale = value
	_set_rule_position(_groups[index].position, index)



func _set_rule_position(value: Vector2, index: int) -> void :
	var screen: Rect2 = Rect2(Vector2(RULE_SCREEN_MARGIN, 0), UiMetrics.viewport_size() - Vector2(RULE_SCREEN_MARGIN * 2.0, 0))
	var local_screen: Rect2 = get_global_transform_with_canvas().affine_inverse() * screen
	var group: Control = _groups[index]
	var content: Rect2 = _backgrounds[index].get_rect()
	var pivot_shift: Vector2 = group.pivot_offset * (Vector2.ONE - group.scale)
	var left: float = content.position.x * group.scale.x + pivot_shift.x
	var right: float = content.end.x * group.scale.x + pivot_shift.x
	value.x = clampf(value.x, local_screen.position.x - left, local_screen.end.x - right)
	group.position = value


func _set_rule_dim(amount: float, index: int) -> void :
	_dim_amounts[index] = amount
	(_groups[index].material as ShaderMaterial).set_shader_parameter(&"dim_amount", amount)


func _cancel_rule_tweens() -> void :
	for i: int in _rule_tweens.size():
		var tween: Tween = _rule_tweens[i]
		if tween != null and tween.is_valid():
			tween.kill()
		_rule_tweens[i] = null


func target_global_rect() -> Rect2:
	return _target_slot.get_global_rect()


func count_global_rect() -> Rect2:
	return _count.get_global_rect()
