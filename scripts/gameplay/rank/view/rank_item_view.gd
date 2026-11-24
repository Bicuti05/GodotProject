class_name RankItemView
extends Control

signal gift_pressed(rank_pos: int)


const ROW_PITCH: float = 200.0

const _ONLINE_BG_PADDING: float = 40.0
const _ONLINE_BG_MIN_WIDTH: float = 96.0
const _ONLINE_BG_HEIGHT: float = 72.0

const _ONLINE_BG_MAX_WIDTH: float = 284.0

const _NICKNAME_H_WITH_ONLINE: float = 60.0
const _NICKNAME_H_ALONE: float = 120.0
const _NICKNAME_CENTER_WITH_ONLINE: float = -30.0
const _NICKNAME_ONLINE_GAP: float = 8.0

const _NICKNAME_W_WITH_GIFT: float = 284.0
const _NICKNAME_W_WIDE: float = 364.0

@export var finish_layout: bool = false
@export var podium_slot: int = 0

@export var top_icons: Array[Texture2D] = []
@export var gift_icons: Array[Texture2D] = []
@export var bg_normal: Texture2D = null
@export var bg_normal_me: Texture2D = null
@export var bg_top: Array[Texture2D] = []
@export var bg_top_me: Array[Texture2D] = []
@export var number_bg: Texture2D = null
@export var number_bg_me: Texture2D = null
@export var online_bg: Texture2D = null
@export var offline_bg: Texture2D = null

@onready var _bg: NinePatchRect = $Bg
@onready var _rank_icon: TextureRect = $RankIcon
@onready var _rank_number: Label = $RankNumber
@onready var _avatar: TextureRect = $Avatar
@onready var _info: Control = $Info
@onready var _nickname: Label = $Info / Nickname
@onready var _online_bg: NinePatchRect = $Info / OnlineBg
@onready var _online: Label = $Info / Online
@onready var _collect_bg: TextureRect = $CollectBg
@onready var _collect_num: Label = $CollectBg / CollectNum
@onready var _collect_icon: TextureRect = $CollectIcon
@onready var _gift_button: TextureButton = $GiftButton
@onready var _outline_glow: NinePatchRect = $OutlineGlow
@onready var _flow_light: TextureRect = $FlowLight

@export var source_row_fx_scene: PackedScene = null
var _source_row_fx: RankRowSourceFx

static var _online_width_cache: Dictionary = {}
static var _online_width_locale: String = ""
var _row_key: String = ""
var _rank_pos: int = 0
var _collect_punch_tween: Tween
var _collect_position_before: Vector2
var _collect_pivot_before: Vector2
var _collect_punch_active: bool = false
var _tilt_tween: Tween = null
var _outline_tween: Tween = null
var _flow_gen: int = 0
var _collect_num_base_font_size: int = 0


func _ready() -> void :
	_nickname.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if podium_slot == 0:
		_nickname.grow_vertical = Control.GROW_DIRECTION_BOTH
	RankAvatarCell.fit_list_frame($AvatarFrame as TextureRect, _avatar)
	if finish_layout:
		_collect_num_base_font_size = _collect_num.get_theme_font_size("font_size")
		_layout_collect_num()
	if _source_row_fx != null:
		_source_row_fx.fit_row(Vector2(size.x, 184.0 if finish_layout else size.y))


func _layout_collect_num() -> void :


	var font: Font = _collect_num.get_theme_font("font")
	var font_size: int = _collect_num.get_theme_font_size("font_size")

	var line: TextLine = TextLine.new()
	line.add_string("0", font, font_size)
	var rid: RID = font.get_rids()[0]
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var glyph: int = text_server.font_get_glyph_index(rid, font_size, "0".unicode_at(0), 0)
	var glyph_offset: Vector2 = text_server.font_get_glyph_offset(rid, Vector2i(font_size, 0), glyph)
	var glyph_size: Vector2 = text_server.font_get_glyph_size(rid, Vector2i(font_size, 0), glyph)
	var correction: float = line.get_size().y * 0.5\
	- line.get_line_ascent() - glyph_offset.y - glyph_size.y * 0.5
	_collect_num.anchor_top = 0.0
	_collect_num.anchor_bottom = 1.0
	_collect_num.offset_top = correction
	_collect_num.offset_bottom = correction


func prepare_rise_fx(active: Callable) -> bool:
	if not active.call():
		return false
	if _source_row_fx == null and source_row_fx_scene != null:
		_source_row_fx = source_row_fx_scene.instantiate() as RankRowSourceFx
		_source_row_fx.visible = false
		add_child(_source_row_fx)
		await get_tree().process_frame
		if not active.call():
			return false
	if _source_row_fx != null:
		_source_row_fx.fit_row(Vector2(size.x, 184.0 if finish_layout else size.y))
	return active.call()


func reset_for_reuse() -> void :
	reset_first_place_fx()
	reset_rise_fx()
	reset_tilt()
	reset_collect_punch()
	set_avatar_visible(true)
	scale = Vector2.ONE
	modulate = Color.WHITE
	position.x = RankListView.ROW_X


func bind(row: Dictionary, avatar: Texture2D, element_tex: Texture2D = null) -> void :
	var rank_pos: int = int(row.get("rank_pos", 0))
	var is_me: bool = bool(row.get("is_me", false))
	var key_changed: bool = _row_key != make_row_key(row)
	_row_key = make_row_key(row)
	_rank_pos = rank_pos

	if podium_slot == 0:
		_bg.texture = _resolve_bg(rank_pos, is_me)
		_collect_bg.texture = number_bg_me if is_me else number_bg
	if key_changed:
		reset_collect_punch()
		reset_first_place_fx()

	var is_top: bool = rank_pos >= 1 and rank_pos <= 3
	_rank_icon.visible = is_top
	_rank_number.visible = not is_top
	_rank_icon.texture = top_icons[rank_pos - 1] if is_top and top_icons.size() >= rank_pos else null
	_rank_number.text = str(rank_pos) if rank_pos > 0 else ""
	_gift_button.visible = is_top
	if podium_slot == 0:
		_gift_button.texture_normal = gift_icons[rank_pos - 1] if is_top and gift_icons.size() >= rank_pos else null

	_avatar.texture = avatar
	var nickname: String = String(row.get("nickname", ""))
	if _nickname.text != nickname:
		_nickname.text = nickname
	if not finish_layout:
		_nickname.offset_right = _NICKNAME_W_WITH_GIFT if is_top else _NICKNAME_W_WIDE
	set_collect_num_display(int(row.get("collect_num", 0)))
	_collect_icon.texture = element_tex

	var key: String = String(row.get("online_text_key", ""))
	_online.visible = not key.is_empty() and podium_slot == 0
	var online_text: String = _format_online(key, int(row.get("online_minutes", 0)))
	if _online.text != online_text:
		_online.text = online_text
	if podium_slot > 0:
		_online_bg.visible = false
	else:
		_refresh_online_bg(key)
		_layout_nickname()


func _layout_nickname() -> void :

	var line: TextLine = TextLine.new()
	line.add_string(_nickname.text, _nickname.get_theme_font("font"), 
		_nickname.get_theme_font_size("font_size"))

	var line_height: float = maxf(line.get_size().y, _nickname.get_minimum_size().y)
	var height: float = maxf(line_height, 
		_NICKNAME_H_WITH_ONLINE if _online.visible else _NICKNAME_H_ALONE)
	var center: float = _avatar.position.y + _avatar.size.y * 0.5 - _info.position.y
	if _online.visible:
		center += _NICKNAME_CENTER_WITH_ONLINE
	_nickname.offset_top = center - height * 0.5
	_nickname.offset_bottom = center + height * 0.5
	if _online.visible:
		var online_top: float = _nickname.offset_bottom + _NICKNAME_ONLINE_GAP
		_online_bg.offset_top = online_top
		_online_bg.offset_bottom = online_top + _ONLINE_BG_HEIGHT
		_online.offset_top = online_top
		_online.offset_bottom = online_top + _ONLINE_BG_HEIGHT


func prepare_text() -> void :
	for label: Label in [_rank_number, _nickname, _online, _collect_num]:
		label.get_minimum_size()


func get_row_key() -> String:
	return _row_key


func set_collect_num_display(value: int) -> void :
	var text: String = str(value)
	if _collect_num.text != text:
		_collect_num.text = text
	if podium_slot > 0:
		var font: Font = _collect_num.get_theme_font("font")
		var font_size: int = _collect_num_base_font_size
		while font_size > 16 and font.get_string_size(_collect_num.text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > _collect_num.size.x:
			font_size -= 2
		if font_size != _collect_num.get_theme_font_size("font_size"):
			_collect_num.add_theme_font_size_override("font_size", font_size)
			_layout_collect_num()



func punch_collect_icon() -> void :
	if not _collect_punch_active:
		_collect_pivot_before = _collect_icon.pivot_offset
		_collect_position_before = _collect_icon.position
		_collect_punch_active = true
	_collect_icon.pivot_offset = _collect_icon.size * 0.5
	_collect_punch_tween = RankCollectImpact.play(self, _collect_icon, 
		_collect_position_before, Vector2.ONE, _collect_punch_tween)
	_collect_punch_tween.tween_callback(reset_collect_punch)

func reset_collect_punch() -> void :
	if is_instance_valid(_collect_punch_tween):
		_collect_punch_tween.kill()
	_collect_punch_tween = null
	_collect_icon.scale = Vector2.ONE
	if _collect_punch_active:
		_collect_icon.position = _collect_position_before
		_collect_icon.pivot_offset = _collect_pivot_before
	_collect_punch_active = false

func get_collect_num_display() -> int:
	return _collect_num.text.to_int()


func get_collect_target_global_pos() -> Vector2:

	if _collect_punch_active:
		return get_global_transform() * (_collect_position_before + _collect_icon.size * 0.5)
	return _collect_icon.get_global_transform() * (_collect_icon.size * 0.5)


func get_collect_icon_global_rect() -> Rect2:
	return _collect_icon.get_global_rect()


func get_gift_button_global_rect() -> Rect2:
	return _gift_button.get_global_rect()


const OUTLINE_FADE_IN_SEC: float = 0.067
const OUTLINE_FADE_OUT_SEC: float = 0.933

const FLOW_SHOW_MAX_FRAMES: int = 8


func play_outline_flash() -> void :
	if _outline_tween != null:
		_outline_tween.kill()
	_outline_glow.modulate.a = 0.0
	_outline_glow.visible = true
	_outline_tween = create_tween()
	_outline_tween.tween_property(_outline_glow, "modulate:a", 1.0, OUTLINE_FADE_IN_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	_outline_tween.tween_property(_outline_glow, "modulate:a", 0.0, OUTLINE_FADE_OUT_SEC)\
	.set_trans(Tween.TRANS_LINEAR)
	_outline_tween.tween_callback( func() -> void : _outline_glow.visible = false)


func show_flow_light() -> void :
	_flow_gen += 1
	var gen: int = _flow_gen
	_flow_light.visible = false
	for _i: int in range(FLOW_SHOW_MAX_FRAMES):
		if not is_inside_tree():
			return
		await get_tree().process_frame
		if gen != _flow_gen:
			return
		if _flow_light.size.x > 0.0 and _flow_light.size.y > 0.0:
			break
	if gen != _flow_gen or not is_inside_tree():
		return
	_flow_light.visible = true


func reset_first_place_fx() -> void :
	_flow_gen += 1
	if _outline_tween != null:
		_outline_tween.kill()
		_outline_tween = null
	_outline_glow.visible = false
	_outline_glow.modulate.a = 1.0
	_flow_light.visible = false


func get_first_place_fx_state() -> Dictionary:
	return {"outline": _outline_glow.visible, "flow": _flow_light.visible}


func _on_gift_pressed() -> void :
	gift_pressed.emit(_rank_pos)


func set_rank_only(rank_pos: int) -> void :
	var is_top: bool = rank_pos >= 1 and rank_pos <= 3
	_rank_icon.visible = is_top
	_rank_number.visible = not is_top
	_rank_icon.texture = top_icons[rank_pos - 1] if is_top and top_icons.size() >= rank_pos else null
	_rank_number.text = str(rank_pos) if rank_pos > 0 else ""
	_gift_button.visible = is_top
	if podium_slot == 0:
		_gift_button.texture_normal = gift_icons[rank_pos - 1] if is_top and gift_icons.size() >= rank_pos else null
	_rank_pos = rank_pos


func play_right_edge_tilt(angle_deg: float, duration: float, flip: bool = false) -> void :
	if _tilt_tween != null and _tilt_tween.is_valid():
		_tilt_tween.kill()
	var target_deg: float = angle_deg if not flip else angle_deg * 0.5
	pivot_offset = Vector2(size.x, size.y)
	_tilt_tween = create_tween()
	_tilt_tween.tween_property(self, "rotation_degrees", target_deg, duration * 0.4)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tilt_tween.tween_property(self, "rotation_degrees", 0.0, duration * 0.6)\
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)


func reset_tilt() -> void :
	if _tilt_tween != null and _tilt_tween.is_valid():
		_tilt_tween.kill()
	_tilt_tween = null
	rotation_degrees = 0.0
	pivot_offset = Vector2.ZERO


func set_rise_outline(on: bool) -> void :
	if _outline_tween != null:
		_outline_tween.kill()
		_outline_tween = null
	if _source_row_fx != null:
		_source_row_fx.stop_glow()
	_outline_glow.visible = on
	if on:


		var vertical_scale: float = _bg.size.y / _bg.texture.get_height()
		var edge: Rect2 = Rect2(_bg.position + Vector2(24.0, 24.0 * vertical_scale), 
			_bg.size - Vector2(48.0, 45.0 * vertical_scale))

		_outline_glow.position = edge.position - Vector2(36.0, 36.0)
		_outline_glow.size = edge.size + Vector2(72.0, 72.0)
		_outline_glow.modulate.a = 1.0


func play_rise_arrows() -> void :
	if _source_row_fx != null:
		_source_row_fx.fit_row(Vector2(size.x, 184.0 if finish_layout else size.y))
		_source_row_fx.start_arrows()


func stop_rise_arrows() -> void :
	if _source_row_fx != null:
		_source_row_fx.stop_arrows()


func set_rise_arrow_alpha(alpha: float) -> void :
	if _source_row_fx != null:
		_source_row_fx.set_arrow_alpha(alpha)


func reset_rise_fx() -> void :
	set_rise_outline(false)
	if _source_row_fx != null:
		_source_row_fx.stop()


func clone_bind_from(src: RankItemView) -> void :
	if src == null:
		return
	reset_rise_fx()
	_row_key = src.get_row_key()
	_rank_pos = src._rank_pos
	_bg.texture = src._bg.texture
	_collect_bg.texture = src._collect_bg.texture
	_rank_icon.visible = src._rank_icon.visible
	_rank_icon.texture = src._rank_icon.texture
	_rank_number.visible = src._rank_number.visible
	_rank_number.text = src._rank_number.text
	_gift_button.visible = src._gift_button.visible
	_gift_button.texture_normal = src._gift_button.texture_normal
	_avatar.texture = src._avatar.texture
	_nickname.text = src._nickname.text
	_nickname.offset_top = src._nickname.offset_top
	_nickname.add_theme_color_override("font_color", src._nickname.get_theme_color("font_color"))
	_online.add_theme_color_override("font_color", src._online.get_theme_color("font_color"))
	_nickname.offset_bottom = src._nickname.offset_bottom
	_nickname.offset_right = src._nickname.offset_right
	_collect_num.text = src._collect_num.text
	_collect_icon.texture = src._collect_icon.texture
	_online.visible = src._online.visible
	_online.text = src._online.text
	_online.offset_top = src._online.offset_top
	_online.offset_bottom = src._online.offset_bottom
	_online_bg.visible = src._online_bg.visible
	_online_bg.texture = src._online_bg.texture
	_online_bg.size = src._online_bg.size
	_online_bg.offset_top = src._online_bg.offset_top
	_online_bg.offset_bottom = src._online_bg.offset_bottom


static func make_row_key(row: Dictionary) -> String:
	if bool(row.get("is_me", false)):
		return "me"
	return "bot:" + String(row.get("nickname", ""))


func _resolve_bg(rank_pos: int, is_me: bool) -> Texture2D:
	if rank_pos >= 1 and rank_pos <= 3:
		var pool: Array[Texture2D] = bg_top_me if is_me else bg_top
		if pool.size() >= rank_pos and pool[rank_pos - 1] != null:
			return pool[rank_pos - 1]
	return bg_normal_me if is_me else bg_normal


func _format_online(key: String, minutes: int) -> String:
	if key.is_empty():
		return ""
	if key == RankFakeUserGenerator.ONLINE_KEY_MINUTES_AGO and minutes >= 60:
		var fmt_h: String = tr(RankFakeUserGenerator.ONLINE_KEY_HOURS_MINUTES_AGO)
		if fmt_h.count("%d") >= 2:
			return fmt_h % [minutes / 60, minutes % 60]
		return (fmt_h % (minutes / 60)) if "%d" in fmt_h else fmt_h
	var fmt: String = tr(key)
	return (fmt % minutes) if "%d" in fmt else fmt


func _refresh_online_bg(key: String) -> void :
	_online_bg.visible = not key.is_empty()
	if key.is_empty():
		return
	_online_bg.texture = online_bg if key == RankFakeUserGenerator.ONLINE_KEY_NOW else offline_bg
	var font: Font = _online.get_theme_font("font")
	var font_size: int = _online.get_theme_font_size("font_size")
	var locale: String = TranslationServer.get_locale()
	if _online_width_locale != locale:
		_online_width_locale = locale
		_online_width_cache.clear()
	var cache_key: String = "%d:%d:%s" % [font.get_instance_id(), font_size, _online.text]
	if not _online_width_cache.has(cache_key):
		_online_width_cache[cache_key] = font.get_string_size(_online.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_width: float = float(_online_width_cache[cache_key])
	var bg_width: float = clampf(text_width + _ONLINE_BG_PADDING, 
		_ONLINE_BG_MIN_WIDTH, _ONLINE_BG_MAX_WIDTH)
	_online_bg.size = Vector2(bg_width, _ONLINE_BG_HEIGHT)


func get_avatar_global_rect() -> Rect2:
	return _avatar.get_global_rect()


func set_avatar_visible(on: bool) -> void :
	_avatar.visible = on
	($AvatarFrame as TextureRect).visible = on


func make_avatar_clone() -> Control:
	var holder: = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = _avatar.size
	var avatar: = _avatar.duplicate() as TextureRect
	avatar.position = Vector2.ZERO
	avatar.visible = true
	holder.add_child(avatar)
	var frame: = ($AvatarFrame as TextureRect).duplicate() as TextureRect
	frame.position = ($AvatarFrame as TextureRect).position - _avatar.position
	frame.visible = true
	holder.add_child(frame)
	return holder
