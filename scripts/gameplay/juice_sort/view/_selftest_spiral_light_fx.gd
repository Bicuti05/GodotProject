extends SceneTree





const FX_SCENE: PackedScene = preload("res://scripts/gameplay/juice_sort/view/spiral_light_fx.tscn")
const STEP: = 1.0 / 60.0
const POT_CENTER: = Vector2(300.0, 1000.0)
const POT_SIZE: = Vector2(240.0, 245.0)

var _failures: Array[String] = []
var _dst: Vector2 = Vector2(540.0, 200.0)


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	var fx: SpiralLightFx = FX_SCENE.instantiate() as SpiralLightFx
	root.add_child(fx)
	fx.set_process(false)
	_check_climb(fx)
	_check_beam(fx)
	_check_reuse_and_cancel(fx)
	_check_rope(fx)
	fx.queue_free()
	if _failures.is_empty():
		print("SPIRAL_LIGHT_FX_SELFTEST PASS")
		quit(0)
	else:
		for f: String in _failures:
			printerr("FAIL: " + f)
		quit(1)


func _check(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)


func _dst_now() -> Vector2:
	return _dst


func _start(fx: SpiralLightFx) -> void :
	fx.start(POT_CENTER, SpiralLightFx.pot_cfg(POT_SIZE), _dst_now)


func _heads(fx: SpiralLightFx) -> Array:
	return fx.get("_heads") as Array



func _step_to(fx: SpiralLightFx, t: float) -> void :
	while fx.is_running():
		var left: float = t - float(fx.get("_t"))
		if left <= 0.0:
			return
		fx._advance(minf(STEP, left))


func _check_climb(fx: SpiralLightFx) -> void :
	_start(fx)
	var cfg: SpiralLightFx.Cfg = SpiralLightFx.pot_cfg(POT_SIZE)
	_check(fx.is_running() and fx.visible, "起播后可见并运行")
	var hs: Array = _heads(fx)
	_check(hs.size() == 2, "两颗光点")
	_check(is_zero_approx(hs[0].alpha) and is_zero_approx(hs[1].alpha), "climb_start 前光点不可见")

	_step_to(fx, (cfg.climb_start + cfg.climb_end) * 0.5)
	var a: Vector2 = hs[0].pos - POT_CENTER
	var b: Vector2 = hs[1].pos - POT_CENTER
	_check(absf(a.x + b.x) < 0.5, "两颗光点水平对称(相差半圈) a=%s b=%s" % [a, b])
	_check(absf(hs[0].depth + hs[1].depth) < 0.01, "两颗光点一前一后")
	var saw_back: = [false, false]
	var y_prev: float = INF
	var monotonic: = true
	while float(fx.get("_t")) < cfg.climb_end - STEP:
		fx._advance(STEP)
		for i in 2:
			if hs[i].depth < -0.5:
				saw_back[i] = true
		var y: float = (hs[0].pos.y + hs[1].pos.y) * 0.5
		if y > y_prev + 0.01:
			monotonic = false
		y_prev = y
	_check(saw_back[0] and saw_back[1], "两颗光点都绕到过盆背后")
	_check(monotonic, "光点整体只往上爬")

	_step_to(fx, cfg.climb_end - 0.001)
	var top_y: float = POT_CENTER.y + cfg.top_dy
	_check(absf(hs[0].pos.y - top_y) < 12.0, "停顿结束时爬到盆口 y=%.1f top=%.1f" % [hs[0].pos.y, top_y])
	_check(absf(hs[0].depth) < 0.2 and absf(hs[1].depth) < 0.2, "到盆口时两颗分居左右侧")
	_check(signf(hs[0].pos.x - POT_CENTER.x) != signf(hs[1].pos.x - POT_CENTER.x), "两颗光点在盆口左右各一")
	var before: Vector2 = hs[0].pos
	fx.follow(POT_CENTER + Vector2(0.0, -50.0))
	fx._advance(0.0)
	_check(absf((hs[0].pos - before).y + 50.0) < 1.0, "follow() 让光点随盆心上浮")


func _check_beam(fx: SpiralLightFx) -> void :
	var cfg: SpiralLightFx.Cfg = SpiralLightFx.pot_cfg(POT_SIZE)
	var hs: Array = _heads(fx)
	_step_to(fx, cfg.climb_end + cfg.beam_dur * 0.5)
	var mid: Vector2 = hs[0].pos
	_check( not hs[0].attached, "光束段光带不再跟随花盆")
	_dst = Vector2(800.0, 200.0)
	_step_to(fx, cfg.climb_end + cfg.beam_dur)
	_check(hs[0].pos.distance_to(_dst) < 1.0 and hs[1].pos.distance_to(_dst) < 1.0, 
		"光束到达重取后的终点 %s / %s" % [hs[0].pos, hs[1].pos])
	_check(mid.distance_to(_dst) > 50.0, "光束中途仍在路上")
	var n_trail: int = (hs[0].offs as PackedVector2Array).size()
	_check(n_trail >= 4, "光束段光带被拉长(采样点 %d)" % n_trail)
	var done: = {"v": false}
	fx.finished.connect( func() -> void : done.v = true, CONNECT_ONE_SHOT)
	_step_to(fx, fx.total_duration() + 0.05)
	_check(done.v and not fx.is_running() and not fx.visible, "播完发 finished 并隐藏")
	_dst = Vector2(540.0, 200.0)


func _check_reuse_and_cancel(fx: SpiralLightFx) -> void :
	_start(fx)
	var hs: Array = _heads(fx)
	_check((hs[0].offs as PackedVector2Array).size() <= 1 and (hs[1].offs as PackedVector2Array).size() <= 1, 
		"复用重新起播不残留上一次的光带")
	_step_to(fx, SpiralLightFx.POT_CLIMB_END * 0.5)
	_check((hs[0].offs as PackedVector2Array).size() > 0, "上爬中有光带")
	var fired: = {"v": false}
	fx.finished.connect( func() -> void : fired.v = true, CONNECT_ONE_SHOT)
	fx.stop()
	_check( not fx.is_running() and not fx.visible, "stop() 立即停播隐藏")
	_check((hs[0].offs as PackedVector2Array).is_empty() and (hs[1].offs as PackedVector2Array).is_empty(), 
		"stop() 清空光带")
	fx._advance(1.0)
	_check( not fired.v, "取消不发 finished")
	for c: Dictionary in fx.finished.get_connections():
		fx.finished.disconnect(c["callable"])
	for d: CPUParticles2D in [fx.get_node("Front/Dust0"), fx.get_node("Front/Dust1")]:
		_check( not d.emitting, "取消后金粉停发")
		_check( not d.local_coords, "金粉留在出生点(不跟光点走)")



func _check_rope(fx: SpiralLightFx) -> void :
	var top_y: = 300.0
	var bottom_y: = 900.0
	var mouth: = Vector2(400.0, 120.0)
	var cfg: SpiralLightFx.Cfg = SpiralLightFx.rope_cfg(top_y, bottom_y, 230.0, 91)
	var center: = Vector2(400.0, (top_y + bottom_y) * 0.5)
	fx.start(center, cfg, func() -> Vector2: return mouth)
	_check((fx.get_node("Front") as Node2D).z_index == 91, "前层 z 按预设设置")
	_check(fx.climb_y() > bottom_y, "起点在最下那朵花之下")
	var hs: Array = _heads(fx)
	var y_prev: float = INF
	var monotonic: = true
	var crossed: Array[float] = []
	var flower_ys: Array[float] = [900.0, 700.0, 500.0, 300.0]
	while float(fx.get("_t")) < cfg.climb_end:
		fx._advance(STEP)
		var y: float = fx.climb_y()
		if y > y_prev + 0.01:
			monotonic = false
		for fy: float in flower_ys:
			if y_prev > fy and y <= fy:
				crossed.append(float(fx.get("_t")))
		y_prev = y
	_check(monotonic, "climb_y() 单调上行")
	_check(crossed.size() == 4, "光点依次越过 4 朵花(%d)" % crossed.size())
	_check(fx.climb_y() < top_y, "爬完时高于最上那朵花")
	_step_to(fx, cfg.climb_end + cfg.beam_dur)
	_check(hs[0].pos.distance_to(mouth) < 1.0 and hs[1].pos.distance_to(mouth) < 1.0, "光束射进盆口")
	_step_to(fx, fx.total_duration() + 0.05)
	_check( not fx.is_running(), "花串版播完收尾")
