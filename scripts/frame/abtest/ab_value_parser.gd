extends RefCounted
class_name AbValueParser










const INF: int = 1 << 30





static func parse_day_segments(s: String) -> Array:
	var out: Array = []
	for raw: String in s.strip_edges().split(",", false):
		var body: String = raw.strip_edges().trim_prefix("[").trim_suffix("]").strip_edges()
		var cv: PackedStringArray = body.split(":")
		if cv.size() != 2:
			continue
		var days: PackedStringArray = cv[0].split("_")
		if days.size() != 2:
			continue
		var lo_s: String = days[0].strip_edges()
		var hi_s: String = days[1].strip_edges()
		var val_s: String = cv[1].strip_edges()
		if not lo_s.is_valid_int() or not val_s.is_valid_int():
			continue
		if hi_s != "inf" and not hi_s.is_valid_int():
			continue
		var hi: int = INF if hi_s == "inf" else hi_s.to_int()
		out.append({"lo": lo_s.to_int(), "hi": hi, "val": val_s.to_int()})
	return out


static func lookup_segment(segments: Array, day: int, fallback: int) -> int:
	for seg: Dictionary in segments:
		if day >= int(seg["lo"]) and day <= int(seg["hi"]):
			return int(seg["val"])
	return fallback





static func parse_step_rules(s: String) -> Array:
	var out: Array = []
	for raw: String in s.strip_edges().split(",", false):
		var parts: PackedStringArray = raw.strip_edges().split("_")
		if parts.size() != 3:
			continue
		var lo_s: String = parts[0].strip_edges()
		var hi_s: String = parts[1].strip_edges()
		var c_s: String = parts[2].strip_edges()
		if not lo_s.is_valid_int() or not c_s.is_valid_float():
			continue
		if hi_s != "inf" and not hi_s.is_valid_int():
			continue
		var hi: int = INF if hi_s == "inf" else hi_s.to_int()
		out.append({"lo": lo_s.to_int(), "hi": hi, "coef": c_s.to_float()})
	return out


static func lookup_rule(rules: Array, level: int) -> float:
	for r: Dictionary in rules:
		if level >= int(r["lo"]) and level <= int(r["hi"]):
			return float(r["coef"])
	return 1.0
