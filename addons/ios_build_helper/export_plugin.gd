@tool
extends EditorPlugin

var _export_plugin: IOSBuildHelperExportPlugin

func _enter_tree() -> void :
	_export_plugin = IOSBuildHelperExportPlugin.new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void :
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class IOSBuildHelperExportPlugin extends EditorExportPlugin:
	const TEMPLATE_DIR: String = "res://ios/build/"
	const APP_DELEGATE_DIR: String = "res://ios/build/app_delegate/"
	const LAUNCH_SCREEN_DIR: String = "res://ios/build/launch_screen/"
	const LAUNCH_LOGO_PATH: String = "res://assets/sprites/oakever_games_logo_white.png"
	const LAUNCH_SCREEN_NAMES: PackedStringArray = ["PocketSortLaunchPhone", "PocketSortLaunchPad"]

	var _export_path: String = ""
	var _is_ios_export: bool = false


	var _is_release_env: bool = false

	func _get_name() -> String:
		return "IOSBuildHelper"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void :
		_is_ios_export = "ios" in features
		if not _is_ios_export:
			return
		_export_path = path



		_is_release_env = "rel" in features
		print("[IOSBuildHelper] _export_begin path=%s is_debug=%s is_release_env=%s features=%s"
			%[path, is_debug, _is_release_env, features])

		_inject_app_delegate_hook()
		_register_launch_screens()

	func _export_file(_path: String, _type: String, _features: PackedStringArray) -> void :
		pass

	func _export_end() -> void :
		if not _is_ios_export:
			return
		_copy_podfile()
		_patch_dummy_cpp_filetype()
		_inject_info_plist()
		_configure_launch_screens()
		_patch_entitlements()
		print("[IOSBuildHelper] _export_end completed")


	func _register_launch_screens() -> void :
		for screen_name: String in LAUNCH_SCREEN_NAMES:
			var path: String = LAUNCH_SCREEN_DIR + screen_name + ".storyboard"
			if not FileAccess.file_exists(path):
				push_error("[IOSBuildHelper] 启动页模板缺失: %s" % path)
				return
			add_ios_bundle_file(path)

	func _configure_launch_screens() -> void :
		var plist_path: String = _resolve_info_plist_path()
		var logo_dir: String = plist_path.get_base_dir().path_join(
			"Images.xcassets/PocketSortLaunchLogo.imageset")
		var err: Error = DirAccess.make_dir_recursive_absolute(logo_dir)
		if err == OK:
			err = DirAccess.copy_absolute(ProjectSettings.globalize_path(LAUNCH_LOGO_PATH), 
				logo_dir.path_join("logo.png"))
		if err != OK:
			push_error("[IOSBuildHelper] 复制启动 Logo 失败: %s (%s)" % [logo_dir, error_string(err)])
			return
		var contents: FileAccess = FileAccess.open(logo_dir.path_join("Contents.json"), FileAccess.WRITE)
		if contents == null:
			push_error("[IOSBuildHelper] 写启动 Logo 资源描述失败: %s" % logo_dir)
			return
		contents.store_string(JSON.stringify({
			"images": [{"filename": "logo.png", "idiom": "universal", "scale": "1x"}], 
			"info": {"author": "xcode", "version": 1}
		}, "\t"))
		contents.close()
		if not _patch_launch_storyboard_types():
			return

		if not _patch_one_key(plist_path, "UILaunchStoryboardName", LAUNCH_SCREEN_NAMES[0]):
			return
		if not _patch_one_key(plist_path, "UILaunchStoryboardName~ipad", LAUNCH_SCREEN_NAMES[1]):
			return
		print("[IOSBuildHelper] 启动页与原生遮罩 Logo 资源已接入")

	func _patch_launch_storyboard_types() -> bool:
		var path: String = _export_path.path_join("project.pbxproj")
		if not FileAccess.file_exists(path):
			push_error("[IOSBuildHelper] 找不到启动页资源的 Xcode 工程: %s" % path)
			return false
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		var found: int = 0
		for index: int in range(lines.size()):
			for screen_name: String in LAUNCH_SCREEN_NAMES:
				if lines[index].contains("name = \"%s.storyboard\"" % screen_name):

					lines[index] = lines[index].replace("lastKnownFileType = file;", "lastKnownFileType = file.storyboard;")
					if lines[index].contains("lastKnownFileType = file.storyboard;"):
						found += 1
		if found != LAUNCH_SCREEN_NAMES.size():
			push_error("[IOSBuildHelper] 启动页资源注册不完整: %d" % found)
			return false
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("[IOSBuildHelper] 写启动页资源类型失败: %s" % path)
			return false
		file.store_string("\n".join(lines))
		return true









	func _inject_app_delegate_hook() -> void :
		var mm_path: String = APP_DELEGATE_DIR + "pocket_sort_app_delegate_supplement.mm"
		if not FileAccess.file_exists(mm_path):
			push_warning("[IOSBuildHelper] AppDelegate 补充文件不存在: %s" % mm_path)
			return
		var content: String = FileAccess.get_file_as_string(mm_path)


		content += "\n\n__attribute__((constructor)) static void _pocket_sort_register_app_delegate_supplement(void) {\n    dispatch_async(dispatch_get_main_queue(), ^{\n        _pocket_sort_install_splash_overlay();\n    });\n    NSLog(@\"[PocketSort] AppDelegate supplement registered (splash overlay dispatch)\");\n}\n"








		add_ios_cpp_code(content)
		print("  injected AppDelegate supplement (pocket_sort_app_delegate_supplement.mm + constructor)")






	func _copy_podfile() -> void :
		var src: String = TEMPLATE_DIR + "Podfile"
		if not FileAccess.file_exists(src):
			push_error("[IOSBuildHelper] Podfile 模板不存在: %s" % src)
			return
		var dst: String = _export_path.get_base_dir().path_join("Podfile")
		var content: PackedByteArray = FileAccess.get_file_as_bytes(src)
		var f: FileAccess = FileAccess.open(dst, FileAccess.WRITE)
		if f == null:
			push_error("[IOSBuildHelper] 写 Podfile 失败: %s -> %s, err=%s" % [src, dst, FileAccess.get_open_error()])
			return
		f.store_buffer(content)
		f.close()
		print("[IOSBuildHelper] 已拷贝 Podfile -> %s" % dst)








	func _patch_dummy_cpp_filetype() -> void :
		var pbxproj_path: String = _export_path.path_join("project.pbxproj")
		if not FileAccess.file_exists(pbxproj_path):
			push_error("[IOSBuildHelper] project.pbxproj 不存在: %s" % pbxproj_path)
			return
		var content: String = FileAccess.get_file_as_string(pbxproj_path)
		var objcpp_marker: String = "explicitFileType = sourcecode.cpp.objcpp; path = dummy.cpp;"
		var cpp_marker: String = "lastKnownFileType = sourcecode.cpp.cpp; path = dummy.cpp;"
		if content.contains(objcpp_marker):
			print("[IOSBuildHelper] dummy.cpp 已是 objcpp 类型，跳过 patch")
			return
		if not content.contains(cpp_marker):
			push_error("[IOSBuildHelper] project.pbxproj 中找不到 dummy.cpp 的 lastKnownFileType=sourcecode.cpp.cpp，Godot 模板可能已变化")
			return
		content = content.replace(cpp_marker, objcpp_marker)
		var f: FileAccess = FileAccess.open(pbxproj_path, FileAccess.WRITE)
		if f == null:
			push_error("[IOSBuildHelper] 写 project.pbxproj 失败: %s" % FileAccess.get_open_error())
			return
		f.store_string(content)
		f.close()
		print("[IOSBuildHelper] 已 patch dummy.cpp -> explicitFileType=sourcecode.cpp.objcpp")







	func _inject_info_plist() -> void :
		print("[IOSBuildHelper] _inject_info_plist 开始")

		var json_path: String = TEMPLATE_DIR + "info_plist_patch.json"
		if not FileAccess.file_exists(json_path):
			push_error(("[IOSBuildHelper] info_plist_patch.json 不存在: %s。该文件应跟随仓库分发,"
				+ " 请检查 git 状态。") % json_path)
			return
		var json_str: String = FileAccess.get_file_as_string(json_path)
		var data: Variant = JSON.parse_string(json_str)
		if typeof(data) != TYPE_DICTIONARY:
			push_error("[IOSBuildHelper] info_plist_patch.json 解析失败: %s" % json_path)
			return
		var dict: Dictionary = data

		var plist_path: String = _resolve_info_plist_path()
		print("  [path] target plist  = %s" % plist_path)
		if not FileAccess.file_exists(plist_path):
			push_error(("[IOSBuildHelper] 目标 Info.plist 不存在: %s。请确认 Godot 导出已完成,"
				+ " 且导出路径命名规则未变(预期 <export_dir>/<scheme>/<scheme>-Info.plist)。") % plist_path)
			return

		var success_count: int = 0
		var fail_count: int = 0
		var skip_count: int = 0
		for key: String in dict.keys():
			if key.begins_with("_"):
				skip_count += 1
				continue
			var v: Variant = dict[key]
			if _patch_one_key(plist_path, key, v):
				success_count += 1
			else:
				fail_count += 1


		_strip_empty_unused_usage_descriptions(plist_path)

		var lint_out: Array = []
		var lint_rc: int = OS.execute("plutil", ["-lint", plist_path], lint_out, true)
		if lint_rc != 0:
			push_error("[IOSBuildHelper] plutil -lint 失败,Info.plist 可能已损坏: %s" % plist_path)

		print("[IOSBuildHelper] _inject_info_plist 完成: success=%d fail=%d skip=%d (target=%s)"
			%[success_count, fail_count, skip_count, plist_path])


	const _UNUSED_USAGE_DESCRIPTION_KEYS: Array[String] = [
		"NSCameraUsageDescription", 
		"NSMicrophoneUsageDescription", 
		"NSPhotoLibraryUsageDescription", 
	]

	func _strip_empty_unused_usage_descriptions(plist_path: String) -> void :
		for key: String in _UNUSED_USAGE_DESCRIPTION_KEYS:
			var extract_out: Array = []
			var extract_rc: int = OS.execute("plutil", 
				["-extract", key, "raw", plist_path], extract_out, true)
			if extract_rc != 0:
				continue
			var value: String = _flat_lines(extract_out).strip_edges()
			if value != "" and value != "<NULL>":
				continue
			var rm_out: Array = []
			var rm_rc: int = OS.execute("plutil", 
				["-remove", key, plist_path], rm_out, true)
			if rm_rc == 0:
				print("  ✓ removed empty %s" % key)
			else:
				push_warning("[IOSBuildHelper] plutil -remove %s 失败 rc=%d output=%s"
					%[key, rm_rc, _flat_lines(rm_out)])













	func _patch_entitlements() -> void :
		print("[IOSBuildHelper] _patch_entitlements 开始")

		var ent_path: String = _resolve_entitlements_path()
		var scheme: String = _export_path.get_file().get_basename()
		var ent_relpath: String = "%s/%s.entitlements" % [scheme, scheme]

		if not FileAccess.file_exists(ent_path):
			if not _create_empty_entitlements(ent_path):
				push_error("[IOSBuildHelper] 创建 entitlements 文件失败: %s" % ent_path)
				return
			if not _patch_pbxproj_set_entitlements(ent_relpath):
				push_warning("[IOSBuildHelper] patch pbxproj CODE_SIGN_ENTITLEMENTS 失败")
		else:
			print("  [reuse] entitlements 文件已存在 (Godot 自动生成 / 官方 addon exporter 已创建)")

		if not _inject_aps_environment(ent_path):
			return

		var lint_out: Array = []
		var lint_rc: int = OS.execute("plutil", ["-lint", ent_path], lint_out, true)
		if lint_rc != 0:
			push_error("[IOSBuildHelper] plutil -lint 失败,entitlements 已损坏: %s" % ent_path)
			return

		print("[IOSBuildHelper] _patch_entitlements 完成")























	func _inject_aps_environment(ent_path: String) -> bool:
		var value: String = "production" if _is_release_env else "development"
		var rm_out: Array = []

		var rm_rc: int = OS.execute("plutil", ["-remove", "aps-environment", ent_path], rm_out, true)
		var ins_out: Array = []
		var ins_rc: int = OS.execute("plutil", 
			["-insert", "aps-environment", "-string", value, ent_path], ins_out, true)
		if ins_rc != 0:
			push_error("[IOSBuildHelper] plutil -insert aps-environment 失败 rc=%d output=[%s]"
				%[ins_rc, _flat_lines(ins_out)])
			return false
		print("  ✓ aps-environment = %s (is_release_env=%s, remove rc=%d, insert rc=%d)"
			%[value, _is_release_env, rm_rc, ins_rc])
		return true

	func _resolve_entitlements_path() -> String:
		var xcodeproj_dir: String = _export_path.get_base_dir()
		var scheme: String = _export_path.get_file().get_basename()
		return xcodeproj_dir.path_join(scheme).path_join("%s.entitlements" % scheme)

	func _create_empty_entitlements(path: String) -> bool:
		var dir: String = path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			push_error("[IOSBuildHelper] entitlements 父目录不存在: %s" % dir)
			return false
		var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			push_error("[IOSBuildHelper] 创建 entitlements 文件失败: %s err=%s"
				%[path, FileAccess.get_open_error()])
			return false
		f.store_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
			+ "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
			+ "<plist version=\"1.0\">\n"
			+ "<dict>\n"
			+ "</dict>\n"
			+ "</plist>\n")
		f.close()
		return true

	func _patch_pbxproj_set_entitlements(ent_relpath: String) -> bool:
		var pbxproj_path: String = _export_path.path_join("project.pbxproj")
		if not FileAccess.file_exists(pbxproj_path):
			push_error("[IOSBuildHelper] project.pbxproj 不存在: %s" % pbxproj_path)
			return false
		var content: String = FileAccess.get_file_as_string(pbxproj_path)

		if content.contains("CODE_SIGN_ENTITLEMENTS"):
			return true

		var regex: = RegEx.new()
		var err: int = regex.compile("INFOPLIST_FILE = \"[^\"]+\";")
		if err != OK:
			push_error("[IOSBuildHelper] regex compile 失败 err=%d" % err)
			return false
		var matches: Array = regex.search_all(content)
		if matches.is_empty():
			push_warning("[IOSBuildHelper] project.pbxproj 找不到 INFOPLIST_FILE anchor")
			return false

		var append_str: String = "\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = \"%s\";" % ent_relpath
		for i in range(matches.size() - 1, -1, -1):
			var m: RegExMatch = matches[i]
			content = content.substr(0, m.get_end()) + append_str + content.substr(m.get_end())

		var f: FileAccess = FileAccess.open(pbxproj_path, FileAccess.WRITE)
		if f == null:
			push_error("[IOSBuildHelper] 写 project.pbxproj 失败: %s" % FileAccess.get_open_error())
			return false
		f.store_string(content)
		f.close()
		return true

	func _resolve_info_plist_path() -> String:
		var xcodeproj_dir: String = _export_path.get_base_dir()
		var scheme: String = _export_path.get_file().get_basename()
		return xcodeproj_dir.path_join(scheme).path_join("%s-Info.plist" % scheme)

	func _patch_one_key(plist_path: String, key: String, value: Variant) -> bool:
		var xml: String = _value_to_plist_xml(value)
		var summary: String = _summarize_value(value)

		var rm_out: Array = []
		var rm_rc: int = OS.execute("plutil", ["-remove", key, plist_path], rm_out, true)

		var ins_out: Array = []
		var ins_rc: int = OS.execute("plutil", ["-insert", key, "-xml", xml, plist_path], ins_out, true)
		if ins_rc != 0:
			push_error("[IOSBuildHelper]     ✗ plutil -insert :%s 失败 rc=%d output=[%s] xml_preview=%s"
				%[key, ins_rc, _flat_lines(ins_out), xml.substr(0, 300)])
			return false
		print("    ✓ :%s = %s  (remove rc=%d, insert rc=%d)" % [key, summary, rm_rc, ins_rc])
		return true

	func _summarize_value(v: Variant) -> String:
		var t: int = typeof(v)
		match t:
			TYPE_STRING:
				var s: String = v
				if s.length() <= 60:
					return "\"%s\"" % s
				return "\"%s...\" (string len=%d)" % [s.substr(0, 55), s.length()]
			TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
				return str(v)
			TYPE_ARRAY:
				return "<array len=%d>" % (v as Array).size()
			TYPE_DICTIONARY:
				return "<dict %d keys>" % (v as Dictionary).size()
		return "<%s>" % type_string(t)

	func _flat_lines(lines: Array) -> String:
		return " | ".join(lines).strip_edges()

	func _shell_escape_for_argv(s: String) -> String:
		return s.replace("\\", "\\\\").replace("$", "\\$")

	func _value_to_plist_xml(v: Variant) -> String:
		match typeof(v):
			TYPE_STRING:
				return "<string>%s</string>" % _shell_escape_for_argv(str(v).xml_escape())
			TYPE_INT:
				return "<integer>%d</integer>" % v
			TYPE_FLOAT:
				return "<real>%f</real>" % v
			TYPE_BOOL:
				return "<true/>" if v else "<false/>"
			TYPE_ARRAY:
				var inner: Array[String] = []
				for item: Variant in v:
					inner.append(_value_to_plist_xml(item))
				return "<array>\n%s\n</array>" % "\n".join(inner)
			TYPE_DICTIONARY:
				var inner: Array[String] = []
				for k: String in v.keys():
					inner.append("<key>%s</key>" % k)
					inner.append(_value_to_plist_xml(v[k]))
				return "<dict>\n%s\n</dict>" % "\n".join(inner)
		return "<string></string>"
