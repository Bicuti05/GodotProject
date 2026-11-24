class_name DebugTestRoutes
extends RefCounted

























func register_all(mgr) -> void :
	mgr.register_route("/state", _state)
	mgr.register_route("/node-props", _node_props)
	mgr.register_route("/scene-tree", _scene_tree)
	mgr.register_route("/cmd", _cmd)
	mgr.register_route("/cmd-list", _cmd_list)
	mgr.register_route("/exec", _exec)
	mgr.register_route("/screenshot", _screenshot)
	mgr.register_route("/node-set", _node_set)
	mgr.register_route("/page-show", _page_show)
	mgr.register_route("/page-hide", _page_hide)
	mgr.register_route("/skip-tutorial", _skip_tutorial)

	mgr.register_route("/juice-level", _juice_level)
	mgr.register_route("/juice-move", _juice_move)
	mgr.register_route("/juice-action", _juice_action)
	mgr.register_route("/juice-replay", _juice_replay)





func _state(ctx: DebugApiContext) -> void :
	var pages: Array = SceneManager.get_active_page_names()
	ctx.set_json({
		"result": "success", 
		"pages": pages, 
		"top_page": pages[-1] if not pages.is_empty() else "", 
		"level": UserState.get_current_level(), 
		"strategy": UserState.get_current_strategy(), 
		"coins": UserState.get_coins(), 
		"props": {
			"hint": UserState.get_prop_count("hint"), 
			"undo": UserState.get_prop_count("undo"), 
			"rope": UserState.get_prop_count("rope"), 
		}, 
		"daily_completed_date": UserState.get_daily_completed_date(), 
		"tutorial_done": UserState.is_tutorial_done(), 
		"level_dirty": UserState.is_current_level_dirty(), 
		"level_retried": UserState.is_current_level_retried(), 
		"user_level": UserState.get_user_level(), 
		"user_level_clean_streak": UserState.get_user_level_clean_streak(), 
		"user_level_recent_dirty": UserState.get_user_level_recent_dirty(), 
		"debug_mode": UserState.is_debug_mode(), 
		"session_id": SessionManager.session_id, 
		"session_count": SessionManager.session_count, 
	})




func _node_props(ctx: DebugApiContext) -> void :
	var path: String = ctx.get_query("path")
	if path == "":
		ctx.set_error("path parameter is required")
		return
	var node: Node = _tree().root.get_node_or_null(NodePath(path))
	if node == null:
		ctx.set_error("node not found: %s" % path, 404)
		return
	var out: Dictionary = {}
	var props_raw: String = ctx.get_query("props")
	if props_raw == "":
		for p in ["name", "visible", "modulate", "position", "global_position", "rotation", "scale", "size", "text", "z_index"]:
			if _has_prop(node, p):
				out[p] = _jsonify(node.get(p))
	else:
		for p in props_raw.split(",", false):
			var key: String = p.strip_edges()
			out[key] = _jsonify(node.get(key))
	ctx.set_json({"result": "success", "path": path, "type": node.get_class(), "props": out})



func _scene_tree(ctx: DebugApiContext) -> void :
	var root_path: String = ctx.get_query("root", "/root")
	var depth: int = ctx.get_query_int("depth", 3)
	var root: Node = _tree().root if root_path == "/root" else _tree().root.get_node_or_null(NodePath(root_path))
	if root == null:
		ctx.set_error("node not found: %s" % root_path, 404)
		return
	ctx.set_json({"result": "success", "tree": _dump_node(root, depth)})






func _cmd(ctx: DebugApiContext) -> void :
	var cmd_name: String = ctx.get_query("name")
	if cmd_name == "":
		ctx.set_error("name parameter is required")
		return
	var args: String = ctx.get_query("args")
	var raw: String = cmd_name if args == "" else "%s %s" % [cmd_name, args]

	CheatBus.issue(raw)
	ctx.set_json({"result": "accepted", "name": cmd_name, "args": args})



func _cmd_list(ctx: DebugApiContext) -> void :
	var out: Array = []
	for cmd: CheatCommand in CheatBus.get_commands():
		out.append({
			"name": cmd.name, 
			"label": cmd.label, 
			"category": cmd.category, 
			"default_args": cmd.default_args, 
		})
	ctx.set_json({"result": "success", "commands": out})






















func _exec(ctx: DebugApiContext) -> void :
	var code: String = ctx.get_query("code")
	if code == "":
		ctx.set_error("code parameter is required")
		return





	var body: String = ""
	for line in code.split("\n"):
		body += "    " + line.replace("\t", "    ") + "\n"





	var _has_return: bool = false
	for line in code.split("\n"):
		if line.strip_edges().begins_with("return"):
			_has_return = true
			break
	if not _has_return:
		body += "    return null\n"
	var full_source: String = "extends RefCounted\nfunc _run(page, out: Array) -> Variant:\n" + body
	var script: = GDScript.new()
	script.source_code = full_source
	var err: Error = script.reload()
	if err != OK:



		ctx.set_json({
			"result": "compile_error", 
			"error_code": err, 
			"hint": "check indentation / brackets in source_code below; parse message is in editor Output panel (Parser Error)", 
			"source_code": full_source, 
		}, 400)
		return
	var instance: RefCounted = script.new()
	var out: Array = []
	var value: Variant = await instance._run(_game_page(), out)
	ctx.set_json({"result": "success", "value": _exec_jsonify(value), "out": _exec_jsonify(out)})




func _exec_jsonify(v: Variant) -> Variant:
	match typeof(v):
		TYPE_DICTIONARY:
			var d: Dictionary = {}
			for k in (v as Dictionary).keys():
				d[str(k)] = _exec_jsonify((v as Dictionary)[k])
			return d
		TYPE_ARRAY:
			var arr: Array = []
			for item: Variant in (v as Array):
				arr.append(_exec_jsonify(item))
			return arr
		TYPE_OBJECT:
			return str(v)
		_:
			return _jsonify(v)



func _skip_tutorial(ctx: DebugApiContext) -> void :
	UserState.set_tutorial_done(true)
	ctx.set_json({"result": "success", "tutorial_done": true})





func _juice_move(ctx: DebugApiContext) -> void :
	var page: Node = _game_page()
	if page == null or not page.has_method("debug_try_move"):
		ctx.set_error("game page is not active", 409)
		return
	for key: String in ["src", "j", "dst"]:
		if not ctx.get_query(key).is_valid_int():
			ctx.set_error("%s must be an integer" % key)
			return
	var src: int = ctx.get_query_int("src")
	var j: int = ctx.get_query_int("j")
	var dst: int = ctx.get_query_int("dst")
	page.debug_try_move.bind(src, j, dst).call_deferred()
	ctx.set_json({"result": "accepted", "src": src, "j": j, "dst": dst})


func _juice_action(ctx: DebugApiContext) -> void :
	var action: String = ctx.get_query("action")
	if action not in ["undo", "restart"]:
		ctx.set_error("action must be undo or restart", 400)
		return
	var page: Node = _game_page()
	if page == null or not page.has_method("debug_game_action"):
		ctx.set_error("game page is not active", 409)
		return
	page.debug_game_action.bind(action).call_deferred()
	ctx.set_json({"result": "accepted", "action": action})
























func _screenshot(ctx: DebugApiContext) -> void :
	var img: Image = _tree().root.get_texture().get_image()
	var max_dim: int = ctx.get_query_int("max", 720)
	var longest: int = max(img.get_width(), img.get_height())
	if max_dim > 0 and longest > max_dim:
		var s: float = float(max_dim) / float(longest)
		img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_BILINEAR)
	ctx.set_json({
		"result": "success", 
		"format": "png", 
		"width": img.get_width(), 
		"height": img.get_height(), 
		"base64": Marshalls.raw_to_base64(img.save_png_to_buffer()), 
	})



func _node_set(ctx: DebugApiContext) -> void :
	var path: String = ctx.get_query("path")
	var prop: String = ctx.get_query("prop")
	if path == "" or prop == "":
		ctx.set_error("path and prop are required")
		return
	var node: Node = _tree().root.get_node_or_null(NodePath(path))
	if node == null:
		ctx.set_error("node not found: %s" % path, 404)
		return
	node.set(prop, _parse_value(ctx.get_query("value")))
	ctx.set_json({"result": "success", "path": path, "prop": prop, "value": _jsonify(node.get(prop))})





func _page_show(ctx: DebugApiContext) -> void :
	var page_name: String = ctx.get_query("name")
	if page_name == "home":
		var game: Node = SceneManager.get_page("game")
		if game != null and game.visible:
			game.call_deferred("return_home")
		else:
			_show_home_deferred.call_deferred()
		ctx.set_json({"result": "accepted", "page": "home"})
		return
	if page_name == "":
		ctx.set_error("name parameter is required")
		return
	var params: Dictionary = {}
	var body: String = ctx.get_query("body")
	if body != "":
		var parsed: Variant = JSON.parse_string(body)
		if parsed is Dictionary:
			params = parsed
	var layer: int = int(SceneManager.PAGE_LAYERS.get(page_name, SceneManager.Layer.PAGE))
	var node: Node
	match layer:
		SceneManager.Layer.DIALOG:
			node = SceneManager.show_dlg(page_name, params)
		SceneManager.Layer.DEBUG:
			node = SceneManager.show_debug_panel(page_name)
		_:
			node = SceneManager.show_page(page_name, params)
	ctx.set_json({"result": "success" if node != null else "error", "page": page_name})


func _page_hide(ctx: DebugApiContext) -> void :
	var page_name: String = ctx.get_query("name")
	if page_name == "":
		ctx.set_error("name parameter is required")
		return
	SceneManager.hide_page(page_name)
	ctx.set_json({"result": "success", "page": page_name})




func _juice_replay(ctx: DebugApiContext) -> void :
	if not OS.has_feature("editor"):
		ctx.set_error("juice replay is editor-only", 409)
		return
	var file: String = ctx.get_query("file")
	if file == "":
		ctx.set_error("file parameter is required")
		return
	var params: Dictionary = {"file": file}
	for key: String in ["game_id", "user_id"]:
		if ctx.get_query(key) != "":
			params[key] = ctx.get_query(key)
	SceneManager.show_debug_panel.bind("juice_replay", params).call_deferred()
	ctx.set_json({"result": "accepted", "params": params})
















func _juice_level(ctx: DebugApiContext) -> void :
	if ctx.get_query("clear") != "":
		var cleared: int = JuiceDebugLevel.clear()
		ctx.set_json({"result": "success", "cleared_level": cleared})
		return

	var text: String = ctx.get_query("body")
	var file: String = ctx.get_query("file")
	if text == "" and file != "":
		if not FileAccess.file_exists(file):
			ctx.set_error("file not found: %s" % file)
			return
		text = FileAccess.get_file_as_string(file)
	if text == "":
		ctx.set_error("body or file parameter is required")
		return

	var res: Dictionary = JuiceDebugLevel.load_from_text(
		text, ctx.get_query_int("level", 0), ctx.get_query_int("as", 0))
	if not bool(res["ok"]):
		ctx.set_json({
			"result": "error", 
			"message": String(res["message"]), 
			"errors": res["errors"], 
		}, 400)
		return




	JuiceDebugLevel.enter.bind(int(res["level"])).call_deferred()
	ctx.set_json({
		"result": "success", 
		"message": String(res["message"]), 
		"level": int(res["level"]), 
		"source": "file:%s" % file if file != "" else "body", 
	})




func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree



func _game_page() -> Node:
	var p: Node = SceneManager.get_page("game")
	return p if p != null and p.visible else null






func _dump_node(node: Node, depth: int) -> Dictionary:
	var d: Dictionary = {
		"name": str(node.name), 
		"type": node.get_class(), 
		"path": str(node.get_path()), 
	}
	if node is CanvasItem:
		d["visible"] = node.visible
	if depth > 0 and node.get_child_count() > 0:
		var kids: Array = []
		for c in node.get_children():
			kids.append(_dump_node(c, depth - 1))
		d["children"] = kids
	return d


func _has_prop(node: Node, p: String) -> bool:
	for d in node.get_property_list():
		if String(d.get("name", "")) == p:
			return true
	return false



func _jsonify(v: Variant) -> Variant:
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME:
			return v if typeof(v) != TYPE_STRING_NAME else String(v)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR3, TYPE_VECTOR3I:
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_COLOR:
			return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
		TYPE_RECT2, TYPE_RECT2I:
			return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
		_:
			return str(v)



func _parse_value(raw: String) -> Variant:
	if raw == "":
		return ""
	var v: Variant = str_to_var(raw)
	if v == null and raw != "null":
		return raw
	return v


func _show_home_deferred() -> void :
	await HomeNavigationFlow.run()
