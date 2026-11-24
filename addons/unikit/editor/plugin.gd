@tool
extends EditorPlugin

const _IOS_PLUGINS_SRC: = "res://addons/unikit/native/ios/plugins"
const _IOS_PLUGINS_DST: = "res://ios/plugins/unikit"

var _ios_export_plugin: UniKitIOSExportPlugin
var _android_export_plugin: UniKitAndroidExportPlugin
var _bi_inspector_plugin: UniKitBIConfigInspectorPlugin

const _MANIFEST: = "res://android/build/src/main/AndroidManifest.xml"
const _MANIFEST_BAK: = "res://android/build/src/main/AndroidManifest.xml.unikit.bak"

func _enter_tree() -> void :
	_self_heal_manifest_bak()
	_sync_ios_plugins_to_project()
	_ios_export_plugin = UniKitIOSExportPlugin.new()
	add_export_plugin(_ios_export_plugin)
	_android_export_plugin = UniKitAndroidExportPlugin.new()
	add_export_plugin(_android_export_plugin)
	_bi_inspector_plugin = UniKitBIConfigInspectorPlugin.new()
	add_inspector_plugin(_bi_inspector_plugin)

func _exit_tree() -> void :
	remove_export_plugin(_ios_export_plugin)
	_ios_export_plugin = null
	remove_export_plugin(_android_export_plugin)
	_android_export_plugin = null
	remove_inspector_plugin(_bi_inspector_plugin)
	_bi_inspector_plugin = null



func _sync_ios_plugins_to_project() -> void :
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_IOS_PLUGINS_SRC)):
		push_error("UniKit 同步失败：addons 下 plugins/ 缺失，路径：" + _IOS_PLUGINS_SRC)
		return


	var dst_global: = ProjectSettings.globalize_path(_IOS_PLUGINS_DST)
	if DirAccess.dir_exists_absolute(dst_global):
		_remove_dir_recursive(dst_global)
	DirAccess.make_dir_recursive_absolute(dst_global)

	var src_global: = ProjectSettings.globalize_path(_IOS_PLUGINS_SRC)
	var copied: = _copy_dir_recursive(src_global, dst_global)
	print("[UniKit:sync] mirrored %d files to %s" % [copied, _IOS_PLUGINS_DST])

static func _copy_dir_recursive(src: String, dst: String) -> int:
	var copied: int = 0
	DirAccess.make_dir_recursive_absolute(dst)
	var d: = DirAccess.open(src)
	if d == null:
		return 0
	d.list_dir_begin()
	var name: String = d.get_next()
	while name != "":
		if name == "." or name == "..":
			name = d.get_next()
			continue
		var src_path: String = src.path_join(name)
		var dst_path: String = dst.path_join(name)
		if d.current_is_dir():
			copied += _copy_dir_recursive(src_path, dst_path)
		else:
			DirAccess.copy_absolute(src_path, dst_path)
			copied += 1
		name = d.get_next()
	d.list_dir_end()
	return copied



static func _remove_dir_recursive(path: String) -> void :
	var d: = DirAccess.open(path)
	if d == null:
		return
	d.list_dir_begin()
	var name: String = d.get_next()
	while name != "":
		if name == "." or name == "..":
			name = d.get_next()
			continue
		var full_path: String = path.path_join(name)
		if d.current_is_dir():
			_remove_dir_recursive(full_path)
			DirAccess.remove_absolute(full_path)
		else:
			DirAccess.remove_absolute(full_path)
		name = d.get_next()
	d.list_dir_end()

func _self_heal_manifest_bak() -> void :
	if not FileAccess.file_exists(_MANIFEST_BAK):
		return
	push_warning("[UniKitPlugin] 检测到 %s 残留（上次 export 异常退出？），自动还原 AndroidManifest" % _MANIFEST_BAK)
	if not FileAccess.file_exists(_MANIFEST):
		push_error("[UniKitPlugin] AndroidManifest 不见了，无法还原；请手动从 .bak 复原")
		return
	var src: = FileAccess.get_file_as_string(_MANIFEST_BAK)
	var f: = FileAccess.open(_MANIFEST, FileAccess.WRITE)
	if f == null:
		push_error("[UniKitPlugin] 还原 manifest 失败")
		return
	f.store_string(src)
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_MANIFEST_BAK))
	print("[UniKitPlugin] ✓ AndroidManifest 已自动还原")
