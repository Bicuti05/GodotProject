class_name MainPackPath









static func register_absolute() -> void :
	if not OS.has_feature("ios"):
		return
	var started_usec: int = Time.get_ticks_usec()
	var exec_path: String = OS.get_executable_path()
	if _register_beside(exec_path):
		SortLogger.info("[Startup] 主包已按绝对路径登记 耗时=%dms" % ((Time.get_ticks_usec() - started_usec) / 1000))
	else:
		SortLogger.error("MainPackPath: 主包绝对路径登记失败，仍使用相对路径 exec=%s" % exec_path)



static func _register_beside(exec_path: String) -> bool:
	var exec_dir: String = exec_path.get_base_dir()
	if not exec_dir.is_absolute_path():
		return false
	var exec_file: String = exec_path.get_file()
	for pack_name: String in [exec_file.get_basename() + ".pck", exec_file + ".pck"]:
		var pack_path: String = exec_dir.path_join(pack_name)
		if FileAccess.file_exists(pack_path) and ProjectSettings.load_resource_pack(pack_path, true):
			return true
	return false
