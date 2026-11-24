@tool
extends RefCounted

class GpmError:
	enum Code{
		NONE = 0, 
		GENERIC, 
		INITIATE_CONNECT_TO_HOST_FAILURE, 
		UNABLE_TO_CONNECT_TO_HOST, 
		UNSUCCESSFUL_REQUEST, 
		MISSING_RESPONSE, 
		UNEXPECTED_STATUS_CODE, 
		GET_REQUEST_FAILURE, 
		FILE_OPEN_FAILURE, 
		PARSE_FAILURE, 
		UNEXPECTED_DATA, 
		NO_PACKAGES, 
		PROCESS_PACKAGES_FAILURE, 
		MISSING_SCRIPT, 
		BAD_SCRIPT_TYPE, 
		SCRIPT_COMPILE_FAILURE, 
	}

	var _error: int
	var _description: String

	func _init(error: int, description: String = "") -> void :
		_error = error
		_description = description

	func _to_string() -> String:
		return "Code: %d\nName: %s\nDescription: %s" % [_error, error_name(), _description]

	func error_code() -> int:
		return _error

	func error_name() -> String:
		return Code.keys()[_error]

	func error_description() -> String:
		return _description


class Result:
	var _value
	var _error: GpmError

	func _init(v) -> void :
		if v is GpmError:
			_error = v
		else:
			_value = v

	func _to_string() -> String:
		return "ERR: %s" % str(_error) if is_err() else "OK: %s" % str(_value)

	func is_ok() -> bool:
		return not is_err()

	func is_err() -> bool:
		return _error != null

	func unwrap():
		return _value

	func unwrap_err() -> GpmError:
		return _error

	func expect(text: String):
		if is_err():
			printerr(text)
			return null
		return _value

	func or_else(val):
		return _value if is_ok() else val

	static func ok(v = null) -> Result:
		return Result.new(v if v != null else OK)

	static func err(error_code: int = 1, description: String = "") -> Result:
		return Result.new(GpmError.new(error_code, description))


class FailedPackages:
	var logs: = []
	var names: = []

	func add(package_name: String, reason: String) -> void :
		logs.append("%s - %s" % [package_name, reason])
		names.append(package_name)

	func get_logs() -> String:
		logs.reverse()
		return "\n".join(PackedStringArray(logs))

	func has_logs() -> bool:
		return not logs.is_empty()


class Hooks:
	var _hooks: = {}

	func add(hook_name: String, advanced_expression: AdvancedExpression) -> void :
		_hooks[hook_name] = advanced_expression

	func run(gpm: Object, hook_name: String):
		return _hooks[hook_name].execute([gpm]) if _hooks.has(hook_name) else null


class AdvancedExpression:
	class AbstractCode:
		var _cache: = []

		func _to_string() -> String:
			return "%s\n%s" % [_get_name(), output()]

		func _get_name() -> String:
			return "AbstractCode"

		static func _build_string(list: Array) -> String:
			return "".join(PackedStringArray(list))

		func tab(times: int = 1) -> AbstractCode:
			for i in times:
				_cache.append("\t")
			return self

		func newline() -> AbstractCode:
			_cache.append("\n")
			return self

		func add(text) -> AbstractCode:
			match typeof(text):
				TYPE_STRING:
					tab()
					_cache.append(text)
					newline()
				TYPE_ARRAY:
					_cache.append_array(text)
				_:
					push_error("Invalid type for add: %s" % str(text))
			return self

		func clear_cache() -> AbstractCode:
			_cache.clear()
			return self

		func output() -> String:
			return _build_string(_cache)

		func raw_data() -> Array:
			return _cache

	class Variable extends AbstractCode:
		func _init(var_name: String, var_value: String = "") -> void :
			_cache.append("var %s = " % var_name)
			if not var_value.is_empty():
				_cache.append(var_value)

		func _get_name() -> String:
			return "Variable"

		func add(text) -> AbstractCode:
			_cache.append(str(text))
			return self

		func output() -> String:
			return "%s\n" % _build_string(_cache)

	class AbstractFunction extends AbstractCode:
		var _function_def: = ""
		var _params: = []

		func _get_name() -> String:
			return "AbstractFunction"

		func _construct_params() -> String:
			return "(%s)" % ",".join(PackedStringArray(_params))

		func add_param(text: String) -> AbstractFunction:
			if _params.has(text):
				push_error("Tried to add duplicate param %s" % text)
			else:
				_params.append(text)
			return self

		func output() -> String:
			return "%s%s" % [_function_def % _construct_params(), _build_string(_cache)]

	class Function extends AbstractFunction:
		func _init(text: String) -> void :
			_function_def = "func %s%s:" % [text, "%s"]
			newline()

		func _get_name() -> String:
			return "Function"

	class Runner extends AbstractFunction:
		func _init() -> void :
			_function_def = "func %s%s:" % [RUN_FUNC, "%s"]
			newline()

		func _get_name() -> String:
			return "Runner"

	const RUN_FUNC: = "__runner__"

	var variables: = []
	var functions: = []
	var runner: = Runner.new()
	var gdscript: GDScript

	func _to_string() -> String:
		return _build_source(variables, functions, runner)

	static func _build_source(v: Array, f: Array, r: Runner) -> String:
		var source: = ""
		for item in v:
			source += item.output()
		for item in f:
			source += item.output()
		source += r.output()
		return source

	static func _create_script(v: Array, f: Array, r: Runner) -> GDScript:
		var s: = GDScript.new()
		s.source_code = _build_source(v, f, r)
		return s

	func add_variable(variable_name: String, variable_value: String = "") -> Variable:
		var variable: = Variable.new(variable_name, variable_value)
		variables.append(variable)
		return variable

	func add_function(function_name: String) -> Function:
		var function: = Function.new(function_name)
		functions.append(function)
		return function

	func add(text: String = "") -> Runner:
		if not text.is_empty():
			runner.add(text)
		return runner

	func add_raw(text: String) -> Runner:
		for line in text.split(";"):
			runner.add(line)
		return runner

	func tab(amount: int = 1) -> Runner:
		runner.tab(amount)
		return runner

	func newline() -> Runner:
		runner.newline()
		return runner

	func compile() -> int:
		gdscript = _create_script(variables, functions, runner)
		return gdscript.reload()

	func execute(params: Array = []):
		return gdscript.new().callv(RUN_FUNC, params)

	func clear() -> void :
		gdscript = null
		variables.clear()
		functions.clear()
		runner = Runner.new()


signal message_logged(text)
signal operation_started(op_name, num_packages)
signal operation_checkpoint_reached(package_name)
signal operation_finished()

const DEFAULT_ERROR: = "Default error"
const REGISTRY: = "https://sdk.lexinshengwen.com"
const REGISTRY_BASE_PATH: = "repository/npm-godot-hosted"
const ADDONS_DIR_FORMAT: = "res://addons/%s"

static func _addon_folder_name(package_name: String) -> String:
	var dot_pos: = package_name.rfind(".")
	var name: = package_name if dot_pos == -1 else package_name.substr(dot_pos + 1)
	return name.replace("-", "_")


const CONNECTING_STATUS: = [
	HTTPClient.STATUS_CONNECTING, 
	HTTPClient.STATUS_RESOLVING, 
]
const SUCCESS_STATUS: = [
	HTTPClient.STATUS_BODY, 
	HTTPClient.STATUS_CONNECTED, 
]

const BASE_HEADERS: = [
	"User-Agent: LexinGodotPackageManager/1.0", 
	"Accept: */*", 
]

static func _build_headers(token: String = "") -> Array:
	var h: = BASE_HEADERS.duplicate()
	if not token.is_empty():
		h.append("Authorization: Basic %s" % token)
	return h

static func _read_npmrc_auth() -> String:
	var home: = OS.get_environment("HOME")
	if home.is_empty():
		home = OS.get_environment("USERPROFILE")
	if home.is_empty():
		return ""
	var file: = FileAccess.open(home.path_join(".npmrc"), FileAccess.READ)
	if file == null:
		return ""

	var auth_lines: = []
	for line in file.get_as_text().split("\n"):
		line = line.strip_edges()
		if ":_auth=" in line or ":_auth =" in line or line.begins_with("_auth"):
			auth_lines.append(line)

	if auth_lines.is_empty():
		push_error("[GPM] 未在 .npmrc 中找到任何 _auth 配置，无法获取 Token")
		return ""

	var target_line: = ""
	if auth_lines.size() == 1:
		target_line = auth_lines[0]
	else:
		for line in auth_lines:
			if "npm-godot-hosted" in line:
				target_line = line
				break
		if target_line.is_empty():
			for line in auth_lines:
				if "npm-unity-hosted" in line:
					target_line = line
					break
		if target_line.is_empty():
			push_error("[GPM] 找到多个 _auth 配置，但未匹配到 npm-godot-hosted 或 npm-unity-hosted，无法获取 Token")
			return ""

	if target_line.is_empty():
		return ""
	var eq_pos: = target_line.find("=")
	if eq_pos == -1:
		return ""
	var value: = target_line.substr(eq_pos + 1).strip_edges()
	if value.begins_with("\"") and value.ends_with("\""):
		value = value.substr(1, value.length() - 2)
	return value


const CONFIG_DIR: = "res://learnings_gpm"
const PACKAGE_FILE: = "res://learnings_gpm/learnings_gpm_manifest.json"
const PackageKeys: = {
	"PACKAGES": "packages", 
	"HOOKS": "hooks", 
	"VERSION": "version", 
	"SCRIPTS": "scripts", 
	"REQUIRED_WHEN": "required_when", 
	"OPTIONAL_WHEN": "optional_when", 
}

const LOCK_FILE: = "res://learnings_gpm/learnings_gpm_manifest.lock"
const LockFileKeys: = {
	"VERSION": "version", 
}

const NpmManifestKeys: = {
	"VERSION": "version", 
	"DIST": "dist", 
	"INTEGRITY": "integrity", 
	"TARBALL": "tarball", 
}

const ValidHooks: = {
	"PRE_UPDATE": "pre_update", 
	"POST_UPDATE": "post_update", 
}


static func _recover_manifest_from_lock(lock_file: Dictionary) -> Dictionary:
	var packages: = {}
	for package_name in lock_file.keys():
		if package_name == "com.learnings.godot.godot-package-manager":
			continue
		var version: String = lock_file[package_name].get(LockFileKeys.VERSION, "")
		if not version.is_empty():
			packages[package_name] = version
	return {PackageKeys.PACKAGES: packages}


static func _recover_manifest_from_addons() -> Dictionary:
	var packages: = {}
	var addons_dir: = DirAccess.open("res://addons")
	if addons_dir == null:
		return {PackageKeys.PACKAGES: packages}
	addons_dir.list_dir_begin()
	var entry: = addons_dir.get_next()
	while entry != "":
		if addons_dir.current_is_dir() and not entry.begins_with("."):
			var pkg_json_path: = "res://addons/%s/package.json" % entry
			if FileAccess.file_exists(pkg_json_path):
				var file: = FileAccess.open(pkg_json_path, FileAccess.READ)
				if file != null:
					var data = JSON.parse_string(file.get_as_text())
					if data is Dictionary:
						var name: String = data.get("name", "")
						var version: String = data.get("version", "")
						if not name.is_empty() and not version.is_empty()\
						and name != "com.learnings.godot.godot-package-manager":
							packages[name] = version
		entry = addons_dir.get_next()
	return {PackageKeys.PACKAGES: packages}


static func _ensure_gdignore() -> void :
	var gdignore_path: = CONFIG_DIR + "/.gdignore"
	if not FileAccess.file_exists(gdignore_path):
		var f: = FileAccess.open(gdignore_path, FileAccess.WRITE)
		if f != null:
			f.store_string("")


func _try_recover_manifest(lock_file: Dictionary) -> Dictionary:
	if not lock_file.is_empty():
		var recovered: = _recover_manifest_from_lock(lock_file)
		var count: int = recovered.get(PackageKeys.PACKAGES, {}).size()
		push_warning("[GPM] manifest 未找到，已从 lock 文件恢复 %d 个包" % count)
		write_config(PACKAGE_FILE, recovered)
		_ensure_gdignore()
		return recovered

	var from_addons: = _recover_manifest_from_addons()
	var packages: Dictionary = from_addons.get(PackageKeys.PACKAGES, {})
	var lock: = {}
	for pkg_name in packages:
		if pkg_name == "com.learnings.godot.godot-package-manager":
			continue
		lock[pkg_name] = {LockFileKeys.VERSION: packages[pkg_name]}
	var count: int = packages.size()
	if count > 0:
		push_warning("[GPM] manifest 和 lock 均未找到，已从 addons 目录扫描到 %d 个包并重建" % count)
	else:
		push_warning("[GPM] manifest 和 lock 均未找到，未找到任何包，已创建空文件")
	write_config(PACKAGE_FILE, from_addons)
	write_config(LOCK_FILE, lock)
	_ensure_gdignore()
	return from_addons


func _read_all_configs() -> Result:

	var lock_file: = {}
	var res: = read_config(LOCK_FILE)
	if res.is_ok():
		lock_file = res.unwrap()

	var package_file: = {}
	res = read_config(PACKAGE_FILE)
	if res.is_ok():
		package_file = res.unwrap()
	elif res.unwrap_err().error_code() == GpmError.Code.FILE_OPEN_FAILURE:
		package_file = _try_recover_manifest(lock_file)
	elif res.unwrap_err().error_code() in [GpmError.Code.PARSE_FAILURE, GpmError.Code.UNEXPECTED_DATA]:
		return res

	return Result.ok([package_file, lock_file])


static func _save_data(data: PackedByteArray, path: String) -> Result:
	var file: = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return Result.err(GpmError.Code.FILE_OPEN_FAILURE, path)
	file.store_buffer(data)
	return Result.ok()



func _send_get_request(host: String, path: String, token: String = "") -> Result:
	var http: = HTTPClient.new()

	var err: = http.connect_to_host(host, 443, TLSOptions.client())
	if err != OK:
		return Result.err(GpmError.Code.INITIATE_CONNECT_TO_HOST_FAILURE, host)

	while http.get_status() in CONNECTING_STATUS:
		http.poll()
		await Engine.get_main_loop().process_frame

	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return Result.err(GpmError.Code.UNABLE_TO_CONNECT_TO_HOST, host)

	err = http.request(HTTPClient.METHOD_GET, "/%s" % path, _build_headers(token))
	if err != OK:
		return Result.err(GpmError.Code.GET_REQUEST_FAILURE, path)

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		await Engine.get_main_loop().process_frame

	if not http.get_status() in SUCCESS_STATUS:
		return Result.err(GpmError.Code.UNSUCCESSFUL_REQUEST, path)

	if http.get_response_code() != 200:
		return Result.err(GpmError.Code.UNEXPECTED_STATUS_CODE, "%s - %d" % [path, http.get_response_code()])

	var body: = PackedByteArray()
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		var chunk: = http.read_response_body_chunk()
		if chunk.size() == 0:
			await Engine.get_main_loop().process_frame
		else:
			body.append_array(chunk)

	return Result.ok(body)


func _request_package_document(package_name: String) -> Result:
	var path: = ("%s/%s" % [REGISTRY_BASE_PATH, package_name]).trim_prefix("/")
	var res = await _send_get_request(REGISTRY, path, _read_npmrc_auth())
	if res.is_err():
		return res
	var document = JSON.parse_string(res.unwrap().get_string_from_utf8())
	if not document is Dictionary:
		return Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - Unexpected json" % package_name)
	return Result.ok(document)


func _request_npm_manifest(package_name: String, package_version: String) -> Result:
	var path: = ("%s/%s/%s" % [REGISTRY_BASE_PATH, package_name, package_version]).trim_prefix("/")
	var res = await _send_get_request(REGISTRY, path, _read_npmrc_auth())
	if res.is_err():
		return res

	var npm_manifest = JSON.parse_string(res.unwrap().get_string_from_utf8())
	if not npm_manifest is Dictionary:
		return Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - Unexpected json" % package_name)

	if not npm_manifest.get(NpmManifestKeys.DIST, {}).has(NpmManifestKeys.TARBALL):
		return Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - manifest missing dist.tarball" % package_name)

	return Result.ok(npm_manifest)


static func _get_files_recursive_inner(original_path: String, path: String) -> Dictionary:
	var result: = {}

	var dir: = DirAccess.open(path)
	if dir == null:
		printerr("Failed to open directory path: %s" % path)
		return result

	dir.include_hidden = true
	dir.list_dir_begin()

	var file_name: = dir.get_next()
	while file_name != "":
		var full_path: = dir.get_current_dir().path_join(file_name)
		if dir.current_is_dir():
			result[path.replace(original_path, "").path_join(file_name)] = _get_files_recursive_inner(original_path, full_path)
		else:
			result[file_name] = full_path
		file_name = dir.get_next()

	return result


static func _get_files_recursive(path: String) -> Dictionary:
	return _get_files_recursive_inner(path, path)


static func _remove_dir_recursive(path: String, delete_base_dir: bool = true, file_dict: Dictionary = {}) -> int:
	var files: = _get_files_recursive(path) if file_dict.is_empty() else file_dict

	var dir: = DirAccess.open(path)
	if dir == null:
		printerr("Failed to open directory for removal: %s" % path)
		return ERR_BUG

	for key in files.keys():
		var file_path: String = path.path_join(key)
		if files[key] is Dictionary:
			if _remove_dir_recursive(file_path, false) != OK:
				printerr("Unable to remove_dir_recursive")
				return ERR_BUG
		if dir.remove(file_path) != OK:
			printerr("Unable to remove file at path: %s" % file_path)
			return ERR_BUG

	if delete_base_dir and dir.remove(path) != OK:
		printerr("Unable to remove file at path: %s" % path)
		return ERR_BUG

	return OK


static func _clean_text(text: String) -> Result:
	var split: PackedStringArray = text.split("\n")
	if split.is_empty():
		return Result.err(GpmError.Code.MISSING_SCRIPT)

	var first_line: = ""
	for line in split:
		first_line = line
		if not first_line.strip_edges().is_empty():
			break

	var whitespace_regex: = RegEx.new()
	whitespace_regex.compile("\\B(\\s+)\\b")
	var regex_match: = whitespace_regex.search(first_line)
	if regex_match == null:
		return Result.ok(split)

	var indent_prefix: String = regex_match.get_string()
	var lines: = PackedStringArray()
	for line in split:
		lines.append(line.trim_prefix(indent_prefix))

	return Result.ok(lines)


static func _build_script(text: String) -> Result:
	var clean_res: = _clean_text(text)
	if clean_res.is_err():
		return clean_res

	var ae: = AdvancedExpression.new()
	ae.runner.add_param("gpm")
	for line in clean_res.unwrap():
		ae.add(line)

	if ae.compile() != OK:
		return Result.err(GpmError.Code.SCRIPT_COMPILE_FAILURE, "_build_script")

	return Result.ok(ae)


static func _compile_hook_value(val, key: String, data: Dictionary) -> Result:
	match typeof(val):
		TYPE_ARRAY:
			return _build_script("\n".join(PackedStringArray(val)))
		TYPE_DICTIONARY:
			var type: String = val.get("type", "")
			var value: String = val.get("value", "")
			if type == "script":
				return _build_script(value)
			elif type == "script_name":
				if not data[PackageKeys.SCRIPTS].has(value):
					return Result.err(GpmError.Code.MISSING_SCRIPT, key)
				return _build_script(data[PackageKeys.SCRIPTS][value])
			else:
				return Result.err(GpmError.Code.BAD_SCRIPT_TYPE, value)
		_:
			return _build_script(val)


static func _parse_hooks(data: Dictionary) -> Result:
	var hooks: = Hooks.new()

	for hook_name in data.get(PackageKeys.HOOKS, {}).keys():
		if not hook_name in ValidHooks.values():
			printerr("Unrecognized hook %s" % hook_name)
			continue

		var res: = _compile_hook_value(data[PackageKeys.HOOKS][hook_name], hook_name, data)
		if res.is_err():
			return Result.err(GpmError.Code.SCRIPT_COMPILE_FAILURE, hook_name)
		hooks.add(hook_name, res.unwrap())

	return Result.ok(hooks)


static func xzf(file_path: String, output_path: String) -> Result:
	var output: = []
	var exit_code: = OS.execute(
		"tar", 
		[
			"xzf", 
			ProjectSettings.globalize_path(file_path), 
			"--strip-components=1", 
			"-C", 
			ProjectSettings.globalize_path(output_path), 
		], 
		output, 
		true
	)

	if exit_code != 0:
		printerr(output)
		return Result.err(GpmError.Code.GENERIC, "Tar failed (exit %d): %s" % [exit_code, output])

	return Result.ok()


func read_config(file_name: String) -> Result:
	if not file_name in [PACKAGE_FILE, LOCK_FILE]:
		return Result.err(GpmError.Code.GENERIC, "Unrecognized file %s" % file_name)

	var file: = FileAccess.open(file_name, FileAccess.READ)
	if file == null:
		return Result.err(GpmError.Code.FILE_OPEN_FAILURE, file_name)

	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		return Result.err(GpmError.Code.PARSE_FAILURE, file_name)
	if not data is Dictionary:
		return Result.err(GpmError.Code.UNEXPECTED_DATA, file_name)
	if file_name == PACKAGE_FILE and data.get(PackageKeys.PACKAGES, {}).is_empty():
		return Result.err(GpmError.Code.NO_PACKAGES, file_name)

	return Result.ok(data)


static func write_config(file_name: String, data: Dictionary) -> Result:
	if not file_name in [PACKAGE_FILE, LOCK_FILE]:
		return Result.err(GpmError.Code.GENERIC, "Unrecognized file %s" % file_name)

	var abs_config_dir: = ProjectSettings.globalize_path(CONFIG_DIR)
	if not DirAccess.dir_exists_absolute(abs_config_dir):
		DirAccess.make_dir_recursive_absolute(abs_config_dir)

	var file: = FileAccess.open(file_name, FileAccess.WRITE)
	if file == null:
		return Result.err(GpmError.Code.FILE_OPEN_FAILURE, file_name)

	file.store_string(JSON.stringify(data, "\t"))
	return Result.ok()


func log_message(text: String) -> void :
	message_logged.emit(text)


func _run_hook(hooks: Hooks, hook_name: String) -> bool:
	var hook_result = hooks.run(self, hook_name)
	if hook_result == false:
		message_logged.emit("Hook %s 返回了 false，已中止" % hook_name)
		return false
	return true




func _resolve_condition_body(body_data, package_name: String, scripts: Dictionary) -> Result:
	if not body_data is Dictionary:
		return Result.ok(body_data)

	var type: String = body_data.get("type", "")
	var value: String = body_data.get("value", "")

	if type == "script":
		return Result.ok(value)
	elif type == "script_name":
		if not scripts.has(value):
			return Result.err(GpmError.Code.MISSING_SCRIPT, "Script does not exist %s" % value)
		return Result.ok(scripts[value])
	else:
		return Result.err(GpmError.Code.BAD_SCRIPT_TYPE, "Invalid type %s" % type)


func _should_skip_package(package_data: Dictionary, package_name: String, package_file: Dictionary) -> Result:
	for condition_key in [PackageKeys.REQUIRED_WHEN, PackageKeys.OPTIONAL_WHEN]:
		if not package_data.has(condition_key):
			continue

		var body_res: = _resolve_condition_body(
			package_data[condition_key], 
			package_name, 
			package_file.get(PackageKeys.SCRIPTS, {})
		)
		if body_res.is_err():
			return body_res

		var body = body_res.unwrap()
		var script_res: = _build_script(body if body is String else "\n".join(PackedStringArray(body)))
		if script_res.is_err():
			return Result.err(GpmError.Code.SCRIPT_COMPILE_FAILURE, "Failed to parse section %s" % condition_key)

		var condition_result = script_res.unwrap().execute([self])
		if typeof(condition_result) != TYPE_BOOL:
			continue

		if condition_key == PackageKeys.REQUIRED_WHEN and condition_result == false:
			message_logged.emit("跳过 %s：%s 条件不满足" % [package_name, condition_key])
			return Result.ok(true)
		if condition_key == PackageKeys.OPTIONAL_WHEN and condition_result == true:
			message_logged.emit("跳过 %s：%s 条件已满足" % [package_name, condition_key])
			return Result.ok(true)

	return Result.ok(false)


func _process_one_package(package_name: String, package_version: String, dir_name: String, out: Dictionary) -> void :
	operation_checkpoint_reached.emit(package_name)

	var res = await _request_npm_manifest(package_name, package_version)
	if not res or res.is_err():
		out[package_name] = res if res else Result.err(GpmError.Code.GENERIC, DEFAULT_ERROR)
		return

	var npm_manifest: Dictionary = res.unwrap()

	var npm_version: String = npm_manifest.get(NpmManifestKeys.VERSION, "")
	if npm_version.is_empty():
		out[package_name] = Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - npm manifest 缺少 version 字段" % package_name)
		return
	log_message("[%s] Manifest 解析成功 — 版本: %s" % [package_name, npm_version])


	var dist: Dictionary = npm_manifest.get(NpmManifestKeys.DIST, {})
	var tarball_url: String = dist.get(NpmManifestKeys.TARBALL, "")
	if tarball_url.is_empty():
		out[package_name] = Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - npm manifest 缺少 dist.tarball 字段" % package_name)
		return

	var tarball_file: String = tarball_url.get_file()
	if tarball_file.is_empty():
		out[package_name] = Result.err(GpmError.Code.UNEXPECTED_DATA, "%s - 无法从 tarball URL 解析文件名" % package_name)
		return

	var tarball_path: String = tarball_url.replace(REGISTRY, "").trim_prefix("/")
	res = await _send_get_request(REGISTRY, tarball_path, _read_npmrc_auth())
	if not res or res.is_err():
		out[package_name] = res if res else Result.err(GpmError.Code.GENERIC, DEFAULT_ERROR)
		return

	var download_location: String = ADDONS_DIR_FORMAT % tarball_file
	res = _save_data(res.unwrap(), download_location)
	if not res or res.is_err():
		out[package_name] = res if res else Result.err(GpmError.Code.GENERIC, DEFAULT_ERROR)
		return


	var dir: = DirAccess.open("res://")
	if dir == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(download_location))
		out[package_name] = Result.err(GpmError.Code.GENERIC, "无法打开 res:// 目录")
		return

	if DirAccess.open(dir_name) != null:
		if _remove_dir_recursive(ProjectSettings.globalize_path(dir_name)) != OK:
			dir.remove(download_location)
			out[package_name] = Result.err(GpmError.Code.GENERIC, "Unable to remove old files")
			return

	if dir.make_dir_recursive(dir_name) != OK:
		dir.remove(download_location)
		out[package_name] = Result.err(GpmError.Code.GENERIC, "Unable to create directory")
		return

	res = xzf(download_location, dir_name)
	if not res or res.is_err():
		dir.remove(download_location)
		out[package_name] = res if res else Result.err(GpmError.Code.GENERIC, DEFAULT_ERROR)
		return

	dir.remove(download_location)
	out[package_name] = Result.ok(npm_version)


func update(force: bool = false) -> Result:
	var manifest_existed: = FileAccess.file_exists(PACKAGE_FILE)
	var res: = _read_all_configs()
	if not res or res.is_err():
		var err_code: int = res.unwrap_err().error_code() if res else GpmError.Code.GENERIC
		if err_code == GpmError.Code.PARSE_FAILURE:
			log_message("[GPM错误] manifest.json 不是合法的 JSON，请检查格式后重试，本次更新已取消")
		elif err_code == GpmError.Code.UNEXPECTED_DATA:
			log_message("[GPM错误] manifest.json 根节点必须是 {} 字典格式，本次更新已取消")
		return res if res else Result.err(GpmError.Code.GENERIC, "Unable to read configs")
	if not manifest_existed and FileAccess.file_exists(PACKAGE_FILE):
		log_message("[GPM警告] manifest.json 未找到，已自动恢复，请在编辑器中确认内容是否正确")

	var configs: Array = res.unwrap()
	var package_file: Dictionary = configs[0]
	var lock_file: Dictionary = configs[1]

	res = _parse_hooks(package_file)
	if res.is_err():
		return res
	var hooks: Hooks = res.unwrap()

	if not _run_hook(hooks, ValidHooks.PRE_UPDATE):
		return Result.ok()

	var failed: = FailedPackages.new()


	var to_update: Array = []
	for package_name in package_file.get(PackageKeys.PACKAGES, {}).keys():
		if package_name == "com.learnings.godot.godot-package-manager":
			continue
		var package_data = package_file[PackageKeys.PACKAGES][package_name]
		var package_version: = ""
		var dir_name: String = ADDONS_DIR_FORMAT % _addon_folder_name(package_name)

		if package_data is Dictionary:
			package_version = package_data.get(PackageKeys.VERSION, "")
			if package_version.is_empty():
				failed.add(package_name, "Missing version")
				continue

			var skip_res: = _should_skip_package(package_data, package_name, package_file)
			if skip_res.is_err():
				failed.add(package_name, skip_res.unwrap_err().error_description())
				continue
			if skip_res.unwrap() == true:
				continue
		else:
			package_version = package_data

		if not force and DirAccess.open(dir_name) != null and lock_file.has(package_name):
			var lock_version: String = lock_file[package_name].get(LockFileKeys.VERSION, "")
			if lock_version == package_version:
				continue

		to_update.append({"name": package_name, "version": package_version, "dir_name": dir_name})

	if to_update.is_empty():
		log_message("无包需要更新")
		return Result.ok()

	operation_started.emit("update", to_update.size())


	var download_out: = {}
	for pkg in to_update:
		_process_one_package(pkg["name"], pkg["version"], pkg["dir_name"], download_out)


	while download_out.size() < to_update.size():
		await Engine.get_main_loop().process_frame


	for pkg in to_update:
		var pkg_name: String = pkg["name"]
		var pkg_result: Result = download_out.get(pkg_name)
		if not pkg_result or pkg_result.is_err():
			failed.add(pkg_name, pkg_result.unwrap_err().to_string() if pkg_result else DEFAULT_ERROR)
		else:
			lock_file[pkg_name] = {LockFileKeys.VERSION: pkg_result.unwrap()}

	var manifest_packages: Dictionary = package_file.get(PackageKeys.PACKAGES, {})


	const SELF_PKG: = "com.learnings.godot.godot-package-manager"
	if manifest_packages.erase(SELF_PKG):
		write_config(PACKAGE_FILE, package_file)
		log_message("[GPM] 已自动从 manifest 中移除 %s" % SELF_PKG)
	lock_file.erase(SELF_PKG)

	var to_remove: = []
	for locked_name in lock_file.keys():
		if not manifest_packages.has(locked_name):
			to_remove.append(locked_name)

	for locked_name in to_remove:
		if locked_name == "com.learnings.godot.godot-package-manager":
			continue
		var dir_name: String = ADDONS_DIR_FORMAT % _addon_folder_name(locked_name)
		log_message("删除 %s（已从 Manifest 中移除）" % locked_name)
		if DirAccess.open(dir_name) != null:
			if _remove_dir_recursive(ProjectSettings.globalize_path(dir_name)) != OK:
				failed.add(locked_name, "Unable to remove directory")
				continue
		lock_file.erase(locked_name)

	operation_finished.emit()

	if not _run_hook(hooks, ValidHooks.POST_UPDATE):
		return Result.ok()

	res = write_config(LOCK_FILE, lock_file)
	if not res or res.is_err():
		return res if res else Result.err(GpmError.Code.GENERIC, "Unable to write lock file")

	if failed.has_logs():
		return Result.err(GpmError.Code.PROCESS_PACKAGES_FAILURE, failed.get_logs())

	return Result.ok()
