extends SceneTree




func _initialize() -> void :
	call_deferred("_start")



func _start() -> void :
	set_script(load("res://scripts/main/pages/game/_selftest_bonus_level_entry.gd"))
	_initialize()
