class_name RankFinishMotion
extends RefCounted



const CURVES: AnimationLibrary = preload("res://scripts/gameplay/rank/view/motion/source_curves.tres")
const UP_SEC: float = 0.23333333
const ROW_PITCH: float = 200.0
const FLYOUT_PX: float = 936.0
const HANDOFF_PX: float = 74.0
const SWAP_SCORE_GAP_SEC: float = 1.7667 - 1.6333

var _tracks: Dictionary = {}


func _init() -> void :

	for name: StringName in [&"row_Rise_Up", &"podium_Sweep1", &"podium_Sweep2", &"podium_Sweep3"]:
		var animation: Animation = CURVES.get_animation(name)
		for index: int in animation.get_track_count():
			_tracks[str(name) + "/" + str(animation.track_get_path(index))] = {"animation": animation, "index": index}


func curve(name: String, path: String, time: float, fallback: Variant) -> Variant:
	var track: Dictionary = _tracks.get(name + "/" + path, {})
	if track.is_empty():
		return fallback
	var animation: Animation = track.animation
	var index: int = int(track.index)
	if animation.track_get_type(index) == Animation.TYPE_BEZIER:
		return animation.bezier_track_interpolate(index, time)
	return animation.value_track_interpolate(index, time)


static func build(old_rank: int, new_rank: int) -> Dictionary:
	if old_rank > 3:
		var slots: int = maxi(old_rank - 4, 0)
		var rise_sec: float = clampf(minf(0.15 * slots, 1.0 + 0.05 * slots), 0.3, 3.0) if slots > 0 else 0.0
		var speed: float = slots * ROW_PITCH / rise_sec if slots > 0 else ROW_PITCH / 0.15
		var fly_at: float = UP_SEC + 0.3 + rise_sec
		var occupant_at: float = fly_at + HANDOFF_PX / speed
		var winner_at: float = occupant_at + 0.167
		return {"branch": "enter_top3", "old_rank": old_rank, "new_rank": new_rank, 
			"slots": slots, "rise_at": UP_SEC + 0.3, "rise_sec": rise_sec, 
			"fly_at": fly_at, "fly_sec": FLYOUT_PX / speed, 
			"occupant_at": occupant_at, "winner_at": winner_at, 
			"sweep_at": winner_at + 0.1, "commit_at": winner_at + 0.5, 
			"vibrate_at": winner_at + 0.5, "duration": winner_at + 0.667}
	var lift_at: float = SWAP_SCORE_GAP_SEC
	return {"branch": "podium_swap", "old_rank": old_rank, "new_rank": new_rank, 
		"lift_at": lift_at, "fly_at": lift_at + 0.3, "mid_at": lift_at + 0.6, 
		"land_at": lift_at + 0.7333, "sweep_at": lift_at + 0.4667, 
		"commit_at": lift_at + 0.6, "vibrate_at": lift_at + 0.7333, 
		"duration": lift_at + 0.9}



static func overtaken_count(plan: Dictionary, time: float) -> int:
	var slots: int = int(plan.slots)
	var passed: int = mini(slots, floori(segment(time, plan.rise_at, plan.fly_at) * (slots + 1)))
	var podium_steps: int = 4 - int(plan.new_rank)
	if time >= float(plan.fly_at):
		passed += mini(podium_steps, floori(segment(time, plan.fly_at, plan.winner_at) * (podium_steps + 1)))
	return passed


func sample(plan: Dictionary, time: float) -> Dictionary:
	var result: Dictionary = {"row_scale": Vector2.ONE, "rise_progress": 0.0, 
		"flyout_progress": 0.0, "arrow_alpha": 0.0, "mount_scale": 1.0, 
		"flyer_progress": Vector2.ZERO, "flyer_above": 0.0, "flyer_scale": 1.0}
	if plan.branch == "enter_top3":
		var up_time: float = clampf(time, 0.0, UP_SEC)
		result.row_scale = Vector2(curve("row_Rise_Up", "Root:scale:x", up_time, 1.0), 
			curve("row_Rise_Up", "Root:scale:y", up_time, 1.0))
		result.arrow_alpha = maxf(0.0, 1.0 - time / 0.5) if time < UP_SEC else 1.0
		result.rise_progress = segment(time, plan.rise_at, plan.fly_at) if plan.slots > 0 else 1.0
		result.flyout_progress = segment(time, plan.fly_at, plan.fly_at + plan.fly_sec)
		return result
	if time >= plan.lift_at:
		result.mount_scale = lerpf(1.0, 0.85, segment(time, plan.lift_at, plan.lift_at + 0.2)) if time < plan.lift_at + 0.2 else lerpf(0.85, 1.0, segment(time, plan.lift_at + 0.2, plan.fly_at))
	if time >= plan.fly_at and time < plan.mid_at:
		var progress: float = segment(time, plan.fly_at, plan.mid_at)
		result.flyer_progress = Vector2(bezier(progress, Vector4(0.389, 0.25, 1.0, 1.0)), 
			bezier(progress, Vector4(0.0, 0.0, 0.667, 1.0)))
		result.flyer_above = 85.0
		result.flyer_scale = lerpf(1.0, 1.2, bezier(progress, Vector4(0.6667, 0.0, 0.3333, 1.0)))
	elif time >= plan.mid_at:
		var progress: float = bezier(segment(time, plan.mid_at, plan.land_at), Vector4(0.75, 0.0, 1.0, 1.0))
		result.flyer_progress = Vector2.ONE
		result.flyer_above = 85.0 * (1.0 - progress)
		result.flyer_scale = lerpf(1.2, 0.9, progress) if time < plan.land_at else lerpf(0.9, 1.0, 
			bezier(segment(time, plan.land_at, plan.duration), Vector4(0.0198, 0.0, 1.0, 1.0)))
	return result


static func winner(age: float, rest_y: float) -> Vector2:
	if age < 0.4:
		var progress: float = pow(clampf(age / 0.4, 0.0, 1.0), 2.0)
		return Vector2(lerpf(rest_y - 300.0, rest_y - 50.0, progress), lerpf(0.9, 1.2, progress))
	if age < 0.5:
		var progress: float = clampf((age - 0.4) / 0.1, 0.0, 1.0)
		return Vector2(lerpf(rest_y - 50.0, rest_y, (1.0 - cos(PI * progress)) * 0.5), 
			lerpf(1.2, 0.95, 1.0 - pow(1.0 - progress, 2.0)))
	var progress: float = clampf((age - 0.5) / 0.167, 0.0, 1.0)
	return Vector2(rest_y, lerpf(0.95, 1.05, 1.0 - pow(1.0 - progress, 2.0)))


static func segment(time: float, start: float, end: float) -> float:
	return clampf((time - start) / maxf(1e-05, end - start), 0.0, 1.0)


static func bezier(progress: float, handles: Vector4) -> float:
	if progress <= 0.0 or progress >= 1.0:
		return clampf(progress, 0.0, 1.0)
	var low: float = 0.0
	var high: float = 1.0
	var parameter: float = 0.0
	for _index: int in 24:
		parameter = (low + high) * 0.5
		var inverse: float = 1.0 - parameter
		var x: float = 3.0 * inverse * inverse * parameter * handles.x + 3.0 * inverse * parameter * parameter * handles.z + pow(parameter, 3.0)
		if x < progress:
			low = parameter
		else:
			high = parameter
	var inverse: float = 1.0 - parameter
	return 3.0 * inverse * inverse * parameter * handles.y + 3.0 * inverse * parameter * parameter * handles.w + pow(parameter, 3.0)
