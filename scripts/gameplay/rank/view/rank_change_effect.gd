class_name RankChangeEffect
extends Node2D


enum Branch{NONE, UPGRADE, DOWNGRADE, UNCHANGED}

@onready var _upgrade: Node2D = $Upgrade
@onready var _upgrade_idle: Node2D = $UpgradeIdle
@onready var _downgrade: Node2D = $Downgrade
@onready var _downgrade_idle: Node2D = $DowngradeIdle
@onready var _unchange_idle: Node2D = $UnchangeIdle

var _branch: int = Branch.NONE


func play_upgrade() -> void :
	stop_all()
	_branch = Branch.UPGRADE
	_burst(_upgrade)
	_loop(_upgrade_idle)


func play_downgrade() -> void :
	stop_all()
	_branch = Branch.DOWNGRADE
	_burst(_downgrade)
	_loop(_downgrade_idle)


func play_unchanged() -> void :
	stop_all()
	_branch = Branch.UNCHANGED
	_loop(_unchange_idle)


func stop_all() -> void :
	_branch = Branch.NONE
	for group in [_upgrade, _upgrade_idle, _downgrade, _downgrade_idle, _unchange_idle]:
		for node in (group as Node).get_children():
			_set_emitting(node as CPUParticles2D, false)
	modulate.a = 1.0


func fade_out(dur: float = 0.3) -> void :
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, dur)
	tw.tween_callback(stop_all)


func _burst(group: Node2D) -> void :
	for node in group.get_children():
		var p: = node as CPUParticles2D
		if p != null:
			p.emitting = false
			p.restart()


func _loop(group: Node2D) -> void :
	for node in group.get_children():
		_set_emitting(node as CPUParticles2D, true)


func _set_emitting(p: CPUParticles2D, value: bool) -> void :
	if p != null:
		p.emitting = value


func get_branch() -> int:
	return _branch


func get_emitting_names() -> Array[String]:
	var names: Array[String] = []
	for p in find_children("*", "CPUParticles2D", true, false):
		if (p as CPUParticles2D).emitting:
			names.append(String((p as Node).name))
	return names
