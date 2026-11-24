class_name RankDanmakuItem
extends Control


const PILL_HEIGHT: float = 81.0
const PILL_PAD_LEFT: float = 108.0
const PILL_PAD_RIGHT: float = 60.0
const PILL_MIN_WIDTH: float = 528.0

@export var bg_textures: Array[Texture2D] = []

@onready var _bg: NinePatchRect = $Bg
@onready var _text: Label = $Text
@onready var _avatar_slot: Control = $AvatarSlot
@onready var _avatar: RankAvatarCell = $AvatarSlot / AvatarCell
@onready var _badge_slot: Control = $BadgeSlot
@onready var _badge: RankBadgeView = $BadgeSlot / Badge


func bind_avatar(text_key: String, avatar_index: int, tex: Texture2D) -> void :
	_avatar_slot.visible = true
	_badge_slot.visible = false
	_avatar.bind(avatar_index, tex)
	_pick_bg()
	_apply_text(text_key)


func bind_badge(text_key: String, tier: int) -> void :
	_avatar_slot.visible = false
	_badge_slot.visible = true
	_badge.set_tier(clampi(tier, RankBadgeView.TIER_MIN, RankBadgeView.TIER_MAX))
	_pick_bg()
	_apply_text(text_key)


func get_pill_width() -> float:
	return size.x


func _pick_bg() -> void :
	if bg_textures.is_empty():
		SortLogger.error("RankDanmakuItem: bg_textures 为空,检查 .tscn 是否绑了四张底图")
		return
	_bg.texture = bg_textures[randi() % bg_textures.size()]


func _apply_text(text_key: String) -> void :
	_text.text = tr(text_key)
	var font: Font = _text.get_theme_font("font")
	var font_size: int = _text.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(
		_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pill_width: float = maxf(
		PILL_PAD_LEFT + text_width + PILL_PAD_RIGHT, PILL_MIN_WIDTH)
	size = Vector2(pill_width, PILL_HEIGHT)
