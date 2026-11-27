extends SceneTree
# -- in.json out.json shard nshards : valid + solvable with a larger search cap
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	var sh := int(a[2]); var n := int(a[3]); var out: Array = []
	for i in arr.size():
		if i % n != sh: continue
		var raw: Dictionary = arr[i]["raw"]
		var lv := JuiceLevel.from_dict(raw)
		var errs: Array[String] = lv.validate()
		if not errs.is_empty():
			out.append({"uid": arr[i]["uid"], "valid": false, "errors": " | ".join(errs)}); continue
		var search := JuiceSolver.begin_full_search(JuiceRules.make_state(lv), lv)
		var res: int = JuiceSolver.advance_full_search(search, lv, {"node_cap": 60000, "state_cap": 300000})
		out.append({"uid": arr[i]["uid"], "valid": true, "solvable": ["UNKNOWN", "WINNABLE", "UNWINNABLE"][res], "expanded": int(search["expanded"])})
	var f := FileAccess.open(a[1], FileAccess.WRITE); f.store_string(JSON.stringify(out)); f.close()
	quit()
