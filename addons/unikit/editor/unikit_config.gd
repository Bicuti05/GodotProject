@tool
class_name UniKitConfig
extends Resource





@export_group("Android（Google 渠道）")
@export var android: UniKitAndroidConfig

@export_group("iOS（Apple 渠道）")
@export var ios: UniKitIOSConfig

func validate() -> Array[String]:
	var errors: Array[String] = []
	if android == null:
		errors.append("android (子 Resource 未创建)")
	else:
		for f in android.validate(): errors.append("android." + f)
	if ios == null:
		errors.append("ios (子 Resource 未创建)")
	else:
		for f in ios.validate(): errors.append("ios." + f)
	return errors


func has_platform(platform: String) -> bool:
	match platform:
		"android": return android != null and android.production_id != ""
		"ios": return ios != null and ios.production_id != ""
		_: return false
