class_name FinishAdRewardDialog
extends DialogScene

@onready var _motion: FinishAdRewardMotion = $Motion
@onready var _dimmer: ColorRect = $Dimmer


func show_bg() -> void :
	reset_content()
	_dimmer.show()

func play(page: Node, target: Control, icon: Control, reward: Dictionary, 
		before: int, after: int, texture: Texture2D, panel: Node) -> void :
	await _motion.play(page, target, icon, reward, before, after, texture, panel)

func get_motion() -> FinishAdRewardMotion:
	return _motion

func reset_content() -> void :
	if is_instance_valid(_motion):
		_motion.stop()

func _on_hide() -> void :
	hide_panel()
