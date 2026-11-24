class_name RankSaluteFx
extends Node2D


const _T_IN_END: float = 0.133
const _T_CHARGE_END: float = 0.5
const _T_SQUASH_END: float = 0.545
const _T_EMIT: float = 0.55
const _T_FIRE_END: float = 0.65
const _T_STRETCH_END: float = 0.717
const _T_HOLD_END: float = 0.8
const _T_RECOIL_END: float = 0.967
const _T_SETTLE_END: float = 1.1

const _SC_CHARGE: Vector2 = Vector2(1.14, 0.76)
const _SC_SQUASH: Vector2 = Vector2(1.95, 0.28)
const _SC_STRETCH: Vector2 = Vector2(0.38, 2.15)
const _SC_RECOIL: Vector2 = Vector2(1.06, 0.88)

const _FLASH_FROM_SCALE: float = 0.35
const _FLASH_TO_SCALE: float = 1.45
const _FLASH_IN_SEC: float = 0.045
const _FLASH_OUT_SEC: float = 0.22

const _BOOST_IN: float = 1.25
const _BOOST_FIRE: float = 1.8

const _ANIM: Dictionary = {
	"SaluteL": {
		"charge_deg": 50.1, 
		"off_in": Vector2(-159.0, 126.0), 
		"off_charge": Vector2(-31.0, 66.0), 
		"off_fire": Vector2(57.0, -111.0), 
		"fire_scale": Vector2(0.8, 1.1), 
	}, 
	"SaluteR": {
		"charge_deg": -50.1, 
		"off_in": Vector2(160.0, 72.0), 
		"off_charge": Vector2(34.0, 67.0), 
		"off_fire": Vector2(-42.0, -109.0), 
		"fire_scale": Vector2(0.9, 1.05), 
	}, 
	"SaluteL2": {
		"charge_deg": 42.2, 
		"off_in": Vector2(-103.0, 55.0), 
		"off_charge": Vector2(-8.0, 22.0), 
		"off_fire": Vector2(25.0, -76.0), 
		"fire_scale": Vector2(0.9, 1.05), 
	}, 
	"SaluteR2": {
		"charge_deg": -50.1, 
		"off_in": Vector2(108.0, 70.0), 
		"off_charge": Vector2(-11.0, 30.0), 
		"off_fire": Vector2(-29.0, -80.0), 
		"fire_scale": Vector2(0.9, 1.05), 
	}, 
}


class _Unit extends RefCounted:
	var salute: Node2D = null
	var barrel: TextureRect = null
	var muzzles: Array[CPUParticles2D] = []
	var flash: Sprite2D = null
	var rest_pos: Vector2 = Vector2.ZERO
	var rest_rot: float = 0.0
	var rest_scale: Vector2 = Vector2.ONE
	var muzzle_offset: Vector2 = Vector2.ZERO
	var charge_rot: float = 0.0
	var off_in: Vector2 = Vector2.ZERO
	var off_charge: Vector2 = Vector2.ZERO
	var off_fire: Vector2 = Vector2.ZERO
	var fire_scale: Vector2 = Vector2.ONE


var _units: Array[_Unit] = []
var _play_token: int = 0
var _tweens: Array[Tween] = []


func _ready() -> void :
	for child in get_children():
		var salute: = child as Node2D
		if salute == null:
			continue
		var barrel: = salute.get_node_or_null("Barrel") as TextureRect
		if barrel == null:
			SortLogger.error("RankSaluteFx: %s 缺 Barrel 子节点,检查 .tscn(应由 tools/gen_rank_salute_fx.py 生成)" % salute.name)
			continue
		if not _ANIM.has(salute.name):
			SortLogger.error("RankSaluteFx: %s 在 _ANIM 表里没有动画参数(两表按节点名对应)" % salute.name)
			continue

		var u: = _Unit.new()
		u.salute = salute
		u.barrel = barrel
		u.flash = salute.get_node_or_null("Flash") as Sprite2D
		u.rest_pos = salute.position
		u.rest_rot = salute.rotation
		u.rest_scale = barrel.scale
		for grand in salute.get_children():
			var p: = grand as CPUParticles2D
			if p != null:
				p.emitting = false
				u.muzzles.append(p)
		if not u.muzzles.is_empty() and u.rest_scale.x != 0.0 and u.rest_scale.y != 0.0:
			u.muzzle_offset = u.muzzles[0].position / u.rest_scale

		var anim: Dictionary = _ANIM[salute.name]
		u.charge_rot = deg_to_rad(float(anim["charge_deg"]))
		u.off_in = anim["off_in"] * _BOOST_IN
		u.off_charge = anim["off_charge"]
		u.off_fire = anim["off_fire"] * _BOOST_FIRE
		u.fire_scale = anim["fire_scale"]
		_units.append(u)

	if _units.is_empty():
		SortLogger.error("RankSaluteFx: 没有可用的礼炮子节点,检查 .tscn(应由 tools/gen_rank_salute_fx.py 生成)")
	reset()


func play() -> void :
	if _units.is_empty():
		return
	_play_token += 1
	var token: int = _play_token
	_kill_tweens()
	visible = true
	for u in _units:
		_animate(u, token)


func stop_all() -> void :
	_play_token += 1
	_kill_tweens()
	for u in _units:
		for p in u.muzzles:
			p.emitting = false


func reset() -> void :
	stop_all()
	visible = false
	modulate.a = 1.0
	for u in _units:
		u.salute.position = u.rest_pos
		u.salute.rotation = u.rest_rot
		u.barrel.scale = u.rest_scale
		u.barrel.modulate.a = 0.0
		var muzzle_pos: Vector2 = u.muzzle_offset * u.rest_scale
		for p in u.muzzles:
			p.position = muzzle_pos
		if u.flash != null:
			u.flash.position = muzzle_pos
			u.flash.scale = Vector2.ONE * _FLASH_FROM_SCALE
			u.flash.modulate.a = 0.0


func _animate(u: _Unit, token: int) -> void :
	u.salute.position = u.rest_pos + u.off_in
	var pos_tw: = _track(u.salute.create_tween())
	pos_tw.tween_property(u.salute, "position", u.rest_pos, _T_IN_END)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pos_tw.tween_property(u.salute, "position", u.rest_pos + u.off_charge, 
		_T_CHARGE_END - _T_IN_END).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pos_tw.tween_property(u.salute, "position", u.rest_pos + u.off_fire, 
		_T_FIRE_END - _T_CHARGE_END).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pos_tw.tween_property(u.salute, "position", u.rest_pos, 
		_T_RECOIL_END - _T_FIRE_END).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	u.salute.rotation = u.rest_rot
	var rot_tw: = _track(u.salute.create_tween())
	rot_tw.tween_interval(_T_IN_END)
	rot_tw.tween_property(u.salute, "rotation", u.charge_rot, 
		_T_CHARGE_END - _T_IN_END).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rot_tw.tween_property(u.salute, "rotation", u.rest_rot, 
		_T_FIRE_END - _T_CHARGE_END).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	u.barrel.scale = u.rest_scale
	var sc_tw: = _track(u.barrel.create_tween())
	sc_tw.tween_interval(_T_IN_END)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale * _SC_CHARGE, 
		_T_CHARGE_END - _T_IN_END).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale * _SC_SQUASH, 
		_T_SQUASH_END - _T_CHARGE_END).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale * u.fire_scale, 
		_T_FIRE_END - _T_SQUASH_END).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale * _SC_STRETCH, 
		_T_STRETCH_END - _T_FIRE_END).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sc_tw.tween_interval(_T_HOLD_END - _T_STRETCH_END)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale * _SC_RECOIL, 
		_T_RECOIL_END - _T_HOLD_END).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sc_tw.tween_property(u.barrel, "scale", u.rest_scale, 
		_T_SETTLE_END - _T_RECOIL_END).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	u.barrel.modulate.a = 0.0
	var a_tw: = _track(u.barrel.create_tween())
	a_tw.tween_property(u.barrel, "modulate:a", 1.0, _T_IN_END)

	var emit_tw: = _track(u.salute.create_tween())
	emit_tw.tween_interval(_T_EMIT)
	emit_tw.tween_callback(_fire.bind(u, token))


func _fire(u: _Unit, token: int) -> void :
	if token != _play_token or not is_inside_tree():
		return
	var muzzle_pos: Vector2 = u.muzzle_offset * u.barrel.scale
	for p in u.muzzles:
		p.position = muzzle_pos
		p.restart()

	if u.flash != null:
		u.flash.position = muzzle_pos
		u.flash.scale = Vector2.ONE * _FLASH_FROM_SCALE
		u.flash.modulate.a = 0.0
		var a_tw: = _track(u.flash.create_tween())
		a_tw.tween_property(u.flash, "modulate:a", 1.0, _FLASH_IN_SEC)
		a_tw.tween_property(u.flash, "modulate:a", 0.0, _FLASH_OUT_SEC)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		var s_tw: = _track(u.flash.create_tween())
		s_tw.tween_property(u.flash, "scale", Vector2.ONE * _FLASH_TO_SCALE, 
			_FLASH_IN_SEC + _FLASH_OUT_SEC).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _track(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _kill_tweens() -> void :
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens.clear()
