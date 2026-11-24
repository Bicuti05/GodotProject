class_name RankListLayout
extends RefCounted


var entries: Array[Dictionary] = []
var rank_indices: Dictionary = {}
var key_indices: Dictionary = {}
var content_height: float = 0.0
var item_count: int = 0


func build(snap: RankSnapshot, has_podium: bool, top_padding: float, bottom_padding: float) -> void :
	entries.clear()
	rank_indices.clear()
	key_indices.clear()
	item_count = 0
	content_height = top_padding
	if snap != null and snap.is_valid():
		for row: Dictionary in snap.rows:
			var rank: int = int(row.get("rank_pos", 0))
			if has_podium and rank <= 3:
				continue
			if rank == snap.downgrade_start_rank and rank > 0:
				_append_banner(RankZoneBanner.Kind.DOWNGRADE, rank, snap.rows.size())
			var index: int = entries.size()
			var key: String = RankItemView.make_row_key(row)
			rank_indices[rank] = index
			key_indices[key] = index
			entries.append({"rank": rank, "key": key, "row": row, 
				"y": content_height, "height": RankItemView.ROW_PITCH, "item_index": item_count})
			item_count += 1
			content_height += RankItemView.ROW_PITCH
			if rank == snap.upgrade_end_rank and rank > 0:
				_append_banner(RankZoneBanner.Kind.UPGRADE, 1, rank)
	content_height += bottom_padding


func _append_banner(kind: RankZoneBanner.Kind, from_rank: int, to_rank: int) -> void :
	entries.append({"rank": -1, "key": "banner:%d" % kind, 
		"kind": kind, "from_rank": from_rank, "to_rank": to_rank, 
		"y": content_height, "height": RankZoneBanner.BANNER_PITCH})
	content_height += RankZoneBanner.BANNER_PITCH


func range_for_scroll(scroll: float, view_height: float, buffer_rows: int = 0) -> Vector2i:
	if entries.is_empty():
		return Vector2i(-1, -1)
	var padding: float = buffer_rows * RankItemView.ROW_PITCH
	var first: int = _first_after(scroll - padding)
	var last: int = first
	var end: float = scroll + view_height + padding
	while last + 1 < entries.size() and float(entries[last + 1].y) < end:
		last += 1
	return Vector2i(first, last)


func _first_after(y: float) -> int:
	var low: int = 0
	var high: int = entries.size()
	while low < high:
		var mid: int = (low + high) / 2
		var entry: Dictionary = entries[mid]
		if float(entry.y) + float(entry.height) <= y:
			low = mid + 1
		else:
			high = mid
	return mini(low, entries.size() - 1)


func scroll_for_rank(rank: int, view_height: float, center_row: bool) -> float:
	var index: int = int(rank_indices.get(rank, -1))
	if index < 0:
		return 0.0
	var y: float = float(entries[index].y)
	if center_row:
		y += RankItemView.ROW_PITCH * 0.5
	return clampf(y - view_height * 0.5, 0.0, maxf(content_height - view_height, 0.0))
