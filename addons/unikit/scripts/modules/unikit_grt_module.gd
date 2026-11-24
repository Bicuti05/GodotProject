class_name UniKitGrtModule
extends UniKitModuleBase


signal ltv_received(ltv: float)


func get_ltv() -> void :
	if _host._plugin == null:
		return
	_host._plugin.getLTV()
