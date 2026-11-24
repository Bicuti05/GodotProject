extends SceneTree


var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void :
	call_deferred("_run")


func _check(ok: bool, label: String) -> void :
	_checks += 1
	if not ok:
		_failures.append(label)
		print("FAIL: ", label)


func _run() -> void :

	var board: Variant = load("res://scripts/gameplay/juice_sort/view/juice_board_view.gd").new()
	var layer: Node2D = Node2D.new()
	root.add_child(layer)
	board._fruit_layer = layer


	board.fade_flowers_out(0.45)
	var natural: Tween = get_processed_tweens().back()
	natural.pause()
	natural.custom_step(0.2)
	_check(layer.modulate.a > 0.0 and layer.modulate.a < 1.0, "通关花层正常渐隐")
	natural.custom_step(0.25)
	_check(is_zero_approx(layer.modulate.a), "通关淡出结束后花层透明")
	board.set_flowers_alpha(1.0)
	_check(is_equal_approx(layer.modulate.a, 1.0), "已完成淡出后新局恢复花层")


	board.fade_flowers_out(0.45)
	var old: Tween = get_processed_tweens().back()
	old.pause()
	old.custom_step(0.2)
	board.set_flowers_alpha(1.0)
	_check( not old.is_valid(), "新局复位取消旧局淡出")
	if old.is_valid():
		old.custom_step(0.5)
	_check(is_equal_approx(layer.modulate.a, 1.0), "旧局剩余动画不覆盖新局Alpha")


	board.fade_flowers_out(0.45)
	var first: Tween = get_processed_tweens().back()
	first.pause()
	first.custom_step(0.1)
	board.fade_flowers_out(0.45)
	var second: Tween = get_processed_tweens().back()
	second.pause()
	_check( not first.is_valid(), "重复淡出取消上一条Alpha动画")
	second.custom_step(0.45)
	_check(is_zero_approx(layer.modulate.a), "替换后的淡出正常完成")
	board.set_flowers_alpha(1.0)
	board.fade_flowers_out(0.45)
	var reset: Tween = get_processed_tweens().back()
	board.set_flowers_alpha(0.65)
	_check( not reset.is_valid() and is_equal_approx(layer.modulate.a, 0.65), 
		"直接设置任意Alpha同样取消旧动画")

	board.free()
	layer.free()
	print("FLOWER_FADE_RESULT: %d checks, %d failures" % [_checks, _failures.size()])
	print("PASS" if _failures.is_empty() else "FAIL")
	quit(0 if _failures.is_empty() else 1)
