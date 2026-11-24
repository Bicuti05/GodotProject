class_name RankBgAmbientFall
extends Control


@onready var _foliage: SplashAmbientFoliage = $Foliage


func _ready() -> void :
	stop()


func start() -> void :
	show()
	_foliage.set_process(true)


func stop() -> void :
	hide()
	_foliage.set_process(false)
