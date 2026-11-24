class_name SpecialChallengeRewardDialog
extends PageScene

const SPINE_DESIGN_SCALE: float = 0.7748305
const SPINE_DESIGN_ORIGIN: Vector2 = Vector2(-8.317, 1343.9054)
const REWARD_SLOTS: Dictionary = {"undo": "reward_bulb", "coins": "reward_coin", "hint": "reward_undo", "rope": "reward_coin"}
const BANNER_STRETCH_BEGIN: float = 14.0 / 30.0
const BANNER_FADE_DURATION: float = 0.12
const CHEST_LIGHT_SCALE: float = 1.35
const GARDEN_ADVANCE: float = 0.2
const GARDEN_SHAKE_DURATION: float = 0.55
const CHEST_LANDING_TIME: float = 14.0 / 30.0
const CHEST_OPEN_TIME: float = 25.0 / 30.0
const CHEST_SHAKE_SPEED: float = 0.75
const CHEST_SHAKE_EASE: float = 0.035
const POST_LANDING_SPEED: float = 0.72
const CHEST_LIGHT_BEGIN: float = 26.0 / 30.0
const CHEST_LIGHT_SPEED: float = 0.55
const REWARD_REVEAL_TIMES: Dictionary = {"left": 1.0, "middle": 1.18, "right": 1.36}
const REWARD_REVEAL_STRETCH: float = 1.5
const REWARD_REVEAL_FADE: float = 0.12
const BUTTON_REVEAL_TIME: float = 1.8
const BUTTON_SOURCE_TIME: float = 46.0 / 30.0
const REWARD_HALO_SPEED_SCALE: float = 1.0 / 12.0
const REWARD_HALO_SPIN: float = 48.0
const REWARD_SPARKLE_SETTLE_DURATION: float = 2.4
const REWARD_SPARKLE_SETTLED_SPEED: float = 0.6
const REWARD_HALO_START_TIMES: Dictionary = {"left": 28.0 / 30.0, "middle": 31.0 / 30.0, "right": 34.0 / 30.0}
const REWARD_HALO_SIZE: Vector2 = Vector2(313.2, 313.2)
const REWARD_HALO_OFFSETS: Dictionary = {
	"undo": Vector2(5.1196, 11.1179), "coins": Vector2(-0.4454, -4.1504), 
	"hint": Vector2(0.0, -16.0003), "rope": Vector2.ZERO, 
}
const ROPE_DESIGN_SIZE: float = 233.928
const SINGLE_ROPE_REWARD_POSITION: Vector2 = Vector2(539.92, 691.92)
const SINGLE_REWARD_LAYOUT: Dictionary = {
	"icon": Vector2(533.7765, 658.4785), "count": Vector2(533.4004, 854.5005), 
	"scale": 1.2, 
}
const DOUBLE_REWARD_LAYOUT: Dictionary = {
	"undo": {"icon": Vector2(322.2607, 679.1854), "count": Vector2(322.9106, 850.8354), 
		"scale": 1.1}, 
	"hint": {"icon": Vector2(752.9683, 670.4454), "count": Vector2(752.5405, 850.0904), 
		"scale": 1.1}, 
}
const COLLECTION_FADE_DURATION: float = 0.16
const PROP_SPLIT_DURATION: float = 0.22
const PROP_FLIGHT_DURATION: float = 0.62
const PROP_FLIGHT_STAGGER: float = 0.12
const PROP_GROUP_STAGGER: float = 0.2
const PROP_FRAME_BOUNDS: Rect2 = Rect2(0.05882353, 0.10526316, 0.88235294, 0.78947368)
const HUD_REVEAL_DURATION: float = 0.32
const TITLE_VIEWPORT_SIZE: Vector2 = Vector2(660.0, 160.0)
const TITLE_FONT_SIZE: int = 100
const BUTTON_FONT_SIZE: int = 102
const BUTTON_TEXT_MARGIN: float = 48.0

var _generation: int = 0
var _instance_id: String = ""
var _busy: bool = false
var _claimed: bool = false
var _ready_ad: bool = false
var _querying: bool = false
var _query_again: bool = false
var _host: WeakRef = null
var _tween: Tween = null
var _opening: bool = false
var _chest_open_sound_played: bool = false
var _reward: Dictionary = {}
var _preview_mode: bool = false
var _active_reward_count: int = 0
var _reward_layout: Dictionary = {}
var _reward_reference: Dictionary = {}
var _count_positions: Dictionary = {}
var _reward_stars: Dictionary = {}
var _reward_sparkle_elapsed: Dictionary = {}
var _collecting: bool = false
var _collection_fade: float = 1.0
var _slots: Dictionary = {}
var _coin_flight_layer: Node2D = null
var _collection_coins: Array[SpineSprite] = []
var _collection_coin_trails: Array[CPUParticles2D] = []

var _collection_coin_haptic: int = 0
var _prop_flight_pool: Array[Sprite2D] = []
var _collection_props: Array[Sprite2D] = []
var _prop_button_impacts: Dictionary = {}
var _borrowed_hud: Array[Dictionary] = []
var _borrowed_coin_safe_top: float = 0.0
var _banner_scale_x: float = 1.0
var _banner_scale_y: float = 1.0
var _banner_y: float = 0.0
var _garden_rotation: float = 0.0
var _garden_timelines: Array[SpineTimeline] = []
var _chest_timelines: Array[SpineTimeline] = []
var _light_timelines: Array[SpineTimeline] = []
var _reward_timelines: Dictionary = {"left": [], "middle": [], "right": []}
var _button_timelines: Array[SpineTimeline] = []
var _swapped_attachments: Dictionary = {}
var _hud_reveal_tween: Tween = null
var _prop_star_pool: Array[CPUParticles2D] = []
@onready var _overlay: ColorRect = $Overlay
@onready var _prop_star_template: CPUParticles2D = $PropFlightLayer / ImpactStars
@onready var _spine: SpineSprite = $Presentation / Spine
@onready var _coin_hud_host: Control = $CoinHudHost
@onready var _prop_bar_host: Control = $PropBarHost
@onready var _coin_flight_root: Node2D = $CoinFlightLayer
@onready var _prop_flight_root: Node2D = $PropFlightLayer
@onready var _flags_material: CanvasItemMaterial = $Presentation / Spine / LeftFlagsLayer.normal_material
@onready var _rewards: Node2D = $Presentation / Rewards
@onready var _reward_effects: Node2D = $Presentation / RewardEffects
@onready var _title: Node2D = $Presentation / Title
@onready var _claim_anchor: Node2D = $Presentation / ClaimAnchor
@onready var _double_anchor: Node2D = $Presentation / DoubleAnchor
@onready var _claim_button: Button = $Presentation / ClaimAnchor / Claim
@onready var _double_button: Button = $Presentation / DoubleAnchor / Double
@onready var _double_appearance: NinePatchRect = $Presentation / DoubleAnchor / Double / Face
@onready var _claim_label: Label = $Presentation / ClaimAnchor / Claim / Label
@onready var _double_label: Label = $Presentation / DoubleAnchor / Double / Content / Row / Label
@onready var _double_row: HBoxContainer = $Presentation / DoubleAnchor / Double / Content / Row
@onready var _ad_icon: TextureRect = $Presentation / DoubleAnchor / Double / Content / Row / AdIcon
@onready var _banner_cloth: ShaderMaterial = $Presentation / Spine / BannerCloth.normal_material
@onready var _title_cloth: ShaderMaterial = $Presentation / Title / Text.material

func _ready() -> void :
	$Presentation / Title / Text.texture = $TitleViewport.get_texture()
	_refresh_localized_text()
	_prop_star_pool.append(_prop_star_template)
	_prop_star_template.finished.connect(_prop_star_template.hide)
	for slot: SpineSlot in _spine.get_skeleton().get_slots():
		_slots[slot.get_data().get_name()] = slot
	_banner_scale_x = (_slots["reward_banner"] as SpineSlot).get_bone().get_scale_x()
	_banner_scale_y = (_slots["reward_banner"] as SpineSlot).get_bone().get_scale_y()
	_banner_y = (_slots["reward_banner"] as SpineSlot).get_bone().get_y()
	_garden_rotation = _spine.get_skeleton().find_bone("garden_pop").get_rotation()
	_cache_presentation_timelines()
	_cache_reveal_timelines()
	_cache_swapped_attachments()
	for kind: String in REWARD_SLOTS:
		_count_positions[kind] = (_rewards.get_node(kind + "/Count") as Label).position
		_reward_stars[kind] = _reward_effects.get_node(kind + "/Stars") as CPUParticles2D
	_spine.before_world_transforms_change.connect(_filter_reward_slots)
	_spine.world_transforms_changed.connect(_sync_presentation)
	_spine.animation_completed.connect(_on_animation_completed)
	RenderingServer.frame_pre_draw.connect(_raise_flag_meshes)
	_layout_presentation()
	_stop_animation()

func _notification(what: int) -> void :
	super._notification(what)
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		_layout_presentation()
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_localized_text()

func _layout_presentation() -> void :
	var insets: Vector2 = UiMetrics.safe_insets()
	var viewport: Vector2 = UiMetrics.viewport_size()
	if not _borrowed_hud.is_empty():
		_coin_hud_host.position.y = insets.x - _borrowed_coin_safe_top
	var layout_scale: float = minf(1.0, (viewport.y - insets.x - insets.y) / UiMetrics.DESIGN.y)
	_spine.scale = Vector2.ONE * layout_scale / SPINE_DESIGN_SCALE
	_spine.position = Vector2(UiMetrics.center_x(), insets.x) + SPINE_DESIGN_ORIGIN * layout_scale
	_layout_reward_effects(layout_scale)
	if visible:
		_sync_presentation(_spine)

func _design_to_global(point: Vector2, layout_scale: float) -> Vector2:
	return Vector2(UiMetrics.center_x(), UiMetrics.safe_insets().x)\
	+ Vector2(point.x - UiMetrics.DESIGN.x * 0.5, point.y) * layout_scale

func _layout_reward_effects(layout_scale: float) -> void :
	var side_halos: Dictionary = {}
	for kind: String in REWARD_SLOTS:
		if not _reward_reference.has(kind):
			continue
		var reference: Dictionary = _reward_reference[kind]
		var target: Transform2D = _spine.global_transform * (reference.transform as Transform2D)
		var multiplier: float = 1.0
		if _reward_layout.has(kind):
			var placement: Dictionary = _reward_layout[kind]
			multiplier = float(placement.scale)
			target.x *= multiplier
			target.y *= multiplier
			target.origin = _design_to_global(placement.icon, layout_scale)
		var inverse: Transform2D = target.affine_inverse()
		var item: Node2D = _rewards.get_node(kind)
		var count: Label = item.get_node("Count")
		count.position = inverse * _design_to_global(_reward_layout[kind].count, layout_scale) - count.size * 0.5\
		if _reward_layout.has(kind) else _count_positions.get(kind, count.position)
		if kind == "rope":
			var icon: Sprite2D = item.get_node("Icon")
			var icon_multiplier: float = multiplier if _active_reward_count == 1 else 1.0
			icon.scale = Vector2.ONE * ROPE_DESIGN_SIZE / icon.texture.get_width()\
			* layout_scale * icon_multiplier / target.get_scale().abs()
		var effect: Node2D = _reward_effects.get_node(kind)
		var halo: Sprite2D = effect.get_node("Halo")
		var halo_center: Vector2 = target.origin + (REWARD_HALO_OFFSETS[kind] as Vector2) * layout_scale * multiplier
		if (kind == "undo" or kind == "hint") and int(_reward.get(kind, 0)) > 0:
			side_halos[kind] = {"halo": halo, "inverse": inverse, "center": halo_center}
		halo.position = inverse * halo_center
		halo.scale = REWARD_HALO_SIZE * multiplier / halo.texture.get_size()\
		* layout_scale / target.get_scale().abs()
		(effect.get_node("Stars") as CPUParticles2D).scale = Vector2.ONE * layout_scale / target.get_scale().abs()
	if side_halos.size() == 2:
		var aligned_y: float = ((side_halos["undo"].center as Vector2).y\
		+ (side_halos["hint"].center as Vector2).y) * 0.5
		for kind: String in side_halos:
			var side_layout: Dictionary = side_halos[kind]
			var center: Vector2 = side_layout.center
			var side_inverse: Transform2D = side_layout.inverse
			center.y = aligned_y
			(side_layout.halo as Sprite2D).position = side_inverse * center

func _apply_reward_layout() -> void :
	var layout_scale: float = _spine.scale.x * SPINE_DESIGN_SCALE
	for kind: String in _reward_layout:
		var placement: Dictionary = _reward_layout[kind]
		var reference: Dictionary = _reward_reference[kind]
		var bone: SpineBone = (_slots[REWARD_SLOTS[kind]] as SpineSlot).get_bone()
		var inverse: Transform2D = bone.get_parent().get_global_transform().affine_inverse()
		var target: Vector2 = inverse * _design_to_global(placement.icon, layout_scale)
		var current: Vector2 = Vector2(bone.get_x(), bone.get_y())
		var travel: Vector2 = (reference.position as Vector2) - (reference.start as Vector2)
		var progress: float = clampf((current - (reference.start as Vector2)).dot(travel) / maxf(travel.length_squared(), 0.0001), 0.0, 1.08)
		var offset: Vector2 = Vector2(target.x, - target.y) - (reference.position as Vector2)
		var adjusted_position: Vector2 = current + offset * progress
		var size_scale: float = lerpf(1.0, float(placement.scale), minf(progress, 1.0))
		bone.set_x(adjusted_position.x)
		bone.set_y(adjusted_position.y)
		bone.set_scale_x(bone.get_scale_x() * size_scale)
		bone.set_scale_y(bone.get_scale_y() * size_scale)

func set_host(host: Node) -> void :
	_host = weakref(host)

func _borrow_hud() -> void :
	var host: Node = _host.get_ref() as Node if _host != null else null
	if host == null:
		return
	var hud: Dictionary = host.get_special_reward_hud_controls()
	_borrowed_coin_safe_top = UiMetrics.safe_insets().x
	_coin_hud_host.position.y = 0.0
	var controls: Array[Control] = [hud["coins"] as Control]
	controls.append_array(hud["props"])
	for control: Control in controls:
		var owners: Array[Dictionary] = []
		var descendants: Array[Node] = [control]
		descendants.append_array(control.find_children("*", "", true, false))
		for descendant: Node in descendants:
			owners.append({"node": descendant, "owner": descendant.owner})
		_borrowed_hud.append({"node": control, "parent": control.get_parent(), "index": control.get_index(), 
			"z_index": control.z_index, "owners": owners})
	for entry: Dictionary in _borrowed_hud:
		var control: Control = entry.node
		control.reparent(_coin_hud_host if control == hud["coins"] else _prop_bar_host)
		control.z_index = 0

func _restore_hud() -> void :
	_borrowed_hud.sort_custom( func(left: Dictionary, right: Dictionary) -> bool: return int(left.index) < int(right.index))
	for entry: Dictionary in _borrowed_hud:
		if not is_instance_valid(entry.node):
			continue
		var control: Control = entry.node
		if not is_instance_valid(entry.parent) or not (entry.parent as Node).is_inside_tree() or (entry.parent as Node).is_queued_for_deletion():
			control.queue_free()
			continue
		control.reparent(entry.parent as Node)
		control.z_index = int(entry.z_index)
		for owned: Dictionary in entry.owners:
			if is_instance_valid(owned.node) and is_instance_valid(owned.owner) and (owned.owner as Node).is_ancestor_of(owned.node):
				(owned.node as Node).owner = owned.owner as Node
	for entry: Dictionary in _borrowed_hud:
		if is_instance_valid(entry.node) and is_instance_valid(entry.parent) and not (entry.node as Node).is_queued_for_deletion():
			(entry.parent as Node).move_child(entry.node as Node, mini(int(entry.index), (entry.parent as Node).get_child_count() - 1))
	_borrowed_hud.clear()

func _raise_flag_meshes() -> void :
	for child: Node in _spine.get_children():
		if child is CanvasItem and (child as CanvasItem).material == _flags_material:
			(child as CanvasItem).z_index = 81

func _exit_tree() -> void :
	_reset_hud_reveal()
	_stop_reward_effects()
	_clear_collection_coins()
	_clear_collection_props()
	_restore_hud()
	_stop_animation()

func _on_show(_params: Dictionary) -> void :
	_preview_mode = false
	if _params.get("host") is Node:
		set_host(_params["host"])
	_generation += 1
	if not is_node_ready():
		await ready
	_refresh_localized_text()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_clear_collection_coins()
	_clear_collection_props()
	_restore_hud()
	_stop_animation()
	_reset_hud_reveal()
	var challenge: Dictionary = UserState.get_special_challenge()
	_instance_id = String(challenge.get("instance_id", ""))
	_reward = challenge.get("reward", {}) as Dictionary
	_claimed = false
	_busy = false
	_opening = true
	_collecting = false
	_collection_fade = 1.0
	_spine.modulate.a = 1.0
	_ready_ad = false
	_prop_bar_host.show()
	visible = true
	_layout_presentation()
	_borrow_hud()
	_refresh_reward()
	_refresh_buttons()
	if not AdManager.reward_ad_loaded.is_connected(_refresh_ad):
		AdManager.reward_ad_loaded.connect(_refresh_ad)
	_refresh_ad()
	AudioManager.play_sfx(&"special_challenge_chest_fly")
	_spine.get_animation_state().set_animation("Appear", false, 0)
	_spine.set_time_scale(1.0)
	_spine.update_skeleton(0.0)
	_raise_flag_meshes()

func play_visual_preview(reward: Dictionary, preview_host: Node = null) -> void :
	_preview_mode = true
	_on_hide()
	_instance_id = ""
	_reward = reward.duplicate(true)
	_busy = false
	_claimed = false
	_opening = true
	_collecting = false
	_collection_fade = 1.0
	_spine.modulate.a = 1.0
	_ready_ad = true
	_refresh_localized_text()
	_refresh_reward()
	_refresh_buttons()
	visible = true
	_layout_presentation()
	if preview_host != null:
		set_host(preview_host)
		_borrow_hud()
	_spine.get_animation_state().set_animation("Appear", false, 0)
	_spine.set_time_scale(1.0)
	_spine.update_skeleton(0.0)
	_raise_flag_meshes()

func stop_visual_preview() -> void :
	if _preview_mode:
		_on_hide()

func can_collect_visual_preview() -> bool:
	return _preview_mode and visible and not _opening and not _busy and not _claimed

func play_visual_preview_collection(before: Dictionary, multiplier: int = 1) -> void :
	if not can_collect_visual_preview() or _host == null or not is_instance_valid(_host.get_ref()):
		return
	var generation: int = _generation
	var reward: Dictionary = _reward.duplicate(true)
	for kind: String in reward:
		reward[kind] = int(reward[kind]) * clampi(multiplier, 1, 2)
	var grant: Dictionary = {"reward": reward, "before": before.duplicate(true)}
	_busy = true
	_begin_hud_reveal()
	_refresh_buttons()
	await fade_presentation(grant)
	if generation != _generation:
		return
	await play_collection(grant)
	if generation != _generation:
		return
	_busy = false
	_claimed = true
	_refresh_buttons()

func _refresh_localized_text() -> void :
	_refresh_title()
	_fit_button_label(_claim_label, _claim_button.size.x - BUTTON_TEXT_MARGIN * 2.0, 
		_claim_button.size.y - 24.0)
	var double_width: float = _double_button.size.x - BUTTON_TEXT_MARGIN * 2.0\
	- _ad_icon.custom_minimum_size.x - float(_double_row.get_theme_constant(&"separation"))
	_fit_button_label(_double_label, double_width, _double_button.size.y - 40.0)


func _fit_button_label(label: Label, max_width: float, max_height: float) -> void :
	var font: Font = label.get_theme_font(&"font")
	var display_text: String = tr(label.text)
	var font_size: int = BUTTON_FONT_SIZE
	var outline: float = 2.0 * float(label.get_theme_constant(&"outline_size"))
	while font_size > 1:
		var line: TextLine = TextLine.new()
		line.add_string(display_text, font, font_size, TranslationServer.get_locale())
		var text_size: Vector2 = line.get_size() + Vector2.ONE * outline
		if text_size.x <= max_width and text_size.y <= max_height:
			break
		font_size -= 1
	label.add_theme_font_size_override(&"font_size", font_size)


func _refresh_title() -> void :
	var label: CurveLabel = $TitleViewport / Label
	label.text = tr("SPECIAL_CHALLENGE_REWARD_TITLE").to_upper()
	label.language = TranslationServer.get_locale()
	var font: Font = label.get_theme_font("font")

	var width: float = clampf(font.get_string_size(label.text, 
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_FONT_SIZE).x + 24.0, 80.0, TITLE_VIEWPORT_SIZE.x - 20.0)
	label.size = Vector2(width, TITLE_VIEWPORT_SIZE.y)
	var font_size: int = TITLE_FONT_SIZE
	var text_server: TextServer = TextServerManager.get_primary_interface()
	while font_size > 1:
		var layout: Dictionary = label._fit_spaced_line(label.text, font, font_size, text_server)
		if not layout.is_empty():
			var bounds: Rect2 = layout.bounds
			if bounds.size.y <= TITLE_VIEWPORT_SIZE.y - 8.0:
				label.position = Vector2((TITLE_VIEWPORT_SIZE.x - width) * 0.5, 
					clampf(0.0, 4.0 - bounds.position.y, TITLE_VIEWPORT_SIZE.y - 4.0 - bounds.end.y))
				break
		font_size -= 1
	label.add_theme_font_size_override(&"font_size", font_size)


func _on_animation_completed(_sprite: SpineSprite, state: SpineAnimationState, entry: SpineTrackEntry) -> void :
	if not visible or not _opening or entry.get_animation().get_name() != "Appear":
		return
	_opening = false
	state.set_animation("flags_idle", true, 1)
	state.set_animation("halo_idle", true, 2)
	_refresh_buttons()

func _stop_animation() -> void :
	if not _preview_mode:
		AudioManager.stop_sfx(&"special_challenge_chest_fly")
		AudioManager.stop_sfx(&"special_challenge_chest_open")
	_chest_open_sound_played = false
	_spine.set_time_scale(0.0)
	_spine.get_animation_state().clear_tracks()
	_spine.get_skeleton().set_to_setup_pose()
	_banner_cloth.set_shader_parameter("elapsed", -1.0)
	_title_cloth.set_shader_parameter("elapsed", -1.0)

func _filter_reward_slots(_sprite: SpineSprite) -> void :
	_pin_flags_to_edges()
	_apply_reward_visual_timing()
	_apply_reward_layout()
	for slot_name: String in _swapped_attachments:
		var slot: SpineSlot = _slots[slot_name]
		if slot.get_attachment() != null:
			slot.set_attachment(_swapped_attachments[slot_name])
	for slot_name: String in ["reward_button_gray", "reward_button_blue", "reward_banner_vine"]:
		(_slots[slot_name] as SpineSlot).set_attachment(null)
	for kind: String in ["hint", "coins", "undo"]:
		if _collecting or int(_reward.get(kind, 0)) <= 0:
			(_slots[REWARD_SLOTS[kind]] as SpineSlot).set_attachment(null)
	for side: String in ["left", "middle", "right"]:
		(_slots["reward_halo_" + side] as SpineSlot).set_attachment(null)
		(_slots["reward_halo_" + side + "_layer_2"] as SpineSlot).set_attachment(null)

func _apply_reward_visual_timing() -> void :
	var state: SpineAnimationState = _spine.get_animation_state()
	var entry: SpineTrackEntry = state.get_current(0)
	if entry == null:
		return
	var appearance_time: float = minf(entry.get_track_time(), entry.get_animation().get_duration())
	_sync_chest_open_sound(appearance_time)
	entry.set_time_scale(1.0 if appearance_time < CHEST_LANDING_TIME else POST_LANDING_SPEED)
	_apply_chest_landing(appearance_time)
	_apply_banner_unfold(appearance_time)
	_apply_reveal_timing(appearance_time)
	var closed_chest: SpineSlot = _slots["baox_3bb"]
	if closed_chest.get_attachment() != null:
		var color: Color = closed_chest.get_color()
		color.a = 1.0
		closed_chest.set_color(color)
	var rays: SpineBone = (_slots["chest_rays"] as SpineSlot).get_bone()
	rays.set_scale_x(rays.get_scale_x() * CHEST_LIGHT_SCALE)
	rays.set_scale_y(rays.get_scale_y() * CHEST_LIGHT_SCALE)

func _sync_chest_open_sound(appearance_time: float) -> void :
	if not _preview_mode and visible and _opening and not _chest_open_sound_played and appearance_time >= CHEST_OPEN_TIME:
		_chest_open_sound_played = true
		AudioManager.play_sfx(&"special_challenge_chest_open")


func _appearance_elapsed(appearance_time: float) -> float:
	return minf(appearance_time, CHEST_LANDING_TIME) + maxf(0.0, appearance_time - CHEST_LANDING_TIME) / POST_LANDING_SPEED

func _cache_reveal_timelines() -> void :
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	var bone_groups: Dictionary = {"chest_rays_1x": "light", "reward_bulb_1x": "left", "reward_coin_1x": "middle", "reward_undo_1x": "right", 
		"reward_halo_left_1x": "left", "reward_halo_middle_1x": "middle", "reward_halo_right_1x": "right", 
		"reward_button_gray_1x": "buttons", "reward_button_blue_1x": "buttons"}
	var slot_groups: Dictionary = {"chest_rays": "light", "chest_inner_glow": "light", "chest_focus_core": "light", "chest_lid_glow": "light", "chest_warm_core": "light", 
		"reward_bulb": "left", "reward_coin": "middle", "reward_undo": "right", "reward_button_gray": "buttons", "reward_button_blue": "buttons"}
	for side: String in _reward_timelines:
		slot_groups["reward_halo_" + side] = side
		slot_groups["reward_halo_" + side + "_layer_2"] = side
	var bone_indices: Dictionary = {}
	var slot_indices: Dictionary = {}
	for bone_name: String in bone_groups:
		bone_indices[skeleton.find_bone(bone_name).get_data().get_index()] = bone_groups[bone_name]
	for slot_name: String in slot_groups:
		slot_indices[(_slots[slot_name] as SpineSlot).get_data().get_index()] = slot_groups[slot_name]
	for timeline: SpineTimeline in _spine.skeleton_data_res.find_animation("Appear").get_timelines():
		var index: int = int(timeline.get_property_ids()[0]) & 4294967295
		var group: String = ""
		if timeline.get_type() in ["RotateTimeline", "TranslateTimeline", "ScaleTimeline"]:
			group = String(bone_indices.get(index, ""))
		elif timeline.get_type() in ["AttachmentTimeline", "RGBATimeline"]:
			group = String(slot_indices.get(index, ""))
		if group == "light":
			_light_timelines.append(timeline)
		elif group == "buttons":
			_button_timelines.append(timeline)
		elif _reward_timelines.has(group):
			(_reward_timelines[group] as Array).append(timeline)

func _cache_swapped_attachments() -> void :
	var state: SpineAnimationState = _spine.get_animation_state()
	var entry: SpineTrackEntry = state.set_animation("Appear", false, 0)
	state.apply(_spine.get_skeleton())
	_apply_reveal_timing(0.0)
	var starts: Dictionary = {}
	for kind: String in REWARD_SLOTS:
		var bone: SpineBone = (_slots[REWARD_SLOTS[kind]] as SpineSlot).get_bone()
		starts[kind] = Vector2(bone.get_x(), bone.get_y())
	entry.set_track_time(entry.get_animation().get_duration())
	state.apply(_spine.get_skeleton())
	_apply_reveal_timing(entry.get_animation().get_duration())
	_spine.get_skeleton().update_world_transform(SpineConstant.Physics_Update)
	for kind: String in REWARD_SLOTS:
		var bone: SpineBone = (_slots[REWARD_SLOTS[kind]] as SpineSlot).get_bone()
		_reward_reference[kind] = {"position": Vector2(bone.get_x(), bone.get_y()), "start": starts[kind], 
			"transform": Transform2D(deg_to_rad(bone.get_world_rotation_x()), 
				Vector2(bone.get_world_scale_x(), bone.get_world_scale_y()), 0.0, 
				Vector2(bone.get_world_x(), bone.get_world_y()))}
	var pairs: Dictionary = {"reward_bulb": "reward_undo", "reward_undo": "reward_bulb"}
	for slot_name: String in pairs:
		_swapped_attachments[slot_name] = (_slots[pairs[slot_name]] as SpineSlot).get_attachment()
	state.clear_tracks()
	_spine.get_skeleton().set_to_setup_pose()

func _apply_reveal_timing(appearance_time: float) -> void :
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	var light_time: float = minf(appearance_time, CHEST_LIGHT_BEGIN) + maxf(0.0, appearance_time - CHEST_LIGHT_BEGIN) * CHEST_LIGHT_SPEED
	for timeline: SpineTimeline in _light_timelines:
		timeline.apply(skeleton, -1.0, light_time, [], 1.0, SpineConstant.MixBlend_Setup, SpineConstant.MixDirection_In)
	for side: String in _reward_timelines:
		var reveal_begin: float = float(REWARD_REVEAL_TIMES["left"] if _active_reward_count > 1 else REWARD_REVEAL_TIMES[side])
		var elapsed: float = appearance_time - reveal_begin
		var reward_time: float = maxf(0.0, float(REWARD_HALO_START_TIMES[side]) + elapsed / REWARD_REVEAL_STRETCH)
		for timeline: SpineTimeline in _reward_timelines[side]:
			timeline.apply(skeleton, -1.0, reward_time, [], 1.0, SpineConstant.MixBlend_Setup, SpineConstant.MixDirection_In)
		var slot_name: String = "reward_bulb" if side == "left" else ("reward_coin" if side == "middle" else "reward_undo")
		var slot: SpineSlot = _slots[slot_name]
		var color: Color = slot.get_color()
		color.a *= smoothstep(0.0, REWARD_REVEAL_FADE, elapsed)
		slot.set_color(color)
	var button_time: float = maxf(0.0, BUTTON_SOURCE_TIME + appearance_time - BUTTON_REVEAL_TIME)
	for timeline: SpineTimeline in _button_timelines:
		timeline.apply(skeleton, -1.0, button_time, [], 1.0, SpineConstant.MixBlend_Setup, SpineConstant.MixDirection_In)

func _apply_banner_unfold(appearance_time: float) -> void :
	var elapsed: float = appearance_time - BANNER_STRETCH_BEGIN
	var banner: SpineBone = (_slots["reward_banner"] as SpineSlot).get_bone()
	banner.set_scale_x(_banner_scale_x)
	banner.set_scale_y(_banner_scale_y)
	banner.set_y(_banner_y)
	_banner_cloth.set_shader_parameter("elapsed", elapsed)
	_title_cloth.set_shader_parameter("elapsed", elapsed)
	for slot_name: String in ["reward_banner", "reward_banner_vine"]:
		var slot: SpineSlot = _slots[slot_name]
		var color: Color = slot.get_color()
		color.a = smoothstep(0.0, BANNER_FADE_DURATION, elapsed)
		slot.set_color(color)

func _cache_presentation_timelines() -> void :
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	var garden_bone_index: int = skeleton.find_bone("garden_pop").get_data().get_index()
	var garden_slot_index: int = (_slots["garden_chest"] as SpineSlot).get_data().get_index()
	var chest_bone_index: int = skeleton.find_bone("front_chest_1x").get_data().get_index()
	for timeline: SpineTimeline in _spine.skeleton_data_res.find_animation("Appear").get_timelines():
		var index: int = int(timeline.get_property_ids()[0]) & 4294967295
		var kind: String = timeline.get_type()
		if (index == garden_bone_index and kind == "ScaleTimeline") or (index == garden_slot_index and kind in ["AttachmentTimeline", "RGBATimeline"]):
			_garden_timelines.append(timeline)
		elif index == chest_bone_index and kind in ["RotateTimeline", "TranslateTimeline", "ScaleTimeline"]:
			_chest_timelines.append(timeline)

func _apply_chest_landing(appearance_time: float) -> void :
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	for timeline: SpineTimeline in _garden_timelines:
		timeline.apply(skeleton, -1.0, appearance_time + GARDEN_ADVANCE, [], 1.0, SpineConstant.MixBlend_Setup, SpineConstant.MixDirection_In)
	_apply_garden_landing(appearance_time)
	if appearance_time < CHEST_LANDING_TIME or appearance_time >= 27.0 / 30.0:
		return
	var progress: float = clampf((appearance_time - CHEST_LANDING_TIME) / (CHEST_OPEN_TIME - CHEST_LANDING_TIME), 0.0, 1.0)
	var eased: float = progress - CHEST_SHAKE_EASE * sin(progress * TAU)
	var shake_time: float = CHEST_LANDING_TIME + (CHEST_OPEN_TIME - CHEST_LANDING_TIME) * CHEST_SHAKE_SPEED * eased
	var fade: float = clampf((appearance_time - CHEST_OPEN_TIME) / (27.0 / 30.0 - CHEST_OPEN_TIME), 0.0, 1.0)
	var weight: float = 1.0 - fade * fade * fade * (fade * (fade * 6.0 - 15.0) + 10.0)
	for timeline: SpineTimeline in _chest_timelines:
		timeline.apply(skeleton, -1.0, shake_time, [], weight, SpineConstant.MixBlend_Replace, SpineConstant.MixDirection_In)

func _apply_garden_landing(appearance_time: float) -> void :
	var elapsed: float = appearance_time - CHEST_LANDING_TIME
	var sway: float = 0.0
	if elapsed > 0.0 and elapsed < GARDEN_SHAKE_DURATION:
		sway = sin(elapsed * TAU * 3.0) * exp( - elapsed * 7.5) * (1.0 - smoothstep(0.4, GARDEN_SHAKE_DURATION, elapsed))
	var garden: SpineBone = _spine.get_skeleton().find_bone("garden_pop")
	garden.set_rotation(_garden_rotation + sway * 0.65)
	garden.set_scale_x(garden.get_scale_x() * (1.0 + sway * 0.012))
	garden.set_scale_y(garden.get_scale_y() * (1.0 - sway * 0.02))

func _pin_flags_to_edges() -> void :
	var viewport: Vector2 = UiMetrics.viewport_size()
	var layout_scale: float = _spine.scale.x * SPINE_DESIGN_SCALE
	var inverse: Transform2D = _spine.global_transform.affine_inverse()
	var skeleton: SpineSkeleton = _spine.get_skeleton()
	for side: String in ["left", "right"]:
		var half_width: float = (219.0 if side == "left" else 219.5) * layout_scale
		var center: Vector2 = Vector2(half_width if side == "left" else viewport.x - half_width, 119.0 * layout_scale)
		var local: Vector2 = inverse * center
		var bone: SpineBone = skeleton.find_bone("celebration_flags_" + side + "_1x")
		bone.set_x(local.x)
		bone.set_y( - local.y)

func _sync_presentation(_sprite: SpineSprite) -> void :
	_raise_flag_meshes()
	var banner: SpineBone = (_slots["reward_banner"] as SpineSlot).get_bone()
	_banner_cloth.set_shader_parameter("cloth_origin", Vector2(banner.get_world_x(), banner.get_world_y()))
	_banner_cloth.set_shader_parameter("cloth_scale", Vector2(banner.get_world_scale_x(), banner.get_world_scale_y()).abs())
	for kind: String in REWARD_SLOTS:
		var item: Node2D = _rewards.get_node(kind)
		if not item.visible or _collecting:
			continue
		var slot: SpineSlot = _slots[REWARD_SLOTS[kind]]
		item.global_transform = slot.get_bone().get_global_transform()
		item.modulate.a = slot.get_color().a
		_sync_reward_effect(kind, item)
	for anchor: Node2D in [_title, _claim_anchor, _double_anchor]:
		var slot_name: String = "reward_banner" if anchor == _title else ("reward_button_blue" if anchor == _claim_anchor else "reward_button_gray")
		var slot: SpineSlot = _slots[slot_name]
		anchor.global_transform = slot.get_bone().get_global_transform()
		anchor.modulate.a = slot.get_color().a * _collection_fade

func _refresh_reward() -> void :
	_stop_reward_effects()
	_reward_effects.modulate.a = 1.0
	_reward_layout.clear()
	var active: Array[String] = []
	for kind: String in REWARD_SLOTS:
		if int(_reward.get(kind, 0)) > 0:
			active.append(kind)
	_active_reward_count = active.size()
	if active.size() == 1:
		_reward_layout[active[0]] = SINGLE_REWARD_LAYOUT.duplicate(true)
		if active[0] == "rope":
			_reward_layout[active[0]].icon = SINGLE_ROPE_REWARD_POSITION
	elif active.size() == 2 and active.has("hint") and active.has("undo"):
		_reward_layout = DOUBLE_REWARD_LAYOUT.duplicate(true)
	for kind: String in REWARD_SLOTS:
		var item: Node2D = _rewards.get_node(kind)
		item.visible = int(_reward.get(kind, 0)) > 0
		item.get_node("Count").text = str(_reward.get(kind, 0))
		item.get_node("Icon").visible = kind == "rope"
		item.scale = Vector2.ONE
		item.modulate.a = 1.0
	_layout_reward_effects(_spine.scale.x * SPINE_DESIGN_SCALE)

func _process(delta: float) -> void :
	for kind: String in _reward_sparkle_elapsed:
		var stars: CPUParticles2D = _reward_stars[kind]
		if not stars.emitting:
			continue
		var elapsed: float = minf(float(_reward_sparkle_elapsed[kind]) + delta, REWARD_SPARKLE_SETTLE_DURATION)
		_reward_sparkle_elapsed[kind] = elapsed
		stars.speed_scale = lerpf(1.0, REWARD_SPARKLE_SETTLED_SPEED, 
			smoothstep(0.0, REWARD_SPARKLE_SETTLE_DURATION, elapsed))

func _sync_reward_effect(kind: String, item: Node2D) -> void :
	var effect: Node2D = _reward_effects.get_node(kind)
	var stars: CPUParticles2D = _reward_stars[kind]
	var showing: bool = item.modulate.a > 0.001
	if showing and not effect.visible:
		_reward_sparkle_elapsed[kind] = 0.0
		stars.speed_scale = 1.0
		stars.restart()
	elif not showing:
		stars.emitting = false
		_reward_sparkle_elapsed.erase(kind)
	effect.visible = showing
	effect.global_transform = item.global_transform
	effect.modulate.a = item.modulate.a
	var state: SpineAnimationState = _spine.get_animation_state()
	var entry: SpineTrackEntry = state.get_current(0)
	var elapsed: float = _appearance_elapsed(minf(entry.get_track_time(), entry.get_animation().get_duration())) if entry != null else 0.0
	var idle: SpineTrackEntry = state.get_current(2)
	if idle != null:
		elapsed += idle.get_track_time()
	(effect.get_node("Halo") as Sprite2D).rotation = deg_to_rad(elapsed * REWARD_HALO_SPIN * REWARD_HALO_SPEED_SCALE)

func _stop_reward_effects() -> void :
	_reward_sparkle_elapsed.clear()
	for effect: Node2D in _reward_effects.get_children():
		(effect.get_node("Stars") as CPUParticles2D).emitting = false
		effect.hide()

func _refresh_buttons() -> void :
	_claim_button.disabled = _preview_mode or _busy or _opening or _claimed
	CommonBtn.apply_disabled_gray(_double_appearance, not _ready_ad)
	CommonBtn.apply_disabled_gray(_double_label, not _ready_ad)
	CommonBtn.apply_disabled_gray(_ad_icon, not _ready_ad)
	_double_button.disabled = _preview_mode or _busy or _opening or _claimed

func _refresh_ad() -> void :
	if _preview_mode or not visible:
		return
	if _querying:
		_query_again = true
		return
	_querying = true
	var generation: int = _generation
	while true:
		_query_again = false
		var ready_ad: bool = await AdManager.check_reward_ads_available("special_challenge")
		if generation == _generation and visible and not _claimed:
			_ready_ad = ready_ad
			_refresh_buttons()
		if not _query_again or generation != _generation:
			break
	_querying = false
	if generation != _generation and visible:
		_refresh_ad()

func _on_claim_pressed() -> void :
	_claim(1)

func _on_double_pressed() -> void :
	if _preview_mode:
		return
	if not _ready_ad:
		SceneManager.show_toast(tr("JUICE_PROP_AD_NOT_READY_TOAST"))
		return
	_claim(2)

func _claim(multiplier: int) -> void :
	if _preview_mode or _busy or _opening or _claimed:
		return
	_busy = true
	_refresh_buttons()
	var generation: int = _generation
	var grant: Dictionary = await SpecialChallengeClaimFlow.run(self, generation, _instance_id, multiplier)
	if generation != _generation or not visible:
		return
	_busy = false
	if not grant.is_empty():
		_claimed = true
	else:
		_ready_ad = false
		SceneManager.show_toast(tr("JUICE_PROP_AD_NOT_READY_TOAST") if multiplier == 2 else tr("HOME_NETWORK_ERROR"))
		_refresh_ad()
	_refresh_buttons()

func is_claim_current(generation: int) -> bool:
	return not _preview_mode and generation == _generation and visible and not _claimed

func was_claimed() -> bool:
	return _claimed

func _reset_hud_reveal() -> void :
	if _hud_reveal_tween != null and _hud_reveal_tween.is_valid():
		_hud_reveal_tween.kill()
	_hud_reveal_tween = null
	for host: Control in [_coin_hud_host, _prop_bar_host]:
		host.z_index = -3
		host.modulate = Color.WHITE

func _begin_hud_reveal() -> void :
	if _coin_hud_host.z_index >= 0:
		return
	var darkness: float = 1.0 - _overlay.color.a * _overlay.modulate.a
	_coin_hud_host.z_index = 90
	_prop_bar_host.z_index = 1
	_hud_reveal_tween = create_tween().set_parallel(true)
	for host: Control in [_coin_hud_host, _prop_bar_host]:
		host.modulate = Color(darkness, darkness, darkness, 1.0)
		_hud_reveal_tween.tween_property(host, "modulate", Color.WHITE, HUD_REVEAL_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_collection_fade(amount: float) -> void :
	_collection_fade = amount
	_spine.modulate.a = amount
	_reward_effects.modulate.a = amount
	if amount <= 0.0:
		_stop_reward_effects()
	_sync_presentation(_spine)

func fade_presentation(grant: Dictionary) -> void :
	var generation: int = _generation
	_begin_hud_reveal()
	_collecting = true
	for kind: String in REWARD_SLOTS:
		var item: Node2D = _rewards.get_node(kind)
		item.get_node("Count").text = str(grant.reward.get(kind, 0))
		item.get_node("Icon").visible = true
	_filter_reward_slots(_spine)
	_tween = create_tween()
	_tween.tween_method(_set_collection_fade, 1.0, 0.0, COLLECTION_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	while generation == _generation and _tween != null and _tween.is_running():
		await get_tree().process_frame
	if generation == _generation:
		_tween = null
		_set_collection_fade(0.0)

func play_collection(grant: Dictionary) -> void :
	var host: Node = _host.get_ref() as Node if _host != null else null
	if host == null:
		return
	var generation: int = _generation
	_collecting = true
	_prop_bar_host.show()
	_filter_reward_slots(_spine)
	_tween = create_tween().set_parallel(true)
	for kind: String in REWARD_SLOTS:
		if int(grant.reward.get(kind, 0)) <= 0:
			continue
		var item: Node2D = _rewards.get_node(kind)
		item.get_node("Count").text = str(grant.reward.get(kind, 0))
		if kind == "coins":
			item.get_node("Icon").visible = false
			_coin_flight_layer = _coin_flight_root
			_coin_flight_layer.show()
			host.append_special_challenge_coin_reward(_tween, item.global_position, 
				int(grant.before.coins), int(grant.before.coins) + int(grant.reward.coins), _coin_flight_layer, 
				_collection_coins, _collection_coin_trails)

			if not _preview_mode:
				HapticManager.cancel_event(_collection_coin_haptic)
				_collection_coin_haptic = host.play_finish_coin_haptic()
			_tween.tween_property(item, "modulate:a", 0.0, 0.6)
			continue
		var group_delay: float = 0.0
		if kind == "hint" and int(grant.reward.get("undo", 0)) > 0:
			group_delay = float(int(grant.reward.undo) - 1) * PROP_FLIGHT_STAGGER + PROP_GROUP_STAGGER
		_append_prop_collection(kind, item, int(grant.reward[kind]), int(grant.before.get(kind, 0)), host, group_delay)
	while generation == _generation and ((_tween != null and _tween.is_running()) or _prop_impacts_running()):
		await get_tree().process_frame
	if generation == _generation:
		_tween = null
		_clear_collection_coins(false)
		_clear_collection_props()
		if is_instance_valid(host):
			host.refresh_economy_ui()

func _find_reward_prop_button(kind: String) -> PropBtn:
	for entry: Dictionary in _borrowed_hud:
		var control: Node = entry.node
		if is_instance_valid(control) and control is PropBtn and (control as PropBtn).get_prop_id() == kind:
			return control as PropBtn
	return null

func _acquire_prop_flight() -> Sprite2D:
	for sprite: Sprite2D in _prop_flight_pool:
		if not sprite.visible:
			sprite.show()
			_collection_props.append(sprite)
			return sprite
	var sprite: Sprite2D = Sprite2D.new()
	_prop_flight_root.add_child(sprite)
	_prop_flight_pool.append(sprite)
	_collection_props.append(sprite)
	return sprite

func _append_prop_collection(kind: String, item: Node2D, count: int, before: int, host: Node, group_delay: float = 0.0) -> void :
	var icon: Sprite2D = item.get_node("Icon") as Sprite2D
	var button: PropBtn = _find_reward_prop_button(kind)
	var dst: Vector2 = host.get_special_reward_target(kind)
	var layout_scale: float = _spine.scale.x * SPINE_DESIGN_SCALE
	var bend: Vector2 = Vector2(-100.0 if kind == "hint" else 100.0, -70.0) * layout_scale
	if is_instance_valid(button):
		_prop_button_impacts[kind] = {"button": button, "scale": button.scale, "last_scale": button.scale, "tween": null}
	_prop_flight_root.show()
	var split_scale: Vector2 = icon.global_scale * (0.78 if count > 1 else 1.0)
	var spacing: float = icon.texture.get_width() * absf(split_scale.x) * 1.08
	var half_width: float = (float(count - 1) * spacing + icon.texture.get_width() * absf(split_scale.x)) * 0.5
	var margin: float = 12.0 * layout_scale
	var center_x: float = clampf(icon.global_position.x, half_width + margin, UiMetrics.viewport_size().x - half_width - margin)
	for index: int in count:
		var sprite: Sprite2D = _acquire_prop_flight()
		sprite.texture = icon.texture
		sprite.global_transform = icon.global_transform
		sprite.modulate = Color.WHITE
		sprite.self_modulate = Color.WHITE
		var offset: float = float(index) - float(count - 1) * 0.5
		var split: Vector2 = Vector2(center_x + offset * spacing, icon.global_position.y - (28.0 + absf(offset) * 12.0) * layout_scale)
		var delay: float = PROP_SPLIT_DURATION + 0.05 + group_delay + float(index) * PROP_FLIGHT_STAGGER
		_tween.tween_property(sprite, "global_position", split, PROP_SPLIT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(sprite, "global_scale", split_scale, PROP_SPLIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_prop_flight_progress.bind(sprite, split, split_scale, button, dst, bend), 
			0.0, 1.0, PROP_FLIGHT_DURATION).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_tween.tween_callback(_on_prop_arrived.bind(sprite, kind, before + index + 1)).set_delay(delay + PROP_FLIGHT_DURATION)
	_tween.tween_property(item, "modulate:a", 0.0, 0.08)

func _set_prop_flight_progress(amount: float, sprite: Sprite2D, start: Vector2, initial_scale: Vector2, 
		button: PropBtn, fallback: Vector2, bend: Vector2) -> void :
	if not is_instance_valid(sprite):
		return
	var dst: Vector2 = fallback
	var dst_scale: Vector2 = initial_scale * 0.5
	if is_instance_valid(button):
		var rect: Rect2 = button.get_reward_collect_global_rect()
		dst = rect.get_center()
		var fit: float = minf(rect.size.x / sprite.texture.get_width(), rect.size.y / sprite.texture.get_height())
		dst_scale = Vector2.ONE * fit
	var control: Vector2 = (start + dst) * 0.5 + bend
	sprite.global_position = start.lerp(control, amount).lerp(control.lerp(dst, amount), amount)
	sprite.global_scale = initial_scale.lerp(dst_scale, smoothstep(0.3, 1.0, amount))
	sprite.modulate.a = 1.0 - smoothstep(0.92, 1.0, amount)

func _on_prop_arrived(sprite: Sprite2D, kind: String, displayed_count: int) -> void :
	if is_instance_valid(sprite):
		sprite.hide()
	var impact: Dictionary = _prop_button_impacts.get(kind, {})
	if impact.is_empty() or not is_instance_valid(impact.button):
		return
	var button: PropBtn = impact.button
	button.set_reward_count_display(displayed_count)
	AudioManager.play_sfx(&"prop_reward_arrive")
	_emit_prop_impact_stars(button)
	var previous: Tween = impact.tween
	impact.tween = null
	if previous != null and previous.is_valid():
		previous.kill()
	if not button.scale.is_equal_approx(impact.last_scale):
		return
	var base: Vector2 = impact.scale
	var punch: Tween = create_tween()
	impact.tween = punch
	punch.tween_method(_set_prop_impact_scale.bind(impact), button.scale, base * Vector2(1.15, 0.88), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	punch.tween_method(_set_prop_impact_scale.bind(impact), base * Vector2(1.15, 0.88), base * Vector2(0.95, 1.08), 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	punch.tween_method(_set_prop_impact_scale.bind(impact), base * Vector2(0.95, 1.08), base, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_prop_impact_scale(value: Vector2, impact: Dictionary) -> void :
	var button: PropBtn = impact.button
	if not is_instance_valid(button) or not button.scale.is_equal_approx(impact.last_scale):
		var punch: Tween = impact.tween
		impact.tween = null
		if punch != null and punch.is_valid():
			punch.kill()
		return
	button.scale = value
	impact.last_scale = value

func _emit_prop_impact_stars(button: PropBtn) -> void :
	var stars: CPUParticles2D = null
	for candidate: CPUParticles2D in _prop_star_pool:
		if not candidate.visible:
			stars = candidate
			break
	if stars == null:
		stars = _prop_star_template.duplicate(0) as CPUParticles2D
		stars.emitting = false
		stars.finished.connect(stars.hide)
		_prop_flight_root.add_child(stars)
		_prop_star_pool.append(stars)
	var frame: TextureRect = button.get_node("Bg") as TextureRect
	var bounds: Rect2 = Rect2(PROP_FRAME_BOUNDS.position * frame.size, PROP_FRAME_BOUNDS.size * frame.size)
	stars.global_position = frame.get_global_transform() * bounds.get_center()
	stars.scale = Vector2.ONE * _spine.scale.x * SPINE_DESIGN_SCALE
	var half_size: Vector2 = bounds.size * 0.5
	var radius: float = minf(half_size.x, half_size.y) * 0.48
	var inner: Vector2 = half_size - Vector2.ONE * radius
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in 32:
		var ray: Vector2 = Vector2.from_angle(float(index) * TAU / 32.0)
		var distance: float = minf(half_size.x / maxf(absf(ray.x), 0.0001), half_size.y / maxf(absf(ray.y), 0.0001))
		var point: Vector2 = ray * distance
		if absf(point.x) > inner.x and absf(point.y) > inner.y:
			var corner: Vector2 = Vector2(signf(ray.x) * inner.x, signf(ray.y) * inner.y)
			var projection: float = ray.dot(corner)
			distance = projection + sqrt(maxf(0.0, projection * projection - corner.length_squared() + radius * radius))
			point = ray * distance
		var world_point: Vector2 = frame.get_global_transform() * (bounds.get_center() + point)
		points.append(stars.to_local(world_point))
	stars.emission_points = points
	stars.show()
	stars.restart()

func _prop_impacts_running() -> bool:
	for stars: CPUParticles2D in _prop_star_pool:
		if stars.visible:
			return true
	for impact: Dictionary in _prop_button_impacts.values():
		var punch: Tween = impact.tween
		if punch != null and punch.is_valid() and punch.is_running():
			return true
	return false

func _clear_collection_props() -> void :
	for stars: CPUParticles2D in _prop_star_pool:
		stars.emitting = false
		stars.hide()
	for impact: Dictionary in _prop_button_impacts.values():
		var punch: Tween = impact.tween
		impact.tween = null
		if punch != null and punch.is_valid():
			punch.kill()
		if is_instance_valid(impact.button) and (impact.button as PropBtn).scale.is_equal_approx(impact.last_scale):
			(impact.button as PropBtn).scale = impact.scale
	_prop_button_impacts.clear()
	for sprite: Sprite2D in _collection_props:
		if is_instance_valid(sprite):
			sprite.hide()
	_collection_props.clear()
	if is_instance_valid(_prop_flight_root):
		_prop_flight_root.hide()

func _clear_collection_coins(cancel_haptic: bool = true) -> void :

	if cancel_haptic:
		HapticManager.cancel_event(_collection_coin_haptic)
		_collection_coin_haptic = 0
	if is_instance_valid(_coin_flight_layer):
		_coin_flight_layer.hide()
		for child: Node in _coin_flight_layer.get_children():
			child.queue_free()
	_coin_flight_layer = null
	_collection_coins.clear()
	_collection_coin_trails.clear()

func _on_back_request() -> void :

	return

func _on_hide() -> void :
	_generation += 1
	_stop_reward_effects()
	_reset_hud_reveal()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	var had_coin_flight: bool = is_instance_valid(_coin_flight_layer)
	_clear_collection_coins()
	_clear_collection_props()
	var host: Node = _host.get_ref() as Node if _host != null else null
	if (had_coin_flight or _collecting) and is_instance_valid(host):
		host.refresh_economy_ui()
	_restore_hud()
	_stop_animation()
	visible = false
	_host = null
	if AdManager.reward_ad_loaded.is_connected(_refresh_ad):
		AdManager.reward_ad_loaded.disconnect(_refresh_ad)
