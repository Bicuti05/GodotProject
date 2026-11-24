@tool
extends EditorPlugin

var _export_plugin: LifecycleCompatExportPlugin


func _enter_tree() -> void :
	_export_plugin = LifecycleCompatExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void :
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class LifecycleCompatExportPlugin extends EditorExportPlugin:
	const SOURCE_PATH: = "res://addons/ios_lifecycle_compat/lifecycle_compat.mm"

	var _is_ios_export: bool = false
	var _export_path: String = ""

	func _get_name() -> String:
		return "IOSLifecycleCompat"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void :
		_is_ios_export = "ios" in features
		if not _is_ios_export:
			return
		_export_path = path
		var source: String = FileAccess.get_file_as_string(SOURCE_PATH)
		if source.is_empty():
			push_error("[IOSLifecycleCompat] 无法读取兼容源码: %s" % SOURCE_PATH)
			return
		add_ios_cpp_code(source)

	func _export_end() -> void :
		if not _is_ios_export:
			return
		_patch_dummy_cpp_filetype()

	func _patch_dummy_cpp_filetype() -> void :
		var pbxproj_path: String = _export_path.path_join("project.pbxproj")
		if not FileAccess.file_exists(pbxproj_path):
			push_error("[IOSLifecycleCompat] project.pbxproj 不存在: %s" % pbxproj_path)
			return
		var content: String = FileAccess.get_file_as_string(pbxproj_path)
		var objcpp_marker: = "explicitFileType = sourcecode.cpp.objcpp; path = dummy.cpp;"
		var cpp_marker: = "lastKnownFileType = sourcecode.cpp.cpp; path = dummy.cpp;"
		if content.contains(objcpp_marker):
			return
		if not content.contains(cpp_marker):
			push_error("[IOSLifecycleCompat] 找不到 dummy.cpp 文件类型标记")
			return
		content = content.replace(cpp_marker, objcpp_marker)
		var file: = FileAccess.open(pbxproj_path, FileAccess.WRITE)
		if file == null:
			push_error("[IOSLifecycleCompat] 无法写入 project.pbxproj")
			return
		file.store_string(content)
		file.close()
