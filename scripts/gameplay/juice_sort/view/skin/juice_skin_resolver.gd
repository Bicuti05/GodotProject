class_name JuiceSkinResolver
extends RefCounted

const COLOR_FIELDS: PackedStringArray = [
	"element", "empty_container", "completed_container", "target_icon", "lock_icon", 
	"rope_top", "rope_mid", "rope_bottom", 
]

static func resolve_page_theme(pack: JuiceSkinDefinition) -> JuiceSkinPageTheme:
	return pack.page_theme if pack != null else null

const SINGLE_FIELDS: PackedStringArray = [
	"target_empty_icon", "parking_container", "parking_rope_top", 
	"parking_rope_mid", "parking_rope_bottom", "mystery_element", 
	"guide_connect_same_color", "guide_collect_by_color", "guide_use_empty_ropes", "guide_target_empty_icon", 
]
var default_skin: JuiceSkinDefinition
var active_skin: JuiceSkinDefinition
var rank_collectible_color: StringName = &""
var rank_collectible_index: int = -1
var _default_colors: Dictionary[StringName, JuiceSkinColorAssets] = {}
var _active_colors: Dictionary[StringName, JuiceSkinColorAssets] = {}

func _init(base: JuiceSkinDefinition, selected: JuiceSkinDefinition) -> void :
	default_skin = base
	active_skin = selected
	for color: JuiceSkinColorAssets in base.colors:
		_default_colors[color.color_key] = color
	for color: JuiceSkinColorAssets in selected.colors:
		_active_colors[color.color_key] = color

func color_visual(key: StringName, field: StringName) -> JuiceSkinVisual:
	if key == rank_collectible_color and rank_collectible_index >= 0:
		var replacement: JuiceSkinVisual = rank_collectible_visual(field)
		if replacement != null:
			return replacement
	return original_color_visual(key, field)


func original_color_visual(key: StringName, field: StringName) -> JuiceSkinVisual:
	var selected: JuiceSkinColorAssets = _active_colors.get(key)
	if selected != null and active_skin != default_skin:
		var visual: JuiceSkinVisual = selected.get(field)
		if visual != null:
			return visual
	var base: JuiceSkinColorAssets = _default_colors.get(key)
	if base == null:
		return null
	return base.get(field) as JuiceSkinVisual

func set_rank_collectible(color: StringName, index: int) -> void :
	rank_collectible_color = color
	rank_collectible_index = index if index >= 0 and index < default_skin.rank_collectible_elements.size() else -1

func rank_collectible_visual(field: StringName) -> JuiceSkinVisual:
	if rank_collectible_index < 0:
		return null
	if field == &"rope_top" or field == &"rope_mid" or field == &"rope_bottom":
		var ribbon: JuiceSkinDefinition = rank_collectible_rope_skin()
		if ribbon == null:
			return null
		match field:
			&"rope_top": return ribbon.rank_collectible_rope_top
			&"rope_mid": return ribbon.rank_collectible_rope_mid
			&"rope_bottom": return ribbon.rank_collectible_rope_bottom
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		if field == &"element" and rank_collectible_index < pack.rank_collectible_elements.size():
			var visual: JuiceSkinVisual = pack.rank_collectible_elements[rank_collectible_index]
			if visual != null:
				return visual
		elif field == &"empty_container" and pack.rank_collectible_container != null:
			return pack.rank_collectible_container
		elif field in [&"completed_container", &"target_icon", &"lock_icon"]:
			if rank_collectible_index < pack.rank_collectible_targets.size():
				var visual: JuiceSkinVisual = pack.rank_collectible_targets[rank_collectible_index]
				if visual != null:
					return visual
			if pack.rank_collectible_target != null:
				return pack.rank_collectible_target
	return null


func rank_collectible_rope_skin() -> JuiceSkinDefinition:
	if rank_collectible_index < 0:
		return null
	if active_skin.rank_collectible_rope_top != null and active_skin.rank_collectible_rope_mid != null\
	and active_skin.rank_collectible_rope_bottom != null:
		return active_skin
	if default_skin.rank_collectible_rope_top != null and default_skin.rank_collectible_rope_mid != null\
	and default_skin.rank_collectible_rope_bottom != null:
		return default_skin
	return null

func color_texture(key: StringName, field: StringName) -> Texture2D:
	var selected: JuiceSkinColorAssets = _active_colors.get(key)
	var texture: Texture2D = selected.get(field) if selected != null else null
	if texture != null:
		return texture
	var base: JuiceSkinColorAssets = _default_colors.get(key)
	return base.get(field) as Texture2D if base != null else null

func single_visual(field: StringName) -> JuiceSkinVisual:
	if active_skin != default_skin:
		var visual: JuiceSkinVisual = active_skin.get(field)
		if visual != null:
			return visual
	return default_skin.get(field) as JuiceSkinVisual

func target_bar_max_visible_count() -> int:
	return active_skin.target_bar_max_visible_count if active_skin.target_bar_max_visible_count > 0\
	else default_skin.target_bar_max_visible_count

func rank_collectible_target_height_ratio() -> float:
	return active_skin.rank_collectible_target_height_ratio if active_skin.rank_collectible_target_height_ratio > 0.0\
	else default_skin.rank_collectible_target_height_ratio

func animation() -> JuiceSkinAnimationAssets:
	return active_skin.collect_animation if active_skin.collect_animation != null else default_skin.collect_animation

func effect_texture(field: StringName, fallback: Texture2D = null) -> Texture2D:
	var selected: Texture2D = active_skin.effects.get(field) if active_skin.effects != null else null
	if selected != null:
		return selected
	var base: Texture2D = default_skin.effects.get(field) if default_skin.effects != null else null
	return base if base != null else fallback


func warmup_asset_paths(group: String) -> PackedStringArray:
	var fields: PackedStringArray = []
	match group:
		"ice_unlock": fields = ["unlock_leaf", "unlock_glow"]
		"connection": fields = ["rope_petal", "rope_star"]
		"mystery_reveal": fields = ["mystery_petal", "mystery_glow", "mystery_flash", "mystery_star"]
	var paths: PackedStringArray = []
	for field: String in fields:
		paths.append(_warmup_resource_path(effect_texture(StringName(field))))
	if group == "mystery_reveal":
		for slot: int in JuiceTheme.COLOR_KEYS.size():
			paths.append(_warmup_resource_path(mystery_particle_texture(slot)))
	return paths

func _warmup_resource_path(resource: Resource) -> String:
	return resource.resource_path if resource != null else "-"


func collection_particle_texture(slot: int) -> Texture2D:
	if slot < 0 or slot >= JuiceTheme.COLOR_KEYS.size():
		return null
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		if pack.effects != null and slot < pack.effects.collection_particles.size():
			if pack.effects.collection_particles[slot] != null:
				return pack.effects.collection_particles[slot]
	return null


func collection_particle_size_correction(texture: Texture2D, for_connection: bool = false) -> float:
	if texture != null:
		for pack: JuiceSkinDefinition in [active_skin, default_skin]:
			if pack.effects != null and pack.effects.collection_particles.has(texture):
				if for_connection and pack.effects.connection_particle_size_correction > 0.0:
					return pack.effects.connection_particle_size_correction
				return pack.effects.collection_particle_size_correction
	return 1.0


func rank_collectible_particle_size(texture: Texture2D, for_connection: bool = false) -> Vector2:
	if texture != null:
		for pack: JuiceSkinDefinition in [active_skin, default_skin]:
			if pack.effects == null:
				continue
			if texture in [pack.effects.rank_collectible_connection_01, pack.effects.rank_collectible_connection_02]:
				var width_range: Vector2 = pack.effects.rank_collectible_connection_size if for_connection\
				else pack.effects.rank_collectible_collection_size
				if width_range != Vector2.ZERO:
					return width_range
	return Vector2.ZERO

func quota_ring_center() -> Vector2:
	return active_skin.effects.quota_ring_center if active_skin.effects != null else default_skin.effects.quota_ring_center

func mystery_particle_texture(slot: int) -> Texture2D:
	if slot < 0 or slot >= JuiceTheme.COLOR_KEYS.size():
		return null
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		if pack.effects != null and slot < pack.effects.mystery_particles.size():
			if pack.effects.mystery_particles[slot] != null:
				return pack.effects.mystery_particles[slot]
	return null

func mystery_particle_size_correction(texture: Texture2D) -> float:
	if texture != null:
		for pack: JuiceSkinDefinition in [active_skin, default_skin]:
			if pack.effects != null and pack.effects.mystery_particles.has(texture):
				return pack.effects.mystery_particle_size_correction
	return 1.0

func quota_ring_shape() -> Vector2:
	return active_skin.effects.quota_ring_shape if active_skin.effects != null else default_skin.effects.quota_ring_shape

func progress_texture(slot: int, fallback: Texture2D) -> Texture2D:
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		if pack.effects != null and slot >= 0 and slot < pack.effects.progress_colors.size():
			if pack.effects.progress_colors[slot] != null:
				return pack.effects.progress_colors[slot]
	return fallback

func collection_butterflies_enabled() -> bool:
	return active_skin.collection_butterflies_enabled

func butterfly_scene(slot: int, fallback: PackedScene) -> PackedScene:
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		if pack.effects != null and slot >= 0 and slot < pack.effects.butterflies.size():
			if pack.effects.butterflies[slot] != null:
				return pack.effects.butterflies[slot]
	return fallback

func sound_id(semantic: StringName, fallback: StringName) -> StringName:
	var selected: StringName = active_skin.sounds.get(semantic, &"")
	if selected != &"":
		return selected
	return default_skin.sounds.get(semantic, fallback)

func identity() -> String:
	return "%s:%d" % [active_skin.id, active_skin.revision]

func toast_key(semantic: String) -> String:
	for pack: JuiceSkinDefinition in [active_skin, default_skin]:
		var key: String = pack.toast_keys.get(semantic, "")
		if not key.is_empty():
			return key
	return semantic

static func validate(pack: JuiceSkinDefinition, expected_id: StringName, require_complete: bool = false) -> String:
	if pack == null or pack.id != expected_id or pack.revision < 1:
		return "皮肤ID或版本不合法"
	if pack.target_bar_max_visible_count < 0:
		return "目标栏一屏数量不能为负数"
	if require_complete and pack.target_bar_max_visible_count == 0:
		return "默认皮肤缺少目标栏一屏数量"
	if not is_finite(pack.rank_collectible_target_height_ratio) or pack.rank_collectible_target_height_ratio < 0.0:
		return "排行榜礼盒高度比例必须是有限非负数"
	if require_complete and pack.rank_collectible_target_height_ratio == 0.0:
		return "默认皮肤缺少排行榜礼盒高度比例"
	var seen: Dictionary = {}
	for visual: JuiceSkinVisual in pack.rank_collectible_elements:
		if not _valid_visual(visual):
			return "排行榜收集物素材无效"
	for visual: JuiceSkinVisual in [pack.rank_collectible_container, pack.rank_collectible_target]:
		if visual != null and not _valid_visual(visual):
			return "排行榜礼盒素材无效"
	if pack.rank_collectible_targets.size() > 5:
		return "排行榜完成礼盒最多五款"
	for visual: JuiceSkinVisual in pack.rank_collectible_targets:
		if visual != null and not _valid_visual(visual):
			return "排行榜完成礼盒素材无效"
	var ribbon: Array[JuiceSkinVisual] = [pack.rank_collectible_rope_top, pack.rank_collectible_rope_mid, pack.rank_collectible_rope_bottom]
	if ribbon.any( func(visual: JuiceSkinVisual) -> bool: return visual != null):
		for visual: JuiceSkinVisual in ribbon:
			if visual == null or not _valid_visual(visual) or not visual.source_bounds.has_area():
				return "排行榜丝带三段素材或可见边界不完整"
		var rows: Vector2 = pack.rank_collectible_rope_body_rows
		if not rows.is_finite() or rows.x <= ribbon[0].source_bounds.position.y or rows.y <= 0.0\
		or rows.x > ribbon[0].texture.get_height() or rows.y > ribbon[1].texture.get_height():
			return "排行榜丝带主体行数无效"
		if ribbon[0].texture.get_width() != ribbon[1].texture.get_width()\
		or ribbon[0].texture.get_width() != ribbon[2].texture.get_width():
			return "排行榜丝带三段源图宽度必须一致"
	for color: JuiceSkinColorAssets in pack.colors:
		if color == null or not JuiceTheme.COLOR_KEYS.has(String(color.color_key)) or seen.has(color.color_key):
			return "颜色配置为空、重复或颜色名无效"
		seen[color.color_key] = true
		for field: String in COLOR_FIELDS:
			var visual: JuiceSkinVisual = color.get(field)
			if visual != null and not _valid_visual(visual):
				return "%s.%s的贴图或几何无效" % [color.color_key, field]
			if require_complete and visual == null:
				return "默认皮肤缺少%s.%s" % [color.color_key, field]
	for field: String in SINGLE_FIELDS:
		var visual: JuiceSkinVisual = pack.get(field)
		if visual != null and not _valid_visual(visual):
			return "%s的贴图或几何无效" % field
		if require_complete and visual == null:
			return "默认皮肤缺少%s" % field
	if require_complete and seen.size() != JuiceTheme.COLOR_KEYS.size():
		return "默认皮肤必须覆盖十色"
	var anim: JuiceSkinAnimationAssets = pack.collect_animation
	if anim != null:
		if (anim.scene == null or anim.color_keys.size() != 10
				or not is_finite(anim.reference_width) or anim.reference_width <= 0.0
				or not is_finite(anim.collection_display_scale) or anim.collection_display_scale <= 0.0
				or not anim.bottom_center.is_finite() or not is_finite(anim.offset_y)
				or anim.slot_prefixes.is_empty() or anim.get_animation == &""
				or anim.idle_animation == &"" or anim.end_animation == &""):
			return "收集动画配置不完整或几何无效"
		var animation_colors: Dictionary = {}
		for key: String in anim.color_keys:
			if key.is_empty() or animation_colors.has(key.to_lower()):
				return "收集动画颜色附件后缀为空或重复"
			animation_colors[key.to_lower()] = true
		for prefix: String in anim.slot_prefixes:
			if prefix.is_empty():
				return "收集动画颜色槽前缀为空"
	if require_complete and anim == null:
		return "默认皮肤缺少收集动画"
	if pack.effects != null:
		if not is_finite(pack.effects.mystery_particle_size_correction) or pack.effects.mystery_particle_size_correction <= 0.0:
			return "揭开粒子尺寸修正无效"
		if pack.effects.mystery_particles.size() > JuiceTheme.COLOR_KEYS.size():
			return "揭开粒子最多十色"
		for texture: Texture2D in pack.effects.mystery_particles:
			if texture != null and (texture.get_width() <= 0 or texture.get_height() <= 0):
				return "揭开粒子贴图尺寸无效"
		if not pack.effects.quota_ring_center.is_finite() or not pack.effects.quota_ring_shape.is_finite() or pack.effects.quota_ring_shape.x <= 0.0 or pack.effects.quota_ring_shape.y <= 0.0:
			return "目标栏光圈几何无效"
		if not is_finite(pack.effects.collection_particle_size_correction) or pack.effects.collection_particle_size_correction <= 0.0:
			return "合成粒子尺寸修正无效"
		if not is_finite(pack.effects.connection_particle_size_correction) or pack.effects.connection_particle_size_correction < 0.0:
			return "连接粒子尺寸修正无效"
		for width_range: Vector2 in [pack.effects.rank_collectible_connection_size, pack.effects.rank_collectible_collection_size]:
			if not width_range.is_finite() or (width_range != Vector2.ZERO and (width_range.x <= 0.0 or width_range.y < width_range.x)):
				return "排行榜雪花尺寸范围无效"
		if pack.effects.collection_particles.size() > JuiceTheme.COLOR_KEYS.size():
			return "合成粒子最多十色"
		for texture: Texture2D in pack.effects.collection_particles:
			if texture != null and (texture.get_width() <= 0 or texture.get_height() <= 0):
				return "合成粒子贴图尺寸无效"
	if pack.effects != null and (pack.effects.progress_colors.size() > 12 or pack.effects.butterflies.size() > 5):
		return "流光最多12槽，蝴蝶最多5槽"
	return ""

static func _valid_visual(visual: JuiceSkinVisual) -> bool:
	return (visual.texture != null and visual.texture.get_width() > 0 and visual.texture.get_height() > 0
		and is_finite(visual.size_correction) and visual.size_correction > 0.0
		and visual.visual_center.is_finite() and visual.bottom_anchor.is_finite()
		and visual.offset.is_finite() and is_finite(visual.source_bottom) and visual.source_bottom >= 0.0
		and (visual.source_bounds == Rect2() or (visual.source_bounds.has_area()
			and visual.source_bounds.position.is_finite() and visual.source_bounds.size.is_finite()
			and Rect2(Vector2.ZERO, visual.texture.get_size()).encloses(visual.source_bounds)))
		and (visual.content_rect == Rect2() or (visual.content_rect.size.x > 0.0 and visual.content_rect.size.y > 0.0
			and visual.content_rect.position.is_finite() and visual.content_rect.size.is_finite())))
