extends SceneTree
# In mỗi màn: valid và solvable (kiểm tra hợp lệ + giải được). Không đo độ khó (xem mục 5).
func _initialize() -> void:
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	for raw: Dictionary in arr:
		var lv := JuiceLevel.from_dict(raw)
		var errs: Array[String] = lv.validate()
		if not errs.is_empty():
			print("LEVEL id=%s valid=false errors=%s" % [raw.get("id", ""), " | ".join(errs)])
			continue
		var search := JuiceSolver.begin_full_search(JuiceRules.make_state(lv), lv)
		var res: int = JuiceSolver.advance_full_search(search, lv, {"node_cap": 4000, "state_cap": 20000})
		print("LEVEL id=%s valid=true solvable=%s expanded=%d" % [
			raw.get("id", ""), ["UNKNOWN", "WINNABLE", "UNWINNABLE"][res], int(search["expanded"])])
	quit()
