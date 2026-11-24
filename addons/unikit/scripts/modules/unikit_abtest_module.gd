class_name UniKitAbTestModule
extends UniKitModuleBase

signal abtest_ready(user_info: Dictionary)
signal abtest_params_updated(update_type: String, user_info: Dictionary)



signal abtest_locsrv_fetched(success: bool)


signal abtest_remote_config_ready








func get_ab_string(key: String, default_value: String = "") -> String:
	if _host._plugin == null:
		return default_value
	return _host._plugin.getAbString(key, default_value)

func get_ab_int(key: String, default_value: int = 0) -> int:
	if _host._plugin == null:
		return default_value
	return _host._plugin.getAbInt(key, default_value)

func get_ab_float(key: String, default_value: float = 0.0) -> float:
	if _host._plugin == null:
		return default_value
	return _host._plugin.getAbFloat(key, default_value)

func dye_ab(key: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.dyeAbTest(key)

func get_all_ab_experiments() -> Dictionary:
	if _host._plugin == null:
		return {}
	var d: Variant = JSON.parse_string(_host._plugin.getAllAbExperimentsJson())
	return d if d is Dictionary else {}

func get_all_publish_ab_experiments() -> Dictionary:
	if _host._plugin == null:
		return {}
	var d: Variant = JSON.parse_string(_host._plugin.getAllPublishAbExperimentsJson())
	return d if d is Dictionary else {}

func get_ab_all_tag() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getAbAllTag()

func get_ab_dyeing_tag() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getAbDyeingTag()

func get_ab_group_id() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getAbGroupId()


func get_ab_user_info() -> Dictionary:
	if _host._plugin == null:
		return {}
	var d: Variant = JSON.parse_string(_host._plugin.getAbUserInfoJson())
	return d if d is Dictionary else {}

func fetch_remote_ab_result() -> void :
	if _host._plugin == null:
		return
	_host._plugin.fetchRemoteLocSerAbResult()

func get_ab_locsrv_param(key: String, default_value: String = "") -> String:
	if _host._plugin == null:
		return default_value
	var v: String = _host._plugin.getAbLocSerParam(key)
	return v if v != "" else default_value

func get_all_ab_locsrv_params() -> Dictionary:
	if _host._plugin == null:
		return {}
	var d: Variant = JSON.parse_string(_host._plugin.getAbAllLocSerParamsJson())
	return d if d is Dictionary else {}

func dye_ab_locsrv(key: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.dyeAbLocSerTag(key)

func set_ab_locsrv_all_tag(all_tags: Array[String], empty_tags: Array[String] = []) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setAbServerTag(JSON.stringify(all_tags), JSON.stringify(empty_tags))

func dye_ab_locsrv_tag(tag: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.dyeAbServerTag(tag)

func get_ab_country() -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getAbCountry()


func set_ab_group_id(group_id: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setAbGroupId(group_id)

func set_ab_country(country: String) -> void :
	if _host._plugin == null:
		return
	_host._plugin.setAbCountry(country)




func get_experiment_value(key: String) -> Variant:
	if _host._plugin == null:
		return null
	var d: Variant = JSON.parse_string(_host._plugin.getExperimentValue(key))
	if d is Dictionary and d.has(key):
		return d[key]
	return null


func is_dyeing(key: String) -> bool:
	if _host._plugin == null:
		return false
	return _host._plugin.isDyeing(key)



func get_group_status(key: String) -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getGroupStatus(key)


func get_dyeing_time(key: String) -> String:
	if _host._plugin == null:
		return ""
	return _host._plugin.getDyeingTime(key)


func get_all_dyeing_times() -> Dictionary:
	if _host._plugin == null:
		return {}
	var d: Variant = JSON.parse_string(_host._plugin.getAllDyeingTimes())
	return d if d is Dictionary else {}
