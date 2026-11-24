@tool
extends Control

var plugin
var gpm
var target_version: String

const SELF_PKG: = "com.learnings.godot.godot-package-manager"
const SELF_DIR: = "res://addons/godot_package_manager"
const SELF_DIR_TMP: = "res://addons/godot_package_manager_updating_tmp"

@onready var _completion_dialog: AcceptDialog = $CompletionDialog


func _ready() -> void :
	_completion_dialog.confirmed.connect(queue_free)
	_completion_dialog.canceled.connect(queue_free)


func start() -> void :
	_run()


func _fail(reason: String) -> void :
	print("[GPM Updater] 更新失败：", reason)
	_completion_dialog.title = "更新失败"
	_completion_dialog.dialog_text = "更新失败：%s" % reason
	_completion_dialog.popup_centered()


func _run() -> void :

	print("[GPM Updater] 正在获取 v%s 的下载信息..." % target_version)
	var res = await gpm._request_npm_manifest(SELF_PKG, target_version)
	if res.is_err():
		_fail("下载失败，当前插件未受影响。\n详情：%s" % res.unwrap_err().to_string())
		return

	var tarball_url: String = res.unwrap().get("dist", {}).get("tarball", "")
	if tarball_url.is_empty():
		_fail("下载失败，当前插件未受影响。\n详情：无法获取 tarball 地址")
		return


	print("[GPM Updater] 正在下载 v%s..." % target_version)
	var tarball_path: = tarball_url.replace(gpm.REGISTRY, "").trim_prefix("/")
	var dl_res = await gpm._send_get_request(gpm.REGISTRY, tarball_path, gpm._read_npmrc_auth())
	if dl_res.is_err():
		_fail("下载失败，当前插件未受影响。\n详情：%s" % dl_res.unwrap_err().to_string())
		return


	var tarball_file: String = tarball_url.get_file()
	var download_location: = "res://addons/%s" % tarball_file
	var save_res = gpm._save_data(dl_res.unwrap(), download_location)
	if save_res.is_err():
		_fail("下载失败，当前插件未受影响。\n详情：%s" % save_res.unwrap_err().to_string())
		return


	var abs_tmp_dir: = ProjectSettings.globalize_path(SELF_DIR_TMP)
	if DirAccess.open(SELF_DIR_TMP) != null:
		gpm._remove_dir_recursive(abs_tmp_dir)


	print("[GPM Updater] 正在解压新版本...")
	DirAccess.make_dir_recursive_absolute(abs_tmp_dir)
	var xzf_res = gpm.xzf(download_location, SELF_DIR_TMP)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(download_location))
	if xzf_res.is_err():
		_fail("解压失败，当前插件未受影响。\n详情：%s" % xzf_res.unwrap_err().to_string())
		return


	print("[GPM Updater] 正在删除旧版本...")
	var abs_self_dir: = ProjectSettings.globalize_path(SELF_DIR)
	if DirAccess.open(SELF_DIR) != null:
		if gpm._remove_dir_recursive(abs_self_dir) != OK:
			gpm._remove_dir_recursive(abs_tmp_dir)
			_fail("删除旧版本目录失败")
			return


	var addons_dir: = DirAccess.open(ProjectSettings.globalize_path("res://addons"))
	if addons_dir == null or addons_dir.rename("godot_package_manager_updating_tmp", "godot_package_manager") != OK:
		_fail("无法将临时目录重命名为 godot_package_manager，新版本文件保留在 godot_package_manager_updating_tmp")
		return


	print("[GPM Updater] 正在重启插件...")
	var ei = plugin.get_editor_interface()
	ei.set_plugin_enabled("godot_package_manager", false)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	ei.set_plugin_enabled("godot_package_manager", true)


	_completion_dialog.dialog_text = "Godot Package Manager 已成功更新到 v%s！" % target_version
	_completion_dialog.popup_centered()
