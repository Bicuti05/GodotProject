class_name JuiceColMark
extends Control


















enum Kind{OK, BAD, SRC, OK_SELECTED, MUTED}




const MARK_SIZE: = 88.0




@export var glow_green: Texture2D = null
@export var glow_red: Texture2D = null
@export var glow_blue: Texture2D = null
@export var glow_yellow: Texture2D = null
@export var fill_green: Texture2D = null
@export var fill_red: Texture2D = null
@export var fill_yellow: Texture2D = null
@export var mark_tick: Texture2D = null
@export var mark_cross: Texture2D = null

@onready var _fill: JuiceCapsuleRect = $Fill
@onready var _glow: JuiceCapsuleRect = $Glow
@onready var _mark: TextureRect = $Mark
var _kind: int = -1
func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		_update_fill_rect()




func set_kind(kind: Kind) -> void :
	if _kind == kind:
		return
	_kind = kind
	match kind:
		Kind.OK:
			_glow.texture = glow_green
			_set_fill(fill_green)
			_set_mark(mark_tick)
		Kind.OK_SELECTED:
			_glow.texture = glow_yellow
			_set_fill(fill_yellow)
			_set_mark(mark_tick)
		Kind.BAD:
			_glow.texture = glow_red
			_set_fill(fill_red)
			_set_mark(mark_cross)
		Kind.SRC:
			_glow.texture = glow_blue
			_fill.texture = null
			_fill.visible = false
			_set_mark(null)

		Kind.MUTED:
			_glow.texture = null
			_set_fill(null)
			_set_mark(null)



func set_selected(selected: bool) -> void :
	if _kind == Kind.OK or _kind == Kind.OK_SELECTED:
		set_kind(Kind.OK_SELECTED if selected else Kind.OK)


func _set_fill(tex: Texture2D) -> void :
	_fill.texture = tex
	_fill.visible = tex != null
	_update_fill_rect()



func _update_fill_rect() -> void :
	if _fill == null or _glow == null:
		return
	var inset: Vector2 = Vector2.ZERO
	if _fill.texture != null and _glow.texture != null:
		var glow_size: Vector2 = _glow.texture.get_size()
		var corner_scale: float = minf(1.0, minf(size.x, size.y) / glow_size.x)
		inset = (glow_size - _fill.texture.get_size()).max(Vector2.ZERO) * 0.5 * corner_scale
	_fill.offset_left = inset.x
	_fill.offset_top = inset.y
	_fill.offset_right = - inset.x
	_fill.offset_bottom = - inset.y


func _set_mark(tex: Texture2D) -> void :
	_mark.texture = tex
	_mark.visible = tex != null
