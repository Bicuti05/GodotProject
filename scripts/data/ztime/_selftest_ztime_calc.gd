extends SceneTree










const C = preload("res://scripts/data/ztime/ztime_calc.gd")

var _failures: Array[String] = []


func _initialize() -> void :
	_test_weights()
	_test_bucket()
	_test_negative_is_zero()
	_test_bad_divisor()
	_finish()



func _test_weights() -> void :
	var raw: float = C.raw_score(120000, 1, 2, 1, 1, 4, 3)
	_expect(is_equal_approx(raw, 190.0 / 12.0), "raw 应为 190/12，实际 %f" % raw)
	_expect(C.bucket(raw) == 5, "15.83 → 16 → 封顶 5，实际 %d" % C.bucket(raw))


func _test_bucket() -> void :
	_expect(C.bucket(3.2) == 4, "3.2 → 4，实际 %d" % C.bucket(3.2))
	_expect(C.bucket(4.0) == 4, "4 整数不进位，实际 %d" % C.bucket(4.0))
	_expect(C.bucket(4.1) == 5, "4.1 → 5，实际 %d" % C.bucket(4.1))
	_expect(C.bucket(5.0) == 5, "5 → 5，实际 %d" % C.bucket(5.0))
	_expect(C.bucket(5.1) == 5, "5.1 → 6 → 封顶 5，实际 %d" % C.bucket(5.1))
	_expect(C.bucket(25.9) == 5, "25.9 → 封顶 5，实际 %d" % C.bucket(25.9))
	_expect(C.bucket(0.0) == 0, "0 → 0，实际 %d" % C.bucket(0.0))
	_expect(C.bucket(0.4) == 1, "0.4 → 1，实际 %d" % C.bucket(0.4))


func _test_negative_is_zero() -> void :
	_expect(C.bucket(-3.5) == 0, "负数按 0，实际 %d" % C.bucket(-3.5))


func _test_bad_divisor() -> void :
	_expect(C.raw_score(60000, 0, 0, 0, 0, 0, 3) == 0.0, "目标数 0 应返回 0")
	_expect(C.raw_score(60000, 0, 0, 0, 0, 3, 0) == 0.0, "容量 0 应返回 0")




func _expect(ok: bool, msg: String) -> void :
	if not ok:
		_failures.append(msg)
		print("[FAIL] %s" % msg)


func _finish() -> void :
	if _failures.is_empty():
		print("PASS")
		quit(0)
		return
	print("FAIL (%d)" % _failures.size())
	quit(1)
