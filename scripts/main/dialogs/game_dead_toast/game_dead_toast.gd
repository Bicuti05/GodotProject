class_name GameDeadToast
extends PageScene



const CARD_SIZE: = Vector2(864.0, 203.0)
const PROP_BAR_RESERVED_H: = 432.0
const CARD_BOTTOM_GAP: = 24.0
const OTHER_BOOSTERS_ACCENT_COLOR: = "#FB6458"



const REDESIGNED_CARD_W: = 900.0
const REDESIGNED_BOTTOM_PAD: = 56.0
const REDESIGNED_BODY_X: = 69.0
const REDESIGNED_BODY_W: = 762.0
const REDESIGNED_BODY_TOP: = 118.0

const BODY_MUTED_COLOR: = "#8692A1"
const CHEER_ACCENT_COLOR: = "#0AA733"

const CHEER_PROGRESS_KEYS: Array[String] = [
	"JUICE_DEAD_CHEER_PROGRESS_1", 
	"JUICE_DEAD_CHEER_PROGRESS_2", 
	"JUICE_DEAD_CHEER_PROGRESS_3", 
]
const CHEER_PLAIN_KEYS: Array[String] = [
	"JUICE_DEAD_CHEER_PLAIN_1", 
	"JUICE_DEAD_CHEER_PLAIN_2", 
	"JUICE_DEAD_CHEER_PLAIN_3", 
]

@onready var _card: NinePatchRect = $Card
@onready var _hint: RichTextLabel = $Card / Hint
@onready var _redesigned_card: Panel = $RedesignedCard
@onready var _redesigned_hint: RichTextLabel = $RedesignedCard / Hint
var _hint_unwinnable: bool = false

var _revive_redesigned: bool = false

var _cheer_key: String = ""
var _filled_pots: int = 0


func _ready() -> void :
	get_viewport().size_changed.connect(_layout)
	_apply_localized_copy()
	_layout()


func _on_show(params: Dictionary = {}) -> void :
	_hint_unwinnable = bool(params.get("hint_unwinnable", false))
	_revive_redesigned = bool(params.get("revive_prompt_redesigned", false))
	_filled_pots = int(params.get("filled_pots", 0))
	_cheer_key = _pick_cheer_key(_filled_pots, int(params.get("target_pots", 0)))

	_card.visible = not _revive_redesigned
	_redesigned_card.visible = _revive_redesigned
	visible = true
	_apply_localized_copy()
	_layout()



	Tracker.track_dlg_show(TrackingEvents.DLG_GAME_OVER, "", false)


func _on_hide() -> void :
	visible = false
	_card.visible = false
	_redesigned_card.visible = false
	_revive_redesigned = false
	_cheer_key = ""
	_filled_pots = 0


func _on_back_request() -> void :
	var game: Node = SceneManager.get_page("game")
	if game != null:
		await game.return_home()


func _notification(what: int) -> void :
	super._notification(what)
	if what == NOTIFICATION_TRANSLATION_CHANGED and _hint != null:
		_apply_localized_copy()
		_layout()


func _apply_localized_copy() -> void :
	if _hint == null:
		return
	var copy: String = tr("JUICE_DEAD_OTHER_BOOSTERS_HINT") if _hint_unwinnable\
	else tr("JUICE_DEAD_BOOSTER_HINT")
	var color: String = OTHER_BOOSTERS_ACCENT_COLOR
	var open_marker: String = "{ACCENT_OPEN}" if _hint_unwinnable else "%1"
	var close_marker: String = "{ACCENT_CLOSE}" if _hint_unwinnable else "%2"
	copy = copy.replace(open_marker, "[color=%s]" % color if _hint_unwinnable else "")
	copy = copy.replace(close_marker, "[/color]" if _hint_unwinnable else "")

	_hint.text = copy
	_hint.add_theme_font_size_override("normal_font_size", 48)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	var body: String = "[color=%s]%s[/color]" % [BODY_MUTED_COLOR, copy]
	if _cheer_key != "":
		body = body + "\n" + _cheer_bbcode()
	_redesigned_hint.text = body
	_redesigned_hint.add_theme_font_size_override("normal_font_size", 48)
	_redesigned_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_redesigned_hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP




func _pick_cheer_key(filled: int, target: int) -> String:
	if not _revive_redesigned:
		return ""
	var keys: Array[String] = CHEER_PROGRESS_KEYS\
	if target > 0 and filled * 2 > target else CHEER_PLAIN_KEYS
	return keys[randi() % keys.size()]



func _cheer_bbcode() -> String:
	var cheer: String = tr(_cheer_key)
	if cheer.contains("%d"):
		cheer = cheer % _filled_pots
	return cheer.replace("{ACCENT_OPEN}", "[color=%s]" % CHEER_ACCENT_COLOR)\
	.replace("{ACCENT_CLOSE}", "[/color]")


func _layout() -> void :
	_layout_control_card()
	_layout_redesigned_card()



func _layout_control_card() -> void :
	if _card == null:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	var bottom_inset: float = UiMetrics.safe_insets().y

	_card.size = CARD_SIZE
	var hint_top: float = 100.0
	var hint_bottom: float = 160.0
	_hint.offset_top = hint_top
	_hint.offset_bottom = hint_bottom
	var extra_height: float = maxf(0.0, float(_hint.get_content_height()) - (hint_bottom - hint_top))

	_hint.offset_bottom = hint_bottom + extra_height
	_card.size.y = CARD_SIZE.y + extra_height
	_card.position = Vector2(
		UiMetrics.center_left(CARD_SIZE.x), 
		vp.y - bottom_inset - PROP_BAR_RESERVED_H - _card.size.y - CARD_BOTTOM_GAP
	).snapped(Vector2.ONE)



func _layout_redesigned_card() -> void :
	if _redesigned_card == null:
		return
	var vp: Vector2 = UiMetrics.viewport_size()
	var bottom_inset: float = UiMetrics.safe_insets().y
	_redesigned_hint.offset_left = REDESIGNED_BODY_X
	_redesigned_hint.offset_right = REDESIGNED_BODY_X + REDESIGNED_BODY_W
	_redesigned_hint.offset_top = REDESIGNED_BODY_TOP
	_redesigned_hint.offset_bottom = REDESIGNED_BODY_TOP
	var body_height: float = maxf(0.0, float(_redesigned_hint.get_content_height()))
	_redesigned_hint.offset_bottom = REDESIGNED_BODY_TOP + body_height
	var card_height: float = REDESIGNED_BODY_TOP + body_height + REDESIGNED_BOTTOM_PAD
	_redesigned_card.size = Vector2(REDESIGNED_CARD_W, card_height)
	_redesigned_card.position = Vector2(
		UiMetrics.center_left(REDESIGNED_CARD_W), 
		vp.y - bottom_inset - PROP_BAR_RESERVED_H - card_height - CARD_BOTTOM_GAP
	).snapped(Vector2.ONE)
